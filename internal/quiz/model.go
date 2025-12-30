package quiz

type Quiz struct {
	ID          string     `yaml:"id" json:"id"`
	Title       string     `yaml:"title" json:"title"`
	Description string     `yaml:"description" json:"description"`
	Questions   []Question `yaml:"questions" json:"questions"`
}

type Question struct {
	ID                 string   `yaml:"id" json:"id"`
	Type               string   `yaml:"type" json:"type"` // "choice" (default), "text", "multi"
	Text               string   `yaml:"text" json:"text"`
	Options            []string `yaml:"options" json:"options"`
	CorrectAnswerIndex int      `yaml:"correct_answer" json:"correct_answer_index,omitempty"`
}

type AnswerAttempt struct {
	QuizID      string `json:"quiz_id"`
	QuestionID  string `json:"question_id"`
	AnswerIndex int    `json:"answer_index"`
}

type AnswerResult struct {
	Correct           bool   `json:"correct"`
	CorrectAnswer     int    `json:"correct_answer"`
	CorrectAnswerText string `json:"correct_answer_text"`
}
