package dto

type SubmitResultRequest struct {
	UserID         string `json:"user_id"`
	QuizID         string `json:"quiz_id"`
	Score          int    `json:"score"`
	TotalQuestions int    `json:"total_questions"`
}

type UserQuota struct {
	QuizzesCompleted  int `json:"quizzes_completed"`
	QuestionsAnswered int `json:"questions_answered"`
	QuizzesLimit      int `json:"quizzes_limit"`
	QuestionsLimit    int `json:"questions_limit"`
	AttemptsLimit     int `json:"attempts_limit"`
	AttemptsUsed      int `json:"attempts_used"`
}

type LeaderboardEntry struct {
	Username  string `json:"username"`
	Score     int    `json:"score"`
	Total     int    `json:"total"`
	QuizTitle string `json:"quiz_title,omitempty"`
}
