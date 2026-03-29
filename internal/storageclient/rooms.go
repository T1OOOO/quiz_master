package storageclient

import (
	"bufio"
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"net/url"
	"strings"
	"time"

	"quiz_master/internal/models"
	"quiz_master/internal/observability"
	storagedto "quiz_master/internal/storageapi/dto"
	"quiz_master/internal/tracing"
)

func (c *Client) CreateRoom(username, avatar string) (*models.Room, error) {
	var payload storagedto.Room
	err := c.doJSON(http.MethodPost, "/internal/storage/rooms", storagedto.RoomCreateRequest{
		Username: username,
		Avatar:   avatar,
	}, &payload)
	if err != nil {
		return nil, err
	}
	return toDomainRoom(&payload), nil
}

func (c *Client) GetRoom(code string) (*models.Room, error) {
	var payload storagedto.Room
	err := c.doJSON(http.MethodGet, "/internal/storage/rooms/"+url.PathEscape(code), nil, &payload)
	if err == errNotFound {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	return toDomainRoom(&payload), nil
}

func (c *Client) JoinRoom(code, username, avatar string) (*models.Room, error) {
	var payload storagedto.Room
	err := c.doJSON(http.MethodPost, "/internal/storage/rooms/"+url.PathEscape(code)+"/join", storagedto.RoomJoinRequest{
		Username: username,
		Avatar:   avatar,
	}, &payload)
	if err != nil {
		return nil, err
	}
	return toDomainRoom(&payload), nil
}

func (c *Client) LeaveRoom(code, username string) (*models.Room, error) {
	var payload storagedto.Room
	err := c.doJSON(http.MethodPost, "/internal/storage/rooms/"+url.PathEscape(code)+"/leave", storagedto.RoomLeaveRequest{
		Username: username,
	}, &payload)
	if err == errNotFound {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	return toDomainRoom(&payload), nil
}

func (c *Client) StartRoom(code, username, quizID string) (*models.Room, error) {
	var payload storagedto.Room
	err := c.doJSON(http.MethodPost, "/internal/storage/rooms/"+url.PathEscape(code)+"/start", storagedto.RoomStartRequest{
		Username: username,
		QuizID:   quizID,
	}, &payload)
	if err != nil {
		return nil, err
	}
	return toDomainRoom(&payload), nil
}

func (c *Client) VoteRoom(code, username string, answerIndex int) (*models.Room, error) {
	var payload storagedto.Room
	err := c.doJSON(http.MethodPost, "/internal/storage/rooms/"+url.PathEscape(code)+"/vote", storagedto.RoomVoteRequest{
		Username:    username,
		AnswerIndex: answerIndex,
	}, &payload)
	if err != nil {
		return nil, err
	}
	return toDomainRoom(&payload), nil
}

func (c *Client) ChatRoom(code, username, text, image string) (*models.Room, error) {
	var payload storagedto.Room
	err := c.doJSON(http.MethodPost, "/internal/storage/rooms/"+url.PathEscape(code)+"/chat", storagedto.RoomChatRequest{
		Username: username,
		Text:     text,
		Image:    image,
	}, &payload)
	if err != nil {
		return nil, err
	}
	return toDomainRoom(&payload), nil
}

func toDomainRoom(room *storagedto.Room) *models.Room {
	if room == nil {
		return nil
	}
	players := make(map[string]*models.Player, len(room.Players))
	for key, player := range room.Players {
		p := player
		players[key] = &models.Player{
			Username:    p.Username,
			AvatarColor: p.AvatarColor,
			Score:       p.Score,
		}
	}
	chat := make([]models.ChatMessage, 0, len(room.ChatHistory))
	for _, item := range room.ChatHistory {
		chat = append(chat, models.ChatMessage{
			User:      item.User,
			Text:      item.Text,
			Image:     item.Image,
			Timestamp: item.Timestamp,
		})
	}
	return &models.Room{
		Code:            room.Code,
		HostID:          room.HostID,
		Version:         room.Version,
		Players:         players,
		State:           room.State,
		QuizID:          room.QuizID,
		CurrentQuestion: room.CurrentQuestion,
		Votes:           room.Votes,
		Revealed:        room.Revealed,
		ChatHistory:     chat,
	}
}

type RoomEvent struct {
	Type          string
	RoomCode      string
	Room          *models.Room
	BroadcastType string
	QuizID        string
	ChatMessage   *models.ChatMessage
}

func (c *Client) StreamRoomEvents(ctx context.Context, onEvent func(RoomEvent) error) error {
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, c.baseURL+"/internal/storage/rooms/stream", nil)
	if err != nil {
		return err
	}
	req.Header.Set("Accept", "application/x-ndjson")
	if c.token != "" {
		req.Header.Set("X-Internal-Token", c.token)
	}

	streamHTTP := &http.Client{
		Timeout:   0,
		Transport: tracing.NewTransport(http.DefaultTransport),
	}
	start := time.Now()
	resp, err := streamHTTP.Do(req)
	statusCode := 0
	if resp != nil {
		statusCode = resp.StatusCode
	}
	observability.RecordUpstreamRequest(c.service, "storage", http.MethodGet, "/internal/storage/rooms/stream", statusCode, time.Since(start), err)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode >= 300 {
		return fmt.Errorf("storage stream failed: %s", resp.Status)
	}

	scanner := bufio.NewScanner(resp.Body)
	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		if line == "" {
			continue
		}
		var payload storagedto.RoomEvent
		if err := json.Unmarshal([]byte(line), &payload); err != nil {
			return err
		}
		if err := onEvent(RoomEvent{
			Type:          payload.Type,
			RoomCode:      payload.RoomCode,
			Room:          toDomainRoom(payload.Room),
			BroadcastType: payload.BroadcastType,
			QuizID:        payload.QuizID,
			ChatMessage:   toDomainChatMessage(payload.ChatMessage),
		}); err != nil {
			return err
		}
	}
	if err := scanner.Err(); err != nil {
		return err
	}
	return nil
}

func toDomainChatMessage(msg *storagedto.RoomChatMessage) *models.ChatMessage {
	if msg == nil {
		return nil
	}
	return &models.ChatMessage{
		User:      msg.User,
		Text:      msg.Text,
		Image:     msg.Image,
		Timestamp: msg.Timestamp,
	}
}
