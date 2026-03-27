package domain

import "time"

type User struct {
	ID       string `json:"id"`
	Username string `json:"username"`
	Password string `json:"-"`
	Role     string `json:"role"`
}

type AuthRequest struct {
	Username string `json:"username"`
	Password string `json:"password"`
}

type AuthResponse struct {
	Token        string `json:"token"`
	RefreshToken string `json:"refresh_token,omitempty"`
	Username     string `json:"username"`
	Role         string `json:"role"`
}

type RefreshRequest struct {
	RefreshToken string `json:"refresh_token"`
}

type UserQuota struct {
	QuizzesCompleted  int `json:"quizzesCompleted"`
	QuestionsAnswered int `json:"questionsAnswered"`
	QuizzesLimit      int `json:"quizzesLimit"`
	QuestionsLimit    int `json:"questionsLimit"`
	AttemptsLimit     int `json:"attemptsLimit"`
	AttemptsUsed      int `json:"attemptsUsed"`
}

type Claims struct {
	UserID   string `json:"user_id"`
	Username string `json:"username"`
	Role     string `json:"role"`
}

type RefreshToken struct {
	Token     string
	UserID     string
	ExpiresAt time.Time
	CreatedAt time.Time
}
