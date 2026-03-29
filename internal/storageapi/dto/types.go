package dto

import "time"

type Question struct {
	ID                 string   `json:"id"`
	Type               string   `json:"type"`
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

type ReportRequest struct {
	QuizID       string `json:"quiz_id"`
	QuestionID   string `json:"question_id"`
	Message      string `json:"message"`
	QuestionText string `json:"question_text,omitempty"`
}

type RoomPlayer struct {
	Username    string `json:"username"`
	AvatarColor string `json:"avatar_color"`
	Score       int    `json:"score"`
}

type RoomChatMessage struct {
	User      string    `json:"user"`
	Text      string    `json:"text"`
	Image     string    `json:"image,omitempty"`
	Timestamp time.Time `json:"timestamp"`
}

type Room struct {
	Code            string                 `json:"code"`
	HostID          string                 `json:"host_id"`
	Version         int64                  `json:"version"`
	Players         map[string]RoomPlayer  `json:"players"`
	State           string                 `json:"state"`
	QuizID          string                 `json:"quiz_id,omitempty"`
	CurrentQuestion int                    `json:"current_question"`
	Votes           map[int]map[string]int `json:"votes"`
	Revealed        map[int]bool           `json:"revealed"`
	ChatHistory     []RoomChatMessage      `json:"chat_history"`
}

type RoomCreateRequest struct {
	Username string `json:"username"`
	Avatar   string `json:"avatar"`
}

type RoomJoinRequest struct {
	Username string `json:"username"`
	Avatar   string `json:"avatar"`
}

type RoomLeaveRequest struct {
	Username string `json:"username"`
}

type RoomStartRequest struct {
	Username string `json:"username"`
	QuizID   string `json:"quiz_id"`
}

type RoomVoteRequest struct {
	Username    string `json:"username"`
	AnswerIndex int    `json:"answer_index"`
}

type RoomChatRequest struct {
	Username string `json:"username"`
	Text     string `json:"text"`
	Image    string `json:"image"`
}

type RoomEvent struct {
	Type          string           `json:"type"`
	RoomCode      string           `json:"room_code,omitempty"`
	Room          *Room            `json:"room,omitempty"`
	BroadcastType string           `json:"broadcast_type,omitempty"`
	QuizID        string           `json:"quiz_id,omitempty"`
	ChatMessage   *RoomChatMessage `json:"chat_message,omitempty"`
}
