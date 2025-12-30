package tests

import (
	"database/sql"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"quiz_master/internal/core/domain"
	"quiz_master/internal/infrastructure/db"
	"quiz_master/internal/services/auth"
	"quiz_master/internal/services/quiz"
	thttp "quiz_master/internal/transport/http"

	"github.com/labstack/echo/v4"
	"github.com/stretchr/testify/suite"
	_ "modernc.org/sqlite"
)

type IntegrationTestSuite struct {
	suite.Suite
	echo *echo.Echo
}

func (s *IntegrationTestSuite) SetupSuite() {
	// Initialize in-memory DB for pure isolation
	dbConn, _ := sql.Open("sqlite", ":memory:")
	
	// Setup Schema
	dbConn.Exec("CREATE TABLE users (id TEXT PRIMARY KEY, username TEXT UNIQUE, password TEXT, role TEXT)")
	dbConn.Exec("CREATE TABLE quizzes (id TEXT PRIMARY KEY, title TEXT, description TEXT)")
	dbConn.Exec("CREATE TABLE questions (id TEXT PRIMARY KEY, quiz_id TEXT, type TEXT, text TEXT, options TEXT, correct_answer_index INTEGER)")
	dbConn.Exec("CREATE TABLE quiz_results (id TEXT PRIMARY KEY, user_id TEXT, quiz_id TEXT, score INTEGER, total_questions INTEGER, completed_at DATETIME)")

	e := echo.New()
	
	// Wiring
	quizRepo := db.NewQuizRepository(dbConn)
	userRepo := db.NewUserRepository(dbConn)
	quizService := quiz.NewQuizService(quizRepo)
	authService := auth.NewAuthService(userRepo)
	quizHandler := thttp.NewQuizHandler(quizService)
	authHandler := thttp.NewAuthHandler(authService)

	api := e.Group("/api")
	api.POST("/register", authHandler.Register)
	api.POST("/login", authHandler.Login)
	api.GET("/quizzes", quizHandler.List)
	
	s.echo = e
}

func (s *IntegrationTestSuite) TestAuthFlow() {
	// 1. Register
	userJSON := `{"username": "testuser", "password": "password123"}`
	req := httptest.NewRequest(http.MethodPost, "/api/register", strings.NewReader(userJSON))
	req.Header.Set(echo.HeaderContentType, echo.MIMEApplicationJSON)
	rec := httptest.NewRecorder()
	
	s.echo.ServeHTTP(rec, req)
	s.Equal(http.StatusOK, rec.Code)

	var res domain.AuthResponse
	err := json.Unmarshal(rec.Body.Bytes(), &res)
	s.NoError(err)
	s.Equal("testuser", res.Username)

	// 2. Login
	req = httptest.NewRequest(http.MethodPost, "/api/login", strings.NewReader(userJSON))
	req.Header.Set(echo.HeaderContentType, echo.MIMEApplicationJSON)
	rec = httptest.NewRecorder()
	
	s.echo.ServeHTTP(rec, req)
	s.Equal(http.StatusOK, rec.Code)
}

func (s *IntegrationTestSuite) TestQuizList() {
	req := httptest.NewRequest(http.MethodGet, "/api/quizzes", nil)
	rec := httptest.NewRecorder()
	
	s.echo.ServeHTTP(rec, req)
	s.Equal(http.StatusOK, rec.Code)
}

func TestIntegration(t *testing.T) {
	suite.Run(t, new(IntegrationTestSuite))
}
