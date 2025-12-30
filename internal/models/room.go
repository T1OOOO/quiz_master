package models

import "time"

const (
	StateWaiting  = "waiting"
	StatePlaying  = "playing"
	StateFinished = "finished"
)

type Player struct {
	Username    string `json:"username"`
	AvatarColor string `json:"avatar_color"`
	Score       int    `json:"score"`
}

type ChatMessage struct {
	User      string    `json:"user"`
	Text      string    `json:"text"`
	Image     string    `json:"image,omitempty"`
	Timestamp time.Time `json:"timestamp"`
}

type Room struct {
	Code            string                    `json:"code"`
	HostID          string                    `json:"host_id"`
	Players         map[string]*Player        `json:"players"`
	State           string                    `json:"state"`
	QuizID          string                    `json:"quiz_id,omitempty"`
	CurrentQuestion int                       `json:"current_question"`
	Votes           map[int]map[string]int    `json:"votes"`    // QuestionIndex -> PlayerID -> AnswerIndex
	Revealed        map[int]bool              `json:"revealed"` // QuestionIndex -> IsRevealed
	ChatHistory     []ChatMessage             `json:"chat_history"`
	QuizQuestions   []Question                `json:"-"`        // Calculated/Cached, not serialized to DB usually, but used in memory
}
