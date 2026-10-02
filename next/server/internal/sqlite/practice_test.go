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

func TestPracticeFeedbackRequiresOwnedAcceptedAnswerAndLeavesRankedSealed(t *testing.T) {
	db, err := sql.Open("sqlite", "file:"+t.TempDir()+"/practice.db")
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
	practice, ok := any(s).(interface {
		StartPracticeRound(context.Context, string, string, int) (attempts.Attempt, error)
		Feedback(context.Context, string, string, string) (attempts.Reveal, bool, error)
	})
	if !ok {
		t.Fatal("immediate practice feedback missing")
	}
	guest, err := NewIdentity(db, nil, identity.NewTokenSource(nil)).CreateGuestSession(ctx, "practice")
	if err != nil {
		t.Fatal(err)
	}
	a, err := practice.StartPracticeRound(ctx, guest.Principal.ID, s.bundle.Quiz.QuizID, 0)
	if err != nil {
		t.Fatal(err)
	}
	q := a.QuestionSnapshots[0]
	if _, _, err = practice.Feedback(ctx, guest.Principal.ID, a.AttemptID, q.QuestionID); !errors.Is(err, attempts.ErrForbidden) {
		t.Fatal("answer leaked before submission")
	}
	wrong := q.OptionOrder[0]
	if wrong == s.bundle.PrivateGrading[q.QuestionID].CorrectOptionID {
		wrong = q.OptionOrder[1]
	}
	req := attempts.AnswerRequest{QuestionID: q.QuestionID, QuestionRevision: q.QuestionRevision, Answer: attempts.Answer{OptionID: &wrong}, IdempotencyKey: "practice-wrong"}
	req.PayloadDigest, _ = attempts.PayloadDigest(a.AttemptID, a.ParticipantID, req)
	if _, err = s.Submit(ctx, guest.Principal.ID, a.AttemptID, req); err != nil {
		t.Fatal(err)
	}
	reveal, correct, err := practice.Feedback(ctx, guest.Principal.ID, a.AttemptID, q.QuestionID)
	if err != nil || correct || reveal.Explanation == "" || reveal.QuestionID != q.QuestionID {
		t.Fatalf("wrong-answer explanation: %v", err)
	}
	if _, _, err = practice.Feedback(ctx, "p_other", a.AttemptID, q.QuestionID); !errors.Is(err, attempts.ErrForbidden) {
		t.Fatal("foreign feedback leaked")
	}
	if _, _, err = practice.Feedback(ctx, guest.Principal.ID, a.AttemptID, a.QuestionSnapshots[1].QuestionID); !errors.Is(err, attempts.ErrForbidden) {
		t.Fatal("future answer leaked")
	}
	q = a.QuestionSnapshots[1]
	right := s.bundle.PrivateGrading[q.QuestionID].CorrectOptionID
	req = attempts.AnswerRequest{QuestionID: q.QuestionID, QuestionRevision: q.QuestionRevision, Answer: attempts.Answer{OptionID: &right}, IdempotencyKey: "practice-right"}
	req.PayloadDigest, _ = attempts.PayloadDigest(a.AttemptID, a.ParticipantID, req)
	if _, err = s.Submit(ctx, guest.Principal.ID, a.AttemptID, req); err != nil {
		t.Fatal(err)
	}
	if _, correct, err = practice.Feedback(ctx, guest.Principal.ID, a.AttemptID, q.QuestionID); err != nil || !correct {
		t.Fatalf("right answer: %v", err)
	}
	ranked, err := s.Start(ctx, guest.Principal.ID)
	if err != nil {
		t.Fatal(err)
	}
	rq := ranked.QuestionSnapshots[0]
	option := rq.OptionOrder[0]
	req = attempts.AnswerRequest{QuestionID: rq.QuestionID, QuestionRevision: rq.QuestionRevision, Answer: attempts.Answer{OptionID: &option}, IdempotencyKey: "ranked"}
	req.PayloadDigest, _ = attempts.PayloadDigest(ranked.AttemptID, ranked.ParticipantID, req)
	if _, err = s.Submit(ctx, guest.Principal.ID, ranked.AttemptID, req); err != nil {
		t.Fatal(err)
	}
	if _, _, err = practice.Feedback(ctx, guest.Principal.ID, ranked.AttemptID, rq.QuestionID); !errors.Is(err, attempts.ErrForbidden) {
		t.Fatal("ranked grading leaked early")
	}
}
