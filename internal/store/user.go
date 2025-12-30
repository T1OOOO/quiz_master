package store

import (
	"database/sql"
	"quiz_master/internal/models"
	"github.com/google/uuid"
)

type UserStore struct {
	db *sql.DB
}

func NewUserStore(db *sql.DB) *UserStore {
	return &UserStore{db: db}
}

func (r *UserStore) GetByUsername(username string) (*models.User, error) {
	var u models.User
	err := r.db.QueryRow("SELECT id, username, password, role FROM users WHERE username = ?", username).
		Scan(&u.ID, &u.Username, &u.Password, &u.Role)
	if err == sql.ErrNoRows {
		return nil, nil
	} else if err != nil {
		return nil, err
	}
	return &u, nil
}

func (r *UserStore) Create(u *models.User) error {
	if u.ID == "" {
		u.ID = uuid.New().String()
	}
	_, err := r.db.Exec("INSERT INTO users (id, username, password, role) VALUES (?, ?, ?, ?)",
		u.ID, u.Username, u.Password, u.Role)
	return err
}

func (r *UserStore) SaveResult(userID, quizID string, score, total int) error {
	id := uuid.New().String()
	_, err := r.db.Exec(`
		INSERT INTO quiz_results (id, user_id, quiz_id, score, total_questions, completed_at)
		VALUES (?, ?, ?, ?, ?, datetime('now'))
	`, id, userID, quizID, score, total)
	return err
}

func (r *UserStore) GetLeaderboard(limit int) ([]map[string]interface{}, error) {
	rows, err := r.db.Query(`
		SELECT u.username, r.score, r.total_questions, q.title
		FROM quiz_results r
		JOIN users u ON u.id = r.user_id
		LEFT JOIN quizzes q ON q.id = r.quiz_id
		ORDER BY r.score DESC, r.completed_at DESC
		LIMIT ?
	`, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var results []map[string]interface{}
	for rows.Next() {
		var username, title string
		var score, total int
		if err := rows.Scan(&username, &score, &total, &title); err != nil {
			return nil, err
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
