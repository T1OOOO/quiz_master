package main

import (
	"bytes"
	"encoding/json"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"quiz_master/next/server/internal/content"
)

func TestCatalogDifficultyCountsAreOptInAndPublicOnly(t *testing.T) {
	dir := t.TempDir()
	writeCatalogDifficultyFixture(t, dir)
	var auditReport bytes.Buffer
	if err := audit(dir, filepath.Join("../../../..", content.DefaultSchemas), &auditReport); err != nil {
		t.Fatalf("fixture rejected by audit: %v report=%s", err, &auditReport)
	}

	plain := filepath.Join(t.TempDir(), "plain.json")
	withDifficulty := filepath.Join(t.TempDir(), "difficulty.json")
	var out, errs bytes.Buffer
	schemas := filepath.Join("../../../..", content.DefaultSchemas)
	if code := run([]string{"catalog", "--in", dir, "--out", plain, "--schemas", schemas}, &out, &errs); code != 0 {
		t.Fatalf("default catalog failed: code=%d out=%s err=%s", code, &out, &errs)
	}
	if code := run([]string{"catalog", "--in", dir, "--out", withDifficulty, "--schemas", schemas, "--with-difficulty"}, &out, &errs); code != 0 {
		t.Fatalf("difficulty catalog failed: code=%d err=%s", code, &errs)
	}

	plainPacks := readCatalogPacks(t, plain)
	if len(plainPacks) != 1 || len(plainPacks[0]) != 5 || plainPacks[0]["difficulty_counts"] != nil {
		t.Fatalf("default catalog changed its five-field contract: %#v", plainPacks)
	}
	difficultyPacks := readCatalogPacks(t, withDifficulty)
	if len(difficultyPacks) != 1 || len(difficultyPacks[0]) != 6 {
		t.Fatalf("difficulty catalog shape: %#v", difficultyPacks)
	}
	counts, ok := difficultyPacks[0]["difficulty_counts"].(map[string]any)
	if !ok || len(counts) != 5 {
		t.Fatalf("difficulty counts missing: %#v", difficultyPacks)
	}
	want := map[string]float64{"easy": 1, "medium": 1, "hard": 1, "nightmare": 1, "unknown": 1}
	for band, count := range want {
		if got, ok := counts[band].(float64); !ok || got != count {
			t.Fatalf("difficulty %s=%v, want %v", band, counts[band], count)
		}
	}
	total := 0.0
	for _, value := range counts {
		total += value.(float64)
	}
	if total != difficultyPacks[0]["questions_count"].(float64) {
		t.Fatalf("difficulty total=%v questions=%v", total, difficultyPacks[0]["questions_count"])
	}
	data, err := os.ReadFile(withDifficulty)
	if err != nil {
		t.Fatal(err)
	}
	if strings.Contains(string(data), "correct_answer") || strings.Contains(string(data), "Секретный текст") || strings.Contains(string(data), "Вариант") {
		t.Fatalf("catalog leaked question or grading data: %s", data)
	}
}

func TestCatalogWithDifficultyDoesNotPublishInvalidCollection(t *testing.T) {
	dir := t.TempDir()
	if err := os.WriteFile(filepath.Join(dir, "invalid.json"), []byte(`{"id":"bad"}`), 0600); err != nil {
		t.Fatal(err)
	}
	path := filepath.Join(t.TempDir(), "catalog.json")
	var out, errs bytes.Buffer
	if code := run([]string{"catalog", "--in", dir, "--out", path, "--schemas", filepath.Join("../../../..", content.DefaultSchemas), "--with-difficulty"}, &out, &errs); code != 2 {
		t.Fatalf("invalid collection code=%d err=%s", code, &errs)
	}
	if _, err := os.Stat(path); !os.IsNotExist(err) {
		t.Fatalf("partial difficulty catalog written: %v", err)
	}
}

func readCatalogPacks(t *testing.T, path string) []map[string]any {
	t.Helper()
	data, err := os.ReadFile(path)
	if err != nil {
		t.Fatal(err)
	}
	var packs []map[string]any
	if err = json.Unmarshal(data, &packs); err != nil {
		t.Fatal(err)
	}
	return packs
}

func writeCatalogDifficultyFixture(t *testing.T, dir string) {
	t.Helper()
	questions := make([]map[string]any, 0, 5)
	for index, difficulty := range []any{1, 4, 7, 9, nil} {
		question := map[string]any{
			"id":             "catalog-difficulty-" + string(rune('a'+index)),
			"type":           "choice",
			"text":           "Секретный текст",
			"options":        []string{"Вариант один", "Вариант два", "Вариант три", "Вариант четыре"},
			"correct_answer": (index % 3) + 1,
			"explanation":    "Пояснение",
		}
		if difficulty != nil {
			question["difficulty"] = difficulty
		}
		questions = append(questions, question)
	}
	payload := map[string]any{
		"id":          "catalog-difficulty-fixture",
		"title":       "Проверка сложности",
		"description": "Только тест",
		"category":    "Тест",
		"questions":   questions,
	}
	data, err := json.Marshal(payload)
	if err != nil {
		t.Fatal(err)
	}
	if err = os.WriteFile(filepath.Join(dir, "fixture.json"), data, 0600); err != nil {
		t.Fatal(err)
	}
}
