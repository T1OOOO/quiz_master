package store

import (
	"database/sql"
	"testing"

	"quiz_master/internal/models"

	_ "modernc.org/sqlite"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func setupUserStoreDB(t *testing.T) *sql.DB {
	db, err := sql.Open("sqlite", ":memory:")
	require.NoError(t, err)

	_, err = db.Exec(`
		CREATE TABLE users (
			id TEXT PRIMARY KEY,
			username TEXT UNIQUE,
			password TEXT,
			role TEXT
		)
	`)
	require.NoError(t, err)

	_, err = db.Exec(`
		CREATE TABLE quiz_results (
			id TEXT PRIMARY KEY,
			user_id TEXT,
			quiz_id TEXT,
			score INTEGER,
			total_questions INTEGER,
			completed_at DATETIME
		)
	`)
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

	return db
}

func TestUserStore_Create(t *testing.T) {
	db := setupUserStoreDB(t)
	defer db.Close()

	store := NewUserStore(db)

	user := &models.User{
		ID:       "user1",
		Username: "testuser",
		Password: "hashedpassword",
		Role:     "user",
	}

	err := store.Create(user)
	require.NoError(t, err)

	// Verify
	result, err := store.GetByUsername("testuser")
	require.NoError(t, err)
	require.NotNil(t, result)
	assert.Equal(t, "testuser", result.Username)
	assert.Equal(t, "hashedpassword", result.Password)
}

func TestUserStore_Create_DuplicateUsername(t *testing.T) {
	db := setupUserStoreDB(t)
	defer db.Close()

	store := NewUserStore(db)

	user1 := &models.User{ID: "user1", Username: "testuser", Password: "pwd1", Role: "user"}
	user2 := &models.User{ID: "user2", Username: "testuser", Password: "pwd2", Role: "user"}

	require.NoError(t, store.Create(user1))
	err := store.Create(user2)
	assert.Error(t, err) // Should fail due to unique constraint
}

func TestUserStore_GetByUsername(t *testing.T) {
	db := setupUserStoreDB(t)
	defer db.Close()

	store := NewUserStore(db)

	user := &models.User{
		ID:       "user1",
		Username: "testuser",
		Password: "hashedpassword",
		Role:     "user",
	}
	require.NoError(t, store.Create(user))

	// Test
	result, err := store.GetByUsername("testuser")
	require.NoError(t, err)
	require.NotNil(t, result)
	assert.Equal(t, "testuser", result.Username)
}

func TestUserStore_GetByUsername_NotFound(t *testing.T) {
	db := setupUserStoreDB(t)
	defer db.Close()

	store := NewUserStore(db)

	result, err := store.GetByUsername("nonexistent")
	require.NoError(t, err)
	assert.Nil(t, result)
}

func TestUserStore_SaveResult(t *testing.T) {
	db := setupUserStoreDB(t)
	defer db.Close()

	store := NewUserStore(db)

	// Create user first
	user := &models.User{ID: "user1", Username: "testuser", Password: "pwd", Role: "user"}
	require.NoError(t, store.Create(user))

	// Save result
	err := store.SaveResult("user1", "quiz1", 8, 10)
	require.NoError(t, err)
}

func TestUserStore_GetLeaderboard(t *testing.T) {
	db := setupUserStoreDB(t)
	defer db.Close()

	store := NewUserStore(db)

	// Create users
	user1 := &models.User{ID: "user1", Username: "user1", Password: "pwd", Role: "user"}
	user2 := &models.User{ID: "user2", Username: "user2", Password: "pwd", Role: "user"}
	require.NoError(t, store.Create(user1))
	require.NoError(t, store.Create(user2))

	// Create quiz
	_, err := db.Exec("INSERT INTO quizzes (id, title, description, category) VALUES (?, ?, ?, ?)",
		"quiz1", "Test Quiz", "Description", "Category")
	require.NoError(t, err)

	// Save results
	require.NoError(t, store.SaveResult("user1", "quiz1", 10, 10))
	require.NoError(t, store.SaveResult("user2", "quiz1", 8, 10))

	// Test
	leaderboard, err := store.GetLeaderboard(10)
	require.NoError(t, err)
	assert.Len(t, leaderboard, 2)
	// Should be sorted by score descending
	assert.Equal(t, 10, leaderboard[0]["score"])
	assert.Equal(t, "user1", leaderboard[0]["username"])
}
