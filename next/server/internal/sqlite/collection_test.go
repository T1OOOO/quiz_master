package sqlite

import (
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"path/filepath"
	"testing"
	"time"

	"quiz_master/next/server/internal/attempts"
	"quiz_master/next/server/internal/content"
	"quiz_master/next/server/internal/identity"
)

func TestSourceCollectionStartsEverySelectedPackAndSurvivesRestart(t *testing.T) {
	db, err := sql.Open("sqlite", "file:"+t.TempDir()+"/quiz.db")
	if err != nil {
		t.Fatal(err)
	}
	defer db.Close()
	ctx := context.Background()
	if err = Apply(ctx, db); err != nil {
		t.Fatal(err)
	}
	root := filepath.Join("..", "..", "..", "..")
	s, err := NewAttempts(db, filepath.Join(root, "quizzes"), "", filepath.Join(root, content.DefaultSchemas), time.Hour)
	if err != nil {
		t.Fatalf("source collection must load: %v", err)
	}
	multi, ok := any(s).(interface {
		CatalogFor(string) (attempts.Catalog, error)
		StartQuiz(context.Context, string, string) (attempts.Attempt, error)
	})
	if !ok {
		t.Fatal("selected quiz capability missing")
	}
	guest, err := NewIdentity(db, nil, identity.NewTokenSource(nil)).CreateGuestSession(ctx, "Guest")
	if err != nil {
		t.Fatal(err)
	}
	var raw string
	rows, err := db.Query("select controlled_bundle from attempt_bundles")
	if err != nil {
		t.Fatal(err)
	}
	var bundles []content.Bundle
	for rows.Next() {
		if err = rows.Scan(&raw); err != nil {
			t.Fatal(err)
		}
		var b content.Bundle
		if err = json.Unmarshal([]byte(raw), &b); err != nil {
			t.Fatal(err)
		}
		bundles = append(bundles, b)
	}
	rows.Close()
	if len(bundles) != 130 {
		t.Fatalf("packs=%d", len(bundles))
	}
	total := 0
	for _, b := range bundles {
		catalog, err := multi.CatalogFor(b.Quiz.QuizID)
		if err != nil {
			t.Fatal(err)
		}
		total += len(catalog.Quiz.Questions)
		a, err := multi.StartQuiz(ctx, guest.Principal.ID, b.Quiz.QuizID)
		if err != nil {
			t.Fatal(err)
		}
		if a.BundleSHA256 != b.BundleSHA256 || len(a.QuestionSnapshots) != len(b.Quiz.Questions) {
			t.Fatalf("wrong selected pack %s", b.Quiz.QuizID)
		}
		if _, err = s.Reveals(ctx, guest.Principal.ID, a.AttemptID); !errors.Is(err, attempts.ErrForbidden) {
			t.Fatal("early answers exposed")
		}
		for _, snap := range a.QuestionSnapshots {
			choice := b.PrivateGrading[snap.QuestionID].CorrectOptionID
			req := attempts.AnswerRequest{QuestionID: snap.QuestionID, QuestionRevision: snap.QuestionRevision, Answer: attempts.Answer{OptionID: &choice}, IdempotencyKey: snap.QuestionID}
			req.PayloadDigest, err = attempts.PayloadDigest(a.AttemptID, a.ParticipantID, req)
			if err != nil {
				t.Fatal(err)
			}
			if _, err = s.Submit(ctx, guest.Principal.ID, a.AttemptID, req); err != nil {
				t.Fatal(err)
			}
		}
		// Pinned DB content, not the service's current/default bundle, drives finish.
		s.bundle = content.Bundle{}
		finished, err := s.Finish(ctx, guest.Principal.ID, a.AttemptID)
		if err != nil {
			t.Fatal(err)
		}
		if len(finished.History) != len(b.Quiz.Questions) || finished.ServerScore != len(b.Quiz.Questions) {
			t.Fatal("selected history/score mismatch")
		}
		if _, err = s.GetHistory(ctx, "p_ffffffffffffffffffffffffffffffff", a.AttemptID); !errors.Is(err, attempts.ErrForbidden) {
			t.Fatal("foreign history exposed")
		}
	}
	if total != 3998 {
		t.Fatalf("questions=%d", total)
	}
	restarted, err := NewAttempts(db, filepath.Join(root, "quizzes"), "", filepath.Join(root, content.DefaultSchemas), time.Hour)
	if err != nil {
		t.Fatal(err)
	}
	historyCtx, cancel := context.WithTimeout(ctx, 3*time.Second)
	defer cancel()
	history, err := restarted.ListHistory(historyCtx, guest.Principal.ID)
	if err != nil || len(history) != 130 {
		t.Fatalf("restart history=%d err=%v", len(history), err)
	}
	if _, err = multi.StartQuiz(ctx, guest.Principal.ID, "../../bad"); !errors.Is(err, attempts.ErrValidation) {
		t.Fatal("unknown selection accepted")
	}
}
