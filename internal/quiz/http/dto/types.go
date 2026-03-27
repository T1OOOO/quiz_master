package quizdto

type QuestionPublic struct {
	ID         string   `json:"id"`
	Type       string   `json:"type"`
	Text       string   `json:"text"`
	ImageURL   string   `json:"image_url,omitempty"`
	Options    []string `json:"options,omitempty"`
	Difficulty int      `json:"difficulty,omitempty"`
}

type QuizPublic struct {
	ID             string           `json:"id"`
	Title          string           `json:"title"`
	Description    string           `json:"description"`
	Category       string           `json:"category"`
	Questions      []QuestionPublic `json:"questions,omitempty"`
	QuestionsCount int              `json:"questions_count"`
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
