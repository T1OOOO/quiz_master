package realtime

import (
	"errors"
	"log"
	"net/http"
	"strings"
	"sync"

	"github.com/gorilla/websocket"
	"github.com/labstack/echo/v4"
	authtoken "quiz_master/internal/auth/token"
)

type Event struct {
	Type    string `json:"type"`
	Message string `json:"message"`
	User    string `json:"user,omitempty"`
}

type Hub struct {
	clients    map[*websocket.Conn]bool
	broadcast  chan Event
	register   chan *websocket.Conn
	unregister chan *websocket.Conn
	mutex      sync.Mutex
}

var GlobalHub = &Hub{
	broadcast:  make(chan Event),
	register:   make(chan *websocket.Conn),
	unregister: make(chan *websocket.Conn),
	clients:    make(map[*websocket.Conn]bool),
}

type quizRepository interface{}

func NewHub(repo quizRepository) *Hub {
	Manager.repo = repo
	return GlobalHub
}

func (h *Hub) Run() {
	for {
		select {
		case client := <-h.register:
			h.mutex.Lock()
			h.clients[client] = true
			h.mutex.Unlock()
			log.Println("New spectator connected")

		case client := <-h.unregister:
			h.mutex.Lock()
			if _, ok := h.clients[client]; ok {
				delete(h.clients, client)
				client.Close()
			}
			h.mutex.Unlock()
			log.Println("Spectator disconnected")

		case message := <-h.broadcast:
			h.mutex.Lock()
			for client := range h.clients {
				err := client.WriteJSON(message)
				if err != nil {
					log.Printf("WS Error: %v", err)
					client.Close()
					delete(h.clients, client)
				}
			}
			h.mutex.Unlock()
		}
	}
}

func (h *Hub) BroadcastEvent(evt Event) {
	h.broadcast <- evt
}

func NewWebSocketHandler(tokens *authtoken.Manager, allowedOrigins []string) echo.HandlerFunc {
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

		GlobalHub.register <- ws

		go func() {
			defer func() {
				GlobalHub.unregister <- ws
				Manager.RemoveClient(ws)
				ws.Close()
			}()

			for {
				_, msg, err := ws.ReadMessage()
				if err != nil {
					break
				}

				Manager.HandleMessage(ws, msg)
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
