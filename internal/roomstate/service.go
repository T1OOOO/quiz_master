package roomstate

import (
	"fmt"
	"math/rand"
	"strings"
	"time"

	"quiz_master/internal/models"
)

const (
	StateWaiting  = "waiting"
	StatePlaying  = "playing"
	StateFinished = "finished"
)

type Repository interface {
	Create(room *models.Room) error
	Get(code string) (*models.Room, error)
	Update(room *models.Room) error
	Delete(code string) error
}

type Service struct {
	repo Repository
}

func New(repo Repository) *Service {
	return &Service{repo: repo}
}

func (s *Service) CreateRoom(username, avatar string) (*models.Room, error) {
	username = strings.TrimSpace(username)
	if username == "" {
		return nil, fmt.Errorf("username is required")
	}

	room := &models.Room{
		Code:            generateCode(),
		HostID:          username,
		Players:         map[string]*models.Player{},
		State:           StateWaiting,
		Votes:           map[int]map[string]int{},
		Revealed:        map[int]bool{},
		ChatHistory:     []models.ChatMessage{},
		CurrentQuestion: 0,
	}
	room.Players[username] = &models.Player{
		Username:    username,
		AvatarColor: avatar,
		Score:       0,
	}

	if err := s.repo.Create(room); err != nil {
		return nil, err
	}
	return room, nil
}

func (s *Service) GetRoom(code string) (*models.Room, error) {
	return s.repo.Get(strings.TrimSpace(code))
}

func (s *Service) JoinRoom(code, username, avatar string) (*models.Room, error) {
	username = strings.TrimSpace(username)
	if username == "" {
		return nil, fmt.Errorf("username is required")
	}
	room, err := s.repo.Get(strings.TrimSpace(code))
	if err != nil {
		return nil, err
	}
	if room == nil {
		return nil, fmt.Errorf("room not found")
	}
	if room.Players == nil {
		room.Players = map[string]*models.Player{}
	}
	room.Players[username] = &models.Player{
		Username:    username,
		AvatarColor: avatar,
		Score:       0,
	}
	if err := s.repo.Update(room); err != nil {
		return nil, err
	}
	return room, nil
}

func (s *Service) LeaveRoom(code, username string) (*models.Room, error) {
	room, err := s.repo.Get(strings.TrimSpace(code))
	if err != nil {
		return nil, err
	}
	if room == nil {
		return nil, nil
	}
	delete(room.Players, strings.TrimSpace(username))
	if len(room.Players) == 0 {
		if err := s.repo.Delete(room.Code); err != nil {
			return nil, err
		}
		return nil, nil
	}
	if room.HostID == username {
		for next := range room.Players {
			room.HostID = next
			break
		}
	}
	if err := s.repo.Update(room); err != nil {
		return nil, err
	}
	return room, nil
}

func (s *Service) StartGame(code, username, quizID string) (*models.Room, error) {
	room, err := s.repo.Get(strings.TrimSpace(code))
	if err != nil {
		return nil, err
	}
	if room == nil {
		return nil, fmt.Errorf("room not found")
	}
	if room.HostID != strings.TrimSpace(username) {
		return nil, fmt.Errorf("only host can start the game")
	}
	room.QuizID = strings.TrimSpace(quizID)
	room.State = StatePlaying
	room.CurrentQuestion = 0
	room.Votes = map[int]map[string]int{}
	if err := s.repo.Update(room); err != nil {
		return nil, err
	}
	return room, nil
}

func (s *Service) SubmitVote(code, username string, answerIndex int) (*models.Room, error) {
	room, err := s.repo.Get(strings.TrimSpace(code))
	if err != nil {
		return nil, err
	}
	if room == nil {
		return nil, fmt.Errorf("room not found")
	}
	if room.Votes == nil {
		room.Votes = map[int]map[string]int{}
	}
	if room.Votes[room.CurrentQuestion] == nil {
		room.Votes[room.CurrentQuestion] = map[string]int{}
	}
	room.Votes[room.CurrentQuestion][strings.TrimSpace(username)] = answerIndex
	if err := s.repo.Update(room); err != nil {
		return nil, err
	}
	return room, nil
}

func (s *Service) SubmitChat(code, username, text, image string) (*models.Room, models.ChatMessage, error) {
	room, err := s.repo.Get(strings.TrimSpace(code))
	if err != nil {
		return nil, models.ChatMessage{}, err
	}
	if room == nil {
		return nil, models.ChatMessage{}, fmt.Errorf("room not found")
	}
	msg := models.ChatMessage{
		User:      strings.TrimSpace(username),
		Text:      strings.TrimSpace(text),
		Image:     strings.TrimSpace(image),
		Timestamp: time.Now().UTC(),
	}
	room.ChatHistory = append(room.ChatHistory, msg)
	if len(room.ChatHistory) > 50 {
		room.ChatHistory = room.ChatHistory[1:]
	}
	if err := s.repo.Update(room); err != nil {
		return nil, models.ChatMessage{}, err
	}
	return room, msg, nil
}

func generateCode() string {
	const letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	b := make([]byte, 4)
	for i := range b {
		b[i] = letters[rand.Intn(len(letters))]
	}
	return string(b)
}
