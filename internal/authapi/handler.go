package authapi

import (
	"net/http"
	"strconv"

	authservice "quiz_master/internal/auth/service"
	authdto "quiz_master/internal/authapi/dto"

	"github.com/labstack/echo/v4"
)

type Handler struct {
	service *authservice.Service
}

func NewHandler(s *authservice.Service) *Handler {
	return &Handler{service: s}
}

func (h *Handler) SubmitResult(c echo.Context) error {
	var req authdto.SubmitResultRequest
	if err := c.Bind(&req); err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "invalid request"})
	}
	if req.UserID == "" || req.QuizID == "" {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "user_id and quiz_id are required"})
	}
	if err := h.service.SubmitResult(req.UserID, req.QuizID, req.Score, req.TotalQuestions); err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": err.Error()})
	}
	return c.JSON(http.StatusOK, map[string]string{"status": "saved"})
}

func (h *Handler) GetLeaderboard(c echo.Context) error {
	limit := 10
	if rawLimit := c.QueryParam("limit"); rawLimit != "" {
		if parsed, err := strconv.Atoi(rawLimit); err == nil && parsed > 0 {
			limit = parsed
		}
	}

	entries, err := h.service.GetLeaderboard(limit)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": err.Error()})
	}
	return c.JSON(http.StatusOK, toDTOLeaderboard(entries))
}

func (h *Handler) GetUserQuota(c echo.Context) error {
	userID := c.Param("userID")
	if userID == "" {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "user_id is required"})
	}
	quota, err := h.service.GetUserQuota(userID)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": err.Error()})
	}
	return c.JSON(http.StatusOK, toDTOQuota(quota))
}
