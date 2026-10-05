package sqlite

import (
	"context"
	"database/sql"
	"errors"
	"testing"
	"time"

	"quiz_master/next/server/internal/attempts"
	"quiz_master/next/server/internal/identity"
)

func TestDifficultyRoundsFilterWholePackBeforePartitioning(t *testing.T) {
	db, err := sql.Open("sqlite", "file:"+t.TempDir()+"/difficulty-rounds.db")
	if err != nil {
		t.Fatal(err)
	}
	defer db.Close()
	if err = Apply(context.Background(), db); err != nil {
		t.Fatal(err)
	}
	s, err := NewAttempts(db, "../../../content/home-alone-1-part-1/bundle.json", "../../../content/home-alone-1-part-1/manifest.json", "../../../contracts/quiz-contract/v1/schemas", time.Hour)
	if err != nil {
		t.Fatal(err)
	}
	selector, ok := any(s).(interface {
		CatalogForDifficulty(string, string) (attempts.Catalog, error)
		StartDifficultyQuiz(context.Context, string, string, string) (attempts.Attempt, error)
		StartDifficultyRound(context.Context, string, string, string, int) (attempts.Attempt, error)
	})
	if !ok {
		t.Fatal("difficulty selection capability missing")
	}
	guest, err := NewIdentity(db, nil, identity.NewTokenSource(nil)).CreateGuestSession(context.Background(), "difficulty test")
	if err != nil {
		t.Fatal(err)
	}
	if _, err = selector.CatalogForDifficulty(s.bundle.Quiz.QuizID, "nightmare"); !errors.Is(err, attempts.ErrNoMatch) {
		t.Fatalf("empty band = %v", err)
	}
	catalog, err := selector.CatalogForDifficulty(s.bundle.Quiz.QuizID, "easy")
	if err != nil {
		t.Fatal(err)
	}
	for _, question := range catalog.Quiz.Questions {
		if question.Difficulty != "easy" {
			t.Fatalf("catalog leaked %s question %s", question.Difficulty, question.QuestionID)
		}
	}
	all, err := selector.StartDifficultyQuiz(context.Background(), guest.Principal.ID, s.bundle.Quiz.QuizID, "easy")
	if err != nil || len(all.QuestionSnapshots) != len(catalog.Quiz.Questions) {
		t.Fatalf("omitted round did not select all matches: %d %v", len(all.QuestionSnapshots), err)
	}
	a, err := selector.StartDifficultyRound(context.Background(), guest.Principal.ID, s.bundle.Quiz.QuizID, "easy", 0)
	if err != nil {
		t.Fatal(err)
	}
	if len(a.QuestionSnapshots) == 0 || len(a.QuestionSnapshots) > 20 || a.BundleSHA256 != s.bundle.BundleSHA256 {
		t.Fatal("filtered round lost immutable bundle identity")
	}
	allowed := map[string]bool{}
	for _, question := range catalog.Quiz.Questions {
		allowed[question.QuestionID] = true
	}
	for _, snapshot := range a.QuestionSnapshots {
		if !allowed[snapshot.QuestionID] {
			t.Fatalf("round selected nonmatching question %s", snapshot.QuestionID)
		}
	}
	if _, err = selector.StartDifficultyRound(context.Background(), guest.Principal.ID, s.bundle.Quiz.QuizID, "easy", -1); !errors.Is(err, attempts.ErrValidation) {
		t.Fatalf("negative round accepted: %v", err)
	}
}
