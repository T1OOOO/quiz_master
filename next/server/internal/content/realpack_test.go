package content

import (
	"encoding/json"
	"os"
	"path/filepath"
	"testing"
)

func TestCheckedInRealPackCompleteAndReproducible(t *testing.T) {
	root := "../../../.."
	source := "quizzes/Cinema/HomeAlone/home_alone_1_part_1.json"
	// Import uses a stable repository-relative provenance URI in the artifacts.
	// Chdir is deliberately avoided: make a local copy of the imported URI only.
	d, m, e := Import(filepath.Join(root, source))
	if e != nil {
		t.Fatal(e)
	}
	m.SourcePath = source
	for i := range d.Questions {
		d.Questions[i].Source["uri"] = source
	}
	Rehash(&d)
	pack := filepath.Join(root, "next/content/home-alone-1-part-1")
	b, e := Build(d, "2026.09.20.p08", "2026-09-20T10:00:00Z", schemas)
	if e != nil {
		t.Fatal(e)
	}
	if len(d.Questions) != 25 || len(m.Questions) != 25 || len(b.PrivateGrading) != 25 {
		t.Fatal("incomplete real pack")
	}
	data, _ := os.ReadFile(filepath.Join(root, source))
	var raw struct {
		Questions []struct {
			ID          string   `json:"id"`
			Text        string   `json:"text"`
			Options     []string `json:"options"`
			Answer      int      `json:"correct_answer"`
			Explanation string   `json:"explanation"`
		}
	}
	if e = json.Unmarshal(data, &raw); e != nil {
		t.Fatal(e)
	}
	seen := map[string]bool{}
	for i, q := range raw.Questions {
		mapped := m.Questions[i]
		canonical := d.Questions[i]
		if seen[mapped.SourceID] || mapped.SourceID != q.ID || mapped.CanonicalID != canonical.QuestionID || mapped.Explanation != q.Explanation || canonical.Stem != q.Text {
			t.Fatalf("lost or duplicate mapping %d", i)
		}
		seen[mapped.SourceID] = true
		if len(mapped.Options) != len(q.Options) {
			t.Fatal("incomplete option mapping")
		}
		for index, option := range mapped.Options {
			if option.SourceIndex != index || canonical.Options[index].OptionID != option.CanonicalID || canonical.Options[index].Text != q.Options[index] {
				t.Fatal("option mismatch")
			}
		}
		if canonical.Grading.CorrectOptionID != mapped.Options[q.Answer].CanonicalID {
			t.Fatalf("answer index mapping wrong at %d", i)
		}
	}
	// New difficulty/tag annotations create a new revision. Historical controlled
	// bundle bytes remain readable and must never be rewritten by source import.
	archived, e := ReadDocument(filepath.Join(pack, "bundle.json"), schemas)
	if e != nil || archived.Bundle == nil {
		t.Fatalf("historical bundle unreadable: %v", e)
	}
	if archived.Bundle.BundleSHA256 == b.BundleSHA256 {
		t.Fatal("annotated source reused historical bundle identity")
	}
}
