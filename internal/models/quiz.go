package models

type Question struct {
	ID                 string   `json:"id" yaml:"id"`
	Type               string   `json:"type" yaml:"type"` // "choice", "text", "multi"
	Text               string   `json:"text" yaml:"text"`
	ImageURL           string   `json:"image_url,omitempty" yaml:"image_url"`
	Options            []string `json:"options,omitempty" yaml:"options"`
	CorrectAnswerIndex int      `json:"correct_answer_index" yaml:"correct_answer"`
	CorrectText        string   `json:"correct_text,omitempty" yaml:"correct_text"`
	CorrectMulti       []int    `json:"correct_multi,omitempty" yaml:"correct_multi"`
	Explanation        string   `json:"explanation,omitempty" yaml:"explanation"`
	Difficulty         int      `json:"difficulty,omitempty" yaml:"difficulty"`
}

type Quiz struct {
	ID             string     `json:"id" yaml:"id"`
	Title          string     `json:"title" yaml:"title"`
	Description    string     `json:"description" yaml:"description"`
	Category       string     `json:"category" yaml:"category"`
	Questions      []Question `json:"questions,omitempty" yaml:"questions"`
	QuestionsCount int        `json:"questions_count" yaml:"-"`
}

type AnswerResult struct {
	Correct       bool        `json:"correct"`
	CorrectAnswer interface{} `json:"correct_answer,omitempty"`
	CorrectText   string      `json:"correct_text,omitempty"`
	Explanation   string      `json:"explanation,omitempty"`
}

type AnswerAttempt struct {
	QuestionID string      `json:"question_id"`
	Answer     interface{} `json:"answer"`
}
