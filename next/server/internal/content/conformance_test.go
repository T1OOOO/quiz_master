package content

import (
	"encoding/json"
	"os"
	"path/filepath"
	"reflect"
	"strings"
	"testing"
)

func TestP04IndependentCanonicalHashVector(t *testing.T) {
	data, e := os.ReadFile(filepath.Join(schemas, "..", "fixtures", "positive.json"))
	if e != nil {
		t.Fatal(e)
	}
	var fixtures map[string]json.RawMessage
	if e = json.Unmarshal(data, &fixtures); e != nil {
		t.Fatal(e)
	}
	var b Bundle
	if e = json.Unmarshal(fixtures["published_bundle"], &b); e != nil {
		t.Fatal(e)
	}
	if got := hashWithout(b, "bundle_sha256"); got != "886816179d39228d08c932c281e052636d6fd8bc6075b9421f623bb001bd2dd3" {
		t.Fatalf("P04 hash mismatch: %s", got)
	}
	for _, pair := range []struct{ key, schema string }{{"draft", "draft-quiz.schema.json"}, {"published_bundle", "published-bundle.schema.json"}} {
		if e := ValidateSchema(fixtures[pair.key], filepath.Join(schemas, pair.schema), pair.key); e != nil {
			t.Fatal(e)
		}
	}
	// P04 has symbolic revision hashes, so explicitly rehash this test copy.
	var d Draft
	_ = json.Unmarshal(fixtures["draft"], &d)
	Rehash(&d)
	built, e := Build(d, "fixture", "2026-09-20T00:00:00Z", schemas)
	if e != nil {
		t.Fatal(e)
	}
	if !reflect.DeepEqual(DraftFromBundle(built), d) {
		t.Fatal("build lost optional media or normalized-text grading")
	}
	if built.Quiz.Questions[0].Media == nil {
		t.Fatal("explicit empty media lost")
	}
}

func TestIDGrammarAndDifficultyBoundaries(t *testing.T) {
	for _, tc := range []struct{ source, want string }{{"A", "id-a"}, {"12", "id-12"}, {"QUIZ__One", "quiz-one"}, {" Quiz One ", "quiz-one"}} {
		d, _, e := importText(t, strings.Replace(legacyBase, "quiz_one", tc.source, 1))
		if e != nil || d.QuizID != tc.want {
			t.Fatalf("mapping %q: %s %v", tc.source, d.QuizID, e)
		}
	}
	for _, id := range []string{"!!!", "вопрос", strings.Repeat("a", 65)} {
		_, _, e := importText(t, strings.Replace(legacyBase, "question_two", id, 1))
		if Code(e) != "invalid_id" {
			t.Fatalf("invalid ID accepted: %v", e)
		}
	}
	for _, tc := range []struct{ number, want string }{{"1", "easy"}, {"3", "easy"}, {"4", "medium"}, {"7", "medium"}, {"8", "hard"}, {"10", "hard"}} {
		d, _, e := importText(t, strings.Replace(legacyBase, `"correct_answer":2`, `"correct_answer":2,"difficulty":`+tc.number, 1))
		if e != nil || d.Questions[0].Difficulty != tc.want {
			t.Fatal("difficulty boundary", e)
		}
	}
}

func TestDiffAddedRemovedQuizAndQuestion(t *testing.T) {
	d := fixture(t)
	other := d
	other.QuizID = "new-quiz"
	other.Questions = append([]Question(nil), d.Questions...)
	other.Questions[0].QuestionID = "new-question"
	got := Diff(d, other)
	for _, want := range []string{"quiz removed: quiz-one", "quiz added: new-quiz", "question removed: question-two", "question added: new-question"} {
		if !strings.Contains(got, want) {
			t.Fatalf("missing %s in %s", want, got)
		}
	}
}
