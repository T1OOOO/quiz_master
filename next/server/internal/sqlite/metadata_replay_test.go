package sqlite

import (
	"context"
	"crypto/sha256"
	"database/sql"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"reflect"
	"testing"
	"time"

	"quiz_master/next/server/internal/attempts"
	"quiz_master/next/server/internal/content"
	"quiz_master/next/server/internal/identity"
)

func TestAnnotatedPartialAttemptPinsMetadataAfterRepublish(t *testing.T) {
	ctx := context.Background()
	db, err := sql.Open("sqlite", "file:"+filepath.Join(t.TempDir(), "replay.db"))
	if err != nil {
		t.Fatal(err)
	}
	defer db.Close()
	if err = Apply(ctx, db); err != nil {
		t.Fatal(err)
	}
	directory := filepath.Join(t.TempDir(), "quizzes")
	if err = os.Mkdir(directory, 0700); err != nil {
		t.Fatal(err)
	}
	schemas := "../../../contracts/quiz-contract/v1/schemas"
	writeJSON := func(path string, value any) {
		t.Helper()
		raw, e := json.Marshal(value)
		if e != nil {
			t.Fatal(e)
		}
		if e = os.WriteFile(path, raw, 0600); e != nil {
			t.Fatal(e)
		}
	}
	// The two dictionaries deliberately share no tag IDs. A live lookup using
	// the replacement dictionary cannot validate the original annotations.
	writeTaxonomy := func(version string) (string, *content.Taxonomy) {
		t.Helper()
		value := map[string]any{
			"schema_version": "qm-taxonomy/v1", "taxonomy_id": "replay-" + version,
			"facets": []any{map[string]any{"id": "topic"}, map[string]any{"id": "knowledge_skill"}},
			"tags": []any{
				map[string]any{"id": "topic:" + version, "facet": "topic", "label_ru": "Тема", "label_en": "Topic", "aliases_ru": []string{}, "aliases_en": []string{}, "parent_ids": []string{}, "player_safe": true},
				map[string]any{"id": "skill:" + version, "facet": "knowledge_skill", "label_ru": "Навык", "label_en": "Skill", "aliases_ru": []string{}, "aliases_en": []string{}, "parent_ids": []string{}, "player_safe": false},
			}, "collections": []any{},
		}
		raw, e := content.Canonical(value)
		if e != nil {
			t.Fatal(e)
		}
		hash := sha256.Sum256(raw)
		value["taxonomy_sha256"] = hex.EncodeToString(hash[:])
		path := filepath.Join(t.TempDir(), "tags.json")
		writeJSON(path, value)
		taxonomy, e := content.LoadTaxonomy(path)
		if e != nil {
			t.Fatal(e)
		}
		return path, taxonomy
	}
	oldDictionary, oldTaxonomy := writeTaxonomy("old")
	newDictionary, newTaxonomy := writeTaxonomy("new")
	source := filepath.Join(directory, "replay.json")
	publish := func(version string, taxonomy *content.Taxonomy, level, correct int) {
		t.Helper()
		questions := []any{}
		for i := 0; i < 2; i++ {
			questions = append(questions, map[string]any{
				"id": fmt.Sprintf("q-replay-%d", i), "type": "choice", "text": fmt.Sprintf("Question %d %s?", i, version),
				"options":        []string{"First " + version, "Second " + version, "Third " + version, "Fourth " + version},
				"correct_answer": correct, "explanation": fmt.Sprintf("%s explanation %d", version, i), "difficulty": level,
				"editorial_tag_ids": []string{"skill:" + version, "topic:" + version}, "context_tag_ids": []string{"topic:" + version},
			})
		}
		writeJSON(source, map[string]any{"id": "replay-quiz", "title": "Replay", "description": "Replay fixture", "category": "Test", "taxonomy_ref": content.TaxonomyRef{TaxonomyID: taxonomy.ID, TaxonomySHA256: taxonomy.SHA256}, "questions": questions})
	}
	load := func(dictionary string) *Attempts {
		t.Helper()
		s, e := NewAttemptsWithTaxonomy(db, directory, "", schemas, time.Hour, dictionary)
		if e != nil {
			t.Fatal(e)
		}
		return s
	}
	publish("old", oldTaxonomy, 2, 1)
	oldService := load(oldDictionary)
	oldBundle := oldService.bundle
	guest, err := NewIdentity(db, nil, identity.NewTokenSource(nil)).CreateGuestSession(ctx, "metadata replay")
	if err != nil {
		t.Fatal(err)
	}
	a, err := oldService.StartQuiz(ctx, guest.Principal.ID, oldBundle.Quiz.QuizID)
	if err != nil {
		t.Fatal(err)
	}
	request := func(index int) attempts.AnswerRequest {
		t.Helper()
		snapshot := a.QuestionSnapshots[index]
		option := oldBundle.PrivateGrading[snapshot.QuestionID].CorrectOptionID
		r := attempts.AnswerRequest{QuestionID: snapshot.QuestionID, QuestionRevision: snapshot.QuestionRevision, Answer: attempts.Answer{OptionID: &option}, IdempotencyKey: fmt.Sprintf("replay-%d", index)}
		r.PayloadDigest, err = attempts.PayloadDigest(a.AttemptID, a.ParticipantID, r)
		if err != nil {
			t.Fatal(err)
		}
		return r
	}
	first := request(0)
	receipt, err := oldService.Submit(ctx, guest.Principal.ID, a.AttemptID, first)
	if err != nil {
		t.Fatal(err)
	}
	publish("new", newTaxonomy, 9, 0)
	current := load(newDictionary)
	newAttempt, err := current.StartQuiz(ctx, guest.Principal.ID, oldBundle.Quiz.QuizID)
	if err != nil {
		t.Fatal(err)
	}
	if newAttempt.BundleSHA256 == a.BundleSHA256 || !reflect.DeepEqual(current.bundle.TaxonomyRef, &content.TaxonomyRef{TaxonomyID: newTaxonomy.ID, TaxonomySHA256: newTaxonomy.SHA256}) {
		t.Fatal("republish did not change bundle/taxonomy identity")
	}
	for i, q := range current.bundle.Quiz.Questions {
		oldQ := oldBundle.Quiz.Questions[i]
		if q.QuestionID != oldQ.QuestionID || q.Revision == oldQ.Revision || q.DifficultyLevel == nil || *q.DifficultyLevel != 9 || q.Difficulty != "nightmare" || !reflect.DeepEqual(q.ContextTagIDs, []string{"topic:new"}) || !reflect.DeepEqual(current.bundle.PrivateQuestionMetadata[q.QuestionID].EditorialTagIDs, []string{"skill:new", "topic:new"}) || newAttempt.QuestionSnapshots[i].QuestionRevision != q.Revision {
			t.Fatal("new attempt did not adopt replacement content")
		}
	}
	// Remove source AND both dictionaries after the replacement service has
	// started: old operations must depend entirely on persisted attempt data.
	for _, path := range []string{source, oldDictionary, newDictionary} {
		if err = os.Remove(path); err != nil {
			t.Fatal(err)
		}
	}
	if _, err = content.LoadTaxonomy(newDictionary); content.Code(err) != "taxonomy_read" {
		t.Fatalf("live taxonomy still available: %v", err)
	}
	replayed, err := current.Submit(ctx, guest.Principal.ID, a.AttemptID, first)
	if err != nil || !reflect.DeepEqual(receipt, replayed) {
		t.Fatalf("first receipt replay: %v", err)
	}
	if _, err = current.Submit(ctx, guest.Principal.ID, a.AttemptID, request(1)); err != nil {
		t.Fatal(err)
	}
	finished, err := current.Finish(ctx, guest.Principal.ID, a.AttemptID)
	if err != nil || finished.ServerScore != 2 || len(finished.History) != 2 {
		t.Fatalf("original grading not pinned: %+v, %v", finished, err)
	}
	reveals, err := current.Reveals(ctx, guest.Principal.ID, a.AttemptID)
	if err != nil || len(reveals) != 2 {
		t.Fatalf("old reveals: %v", err)
	}
	for i, reveal := range reveals {
		q := oldBundle.Quiz.Questions[i]
		if reveal.QuestionID != q.QuestionID || reveal.QuestionRevision != q.Revision || reveal.CorrectAnswer.OptionID != oldBundle.PrivateGrading[q.QuestionID].CorrectOptionID || reveal.Explanation != fmt.Sprintf("old explanation %d", i) || finished.History[i].QuestionRevision != q.Revision {
			t.Fatal("reveal/history used replacement content")
		}
	}
	var hash, version, raw string
	if err = db.QueryRowContext(ctx, `select a.bundle_sha256,a.bundle_version,b.controlled_bundle from attempts a join attempt_bundles b on b.bundle_sha256=a.bundle_sha256 and b.bundle_version=a.bundle_version where a.id=?`, a.AttemptID).Scan(&hash, &version, &raw); err != nil {
		t.Fatal(err)
	}
	var pinned content.Bundle
	if err = json.Unmarshal([]byte(raw), &pinned); err != nil {
		t.Fatal(err)
	}
	if hash != a.BundleSHA256 || version != a.BundleVersion || !reflect.DeepEqual(pinned, oldBundle) {
		t.Fatal("persisted original annotations/grading/taxonomy/bundle changed")
	}
	rows, err := db.QueryContext(ctx, `select position,public_question,snapshot from attempt_questions where attempt_id=? order by position`, a.AttemptID)
	if err != nil {
		t.Fatal(err)
	}
	defer rows.Close()
	count := 0
	for rows.Next() {
		var position int
		var publicRaw, snapshotRaw string
		if err = rows.Scan(&position, &publicRaw, &snapshotRaw); err != nil {
			t.Fatal(err)
		}
		var public content.PublicQuestion
		var snapshot attempts.Snapshot
		if err = json.Unmarshal([]byte(publicRaw), &public); err != nil {
			t.Fatal(err)
		}
		if err = json.Unmarshal([]byte(snapshotRaw), &snapshot); err != nil {
			t.Fatal(err)
		}
		if position != count || !reflect.DeepEqual(public, oldBundle.Quiz.Questions[count]) || !reflect.DeepEqual(snapshot, a.QuestionSnapshots[count]) {
			t.Fatal("stored revision/options/order/public metadata changed")
		}
		count++
	}
	if err = rows.Err(); err != nil {
		t.Fatal(err)
	}
	if count != 2 {
		t.Fatalf("pinned question count = %d", count)
	}
}
