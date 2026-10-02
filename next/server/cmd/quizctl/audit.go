package main

import (
	"encoding/json"
	"io"
	"io/fs"
	"os"
	"path/filepath"
	"strings"

	"quiz_master/next/server/internal/content"
)

type auditPack struct {
	Path        string `json:"path"`
	SourceID    string `json:"source_id"`
	CanonicalID string `json:"canonical_id,omitempty"`
	Title       string `json:"title"`
	Description string `json:"description"`
	Category    string `json:"category"`
	Questions   int    `json:"questions"`
	Error       string `json:"error,omitempty"`
}

// audit checks readiness, not factual truth, and never writes migration artifacts.
func audit(root, schemas string, out io.Writer) error {
	info, err := os.Lstat(root)
	if err != nil || !info.IsDir() {
		return &content.Error{Kind: "input_directory", Path: root}
	}
	report := struct {
		Files     int         `json:"files"`
		Questions int         `json:"questions"`
		Ready     int         `json:"ready"`
		Blocked   int         `json:"blocked"`
		Packs     []auditPack `json:"packs"`
	}{Packs: []auditPack{}}
	ids := map[string][]int{}
	err = filepath.WalkDir(root, func(path string, entry fs.DirEntry, walkErr error) error {
		if walkErr != nil {
			return &content.Error{Kind: "read", Path: path}
		}
		if entry.IsDir() || !strings.EqualFold(filepath.Ext(path), ".json") {
			return nil
		}
		row := auditPack{Path: filepath.ToSlash(path)}
		var checkErr error
		if entry.Type()&os.ModeSymlink != 0 {
			checkErr = &content.Error{Kind: "symlink", Path: path}
		} else {
			// Counts describe source material even when strict import rejects the pack.
			var source struct {
				ID          string            `json:"id"`
				Title       string            `json:"title"`
				Description string            `json:"description"`
				Category    string            `json:"category"`
				Questions   []json.RawMessage `json:"questions"`
			}
			data, e := os.ReadFile(path)
			if e == nil && json.Unmarshal(data, &source) == nil {
				row.SourceID, row.Title, row.Category, row.Questions = source.ID, source.Title, source.Category, len(source.Questions)
				row.Description = source.Description
			}
			draft, _, e := content.Import(path)
			checkErr = e
			if e == nil {
				row.CanonicalID = draft.QuizID
				ids[draft.QuizID] = append(ids[draft.QuizID], len(report.Packs))
				checkErr = content.ValidateDraft(draft, filepath.Join(schemas, "draft-quiz.schema.json"))
			}
		}
		if checkErr != nil {
			row.Error = checkErr.Error()
		}
		report.Questions += row.Questions
		report.Packs = append(report.Packs, row)
		return nil
	})
	if err != nil {
		return err
	}
	if len(report.Packs) == 0 {
		return &content.Error{Kind: "empty_collection", Path: root}
	}
	for id, indexes := range ids {
		if len(indexes) > 1 {
			for _, index := range indexes {
				row := &report.Packs[index]
				collision := (&content.Error{Kind: "duplicate_id", Path: row.Path + "#" + id}).Error()
				if row.Error == "" {
					row.Error = collision
				} else {
					row.Error += "; " + collision
				}
			}
		}
	}
	report.Files = len(report.Packs)
	for _, row := range report.Packs {
		if row.Error == "" {
			report.Ready++
		} else {
			report.Blocked++
		}
	}
	encoder := json.NewEncoder(out)
	encoder.SetIndent("", "  ")
	if err := encoder.Encode(report); err != nil {
		return err
	}
	if report.Blocked != 0 {
		return &content.Error{Kind: "collection_blocked", Path: root}
	}
	return nil
}
