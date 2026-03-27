package quizhttp

import (
	"net/http"

	quizdomain "quiz_master/internal/quiz/domain"
	quizservice "quiz_master/internal/quiz/service"

	"github.com/labstack/echo/v4"
)

type Handler struct {
	service *quizservice.QuizService
}

func NewHandler(s *quizservice.QuizService) *Handler {
	return &Handler{service: s}
}

func (h *Handler) List(c echo.Context) error {
	quizzes, err := h.service.ListQuizzes()
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": err.Error()})
	}
	return c.JSON(http.StatusOK, quizzes)
}

func (h *Handler) Get(c echo.Context) error {
	id := c.Param("id")
	mode := c.QueryParam("mode")

	if mode == "summary" {
		q, err := h.service.GetQuizSummary(id)
		if err != nil {
			return c.JSON(http.StatusInternalServerError, map[string]string{"error": err.Error()})
		}
		if q == nil {
			return c.JSON(http.StatusNotFound, map[string]string{"error": "quiz not found"})
		}
		return c.JSON(http.StatusOK, q)
	}

	q, err := h.service.GetQuiz(id)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": err.Error()})
	}
	if q == nil {
		return c.JSON(http.StatusNotFound, map[string]string{"error": "quiz not found"})
	}
	return c.JSON(http.StatusOK, q)
}

func (h *Handler) GetQuestion(c echo.Context) error {
	id := c.Param("id")
	qid := c.Param("qid")

	q, err := h.service.GetQuestion(id, qid)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": err.Error()})
	}
	if q == nil {
		return c.JSON(http.StatusNotFound, map[string]string{"error": "question not found"})
	}
	return c.JSON(http.StatusOK, q)
}

func (h *Handler) Create(c echo.Context) error {
	var q quizdomain.Quiz
	if err := c.Bind(&q); err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "invalid request"})
	}
	if err := h.service.CreateQuiz(&q); err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": err.Error()})
	}
	return c.JSON(http.StatusCreated, q)
}

func (h *Handler) CheckAnswer(c echo.Context) error {
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
	if res == nil {
		return c.JSON(http.StatusNotFound, map[string]string{"error": "quiz or question not found"})
	}
	return c.JSON(http.StatusOK, res)
}

func (h *Handler) Update(c echo.Context) error {
	id := c.Param("id")
	var q quizdomain.Quiz
	if err := c.Bind(&q); err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "invalid request"})
	}
	q.ID = id
	if err := h.service.UpdateQuiz(&q); err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": err.Error()})
	}
	return c.JSON(http.StatusOK, q)
}

func (h *Handler) Delete(c echo.Context) error {
	id := c.Param("id")
	if err := h.service.DeleteQuiz(id); err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": err.Error()})
	}
	return c.NoContent(http.StatusNoContent)
}

func (h *Handler) Report(c echo.Context) error {
	var report quizdomain.QuizReport
	if err := c.Bind(&report); err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "invalid request"})
	}
	if err := h.service.SubmitReport(&report); err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": err.Error()})
	}

	return c.JSON(http.StatusOK, map[string]string{"status": "reported"})
}
