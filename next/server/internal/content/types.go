// Package content implements the private quiz-contract/v1 content pipeline.
package content

import "errors"

const DefaultSchemas = "next/contracts/quiz-contract/v1/schemas"

// Error deliberately contains only a code and location, never content/answer values.
type Error struct{ Kind, Path string }

func (e *Error) Error() string { return e.Kind + ": " + e.Path }
func Code(err error) string {
	var e *Error
	if errors.As(err, &e) {
		return e.Kind
	}
	return ""
}

type Revision struct {
	Number int    `json:"number"`
	SHA256 string `json:"sha256"`
}
type Grading struct {
	CorrectOptionID  string   `json:"correct_option_id,omitempty"`
	CorrectOptionIDs []string `json:"correct_option_ids,omitempty"`
	AcceptedVariants []string `json:"accepted_variants,omitempty"`
}
type Media map[string]string
type Option struct {
	OptionID string `json:"option_id"`
	Text     string `json:"text"`
	Media    Media  `json:"media,omitempty"`
}
type Question struct {
	QuestionID string            `json:"question_id"`
	Revision   Revision          `json:"revision"`
	Stem       string            `json:"stem"`
	Options    []Option          `json:"options"`
	Difficulty string            `json:"difficulty"`
	Source     map[string]string `json:"source"`
	Media      *[]Media          `json:"media,omitempty"`
	AnswerKind string            `json:"answer_kind"`
	Grading    Grading           `json:"grading"`
}
type Draft struct {
	Contract  string     `json:"contract"`
	State     string     `json:"state"`
	QuizID    string     `json:"quiz_id"`
	Revision  Revision   `json:"revision"`
	Locale    string     `json:"locale"`
	Questions []Question `json:"questions"`
}
type OptionMap struct {
	SourceIndex int    `json:"source_index"`
	CanonicalID string `json:"canonical_id"`
}
type QuestionMap struct {
	SourceID    string      `json:"source_id"`
	CanonicalID string      `json:"canonical_id"`
	Options     []OptionMap `json:"options"`
	// Explanations have no accepted v1 draft field; retain them privately, unchanged.
	Explanation string `json:"source_explanation,omitempty"`
}
type Manifest struct {
	MappingVersion  string        `json:"mapping_version"`
	SourcePath      string        `json:"source_path"`
	SourceSHA256    string        `json:"source_sha256"`
	SourceQuizID    string        `json:"source_quiz_id"`
	CanonicalQuizID string        `json:"canonical_quiz_id"`
	Category        string        `json:"source_category"`
	Title           string        `json:"source_title"`
	Description     string        `json:"source_description"`
	Questions       []QuestionMap `json:"questions"`
}
type PublicQuestion struct {
	QuizID     string            `json:"quiz_id"`
	QuestionID string            `json:"question_id"`
	Revision   Revision          `json:"revision"`
	Stem       string            `json:"stem"`
	Options    []Option          `json:"options"`
	Difficulty string            `json:"difficulty"`
	Source     map[string]string `json:"source"`
	Media      *[]Media          `json:"media,omitempty"`
	AnswerKind string            `json:"answer_kind"`
}
type PublicQuiz struct {
	QuizID    string           `json:"quiz_id"`
	Revision  Revision         `json:"revision"`
	Locale    string           `json:"locale"`
	Questions []PublicQuestion `json:"questions"`
}
type Bundle struct {
	Contract       string             `json:"contract"`
	BundleVersion  string             `json:"bundle_version"`
	BundleSHA256   string             `json:"bundle_sha256"`
	PublishedAt    string             `json:"published_at"`
	Quiz           PublicQuiz         `json:"quiz"`
	PrivateGrading map[string]Grading `json:"private_grading"`
}
