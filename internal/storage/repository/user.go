package repository

import (
	"database/sql"
	"strings"

	authdomain "quiz_master/internal/auth/domain"

	"github.com/google/uuid"
)

type UserRepository struct {
	db *sql.DB
}

func NewUserRepository(db *sql.DB) *UserRepository {
	return &UserRepository{db: db}
}

func (r *UserRepository) GetByUsername(username string) (*authdomain.User, error) {
	var user authdomain.User
	err := r.db.QueryRow("SELECT id, username, password_hash, role FROM users WHERE username = ?", username).
		Scan(&user.ID, &user.Username, &user.Password, &user.Role)
	if err != nil {
		err = r.db.QueryRow("SELECT id, username, password, role FROM users WHERE username = ?", username).
			Scan(&user.ID, &user.Username, &user.Password, &user.Role)
		if err == sql.ErrNoRows {
			return nil, nil
		} else if err != nil {
			return nil, err
		}
	}
	return &user, nil
}

func (r *UserRepository) Create(user *authdomain.User) error {
	if user.ID == "" {
		user.ID = uuid.New().String()
	}

	_, err := r.db.Exec("INSERT INTO users (id, username, password_hash, role) VALUES (?, ?, ?, ?)",
		user.ID, user.Username, user.Password, user.Role)
	if err == nil {
		return nil
	}

	_, legacyErr := r.db.Exec("INSERT INTO users (id, username, password, role) VALUES (?, ?, ?, ?)",
		user.ID, user.Username, user.Password, user.Role)
	if legacyErr == nil {
		return nil
	}

	return err
}

func (r *UserRepository) SaveResult(userID, quizID string, score, total int) error {
	_, err := r.db.Exec(`
		INSERT INTO quiz_results (id, user_id, quiz_id, score, total_questions, completed_at)
		VALUES (?, ?, ?, ?, ?, datetime('now'))
	`, uuid.New().String(), userID, quizID, score, total)
	return err
}

func (r *UserRepository) GetLeaderboard(limit int) ([]map[string]interface{}, error) {
	rows, err := r.db.Query(`
		SELECT u.username, r.score, r.total_questions, q.title
		FROM quiz_results r
		JOIN users u ON u.id = r.user_id
		LEFT JOIN quizzes q ON q.id = r.quiz_id
		ORDER BY r.score DESC, r.completed_at DESC
		LIMIT ?
	`, limit)
	if err != nil {
		if !strings.Contains(strings.ToLower(err.Error()), "no such table: quizzes") {
			return nil, err
		}
		return r.getLeaderboardWithoutQuizzes(limit)
	}
	defer rows.Close()

	return scanLeaderboard(rows, true)
}

func (r *UserRepository) getLeaderboardWithoutQuizzes(limit int) ([]map[string]interface{}, error) {
	rows, err := r.db.Query(`
		SELECT u.username, r.score, r.total_questions
		FROM quiz_results r
		JOIN users u ON u.id = r.user_id
		ORDER BY r.score DESC, r.completed_at DESC
		LIMIT ?
	`, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	return scanLeaderboard(rows, false)
}

func scanLeaderboard(rows *sql.Rows, withTitle bool) ([]map[string]interface{}, error) {
	var results []map[string]interface{}
	for rows.Next() {
		var username string
		var score, total int
		title := ""
		if withTitle {
			if err := rows.Scan(&username, &score, &total, &title); err != nil {
				return nil, err
			}
		} else {
			if err := rows.Scan(&username, &score, &total); err != nil {
				return nil, err
			}
		}
		results = append(results, map[string]interface{}{
			"username":   username,
			"score":      score,
			"total":      total,
			"quiz_title": title,
		})
	}
	return results, nil
}
