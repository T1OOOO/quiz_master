package api

import (
	"fmt"
	"net/http"
	"quiz_master/internal/models"
	"quiz_master/internal/service"
	"quiz_master/internal/realtime"
	
	"github.com/golang-jwt/jwt/v5"
	"github.com/labstack/echo/v4"
)

type AuthHandler struct {
	service *service.AuthService
}

func NewAuthHandler(s *service.AuthService) *AuthHandler {
	return &AuthHandler{service: s}
}

func (h *AuthHandler) Login(c echo.Context) error {
	var req models.AuthRequest
	if err := c.Bind(&req); err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "invalid request"})
	}
	res, err := h.service.Login(&req)
	if err != nil {
		return c.JSON(http.StatusUnauthorized, map[string]string{"error": err.Error()})
	}
	return c.JSON(http.StatusOK, res)
}

func (h *AuthHandler) Register(c echo.Context) error {
	var req models.AuthRequest
	if err := c.Bind(&req); err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "invalid request"})
	}
	res, err := h.service.Register(&req)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": err.Error()})
	}
	return c.JSON(http.StatusOK, res)
}

func (h *AuthHandler) GuestLogin(c echo.Context) error {
	var req struct {
		Username string `json:"username"`
	}
	_ = c.Bind(&req)
	
	res, err := h.service.GuestLogin(req.Username)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": err.Error()})
	}
	return c.JSON(http.StatusOK, res)
}

func (h *AuthHandler) GetLeaderboard(c echo.Context) error {
	res, err := h.service.GetLeaderboard()
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": err.Error()})
	}
	return c.JSON(http.StatusOK, res)
}

func (h *AuthHandler) SubmitResult(c echo.Context) error {
	user := c.Get("user").(*jwt.Token)
	claims := user.Claims.(jwt.MapClaims)
	userID := claims["user_id"].(string)
	username := claims["username"].(string)

	var req struct {
		QuizID         string `json:"quiz_id"`
		Score          int    `json:"score"`
		TotalQuestions int    `json:"total_questions"`
	}
	if err := c.Bind(&req); err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "Invalid request"})
	}

	err := h.service.SubmitResult(userID, req.QuizID, req.Score, req.TotalQuestions)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "Failed to save result"})
	}

	// Broadcast event
	// We access the global hub. Refactor this later to be injected if needed.
	realtime.GlobalHub.BroadcastEvent(realtime.Event{
		Type:    "quiz_completed",
		User:    username,
		Message: fmt.Sprintf("%s finished quiz %s with score %d/%d!", username, req.QuizID, req.Score, req.TotalQuestions),
	})

	return c.JSON(http.StatusOK, map[string]string{"status": "saved"})
}
