package main

import (
	"bytes"
	"encoding/json"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strings"
	"testing"

	"quiz_master/next/server/internal/content"
)

func TestCLIEndToEnd(t *testing.T) {
	root, e := filepath.Abs("../../../..")
	if e != nil {
		t.Fatal(e)
	}
	dir := t.TempDir()
	binary := filepath.Join(dir, "quizctl")
	if runtime.GOOS == "windows" {
		binary += ".exe"
	}
	build := exec.Command("go", "build", "-o", binary, "./next/server/cmd/quizctl")
	build.Dir = root
	if out, e := build.CombinedOutput(); e != nil {
		t.Fatalf("build: %v %s", e, out)
	}
	invoke := func(want int, args ...string) string {
		t.Helper()
		cmd := exec.Command(binary, args...)
		cmd.Dir = root
		out, e := cmd.CombinedOutput()
		code := 0
		if e != nil {
			exit, ok := e.(*exec.ExitError)
			if !ok {
				t.Fatal(e)
			}
			code = exit.ExitCode()
		}
		if code != want {
			t.Fatalf("%v exit=%d want=%d output=%s", args, code, want, out)
		}
		return string(out)
	}
	source := "quizzes/Cinema/HomeAlone/home_alone_1_part_1.json"
	for _, name := range []string{"one", "two"} {
		dest := filepath.Join(dir, name)
		invoke(0, "import", "--in", source, "--out", dest)
		invoke(0, "validate", "--in", filepath.Join(dest, "draft.json"))
		invoke(0, "build", "--in", filepath.Join(dest, "draft.json"), "--out", filepath.Join(dest, "bundle.json"), "--version", "2026.09.20.p08", "--published-at", "2026-09-20T10:00:00Z")
		invoke(0, "validate", "--in", filepath.Join(dest, "bundle.json"))
	}
	for _, name := range []string{"draft.json", "manifest.json", "bundle.json"} {
		a, _ := os.ReadFile(filepath.Join(dir, "one", name))
		b, _ := os.ReadFile(filepath.Join(dir, "two", name))
		if !bytes.Equal(a, b) {
			t.Fatalf("nonidentical %s", name)
		}
	}
	before := filepath.Join(dir, "one", "bundle.json")
	after := filepath.Join(dir, "two", "bundle.json")
	if got := invoke(0, "diff", "--before", before, "--after", after); strings.TrimSpace(got) != "no changes" {
		t.Fatalf("unexpected equal diff: %s", got)
	}
	schemaDir := filepath.Join(root, content.DefaultSchemas)
	doc, e := content.ReadDocument(filepath.Join(dir, "one", "draft.json"), schemaDir)
	if e != nil {
		t.Fatal(e)
	}
	if len(doc.Draft.Questions) != 25 {
		t.Fatal("lost questions")
	}
	doc.Draft.Questions[0].Stem += " (controlled mutation)"
	doc.Draft.Questions[0].Revision.Number++
	doc.Draft.Revision.Number++
	content.Rehash(&doc.Draft)
	mutation := filepath.Join(dir, "changed.json")
	if e = content.WriteJSON(mutation, doc.Draft, false); e != nil {
		t.Fatal(e)
	}
	invoke(0, "build", "--in", mutation, "--out", after, "--force", "--version", "2026.09.20.p08", "--published-at", "2026-09-20T10:00:00Z")
	diff := invoke(1, "diff", "--before", before, "--after", after)
	if !strings.Contains(diff, "question changed: q-ha1-p1-1") || strings.Contains(diff, "correct_option") || strings.Contains(diff, "Кевин") {
		t.Fatalf("bad/leaking diff: %s", diff)
	}
	invoke(2, "import", "--in", source, "--out", filepath.Join(dir, "one"))
	invoke(0, "import", "--in", source, "--out", filepath.Join(dir, "one"), "--force")
	// Force may update the same source; it must never hide an ID collision.
	sourceBytes, _ := os.ReadFile(filepath.Join(root, source))
	collision := filepath.Join(dir, "collision.json")
	_ = os.WriteFile(collision, []byte(strings.Replace(string(sourceBytes), "home_alone_1_part_1", "HOME-ALONE-1-PART-1", 1)), 0600)
	if got := invoke(2, "import", "--in", collision, "--out", filepath.Join(dir, "one"), "--force"); !strings.Contains(got, "id_collision") {
		t.Fatal(got)
	}
	invoke(2, "build", "--in", mutation, "--out", after, "--version", "v2", "--published-at", "invalid")
	invoke(2, "build", "--in", mutation, "--out", mutation, "--version", "v2", "--published-at", "2026-09-20T10:00:00Z", "--force")
	invoke(2, "validate", "--in", mutation, mutation)
	invoke(2, "diff", "--before", before)
	invoke(2, "import", "--in", source, "--out", filepath.Join(dir, "one"), "unexpected")
	invoke(2, "unknown")
	// Unknown fields must be rejected before decoding strips them.
	data, _ := os.ReadFile(mutation)
	var raw map[string]any
	_ = json.Unmarshal(data, &raw)
	raw["secret"] = true
	data, _ = json.Marshal(raw)
	invalid := filepath.Join(dir, "invalid.json")
	_ = os.WriteFile(invalid, data, 0600)
	if out := invoke(2, "validate", "--in", invalid); !strings.Contains(out, "schema_invalid") {
		t.Fatal(out)
	}
}
