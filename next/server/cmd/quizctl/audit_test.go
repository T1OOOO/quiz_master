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

func TestAuditReportsEveryFileWithoutPublishing(t *testing.T) {
	dir := t.TempDir()
	source, err := os.ReadFile("../../../../quizzes/Cinema/HomeAlone/home_alone_1_part_1.json")
	if err != nil {
		t.Fatal(err)
	}
	for name, data := range map[string][]byte{"a.json": source, "b.json": source, "c.json": []byte(`{}`)} {
		if err := os.WriteFile(filepath.Join(dir, name), data, 0600); err != nil {
			t.Fatal(err)
		}
	}
	var out, errs bytes.Buffer
	code := run([]string{"audit", "--in", dir, "--schemas", filepath.Join("../../../..", content.DefaultSchemas)}, &out, &errs)
	if code != 2 || out.Len() == 0 {
		t.Fatalf("want full blocked report, code=%d out=%s err=%s", code, &out, &errs)
	}
	var report struct {
		Files     int `json:"files"`
		Questions int `json:"questions"`
		Ready     int `json:"ready"`
		Blocked   int `json:"blocked"`
		Packs     []struct {
			Path  string `json:"path"`
			Error string `json:"error"`
		} `json:"packs"`
	}
	if err := json.Unmarshal(out.Bytes(), &report); err != nil {
		t.Fatal(err)
	}
	if report.Files != 3 || report.Questions != 50 || report.Ready != 0 || report.Blocked != 3 || len(report.Packs) != 3 {
		t.Fatalf("incomplete report: %+v", report)
	}
	for _, p := range report.Packs[:2] {
		if !strings.Contains(p.Error, "duplicate_id") {
			t.Fatalf("both colliding packs must be blocked: %+v", p)
		}
	}
	if !strings.Contains(report.Packs[2].Error, "required") {
		t.Fatal(report.Packs[2])
	}
	if strings.Contains(out.String(), "correct_option") || strings.Contains(out.String(), "source_explanation") {
		t.Fatal("private grading leaked")
	}
	entries, _ := os.ReadDir(dir)
	if len(entries) != 3 {
		t.Fatal("audit wrote into the input directory")
	}
	// Remove the two invalid entries: the same real pack must now pass.
	for _, name := range []string{"b.json", "c.json"} {
		if err := os.Remove(filepath.Join(dir, name)); err != nil {
			t.Fatal(err)
		}
	}
	out.Reset()
	errs.Reset()
	if code := run([]string{"audit", "--in", dir, "--schemas", filepath.Join("../../../..", content.DefaultSchemas)}, &out, &errs); code != 0 {
		t.Fatalf("valid pack rejected: %s", &errs)
	}
	if err := json.Unmarshal(out.Bytes(), &report); err != nil {
		t.Fatal(err)
	}
	if report.Files != 1 || report.Ready != 1 || report.Blocked != 0 || report.Questions != 25 {
		t.Fatalf("wrong valid totals: %+v", report)
	}
}

func TestAuditRejectsEmptyOrMissingDirectory(t *testing.T) {
	for _, path := range []string{t.TempDir(), filepath.Join(t.TempDir(), "missing")} {
		var out, errs bytes.Buffer
		if run([]string{"audit", "--in", path}, &out, &errs) != 2 {
			t.Fatal("empty/missing collection accepted")
		}
	}
}
