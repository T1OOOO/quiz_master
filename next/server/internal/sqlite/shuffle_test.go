package sqlite

import (
	"context"
	"database/sql"
	"encoding/json"
	"path/filepath"
	"strings"
	"testing"
	"time"

	"quiz_master/next/server/internal/content"
	"quiz_master/next/server/internal/identity"
)

// Feedback rep_1688: starting a whole pack must not replay the same question order.
func TestWholePackStartShufflesQuestionOrder(t *testing.T) {
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
		t.Fatal(err)
	}
	var raw string
	if err = db.QueryRow("select controlled_bundle from attempt_bundles where json_array_length(json_extract(controlled_bundle,'$.quiz.questions')) >= 10 limit 1").Scan(&raw); err != nil {
		t.Fatal(err)
	}
	var b content.Bundle
	if err = json.Unmarshal([]byte(raw), &b); err != nil {
		t.Fatal(err)
	}
	guest, err := NewIdentity(db, nil, identity.NewTokenSource(nil)).CreateGuestSession(ctx, "Guest")
	if err != nil {
		t.Fatal(err)
	}
	orders := map[string]bool{}
	for range 5 {
		a, err := s.StartQuiz(ctx, guest.Principal.ID, b.Quiz.QuizID)
		if err != nil {
			t.Fatal(err)
		}
		if len(a.QuestionSnapshots) != len(b.Quiz.Questions) {
			t.Fatalf("questions=%d want %d", len(a.QuestionSnapshots), len(b.Quiz.Questions))
		}
		ids := make([]string, len(a.QuestionSnapshots))
		for i, snap := range a.QuestionSnapshots {
			ids[i] = snap.QuestionID
		}
		orders[strings.Join(ids, ",")] = true
	}
	if len(orders) < 2 {
		t.Fatal("five whole-pack starts produced one question order")
	}
}
