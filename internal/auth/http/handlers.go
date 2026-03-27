package http

import (
	"fmt"
	"net/http"
	"strconv"

	authdomain "quiz_master/internal/auth/domain"
	authservice "quiz_master/internal/auth/service"
	"quiz_master/internal/realtime"

	"github.com/golang-jwt/jwt/v5"
	"github.com/labstack/echo/v4"
)

type Handler struct {
	service *authservice.Service
	hub     EventBroadcaster
}

type EventBroadcaster interface {
	BroadcastEvent(evt realtime.Event)
}

func NewHandler(service *authservice.Service, hub EventBroadcaster) *Handler {
	return &Handler{service: service, hub: hub}
}

func (h *Handler) Register(c echo.Context) error {
	var req authdomain.AuthRequest
	if err := c.Bind(&req); err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "invalid request"})
	}

	res, err := h.service.Register(&req)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": err.Error()})
	}

	return c.JSON(http.StatusOK, res)
}

func (h *Handler) Login(c echo.Context) error {
	var req authdomain.AuthRequest
	if err := c.Bind(&req); err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "invalid request"})
	}

	res, err := h.service.Login(&req)
	if err != nil {
		return c.JSON(http.StatusUnauthorized, map[string]string{"error": err.Error()})
	}

	return c.JSON(http.StatusOK, res)
}

func (h *Handler) Refresh(c echo.Context) error {
	var req authdomain.RefreshRequest
	if err := c.Bind(&req); err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "invalid request"})
	}

	res, err := h.service.Refresh(req.RefreshToken)
	if err != nil {
		return c.JSON(http.StatusUnauthorized, map[string]string{"error": err.Error()})
	}

	return c.JSON(http.StatusOK, res)
}

func (h *Handler) GuestLogin(c echo.Context) error {
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

func (h *Handler) GetLeaderboard(c echo.Context) error {
	limit := 10
	if rawLimit := c.QueryParam("limit"); rawLimit != "" {
		if parsed, err := strconv.Atoi(rawLimit); err == nil && parsed > 0 {
			limit = parsed
		}
	}

	res, err := h.service.GetLeaderboard(limit)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": err.Error()})
	}

	return c.JSON(http.StatusOK, res)
}

func (h *Handler) GetUserQuota(c echo.Context) error {
	user := c.Get("user").(*jwt.Token)
	claims := user.Claims.(jwt.MapClaims)
	userID, _ := claims["user_id"].(string)

	res, err := h.service.GetUserQuota(userID)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": err.Error()})
	}

	return c.JSON(http.StatusOK, res)
}

func (h *Handler) SubmitResult(c echo.Context) error {
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

	if err := h.service.SubmitResult(userID, req.QuizID, req.Score, req.TotalQuestions); err != nil {
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
