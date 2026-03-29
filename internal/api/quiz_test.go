package api

import (
	"bytes"
	"database/sql"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	quizdomain "quiz_master/internal/quiz/domain"
	quizdto "quiz_master/internal/quiz/http/dto"
	quizservice "quiz_master/internal/quiz/service"
	storagerepo "quiz_master/internal/storage/repository"

	"github.com/labstack/echo/v4"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	_ "modernc.org/sqlite"
)

func setupQuizHandler(t *testing.T) (*QuizHandler, *sql.DB) {
	db, err := sql.Open("sqlite", ":memory:")
	require.NoError(t, err)

	_, err = db.Exec(`
		CREATE TABLE quizzes (
			id TEXT PRIMARY KEY,
			title TEXT,
			description TEXT,
			category TEXT
		)
	`)
	require.NoError(t, err)

	_, err = db.Exec(`
		CREATE TABLE questions (
			id TEXT PRIMARY KEY,
			quiz_id TEXT,
			type TEXT,
			text TEXT,
			options TEXT,
			correct_answer_index INTEGER,
			correct_text TEXT,
			correct_multi TEXT,
			image_url TEXT,
			explanation TEXT,
			difficulty INTEGER
		)
	`)
	require.NoError(t, err)

	repo := storagerepo.NewQuizRepository(db)
	quizService := quizservice.New(repo)
	handler := NewQuizHandler(quizService)

	return handler, db
}

func TestQuizHandler_List(t *testing.T) {
	handler, db := setupQuizHandler(t)
	defer db.Close()

	repo := storagerepo.NewQuizRepository(db)
	quiz := &quizdomain.Quiz{
		ID:          "test-quiz",
		Title:       "Test Quiz",
		Description: "Description",
		Category:    "Category",
		Questions:   []quizdomain.Question{},
	}
	require.NoError(t, repo.Create(quiz))

	e := echo.New()
	req := httptest.NewRequest(http.MethodGet, "/quizzes", nil)
	rec := httptest.NewRecorder()
	c := e.NewContext(req, rec)

	err := handler.List(c)
	require.NoError(t, err)
	assert.Equal(t, http.StatusOK, rec.Code)

	var quizzes []quizdomain.Quiz
	err = json.Unmarshal(rec.Body.Bytes(), &quizzes)
	require.NoError(t, err)
	assert.Len(t, quizzes, 1)
}

func TestQuizHandler_Get(t *testing.T) {
	handler, db := setupQuizHandler(t)
	defer db.Close()

	repo := storagerepo.NewQuizRepository(db)
	quiz := &quizdomain.Quiz{
		ID:          "test-quiz",
		Title:       "Test Quiz",
		Description: "Description",
		Category:    "Category",
		Questions: []quizdomain.Question{
			{
				ID:                 "q1",
				Type:               "choice",
				Text:               "Question?",
				Options:            []string{"A", "B"},
				CorrectAnswerIndex: 0,
			},
		},
	}
	require.NoError(t, repo.Create(quiz))

	e := echo.New()
	req := httptest.NewRequest(http.MethodGet, "/quizzes/test-quiz", nil)
	rec := httptest.NewRecorder()
	c := e.NewContext(req, rec)
	c.SetPath("/quizzes/:id")
	c.SetParamNames("id")
	c.SetParamValues("test-quiz")

	err := handler.Get(c)
	require.NoError(t, err)
	assert.Equal(t, http.StatusOK, rec.Code)

	var result quizdto.QuizPublic
	err = json.Unmarshal(rec.Body.Bytes(), &result)
	require.NoError(t, err)
	assert.Equal(t, "test-quiz", result.ID)
	assert.Equal(t, "Test Quiz", result.Title)
}

func TestQuizHandler_Get_Summary(t *testing.T) {
	handler, db := setupQuizHandler(t)
	defer db.Close()

	repo := storagerepo.NewQuizRepository(db)
	quiz := &quizdomain.Quiz{
		ID:          "test-quiz",
		Title:       "Test Quiz",
		Description: "Description",
		Category:    "Category",
		Questions: []quizdomain.Question{
			{
				ID:                 "q1",
				Type:               "choice",
				Text:               "Question?",
				Options:            []string{"A", "B"},
				CorrectAnswerIndex: 0,
				Difficulty:         1,
			},
		},
	}
	require.NoError(t, repo.Create(quiz))

	e := echo.New()
	req := httptest.NewRequest(http.MethodGet, "/quizzes/test-quiz?mode=summary", nil)
	rec := httptest.NewRecorder()
	c := e.NewContext(req, rec)
	c.SetPath("/quizzes/:id")
	c.SetParamNames("id")
	c.SetParamValues("test-quiz")

	err := handler.Get(c)
	require.NoError(t, err)
	assert.Equal(t, http.StatusOK, rec.Code)

	var result quizdto.QuizPublic
	err = json.Unmarshal(rec.Body.Bytes(), &result)
	require.NoError(t, err)
	assert.Equal(t, "test-quiz", result.ID)
	assert.Len(t, result.Questions, 1)
}

func TestQuizHandler_Get_NotFound(t *testing.T) {
	handler, _ := setupQuizHandler(t)

	e := echo.New()
	req := httptest.NewRequest(http.MethodGet, "/quizzes/nonexistent", nil)
	rec := httptest.NewRecorder()
	c := e.NewContext(req, rec)
	c.SetPath("/quizzes/:id")
	c.SetParamNames("id")
	c.SetParamValues("nonexistent")

	err := handler.Get(c)
	require.NoError(t, err)
	assert.Equal(t, http.StatusNotFound, rec.Code)
}

func TestQuizHandler_GetQuestion(t *testing.T) {
	handler, db := setupQuizHandler(t)
	defer db.Close()

	repo := storagerepo.NewQuizRepository(db)
	quiz := &quizdomain.Quiz{
		ID:          "test-quiz",
		Title:       "Test Quiz",
		Description: "Description",
		Category:    "Category",
		Questions: []quizdomain.Question{
			{
				ID:                 "q1",
				Type:               "choice",
				Text:               "Question?",
				Options:            []string{"A", "B", "C"},
				CorrectAnswerIndex: 0,
				ImageURL:           "http://example.com/img.jpg",
			},
		},
	}
	require.NoError(t, repo.Create(quiz))

	e := echo.New()
	req := httptest.NewRequest(http.MethodGet, "/quizzes/test-quiz/questions/q1", nil)
	rec := httptest.NewRecorder()
	c := e.NewContext(req, rec)
	c.SetPath("/quizzes/:id/questions/:qid")
	c.SetParamNames("id", "qid")
	c.SetParamValues("test-quiz", "q1")

	err := handler.GetQuestion(c)
	require.NoError(t, err)
	assert.Equal(t, http.StatusOK, rec.Code)

	var result quizdto.QuestionPublic
	err = json.Unmarshal(rec.Body.Bytes(), &result)
	require.NoError(t, err)
	assert.Equal(t, "q1", result.ID)
	assert.Equal(t, "Question?", result.Text)
}

func TestQuizHandler_CheckAnswer(t *testing.T) {
	handler, db := setupQuizHandler(t)
	defer db.Close()

	repo := storagerepo.NewQuizRepository(db)
	quiz := &quizdomain.Quiz{
		ID:          "test-quiz",
		Title:       "Test Quiz",
		Description: "Description",
		Category:    "Category",
		Questions: []quizdomain.Question{
			{
				ID:                 "q1",
				Type:               "choice",
				Text:               "Question?",
				Options:            []string{"A", "B", "C"},
				CorrectAnswerIndex: 0,
				Explanation:        "A is correct",
			},
		},
	}
	require.NoError(t, repo.Create(quiz))

	e := echo.New()
	body := map[string]interface{}{
		"question_id": "q1",
		"answer":      0,
	}
	bodyBytes, _ := json.Marshal(body)
	req := httptest.NewRequest(http.MethodPost, "/quizzes/test-quiz/check", bytes.NewReader(bodyBytes))
	req.Header.Set(echo.HeaderContentType, echo.MIMEApplicationJSON)
	rec := httptest.NewRecorder()
	c := e.NewContext(req, rec)
	c.SetPath("/quizzes/:id/check")
	c.SetParamNames("id")
	c.SetParamValues("test-quiz")

	err := handler.CheckAnswer(c)
	require.NoError(t, err)
	assert.Equal(t, http.StatusOK, rec.Code)

	var result quizdto.AnswerResult
	err = json.Unmarshal(rec.Body.Bytes(), &result)
	require.NoError(t, err)
	assert.True(t, result.Correct)
	assert.Equal(t, "A is correct", result.Explanation)
}
