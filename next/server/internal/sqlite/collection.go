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
func newCollection(db *sql.DB, directory, schemas string, duration time.Duration, taxonomyPath string) (*Attempts, error) {
	type pack struct {
		service       *Attempts
		raw, manifest []byte
	}
	var taxonomy *content.Taxonomy
	if taxonomyPath != "" {
		var err error
		taxonomy, err = content.LoadTaxonomy(taxonomyPath)
		if err != nil {
			return nil, err
		}
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
		draft, manifest, err := content.ImportWithTaxonomy(path, taxonomy)
		if err != nil {
			return err
		}
		bundle, err := content.BuildWithTaxonomy(draft, "source-v1", "2026-10-02T00:00:00Z", taxonomy, schemas)
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
func (s *Attempts) CatalogForDifficulty(id, difficulty string) (attempts.Catalog, error) {
	pack, err := s.selected(id)
	if err != nil {
		return attempts.Catalog{}, err
	}
	selected, err := selectDifficulty(pack, difficulty)
	if err != nil {
		return attempts.Catalog{}, err
	}
	return selected.Catalog(), nil
}
func (s *Attempts) StartQuiz(ctx context.Context, owner, id string) (attempts.Attempt, error) {
	pack, err := s.selected(id)
	if err != nil {
		return attempts.Attempt{}, err
	}
	return pack.Start(ctx, owner)
}
func (s *Attempts) StartPracticeQuiz(ctx context.Context, owner, id string) (attempts.Attempt, error) {
	pack, err := s.selected(id)
	if err != nil {
		return attempts.Attempt{}, err
	}
	return pack.start(ctx, owner, true)
}
func (s *Attempts) StartDifficultyQuiz(ctx context.Context, owner, id, difficulty string) (attempts.Attempt, error) {
	pack, err := s.selected(id)
	if err != nil {
		return attempts.Attempt{}, err
	}
	selected, err := selectDifficulty(pack, difficulty)
	if err != nil {
		return attempts.Attempt{}, err
	}
	return selected.start(ctx, owner, false)
}
func (s *Attempts) StartDifficultyPracticeQuiz(ctx context.Context, owner, id, difficulty string) (attempts.Attempt, error) {
	pack, err := s.selected(id)
	if err != nil {
		return attempts.Attempt{}, err
	}
	selected, err := selectDifficulty(pack, difficulty)
	if err != nil {
		return attempts.Attempt{}, err
	}
	return selected.start(ctx, owner, true)
}

// Rounds partition the source without changing its immutable grading bundle.
// Shuffle only within a round: advancing through every round never repeats or loses a question.
func (s *Attempts) StartRound(ctx context.Context, owner, id string, round int) (attempts.Attempt, error) {
	return s.startRound(ctx, owner, id, round, false)
}
func (s *Attempts) StartPracticeRound(ctx context.Context, owner, id string, round int) (attempts.Attempt, error) {
	return s.startRound(ctx, owner, id, round, true)
}
func (s *Attempts) StartDifficultyRound(ctx context.Context, owner, id, difficulty string, round int) (attempts.Attempt, error) {
	return s.startDifficultyRound(ctx, owner, id, difficulty, round, false)
}
func (s *Attempts) StartDifficultyPracticeRound(ctx context.Context, owner, id, difficulty string, round int) (attempts.Attempt, error) {
	return s.startDifficultyRound(ctx, owner, id, difficulty, round, true)
}
func (s *Attempts) startRound(ctx context.Context, owner, id string, round int, practice bool) (attempts.Attempt, error) {
	pack, err := s.selected(id)
	if err != nil {
		return attempts.Attempt{}, err
	}
	questions, err := attempts.QuestionRound(pack.bundle.Quiz.Questions, round)
	if err != nil {
		return attempts.Attempt{}, err
	}
	return startQuestionRound(ctx, owner, pack, questions, practice)
}
func (s *Attempts) startDifficultyRound(ctx context.Context, owner, id, difficulty string, round int, practice bool) (attempts.Attempt, error) {
	pack, err := s.selected(id)
	if err != nil {
		return attempts.Attempt{}, err
	}
	selected, err := selectDifficulty(pack, difficulty)
	if err != nil {
		return attempts.Attempt{}, err
	}
	questions, err := attempts.QuestionRound(selected.bundle.Quiz.Questions, round)
	if err != nil {
		return attempts.Attempt{}, err
	}
	return startQuestionRound(ctx, owner, selected, questions, practice)
}
func startQuestionRound(ctx context.Context, owner string, pack *Attempts, questions []content.PublicQuestion, practice bool) (attempts.Attempt, error) {
	ids := make([]string, len(questions))
	byID := map[string]content.PublicQuestion{}
	for i, q := range questions {
		ids[i] = q.QuestionID
		byID[q.QuestionID] = q
	}
	if err := attempts.RandomShuffle(ids); err != nil {
		return attempts.Attempt{}, err
	}
	selected := *pack
	selected.bundle.Quiz.Questions = make([]content.PublicQuestion, len(ids))
	for i, id := range ids {
		selected.bundle.Quiz.Questions[i] = byID[id]
	}
	return selected.start(ctx, owner, practice)
}
func selectDifficulty(pack *Attempts, difficulty string) (*Attempts, error) {
	quiz, err := attempts.SelectDifficulty(pack.bundle.Quiz, difficulty)
	if err != nil {
		return nil, err
	}
	selected := *pack
	selected.bundle.Quiz = quiz
	return &selected, nil
}
