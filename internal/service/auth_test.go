package service

import (
	"database/sql"
	"testing"

	"quiz_master/internal/models"
	"quiz_master/internal/store"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	_ "modernc.org/sqlite"
)

func setupAuthTestDB(t *testing.T) *sql.DB {
	db, err := sql.Open("sqlite", ":memory:")
	require.NoError(t, err)

	// Create schema
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
		CREATE TABLE refresh_tokens (
			token TEXT PRIMARY KEY,
			user_id TEXT,
			expires_at DATETIME,
			created_at DATETIME
		)
	`)
	require.NoError(t, err)

	return db
}

func TestAuthService_Register(t *testing.T) {
	db := setupAuthTestDB(t)
	defer db.Close()

	repo := store.NewUserStore(db)
	service := NewAuthService(repo)

	req := &models.AuthRequest{
		Username: "testuser",
		Password: "password123",
	}

	res, err := service.Register(req)
	require.NoError(t, err)
	require.NotNil(t, res)
	assert.NotEmpty(t, res.Token)
	assert.Equal(t, "testuser", res.Username)
	assert.Equal(t, "user", res.Role)
}

func TestAuthService_Register_DuplicateUsername(t *testing.T) {
	db := setupAuthTestDB(t)
	defer db.Close()

	repo := store.NewUserStore(db)
	service := NewAuthService(repo)

	req := &models.AuthRequest{
		Username: "testuser",
		Password: "password123",
	}

	// First registration
	_, err := service.Register(req)
	require.NoError(t, err)

	// Second registration with same username should fail
	_, err = service.Register(req)
	assert.Error(t, err)
}

func TestAuthService_Login(t *testing.T) {
	db := setupAuthTestDB(t)
	defer db.Close()

	repo := store.NewUserStore(db)
	service := NewAuthService(repo)

	// Register first
	req := &models.AuthRequest{
		Username: "testuser",
		Password: "password123",
	}
	_, err := service.Register(req)
	require.NoError(t, err)

	// Login
	res, err := service.Login(req)
	require.NoError(t, err)
	require.NotNil(t, res)
	assert.NotEmpty(t, res.Token)
	assert.Equal(t, "testuser", res.Username)
}

func TestAuthService_Login_InvalidCredentials(t *testing.T) {
	db := setupAuthTestDB(t)
	defer db.Close()

	repo := store.NewUserStore(db)
	service := NewAuthService(repo)

	// Register first
	req := &models.AuthRequest{
		Username: "testuser",
		Password: "password123",
	}
	_, err := service.Register(req)
	require.NoError(t, err)

	// Login with wrong password
	wrongReq := &models.AuthRequest{
		Username: "testuser",
		Password: "wrongpassword",
	}
	_, err = service.Login(wrongReq)
	assert.Error(t, err)
	assert.Contains(t, err.Error(), "invalid credentials")
}

func TestAuthService_Login_UserNotFound(t *testing.T) {
	db := setupAuthTestDB(t)
	defer db.Close()

	repo := store.NewUserStore(db)
	service := NewAuthService(repo)

	req := &models.AuthRequest{
		Username: "nonexistent",
		Password: "password123",
	}

	_, err := service.Login(req)
	assert.Error(t, err)
	assert.Contains(t, err.Error(), "invalid credentials")
}

func TestAuthService_GuestLogin(t *testing.T) {
	db := setupAuthTestDB(t)
	defer db.Close()

	repo := store.NewUserStore(db)
	service := NewAuthService(repo)

	res, err := service.GuestLogin("guestuser")
	require.NoError(t, err)
	require.NotNil(t, res)
	assert.NotEmpty(t, res.Token)
	assert.Equal(t, "guestuser", res.Username)
	assert.Equal(t, "guest", res.Role)
}

func TestAuthService_GuestLogin_EmptyUsername(t *testing.T) {
	db := setupAuthTestDB(t)
	defer db.Close()

	repo := store.NewUserStore(db)
	service := NewAuthService(repo)

	res, err := service.GuestLogin("")
	require.NoError(t, err)
	require.NotNil(t, res)
	assert.NotEmpty(t, res.Token)
	assert.Contains(t, res.Username, "Guest-")
	assert.Equal(t, "guest", res.Role)
}

func TestAuthService_SubmitResult(t *testing.T) {
	db := setupAuthTestDB(t)
	defer db.Close()

	repo := store.NewUserStore(db)
	service := NewAuthService(repo)

	// Create user
	user := &models.User{
		ID:       "user1",
		Username: "testuser",
		Password: "hashed",
		Role:     "user",
	}
	require.NoError(t, repo.Create(user))

	// Submit result
	err := service.SubmitResult("user1", "quiz1", 8, 10)
	require.NoError(t, err)
}

func TestAuthService_GetLeaderboard(t *testing.T) {
	db := setupAuthTestDB(t)
	defer db.Close()

	repo := store.NewUserStore(db)
	service := NewAuthService(repo)

	// Create users and results
	user1 := &models.User{ID: "user1", Username: "user1", Password: "pwd", Role: "user"}
	user2 := &models.User{ID: "user2", Username: "user2", Password: "pwd", Role: "user"}
	require.NoError(t, repo.Create(user1))
	require.NoError(t, repo.Create(user2))

	require.NoError(t, service.SubmitResult("user1", "quiz1", 10, 10))
	require.NoError(t, service.SubmitResult("user2", "quiz1", 8, 10))

	// Get leaderboard
	leaderboard, err := service.GetLeaderboard(10)
	require.NoError(t, err)
	assert.Len(t, leaderboard, 2)
	// Should be sorted by score descending
	assert.Equal(t, 10, leaderboard[0]["score"])
}

func TestAuthService_GetUserQuota_DefaultUnlimited(t *testing.T) {
	db := setupAuthTestDB(t)
	defer db.Close()

	repo := store.NewUserStore(db)
	service := NewAuthService(repo)

	quota, err := service.GetUserQuota("user1")
	require.NoError(t, err)
	require.NotNil(t, quota)
	assert.Equal(t, 0, quota.QuizzesLimit)
	assert.Equal(t, 0, quota.QuestionsLimit)
	assert.Equal(t, 0, quota.AttemptsLimit)
}

func TestAuthService_RefreshRotatesRefreshToken(t *testing.T) {
	db := setupAuthTestDB(t)
	defer db.Close()

	repo := store.NewUserStore(db)
	service := NewAuthService(repo)

	initial, err := service.Register(&models.AuthRequest{
		Username: "refresh-user",
		Password: "password123",
	})
	require.NoError(t, err)
	require.NotEmpty(t, initial.RefreshToken)

	refreshed, err := service.Refresh(initial.RefreshToken)
	require.NoError(t, err)
	require.NotEmpty(t, refreshed.Token)
	require.NotEmpty(t, refreshed.RefreshToken)
	assert.NotEqual(t, initial.RefreshToken, refreshed.RefreshToken)

	_, err = service.Refresh(initial.RefreshToken)
	assert.Error(t, err)
}
