package sqlite

import (
	"context"
	"database/sql"
	"encoding/json"
	"io/fs"
	"path/filepath"
	"strings"
	"time"

	"quiz_master/next/server/internal/attempts"
	"quiz_master/next/server/internal/content"
)

// Source answers stay server-side. Validate the entire collection before
// atomically storing immutable bundles; existing attempts retain their versions.
func newCollection(db *sql.DB, directory, schemas string, duration time.Duration) (*Attempts, error) {
	type pack struct {
		service       *Attempts
		raw, manifest []byte
	}
	var loaded []pack
	packs := map[string]*Attempts{}
	err := filepath.WalkDir(directory, func(path string, entry fs.DirEntry, walkErr error) error {
		if walkErr != nil {
			return walkErr
		}
		if entry.Type()&fs.ModeSymlink != 0 {
			return attempts.ErrValidation
		}
		if entry.IsDir() || !strings.HasSuffix(entry.Name(), ".json") {
			return nil
		}
		draft, manifest, err := content.Import(path)
		if err != nil {
			return err
		}
		bundle, err := content.Build(draft, "source-v1", "2026-10-02T00:00:00Z", schemas)
		if err != nil {
			return err
		}
		if packs[bundle.Quiz.QuizID] != nil {
			return attempts.ErrConflict
		}
		explanations := map[string]string{}
		for _, question := range manifest.Questions {
			explanations[question.CanonicalID] = question.Explanation
		}
		if len(explanations) != len(bundle.Quiz.Questions) {
			return attempts.ErrValidation
		}
		raw, err := content.Canonical(bundle)
		if err != nil {
			return err
		}
		// A source location is provenance, not machine-specific deployment identity.
		manifest.SourcePath, err = filepath.Rel(directory, path)
		if err != nil {
			return err
		}
		manifest.SourcePath = filepath.ToSlash(manifest.SourcePath)
		manifestRaw, err := json.Marshal(manifest)
		if err != nil {
			return err
		}
		service := &Attempts{db: db, bundle: bundle, duration: duration, explanations: explanations}
		packs[bundle.Quiz.QuizID] = service
		loaded = append(loaded, pack{service, raw, manifestRaw})
		return nil
	})
	if err != nil {
		return nil, err
	}
	if len(loaded) == 0 {
		return nil, attempts.ErrValidation
	}
	tx, err := db.Begin()
	if err != nil {
		return nil, err
	}
	defer tx.Rollback()
	for _, p := range loaded {
		b := p.service.bundle
		if _, err = tx.Exec("insert or ignore into attempt_bundles(bundle_sha256,bundle_version,controlled_bundle,manifest) values(?,?,?,?)", b.BundleSHA256, b.BundleVersion, string(p.raw), string(p.manifest)); err != nil {
			return nil, err
		}
		var stored string
		if err = tx.QueryRow("select manifest from attempt_bundles where bundle_sha256=? and bundle_version=?", b.BundleSHA256, b.BundleVersion).Scan(&stored); err != nil {
			return nil, err
		}
		if stored != string(p.manifest) {
			return nil, attempts.ErrConflict
		}
	}
	if err = tx.Commit(); err != nil {
		return nil, err
	}
	fallback := packs["home-alone-1-part-1"]
	if fallback == nil {
		fallback = loaded[0].service
	}
	root := *fallback
	root.packs = packs
	return &root, nil
}

func (s *Attempts) selected(id string) (*Attempts, error) {
	if s.packs != nil {
		if pack := s.packs[id]; pack != nil {
			return pack, nil
		}
	} else if id == s.bundle.Quiz.QuizID {
		return s, nil
	}
	return nil, attempts.ErrValidation
}
func (s *Attempts) CatalogFor(id string) (attempts.Catalog, error) {
	pack, err := s.selected(id)
	if err != nil {
		return attempts.Catalog{}, err
	}
	return pack.Catalog(), nil
}
func (s *Attempts) StartQuiz(ctx context.Context, owner, id string) (attempts.Attempt, error) {
	pack, err := s.selected(id)
	if err != nil {
		return attempts.Attempt{}, err
	}
	return pack.Start(ctx, owner)
}

// Rounds partition the source without changing its immutable grading bundle.
// Shuffle only within a round: advancing through every round never repeats or loses a question.
func (s *Attempts) StartRound(ctx context.Context, owner, id string, round int) (attempts.Attempt, error) {
	pack, err := s.selected(id)
	if err != nil {
		return attempts.Attempt{}, err
	}
	questions := pack.bundle.Quiz.Questions
	if round < 0 || round >= (len(questions)+19)/20 {
		return attempts.Attempt{}, attempts.ErrValidation
	}
	end := min((round+1)*20, len(questions))
	ids := make([]string, end-round*20)
	byID := map[string]content.PublicQuestion{}
	for i, q := range questions[round*20 : end] {
		ids[i] = q.QuestionID
		byID[q.QuestionID] = q
	}
	if err = attempts.RandomShuffle(ids); err != nil {
		return attempts.Attempt{}, err
	}
	selected := *pack
	selected.bundle.Quiz.Questions = make([]content.PublicQuestion, len(ids))
	for i, id := range ids {
		selected.bundle.Quiz.Questions[i] = byID[id]
	}
	return selected.Start(ctx, owner)
}
