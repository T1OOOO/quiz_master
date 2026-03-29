package storageapi

import (
	"bytes"
	"database/sql"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	quizdomain "quiz_master/internal/quiz/domain"
	quizservice "quiz_master/internal/quiz/service"
	storagerepo "quiz_master/internal/storage/repository"
	storagedto "quiz_master/internal/storageapi/dto"

	"github.com/labstack/echo/v4"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	_ "modernc.org/sqlite"
)

func setupHandler(t *testing.T) (*Handler, *sql.DB) {
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

	_, err = db.Exec(`
		CREATE TABLE reports (
			id TEXT PRIMARY KEY,
			quiz_id TEXT,
			question_id TEXT,
			message TEXT,
			question_text TEXT,
			created_at DATETIME
		)
	`)
	require.NoError(t, err)

	repo := storagerepo.NewQuizRepository(db)
	return NewHandler(quizservice.New(repo), nil), db
}

func TestHandlerCreate_UsesContractDTO(t *testing.T) {
	handler, db := setupHandler(t)
	defer db.Close()

	payload, err := json.Marshal(storagedto.Quiz{
		ID:          "quiz-1",
		Title:       "Quiz 1",
		Description: "Desc",
		Category:    "General",
		Questions: []storagedto.Question{
			{
				ID:                 "q1",
				Type:               "choice",
				Text:               "Question?",
				Options:            []string{"A", "B"},
				CorrectAnswerIndex: 0,
			},
		},
	})
	require.NoError(t, err)

	e := echo.New()
	req := httptest.NewRequest(http.MethodPost, "/internal/storage/quizzes", bytes.NewReader(payload))
	req.Header.Set(echo.HeaderContentType, echo.MIMEApplicationJSON)
	rec := httptest.NewRecorder()
	c := e.NewContext(req, rec)

	err = handler.Create(c)
	require.NoError(t, err)
	assert.Equal(t, http.StatusCreated, rec.Code)

	var result storagedto.Quiz
	require.NoError(t, json.Unmarshal(rec.Body.Bytes(), &result))
	assert.Equal(t, "quiz-1", result.ID)
	assert.Len(t, result.Questions, 1)
}

func TestHandlerGetQuestion_UsesContractDTO(t *testing.T) {
	handler, db := setupHandler(t)
	defer db.Close()

	repo := storagerepo.NewQuizRepository(db)
	require.NoError(t, repo.Create(&quizdomain.Quiz{
		ID:          "quiz-1",
		Title:       "Quiz 1",
		Description: "Desc",
		Category:    "General",
		Questions: []quizdomain.Question{
			{
				ID:                 "q1",
				Type:               "choice",
				Text:               "Question?",
				Options:            []string{"A", "B"},
				CorrectAnswerIndex: 0,
				Explanation:        "Because A",
			},
		},
	}))

	e := echo.New()
	req := httptest.NewRequest(http.MethodGet, "/internal/storage/quizzes/quiz-1/questions/q1", nil)
	rec := httptest.NewRecorder()
	c := e.NewContext(req, rec)
	c.SetParamNames("id", "qid")
	c.SetParamValues("quiz-1", "q1")

	err := handler.GetQuestion(c)
	require.NoError(t, err)
	assert.Equal(t, http.StatusOK, rec.Code)

	var result storagedto.Question
	require.NoError(t, json.Unmarshal(rec.Body.Bytes(), &result))
	assert.Equal(t, "q1", result.ID)
	assert.Equal(t, "Because A", result.Explanation)
}
