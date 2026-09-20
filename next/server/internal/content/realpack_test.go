package content

import (
	"bytes"
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
	if m.SourceSHA256 != "35a3e9f1aeb415d1e20d7ef913a493bfe8bbef2eb145ebc2079a29ebc725ed9a" {
		t.Fatal("selected legacy source changed")
	}
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
	for name, value := range map[string]any{"draft.json": d, "manifest.json": m, "bundle.json": b} {
		want, e := os.ReadFile(filepath.Join(pack, name))
		if e != nil {
			t.Fatal(e)
		}
		got, _ := Canonical(value)
		got = append(got, '\n')
		if !bytes.Equal(got, want) {
			t.Errorf("checked-in %s is not reproducible", name)
		}
	}
	if b.BundleSHA256 != "6c7754aa9b142d8657bac1bb65f0536d30364d262ef109315c4b9356ee512b95" {
		t.Fatal("real bundle hash changed")
	}
}
