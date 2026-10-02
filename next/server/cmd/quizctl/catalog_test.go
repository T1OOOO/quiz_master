package main

import (
	"bytes"
	"encoding/json"
	"os"
	"path/filepath"
	"testing"

	"quiz_master/next/server/internal/content"
)

// Catches missing packs, ID collisions and accidentally exporting private data.
func TestCatalogExportsWholeCorpusAsMetadataOnly(t *testing.T) {
	path := filepath.Join(t.TempDir(), "catalog.json")
	var out, errs bytes.Buffer
	code := run([]string{"catalog", "--in", "../../../../quizzes", "--out", path,
		"--schemas", filepath.Join("../../../..", content.DefaultSchemas)}, &out, &errs)
	if code != 0 {
		t.Fatalf("catalog failed: code=%d err=%s", code, &errs)
	}
	data, err := os.ReadFile(path)
	if err != nil {
		t.Fatal(err)
	}
	var packs []map[string]any
	if err := json.Unmarshal(data, &packs); err != nil {
		t.Fatal(err)
	}
	if len(packs) != 101 {
		t.Fatalf("want 101 packs, got %d", len(packs))
	}
	allowed := map[string]bool{"quiz_id": true, "title": true, "description": true, "category": true, "questions_count": true}
	ids := map[string]bool{}
	total := 0
	for _, pack := range packs {
		if len(pack) != 5 {
			t.Fatalf("unexpected metadata fields: %v", pack)
		}
		for key := range pack {
			if !allowed[key] {
				t.Fatalf("private/unexpected field %s", key)
			}
		}
		id, ok := pack["quiz_id"].(string)
		if !ok || id == "" || ids[id] {
			t.Fatalf("invalid/duplicate ID: %v", id)
		}
		ids[id] = true
		total += int(pack["questions_count"].(float64))
	}
	if total != 3128 || !ids["gastronomy-cheeses-and-dairy"] {
		t.Fatalf("incomplete catalog: questions=%d", total)
	}
}

func TestCatalogDoesNotPublishPartialInvalidCollection(t *testing.T) {
	dir := t.TempDir()
	if err := os.WriteFile(filepath.Join(dir, "bad.json"), []byte(`{}`), 0600); err != nil {
		t.Fatal(err)
	}
	path := filepath.Join(t.TempDir(), "catalog.json")
	var out, errs bytes.Buffer
	if run([]string{"catalog", "--in", dir, "--out", path,
		"--schemas", filepath.Join("../../../..", content.DefaultSchemas)}, &out, &errs) != 2 {
		t.Fatal("invalid catalog accepted")
	}
	if _, err := os.Stat(path); !os.IsNotExist(err) {
		t.Fatal("partial catalog published")
	}
}
