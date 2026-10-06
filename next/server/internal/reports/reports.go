// Package reports validates and persists private participant feedback.
package reports

import (
	"bytes"
	"crypto/sha256"
	"encoding/base64"
	"encoding/hex"
	"encoding/json"
	"errors"
	"image/png"
	"math"
	"regexp"
	"strings"
	"time"
	"unicode/utf8"
)

var (
	ErrValidation  = errors.New("invalid feedback report")
	ErrTooLarge    = errors.New("feedback report exceeds limit")
	ErrConflict    = errors.New("feedback request id already used")
	ErrNotFound    = errors.New("feedback report not found")
	requestPattern = regexp.MustCompile(`^frq_[0-9a-f]{32}$`)
	reportPattern  = regexp.MustCompile(`^rep_[0-9a-f]{32}$`)
)

type Viewport struct {
	Width  float64 `json:"width"`
	Height float64 `json:"height"`
	DPR    float64 `json:"dpr"`
}

type Context struct {
	Route        string   `json:"route"`
	Viewport     Viewport `json:"viewport"`
	Locale       string   `json:"locale"`
	Theme        string   `json:"theme"`
	Platform     string   `json:"platform"`
	AppVersion   string   `json:"app_version"`
	Timestamp    string   `json:"timestamp"`
	QuizID       string   `json:"quiz_id,omitempty"`
	QuestionID   string   `json:"question_id,omitempty"`
	AttemptID    string   `json:"attempt_id,omitempty"`
	QuestionText string   `json:"question_text,omitempty"`
}

type Request struct {
	RequestID  string   `json:"request_id"`
	Type       string   `json:"type"`
	ItemIDs    []string `json:"item_ids"`
	Comment    string   `json:"comment"`
	Context    Context  `json:"context"`
	Screenshot string   `json:"screenshot,omitempty"`
}

type Receipt struct {
	ID        string    `json:"id"`
	Status    string    `json:"status"`
	CreatedAt time.Time `json:"created_at"`
}

type Report struct {
	ID            string    `json:"id"`
	ParticipantID string    `json:"participant_id"`
	Type          string    `json:"type"`
	ItemIDs       []string  `json:"item_ids"`
	Comment       string    `json:"comment"`
	Context       Context   `json:"context"`
	Status        string    `json:"status"`
	CreatedAt     time.Time `json:"created_at"`
	UpdatedAt     time.Time `json:"updated_at"`
	HasScreenshot bool      `json:"has_screenshot"`
}

type Page struct {
	Reports []Report `json:"reports"`
	Total   int      `json:"total"`
	Limit   int      `json:"limit"`
	Offset  int      `json:"offset"`
}

func ValidID(id string) bool         { return reportPattern.MatchString(id) }
func ValidStatus(status string) bool { return status == "open" || status == "resolved" }

func bounded(value string, max int, required bool) bool {
	n := utf8.RuneCountInString(value)
	return utf8.ValidString(value) && n <= max && (!required || strings.TrimSpace(value) != "")
}

// Normalize produces the digest of the effective payload, not transport JSON.
// This makes whitespace/key-order changes safe while preserving conflict detection.
func Normalize(in Request) (Request, []byte, string, error) {
	in.Comment = strings.TrimSpace(in.Comment)
	if !requestPattern.MatchString(in.RequestID) || (in.Type != "ui" && in.Type != "content" && in.Type != "idea") || !bounded(in.Comment, 5000, true) || len(in.ItemIDs) < 1 || len(in.ItemIDs) > 16 {
		return Request{}, nil, "", ErrValidation
	}
	for _, id := range in.ItemIDs {
		if !bounded(id, 512, true) {
			return Request{}, nil, "", ErrValidation
		}
	}
	c := &in.Context
	if !bounded(c.Route, 512, true) || !strings.HasPrefix(c.Route, "/") || strings.ContainsAny(c.Route, "?#\\\r\n") || c.Route == "/feedback" || (strings.HasPrefix(c.Route, "/join/") && c.Route != "/join/[invite]") {
		return Request{}, nil, "", ErrValidation
	}
	for _, value := range []string{c.Locale, c.Platform, c.AppVersion} {
		if !bounded(value, 64, true) {
			return Request{}, nil, "", ErrValidation
		}
	}
	if c.Theme != "light" && c.Theme != "dark" {
		return Request{}, nil, "", ErrValidation
	}
	for _, value := range []string{c.QuizID, c.QuestionID, c.AttemptID} {
		if !bounded(value, 256, false) {
			return Request{}, nil, "", ErrValidation
		}
	}
	if !bounded(c.QuestionText, 4000, false) || !bounded(c.Timestamp, 64, true) {
		return Request{}, nil, "", ErrValidation
	}
	timestamp, err := time.Parse(time.RFC3339Nano, c.Timestamp)
	_, offset := timestamp.Zone()
	if err != nil || offset != 0 {
		return Request{}, nil, "", ErrValidation
	}
	c.Timestamp = timestamp.UTC().Format(time.RFC3339Nano)
	for _, value := range []float64{c.Viewport.Width, c.Viewport.Height, c.Viewport.DPR} {
		if math.IsNaN(value) || math.IsInf(value, 0) || value <= 0 {
			return Request{}, nil, "", ErrValidation
		}
	}
	if c.Viewport.Width > 32768 || c.Viewport.Height > 32768 || c.Viewport.DPR > 16 {
		return Request{}, nil, "", ErrValidation
	}
	contextJSON, err := json.Marshal(c)
	if err != nil {
		return Request{}, nil, "", ErrValidation
	}
	if len(contextJSON) > 16<<10 {
		return Request{}, nil, "", ErrTooLarge
	}
	var shot []byte
	if in.Screenshot != "" {
		if len(in.Screenshot) > base64.StdEncoding.EncodedLen(2<<20) {
			return Request{}, nil, "", ErrTooLarge
		}
		shot, err = base64.StdEncoding.Strict().DecodeString(in.Screenshot)
		if err != nil {
			return Request{}, nil, "", ErrValidation
		}
		if len(shot) > 2<<20 {
			return Request{}, nil, "", ErrTooLarge
		}
		cfg, decodeErr := png.DecodeConfig(bytes.NewReader(shot))
		if decodeErr != nil || cfg.Width <= 0 || cfg.Height <= 0 {
			return Request{}, nil, "", ErrValidation
		}
		if int64(cfg.Width)*int64(cfg.Height) > 4_000_000 {
			return Request{}, nil, "", ErrTooLarge
		}
		if _, err = png.Decode(bytes.NewReader(shot)); err != nil {
			return Request{}, nil, "", ErrValidation
		}
		in.Screenshot = base64.StdEncoding.EncodeToString(shot)
	}
	normalized, err := json.Marshal(in)
	if err != nil {
		return Request{}, nil, "", ErrValidation
	}
	digest := sha256.Sum256(normalized)
	return in, shot, hex.EncodeToString(digest[:]), nil
}
