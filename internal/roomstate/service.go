package roomstate

import (
	"context"
	"fmt"
	"math/rand"
	"strings"
	"sync"
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
	repo   Repository
	broker *Broker
}

func New(repo Repository) *Service {
	return &Service{
		repo:   repo,
		broker: NewBroker(),
	}
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
	s.publish(Event{Type: EventTypeUpsert, RoomCode: room.Code, Room: room})
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
	s.publish(Event{Type: EventTypeUpsert, RoomCode: room.Code, Room: room})
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
		s.publish(Event{Type: EventTypeDelete, RoomCode: room.Code})
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
	s.publish(Event{Type: EventTypeUpsert, RoomCode: room.Code, Room: room})
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
	s.publish(Event{Type: EventTypeUpsert, RoomCode: room.Code, Room: room, BroadcastType: "game_started", QuizID: room.QuizID})
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
	s.publish(Event{Type: EventTypeUpsert, RoomCode: room.Code, Room: room})
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
	s.publish(Event{Type: EventTypeUpsert, RoomCode: room.Code, Room: room, BroadcastType: "chat_message", ChatMessage: &msg})
	return room, msg, nil
}

func (s *Service) Subscribe(ctx context.Context) <-chan Event {
	if s == nil || s.broker == nil {
		ch := make(chan Event)
		close(ch)
		return ch
	}
	return s.broker.Subscribe(ctx)
}

func (s *Service) publish(evt Event) {
	if s == nil || s.broker == nil {
		return
	}
	s.broker.Publish(evt)
}

type EventType string

const (
	EventTypeUpsert EventType = "upsert"
	EventTypeDelete EventType = "delete"
)

type Event struct {
	Type          EventType           `json:"type"`
	RoomCode      string              `json:"room_code,omitempty"`
	Room          *models.Room        `json:"room,omitempty"`
	BroadcastType string              `json:"broadcast_type,omitempty"`
	QuizID        string              `json:"quiz_id,omitempty"`
	ChatMessage   *models.ChatMessage `json:"chat_message,omitempty"`
}

type Broker struct {
	mu          sync.RWMutex
	subscribers map[chan Event]struct{}
}

func NewBroker() *Broker {
	return &Broker{subscribers: make(map[chan Event]struct{})}
}

func (b *Broker) Subscribe(ctx context.Context) <-chan Event {
	ch := make(chan Event, 16)
	b.mu.Lock()
	b.subscribers[ch] = struct{}{}
	b.mu.Unlock()

	go func() {
		<-ctx.Done()
		b.mu.Lock()
		delete(b.subscribers, ch)
		b.mu.Unlock()
		close(ch)
	}()

	return ch
}

func (b *Broker) Publish(evt Event) {
	b.mu.RLock()
	subscribers := make([]chan Event, 0, len(b.subscribers))
	for ch := range b.subscribers {
		subscribers = append(subscribers, ch)
	}
	b.mu.RUnlock()

	for _, ch := range subscribers {
		select {
		case ch <- evt:
		default:
		}
	}
}

func generateCode() string {
	const letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	b := make([]byte, 4)
	for i := range b {
		b[i] = letters[rand.Intn(len(letters))]
	}
	return string(b)
}
