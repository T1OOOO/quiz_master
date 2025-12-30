package service

import (
	"errors"
	"fmt"
	"math/rand"
	"time"

	"quiz_master/internal/models"
	"quiz_master/internal/store"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
	"golang.org/x/crypto/bcrypt"
)

var SecretKey = []byte("your-secret-key-change-this-in-prod")

type AuthService struct {
	repo *store.UserStore
}

func NewAuthService(repo *store.UserStore) *AuthService {
	return &AuthService{repo: repo}
}

func (s *AuthService) Register(req *models.AuthRequest) (*models.AuthResponse, error) {
	hashed, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		return nil, err
	}
	
	id := uuid.New().String()
	user := &models.User{
		ID:       id,
		Username: req.Username,
		Password: string(hashed),
		Role:     "user",
	}
	
	// Create user
	if err := s.repo.Create(user); err != nil {
		return nil, err // likely username conflict
	}
	
	return s.generateToken(user.ID, user.Username, user.Role)
}

func (s *AuthService) Login(req *models.AuthRequest) (*models.AuthResponse, error) {
	user, err := s.repo.GetByUsername(req.Username)
	if err != nil {
		return nil, err
	}
	if user == nil {
		return nil, errors.New("invalid credentials")
	}
	
	if err := bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(req.Password)); err != nil {
		return nil, errors.New("invalid credentials")
	}
	
	return s.generateToken(user.ID, user.Username, user.Role)
}

func (s *AuthService) GuestLogin(username string) (*models.AuthResponse, error) {
	id := uuid.New().String()
	
	if username == "" {
		randNum := rand.Intn(9000) + 1000
		username = fmt.Sprintf("Guest-%d", randNum)
	}

	user := &models.User{
		ID:       id,
		Username: username,
		Password: "guest_no_password",
		Role:     "guest",
	}

	if err := s.repo.Create(user); err != nil {
		return nil, err
	}

	return s.generateToken(user.ID, user.Username, user.Role)
}

func (s *AuthService) generateToken(id, username, role string) (*models.AuthResponse, error) {
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
		"user_id":  id,
		"username": username,
		"role":     role,
		"exp":      time.Now().Add(24 * time.Hour).Unix(),
	})

	t, err := token.SignedString(SecretKey)
	if err != nil {
		return nil, err
	}

	return &models.AuthResponse{
		Token:    t,
		Username: username,
		Role:     role,
	}, nil
}

func (s *AuthService) GetLeaderboard() ([]map[string]interface{}, error) {
	return s.repo.GetLeaderboard(10)
}

func (s *AuthService) SubmitResult(userID, quizID string, score, total int) error {
	return s.repo.SaveResult(userID, quizID, score, total)
}
