package server

import (
	"bytes"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"testing"

	authdomain "quiz_master/internal/auth/domain"
	authdto "quiz_master/internal/authapi/dto"

	"github.com/golang-jwt/jwt/v5"
	"github.com/labstack/echo/v4"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

type fakeAuthGatewayClient struct {
	registerFn     func(*authdomain.AuthRequest) (*authdomain.AuthResponse, error)
	loginFn        func(*authdomain.AuthRequest) (*authdomain.AuthResponse, error)
	guestLoginFn   func(string) (*authdomain.AuthResponse, error)
	refreshFn      func(string) (*authdomain.AuthResponse, error)
	leaderboardFn  func(int) ([]authdto.LeaderboardEntry, error)
	quotaFn        func(string) (*authdomain.UserQuota, error)
	submitResultFn func(string, string, int, int) error
}

func (f *fakeAuthGatewayClient) Register(req *authdomain.AuthRequest) (*authdomain.AuthResponse, error) {
	return f.registerFn(req)
}
func (f *fakeAuthGatewayClient) Login(req *authdomain.AuthRequest) (*authdomain.AuthResponse, error) {
	return f.loginFn(req)
}
func (f *fakeAuthGatewayClient) GuestLogin(username string) (*authdomain.AuthResponse, error) {
	return f.guestLoginFn(username)
}
func (f *fakeAuthGatewayClient) Refresh(token string) (*authdomain.AuthResponse, error) {
	return f.refreshFn(token)
}
func (f *fakeAuthGatewayClient) GetLeaderboard(limit int) ([]authdto.LeaderboardEntry, error) {
	return f.leaderboardFn(limit)
}
func (f *fakeAuthGatewayClient) GetUserQuota(userID string) (*authdomain.UserQuota, error) {
	return f.quotaFn(userID)
}
func (f *fakeAuthGatewayClient) SubmitResult(userID, quizID string, score, totalQuestions int) error {
	return f.submitResultFn(userID, quizID, score, totalQuestions)
}

func TestAuthGatewayRegister(t *testing.T) {
	handler := newAuthGatewayHandler(&fakeAuthGatewayClient{
		registerFn: func(req *authdomain.AuthRequest) (*authdomain.AuthResponse, error) {
			assert.Equal(t, "alex", req.Username)
			return &authdomain.AuthResponse{Token: "jwt", Username: "alex", Role: "user"}, nil
		},
	}, nil)

	e := echo.New()
	req := httptest.NewRequest(http.MethodPost, "/api/register", bytes.NewReader([]byte(`{"username":"alex","password":"pwd"}`)))
	req.Header.Set(echo.HeaderContentType, echo.MIMEApplicationJSON)
	rec := httptest.NewRecorder()
	c := e.NewContext(req, rec)

	err := handler.Register(c)
	require.NoError(t, err)
	assert.Equal(t, http.StatusOK, rec.Code)
}

func TestAuthGatewaySubmitResult(t *testing.T) {
	handler := newAuthGatewayHandler(&fakeAuthGatewayClient{
		registerFn: func(req *authdomain.AuthRequest) (*authdomain.AuthResponse, error) { return nil, errors.New("unused") },
		loginFn:    func(req *authdomain.AuthRequest) (*authdomain.AuthResponse, error) { return nil, errors.New("unused") },
		guestLoginFn: func(username string) (*authdomain.AuthResponse, error) {
			return nil, errors.New("unused")
		},
		refreshFn: func(token string) (*authdomain.AuthResponse, error) { return nil, errors.New("unused") },
		leaderboardFn: func(limit int) ([]authdto.LeaderboardEntry, error) {
			return nil, errors.New("unused")
		},
		quotaFn: func(userID string) (*authdomain.UserQuota, error) { return nil, errors.New("unused") },
		submitResultFn: func(userID, quizID string, score, totalQuestions int) error {
			assert.Equal(t, "user-1", userID)
			assert.Equal(t, "quiz-1", quizID)
			assert.Equal(t, 9, score)
			assert.Equal(t, 10, totalQuestions)
			return nil
		},
	}, nil)

	e := echo.New()
	req := httptest.NewRequest(http.MethodPost, "/api/submit", bytes.NewReader([]byte(`{"quiz_id":"quiz-1","score":9,"total_questions":10}`)))
	req.Header.Set(echo.HeaderContentType, echo.MIMEApplicationJSON)
	rec := httptest.NewRecorder()
	c := e.NewContext(req, rec)
	c.Set("user", jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
		"user_id":  "user-1",
		"username": "alex",
		"role":     "user",
	}))

	err := handler.SubmitResult(c)
	require.NoError(t, err)
	assert.Equal(t, http.StatusOK, rec.Code)
}

func TestAuthGatewayLeaderboard(t *testing.T) {
	handler := newAuthGatewayHandler(&fakeAuthGatewayClient{
		leaderboardFn: func(limit int) ([]authdto.LeaderboardEntry, error) {
			assert.Equal(t, 5, limit)
			return []authdto.LeaderboardEntry{{Username: "alex", Score: 9, Total: 10, QuizTitle: "Quiz 1"}}, nil
		},
	}, nil)

	e := echo.New()
	req := httptest.NewRequest(http.MethodGet, "/api/leaderboard?limit=5", nil)
	rec := httptest.NewRecorder()
	c := e.NewContext(req, rec)

	err := handler.GetLeaderboard(c)
	require.NoError(t, err)
	assert.Equal(t, http.StatusOK, rec.Code)

	var out []authdto.LeaderboardEntry
	require.NoError(t, json.Unmarshal(rec.Body.Bytes(), &out))
	require.Len(t, out, 1)
	assert.Equal(t, "alex", out[0].Username)
}
