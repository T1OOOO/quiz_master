package attempts

import (
	"context"
	"encoding/json"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"

	"quiz_master/next/server/internal/content"
)

func TestControlledBundleFailsClosedBeforeDatabaseAccess(t *testing.T) {
	raw, err := os.ReadFile("../../../content/home-alone-1-part-1/bundle.json")
	if err != nil {
		t.Fatal(err)
	}
	for name, data := range map[string][]byte{
		"unknown":                append([]byte(`{"unknown":true,`), raw[1:]...),
		"duplicate":              append([]byte(`{"contract":"quiz-contract/v1",`), raw[1:]...),
		"trailing":               append(append([]byte(nil), raw...), []byte(`{}`)...),
		"wrong hash":             []byte(strings.Replace(string(raw), "6c7754aa9b142d8657bac1bb65f0536d30364d262ef109315c4b9356ee512b95", strings.Repeat("0", 64), 1)),
		"wrong private revision": []byte(strings.Replace(string(raw), `"correct_option_id":"q-ha1-p1-1-opt-1"`, `"correct_option_id":"q-ha1-p1-1-opt-2"`, 1)),
	} {
		t.Run(name, func(t *testing.T) {
			path := filepath.Join(t.TempDir(), "bundle.json")
			if err := os.WriteFile(path, data, 0600); err != nil {
				t.Fatal(err)
			}
			if _, err := NewService(context.Background(), nil, path, "../../../contracts/quiz-contract/v1/schemas", 30*time.Minute, Options{}); err == nil {
				t.Fatal("invalid controlled bundle accepted")
			}
		})
	}
	if _, err := NewService(context.Background(), nil, "../../../content/home-alone-1-part-1/draft.json", "../../../contracts/quiz-contract/v1/schemas", 30*time.Minute, Options{}); err == nil {
		t.Fatal("private draft used as bundle")
	}
}

func TestManifestMustExactlyCoverControlledBundle(t *testing.T) {
	doc, err := content.ReadDocument("../../../content/home-alone-1-part-1/bundle.json", "../../../contracts/quiz-contract/v1/schemas")
	if err != nil {
		t.Fatal(err)
	}
	raw, err := os.ReadFile("../../../content/home-alone-1-part-1/manifest.json")
	if err != nil {
		t.Fatal(err)
	}
	var original content.Manifest
	if err = json.Unmarshal(raw, &original); err != nil {
		t.Fatal(err)
	}
	valid := filepath.Join(t.TempDir(), "manifest.json")
	if err = os.WriteFile(valid, raw, 0600); err != nil {
		t.Fatal(err)
	}
	manifest, err := loadManifest(valid, *doc.Bundle)
	if err != nil || len(manifest.Explanations) != len(doc.Bundle.Quiz.Questions) {
		t.Fatalf("valid manifest: count=%d err=%v", len(manifest.Explanations), err)
	}
	if manifest.Explanations[original.Questions[0].CanonicalID] != original.Questions[0].Explanation {
		t.Fatal("manifest explanation was not retained unchanged")
	}
	if manifest.SHA256 != "93af5f22c9d4d570335a37aa6419d4b613e239d149293a6811f753d5e5f132d5" {
		t.Fatalf("manifest exact-byte SHA-256 = %q", manifest.SHA256)
	}
	changed := original
	changed.Questions = append([]content.QuestionMap(nil), original.Questions...)
	changed.Questions[0].Explanation += " changed"
	changedRaw, err := json.Marshal(changed)
	if err != nil {
		t.Fatal(err)
	}
	changedPath := filepath.Join(t.TempDir(), "manifest.json")
	if err = os.WriteFile(changedPath, changedRaw, 0600); err != nil {
		t.Fatal(err)
	}
	changedManifest, err := loadManifest(changedPath, *doc.Bundle)
	if err != nil {
		t.Fatal(err)
	}
	if changedManifest.SHA256 == manifest.SHA256 {
		t.Fatal("explanation-only manifest change retained the same digest")
	}

	for name, mutate := range map[string]func(*content.Manifest){
		"quiz mismatch":      func(m *content.Manifest) { m.CanonicalQuizID = "different-quiz" },
		"missing question":   func(m *content.Manifest) { m.Questions = m.Questions[:len(m.Questions)-1] },
		"duplicate question": func(m *content.Manifest) { m.Questions[1].CanonicalID = m.Questions[0].CanonicalID },
		"unknown question":   func(m *content.Manifest) { m.Questions[0].CanonicalID = "question-not-in-bundle" },
		"blank explanation":  func(m *content.Manifest) { m.Questions[0].Explanation = " \t" },
	} {
		t.Run(name, func(t *testing.T) {
			var m content.Manifest
			if err := json.Unmarshal(raw, &m); err != nil {
				t.Fatal(err)
			}
			mutate(&m)
			data, err := json.Marshal(m)
			if err != nil {
				t.Fatal(err)
			}
			path := filepath.Join(t.TempDir(), "manifest.json")
			if err = os.WriteFile(path, data, 0600); err != nil {
				t.Fatal(err)
			}
			if _, err = loadManifest(path, *doc.Bundle); err == nil {
				t.Fatal("mismatched manifest accepted")
			}
		})
	}
}
