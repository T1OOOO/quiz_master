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

func TestDifficultySelectionRejectsShortBands(t *testing.T) {
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
	for _, difficulty := range []string{"easy", "medium", "hard", "nightmare"} {
		if _, err = selector.CatalogForDifficulty(s.bundle.Quiz.QuizID, difficulty); !errors.Is(err, attempts.ErrNoMatch) {
			t.Fatalf("short %s catalog = %v", difficulty, err)
		}
	}
	guest, err := NewIdentity(db, nil, identity.NewTokenSource(nil)).CreateGuestSession(context.Background(), "difficulty test")
	if err != nil {
		t.Fatal(err)
	}
	if _, err = selector.StartDifficultyQuiz(context.Background(), guest.Principal.ID, s.bundle.Quiz.QuizID, "medium"); !errors.Is(err, attempts.ErrNoMatch) {
		t.Fatalf("short selected start = %v", err)
	}
	if _, err = selector.StartDifficultyRound(context.Background(), guest.Principal.ID, s.bundle.Quiz.QuizID, "medium", 0); !errors.Is(err, attempts.ErrNoMatch) {
		t.Fatalf("short selected round = %v", err)
	}
}
