package reports_test

import (
	"context"
	"database/sql"
	"errors"
	"path/filepath"
	"strings"
	"sync"
	"testing"

	_ "modernc.org/sqlite"
	"quiz_master/next/server/internal/reports"
	localsqlite "quiz_master/next/server/internal/sqlite"
)

const participant = "p_0123456789abcdef0123456789abcdef"

func sampleReport() reports.Request {
	return reports.Request{RequestID: "frq_0123456789abcdef0123456789abcdef", Type: "ui", ItemIDs: []string{"screen:/library"}, Comment: "Useful private feedback", Context: reports.Context{Route: "/library", Viewport: reports.Viewport{Width: 390, Height: 844, DPR: 2}, Locale: "ru", Theme: "light", Platform: "web", AppVersion: "test", Timestamp: "2026-10-06T00:00:00Z"}}
}

func seedParticipant(t *testing.T, db *sql.DB, id string) {
	t.Helper()
	_, err := db.Exec(`INSERT INTO participants(id,kind,display_name,created_at,updated_at) VALUES($1,'guest','Guest','2026-10-06T00:00:00Z','2026-10-06T00:00:00Z')`, id)
	if err != nil {
		t.Fatal(err)
	}
}

func checkConcurrentRetries(t *testing.T, store *reports.Store) reports.Receipt {
	t.Helper()
	const count = 16
	var wg sync.WaitGroup
	ids := make(chan string, count)
	errs := make(chan error, count)
	created := make(chan bool, count)
	for range count {
		wg.Add(1)
		go func() {
			defer wg.Done()
			r, fresh, err := store.Create(context.Background(), participant, sampleReport())
			ids <- r.ID
			created <- fresh
			errs <- err
		}()
	}
	wg.Wait()
	close(ids)
	close(errs)
	close(created)
	for err := range errs {
		if err != nil {
			t.Fatal(err)
		}
	}
	var id string
	for got := range ids {
		if id == "" {
			id = got
		}
		if got != id {
			t.Fatal("concurrent retries created different IDs")
		}
	}
	freshCount := 0
	for fresh := range created {
		if fresh {
			freshCount++
		}
	}
	if freshCount != 1 {
		t.Fatalf("first creations=%d", freshCount)
	}
	r, fresh, err := store.Create(context.Background(), participant, sampleReport())
	if err != nil || fresh || r.ID != id {
		t.Fatalf("retry failed: %v", err)
	}
	changed := sampleReport()
	changed.Comment = "different"
	if _, _, err = store.Create(context.Background(), participant, changed); !errors.Is(err, reports.ErrConflict) {
		t.Fatal("different payload accepted under same key")
	}
	normalized := sampleReport()
	normalized.Comment = "  " + normalized.Comment + "  "
	if _, fresh, err = store.Create(context.Background(), participant, normalized); err != nil || fresh {
		t.Fatal("trimmed-equivalent retry conflicts")
	}
	return r
}

func TestSQLiteFeedbackPersistsAcrossReopenAndConcurrentRetries(t *testing.T) {
	path := filepath.Join(t.TempDir(), "reports.db")
	db, err := sql.Open("sqlite", path)
	if err != nil {
		t.Fatal(err)
	}
	if err = localsqlite.Apply(context.Background(), db); err != nil {
		t.Fatal(err)
	}
	seedParticipant(t, db, participant)
	r := checkConcurrentRetries(t, reports.NewStore(db))
	if err = db.Close(); err != nil {
		t.Fatal(err)
	}
	db, err = sql.Open("sqlite", path)
	if err != nil {
		t.Fatal(err)
	}
	defer db.Close()
	if err = localsqlite.Apply(context.Background(), db); err != nil {
		t.Fatal(err)
	}
	store := reports.NewStore(db)
	again, fresh, err := store.Create(context.Background(), participant, sampleReport())
	if err != nil || fresh || again != r {
		t.Fatalf("restart lost receipt: %v", err)
	}
	other := "p_11111111111111111111111111111111"
	seedParticipant(t, db, other)
	second, fresh, err := store.Create(context.Background(), other, sampleReport())
	if err != nil || !fresh || second.ID == r.ID {
		t.Fatal("participants cannot independently reuse request id")
	}
	page, err := store.List(context.Background(), "all", 1, 1)
	if err != nil || page.Total != 2 || len(page.Reports) != 1 {
		t.Fatal("pagination is not durable")
	}
}

func TestReportValidationRequiresBoundedSafeContext(t *testing.T) {
	for _, mutate := range []func(*reports.Request){
		func(r *reports.Request) { r.RequestID = "bad" },
		func(r *reports.Request) { r.Context.Route = "/feedback" },
		func(r *reports.Request) { r.Context.Timestamp = "2026-10-06T03:00:00+03:00" },
		func(r *reports.Request) { r.Context.QuestionText = strings.Repeat("я", 4001) },
		func(r *reports.Request) { r.Context.Viewport.DPR = 100 },
		func(r *reports.Request) { r.ItemIDs = nil },
	} {
		r := sampleReport()
		mutate(&r)
		if _, _, _, err := reports.Normalize(r); !errors.Is(err, reports.ErrValidation) {
			t.Fatal("invalid context accepted")
		}
	}
	r := sampleReport()
	r.Screenshot = strings.Repeat("A", 3<<20)
	if _, _, _, err := reports.Normalize(r); !errors.Is(err, reports.ErrTooLarge) {
		t.Fatal("oversized encoded screenshot accepted")
	}
}
