package attempts

import (
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"os"
	"strings"
	"unicode/utf8"

	"github.com/jackc/pgx/v5"
	"quiz_master/next/server/internal/content"
)

type CorrectAnswer struct {
	OptionID  string   `json:"option_id,omitempty"`
	OptionIDs []string `json:"option_ids,omitempty"`
	Text      string   `json:"text"`
}

type Reveal struct {
	QuizID           string           `json:"quiz_id"`
	QuestionID       string           `json:"question_id"`
	QuestionRevision content.Revision `json:"question_revision"`
	CorrectAnswer    CorrectAnswer    `json:"correct_answer"`
	Explanation      string           `json:"explanation"`
}

type revealManifest struct {
	Explanations map[string]string
	SHA256       string
}

func loadManifest(path string, bundle content.Bundle) (revealManifest, error) {
	raw, err := os.ReadFile(path)
	if err != nil {
		return revealManifest{}, fmt.Errorf("load explanation manifest: %w", err)
	}
	if !utf8.Valid(raw) {
		return revealManifest{}, errors.New("explanation manifest is not valid UTF-8")
	}
	var manifest content.Manifest
	decoder := json.NewDecoder(bytes.NewReader(raw))
	decoder.DisallowUnknownFields()
	if err = decoder.Decode(&manifest); err != nil {
		return revealManifest{}, errors.New("explanation manifest is invalid")
	}
	if err = decoder.Decode(&struct{}{}); !errors.Is(err, io.EOF) {
		return revealManifest{}, errors.New("explanation manifest has trailing data")
	}
	if manifest.CanonicalQuizID != bundle.Quiz.QuizID || len(manifest.Questions) != len(bundle.Quiz.Questions) {
		return revealManifest{}, errors.New("explanation manifest does not match controlled bundle")
	}
	wanted := make(map[string]bool, len(bundle.Quiz.Questions))
	for _, question := range bundle.Quiz.Questions {
		wanted[question.QuestionID] = true
	}
	explanations := make(map[string]string, len(manifest.Questions))
	for _, question := range manifest.Questions {
		if !wanted[question.CanonicalID] || explanations[question.CanonicalID] != "" || strings.TrimSpace(question.Explanation) == "" {
			return revealManifest{}, errors.New("explanation manifest question coverage is invalid")
		}
		explanations[question.CanonicalID] = question.Explanation
	}
	if len(explanations) != len(wanted) {
		return revealManifest{}, errors.New("explanation manifest question coverage is incomplete")
	}
	digest := sha256.Sum256(raw)
	return revealManifest{Explanations: explanations, SHA256: hex.EncodeToString(digest[:])}, nil
}
func ValidateManifest(path string, bundle content.Bundle) (map[string]string, error) {
	m, err := loadManifest(path, bundle)
	return m.Explanations, err
}

func buildReveal(bundle content.Bundle, explanations map[string]string, questionID string) (Reveal, error) {
	var question *content.PublicQuestion
	for i := range bundle.Quiz.Questions {
		if bundle.Quiz.Questions[i].QuestionID == questionID {
			question = &bundle.Quiz.Questions[i]
			break
		}
	}
	if question == nil || strings.TrimSpace(explanations[questionID]) == "" {
		return Reveal{}, errors.New("reveal input is incomplete")
	}
	grading, ok := bundle.PrivateGrading[questionID]
	if !ok {
		return Reveal{}, errors.New("reveal grading is missing")
	}
	answer := CorrectAnswer{}
	optionText := func(id string) (string, bool) {
		for _, option := range question.Options {
			if option.OptionID == id && strings.TrimSpace(option.Text) != "" {
				return option.Text, true
			}
		}
		return "", false
	}
	switch question.AnswerKind {
	case "single_choice":
		text, found := optionText(grading.CorrectOptionID)
		if !found {
			return Reveal{}, errors.New("reveal option is missing")
		}
		answer.OptionID, answer.Text = grading.CorrectOptionID, text
	case "multiple_choice":
		if len(grading.CorrectOptionIDs) == 0 {
			return Reveal{}, errors.New("reveal options are missing")
		}
		texts := make([]string, 0, len(grading.CorrectOptionIDs))
		for _, id := range grading.CorrectOptionIDs {
			text, found := optionText(id)
			if !found {
				return Reveal{}, errors.New("reveal option is missing")
			}
			answer.OptionIDs = append(answer.OptionIDs, id)
			texts = append(texts, text)
		}
		answer.Text = strings.Join(texts, ", ")
	case "normalized_text":
		if len(grading.AcceptedVariants) == 0 || strings.TrimSpace(grading.AcceptedVariants[0]) == "" {
			return Reveal{}, errors.New("reveal display variant is missing")
		}
		answer.Text = grading.AcceptedVariants[0]
	default:
		return Reveal{}, errors.New("reveal answer kind is invalid")
	}
	return Reveal{QuizID: bundle.Quiz.QuizID, QuestionID: questionID, QuestionRevision: question.Revision, CorrectAnswer: answer, Explanation: explanations[questionID]}, nil
}
func BuildReveal(bundle content.Bundle, explanations map[string]string, questionID string) (Reveal, error) {
	return buildReveal(bundle, explanations, questionID)
}

func (s *Service) Reveals(ctx context.Context, owner, attemptID string) ([]Reveal, error) {
	if _, err := ExternalParticipant(owner); err != nil {
		return nil, ErrForbidden
	}
	var status, bundleHash string
	err := s.pool.QueryRow(ctx, `select status,bundle_sha256 from attempts where id=$1 and participant_id=$2`, attemptID, owner).Scan(&status, &bundleHash)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, ErrForbidden
	}
	if err != nil {
		return nil, err
	}
	if status != "finished" {
		return nil, ErrValidation
	}
	if bundleHash != s.bundle.BundleSHA256 {
		return nil, errors.New("attempt bundle is not available for reveal")
	}
	rows, err := s.pool.Query(ctx, `select q.question_id from attempt_answers r join attempt_questions q using(attempt_id,question_id) where r.attempt_id=$1 order by q.position`, attemptID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	reveals := []Reveal{}
	for rows.Next() {
		var questionID string
		if err = rows.Scan(&questionID); err != nil {
			return nil, err
		}
		reveal, buildErr := buildReveal(s.bundle, s.explanations, questionID)
		if buildErr != nil {
			return nil, buildErr
		}
		reveals = append(reveals, reveal)
	}
	return reveals, rows.Err()
}
