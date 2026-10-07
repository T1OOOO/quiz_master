package sqlite

import (
	"context"
	"database/sql"
	"errors"
	"quiz_master/next/server/internal/attempts"
	"quiz_master/next/server/internal/identity"
	"testing"
	"time"
)

func TestRoundsCoverEveryQuestionOnceAndPinShuffledSnapshots(t *testing.T) {
	db, err := sql.Open("sqlite", "file:"+t.TempDir()+"/rounds.db")
	if err != nil {
		t.Fatal(err)
	}
	defer db.Close()
	ctx := context.Background()
	if err = Apply(ctx, db); err != nil {
		t.Fatal(err)
	}
	s, err := NewAttempts(db, "../../../content/home-alone-1-part-1/bundle.json", "../../../content/home-alone-1-part-1/manifest.json", "../../../contracts/quiz-contract/v1/schemas", time.Hour)
	if err != nil {
		t.Fatal(err)
	}
	rounds, ok := any(s).(interface {
		StartRound(context.Context, string, string, int) (attempts.Attempt, error)
	})
	if !ok {
		t.Fatal("20-question round capability missing")
	}
	guest, err := NewIdentity(db, nil, identity.NewTokenSource(nil)).CreateGuestSession(ctx, "round test")
	if err != nil {
		t.Fatal(err)
	}
	seen := map[string]bool{}
	for round, want := range []int{25} {
		a, err := rounds.StartRound(ctx, guest.Principal.ID, s.bundle.Quiz.QuizID, round)
		if err != nil {
			t.Fatal(err)
		}
		if len(a.QuestionSnapshots) != want || a.BundleSHA256 != s.bundle.BundleSHA256 {
			t.Fatal("wrong round or bundle")
		}
		for _, q := range a.QuestionSnapshots {
			if seen[q.QuestionID] {
				t.Fatal("question repeated across rounds")
			}
			seen[q.QuestionID] = true
			option := s.bundle.PrivateGrading[q.QuestionID].CorrectOptionID
			request := attempts.AnswerRequest{QuestionID: q.QuestionID, QuestionRevision: q.QuestionRevision, Answer: attempts.Answer{OptionID: &option}, IdempotencyKey: q.QuestionID}
			request.PayloadDigest, _ = attempts.PayloadDigest(a.AttemptID, a.ParticipantID, request)
			if _, err = s.Submit(ctx, guest.Principal.ID, a.AttemptID, request); err != nil {
				t.Fatal(err)
			}
		}
		result, err := s.Finish(ctx, guest.Principal.ID, a.AttemptID)
		if err != nil || len(result.History) != want {
			t.Fatalf("round finish: %v", err)
		}
	}
	if len(seen) != 25 {
		t.Fatal("source questions lost")
	}
	for _, bad := range []int{-1, 1, 2, 2147483647} {
		if _, err = rounds.StartRound(ctx, guest.Principal.ID, s.bundle.Quiz.QuizID, bad); !errors.Is(err, attempts.ErrValidation) {
			t.Fatal("invalid round accepted")
		}
	}
	a, err := rounds.StartRound(ctx, guest.Principal.ID, s.bundle.Quiz.QuizID, 0)
	if err != nil {
		t.Fatal(err)
	}
	same := true
	for i, q := range a.QuestionSnapshots {
		same = same && q.QuestionID == s.bundle.Quiz.Questions[i].QuestionID
	}
	if same {
		t.Fatal("question order not shuffled")
	}
	var stored int
	if err = db.QueryRow("select count(*) from attempt_questions where attempt_id=?", a.AttemptID).Scan(&stored); err != nil || stored != 25 {
		t.Fatal("round snapshot not pinned")
	}
}
