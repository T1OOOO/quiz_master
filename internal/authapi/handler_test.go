package authapi

import (
	"bytes"
	"database/sql"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	authdomain "quiz_master/internal/auth/domain"
	authservice "quiz_master/internal/auth/service"
	authtoken "quiz_master/internal/auth/token"
	storagerepo "quiz_master/internal/storage/repository"

	"github.com/labstack/echo/v4"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	_ "modernc.org/sqlite"
)

func setupHandler(t *testing.T) (*Handler, *sql.DB) {
	db, err := sql.Open("sqlite", ":memory:")
	require.NoError(t, err)

	_, err = db.Exec(`
		CREATE TABLE users (
			id TEXT PRIMARY KEY,
			username TEXT UNIQUE,
			password TEXT,
			role TEXT
		)
	`)
	require.NoError(t, err)

	_, err = db.Exec(`
		CREATE TABLE quiz_results (
			id TEXT PRIMARY KEY,
			user_id TEXT,
			quiz_id TEXT,
			quiz_title TEXT,
			score INTEGER,
			total_questions INTEGER,
			completed_at DATETIME
		)
	`)
	require.NoError(t, err)

	_, err = db.Exec(`
		CREATE TABLE refresh_tokens (
			token TEXT PRIMARY KEY,
			user_id TEXT,
			expires_at DATETIME,
			created_at DATETIME
		)
	`)
	require.NoError(t, err)

	repo := storagerepo.NewUserRepository(db)
	svc := authservice.New(repo, authtoken.NewLegacyManager(), nil)
	return NewHandler(svc), db
}

func TestHandlerSubmitResult_UsesContractDTO(t *testing.T) {
	handler, db := setupHandler(t)
	defer db.Close()

	repo := storagerepo.NewUserRepository(db)
	require.NoError(t, repo.Create(&authdomain.User{
		ID:       "user-1",
		Username: "alex",
		Password: "pwd",
		Role:     "user",
	}))

	payload, err := json.Marshal(map[string]interface{}{
		"user_id":         "user-1",
		"quiz_id":         "quiz-1",
		"score":           9,
		"total_questions": 10,
	})
	require.NoError(t, err)

	e := echo.New()
	req := httptest.NewRequest(http.MethodPost, "/internal/auth/results", bytes.NewReader(payload))
	req.Header.Set(echo.HeaderContentType, echo.MIMEApplicationJSON)
	rec := httptest.NewRecorder()
	c := e.NewContext(req, rec)

	err = handler.SubmitResult(c)
	require.NoError(t, err)
	assert.Equal(t, http.StatusOK, rec.Code)
}

func TestHandlerGetLeaderboard_UsesContractDTO(t *testing.T) {
	handler, db := setupHandler(t)
	defer db.Close()

	repo := storagerepo.NewUserRepository(db)
	require.NoError(t, repo.Create(&authdomain.User{ID: "user-1", Username: "alex", Password: "pwd", Role: "user"}))
	require.NoError(t, repo.SaveResult("user-1", "quiz-1", "Quiz 1", 9, 10))

	e := echo.New()
	req := httptest.NewRequest(http.MethodGet, "/internal/auth/leaderboard?limit=5", nil)
	rec := httptest.NewRecorder()
	c := e.NewContext(req, rec)

	err := handler.GetLeaderboard(c)
	require.NoError(t, err)
	assert.Equal(t, http.StatusOK, rec.Code)

	var entries []map[string]interface{}
	require.NoError(t, json.Unmarshal(rec.Body.Bytes(), &entries))
	assert.Len(t, entries, 1)
	assert.Equal(t, "alex", entries[0]["username"])
}
