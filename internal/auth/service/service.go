package service

import (
	"errors"
	"fmt"
	"math/rand"

	authdomain "quiz_master/internal/auth/domain"
	authrepo "quiz_master/internal/auth/repository"
	"quiz_master/internal/auth/token"

	"github.com/google/uuid"
	"golang.org/x/crypto/bcrypt"
)

type Service struct {
	repo   authrepo.UserRepository
	tokens *token.Manager
}

func New(repo authrepo.UserRepository, tokens *token.Manager) *Service {
	if tokens == nil {
		tokens = token.NewLegacyManager()
	}
	return &Service{repo: repo, tokens: tokens}
}

func (s *Service) Register(req *authdomain.AuthRequest) (*authdomain.AuthResponse, error) {
	hashed, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		return nil, err
	}

	user := &authdomain.User{
		ID:       uuid.New().String(),
		Username: req.Username,
		Password: string(hashed),
		Role:     "user",
	}

	if err := s.repo.Create(user); err != nil {
		return nil, err
	}

	return s.generateToken(user)
}

func (s *Service) Login(req *authdomain.AuthRequest) (*authdomain.AuthResponse, error) {
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

	return s.generateToken(user)
}

func (s *Service) GuestLogin(username string) (*authdomain.AuthResponse, error) {
	if username == "" {
		username = fmt.Sprintf("Guest-%d", rand.Intn(9000)+1000)
	}

	user := &authdomain.User{
		ID:       uuid.New().String(),
		Username: username,
		Password: "guest_no_password",
		Role:     "guest",
	}

	if err := s.repo.Create(user); err != nil {
		return nil, err
	}

	return s.generateToken(user)
}

func (s *Service) GetLeaderboard() ([]map[string]interface{}, error) {
	return s.repo.GetLeaderboard(10)
}

func (s *Service) SubmitResult(userID, quizID string, score, total int) error {
	return s.repo.SaveResult(userID, quizID, score, total)
}

func (s *Service) Tokens() *token.Manager {
	return s.tokens
}

func (s *Service) generateToken(user *authdomain.User) (*authdomain.AuthResponse, error) {
	signed, err := s.tokens.Generate(authdomain.Claims{
		UserID:   user.ID,
		Username: user.Username,
		Role:     user.Role,
	})
	if err != nil {
		return nil, err
	}

	return &authdomain.AuthResponse{
		Token:    signed,
		Username: user.Username,
		Role:     user.Role,
	}, nil
}
