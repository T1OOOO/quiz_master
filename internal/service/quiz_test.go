package service

import (
	"database/sql"
	"testing"

	"quiz_master/internal/models"
	"quiz_master/internal/store"

	_ "modernc.org/sqlite"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func setupTestDB(t *testing.T) *sql.DB {
	db, err := sql.Open("sqlite", ":memory:")
	require.NoError(t, err)

	// Create schema
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

	return db
}

func TestQuizService_ListQuizzes(t *testing.T) {
	db := setupTestDB(t)
	defer db.Close()

	repo := store.NewQuizStore(db)
	service := NewQuizService(repo)

	// Create test quiz
	quiz := &models.Quiz{
		ID:          "test-quiz-1",
		Title:       "Test Quiz",
		Description: "Test Description",
		Category:    "Test",
		Questions: []models.Question{
			{
				ID:                 "q1",
				Type:               "choice",
				Text:               "Test question?",
				Options:            []string{"A", "B", "C"},
				CorrectAnswerIndex: 0,
			},
		},
	}
	require.NoError(t, repo.Create(quiz))

	// Test
	quizzes, err := service.ListQuizzes()
	require.NoError(t, err)
	assert.Len(t, quizzes, 1)
	assert.Equal(t, "test-quiz-1", quizzes[0].ID)
}

func TestQuizService_GetQuiz(t *testing.T) {
	db := setupTestDB(t)
	defer db.Close()

	repo := store.NewQuizStore(db)
	service := NewQuizService(repo)

	// Create test quiz
	quiz := &models.Quiz{
		ID:          "test-quiz-1",
		Title:       "Test Quiz",
		Description: "Test Description",
		Category:    "Test",
		Questions: []models.Question{
			{
				ID:                 "q1",
				Type:               "choice",
				Text:               "Test question?",
				Options:            []string{"A", "B", "C"},
				CorrectAnswerIndex: 0,
			},
		},
	}
	require.NoError(t, repo.Create(quiz))

	// Test
	result, err := service.GetQuiz("test-quiz-1")
	require.NoError(t, err)
	require.NotNil(t, result)
	assert.Equal(t, "test-quiz-1", result.ID)
	assert.Equal(t, "Test Quiz", result.Title)
	assert.Len(t, result.Questions, 1)
}

func TestQuizService_GetQuizSummary(t *testing.T) {
	db := setupTestDB(t)
	defer db.Close()

	repo := store.NewQuizStore(db)
	service := NewQuizService(repo)

	// Create test quiz
	quiz := &models.Quiz{
		ID:          "test-quiz-1",
		Title:       "Test Quiz",
		Description: "Test Description",
		Category:    "Test",
		Questions: []models.Question{
			{
				ID:                 "q1",
				Type:               "choice",
				Text:               "Test question?",
				Options:            []string{"A", "B", "C"},
				CorrectAnswerIndex: 0,
				Difficulty:         1,
			},
		},
	}
	require.NoError(t, repo.Create(quiz))

	// Test
	result, err := service.GetQuizSummary("test-quiz-1")
	require.NoError(t, err)
	require.NotNil(t, result)
	assert.Equal(t, "test-quiz-1", result.ID)
	assert.Len(t, result.Questions, 1)
	// Summary should have lightweight questions
	assert.Equal(t, "q1", result.Questions[0].ID)
}

func TestQuizService_GetQuestion(t *testing.T) {
	db := setupTestDB(t)
	defer db.Close()

	repo := store.NewQuizStore(db)
	service := NewQuizService(repo)

	// Create test quiz
	quiz := &models.Quiz{
		ID:          "test-quiz-1",
		Title:       "Test Quiz",
		Description: "Test Description",
		Category:    "Test",
		Questions: []models.Question{
			{
				ID:                 "q1",
				Type:               "choice",
				Text:               "Test question?",
				Options:            []string{"A", "B", "C"},
				CorrectAnswerIndex: 0,
				ImageURL:           "http://example.com/image.jpg",
			},
		},
	}
	require.NoError(t, repo.Create(quiz))

	// Test
	result, err := service.GetQuestion("test-quiz-1", "q1")
	require.NoError(t, err)
	require.NotNil(t, result)
	assert.Equal(t, "q1", result.ID)
	assert.Equal(t, "Test question?", result.Text)
	assert.Equal(t, "http://example.com/image.jpg", result.ImageURL)
}

func TestQuizService_CheckAnswer_Choice(t *testing.T) {
	db := setupTestDB(t)
	defer db.Close()

	repo := store.NewQuizStore(db)
	service := NewQuizService(repo)

	// Create test quiz
	quiz := &models.Quiz{
		ID:          "test-quiz-1",
		Title:       "Test Quiz",
		Description: "Test Description",
		Category:    "Test",
		Questions: []models.Question{
			{
				ID:                 "q1",
				Type:               "choice",
				Text:               "Test question?",
				Options:            []string{"A", "B", "C"},
				CorrectAnswerIndex: 0,
				Explanation:        "A is correct",
			},
		},
	}
	require.NoError(t, repo.Create(quiz))

	// Test correct answer
	result, err := service.CheckAnswer("test-quiz-1", "q1", 0)
	require.NoError(t, err)
	require.NotNil(t, result)
	assert.True(t, result.Correct)
	assert.Equal(t, 0, result.CorrectAnswer)
	assert.Equal(t, "A is correct", result.Explanation)

	// Test incorrect answer
	result, err = service.CheckAnswer("test-quiz-1", "q1", 1)
	require.NoError(t, err)
	require.NotNil(t, result)
	assert.False(t, result.Correct)
}

func TestQuizService_CheckAnswer_Text(t *testing.T) {
	db := setupTestDB(t)
	defer db.Close()

	repo := store.NewQuizStore(db)
	service := NewQuizService(repo)

	// Create test quiz
	quiz := &models.Quiz{
		ID:          "test-quiz-1",
		Title:       "Test Quiz",
		Description: "Test Description",
		Category:    "Test",
		Questions: []models.Question{
			{
				ID:          "q1",
				Type:        "text",
				Text:        "What is the answer?",
				CorrectText: "answer",
			},
		},
	}
	require.NoError(t, repo.Create(quiz))

	// Test correct answer
	result, err := service.CheckAnswer("test-quiz-1", "q1", "answer")
	require.NoError(t, err)
	require.NotNil(t, result)
	assert.True(t, result.Correct)

	// Test incorrect answer
	result, err = service.CheckAnswer("test-quiz-1", "q1", "wrong")
	require.NoError(t, err)
	require.NotNil(t, result)
	assert.False(t, result.Correct)
}

func TestQuizService_CreateQuiz(t *testing.T) {
	db := setupTestDB(t)
	defer db.Close()

	repo := store.NewQuizStore(db)
	service := NewQuizService(repo)

	quiz := &models.Quiz{
		ID:          "new-quiz",
		Title:       "New Quiz",
		Description: "New Description",
		Category:    "New Category",
		Questions: []models.Question{
			{
				ID:                 "q1",
				Type:               "choice",
				Text:               "Question?",
				Options:            []string{"A", "B"},
				CorrectAnswerIndex: 0,
			},
		},
	}

	err := service.CreateQuiz(quiz)
	require.NoError(t, err)

	// Verify
	result, err := service.GetQuiz("new-quiz")
	require.NoError(t, err)
	require.NotNil(t, result)
	assert.Equal(t, "New Quiz", result.Title)
}

func TestQuizService_UpdateQuiz(t *testing.T) {
	db := setupTestDB(t)
	defer db.Close()

	repo := store.NewQuizStore(db)
	service := NewQuizService(repo)

	// Create initial quiz
	quiz := &models.Quiz{
		ID:          "update-quiz",
		Title:       "Original Title",
		Description: "Original Description",
		Category:    "Original",
		Questions:   []models.Question{},
	}
	require.NoError(t, service.CreateQuiz(quiz))

	// Update
	quiz.Title = "Updated Title"
	err := service.UpdateQuiz(quiz)
	require.NoError(t, err)

	// Verify
	result, err := service.GetQuiz("update-quiz")
	require.NoError(t, err)
	require.NotNil(t, result)
	assert.Equal(t, "Updated Title", result.Title)
}

func TestQuizService_DeleteQuiz(t *testing.T) {
	db := setupTestDB(t)
	defer db.Close()

	repo := store.NewQuizStore(db)
	service := NewQuizService(repo)

	// Create quiz
	quiz := &models.Quiz{
		ID:          "delete-quiz",
		Title:       "To Delete",
		Description: "Description",
		Category:    "Category",
		Questions:   []models.Question{},
	}
	require.NoError(t, service.CreateQuiz(quiz))

	// Delete
	err := service.DeleteQuiz("delete-quiz")
	require.NoError(t, err)

	// Verify
	result, err := service.GetQuiz("delete-quiz")
	require.NoError(t, err)
	assert.Nil(t, result)
}
