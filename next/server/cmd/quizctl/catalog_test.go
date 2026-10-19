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
		"--schemas", filepath.Join("../../../..", content.DefaultSchemas), "--taxonomy", filepath.Join("../../../..", "metadata", "tags.v1.json")}, &out, &errs)
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
	if len(packs) != 105 {
		t.Fatalf("want 105 playable packs, got %d", len(packs))
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
	if total != 4520 || !ids["planet-paradoxes-20261010"] || !ids["prep-wave20-paintings"] || !ids["gastronomy-animal-products"] || !ids["prep-capitals-1"] || !ids["prep-film-actors-1"] || !ids["prep-capitals-world"] || !ids["prep-film-directors-1"] || !ids["prep-flags-world"] {
		t.Fatalf("incomplete catalog: questions=%d", total)
	}
	for _, id := range []string{"preparation-books-classic", "preparation-books-modern", "prep-musicals", "prep-ballet", "prep-opera", "prep-compositions", "prep-history-events", "prep-greek-mythology", "prep-norse-mythology", "prep-folklore", "prep-film-actors-2"} {
		if !ids[id] {
			t.Fatalf("missing preparation bank %s", id)
		}
	}
	for _, id := range []string{"cinema-people-20261011", "music-people-20261011", "pub-connections-20261014"} {
		if !ids[id] {
			t.Fatalf("missing reviewed craft bank %s", id)
		}
	}
	for _, id := range []string{"cinema-science-fiction-worlds", "theme-harry-potter", "theme-tv-series", "animation-studios-pixar-dreamworks", "theme-game-worlds"} {
		if !ids[id] {
			t.Fatalf("missing thematic bank %s", id)
		}
	}
	for source, target := range content.RoundAliases {
		if ids[source] {
			t.Fatalf("legacy alias %s exported instead of %s", source, target)
		}
		if !ids[target] {
			t.Fatalf("derived alias target %s for %s missing", target, source)
		}
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
