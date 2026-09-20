package content

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"reflect"
	"strings"
	"testing"
)

const schemas = "../../../contracts/quiz-contract/v1/schemas"
const legacyBase = `{"id":"quiz_one","title":"T","description":"D","category":"C","questions":[{"id":"question_two","type":"choice","text":"S","options":["a","b","c","d"],"correct_answer":2}]}`

func importText(t *testing.T, source string) (Draft, Manifest, error) {
	t.Helper()
	p := filepath.Join(t.TempDir(), "legacy.json")
	if e := os.WriteFile(p, []byte(source), 0600); e != nil {
		t.Fatal(e)
	}
	return Import(p)
}
func fixture(t *testing.T) Draft {
	t.Helper()
	d, _, e := importText(t, legacyBase)
	if e != nil {
		t.Fatal(e)
	}
	return d
}

// Catches zero-default answer decoding and ignored multi/difficulty.
func TestImportGolden(t *testing.T) {
	for _, tc := range []struct {
		name, fields, options string
		answer                int
		kind, difficulty      string
		ids                   []string
	}{
		{"zero_missing", "", `["a","b","c","d"]`, 0, "single_choice", "unknown", []string{"question-two-opt-1"}},
		{"nonzero_null", `,"difficulty":null,"correct_multi":null`, `["a","b","c","d"]`, 2, "single_choice", "unknown", []string{"question-two-opt-3"}},
		{"last_four_empty", `,"difficulty":1,"correct_multi":[]`, `["a","b","c","d"]`, 3, "single_choice", "easy", []string{"question-two-opt-4"}},
		{"last_five", `,"difficulty":7`, `["a","b","c","d","e"]`, 4, "single_choice", "medium", []string{"question-two-opt-5"}},
		{"last_six", `,"difficulty":10`, `["a","b","c","d","e","f"]`, 5, "single_choice", "hard", []string{"question-two-opt-6"}},
		{"multi", `,"difficulty":8,"correct_multi":[3,2]`, `["a","b","c","d"]`, 2, "multiple_choice", "hard", []string{"question-two-opt-3", "question-two-opt-4"}},
	} {
		t.Run(tc.name, func(t *testing.T) {
			s := strings.Replace(legacyBase, `["a","b","c","d"]`, tc.options, 1)
			s = strings.Replace(s, `"correct_answer":2`, fmt.Sprintf(`"correct_answer":%d%s`, tc.answer, tc.fields), 1)
			d, m, e := importText(t, s)
			if e != nil {
				t.Fatal(e)
			}
			q := d.Questions[0]
			ids := q.Grading.CorrectOptionIDs
			if q.AnswerKind == "single_choice" {
				ids = []string{q.Grading.CorrectOptionID}
			}
			if q.AnswerKind != tc.kind || q.Difficulty != tc.difficulty || !reflect.DeepEqual(ids, tc.ids) {
				t.Fatalf("incorrect mapping: kind=%s difficulty=%s", q.AnswerKind, q.Difficulty)
			}
			if d.QuizID != "quiz-one" || len(m.Questions) != 1 || len(m.SourceSHA256) != 64 {
				t.Fatal("incomplete manifest")
			}
		})
	}
}
func TestImportNegative(t *testing.T) {
	cases := []struct{ name, old, new, code string }{
		{"answer_missing", `,"correct_answer":2`, ``, "answer_index"},
		{"answer_null", `"correct_answer":2`, `"correct_answer":null`, "answer_index"},
		{"answer_negative", `"correct_answer":2`, `"correct_answer":-1`, "answer_index"},
		{"answer_out", `"correct_answer":2`, `"correct_answer":4`, "answer_index"},
		{"answer_fraction", `"correct_answer":2`, `"correct_answer":1.5`, "answer_index"},
		{"answer_string", `"correct_answer":2`, `"correct_answer":"2"`, "answer_index"},
		{"multi_type", `"correct_answer":2`, `"correct_answer":2,"correct_multi":false`, "multi_index"},
		{"multi_one", `"correct_answer":2`, `"correct_answer":2,"correct_multi":[2]`, "multi_index"},
		{"multi_duplicate", `"correct_answer":2`, `"correct_answer":2,"correct_multi":[2,2]`, "multi_index"},
		{"multi_fraction", `"correct_answer":2`, `"correct_answer":2,"correct_multi":[2,1.5]`, "multi_index"},
		{"multi_null_element", `"correct_answer":2`, `"correct_answer":2,"correct_multi":[2,null]`, "multi_index"},
		{"multi_string_element", `"correct_answer":2`, `"correct_answer":2,"correct_multi":[2,"3"]`, "multi_index"},
		{"multi_out", `"correct_answer":2`, `"correct_answer":2,"correct_multi":[2,4]`, "multi_index"},
		{"multi_negative", `"correct_answer":2`, `"correct_answer":2,"correct_multi":[2,-1]`, "multi_index"},
		{"multi_conflict", `"correct_answer":2`, `"correct_answer":2,"correct_multi":[0,1]`, "multi_conflict"},
		{"difficulty_zero", `"correct_answer":2`, `"correct_answer":2,"difficulty":0`, "difficulty"},
		{"difficulty_negative", `"correct_answer":2`, `"correct_answer":2,"difficulty":-1`, "difficulty"},
		{"difficulty_high", `"correct_answer":2`, `"correct_answer":2,"difficulty":11`, "difficulty"},
		{"difficulty_fraction", `"correct_answer":2`, `"correct_answer":2,"difficulty":1.5`, "difficulty"},
		{"difficulty_string", `"correct_answer":2`, `"correct_answer":2,"difficulty":"1"`, "difficulty"},
		{"difficulty_bool", `"correct_answer":2`, `"correct_answer":2,"difficulty":true`, "difficulty"},
		{"blank_stem", `"text":"S"`, `"text":" \t"`, "required"},
		{"blank_option", `"a","b"`, `" ","b"`, "option_blank"},
		{"blank_title", `"title":"T"`, `"title":" "`, "required"},
		{"bad_type", `"type":"choice"`, `"type":"text"`, "type"},
		{"few_options", `"a","b","c","d"`, `"a","b","c"`, "option_count"},
		{"many_options", `"a","b","c","d"`, `"a","b","c","d","e","f","g"`, "option_count"},
		{"unknown_question", `"correct_answer":2`, `"correct_answer":2,"answer_key":"secret-marker"`, "unknown_field"},
		{"unknown_quiz", `"title":"T"`, `"title":"T","surprise":1`, "unknown_field"},
		{"invalid_id", `"id":"quiz_one"`, `"id":"!!!"`, "invalid_id"},
		{"duplicate_key", `"correct_answer":2`, `"correct_answer":2,"correct_answer":0`, "duplicate_key"},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			_, _, e := importText(t, strings.Replace(legacyBase, tc.old, tc.new, 1))
			if Code(e) != tc.code {
				t.Fatalf("want %s got %v", tc.code, e)
			}
			if !strings.Contains(e.Error(), "legacy.json") || strings.Contains(e.Error(), "secret-marker") {
				t.Fatal("unsafe/missing context")
			}
		})
	}
	for _, tc := range []struct{ name, source, code string }{
		{"malformed", "{", "invalid_json"}, {"trailing", legacyBase + ` {}`, "trailing_json"}, {"nonobject", "[]", "invalid_json"}, {"null", "null", "invalid_json"},
		{"nonobject_question", `{"id":"quiz_one","title":"T","description":"D","category":"C","questions":[null]}`, "invalid_json"},
		{"empty_questions", `{"id":"quiz_one","title":"T","description":"D","category":"C","questions":[]}`, "required"},
	} {
		t.Run(tc.name, func(t *testing.T) {
			_, _, e := importText(t, tc.source)
			if Code(e) != tc.code {
				t.Fatalf("want %s got %v", tc.code, e)
			}
		})
	}
	for _, tc := range []struct{ id, code string }{{"question_two", "duplicate_id"}, {"question-two", "id_collision"}} {
		t.Run(tc.code, func(t *testing.T) {
			var obj map[string]any
			_ = json.Unmarshal([]byte(legacyBase), &obj)
			q := obj["questions"].([]any)[0].(map[string]any)
			other := map[string]any{}
			for k, v := range q {
				other[k] = v
			}
			other["id"] = tc.id
			obj["questions"] = []any{q, other}
			data, _ := json.Marshal(obj)
			_, _, e := importText(t, string(data))
			if Code(e) != tc.code {
				t.Fatalf("want %s got %v", tc.code, e)
			}
		})
	}
}
func TestHashUnescapedUnicodeSortedKeys(t *testing.T) {
	wantJSON := []byte("{\"a\":\"<>&é\u2028\u2029\",\"z\":1}")
	if got := sum(map[string]any{"z": 1, "a": "<>&é\u2028\u2029"}); got != hashBytes(wantJSON) {
		t.Fatal("canonical hash escaped Unicode/HTML or unsorted keys")
	}
}
func TestBuildRejectsInvalidDraftAndTimestamp(t *testing.T) {
	if _, e := Build(Draft{}, "v1", "2026-09-20T00:00:00Z"); e == nil {
		t.Fatal("accepted invalid draft")
	}
	if _, e := Build(fixture(t), "v1", "not-a-time"); e == nil {
		t.Fatal("accepted invalid timestamp")
	}
}
func TestDiffDetectsChangedQuestionRevisionWithoutSecrets(t *testing.T) {
	before := fixture(t)
	after := before
	after.Questions = append([]Question(nil), before.Questions...)
	after.Questions[0].Revision.SHA256 = strings.Repeat("a", 64)
	got := Diff(before, after)
	if got == "no changes" || !strings.Contains(got, "question-two") || strings.Contains(got, "correct_option") {
		t.Fatalf("bad diff: %s", got)
	}
}
