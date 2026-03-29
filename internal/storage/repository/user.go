package repository

import (
	"database/sql"
	"fmt"
	"time"

	authdomain "quiz_master/internal/auth/domain"
	"quiz_master/internal/dbx"

	"github.com/google/uuid"
)

type UserRepository struct {
	db *sql.DB
}

func NewUserRepository(db *sql.DB) *UserRepository {
	return &UserRepository{db: db}
}

func (r *UserRepository) GetByID(id string) (*authdomain.User, error) {
	var user authdomain.User
	err := r.db.QueryRow(dbx.Rebind(r.db, "SELECT id, username, password_hash, role FROM users WHERE id = ?"), id).
		Scan(&user.ID, &user.Username, &user.Password, &user.Role)
	if err != nil {
		err = r.db.QueryRow(dbx.Rebind(r.db, "SELECT id, username, password, role FROM users WHERE id = ?"), id).
			Scan(&user.ID, &user.Username, &user.Password, &user.Role)
		if err == sql.ErrNoRows {
			return nil, nil
		} else if err != nil {
			return nil, err
		}
	}
	return &user, nil
}

func (r *UserRepository) GetByUsername(username string) (*authdomain.User, error) {
	var user authdomain.User
	err := r.db.QueryRow(dbx.Rebind(r.db, "SELECT id, username, password_hash, role FROM users WHERE username = ?"), username).
		Scan(&user.ID, &user.Username, &user.Password, &user.Role)
	if err != nil {
		err = r.db.QueryRow(dbx.Rebind(r.db, "SELECT id, username, password, role FROM users WHERE username = ?"), username).
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

	_, err := r.db.Exec(dbx.Rebind(r.db, "INSERT INTO users (id, username, password_hash, role) VALUES (?, ?, ?, ?)"),
		user.ID, user.Username, user.Password, user.Role)
	if err == nil {
		return nil
	}

	_, legacyErr := r.db.Exec(dbx.Rebind(r.db, "INSERT INTO users (id, username, password, role) VALUES (?, ?, ?, ?)"),
		user.ID, user.Username, user.Password, user.Role)
	if legacyErr == nil {
		return nil
	}

	return err
}

func (r *UserRepository) SaveResult(userID, quizID, quizTitle string, score, total int) error {
	query := fmt.Sprintf(`
		INSERT INTO quiz_results (id, user_id, quiz_id, quiz_title, score, total_questions, completed_at)
		VALUES (?, ?, ?, ?, ?, ?, %s)
	`, dbx.NowExpr(r.db))
	_, err := r.db.Exec(dbx.Rebind(r.db, query), uuid.New().String(), userID, quizID, quizTitle, score, total)
	return err
}

func (r *UserRepository) GetLeaderboard(limit int) ([]map[string]interface{}, error) {
	rows, err := r.db.Query(dbx.Rebind(r.db, `
		SELECT u.username, r.score, r.total_questions, COALESCE(r.quiz_title, '')
		FROM quiz_results r
		JOIN users u ON u.id = r.user_id
		ORDER BY r.score DESC, r.completed_at DESC
		LIMIT ?
	`), limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	return scanLeaderboard(rows, true)
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

func (r *UserRepository) SaveRefreshToken(token *authdomain.RefreshToken) error {
	_, err := r.db.Exec(
		dbx.Rebind(r.db, "INSERT INTO refresh_tokens (token, user_id, expires_at, created_at) VALUES (?, ?, ?, ?)"),
		token.Token,
		token.UserID,
		token.ExpiresAt.UTC(),
		token.CreatedAt.UTC(),
	)
	return err
}

func (r *UserRepository) GetRefreshToken(refreshToken string) (*authdomain.RefreshToken, error) {
	var stored authdomain.RefreshToken
	var createdAt interface{}
	var expiresAt interface{}
	err := r.db.QueryRow(
		dbx.Rebind(r.db, "SELECT token, user_id, expires_at, created_at FROM refresh_tokens WHERE token = ?"),
		refreshToken,
	).Scan(&stored.Token, &stored.UserID, &expiresAt, &createdAt)
	if err == sql.ErrNoRows {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}

	stored.ExpiresAt, err = parseDBTime(expiresAt)
	if err != nil {
		return nil, err
	}
	stored.CreatedAt, err = parseDBTime(createdAt)
	if err != nil {
		return nil, err
	}

	return &stored, nil
}

func (r *UserRepository) DeleteRefreshToken(refreshToken string) error {
	_, err := r.db.Exec(dbx.Rebind(r.db, "DELETE FROM refresh_tokens WHERE token = ?"), refreshToken)
	return err
}

func parseDBTime(value interface{}) (time.Time, error) {
	switch v := value.(type) {
	case time.Time:
		return v, nil
	case string:
		return parseDBTimeString(v)
	case []byte:
		return parseDBTimeString(string(v))
	default:
		return time.Time{}, sql.ErrNoRows
	}
}

func parseDBTimeString(value string) (time.Time, error) {
	layouts := []string{
		time.RFC3339Nano,
		time.RFC3339,
		"2006-01-02 15:04:05.999999999-07:00",
		"2006-01-02 15:04:05.999999999",
		"2006-01-02 15:04:05",
	}
	for _, layout := range layouts {
		if ts, err := time.Parse(layout, value); err == nil {
			return ts, nil
		}
	}
	return time.Time{}, sql.ErrNoRows
}
