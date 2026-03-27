package api

import (
	"bytes"
	"database/sql"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"quiz_master/internal/models"
	"quiz_master/internal/service"
	"quiz_master/internal/store"

	_ "modernc.org/sqlite"
	"github.com/labstack/echo/v4"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func setupAuthHandler(t *testing.T) (*AuthHandler, *sql.DB) {
	db, err := sql.Open("sqlite", ":memory:")
	require.NoError(t, err)

	// Create schema
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

	repo := store.NewUserStore(db)
	authService := service.NewAuthService(repo)
	handler := NewAuthHandler(authService)

	return handler, db
}

func TestAuthHandler_Register(t *testing.T) {
	handler, db := setupAuthHandler(t)
	defer db.Close()

	// Setup Echo
	e := echo.New()
	body := map[string]string{
		"username": "testuser",
		"password": "password123",
	}
	bodyBytes, _ := json.Marshal(body)
	req := httptest.NewRequest(http.MethodPost, "/register", bytes.NewReader(bodyBytes))
	req.Header.Set(echo.HeaderContentType, echo.MIMEApplicationJSON)
	rec := httptest.NewRecorder()
	c := e.NewContext(req, rec)

	// Test
	err := handler.Register(c)
	require.NoError(t, err)
	assert.Equal(t, http.StatusOK, rec.Code)

	var result models.AuthResponse
	err = json.Unmarshal(rec.Body.Bytes(), &result)
	require.NoError(t, err)
	assert.NotEmpty(t, result.Token)
	assert.Equal(t, "testuser", result.Username)
}

func TestAuthHandler_Register_InvalidRequest(t *testing.T) {
	handler, db := setupAuthHandler(t)
	defer db.Close()

	// Setup Echo
	e := echo.New()
	req := httptest.NewRequest(http.MethodPost, "/register", bytes.NewReader([]byte("invalid json")))
	req.Header.Set(echo.HeaderContentType, echo.MIMEApplicationJSON)
	rec := httptest.NewRecorder()
	c := e.NewContext(req, rec)

	// Test
	err := handler.Register(c)
	require.NoError(t, err)
	assert.Equal(t, http.StatusBadRequest, rec.Code)
}

func TestAuthHandler_Login(t *testing.T) {
	handler, db := setupAuthHandler(t)
	defer db.Close()

	// Register first
	repo := store.NewUserStore(db)
	authService := service.NewAuthService(repo)
	registerReq := &models.AuthRequest{
		Username: "testuser",
		Password: "password123",
	}
	_, err := authService.Register(registerReq)
	require.NoError(t, err)

	// Setup Echo for login
	e := echo.New()
	body := map[string]string{
		"username": "testuser",
		"password": "password123",
	}
	bodyBytes, _ := json.Marshal(body)
	req := httptest.NewRequest(http.MethodPost, "/login", bytes.NewReader(bodyBytes))
	req.Header.Set(echo.HeaderContentType, echo.MIMEApplicationJSON)
	rec := httptest.NewRecorder()
	c := e.NewContext(req, rec)

	// Test
	err = handler.Login(c)
	require.NoError(t, err)
	assert.Equal(t, http.StatusOK, rec.Code)

	var result models.AuthResponse
	err = json.Unmarshal(rec.Body.Bytes(), &result)
	require.NoError(t, err)
	assert.NotEmpty(t, result.Token)
	assert.Equal(t, "testuser", result.Username)
}

func TestAuthHandler_Login_InvalidCredentials(t *testing.T) {
	handler, db := setupAuthHandler(t)
	defer db.Close()

	// Setup Echo
	e := echo.New()
	body := map[string]string{
		"username": "nonexistent",
		"password": "wrongpassword",
	}
	bodyBytes, _ := json.Marshal(body)
	req := httptest.NewRequest(http.MethodPost, "/login", bytes.NewReader(bodyBytes))
	req.Header.Set(echo.HeaderContentType, echo.MIMEApplicationJSON)
	rec := httptest.NewRecorder()
	c := e.NewContext(req, rec)

	// Test
	err := handler.Login(c)
	require.NoError(t, err)
	assert.Equal(t, http.StatusUnauthorized, rec.Code)
}

func TestAuthHandler_GuestLogin(t *testing.T) {
	handler, db := setupAuthHandler(t)
	defer db.Close()

	// Setup Echo
	e := echo.New()
	body := map[string]string{
		"username": "guestuser",
	}
	bodyBytes, _ := json.Marshal(body)
	req := httptest.NewRequest(http.MethodPost, "/guest", bytes.NewReader(bodyBytes))
	req.Header.Set(echo.HeaderContentType, echo.MIMEApplicationJSON)
	rec := httptest.NewRecorder()
	c := e.NewContext(req, rec)

	// Test
	err := handler.GuestLogin(c)
	require.NoError(t, err)
	assert.Equal(t, http.StatusOK, rec.Code)

	var result models.AuthResponse
	err = json.Unmarshal(rec.Body.Bytes(), &result)
	require.NoError(t, err)
	assert.NotEmpty(t, result.Token)
	assert.Equal(t, "guestuser", result.Username)
}

func TestAuthHandler_GetLeaderboard(t *testing.T) {
	handler, db := setupAuthHandler(t)
	defer db.Close()

	// Create test data
	repo := store.NewUserStore(db)
	authService := service.NewAuthService(repo)
	user1 := &models.User{ID: "user1", Username: "user1", Password: "pwd", Role: "user"}
	user2 := &models.User{ID: "user2", Username: "user2", Password: "pwd", Role: "user"}
	require.NoError(t, repo.Create(user1))
	require.NoError(t, repo.Create(user2))

	require.NoError(t, authService.SubmitResult("user1", "quiz1", 10, 10))
	require.NoError(t, authService.SubmitResult("user2", "quiz1", 8, 10))

	// Setup Echo
	e := echo.New()
	req := httptest.NewRequest(http.MethodGet, "/leaderboard", nil)
	rec := httptest.NewRecorder()
	c := e.NewContext(req, rec)

	// Test
	err := handler.GetLeaderboard(c)
	require.NoError(t, err)
	assert.Equal(t, http.StatusOK, rec.Code)

	var result []map[string]interface{}
	err = json.Unmarshal(rec.Body.Bytes(), &result)
	require.NoError(t, err)
	assert.Len(t, result, 2)
}

func TestAuthHandler_Refresh(t *testing.T) {
	handler, db := setupAuthHandler(t)
	defer db.Close()

	repo := store.NewUserStore(db)
	authService := service.NewAuthService(repo)
	initial, err := authService.Register(&models.AuthRequest{
		Username: "refresh-user",
		Password: "password123",
	})
	require.NoError(t, err)

	e := echo.New()
	bodyBytes, _ := json.Marshal(map[string]string{
		"refresh_token": initial.RefreshToken,
	})
	req := httptest.NewRequest(http.MethodPost, "/refresh", bytes.NewReader(bodyBytes))
	req.Header.Set(echo.HeaderContentType, echo.MIMEApplicationJSON)
	rec := httptest.NewRecorder()
	c := e.NewContext(req, rec)

	err = handler.Refresh(c)
	require.NoError(t, err)
	assert.Equal(t, http.StatusOK, rec.Code)

	var result models.AuthResponse
	err = json.Unmarshal(rec.Body.Bytes(), &result)
	require.NoError(t, err)
	assert.NotEmpty(t, result.Token)
	assert.NotEmpty(t, result.RefreshToken)
	assert.NotEqual(t, initial.RefreshToken, result.RefreshToken)
}

// TestAuthHandler_SubmitResult is skipped because it requires GlobalHub.Run() to be running
// which would block the test. The functionality is tested in service/auth_test.go
func TestAuthHandler_SubmitResult(t *testing.T) {
	t.Skip("Skipping due to GlobalHub blocking - tested in service layer")
}
