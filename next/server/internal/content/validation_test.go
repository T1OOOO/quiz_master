package content

import (
	"encoding/json"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestDraftSchemaAndCrossRecordNegatives(t *testing.T) {
	for _, tc := range []struct {
		name, code string
		mutate     func(*Draft)
	}{
		{"contract", "schema_invalid", func(d *Draft) { d.Contract = "wrong" }},
		{"revision_shape", "schema_invalid", func(d *Draft) { d.Revision.Number = 0 }},
		{"option_id", "schema_invalid", func(d *Draft) { d.Questions[0].Options[0].OptionID = "Bad" }},
		{"duplicate_question", "duplicate_id", func(d *Draft) { d.Questions = append(d.Questions, d.Questions[0]) }},
		{"duplicate_option", "duplicate_id", func(d *Draft) { d.Questions[0].Options[0].OptionID = d.Questions[0].Options[1].OptionID }},
		{"blank_stem", "required", func(d *Draft) { d.Questions[0].Stem = " " }},
		{"blank_option", "required", func(d *Draft) { d.Questions[0].Options[0].Text = " " }},
		{"missing_reference", "grading_reference", func(d *Draft) { d.Questions[0].Grading.CorrectOptionID = "opt-missing" }},
		{"wrong_kind", "grading_kind", func(d *Draft) { d.Questions[0].AnswerKind = "multiple_choice" }},
		{"multi_duplicate", "grading_reference", func(d *Draft) {
			d.Questions[0].AnswerKind = "multiple_choice"
			d.Questions[0].Grading = Grading{CorrectOptionIDs: []string{"question-two-opt-1", "question-two-opt-1"}}
		}},
		{"multi_reference", "grading_reference", func(d *Draft) {
			d.Questions[0].AnswerKind = "multiple_choice"
			d.Questions[0].Grading = Grading{CorrectOptionIDs: []string{"opt-missing"}}
		}},
		{"text_duplicate_normalized", "grading_variants", func(d *Draft) {
			d.Questions[0].AnswerKind = "normalized_text"
			d.Questions[0].Grading = Grading{AcceptedVariants: []string{"Straße", "STRASSE"}}
		}},
		{"text_blank", "grading_variants", func(d *Draft) {
			d.Questions[0].AnswerKind = "normalized_text"
			d.Questions[0].Grading = Grading{AcceptedVariants: []string{"\u00a0"}}
		}},
		{"stale_question", "revision_hash", func(d *Draft) { d.Questions[0].Stem = "changed" }},
		{"stale_quiz", "revision_hash", func(d *Draft) { d.Locale = "en" }},
	} {
		t.Run(tc.name, func(t *testing.T) {
			d := fixture(t)
			tc.mutate(&d)
			e := ValidateDraft(d, filepath.Join(schemas, "draft-quiz.schema.json"))
			if Code(e) != tc.code {
				t.Fatalf("want %s got %v", tc.code, e)
			}
		})
	}
}
func TestBuildAndBundleValidation(t *testing.T) {
	d := fixture(t)
	b, e := Build(d, "test-v1", "2026-09-20T10:00:00Z", schemas)
	if e != nil {
		t.Fatal(e)
	}
	if e := ValidateBundle(b, filepath.Join(schemas, "published-bundle.schema.json")); e != nil {
		t.Fatal(e)
	}
	public, _ := json.Marshal(b.Quiz)
	if strings.Contains(string(public), "grading") || strings.Contains(string(public), "correct_option") {
		t.Fatal("public leak")
	}
	b2, e := Build(d, "test-v1", "2026-09-20T10:00:00Z", schemas)
	if e != nil || sum(b) != sum(b2) {
		t.Fatal("nondeterministic build")
	}
	for _, tc := range []struct {
		name, code string
		mutate     func(*Bundle)
	}{
		{"timestamp", "schema_invalid", func(b *Bundle) { b.PublishedAt = "tomorrow" }},
		{"bundle_hash", "bundle_hash", func(b *Bundle) { b.BundleSHA256 = strings.Repeat("0", 64) }},
		{"stale_quiz_reference", "quiz_reference", func(b *Bundle) { b.Quiz.Questions[0].QuizID = "other-quiz" }},
		{"grading_missing", "grading_coverage", func(b *Bundle) { delete(b.PrivateGrading, "question-two") }},
		{"grading_extra", "grading_coverage", func(b *Bundle) { b.PrivateGrading["extra-question"] = Grading{CorrectOptionID: "opt-one"} }},
		{"wrong_answer_with_fresh_bundle_hash", "revision_hash", func(b *Bundle) {
			b.PrivateGrading["question-two"] = Grading{CorrectOptionID: "question-two-opt-1"}
			b.BundleSHA256 = hashWithout(*b, "bundle_sha256")
		}},
		{"changed_public_with_fresh_bundle_hash", "revision_hash", func(b *Bundle) {
			b.Quiz.Questions[0].Stem = "changed"
			b.BundleSHA256 = hashWithout(*b, "bundle_sha256")
		}},
	} {
		t.Run(tc.name, func(t *testing.T) {
			data, _ := json.Marshal(b)
			var bad Bundle
			_ = json.Unmarshal(data, &bad)
			tc.mutate(&bad)
			if e := ValidateBundle(bad, filepath.Join(schemas, "published-bundle.schema.json")); Code(e) != tc.code {
				t.Fatalf("want %s got %v", tc.code, e)
			}
		})
	}
}
func TestRawSchemaPreservesUnknownFieldsAndValidates202012(t *testing.T) {
	d := fixture(t)
	data, _ := json.Marshal(d)
	for _, replacement := range []string{`"stem":"S","secret":"never-print-me"`, `"stem":17`} {
		p := filepath.Join(t.TempDir(), "draft.json")
		_ = os.WriteFile(p, []byte(strings.Replace(string(data), `"stem":"S"`, replacement, 1)), 0600)
		if _, e := ReadDocument(p, schemas); Code(e) != "schema_invalid" || strings.Contains(e.Error(), "never-print-me") || !strings.Contains(e.Error(), "/questions/0") {
			t.Fatalf("schema bypass/leak: %v", e)
		}
	}
	p := filepath.Join(t.TempDir(), "schema.json")
	_ = os.WriteFile(p, []byte(`{"$schema":"https://json-schema.org/draft/2020-12/schema","type":"array","prefixItems":[{"const":1}],"items":false}`), 0600)
	if e := ValidateSchema([]byte(`[1,2]`), p, "probe"); Code(e) != "schema_invalid" {
		t.Fatalf("2020-12 prefixItems bypass: %v", e)
	}
	if e := ValidateSchema([]byte(`[1]`), p, "probe"); e != nil {
		t.Fatal(e)
	}
	_ = os.WriteFile(p, []byte(`{`), 0600)
	if e := ValidateSchema(data, p, "probe"); Code(e) != "schema_load" {
		t.Fatalf("malformed schema: %v", e)
	}
}
func TestDuplicateQuizCollectionRejected(t *testing.T) {
	d := fixture(t)
	if e := ValidateCollection([]Draft{d, d}, schemas); Code(e) != "duplicate_id" {
		t.Fatalf("duplicate quiz accepted: %v", e)
	}
}

func TestNormalizationVectors(t *testing.T) {
	data, e := os.ReadFile("testdata/normalization.json")
	if e != nil {
		t.Fatal(e)
	}
	var vectors []struct{ Input, Expected string }
	if e = json.Unmarshal(data, &vectors); e != nil {
		t.Fatal(e)
	}
	for i, v := range vectors {
		if got := NormalizeText(v.Input); got != v.Expected {
			t.Errorf("vector %d got %q want %q", i, got, v.Expected)
		}
	}
}

func TestRawBundleSchemaNegatives(t *testing.T) {
	b, e := Build(fixture(t), "v1", "2026-09-20T10:00:00Z", schemas)
	if e != nil {
		t.Fatal(e)
	}
	for _, tc := range []struct {
		name   string
		mutate func(map[string]any)
	}{
		{"public_secret", func(m map[string]any) {
			m["quiz"].(map[string]any)["questions"].([]any)[0].(map[string]any)["grading"] = map[string]any{"correct_option_id": "secret-marker"}
		}},
		{"grading_type", func(m map[string]any) { m["private_grading"].(map[string]any)["question-two"] = 7 }},
		{"null_questions", func(m map[string]any) { m["quiz"].(map[string]any)["questions"] = nil }},
		{"date_format", func(m map[string]any) { m["published_at"] = "2026-99-99T25:00:00Z" }},
	} {
		t.Run(tc.name, func(t *testing.T) {
			data, _ := json.Marshal(b)
			var m map[string]any
			_ = json.Unmarshal(data, &m)
			tc.mutate(m)
			data, _ = json.Marshal(m)
			p := filepath.Join(t.TempDir(), "bundle.json")
			_ = os.WriteFile(p, data, 0600)
			if _, e := ReadDocument(p, schemas); Code(e) != "schema_invalid" || strings.Contains(e.Error(), "secret-marker") {
				t.Fatalf("bundle schema bypass/leak: %v", e)
			}
		})
	}
}
