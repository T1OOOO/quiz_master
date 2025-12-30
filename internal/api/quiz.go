package api

import (
	"net/http"
	"quiz_master/internal/models"
	"quiz_master/internal/service"
	"github.com/labstack/echo/v4"
)

type QuizHandler struct {
	service *service.QuizService
}

func NewQuizHandler(s *service.QuizService) *QuizHandler {
	return &QuizHandler{service: s}
}

func (h *QuizHandler) List(c echo.Context) error {
	quizzes, err := h.service.ListQuizzes()
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": err.Error()})
	}
	return c.JSON(http.StatusOK, quizzes)
}

func (h *QuizHandler) Get(c echo.Context) error {
	id := c.Param("id")
	q, err := h.service.GetQuiz(id)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": err.Error()})
	}
	if q == nil {
		return c.JSON(http.StatusNotFound, map[string]string{"error": "quiz not found"})
	}
	return c.JSON(http.StatusOK, q)
}

func (h *QuizHandler) Create(c echo.Context) error {
	var q models.Quiz
	if err := c.Bind(&q); err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "invalid request"})
	}
	if err := h.service.CreateQuiz(&q); err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": err.Error()})
	}
	return c.JSON(http.StatusCreated, q)
}

func (h *QuizHandler) CheckAnswer(c echo.Context) error {
	quizID := c.Param("id")
	var req struct {
		QuestionID string `json:"question_id"`
		Answer     int    `json:"answer"`
	}
	if err := c.Bind(&req); err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "invalid request"})
	}
	res, err := h.service.CheckAnswer(quizID, req.QuestionID, req.Answer)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": err.Error()})
	}
	return c.JSON(http.StatusOK, res)
}

func (h *QuizHandler) Update(c echo.Context) error {
	id := c.Param("id")
	var q models.Quiz
	if err := c.Bind(&q); err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "invalid request"})
	}
	q.ID = id
	if err := h.service.UpdateQuiz(&q); err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": err.Error()})
	}
	return c.JSON(http.StatusOK, q)
}

func (h *QuizHandler) Delete(c echo.Context) error {
	id := c.Param("id")
	if err := h.service.DeleteQuiz(id); err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": err.Error()})
	}
	return c.NoContent(http.StatusNoContent)
}
