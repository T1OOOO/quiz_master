package server

import (
	"fmt"
	"net/http"

	authdomain "quiz_master/internal/auth/domain"
	authdto "quiz_master/internal/authapi/dto"
	"quiz_master/internal/realtime"

	"github.com/golang-jwt/jwt/v5"
	"github.com/labstack/echo/v4"
)

type authGatewayClient interface {
	Register(req *authdomain.AuthRequest) (*authdomain.AuthResponse, error)
	Login(req *authdomain.AuthRequest) (*authdomain.AuthResponse, error)
	GuestLogin(username string) (*authdomain.AuthResponse, error)
	Refresh(refreshToken string) (*authdomain.AuthResponse, error)
	GetLeaderboard(limit int) ([]authdto.LeaderboardEntry, error)
	GetUserQuota(userID string) (*authdomain.UserQuota, error)
	SubmitResult(userID, quizID string, score, totalQuestions int) error
}

type authGatewayHandler struct {
	client authGatewayClient
	hub    *realtime.Hub
}

func newAuthGatewayHandler(client authGatewayClient, hub *realtime.Hub) *authGatewayHandler {
	return &authGatewayHandler{client: client, hub: hub}
}

func (h *authGatewayHandler) Register(c echo.Context) error {
	var req authdomain.AuthRequest
	if err := c.Bind(&req); err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "invalid request"})
	}
	res, err := h.client.Register(&req)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": err.Error()})
	}
	return c.JSON(http.StatusOK, res)
}

func (h *authGatewayHandler) Login(c echo.Context) error {
	var req authdomain.AuthRequest
	if err := c.Bind(&req); err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "invalid request"})
	}
	res, err := h.client.Login(&req)
	if err != nil {
		return c.JSON(http.StatusUnauthorized, map[string]string{"error": err.Error()})
	}
	return c.JSON(http.StatusOK, res)
}

func (h *authGatewayHandler) GuestLogin(c echo.Context) error {
	var req struct {
		Username string `json:"username"`
	}
	_ = c.Bind(&req)
	res, err := h.client.GuestLogin(req.Username)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": err.Error()})
	}
	return c.JSON(http.StatusOK, res)
}

func (h *authGatewayHandler) Refresh(c echo.Context) error {
	var req authdomain.RefreshRequest
	if err := c.Bind(&req); err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "invalid request"})
	}
	res, err := h.client.Refresh(req.RefreshToken)
	if err != nil {
		return c.JSON(http.StatusUnauthorized, map[string]string{"error": err.Error()})
	}
	return c.JSON(http.StatusOK, res)
}

func (h *authGatewayHandler) GetLeaderboard(c echo.Context) error {
	limit := 10
	if raw := c.QueryParam("limit"); raw != "" {
		var parsed int
		_, _ = fmt.Sscanf(raw, "%d", &parsed)
		if parsed > 0 {
			limit = parsed
		}
	}
	res, err := h.client.GetLeaderboard(limit)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": err.Error()})
	}
	return c.JSON(http.StatusOK, res)
}

func (h *authGatewayHandler) GetUserQuota(c echo.Context) error {
	user := c.Get("user").(*jwt.Token)
	claims := user.Claims.(jwt.MapClaims)
	userID, _ := claims["user_id"].(string)
	res, err := h.client.GetUserQuota(userID)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": err.Error()})
	}
	return c.JSON(http.StatusOK, res)
}

func (h *authGatewayHandler) SubmitResult(c echo.Context) error {
	user := c.Get("user").(*jwt.Token)
	claims := user.Claims.(jwt.MapClaims)
	userID, _ := claims["user_id"].(string)
	username, _ := claims["username"].(string)

	var req struct {
		QuizID         string `json:"quiz_id"`
		Score          int    `json:"score"`
		TotalQuestions int    `json:"total_questions"`
	}
	if err := c.Bind(&req); err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "Invalid request"})
	}

	if err := h.client.SubmitResult(userID, req.QuizID, req.Score, req.TotalQuestions); err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "Failed to save result"})
	}

	if h.hub != nil {
		h.hub.BroadcastEvent(realtime.Event{
			Type:    "quiz_completed",
			User:    username,
			Message: fmt.Sprintf("%s finished quiz %s with score %d/%d!", username, req.QuizID, req.Score, req.TotalQuestions),
		})
	}

	return c.JSON(http.StatusOK, map[string]string{"status": "saved"})
}
