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
		SourceCatalogFor(string) (attempts.Catalog, error)
		StartQuiz(context.Context, string, string) (attempts.Attempt, error)
		StartPracticeQuiz(context.Context, string, string) (attempts.Attempt, error)
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
	if len(bundles) != 161 {
		t.Fatalf("packs=%d", len(bundles))
	}
	byQuizID := make(map[string]content.Bundle, len(bundles))
	for _, b := range bundles {
		byQuizID[b.Quiz.QuizID] = b
	}
	startedPacks := 0
	for _, b := range bundles {
		sourceCatalog, err := multi.SourceCatalogFor(b.Quiz.QuizID)
		if err != nil || sourceCatalog.Quiz.QuizID != b.Quiz.QuizID || len(sourceCatalog.Quiz.Questions) != len(b.Quiz.Questions) {
			t.Fatalf("source catalog %s: %+v %v", b.Quiz.QuizID, sourceCatalog, err)
		}
		if playableID := content.PlayableQuizID(b.Quiz.QuizID); playableID != b.Quiz.QuizID {
			target, ok := byQuizID[playableID]
			if !ok {
				t.Fatalf("alias target %s for %s missing from source collection", playableID, b.Quiz.QuizID)
			}
			catalog, err := multi.CatalogFor(b.Quiz.QuizID)
			if err != nil || catalog.Quiz.QuizID != playableID || len(catalog.Quiz.Questions) != len(target.Quiz.Questions) {
				t.Fatalf("legacy alias catalog %s: %+v %v", b.Quiz.QuizID, catalog, err)
			}
			continue
		}
		if len(b.Quiz.Questions) < attempts.MinimumAttemptQuestions {
			if _, err := multi.CatalogFor(b.Quiz.QuizID); !errors.Is(err, attempts.ErrNoMatch) {
				t.Fatalf("short pack catalog %s: %v", b.Quiz.QuizID, err)
			}
			if _, err := multi.StartQuiz(ctx, guest.Principal.ID, b.Quiz.QuizID); !errors.Is(err, attempts.ErrNoMatch) {
				t.Fatalf("short pack standard start %s: %v", b.Quiz.QuizID, err)
			}
			if _, err := multi.StartPracticeQuiz(ctx, guest.Principal.ID, b.Quiz.QuizID); !errors.Is(err, attempts.ErrNoMatch) {
				t.Fatalf("short pack practice start %s: %v", b.Quiz.QuizID, err)
			}
			continue
		}
		catalog, err := multi.CatalogFor(b.Quiz.QuizID)
		if err != nil {
			t.Fatal(err)
		}
		if len(catalog.Quiz.Questions) != len(b.Quiz.Questions) {
			t.Fatalf("eligible catalog count for %s = %d, want %d", b.Quiz.QuizID, len(catalog.Quiz.Questions), len(b.Quiz.Questions))
		}
		startedPacks++
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
	restarted, err := NewAttempts(db, filepath.Join(root, "quizzes"), "", filepath.Join(root, content.DefaultSchemas), time.Hour)
	if err != nil {
		t.Fatal(err)
	}
	historyCtx, cancel := context.WithTimeout(ctx, 3*time.Second)
	defer cancel()
	history, err := restarted.ListHistory(historyCtx, guest.Principal.ID)
	if err != nil || len(history) != startedPacks {
		t.Fatalf("restart history=%d err=%v", len(history), err)
	}
	if _, err = multi.StartQuiz(ctx, guest.Principal.ID, "../../bad"); !errors.Is(err, attempts.ErrValidation) {
		t.Fatal("unknown selection accepted")
	}
}

func TestCollectionResolvesLegacyAliasToDerivedPlayablePackOnly(t *testing.T) {
	legacy := &Attempts{bundle: content.Bundle{Quiz: content.PublicQuiz{QuizID: "legacy-short", Questions: make([]content.PublicQuestion, 3)}, PrivateGrading: map[string]content.Grading{"legacy-question": {CorrectOptionID: "legacy-private"}}}}
	derived := &Attempts{bundle: content.Bundle{Quiz: content.PublicQuiz{QuizID: "derived-twenty", Questions: make([]content.PublicQuestion, attempts.MinimumAttemptQuestions)}, PrivateGrading: map[string]content.Grading{"derived-question": {CorrectOptionID: "derived-private"}}}}
	packs := map[string]*Attempts{"legacy-short": legacy, "derived-twenty": derived}
	aliases := map[string]string{"legacy-short": "derived-twenty"}

	if err := validateRoundAliases(packs, aliases); err != nil {
		t.Fatal(err)
	}
	selected, err := selectPack(packs, "legacy-short", aliases)
	if err != nil {
		t.Fatal(err)
	}
	if selected != derived || selected.bundle.Quiz.QuizID != "derived-twenty" || selected.bundle.PrivateGrading["derived-question"].CorrectOptionID != "derived-private" {
		t.Fatal("legacy selection did not use the derived playable bundle and its private grading")
	}
	if legacy.bundle.PrivateGrading["legacy-question"].CorrectOptionID != "legacy-private" {
		t.Fatal("legacy private grading was changed")
	}
}

func TestCollectionRejectsInvalidAliasesForLoadedSources(t *testing.T) {
	packs := map[string]*Attempts{"legacy": {}, "target": {}}
	for name, aliases := range map[string]map[string]string{
		"self":    {"legacy": "legacy"},
		"cycle":   {"legacy": "target", "target": "legacy"},
		"unknown": {"legacy": "missing"},
	} {
		t.Run(name, func(t *testing.T) {
			if err := validateRoundAliases(packs, aliases); !errors.Is(err, attempts.ErrValidation) {
				t.Fatalf("validate aliases = %v", err)
			}
		})
	}
}
