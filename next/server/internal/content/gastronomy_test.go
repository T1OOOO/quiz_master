package content

import (
	"encoding/json"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestGastronomyMigrationPreservesDistinctLegacyIdentityAndAnswers(t *testing.T) {
	seen := map[string]bool{}
	count := 0
	for _, name := range []string{"cheeses_and_dairy", "cooking_techniques", "drinks_and_alcohol", "fruits_and_vegetables", "meat_and_fish", "spices_and_ingredients", "sweets_and_desserts", "traditions_and_etiquette"} {
		path := filepath.Join("../../../..", "quizzes/Gastronomy/gastronomy_"+name+".json")
		data, err := os.ReadFile(path)
		if err != nil {
			t.Fatal(err)
		}
		var raw struct {
			ID        string `json:"id"`
			Questions []struct {
				ID          string   `json:"id"`
				Text        string   `json:"text"`
				Options     []string `json:"options"`
				Answer      int      `json:"correct_answer"`
				Explanation string   `json:"explanation"`
			} `json:"questions"`
		}
		if err := json.Unmarshal(data, &raw); err != nil {
			t.Fatal(err)
		}
		draft, manifest, err := Import(path)
		if err != nil {
			t.Fatal(err)
		}
		if draft.QuizID != "gastronomy-"+strings.ReplaceAll(name, "_", "-") || seen[draft.QuizID] {
			t.Fatalf("legacy packs collapse: %s -> %s", raw.ID, draft.QuizID)
		}
		seen[draft.QuizID] = true
		if manifest.MappingVersion != "legacy-choice/v2" || manifest.SourceQuizID != raw.ID || manifest.CanonicalQuizID != draft.QuizID || len(draft.Questions) != len(raw.Questions) || len(manifest.Questions) != len(raw.Questions) {
			t.Fatal("identity/questions lost")
		}
		if err := ValidateDraft(draft, filepath.Join(schemas, "draft-quiz.schema.json")); err != nil {
			t.Fatal(err)
		}
		for i, q := range raw.Questions {
			got, mapping := draft.Questions[i], manifest.Questions[i]
			if mapping.SourceID != q.ID || mapping.CanonicalID != got.QuestionID || got.Stem != q.Text || mapping.Explanation != q.Explanation || len(got.Options) != len(q.Options) {
				t.Fatalf("question changed at %s #%d", name, i)
			}
			for j, option := range q.Options {
				if got.Options[j].Text != option || mapping.Options[j].SourceIndex != j || mapping.Options[j].CanonicalID != got.Options[j].OptionID {
					t.Fatal("option changed")
				}
			}
			if got.Grading.CorrectOptionID != got.Options[q.Answer].OptionID {
				t.Fatalf("wrong answer at %s #%d", name, i)
			}
		}
		count += len(raw.Questions)
		dest := t.TempDir()
		values := map[string]any{"draft.json": draft, "manifest.json": manifest}
		if err := WriteFiles(dest, values, false); err != nil {
			t.Fatal(err)
		}
		if err := WriteFiles(dest, values, true); err != nil {
			t.Fatal("mapped manifest cannot be reused:", err)
		}
	}
	if count != 221 {
		t.Fatalf("want 221 preserved questions, got %d", count)
	}
}
