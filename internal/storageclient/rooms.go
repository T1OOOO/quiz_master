package storageclient

import (
	"net/http"
	"net/url"

	"quiz_master/internal/models"
	storagedto "quiz_master/internal/storageapi/dto"
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
