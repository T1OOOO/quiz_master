//go:build integration

package attempts

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"reflect"
	"strings"
	"sync"
	"sync/atomic"
	"testing"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
	"quiz_master/next/server/internal/content"
	"quiz_master/next/server/internal/identity"
	"quiz_master/next/server/internal/migrate"
)

func TestPostgresAttemptLifecycle(t *testing.T) {
	ctx := context.Background()
	pool, err := pgxpool.New(ctx, os.Getenv("QM_TEST_DATABASE_URL"))
	if err != nil {
		t.Fatal(err)
	}
	defer pool.Close()
	if err = migrate.Apply(ctx, pool, migrate.Migrations()); err != nil {
		t.Fatal(err)
	}
	var ticks atomic.Int64
	ticks.Store(time.Date(2026, 9, 20, 12, 0, 0, 0, time.UTC).UnixNano())
	now := func() time.Time { return time.Unix(0, ticks.Load()).UTC() }
	path := "../../../content/home-alone-1-part-1/bundle.json"
	schemas := "../../../contracts/quiz-contract/v1/schemas"
	opts := Options{Now: now, Shuffle: func(ids []string) error {
		for i, j := 0, len(ids)-1; i < j; i, j = i+1, j-1 {
			ids[i], ids[j] = ids[j], ids[i]
		}
		return nil
	}}
	newService := func() *Service {
		s, e := NewService(ctx, pool, path, schemas, 30*time.Minute, opts)
		if e != nil {
			t.Fatal(e)
		}
		return s
	}
	s := newService()
	ident := identity.NewService(pool, now, identity.NewTokenSource(nil))
	owner, token, err := ident.CreateGuest(ctx, "P09 owner")
	if err != nil {
		t.Fatal(err)
	}
	other, _, err := ident.CreateGuest(ctx, "P09 other")
	if err != nil {
		t.Fatal(err)
	}
	start := func() Attempt {
		a, e := s.Start(ctx, owner.ID)
		if e != nil {
			t.Fatal(e)
		}
		return a
	}
	t.Run("finished row requires timestamp and history", func(t *testing.T) {
		for _, missing := range []string{"finished_at", "finish_history"} {
			tx, e := pool.Begin(ctx)
			if e != nil {
				t.Fatal(e)
			}
			finished, history := any(now()), any([]byte(`[{"question_id":"q-one"}]`))
			if missing == "finished_at" {
				finished = nil
			} else {
				history = nil
			}
			_, e = tx.Exec(ctx, `insert into attempts(id,participant_id,external_participant_id,bundle_sha256,bundle_version,scoring_policy_version,started_at,deadline_at,status,finished_at,server_score,finish_history) values('a-invalid-finish',$1,$2,$3,$4,'scoring/v1',$5,$6,'finished',$7,0,$8)`, owner.ID, "p-"+owner.ID[2:], s.bundle.BundleSHA256, s.bundle.BundleVersion, now(), now().Add(30*time.Minute), finished, history)
			_ = tx.Rollback(ctx)
			if e == nil {
				t.Fatalf("accepted finished row without %s", missing)
			}
		}
	})
	request := func(a Attempt, index int, option, key string) AnswerRequest {
		snap := a.QuestionSnapshots[index]
		r := AnswerRequest{QuestionID: snap.QuestionID, QuestionRevision: snap.QuestionRevision, Answer: Answer{OptionID: &option}, IdempotencyKey: key}
		r.PayloadDigest, _ = PayloadDigest(a.AttemptID, a.ParticipantID, r)
		return r
	}
	t.Run("immutable bundle and snapshots", func(t *testing.T) {
		a := start()
		if len(a.QuestionSnapshots) != 25 || a.QuestionSnapshots[1].OptionOrder[0] != "q-ha1-p1-2-opt-6" || a.QuestionSnapshots[1].PositionToOptionID["5"] != "q-ha1-p1-2-opt-1" {
			t.Fatal("unpinned order")
		}
		var stored []byte
		if err := pool.QueryRow(ctx, "select snapshot from attempt_questions where attempt_id=$1 and question_id=$2", a.AttemptID, a.QuestionSnapshots[1].QuestionID).Scan(&stored); err != nil {
			t.Fatal(err)
		}
		var snap Snapshot
		_ = json.Unmarshal(stored, &snap)
		if !reflect.DeepEqual(snap, a.QuestionSnapshots[1]) {
			t.Fatal("snapshot differs")
		}
		for _, query := range []string{"update attempt_bundles set bundle_version='changed'", "update attempt_questions set position=position+100", "update attempts set deadline_at=deadline_at+interval '1 hour'"} {
			if _, err := pool.Exec(ctx, query); err == nil {
				t.Fatal("immutable data changed")
			}
		}
		doc, e := content.ReadDocument(path, schemas)
		if e != nil {
			t.Fatal(e)
		}
		draft := doc.Draft
		draft.Questions[0].Stem += " changed"
		content.Rehash(&draft)
		b, e := content.Build(draft, doc.Bundle.BundleVersion, doc.Bundle.PublishedAt, schemas)
		if e != nil {
			t.Fatal(e)
		}
		raw, _ := json.Marshal(b)
		conflictPath := filepath.Join(t.TempDir(), "bundle.json")
		if e = os.WriteFile(conflictPath, raw, 0600); e != nil {
			t.Fatal(e)
		}
		if _, e = NewService(ctx, pool, conflictPath, schemas, 30*time.Minute, opts); e == nil {
			t.Fatal("version/hash conflict accepted")
		}
		if _, e = NewService(ctx, pool, path, schemas, time.Second, opts); e == nil {
			t.Fatal("invalid service duration")
		}
	})
	t.Run("validation ownership replay and restart", func(t *testing.T) {
		a := start()
		good := request(a, 1, "q-ha1-p1-2-opt-2", "first")
		if _, e := s.Submit(ctx, other.ID, a.AttemptID, good); !errors.Is(e, ErrForbidden) {
			t.Fatal(e)
		}
		if _, e := s.Submit(ctx, owner.ID, "att-missing", good); !errors.Is(e, ErrForbidden) {
			t.Fatal(e)
		}
		for _, kind := range []string{"revision", "option", "digest", "kind"} {
			bad := good
			switch kind {
			case "revision":
				bad.QuestionRevision.Number++
			case "option":
				v := "opt-forged"
				bad.Answer = Answer{OptionID: &v}
			case "kind":
				v := "text"
				bad.Answer = Answer{Text: &v}
			}
			bad.PayloadDigest, _ = PayloadDigest(a.AttemptID, a.ParticipantID, bad)
			if kind == "digest" {
				bad.PayloadDigest = strings.Repeat("0", 64)
			}
			if _, e := s.Submit(ctx, owner.ID, a.AttemptID, bad); e == nil {
				t.Fatal("accepted forged", kind)
			}
		}
		r, e := s.Submit(ctx, owner.ID, a.AttemptID, good)
		if e != nil {
			t.Fatal(e)
		}
		replay, e := s.Submit(ctx, owner.ID, a.AttemptID, good)
		if e != nil || !reflect.DeepEqual(r, replay) {
			t.Fatal("replay", e)
		}
		changed := request(a, 1, "q-ha1-p1-2-opt-1", "first")
		if _, e = s.Submit(ctx, owner.ID, a.AttemptID, changed); !errors.Is(e, ErrConflict) {
			t.Fatal("conflict", e)
		}
		changed.IdempotencyKey = "replace"
		if _, e = s.Submit(ctx, owner.ID, a.AttemptID, changed); !errors.Is(e, ErrConflict) {
			t.Fatal("replacement", e)
		}
		if _, e = s.Submit(ctx, owner.ID, a.AttemptID, request(a, 2, "q-ha1-p1-3-opt-1", "wrong")); e != nil {
			t.Fatal(e)
		}
		f, e := s.Finish(ctx, owner.ID, a.AttemptID)
		if e != nil || f.ServerScore != 1 || len(f.History) != 2 {
			t.Fatal("partial finish", e, f.ServerScore)
		}
		s = newService()
		got, e := s.GetHistory(ctx, owner.ID, a.AttemptID)
		if e != nil || !reflect.DeepEqual(got, f) {
			t.Fatal("restart", e)
		}
		again, e := s.Finish(ctx, owner.ID, a.AttemptID)
		if e != nil || !reflect.DeepEqual(again, f) {
			t.Fatal("finish replay", e)
		}
		if _, e = s.GetHistory(ctx, other.ID, a.AttemptID); !errors.Is(e, ErrForbidden) {
			t.Fatal("history owner", e)
		}
		list, e := s.ListHistory(ctx, other.ID)
		if e != nil || len(list) != 0 {
			t.Fatal("list owner", e)
		}
		replay, e = s.Submit(ctx, owner.ID, a.AttemptID, good)
		if e != nil || !reflect.DeepEqual(r, replay) {
			t.Fatal("finished receipt replay", e)
		}
		if _, e = s.Submit(ctx, owner.ID, a.AttemptID, request(a, 3, "q-ha1-p1-4-opt-1", "late")); !errors.Is(e, ErrValidation) {
			t.Fatal("finished mutation", e)
		}
		var leak bool
		if e = pool.QueryRow(ctx, `select exists(select 1 from attempts a where row_to_json(a)::text like '%'||$1||'%' union all select 1 from attempt_answers r where row_to_json(r)::text like '%'||$1||'%')`, token).Scan(&leak); e != nil || leak {
			t.Fatal("raw token persisted", e)
		}
	})
	t.Run("deadline and empty finish", func(t *testing.T) {
		a := start()
		if _, e := s.Finish(ctx, owner.ID, a.AttemptID); !errors.Is(e, ErrValidation) {
			t.Fatal("empty finish", e)
		}
		r := request(a, 1, "q-ha1-p1-2-opt-2", "before")
		ticks.Add(int64(30*time.Minute - time.Microsecond))
		if _, e := s.Submit(ctx, owner.ID, a.AttemptID, r); e != nil {
			t.Fatal(e)
		}
		ticks.Add(int64(time.Microsecond))
		if _, e := s.Submit(ctx, owner.ID, a.AttemptID, request(a, 2, "q-ha1-p1-3-opt-2", "boundary")); !errors.Is(e, ErrDeadline) {
			t.Fatal("exact deadline", e)
		}
		ticks.Add(int64(time.Hour))
		if _, e := s.Submit(ctx, owner.ID, a.AttemptID, r); e != nil {
			t.Fatal("late replay", e)
		}
		if f, e := s.Finish(ctx, owner.ID, a.AttemptID); e != nil || f.ServerScore != 1 {
			t.Fatal("late finish", e)
		}
	})
	t.Run("concurrent answer and finish", func(t *testing.T) {
		a := start()
		var wg sync.WaitGroup
		errs := make(chan error, 8)
		for i := 0; i < 8; i++ {
			wg.Add(1)
			go func() {
				defer wg.Done()
				_, e := s.Submit(ctx, owner.ID, a.AttemptID, request(a, 1, "q-ha1-p1-2-opt-2", "race"))
				errs <- e
			}()
		}
		wg.Wait()
		close(errs)
		for e := range errs {
			if e != nil {
				t.Fatal(e)
			}
		}
		results := make(chan Finish, 8)
		errs = make(chan error, 8)
		for i := 0; i < 8; i++ {
			wg.Add(1)
			go func() { defer wg.Done(); f, e := s.Finish(ctx, owner.ID, a.AttemptID); results <- f; errs <- e }()
		}
		wg.Wait()
		close(results)
		close(errs)
		for e := range errs {
			if e != nil {
				t.Fatal(e)
			}
		}
		var first *Finish
		for f := range results {
			if first == nil {
				x := f
				first = &x
			}
			if !reflect.DeepEqual(*first, f) || f.ServerScore != 1 || len(f.History) != 1 {
				t.Fatal("concurrent finish differs")
			}
		}
	})
	t.Run("rollback on receipt insertion failure", func(t *testing.T) {
		fixed := opts
		fixedID, e := randomID("fixed")
		if e != nil {
			t.Fatal(e)
		}
		fixed.ID = func(prefix string) (string, error) { return prefix + "-" + fixedID, nil }
		failing, e := NewService(ctx, pool, path, schemas, 30*time.Minute, fixed)
		if e != nil {
			t.Fatal(e)
		}
		a := start()
		if _, e = failing.Submit(ctx, owner.ID, a.AttemptID, request(a, 1, "q-ha1-p1-2-opt-2", "one")); e != nil {
			t.Fatal(e)
		}
		if _, e = failing.Submit(ctx, owner.ID, a.AttemptID, request(a, 2, "q-ha1-p1-3-opt-2", "two")); e == nil {
			t.Fatal("duplicate receipt accepted")
		}
		var count int
		if e = pool.QueryRow(ctx, "select count(*) from attempt_answers where attempt_id=$1", a.AttemptID).Scan(&count); e != nil || count != 1 {
			t.Fatal("rollback", e, count)
		}
		if _, e = s.Submit(ctx, owner.ID, a.AttemptID, request(a, 2, "q-ha1-p1-3-opt-2", "two")); e != nil {
			t.Fatal("retry after rollback", e)
		}
	})
	t.Run("queued answer samples time after lock", func(t *testing.T) {
		a := start()
		tx, e := pool.Begin(ctx)
		if e != nil {
			t.Fatal(e)
		}
		defer func() { _ = tx.Rollback(ctx) }()
		if _, e = lockAttempt(ctx, tx, owner.ID, a.AttemptID); e != nil {
			t.Fatal(e)
		}
		result := make(chan error, 1)
		go func() {
			_, e := s.Submit(ctx, owner.ID, a.AttemptID, request(a, 1, "q-ha1-p1-2-opt-2", "queued"))
			result <- e
		}()
		// Wait for PostgreSQL to report the queued lock, bounded by two seconds.
		until := time.Now().Add(2 * time.Second)
		waiting := false
		for time.Now().Before(until) {
			if e = pool.QueryRow(ctx, `select exists(select 1 from pg_stat_activity where datname=current_database() and wait_event_type='Lock' and query like '%from attempts%for update%')`).Scan(&waiting); e != nil {
				t.Fatal(e)
			}
			if waiting {
				break
			}
			time.Sleep(5 * time.Millisecond)
		}
		if !waiting {
			t.Fatal("answer did not queue on attempt lock")
		}
		ticks.Add(int64(30 * time.Minute))
		if e = tx.Commit(ctx); e != nil {
			t.Fatal(e)
		}
		select {
		case e = <-result:
			if !errors.Is(e, ErrDeadline) {
				t.Fatal("queued stale clock", e)
			}
		case <-time.After(2 * time.Second):
			t.Fatal("queued answer did not return")
		}
	})
	t.Run("different keys race and answer finish serialize", func(t *testing.T) {
		a := start()
		var wg sync.WaitGroup
		results := make(chan error, 2)
		for _, key := range []string{"race-one", "race-two"} {
			wg.Add(1)
			go func(key string) {
				defer wg.Done()
				_, e := s.Submit(ctx, owner.ID, a.AttemptID, request(a, 1, "q-ha1-p1-2-opt-2", key))
				results <- e
			}(key)
		}
		wg.Wait()
		close(results)
		accepted, conflicts := 0, 0
		for e := range results {
			if e == nil {
				accepted++
			} else if errors.Is(e, ErrConflict) {
				conflicts++
			} else {
				t.Fatal(e)
			}
		}
		if accepted != 1 || conflicts != 1 {
			t.Fatal("answer race", accepted, conflicts)
		}
		answerResult := make(chan error, 1)
		finishResult := make(chan Finish, 1)
		finishError := make(chan error, 1)
		go func() {
			_, e := s.Submit(ctx, owner.ID, a.AttemptID, request(a, 2, "q-ha1-p1-3-opt-2", "race-finish"))
			answerResult <- e
		}()
		go func() { f, e := s.Finish(ctx, owner.ID, a.AttemptID); finishResult <- f; finishError <- e }()
		e := <-answerResult
		f := <-finishResult
		if fe := <-finishError; fe != nil {
			t.Fatal(fe)
		}
		want := 1
		if e == nil {
			want = 2
		} else if !errors.Is(e, ErrValidation) {
			t.Fatal(e)
		}
		if f.ServerScore != want || len(f.History) != want {
			t.Fatal("non-atomic answer/finish", f.ServerScore, want)
		}
	})
	t.Run("multi partial exact and normalized text persisted", func(t *testing.T) {
		doc, e := content.ReadDocument(path, schemas)
		if e != nil {
			t.Fatal(e)
		}
		d := doc.Draft
		for _, i := range []int{0, 1} {
			q := &d.Questions[i]
			q.AnswerKind = "multiple_choice"
			q.Grading = content.Grading{CorrectOptionIDs: []string{q.Options[0].OptionID, q.Options[1].OptionID}}
		}
		d.Questions[2].AnswerKind = "normalized_text"
		d.Questions[2].Grading = content.Grading{AcceptedVariants: []string{"Straße é"}}
		content.Rehash(&d)
		b, e := content.Build(d, "p09-typed-fixture", doc.Bundle.PublishedAt, schemas)
		if e != nil {
			t.Fatal(e)
		}
		raw, _ := json.Marshal(b)
		fixture := filepath.Join(t.TempDir(), "typed.json")
		if e = os.WriteFile(fixture, raw, 0600); e != nil {
			t.Fatal(e)
		}
		typed, e := NewService(ctx, pool, fixture, schemas, 30*time.Minute, opts)
		if e != nil {
			t.Fatal(e)
		}
		a, e := typed.Start(ctx, owner.ID)
		if e != nil {
			t.Fatal(e)
		}
		selections := [][]string{{"q-ha1-p1-1-opt-1"}, {"q-ha1-p1-2-opt-2", "q-ha1-p1-2-opt-1"}}
		text := "  STRASSE\tE\u0301 "
		for i := 0; i < 3; i++ {
			r := request(a, i, "unused", fmt.Sprintf("typed-%d", i))
			if i < 2 {
				r.Answer = Answer{OptionIDs: &selections[i]}
			} else {
				r.Answer = Answer{Text: &text}
			}
			r.PayloadDigest, _ = PayloadDigest(a.AttemptID, a.ParticipantID, r)
			if _, e = typed.Submit(ctx, owner.ID, a.AttemptID, r); e != nil {
				t.Fatal(e)
			}
		}
		f, e := typed.Finish(ctx, owner.ID, a.AttemptID)
		if e != nil || f.ServerScore != 2 || len(f.History) != 3 {
			t.Fatal("typed database scoring", e, f.ServerScore)
		}
	})
}
