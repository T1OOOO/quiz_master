package quizdomain

import "time"

type Question struct {
	ID                 string   `json:"id"`
	Type               string   `json:"type"` // "choice", "text", "multi"
	Text               string   `json:"text"`
	ImageURL           string   `json:"image_url,omitempty"`
	Options            []string `json:"options,omitempty"`
	CorrectAnswerIndex int      `json:"correct_answer_index"`
	CorrectText        string   `json:"correct_text,omitempty"`
	CorrectMulti       []int    `json:"correct_multi,omitempty"`
	Explanation        string   `json:"explanation,omitempty"`
	Difficulty         int      `json:"difficulty,omitempty"`
}

type Quiz struct {
	ID             string     `json:"id"`
	Title          string     `json:"title"`
	Description    string     `json:"description"`
	Category       string     `json:"category"`
	Questions      []Question `json:"questions,omitempty"`
	QuestionsCount int        `json:"questions_count"`
}

type QuizReport struct {
	ID           string    `json:"id,omitempty"`
	QuizID       string    `json:"quiz_id"`
	QuestionID   string    `json:"question_id"`
	Message      string    `json:"message"`
	QuestionText string    `json:"question_text,omitempty"`
	CreatedAt    time.Time `json:"created_at"`
}
