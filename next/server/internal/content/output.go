package content

import (
	"encoding/json"
	"os"
	"path/filepath"
	"sort"
	"strings"
)

func safeDestination(dir string) error {
	if dir == "" {
		return &Error{"output_path", dir}
	}
	for _, part := range strings.FieldsFunc(dir, func(r rune) bool { return r == '/' || r == '\\' }) {
		if part == ".." {
			return &Error{"output_path", dir}
		}
	}
	absolute, e := filepath.Abs(dir)
	if e != nil {
		return &Error{"output_path", dir}
	}
	for p := absolute; ; p = filepath.Dir(p) {
		info, e := os.Lstat(p)
		if e == nil && (info.Mode()&os.ModeSymlink != 0 || !info.IsDir()) {
			return &Error{"output_path", dir}
		}
		if e != nil && !os.IsNotExist(e) {
			return &Error{"output_path", dir}
		}
		if filepath.Dir(p) == p {
			break
		}
	}
	return nil
}

func WriteJSON(path string, value any, force bool) error {
	if path == "" {
		return &Error{"output_path", path}
	}
	// Check the caller's spelling before filepath.Dir can clean away traversal.
	for _, part := range strings.FieldsFunc(path, func(r rune) bool { return r == '/' || r == '\\' }) {
		if part == ".." {
			return &Error{"output_path", path}
		}
	}
	return WriteFiles(filepath.Dir(path), map[string]any{filepath.Base(path): value}, force)
}

// WriteFiles validates and stages the entire set before publishing any file.
// Each file is published with an atomic sibling move; competing quizctl writers
// are excluded. Existing files are retained on ordinary staging/preflight errors.
// A process/power failure between final moves can leave a mixed pair; consumers
// must validate the draft and manifest source hash before treating them as a pack.
func WriteFiles(dir string, values map[string]any, force bool) error {
	if e := safeDestination(dir); e != nil {
		return e
	}
	names := make([]string, 0, len(values))
	encoded := map[string][]byte{}
	for name, v := range values {
		if name == "" || name == "." || name == ".." || strings.ContainsAny(name, "/\\:") || strings.HasPrefix(name, ".quizctl") || strings.TrimRight(name, " .") != name {
			return &Error{"output_path", name}
		}
		b, e := Canonical(v)
		if e != nil {
			return &Error{"encode", filepath.Join(dir, name)}
		}
		encoded[name] = append(b, '\n')
		names = append(names, name)
	}
	sort.Strings(names)
	if e := os.MkdirAll(dir, 0700); e != nil {
		return &Error{"write", dir}
	}
	lockPath := filepath.Join(dir, ".quizctl-lock")
	lock, e := os.OpenFile(lockPath, os.O_WRONLY|os.O_CREATE|os.O_EXCL, 0600)
	if e != nil {
		return &Error{"output_busy", dir}
	}
	_ = lock.Close()
	defer os.Remove(lockPath)
	if incoming, ok := values["manifest.json"].(Manifest); ok {
		p := filepath.Join(dir, "manifest.json")
		if info, err := os.Lstat(p); err == nil {
			if !info.Mode().IsRegular() {
				return &Error{"output_path", p}
			}
			data, err := os.ReadFile(p)
			var previous Manifest
			if err != nil || json.Unmarshal(data, &previous) != nil || previous.MappingVersion != "legacy-choice/v1" {
				return &Error{"manifest_invalid", p}
			}
			if previous.CanonicalQuizID == incoming.CanonicalQuizID {
				if previous.SourceQuizID != incoming.SourceQuizID {
					return &Error{"id_collision", p}
				}
				a, _ := filepath.Abs(previous.SourcePath)
				b, _ := filepath.Abs(incoming.SourcePath)
				if !strings.EqualFold(a, b) {
					return &Error{"duplicate_id", p}
				}
			}
		}
	}
	old := map[string][]byte{}
	for _, name := range names {
		p := filepath.Join(dir, name)
		info, e := os.Lstat(p)
		if e == nil {
			if !info.Mode().IsRegular() {
				return &Error{"output_path", p}
			}
			if !force {
				return &Error{"output_exists", p}
			}
			data, e := os.ReadFile(p)
			if e != nil {
				return &Error{"read", p}
			}
			old[name] = data
		} else if !os.IsNotExist(e) {
			return &Error{"write", p}
		}
	}
	staged := map[string]string{}
	defer func() {
		for _, p := range staged {
			_ = os.Remove(p)
		}
	}()
	for _, name := range names {
		p, e := stage(dir, encoded[name])
		if e != nil {
			return &Error{"write", filepath.Join(dir, name)}
		}
		staged[name] = p
	}
	committed := []string{}
	for _, name := range names {
		p := filepath.Join(dir, name)
		if e := publishFile(staged[name], p, force); e != nil {
			// Roll back a reported commit error; do not silently claim a successful set.
			for _, done := range committed {
				target := filepath.Join(dir, done)
				if previous, ok := old[done]; ok {
					temp, err := stage(dir, previous)
					if err != nil {
						return &Error{"rollback_failed", target}
					}
					err = publishFile(temp, target, true)
					_ = os.Remove(temp)
					if err != nil {
						return &Error{"rollback_failed", target}
					}
				} else if err := os.Remove(target); err != nil {
					return &Error{"rollback_failed", target}
				}
			}
			if os.IsExist(e) {
				return &Error{"output_exists", p}
			}
			return &Error{"write", p}
		}
		committed = append(committed, name)
	}
	return nil
}
func stage(dir string, b []byte) (string, error) {
	f, e := os.CreateTemp(dir, ".quizctl-*")
	if e != nil {
		return "", e
	}
	name := f.Name()
	if _, e = f.Write(b); e == nil {
		e = f.Sync()
	}
	closeErr := f.Close()
	if e == nil {
		e = closeErr
	}
	if e != nil {
		_ = os.Remove(name)
		return "", e
	}
	return name, nil
}
