package content

import (
	"encoding/json"
	"os"
	"path/filepath"
	"reflect"
	"strings"
	"testing"
)

func TestImportExplicitQuestionIdentityMetadata(t *testing.T) {
	root := filepath.Join("..", "..", "..", "..")
	source, err := os.ReadFile(filepath.Join(root, "quizzes", "Cinema", "LOTR", "lotr_return_king_bts_100.json"))
	if err != nil {
		t.Fatal(err)
	}
	taxonomy, err := LoadTaxonomy(filepath.Join(root, "metadata", "tags.v1.json"))
	if err != nil {
		t.Fatal(err)
	}

	path := filepath.Join(t.TempDir(), "lotr_return_king_bts_100.json")
	if err = os.WriteFile(path, source, 0600); err != nil {
		t.Fatal(err)
	}
	before, beforeManifest, err := ImportWithTaxonomy(path, taxonomy)
	if err != nil {
		t.Fatal(err)
	}
	before93 := identityQuestion(t, before, "lotr-rk-93")
	before95 := identityQuestion(t, before, "lotr-rk-95")
	if before93.Revision.Number != 1 || before95.Revision.Number != 1 {
		t.Fatalf("absent revision_number did not default to 1: q93=%d q95=%d", before93.Revision.Number, before95.Revision.Number)
	}
	if got := before95.Options[3].OptionID; got != "lotr-rk-95-opt-4" {
		t.Fatalf("absent option_ids did not keep positional ID: %q", got)
	}

	var raw map[string]any
	decoder := json.NewDecoder(strings.NewReader(string(source)))
	decoder.UseNumber()
	if err = decoder.Decode(&raw); err != nil {
		t.Fatal(err)
	}
	for _, value := range raw["questions"].([]any) {
		question := value.(map[string]any)
		switch question["id"] {
		case "lotr_rk_93":
			question["revision_number"] = json.Number("2")
		case "lotr_rk_95":
			question["revision_number"] = json.Number("2")
			question["option_ids"] = []any{
				"lotr-rk-95-opt-1",
				"lotr-rk-95-opt-2",
				"lotr-rk-95-opt-3",
				"lotr-rk-95-opt-5",
			}
		}
	}
	withIdentity, err := json.Marshal(raw)
	if err != nil {
		t.Fatal(err)
	}
	if err = os.WriteFile(path, withIdentity, 0600); err != nil {
		t.Fatal(err)
	}
	after, afterManifest, err := ImportWithTaxonomy(path, taxonomy)
	if err != nil {
		t.Fatal(err)
	}

	after93 := identityQuestion(t, after, "lotr-rk-93")
	after95 := identityQuestion(t, after, "lotr-rk-95")
	if after93.Revision.Number != 2 || after95.Revision.Number != 2 {
		t.Fatalf("explicit revisions not retained: q93=%d q95=%d", after93.Revision.Number, after95.Revision.Number)
	}
	wantOptionIDs := []string{"lotr-rk-95-opt-1", "lotr-rk-95-opt-2", "lotr-rk-95-opt-3", "lotr-rk-95-opt-5"}
	gotOptionIDs := make([]string, len(after95.Options))
	for i := range after95.Options {
		gotOptionIDs[i] = after95.Options[i].OptionID
	}
	if !reflect.DeepEqual(gotOptionIDs, wantOptionIDs) {
		t.Fatalf("q95 option identity = %v, want %v", gotOptionIDs, wantOptionIDs)
	}
	if after95.Grading.CorrectOptionID != "lotr-rk-95-opt-2" {
		t.Fatalf("q95 answer identity = %q", after95.Grading.CorrectOptionID)
	}
	q95Map := identityQuestionMap(t, afterManifest, "lotr-rk-95")
	for i, option := range q95Map.Options {
		if option.SourceIndex != i || option.CanonicalID != wantOptionIDs[i] {
			t.Fatalf("q95 manifest option %d = %+v", i, option)
		}
	}

	if beforeManifest.SourcePath != afterManifest.SourcePath {
		t.Fatalf("comparison used different source paths: %q != %q", beforeManifest.SourcePath, afterManifest.SourcePath)
	}
	targets := map[string]bool{"lotr-rk-93": true, "lotr-rk-95": true}
	unchanged := 0
	for i, question := range before.Questions {
		if targets[question.QuestionID] {
			continue
		}
		if !reflect.DeepEqual(question, after.Questions[i]) {
			t.Fatalf("non-target question changed: %s", question.QuestionID)
		}
		if !reflect.DeepEqual(beforeManifest.Questions[i], afterManifest.Questions[i]) {
			t.Fatalf("non-target manifest mapping changed: %s", question.QuestionID)
		}
		unchanged++
	}
	if unchanged != 98 {
		t.Fatalf("compared %d unchanged questions, want 98", unchanged)
	}
}

func TestImportExplicitQuestionIdentityMetadataRejectsMalformedValues(t *testing.T) {
	cases := []struct {
		name, fields, code string
	}{
		{"option IDs null", `,"option_ids":null`, "option_ids"},
		{"option IDs wrong type", `,"option_ids":"question-two-opt-1"`, "option_ids"},
		{"option IDs wrong length", `,"option_ids":["question-two-opt-1"]`, "option_ids"},
		{"option IDs duplicate", `,"option_ids":["question-two-opt-1","question-two-opt-2","question-two-opt-2","question-two-opt-4"]`, "option_ids"},
		{"option ID blank", `,"option_ids":["question-two-opt-1"," ","question-two-opt-3","question-two-opt-4"]`, "option_ids"},
		{"option ID illegal", `,"option_ids":["question-two-opt-1","question-two-opt-2","INVALID","question-two-opt-4"]`, "option_ids"},
		{"revision null", `,"revision_number":null`, "revision_number"},
		{"revision wrong type", `,"revision_number":"2"`, "revision_number"},
		{"revision zero", `,"revision_number":0`, "revision_number"},
		{"revision negative", `,"revision_number":-1`, "revision_number"},
		{"revision fractional", `,"revision_number":1.5`, "revision_number"},
		{"revision overflow", `,"revision_number":9223372036854775808`, "revision_number"},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			source := strings.Replace(legacyBase, `"correct_answer":2`, `"correct_answer":2`+tc.fields, 1)
			_, _, err := importText(t, source)
			if Code(err) != tc.code {
				t.Fatalf("want %s, got %v", tc.code, err)
			}
		})
	}
}

func identityQuestion(t *testing.T, draft Draft, id string) Question {
	t.Helper()
	for _, question := range draft.Questions {
		if question.QuestionID == id {
			return question
		}
	}
	t.Fatalf("question %q not found", id)
	return Question{}
}

func identityQuestionMap(t *testing.T, manifest Manifest, id string) QuestionMap {
	t.Helper()
	for _, question := range manifest.Questions {
		if question.CanonicalID == id {
			return question
		}
	}
	t.Fatalf("question map %q not found", id)
	return QuestionMap{}
}
