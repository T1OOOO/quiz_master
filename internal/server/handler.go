package server

import (
	"fmt"
	"net/http"
	"quiz_master/internal/quiz"
	"quiz_master/internal/realtime"

	"github.com/labstack/echo/v4"
)

type Handler struct {
	Service *quiz.Service
}

func NewHandler(s *quiz.Service) *Handler {
	return &Handler{Service: s}
}

func (h *Handler) RegisterRoutes(e *echo.Echo) {
	api := e.Group("/api")
	api.GET("/quizzes", h.ListQuizzes)
	api.GET("/quizzes/:id", h.GetQuiz)
	api.POST("/quizzes/:id/check", h.CheckAnswer)
}

func (h *Handler) ListQuizzes(c echo.Context) error {
	list, err := h.Service.List()
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "Failed to fetch quizzes"})
	}
	return c.JSON(http.StatusOK, list)
}

func (h *Handler) GetQuiz(c echo.Context) error {
	id := c.Param("id")
	q, err := h.Service.Get(id)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "Database error"})
	}
	if q == nil {
		return c.JSON(http.StatusNotFound, map[string]string{"error": "Quiz not found"})
	}
	return c.JSON(http.StatusOK, q)
}

func (h *Handler) CreateQuiz(c echo.Context) error {
	var q quiz.Quiz
	if err := c.Bind(&q); err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "Invalid request"})
	}
	
	if err := h.Service.Create(&q); err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "Failed to create quiz"})
	}
	
	return c.JSON(http.StatusCreated, q)
}

func (h *Handler) UpdateQuiz(c echo.Context) error {
	id := c.Param("id")
	var q quiz.Quiz
	if err := c.Bind(&q); err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "Invalid request"})
	}
	q.ID = id
	
	if err := h.Service.Update(&q); err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "Failed to update quiz"})
	}
	
	return c.JSON(http.StatusOK, q)
}

func (h *Handler) DeleteQuiz(c echo.Context) error {
	id := c.Param("id")
	if err := h.Service.Delete(id); err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "Failed to delete quiz"})
	}
	return c.JSON(http.StatusOK, map[string]string{"status": "deleted"})
}

func (h *Handler) CheckAnswer(c echo.Context) error {
	id := c.Param("id")
	var req quiz.AnswerAttempt
	if err := c.Bind(&req); err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "Invalid request"})
	}

	req.QuizID = id

	result, ok := h.Service.CheckAnswer(req.QuizID, req.QuestionID, req.AnswerIndex)
	if !ok {
		return c.JSON(http.StatusNotFound, map[string]string{"error": "Quiz or Question not found"})
	}

	if result.Correct {
		realtime.GlobalHub.BroadcastEvent(realtime.Event{
			Type:    "answer_correct",
			Message: fmt.Sprintf("Someone answered a question correctly in %s!", req.QuizID),
		})
	}

	return c.JSON(http.StatusOK, result)
}
