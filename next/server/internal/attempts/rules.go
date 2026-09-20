// Package attempts owns pinned, participant-scoped solo attempts and scoring.
package attempts

import (
	"crypto/rand"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"math/big"
	"regexp"
	"strconv"
	"time"

	"quiz_master/next/server/internal/content"
)

var (
	ErrForbidden        = errors.New("forbidden")
	ErrValidation       = errors.New("validation_failed")
	ErrRevision         = errors.New("stale_revision")
	ErrDeadline         = errors.New("deadline_exceeded")
	ErrConflict         = errors.New("idempotency_conflict")
	internalParticipant = regexp.MustCompile(`^p_[0-9a-f]{32}$`)
	externalParticipant = regexp.MustCompile(`^p-[0-9a-f]{32}$`)
	contractID          = regexp.MustCompile(`^[a-z][a-z0-9-]{2,63}$`)
)

func ExternalParticipant(id string) (string, error) {
	if !internalParticipant.MatchString(id) {
		return "", ErrForbidden
	}
	return "p-" + id[2:], nil
}
func InternalParticipant(id string) (string, error) {
	if !externalParticipant.MatchString(id) {
		return "", ErrForbidden
	}
	return "p_" + id[2:], nil
}

type Answer struct {
	OptionID  *string   `json:"option_id,omitempty"`
	OptionIDs *[]string `json:"option_ids,omitempty"`
	Text      *string   `json:"text,omitempty"`
}
type AnswerRequest struct {
	QuestionID       string           `json:"question_id"`
	QuestionRevision content.Revision `json:"question_revision"`
	Answer           Answer           `json:"answer"`
	IdempotencyKey   string           `json:"idempotency_key"`
	PayloadDigest    string           `json:"payload_digest"`
}
type Snapshot struct {
	QuestionID         string            `json:"question_id"`
	QuestionRevision   content.Revision  `json:"question_revision"`
	OptionOrder        []string          `json:"option_order"`
	PositionToOptionID map[string]string `json:"position_to_option_id"`
}
type Attempt struct {
	StartedAt            time.Time  `json:"-"`
	DeadlineAt           time.Time  `json:"-"`
	AttemptID            string     `json:"attempt_id"`
	ParticipantID        string     `json:"participant_id"`
	BundleVersion        string     `json:"bundle_version"`
	BundleSHA256         string     `json:"bundle_sha256"`
	ScoringPolicyVersion string     `json:"scoring_policy_version"`
	QuestionSnapshots    []Snapshot `json:"question_snapshots"`
	Status               string     `json:"status"`
}
type Receipt struct {
	ReceiptID        string           `json:"receipt_id"`
	AttemptID        string           `json:"attempt_id"`
	ParticipantID    string           `json:"participant_id"`
	QuestionID       string           `json:"question_id"`
	QuestionRevision content.Revision `json:"question_revision"`
	AcceptedAt       time.Time        `json:"accepted_at"`
}
type HistoryEntry struct {
	QuestionID       string           `json:"question_id"`
	QuestionRevision content.Revision `json:"question_revision"`
	ReceiptID        string           `json:"receipt_id"`
}
type Finish struct {
	AttemptID     string         `json:"attempt_id"`
	ParticipantID string         `json:"participant_id"`
	Status        string         `json:"status"`
	FinishedAt    time.Time      `json:"finished_at"`
	ServerScore   int            `json:"server_score"`
	History       []HistoryEntry `json:"history"`
}

func PayloadDigest(attemptID, participantID string, req AnswerRequest) (string, error) {
	b, err := content.Canonical(map[string]any{"attempt_id": attemptID, "participant_id": participantID, "question_id": req.QuestionID, "question_revision": req.QuestionRevision, "answer": req.Answer})
	if err != nil {
		return "", err
	}
	h := sha256.Sum256(b)
	return hex.EncodeToString(h[:]), nil
}
func validateAnswer(q content.PublicQuestion, a Answer) error {
	fields := 0
	if a.OptionID != nil {
		fields++
	}
	if a.OptionIDs != nil {
		fields++
	}
	if a.Text != nil {
		fields++
	}
	if fields != 1 {
		return ErrValidation
	}
	options := map[string]bool{}
	for _, o := range q.Options {
		options[o.OptionID] = true
	}
	switch q.AnswerKind {
	case "single_choice":
		if a.OptionID == nil || !options[*a.OptionID] {
			return ErrValidation
		}
	case "multiple_choice":
		if a.OptionIDs == nil || len(*a.OptionIDs) == 0 {
			return ErrValidation
		}
		seen := map[string]bool{}
		for _, id := range *a.OptionIDs {
			if !options[id] || seen[id] {
				return ErrValidation
			}
			seen[id] = true
		}
	case "normalized_text":
		if a.Text == nil || len(*a.Text) > 8192 {
			return ErrValidation
		}
	default:
		return ErrValidation
	}
	return nil
}
func score(q content.PublicQuestion, g content.Grading, a Answer) int {
	if validateAnswer(q, a) != nil {
		return 0
	}
	switch q.AnswerKind {
	case "single_choice":
		if *a.OptionID == g.CorrectOptionID {
			return 1
		}
	case "multiple_choice":
		if len(*a.OptionIDs) != len(g.CorrectOptionIDs) {
			return 0
		}
		key := map[string]bool{}
		for _, id := range g.CorrectOptionIDs {
			key[id] = true
		}
		for _, id := range *a.OptionIDs {
			if !key[id] {
				return 0
			}
		}
		return 1
	case "normalized_text":
		for _, v := range g.AcceptedVariants {
			if content.NormalizeText(*a.Text) == content.NormalizeText(v) {
				return 1
			}
		}
	}
	return 0
}

type Shuffler func([]string) error

func makeSnapshots(b content.Bundle, shuffle Shuffler) ([]Snapshot, error) {
	out := make([]Snapshot, 0, len(b.Quiz.Questions))
	for _, q := range b.Quiz.Questions {
		snap := Snapshot{QuestionID: q.QuestionID, QuestionRevision: q.Revision, OptionOrder: []string{}, PositionToOptionID: map[string]string{}}
		remaining := map[string]bool{}
		for _, o := range q.Options {
			snap.OptionOrder = append(snap.OptionOrder, o.OptionID)
			remaining[o.OptionID] = true
		}
		if err := shuffle(snap.OptionOrder); err != nil {
			return nil, err
		}
		for i, id := range snap.OptionOrder {
			if !remaining[id] {
				return nil, ErrValidation
			}
			delete(remaining, id)
			snap.PositionToOptionID[strconv.Itoa(i)] = id
		}
		if len(remaining) != 0 {
			return nil, ErrValidation
		}
		out = append(out, snap)
	}
	return out, nil
}

func MakeSnapshots(b content.Bundle, shuffle Shuffler) ([]Snapshot, error) {
	return makeSnapshots(b, shuffle)
}
func RandomShuffle(ids []string) error                                { return randomShuffle(ids) }
func ValidateAnswer(q content.PublicQuestion, a Answer) error         { return validateAnswer(q, a) }
func Score(q content.PublicQuestion, g content.Grading, a Answer) int { return score(q, g, a) }
func randomID(prefix string) (string, error) {
	var b [16]byte
	if _, err := rand.Read(b[:]); err != nil {
		return "", err
	}
	return prefix + "-" + hex.EncodeToString(b[:]), nil
}
func randomShuffle(ids []string) error {
	for i := len(ids) - 1; i > 0; i-- {
		n, err := rand.Int(rand.Reader, big.NewInt(int64(i+1)))
		if err != nil {
			return err
		}
		j := int(n.Int64())
		ids[i], ids[j] = ids[j], ids[i]
	}
	return nil
}
