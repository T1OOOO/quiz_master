package store

import (
	"database/sql"
	"testing"

	"quiz_master/internal/models"

	_ "modernc.org/sqlite"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func setupQuizStoreDB(t *testing.T) *sql.DB {
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

	return db
}

func TestQuizStore_Create(t *testing.T) {
	db := setupQuizStoreDB(t)
	defer db.Close()

	store := NewQuizStore(db)

	quiz := &models.Quiz{
		ID:          "test-quiz",
		Title:       "Test Quiz",
		Description: "Description",
		Category:    "Category",
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

	err := store.Create(quiz)
	require.NoError(t, err)

	// Verify
	result, err := store.Get("test-quiz")
	require.NoError(t, err)
	require.NotNil(t, result)
	assert.Equal(t, "Test Quiz", result.Title)
	assert.Len(t, result.Questions, 1)
}

func TestQuizStore_Get(t *testing.T) {
	db := setupQuizStoreDB(t)
	defer db.Close()

	store := NewQuizStore(db)

	quiz := &models.Quiz{
		ID:          "test-quiz",
		Title:       "Test Quiz",
		Description: "Description",
		Category:    "Category",
		Questions: []models.Question{
			{
				ID:                 "q1",
				Type:               "choice",
				Text:               "Question?",
				Options:            []string{"A", "B", "C"},
				CorrectAnswerIndex: 0,
				ImageURL:           "http://example.com/img.jpg",
				Explanation:        "Explanation",
				Difficulty:         1,
			},
		},
	}
	require.NoError(t, store.Create(quiz))

	// Test
	result, err := store.Get("test-quiz")
	require.NoError(t, err)
	require.NotNil(t, result)
	assert.Equal(t, "Test Quiz", result.Title)
	assert.Len(t, result.Questions, 1)
	assert.Equal(t, "q1", result.Questions[0].ID)
	assert.Equal(t, "http://example.com/img.jpg", result.Questions[0].ImageURL)
}

func TestQuizStore_Get_NotFound(t *testing.T) {
	db := setupQuizStoreDB(t)
	defer db.Close()

	store := NewQuizStore(db)

	result, err := store.Get("nonexistent")
	require.NoError(t, err)
	assert.Nil(t, result)
}

func TestQuizStore_GetSummary(t *testing.T) {
	db := setupQuizStoreDB(t)
	defer db.Close()

	store := NewQuizStore(db)

	quiz := &models.Quiz{
		ID:          "test-quiz",
		Title:       "Test Quiz",
		Description: "Description",
		Category:    "Category",
		Questions: []models.Question{
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
	require.NoError(t, store.Create(quiz))

	// Test
	result, err := store.GetSummary("test-quiz")
	require.NoError(t, err)
	require.NotNil(t, result)
	assert.Equal(t, "Test Quiz", result.Title)
	assert.Len(t, result.Questions, 1)
	// Summary should have lightweight data
	assert.Equal(t, "q1", result.Questions[0].ID)
	assert.Equal(t, "Question?", result.Questions[0].Text)
	assert.Empty(t, result.Questions[0].Options) // Options should be empty in summary
}

func TestQuizStore_GetQuestion(t *testing.T) {
	db := setupQuizStoreDB(t)
	defer db.Close()

	store := NewQuizStore(db)

	quiz := &models.Quiz{
		ID:          "test-quiz",
		Title:       "Test Quiz",
		Description: "Description",
		Category:    "Category",
		Questions: []models.Question{
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
	require.NoError(t, store.Create(quiz))

	// Test
	result, err := store.GetQuestion("test-quiz", "q1")
	require.NoError(t, err)
	require.NotNil(t, result)
	assert.Equal(t, "q1", result.ID)
	assert.Equal(t, "Question?", result.Text)
	assert.Len(t, result.Options, 3)
	assert.Equal(t, "http://example.com/img.jpg", result.ImageURL)
}

func TestQuizStore_Update(t *testing.T) {
	db := setupQuizStoreDB(t)
	defer db.Close()

	store := NewQuizStore(db)

	// Create
	quiz := &models.Quiz{
		ID:          "test-quiz",
		Title:       "Original Title",
		Description: "Original Description",
		Category:    "Original",
		Questions:   []models.Question{},
	}
	require.NoError(t, store.Create(quiz))

	// Update
	quiz.Title = "Updated Title"
	quiz.Questions = []models.Question{
		{
			ID:                 "q1",
			Type:               "choice",
			Text:               "New Question?",
			Options:            []string{"A", "B"},
			CorrectAnswerIndex: 0,
		},
	}
	err := store.Update(quiz)
	require.NoError(t, err)

	// Verify
	result, err := store.Get("test-quiz")
	require.NoError(t, err)
	require.NotNil(t, result)
	assert.Equal(t, "Updated Title", result.Title)
	assert.Len(t, result.Questions, 1)
}

func TestQuizStore_Delete(t *testing.T) {
	db := setupQuizStoreDB(t)
	defer db.Close()

	store := NewQuizStore(db)

	quiz := &models.Quiz{
		ID:          "test-quiz",
		Title:       "Test Quiz",
		Description: "Description",
		Category:    "Category",
		Questions:   []models.Question{},
	}
	require.NoError(t, store.Create(quiz))

	// Delete
	err := store.Delete("test-quiz")
	require.NoError(t, err)

	// Verify
	result, err := store.Get("test-quiz")
	require.NoError(t, err)
	assert.Nil(t, result)
}

func TestQuizStore_List(t *testing.T) {
	db := setupQuizStoreDB(t)
	defer db.Close()

	store := NewQuizStore(db)

	// Create multiple quizzes
	quiz1 := &models.Quiz{ID: "quiz1", Title: "Quiz 1", Description: "Desc 1", Category: "Cat1", Questions: []models.Question{}}
	quiz2 := &models.Quiz{ID: "quiz2", Title: "Quiz 2", Description: "Desc 2", Category: "Cat2", Questions: []models.Question{}}
	require.NoError(t, store.Create(quiz1))
	require.NoError(t, store.Create(quiz2))

	// Test
	quizzes, err := store.List()
	require.NoError(t, err)
	assert.Len(t, quizzes, 2)
}
