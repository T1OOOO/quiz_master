package tests

import (
	"bytes"
	"database/sql"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	legacyapi "quiz_master/internal/api"
	authhttp "quiz_master/internal/auth/http"
	authservice "quiz_master/internal/auth/service"
	authtoken "quiz_master/internal/auth/token"
	"quiz_master/internal/models"
	legacyservice "quiz_master/internal/service"
	storagerepo "quiz_master/internal/storage/repository"

	"github.com/labstack/echo/v4"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	_ "modernc.org/sqlite"
)

func setupIntegrationServer(t *testing.T) (*echo.Echo, *sql.DB) {
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
		CREATE TABLE quizzes (
			id TEXT PRIMARY KEY,
			title TEXT,
			description TEXT,
			category TEXT
		)
	`)
	require.NoError(t, err)

	_, err = db.Exec(`
		CREATE TABLE questions (
			id TEXT PRIMARY KEY,
			quiz_id TEXT,
			type TEXT,
			text TEXT,
			options TEXT,
			correct_answer_index INTEGER,
			correct_text TEXT,
			correct_multi TEXT,
			image_url TEXT,
			explanation TEXT,
			difficulty INTEGER
		)
	`)
	require.NoError(t, err)

	_, err = db.Exec(`
		CREATE TABLE quiz_results (
			id TEXT PRIMARY KEY,
			user_id TEXT,
			quiz_id TEXT,
			score INTEGER,
			total_questions INTEGER,
			completed_at DATETIME
		)
	`)
	require.NoError(t, err)

	userRepo := storagerepo.NewUserRepository(db)
	quizRepo := storagerepo.NewQuizRepository(db)

	authSvc := authservice.New(userRepo, authtoken.NewLegacyManager())
	quizSvc := legacyservice.NewQuizService(quizRepo)

	authHandler := authhttp.NewHandler(authSvc, nil)
	authMiddleware := authhttp.NewMiddleware(authtoken.NewLegacyManager())
	quizHandler := legacyapi.NewQuizHandler(quizSvc)

	e := echo.New()
	api := e.Group("/api")
	authhttp.RegisterRoutes(api, authHandler, authMiddleware)
	api.GET("/quizzes", quizHandler.List)

	return e, db
}

func TestIntegration_AuthFlow(t *testing.T) {
	e, db := setupIntegrationServer(t)
	defer db.Close()

	payload := map[string]string{"username": "testuser", "password": "password123"}
	body, err := json.Marshal(payload)
	require.NoError(t, err)

	req := httptest.NewRequest(http.MethodPost, "/api/register", bytes.NewReader(body))
	req.Header.Set(echo.HeaderContentType, echo.MIMEApplicationJSON)
	rec := httptest.NewRecorder()
	e.ServeHTTP(rec, req)
	assert.Equal(t, http.StatusOK, rec.Code)

	var registerRes models.AuthResponse
	err = json.Unmarshal(rec.Body.Bytes(), &registerRes)
	require.NoError(t, err)
	assert.Equal(t, "testuser", registerRes.Username)

	req = httptest.NewRequest(http.MethodPost, "/api/login", bytes.NewReader(body))
	req.Header.Set(echo.HeaderContentType, echo.MIMEApplicationJSON)
	rec = httptest.NewRecorder()
	e.ServeHTTP(rec, req)
	assert.Equal(t, http.StatusOK, rec.Code)
}

func TestIntegration_QuizList(t *testing.T) {
	e, db := setupIntegrationServer(t)
	defer db.Close()

	quizRepo := storagerepo.NewQuizRepository(db)
	err := quizRepo.Create(&models.Quiz{
		ID:          "quiz-1",
		Title:       "Quiz 1",
		Description: "Desc",
		Category:    "General",
	})
	require.NoError(t, err)

	req := httptest.NewRequest(http.MethodGet, "/api/quizzes", nil)
	rec := httptest.NewRecorder()
	e.ServeHTTP(rec, req)
	assert.Equal(t, http.StatusOK, rec.Code)

	var quizzes []models.Quiz
	err = json.Unmarshal(rec.Body.Bytes(), &quizzes)
	require.NoError(t, err)
	assert.Len(t, quizzes, 1)
}
