package repository

import authdomain "quiz_master/internal/auth/domain"

type UserRepository interface {
	GetByUsername(username string) (*authdomain.User, error)
	Create(user *authdomain.User) error
	SaveResult(userID, quizID string, score, total int) error
	GetLeaderboard(limit int) ([]map[string]interface{}, error)
}
