package main

import (
	"bytes"
	"encoding/json"
	"path/filepath"
	"strings"
	"testing"

	"quiz_master/next/server/internal/content"
)

func TestSourceCorpusHasDistinctAnswerLabels(t *testing.T) {
	var out bytes.Buffer
	taxonomy, err := content.LoadTaxonomy(filepath.Join("../../../..", "metadata", "tags.v1.json"))
	if err != nil {
		t.Fatal(err)
	}
	if err := auditWithTaxonomy("../../../../quizzes", filepath.Join("../../../..", content.DefaultSchemas), taxonomy, &out); err != nil {
		t.Fatal(err)
	}
	var report struct{ Packs []auditPack }
	if err := json.Unmarshal(out.Bytes(), &report); err != nil {
		t.Fatal(err)
	}
	want := map[string]string{"q-philias-100-54": "Ольфактофилия", "q-philias-100-59": "Эритрофилия", "q-phobias-part-8-20": "Пирофобия", "cinema-people-017": "Pinewood Studios", "music-people-017": "Миниатюрный динамик для подушки"}
	for _, pack := range report.Packs {
		draft, _, err := content.ImportWithTaxonomy(pack.Path, taxonomy)
		if err != nil {
			t.Fatal(err)
		}
		for _, q := range draft.Questions {
			seen := map[string]bool{}
			for _, option := range q.Options {
				label := strings.ToLower(strings.TrimSpace(option.Text))
				if seen[label] {
					t.Errorf("%s/%s: duplicate answer label %q", draft.QuizID, q.QuestionID, option.Text)
				}
				seen[label] = true
				if answer, ok := want[q.QuestionID]; ok && option.OptionID == q.Grading.CorrectOptionID {
					if option.Text != answer {
						t.Errorf("%s: migrated answer changed to %q", q.QuestionID, option.Text)
					}
					delete(want, q.QuestionID)
				}
			}
		}
	}
	if len(want) != 0 {
		t.Fatalf("missing repaired answer fixtures: %v", want)
	}
}
