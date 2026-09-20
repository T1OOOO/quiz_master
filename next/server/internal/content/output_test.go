package content

import (
	"os"
	"path/filepath"
	"strings"
	"sync"
	"testing"
)

func TestAtomicWritesRefuseClobberAndCleanTemporaryFiles(t *testing.T) {
	dir := t.TempDir()
	p := filepath.Join(dir, "out.json")
	if e := WriteJSON(p, map[string]string{"x": "first"}, false); e != nil {
		t.Fatal(e)
	}
	before, _ := os.ReadFile(p)
	if e := WriteJSON(p, map[string]string{"x": "second"}, false); Code(e) != "output_exists" {
		t.Fatalf("clobber: %v", e)
	}
	if data, _ := os.ReadFile(p); string(data) != string(before) {
		t.Fatal("refusal changed bytes")
	}
	if e := WriteJSON(p, map[string]string{"x": "second"}, true); e != nil {
		t.Fatal(e)
	}
	if data, _ := os.ReadFile(p); string(data) != "{\"x\":\"second\"}\n" {
		t.Fatal("force did not replace atomically")
	}
	if e := WriteJSON(p, make(chan int), true); Code(e) != "encode" {
		t.Fatalf("expected encode error: %v", e)
	}
	entries, _ := os.ReadDir(dir)
	if len(entries) != 1 {
		t.Fatal("temporary file leaked")
	}
}

func TestConcurrentWritersNeverClobber(t *testing.T) {
	p := filepath.Join(t.TempDir(), "out.json")
	var wg sync.WaitGroup
	results := make(chan error, 8)
	for i := 0; i < 8; i++ {
		wg.Add(1)
		go func(i int) { defer wg.Done(); results <- WriteJSON(p, map[string]int{"writer": i}, false) }(i)
	}
	wg.Wait()
	close(results)
	successes := 0
	for e := range results {
		if e == nil {
			successes++
		} else if Code(e) != "output_exists" && Code(e) != "output_busy" {
			t.Fatal(e)
		}
	}
	if successes != 1 {
		t.Fatalf("successful writers=%d, want exactly one", successes)
	}
	entries, _ := os.ReadDir(filepath.Dir(p))
	if len(entries) != 1 {
		t.Fatal("temporary or lock leak")
	}
}
func TestOutputDestinationTraversalAndLinks(t *testing.T) {
	dir := t.TempDir()
	if e := WriteJSON(dir+"/nested/../outside.json", map[string]string{}, false); Code(e) != "output_path" {
		t.Fatalf("accepted file traversal: %v", e)
	}
	for _, name := range []string{"../outside.json", `..\outside.json`, "/absolute.json", `C:\absolute.json`, "a/b.json", "a:b.json", ".", ".."} {
		if e := WriteFiles(dir, map[string]any{name: map[string]string{}}, false); Code(e) != "output_path" {
			t.Fatalf("accepted unsafe destination %q: %v", name, e)
		}
	}
	outside := t.TempDir()
	link := filepath.Join(dir, "linked")
	if e := os.Symlink(outside, link); e == nil {
		if e = WriteJSON(filepath.Join(link, "out.json"), map[string]string{}, false); Code(e) != "output_path" {
			t.Fatalf("followed symlink: %v", e)
		}
	}
}
func TestImportOutputsPreflightTogether(t *testing.T) {
	dir := t.TempDir()
	p := filepath.Join(dir, "manifest.json")
	_ = os.WriteFile(p, []byte("original"), 0600)
	if e := WriteFiles(dir, map[string]any{"draft.json": map[string]string{}, "manifest.json": map[string]string{}}, false); Code(e) != "output_exists" {
		t.Fatalf("expected preflight refusal: %v", e)
	}
	if _, e := os.Stat(filepath.Join(dir, "draft.json")); !os.IsNotExist(e) {
		t.Fatal("partial import written")
	}
	files, _ := os.ReadDir(dir)
	for _, f := range files {
		if strings.HasPrefix(f.Name(), ".quizctl") {
			t.Fatal("temporary leak")
		}
	}
}
