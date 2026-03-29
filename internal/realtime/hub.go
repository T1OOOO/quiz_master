package realtime

import (
	"context"
	"encoding/json"
	"errors"
	"log"
	"net/http"
	"strings"
	"sync"
	"time"

	"github.com/gorilla/websocket"
	"github.com/labstack/echo/v4"
	authtoken "quiz_master/internal/auth/token"
	"quiz_master/internal/models"
)

type Event struct {
	Type    string `json:"type"`
	Message string `json:"message"`
	User    string `json:"user,omitempty"`
}

type RoomStore interface {
	CreateRoom(username, avatar string) (*models.Room, error)
	GetRoom(code string) (*models.Room, error)
	JoinRoom(code, username, avatar string) (*models.Room, error)
	LeaveRoom(code, username string) (*models.Room, error)
	StartRoom(code, username, quizID string) (*models.Room, error)
	VoteRoom(code, username string, answerIndex int) (*models.Room, error)
	ChatRoom(code, username, text, image string) (*models.Room, error)
}

type RoomEventStreamer interface {
	StreamRoomEvents(ctx context.Context, onEvent func(RoomEvent) error) error
}

type RoomEvent struct {
	Type          string
	RoomCode      string
	Room          *models.Room
	BroadcastType string
	QuizID        string
	ChatMessage   *models.ChatMessage
}

type clientState struct {
	username string
	roomCode string
}

type Hub struct {
	store      RoomStore
	broadcast  chan Event
	register   chan *websocket.Conn
	unregister chan *websocket.Conn

	mutex       sync.RWMutex
	clients     map[*websocket.Conn]clientState
	subscribers map[string]map[*websocket.Conn]struct{}
}

func NewHub(store RoomStore) *Hub {
	return &Hub{
		store:       store,
		broadcast:   make(chan Event, 32),
		register:    make(chan *websocket.Conn, 32),
		unregister:  make(chan *websocket.Conn, 32),
		clients:     make(map[*websocket.Conn]clientState),
		subscribers: make(map[string]map[*websocket.Conn]struct{}),
	}
}

func (h *Hub) Run() {
	if streamer, ok := h.store.(RoomEventStreamer); ok {
		go h.consumeRoomEvents(streamer)
	}

	for {
		select {
		case client := <-h.register:
			h.mutex.Lock()
			h.clients[client] = clientState{}
			h.mutex.Unlock()
			log.Println("New websocket client connected")

		case client := <-h.unregister:
			h.removeClient(client)
			log.Println("Websocket client disconnected")

		case message := <-h.broadcast:
			h.broadcastGlobal(message)
		}
	}
}

func (h *Hub) BroadcastEvent(evt Event) {
	h.broadcast <- evt
}

func (h *Hub) HandleMessage(conn *websocket.Conn, message []byte) {
	var base struct {
		Type    string          `json:"type"`
		Payload json.RawMessage `json:"payload"`
	}
	if err := json.Unmarshal(message, &base); err != nil {
		sendError(conn, "invalid message")
		return
	}

	switch base.Type {
	case "create_room":
		h.handleCreateRoom(conn, base.Payload)
	case "join_room":
		h.handleJoinRoom(conn, base.Payload)
	default:
		state, ok := h.getClientState(conn)
		if !ok || state.roomCode == "" || state.username == "" {
			sendError(conn, "join a room first")
			return
		}
		h.handleRoomMessage(conn, state, base.Type, base.Payload)
	}
}

func (h *Hub) handleCreateRoom(conn *websocket.Conn, payload []byte) {
	var req struct {
		Username string `json:"username"`
		Code     string `json:"code"`
		Avatar   string `json:"avatar"`
	}
	if err := json.Unmarshal(payload, &req); err != nil {
		sendError(conn, "invalid create room request")
		return
	}

	room, err := h.store.CreateRoom(req.Username, req.Avatar)
	if err != nil {
		sendError(conn, err.Error())
		return
	}

	h.bindClientToRoom(conn, room.Code, req.Username)
}

func (h *Hub) handleJoinRoom(conn *websocket.Conn, payload []byte) {
	var req struct {
		Username string `json:"username"`
		Code     string `json:"code"`
		Avatar   string `json:"avatar"`
	}
	if err := json.Unmarshal(payload, &req); err != nil {
		sendError(conn, "invalid join room request")
		return
	}

	room, err := h.store.JoinRoom(req.Code, req.Username, req.Avatar)
	if err != nil {
		sendError(conn, err.Error())
		return
	}

	h.bindClientToRoom(conn, room.Code, req.Username)
}

func (h *Hub) handleRoomMessage(conn *websocket.Conn, state clientState, msgType string, payload []byte) {
	var (
		room *models.Room
		err  error
	)

	switch msgType {
	case "start_game":
		var req struct {
			QuizID string `json:"quiz_id"`
		}
		if err := json.Unmarshal(payload, &req); err != nil {
			sendError(conn, "invalid start game request")
			return
		}
		room, err = h.store.StartRoom(state.roomCode, state.username, req.QuizID)
	case "vote":
		var req struct {
			AnswerIndex int `json:"answer_index"`
		}
		if err := json.Unmarshal(payload, &req); err != nil {
			sendError(conn, "invalid vote request")
			return
		}
		room, err = h.store.VoteRoom(state.roomCode, state.username, req.AnswerIndex)
	case "chat":
		var req struct {
			Text  string `json:"text"`
			Image string `json:"image"`
		}
		if err := json.Unmarshal(payload, &req); err != nil {
			sendError(conn, "invalid chat request")
			return
		}
		room, err = h.store.ChatRoom(state.roomCode, state.username, req.Text, req.Image)
	default:
		sendError(conn, "unsupported message type")
		return
	}

	if err != nil {
		sendError(conn, err.Error())
		return
	}
	_ = room
}

func (h *Hub) bindClientToRoom(conn *websocket.Conn, code, username string) {
	h.mutex.Lock()
	defer h.mutex.Unlock()

	state := h.clients[conn]
	if state.roomCode != "" && state.roomCode != code {
		delete(h.subscribers[state.roomCode], conn)
	}
	state.roomCode = code
	state.username = username
	h.clients[conn] = state
	if h.subscribers[code] == nil {
		h.subscribers[code] = make(map[*websocket.Conn]struct{})
	}
	h.subscribers[code][conn] = struct{}{}
}

func (h *Hub) getClientState(conn *websocket.Conn) (clientState, bool) {
	h.mutex.RLock()
	defer h.mutex.RUnlock()
	state, ok := h.clients[conn]
	return state, ok
}

func (h *Hub) removeClient(conn *websocket.Conn) {
	h.mutex.Lock()
	state, ok := h.clients[conn]
	if ok {
		delete(h.clients, conn)
		if state.roomCode != "" {
			if subs := h.subscribers[state.roomCode]; subs != nil {
				delete(subs, conn)
				if len(subs) == 0 {
					delete(h.subscribers, state.roomCode)
				}
			}
		}
	}
	h.mutex.Unlock()

	if ok && state.roomCode != "" && state.username != "" {
		_, _ = h.store.LeaveRoom(state.roomCode, state.username)
	}
	_ = conn.Close()
}

func (h *Hub) publishRoomState(room *models.Room) {
	if room == nil {
		return
	}

	players := make([]map[string]any, 0, len(room.Players))
	for _, player := range room.Players {
		if player == nil {
			continue
		}
		players = append(players, map[string]any{
			"username": player.Username,
			"avatar":   player.AvatarColor,
			"score":    player.Score,
		})
	}

	h.broadcastRoomMessage(room.Code, map[string]any{
		"type": "room_state",
		"room": map[string]any{
			"code":             room.Code,
			"host":             room.HostID,
			"version":          room.Version,
			"state":            room.State,
			"players":          players,
			"votes":            room.Votes,
			"quiz_id":          room.QuizID,
			"current_question": room.CurrentQuestion,
			"chat_history":     room.ChatHistory,
		},
	})
}

func (h *Hub) broadcastRoomMessage(code string, message any) {
	h.mutex.RLock()
	clients := make([]*websocket.Conn, 0, len(h.subscribers[code]))
	for conn := range h.subscribers[code] {
		clients = append(clients, conn)
	}
	h.mutex.RUnlock()

	for _, conn := range clients {
		if err := conn.WriteJSON(message); err != nil {
			h.unregister <- conn
		}
	}
}

func (h *Hub) broadcastGlobal(message Event) {
	h.mutex.RLock()
	clients := make([]*websocket.Conn, 0, len(h.clients))
	for conn := range h.clients {
		clients = append(clients, conn)
	}
	h.mutex.RUnlock()

	for _, conn := range clients {
		if err := conn.WriteJSON(message); err != nil {
			h.unregister <- conn
		}
	}
}

func (h *Hub) consumeRoomEvents(streamer RoomEventStreamer) {
	for {
		err := streamer.StreamRoomEvents(context.Background(), func(evt RoomEvent) error {
			h.handleRoomEvent(evt)
			return nil
		})
		if err != nil {
			log.Printf("room event stream disconnected: %v", err)
			time.Sleep(500 * time.Millisecond)
			continue
		}
		return
	}
}

func (h *Hub) handleRoomEvent(evt RoomEvent) {
	switch evt.Type {
	case "delete":
		h.broadcastRoomMessage(evt.RoomCode, map[string]any{
			"type":    "room_closed",
			"code":    evt.RoomCode,
			"message": "room closed",
		})
		h.mutex.Lock()
		delete(h.subscribers, evt.RoomCode)
		h.mutex.Unlock()
	case "upsert":
		switch evt.BroadcastType {
		case "game_started":
			h.broadcastRoomMessage(evt.RoomCode, map[string]any{
				"type":    "game_started",
				"quiz_id": evt.QuizID,
			})
		case "chat_message":
			if evt.ChatMessage != nil {
				h.broadcastRoomMessage(evt.RoomCode, map[string]any{
					"type":    "chat_message",
					"message": evt.ChatMessage,
				})
			}
		}
		h.publishRoomState(evt.Room)
	}
}

func NewWebSocketHandler(tokens *authtoken.Manager, allowedOrigins []string, hub *Hub) echo.HandlerFunc {
	allowed := make(map[string]struct{}, len(allowedOrigins))
	for _, origin := range allowedOrigins {
		origin = strings.TrimSpace(origin)
		if origin != "" {
			allowed[origin] = struct{}{}
		}
	}

	upgrader := websocket.Upgrader{
		CheckOrigin: func(r *http.Request) bool {
			origin := strings.TrimSpace(r.Header.Get("Origin"))
			if origin == "" {
				return false
			}
			_, ok := allowed[origin]
			return ok
		},
	}

	return func(c echo.Context) error {
		if err := authorizeWebSocketRequest(c.Request(), tokens); err != nil {
			return c.JSON(http.StatusUnauthorized, map[string]string{"error": "unauthorized websocket"})
		}

		ws, err := upgrader.Upgrade(c.Response(), c.Request(), nil)
		if err != nil {
			return err
		}

		hub.register <- ws

		go func() {
			defer func() {
				hub.unregister <- ws
			}()

			for {
				_, msg, err := ws.ReadMessage()
				if err != nil {
					break
				}
				hub.HandleMessage(ws, msg)
			}
		}()

		return nil
	}
}

func authorizeWebSocketRequest(r *http.Request, tokens *authtoken.Manager) error {
	if tokens == nil {
		return errors.New("token manager is not configured")
	}

	tokenString := strings.TrimSpace(extractBearerToken(r.Header.Get("Authorization")))
	if tokenString == "" {
		tokenString = strings.TrimSpace(r.URL.Query().Get("access_token"))
	}
	if tokenString == "" {
		tokenString = strings.TrimSpace(r.URL.Query().Get("token"))
	}
	if tokenString == "" {
		return errors.New("missing websocket token")
	}
	_, err := tokens.Parse(tokenString)
	return err
}

func extractBearerToken(header string) string {
	parts := strings.SplitN(header, " ", 2)
	if len(parts) == 2 && strings.EqualFold(parts[0], "Bearer") {
		return parts[1]
	}
	return ""
}

func sendError(conn *websocket.Conn, msg string) {
	_ = conn.WriteJSON(map[string]string{"type": "error", "message": msg})
}
