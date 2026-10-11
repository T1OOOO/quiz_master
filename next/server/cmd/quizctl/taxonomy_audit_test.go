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

const frozenTaxonomySHA256 = "07e4bbb5c7afcdab3b41a26dca1bf0ba9a830d5f776a98ebceeaeb2bd8356151"

func writeAnnotatedSource(t *testing.T, dir, tag string) string {
	t.Helper()
	source := map[string]any{
		"id":           "annotated-audit",
		"title":        "Annotated audit fixture",
		"description":  "Exercises the frozen taxonomy path.",
		"category":     "Tests",
		"taxonomy_ref": map[string]any{"taxonomy_id": "qm-tags-v1", "taxonomy_sha256": frozenTaxonomySHA256},
		"questions": []any{map[string]any{
			"id": "annotated-audit-001", "text": "Which option is correct?", "options": []string{"zero", "one", "two", "three"},
			"correct_answer": 1, "explanation": "The nonzero option is correct.", "type": "choice", "difficulty": 4,
			"editorial_tag_ids": []string{tag}, "context_tag_ids": []string{},
		}},
	}
	data, err := json.Marshal(source)
	if err != nil {
		t.Fatal(err)
	}
	path := filepath.Join(dir, "annotated.json")
	if err := os.WriteFile(path, data, 0600); err != nil {
		t.Fatal(err)
	}
	return path
}

func TestAuditAndCatalogHonorExplicitFrozenTaxonomy(t *testing.T) {
	dir := t.TempDir()
	writeAnnotatedSource(t, dir, "domain:arts")
	taxonomy := filepath.Join("..", "..", "..", "..", "metadata", "tags.v1.json")
	schemas := filepath.Join("..", "..", "..", "..", content.DefaultSchemas)

	var out, errs bytes.Buffer
	if code := run([]string{"audit", "--taxonomy", taxonomy, "--schemas", schemas, "--in", dir}, &out, &errs); code != 0 {
		t.Fatalf("annotated audit with explicit frozen taxonomy failed: code=%d out=%s err=%s", code, &out, &errs)
	}
	var report struct {
		Ready, Blocked int
	}
	if err := json.Unmarshal(out.Bytes(), &report); err != nil || report.Ready != 1 || report.Blocked != 0 {
		t.Fatalf("annotated audit report = %+v, err=%v", report, err)
	}

	catalog := filepath.Join(t.TempDir(), "catalog.json")
	out.Reset()
	errs.Reset()
	if code := run([]string{"catalog", "--taxonomy", taxonomy, "--schemas", schemas, "--in", dir, "--out", catalog}, &out, &errs); code != 0 {
		t.Fatalf("annotated catalog with explicit frozen taxonomy failed: code=%d out=%s err=%s", code, &out, &errs)
	}
	data, err := os.ReadFile(catalog)
	if err != nil {
		t.Fatal(err)
	}
	if strings.Contains(string(data), "editorial_tag_ids") || strings.Contains(string(data), "correct_option") || strings.Contains(string(data), "domain:arts") {
		t.Fatalf("catalog leaked private metadata: %s", data)
	}

	for _, args := range [][]string{
		{"audit", "--schemas", schemas, "--in", dir},
		{"audit", "--taxonomy", filepath.Join(dir, "missing.json"), "--schemas", schemas, "--in", dir},
	} {
		out.Reset()
		errs.Reset()
		if code := run(args, &out, &errs); code != 2 {
			t.Fatalf("%v exit=%d want 2", args, code)
		}
	}

	writeAnnotatedSource(t, dir, "topic:not-in-frozen-taxonomy")
	if err := os.WriteFile(catalog, []byte("sentinel"), 0600); err != nil {
		t.Fatal(err)
	}
	out.Reset()
	errs.Reset()
	if code := run([]string{"catalog", "--taxonomy", taxonomy, "--schemas", schemas, "--in", dir, "--out", catalog, "--force"}, &out, &errs); code != 2 {
		t.Fatalf("unknown tag catalog exit=%d want 2", code)
	}
	if data, err := os.ReadFile(catalog); err != nil || string(data) != "sentinel" {
		t.Fatalf("catalog overwrite after rejected taxonomy: %q err=%v", data, err)
	}
}
