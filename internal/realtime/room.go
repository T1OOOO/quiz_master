package realtime

import (
	"encoding/json"
	"math/rand"
	"sync"
	"time"
	"quiz_master/internal/store"

	"github.com/gorilla/websocket"
)

// Game States
const (
	StateWaiting = "waiting"
	StatePlaying = "playing"
	StateFinished = "finished"
)

type Player struct {
	Conn     *websocket.Conn
	Username string
	Avatar   string // Hex color
	Score    int
}

type ChatMessage struct {
	User      string `json:"user"`
	Text      string `json:"text"`
	Image     string `json:"image,omitempty"` // Base64
	Timestamp int64  `json:"timestamp"`
}

type Room struct {
	Code            string
	HostID          string
	Players         map[string]*Player
	State           string
	QuizID          string
	CurrentQuestion int
	Votes           map[string]int
	ChatHistory     []ChatMessage
	Mutex           sync.RWMutex
}

type RoomManager struct {
	rooms   map[string]*Room
	clients map[*websocket.Conn]string
	mutex   sync.RWMutex
	repo    *store.QuizStore
}

var Manager = &RoomManager{
	rooms:   make(map[string]*Room),
	clients: make(map[*websocket.Conn]string),
}

// Payloads
type JoinPayload struct {
	Username string `json:"username"`
	Code     string `json:"code"` // Empty for create
	Avatar   string `json:"avatar"`
}

type GamePayload struct {
	Type    string          `json:"type"`
	Payload json.RawMessage `json:"payload"`
}

func (rm *RoomManager) HandleMessage(conn *websocket.Conn, message []byte) {
	var base GamePayload
	if err := json.Unmarshal(message, &base); err != nil {
		return
	}

	switch base.Type {
	case "create_room":
		rm.createRoom(conn, base.Payload)
	case "join_room":
		rm.joinRoom(conn, base.Payload)
	default:
		// Route to specific room
		rm.mutex.RLock()
		code, ok := rm.clients[conn]
		rm.mutex.RUnlock()
		if ok {
			rm.handleRoomMessage(code, conn, base.Type, base.Payload)
		}
	}
}

func (rm *RoomManager) createRoom(conn *websocket.Conn, data []byte) {
	var p JoinPayload
	json.Unmarshal(data, &p)
	
	code := generateCode()
	room := &Room{
		Code:    code,
		HostID:  p.Username,
		Players: make(map[string]*Player),
		State:   StateWaiting,
		Votes:   make(map[string]int),
	}
	
	// Add host as player
	player := &Player{Conn: conn, Username: p.Username, Avatar: p.Avatar}
	room.Players[p.Username] = player
	
	rm.mutex.Lock()
	rm.rooms[code] = room
	rm.clients[conn] = code
	rm.mutex.Unlock()
	
	room.BroadcastState()
}

func (rm *RoomManager) joinRoom(conn *websocket.Conn, data []byte) {
	var p JoinPayload
	json.Unmarshal(data, &p)
	
	rm.mutex.RLock()
	room, ok := rm.rooms[p.Code]
	rm.mutex.RUnlock()
	
	if !ok {
		sendError(conn, "Room not found")
		return
	}
	
	room.Mutex.Lock()
	room.Players[p.Username] = &Player{Conn: conn, Username: p.Username, Avatar: p.Avatar}
	room.Mutex.Unlock()
	
	rm.mutex.Lock()
	rm.clients[conn] = p.Code
	rm.mutex.Unlock()
	
	room.BroadcastState()
}

func (rm *RoomManager) handleRoomMessage(code string, conn *websocket.Conn, msgType string, payload []byte) {
	rm.mutex.RLock()
	room, ok := rm.rooms[code]
	rm.mutex.RUnlock()
	if !ok { return }

	// Find player
	var player *Player
	room.Mutex.RLock()
	for _, p := range room.Players {
		if p.Conn == conn {
			player = p
			break
		}
	}
	room.Mutex.RUnlock()

	if player == nil { return }

	switch msgType {
	case "start_game":
		if player.Username == room.HostID {
			var d struct { QuizID string `json:"quiz_id"` }
			json.Unmarshal(payload, &d)
			room.StartGame(d.QuizID)
		}
	case "vote":
		var d struct { AnswerIdx int `json:"answer_index"` }
		json.Unmarshal(payload, &d)
		room.SubmitVote(player.Username, d.AnswerIdx)
	case "chat":
		var d struct { Text string `json:"text"`; Image string `json:"image"` }
		json.Unmarshal(payload, &d)
		room.SubmitChat(player.Username, d.Text, d.Image)
	}
}

func (rm *RoomManager) RemoveClient(conn *websocket.Conn) {
	rm.mutex.Lock()
	defer rm.mutex.Unlock()
	
	code, ok := rm.clients[conn]
	if !ok { return }
	
	delete(rm.clients, conn)
	
	if room, exists := rm.rooms[code]; exists {
		room.Mutex.Lock()
		// Remove player
		for name, p := range room.Players {
			if p.Conn == conn {
				delete(room.Players, name)
				break
			}
		}
		empty := len(room.Players) == 0
		room.Mutex.Unlock()
		
		if empty {
			delete(rm.rooms, code)
		} else {
			room.BroadcastState()
		}
	}
}

// Room Methods

func (r *Room) BroadcastState() {
	r.Mutex.RLock()
	defer r.Mutex.RUnlock()
	
	// Simplify for frontend
	type PublicPlayer struct {
		Username string `json:"username"`
		Avatar   string `json:"avatar"`
		Score    int    `json:"score"`
	}
	
	players := make([]PublicPlayer, 0)
	for _, p := range r.Players {
		players = append(players, PublicPlayer{p.Username, p.Avatar, p.Score})
	}
	
	msg := map[string]interface{}{
		"type": "room_state",
		"room": map[string]interface{}{
			"code":             r.Code,
			"host":             r.HostID,
			"state":            r.State,
			"players":          players,
			"votes":            r.Votes,
			"quiz_id":          r.QuizID,
			"current_question": r.CurrentQuestion,
			"chat_history":     r.ChatHistory,
		},
	}
	
	r.broadcast(msg)
}

func (r *Room) StartGame(quizID string) {
	r.Mutex.Lock()
	r.QuizID = quizID
	r.State = StatePlaying
	r.CurrentQuestion = 0
	r.Votes = make(map[string]int)
	r.Mutex.Unlock()
	
	r.broadcast(map[string]interface{}{
		"type": "game_started",
		"quiz_id": quizID,
	})
	
	r.BroadcastState()
}

func (r *Room) SubmitVote(username string, idx int) {
	r.Mutex.Lock()
	r.Votes[username] = idx
	r.Mutex.Unlock()
	r.BroadcastState()
}

func (r *Room) broadcast(msg interface{}) {
	for _, p := range r.Players {
		p.Conn.WriteJSON(msg)
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

func (r *Room) SubmitChat(username string, text, image string) {
	r.Mutex.Lock()
	msg := ChatMessage{
		User:      username,
		Text:      text,
		Image:     image,
		Timestamp: time.Now().Unix(),
	}
	r.ChatHistory = append(r.ChatHistory, msg)
	if len(r.ChatHistory) > 50 {
		r.ChatHistory = r.ChatHistory[1:] // Keep last 50
	}
	r.Mutex.Unlock()
	
	// Broadcast chat event specifically (optimization)
	r.broadcast(map[string]interface{}{
		"type": "chat_message",
		"message": msg,
	})
}

func sendError(conn *websocket.Conn, msg string) {
	conn.WriteJSON(map[string]string{"type": "error", "message": msg})
}
