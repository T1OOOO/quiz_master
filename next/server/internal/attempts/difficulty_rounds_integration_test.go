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
	"testing"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
	"quiz_master/next/server/internal/content"
	"quiz_master/next/server/internal/identity"
	"quiz_master/next/server/internal/migrate"
)

func TestPostgresDifficultyRoundsPersistFilteredShuffledPartitions(t *testing.T) {
	ctx := context.Background()
	pool, err := pgxpool.New(ctx, os.Getenv("QM_TEST_DATABASE_URL"))
	if err != nil {
		t.Fatal(err)
	}
	defer pool.Close()
	if err = migrate.Apply(ctx, pool, migrate.Migrations()); err != nil {
		t.Fatal(err)
	}
	schemas := "../../../contracts/quiz-contract/v1/schemas"
	doc, err := content.ReadDocument("../../../content/home-alone-1-part-1/bundle.json", schemas)
	if err != nil {
		t.Fatal(err)
	}
	draft := doc.Draft
	draft.QuizID = "pg-difficulty-rounds"
	draft.Questions = nil
	manifest := content.Manifest{CanonicalQuizID: draft.QuizID}
	for i := 0; i < 82; i++ {
		q := doc.Draft.Questions[0]
		q.QuestionID = fmt.Sprintf("q-pg-difficulty-%02d", i)
		q.Stem = fmt.Sprintf("Filtered persistence question %d?", i)
		q.Options = make([]content.Option, 4)
		for j := range q.Options {
			q.Options[j] = content.Option{OptionID: fmt.Sprintf("%s-opt-%d", q.QuestionID, j), Text: fmt.Sprintf("Option %d", j)}
		}
		q.Grading = content.Grading{CorrectOptionID: q.Options[1].OptionID}
		level := 7
		q.Difficulty = "hard"
		if i%2 == 0 {
			level = 2
			q.Difficulty = "easy"
		}
		q.DifficultyLevel = &level
		draft.Questions = append(draft.Questions, q)
		manifest.Questions = append(manifest.Questions, content.QuestionMap{CanonicalID: q.QuestionID, Explanation: fmt.Sprintf("Explanation %d", i)})
	}
	content.Rehash(&draft)
	bundle, err := content.Build(draft, "pg-difficulty-rounds-v1", "2026-10-05T00:00:00Z", schemas)
	if err != nil {
		t.Fatal(err)
	}
	dir := t.TempDir()
	write := func(name string, value any) string {
		t.Helper()
		raw, e := json.Marshal(value)
		if e != nil {
			t.Fatal(e)
		}
		path := filepath.Join(dir, name)
		if e = os.WriteFile(path, raw, 0600); e != nil {
			t.Fatal(e)
		}
		return path
	}
	service, err := NewService(ctx, pool, write("bundle.json", bundle), schemas, time.Hour, Options{ManifestPath: write("manifest.json", manifest), Shuffle: func(ids []string) error {
		for i, j := 0, len(ids)-1; i < j; i, j = i+1, j-1 {
			ids[i], ids[j] = ids[j], ids[i]
		}
		return nil
	}})
	if err != nil {
		t.Fatal(err)
	}
	owner, _, err := identity.NewService(pool, nil, identity.NewTokenSource(nil)).CreateGuest(ctx, "filtered rounds")
	if err != nil {
		t.Fatal(err)
	}
	original := service.Catalog()
	catalog, err := service.CatalogForDifficulty(bundle.Quiz.QuizID, "easy")
	if err != nil {
		t.Fatal(err)
	}
	if len(catalog.Quiz.Questions) != 41 || catalog.BundleSHA256 != bundle.BundleSHA256 || catalog.BundleVersion != bundle.BundleVersion || catalog.DifficultyCounts["easy"] != 41 || catalog.DifficultyCounts["hard"] != 0 {
		t.Fatal("filtered catalog/source identity mismatch")
	}
	whole, err := service.StartDifficultyQuiz(ctx, owner.ID, bundle.Quiz.QuizID, "easy")
	if err != nil || len(whole.QuestionSnapshots) != 41 {
		t.Fatalf("whole filtered attempt: %v", err)
	}
	for i, snapshot := range whole.QuestionSnapshots {
		if snapshot.QuestionID != catalog.Quiz.Questions[i].QuestionID {
			t.Fatal("whole attempt/catalog order mismatch")
		}
	}
	seen := map[string]bool{}
	for round, want := range []int{20, 21} {
		a, e := service.StartDifficultyRound(ctx, owner.ID, bundle.Quiz.QuizID, "easy", round)
		if e != nil {
			t.Fatal(e)
		}
		if len(a.QuestionSnapshots) != want || a.BundleSHA256 != catalog.BundleSHA256 || a.BundleVersion != catalog.BundleVersion {
			t.Fatalf("round %d identity/count mismatch", round)
		}
		start, end := round*20, round*20+want
		for i, snapshot := range a.QuestionSnapshots {
			q := catalog.Quiz.Questions[end-1-i]
			if snapshot.QuestionID != q.QuestionID || snapshot.QuestionRevision != q.Revision || seen[q.QuestionID] {
				t.Fatalf("round %d leaked/repeated/unshuffled question at %d", round, i)
			}
			seen[q.QuestionID] = true
			for j, option := range snapshot.OptionOrder {
				if option != q.Options[len(q.Options)-1-j].OptionID || snapshot.PositionToOptionID[fmt.Sprint(j)] != option {
					t.Fatal("stored snapshot option permutation lost")
				}
			}
		}
		// Read actual database rows in persisted position order; compare both the
		// public metadata/revision and snapshot with the exact selected slice.
		rows, e := pool.Query(ctx, `select position,question_id,revision_number,revision_sha256,public_question,snapshot from attempt_questions where attempt_id=$1 order by position`, a.AttemptID)
		if e != nil {
			t.Fatal(e)
		}
		count := 0
		for rows.Next() {
			var position, revision int
			var id, hash string
			var publicRaw, snapshotRaw []byte
			if e = rows.Scan(&position, &id, &revision, &hash, &publicRaw, &snapshotRaw); e != nil {
				rows.Close()
				t.Fatal(e)
			}
			var public content.PublicQuestion
			var snapshot Snapshot
			if e = json.Unmarshal(publicRaw, &public); e != nil {
				rows.Close()
				t.Fatal(e)
			}
			if e = json.Unmarshal(snapshotRaw, &snapshot); e != nil {
				rows.Close()
				t.Fatal(e)
			}
			if count >= want {
				rows.Close()
				t.Fatal("extra stored question")
			}
			q := catalog.Quiz.Questions[end-1-count]
			if position != count || id != q.QuestionID || revision != q.Revision.Number || hash != q.Revision.SHA256 || !reflect.DeepEqual(public, q) || !reflect.DeepEqual(snapshot, a.QuestionSnapshots[count]) {
				rows.Close()
				t.Fatalf("round %d persisted position %d differs from selected [%d:%d]", round, count, start, end)
			}
			count++
		}
		e = rows.Err()
		rows.Close()
		if e != nil || count != want {
			t.Fatalf("round %d stored count=%d: %v", round, count, e)
		}
		var storedHash, storedVersion string
		if e = pool.QueryRow(ctx, `select bundle_sha256,bundle_version from attempts where id=$1`, a.AttemptID).Scan(&storedHash, &storedVersion); e != nil || storedHash != bundle.BundleSHA256 || storedVersion != bundle.BundleVersion {
			t.Fatalf("persisted source identity: %v", e)
		}
	}
	if len(seen) != 41 {
		t.Fatalf("round union = %d", len(seen))
	}
	for _, q := range catalog.Quiz.Questions {
		if !seen[q.QuestionID] {
			t.Fatal("catalog question absent from round union")
		}
	}
	if !reflect.DeepEqual(original, service.Catalog()) {
		t.Fatal("round selection mutated full catalog")
	}
	if _, err = service.StartDifficultyRound(ctx, owner.ID, bundle.Quiz.QuizID, "easy", 2); !errors.Is(err, ErrValidation) {
		t.Fatalf("past-tail round: %v", err)
	}
	if _, err = service.CatalogForDifficulty(bundle.Quiz.QuizID, "nightmare"); !errors.Is(err, ErrNoMatch) {
		t.Fatalf("empty catalog: %v", err)
	}
	if _, err = service.StartDifficultyQuiz(ctx, owner.ID, bundle.Quiz.QuizID, "nightmare"); !errors.Is(err, ErrNoMatch) {
		t.Fatalf("empty filtered attempt: %v", err)
	}
}
