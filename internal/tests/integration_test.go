package tests

import (
	"bytes"
	"database/sql"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	authdomain "quiz_master/internal/auth/domain"
	authhttp "quiz_master/internal/auth/http"
	authservice "quiz_master/internal/auth/service"
	authtoken "quiz_master/internal/auth/token"
	quizdomain "quiz_master/internal/quiz/domain"
	quizhttp "quiz_master/internal/quiz/http"
	quizservice "quiz_master/internal/quiz/service"
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

	_, err = db.Exec(`
		CREATE TABLE reports (
			id TEXT PRIMARY KEY,
			quiz_id TEXT,
			question_id TEXT,
			message TEXT,
			question_text TEXT,
			created_at DATETIME
		)
	`)
	require.NoError(t, err)

	userRepo := storagerepo.NewUserRepository(db)
	quizRepo := storagerepo.NewQuizRepository(db)

	authSvc := authservice.New(userRepo, authtoken.NewLegacyManager(), nil)
	quizSvc := quizservice.New(quizRepo)

	authHandler := authhttp.NewHandler(authSvc, nil)
	authMiddleware := authhttp.NewMiddleware(authtoken.NewLegacyManager())
	quizHandler := quizhttp.NewHandler(quizSvc)

	e := echo.New()
	api := e.Group("/api")
	authhttp.RegisterRoutes(api, authHandler, authMiddleware)
	api.GET("/quizzes", quizHandler.List)
	api.GET("/quota", authHandler.GetUserQuota, authMiddleware.JWT)
	api.POST("/report", quizHandler.Report)

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

	var registerRes authdomain.AuthResponse
	err = json.Unmarshal(rec.Body.Bytes(), &registerRes)
	require.NoError(t, err)
	assert.Equal(t, "testuser", registerRes.Username)

	req = httptest.NewRequest(http.MethodPost, "/api/login", bytes.NewReader(body))
	req.Header.Set(echo.HeaderContentType, echo.MIMEApplicationJSON)
	rec = httptest.NewRecorder()
	e.ServeHTTP(rec, req)
	assert.Equal(t, http.StatusOK, rec.Code)

	req = httptest.NewRequest(
		http.MethodPost,
		"/api/refresh",
		bytes.NewReader([]byte(`{"refresh_token":"`+registerRes.RefreshToken+`"}`)),
	)
	req.Header.Set(echo.HeaderContentType, echo.MIMEApplicationJSON)
	rec = httptest.NewRecorder()
	e.ServeHTTP(rec, req)
	assert.Equal(t, http.StatusOK, rec.Code)
}

func TestIntegration_QuizList(t *testing.T) {
	e, db := setupIntegrationServer(t)
	defer db.Close()

	quizRepo := storagerepo.NewQuizRepository(db)
	err := quizRepo.Create(&quizdomain.Quiz{
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

	var quizzes []quizdomain.Quiz
	err = json.Unmarshal(rec.Body.Bytes(), &quizzes)
	require.NoError(t, err)
	assert.Len(t, quizzes, 1)
}

func TestIntegration_ReportPersistsToDatabase(t *testing.T) {
	e, db := setupIntegrationServer(t)
	defer db.Close()

	quizRepo := storagerepo.NewQuizRepository(db)
	err := quizRepo.Create(&quizdomain.Quiz{
		ID:          "quiz-1",
		Title:       "Quiz 1",
		Description: "Desc",
		Category:    "General",
		Questions: []quizdomain.Question{
			{
				ID:                 "question-1",
				Type:               "choice",
				Text:               "Question?",
				Options:            []string{"A", "B"},
				CorrectAnswerIndex: 0,
			},
		},
	})
	require.NoError(t, err)

	payload := map[string]string{
		"quiz_id":       "quiz-1",
		"question_id":   "question-1",
		"message":       "Wrong answer mapping",
		"question_text": "Question?",
	}
	body, err := json.Marshal(payload)
	require.NoError(t, err)

	req := httptest.NewRequest(http.MethodPost, "/api/report", bytes.NewReader(body))
	req.Header.Set(echo.HeaderContentType, echo.MIMEApplicationJSON)
	rec := httptest.NewRecorder()
	e.ServeHTTP(rec, req)
	assert.Equal(t, http.StatusOK, rec.Code)

	var count int
	err = db.QueryRow("SELECT COUNT(*) FROM reports WHERE quiz_id = ? AND question_id = ?", "quiz-1", "question-1").Scan(&count)
	require.NoError(t, err)
	assert.Equal(t, 1, count)
}
