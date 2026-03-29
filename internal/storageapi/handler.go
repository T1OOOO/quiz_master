package storageapi

import (
	"net/http"

	quizdomain "quiz_master/internal/quiz/domain"
	quizservice "quiz_master/internal/quiz/service"
	storagedto "quiz_master/internal/storageapi/dto"

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
	out := make([]storagedto.Quiz, len(quizzes))
	for i, quiz := range quizzes {
		dtoQuiz := toDTOQuiz(&quiz)
		if dtoQuiz != nil {
			out[i] = *dtoQuiz
		}
	}
	return c.JSON(http.StatusOK, out)
}

func (h *Handler) Get(c echo.Context) error {
	id := c.Param("id")
	q, err := h.service.GetRawQuiz(id)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": err.Error()})
	}
	if q == nil {
		return c.JSON(http.StatusNotFound, map[string]string{"error": "quiz not found"})
	}
	return c.JSON(http.StatusOK, toDTOQuiz(q))
}

func (h *Handler) GetSummary(c echo.Context) error {
	id := c.Param("id")
	q, err := h.service.GetRawQuizSummary(id)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": err.Error()})
	}
	if q == nil {
		return c.JSON(http.StatusNotFound, map[string]string{"error": "quiz not found"})
	}
	return c.JSON(http.StatusOK, toDTOQuiz(q))
}

func (h *Handler) GetQuestion(c echo.Context) error {
	id := c.Param("id")
	qid := c.Param("qid")
	q, err := h.service.GetRawQuestion(id, qid)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": err.Error()})
	}
	if q == nil {
		return c.JSON(http.StatusNotFound, map[string]string{"error": "question not found"})
	}
	return c.JSON(http.StatusOK, toDTOQuestion(*q))
}

func (h *Handler) Create(c echo.Context) error {
	var payload storagedto.Quiz
	if err := c.Bind(&payload); err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "invalid request"})
	}
	q := fromDTOQuiz(&payload)
	if q == nil {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "invalid request"})
	}
	if err := h.service.CreateQuiz(q); err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": err.Error()})
	}
	return c.JSON(http.StatusCreated, toDTOQuiz(q))
}

func (h *Handler) Update(c echo.Context) error {
	id := c.Param("id")
	var payload storagedto.Quiz
	if err := c.Bind(&payload); err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "invalid request"})
	}
	q := fromDTOQuiz(&payload)
	if q == nil {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "invalid request"})
	}
	q.ID = id
	if err := h.service.UpdateQuiz(q); err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": err.Error()})
	}
	return c.JSON(http.StatusOK, toDTOQuiz(q))
}

func (h *Handler) Delete(c echo.Context) error {
	id := c.Param("id")
	if err := h.service.DeleteQuiz(id); err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": err.Error()})
	}
	return c.NoContent(http.StatusNoContent)
}

func (h *Handler) Report(c echo.Context) error {
	var payload storagedto.ReportRequest
	if err := c.Bind(&payload); err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "invalid request"})
	}
	report := quizdomain.QuizReport{
		QuizID:       payload.QuizID,
		QuestionID:   payload.QuestionID,
		Message:      payload.Message,
		QuestionText: payload.QuestionText,
	}
	if err := h.service.SubmitReport(&report); err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": err.Error()})
	}
	return c.JSON(http.StatusOK, map[string]string{"status": "reported"})
}
