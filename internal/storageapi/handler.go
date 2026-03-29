package storageapi

import (
	"encoding/json"
	"net/http"

	"quiz_master/internal/models"
	quizdomain "quiz_master/internal/quiz/domain"
	quizservice "quiz_master/internal/quiz/service"
	"quiz_master/internal/roomstate"
	storagedto "quiz_master/internal/storageapi/dto"

	"github.com/labstack/echo/v4"
)

type Handler struct {
	service *quizservice.QuizService
	rooms   *roomstate.Service
}

func NewHandler(s *quizservice.QuizService, rooms *roomstate.Service) *Handler {
	return &Handler{service: s, rooms: rooms}
}

func (h *Handler) List(c echo.Context) error {
	quizzes, err := h.service.ListQuizzes()
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": err.Error()})
	}
	out := make([]storagedto.Quiz, len(quizzes))
	for i, quiz := range quizzes {
		dtoQuiz := toDTOQuiz(&quiz)
		if dtoQuiz != nil {
			out[i] = *dtoQuiz
		}
	}
	return c.JSON(http.StatusOK, out)
}

func (h *Handler) Get(c echo.Context) error {
	id := c.Param("id")
	q, err := h.service.GetRawQuiz(id)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": err.Error()})
	}
	if q == nil {
		return c.JSON(http.StatusNotFound, map[string]string{"error": "quiz not found"})
	}
	return c.JSON(http.StatusOK, toDTOQuiz(q))
}

func (h *Handler) GetSummary(c echo.Context) error {
	id := c.Param("id")
	q, err := h.service.GetRawQuizSummary(id)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": err.Error()})
	}
	if q == nil {
		return c.JSON(http.StatusNotFound, map[string]string{"error": "quiz not found"})
	}
	return c.JSON(http.StatusOK, toDTOQuiz(q))
}

func (h *Handler) GetQuestion(c echo.Context) error {
	id := c.Param("id")
	qid := c.Param("qid")
	q, err := h.service.GetRawQuestion(id, qid)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": err.Error()})
	}
	if q == nil {
		return c.JSON(http.StatusNotFound, map[string]string{"error": "question not found"})
	}
	return c.JSON(http.StatusOK, toDTOQuestion(*q))
}

func (h *Handler) Create(c echo.Context) error {
	var payload storagedto.Quiz
	if err := c.Bind(&payload); err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "invalid request"})
	}
	q := fromDTOQuiz(&payload)
	if q == nil {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "invalid request"})
	}
	if err := h.service.CreateQuiz(q); err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": err.Error()})
	}
	return c.JSON(http.StatusCreated, toDTOQuiz(q))
}

func (h *Handler) Update(c echo.Context) error {
	id := c.Param("id")
	var payload storagedto.Quiz
	if err := c.Bind(&payload); err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "invalid request"})
	}
	q := fromDTOQuiz(&payload)
	if q == nil {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "invalid request"})
	}
	q.ID = id
	if err := h.service.UpdateQuiz(q); err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": err.Error()})
	}
	return c.JSON(http.StatusOK, toDTOQuiz(q))
}

func (h *Handler) Delete(c echo.Context) error {
	id := c.Param("id")
	if err := h.service.DeleteQuiz(id); err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": err.Error()})
	}
	return c.NoContent(http.StatusNoContent)
}

func (h *Handler) Report(c echo.Context) error {
	var payload storagedto.ReportRequest
	if err := c.Bind(&payload); err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "invalid request"})
	}
	report := quizdomain.QuizReport{
		QuizID:       payload.QuizID,
		QuestionID:   payload.QuestionID,
		Message:      payload.Message,
		QuestionText: payload.QuestionText,
	}
	if err := h.service.SubmitReport(&report); err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": err.Error()})
	}
	return c.JSON(http.StatusOK, map[string]string{"status": "reported"})
}

func (h *Handler) CreateRoom(c echo.Context) error {
	var payload storagedto.RoomCreateRequest
	if err := c.Bind(&payload); err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "invalid request"})
	}
	room, err := h.rooms.CreateRoom(payload.Username, payload.Avatar)
	if err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": err.Error()})
	}
	return c.JSON(http.StatusCreated, toDTORoom(room))
}

func (h *Handler) GetRoom(c echo.Context) error {
	room, err := h.rooms.GetRoom(c.Param("code"))
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": err.Error()})
	}
	if room == nil {
		return c.JSON(http.StatusNotFound, map[string]string{"error": "room not found"})
	}
	return c.JSON(http.StatusOK, toDTORoom(room))
}

func (h *Handler) JoinRoom(c echo.Context) error {
	var payload storagedto.RoomJoinRequest
	if err := c.Bind(&payload); err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "invalid request"})
	}
	room, err := h.rooms.JoinRoom(c.Param("code"), payload.Username, payload.Avatar)
	if err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": err.Error()})
	}
	return c.JSON(http.StatusOK, toDTORoom(room))
}

func (h *Handler) LeaveRoom(c echo.Context) error {
	var payload storagedto.RoomLeaveRequest
	if err := c.Bind(&payload); err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "invalid request"})
	}
	room, err := h.rooms.LeaveRoom(c.Param("code"), payload.Username)
	if err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": err.Error()})
	}
	if room == nil {
		return c.NoContent(http.StatusNoContent)
	}
	return c.JSON(http.StatusOK, toDTORoom(room))
}

func (h *Handler) StartRoom(c echo.Context) error {
	var payload storagedto.RoomStartRequest
	if err := c.Bind(&payload); err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "invalid request"})
	}
	room, err := h.rooms.StartGame(c.Param("code"), payload.Username, payload.QuizID)
	if err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": err.Error()})
	}
	return c.JSON(http.StatusOK, toDTORoom(room))
}

func (h *Handler) VoteRoom(c echo.Context) error {
	var payload storagedto.RoomVoteRequest
	if err := c.Bind(&payload); err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "invalid request"})
	}
	room, err := h.rooms.SubmitVote(c.Param("code"), payload.Username, payload.AnswerIndex)
	if err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": err.Error()})
	}
	return c.JSON(http.StatusOK, toDTORoom(room))
}

func (h *Handler) ChatRoom(c echo.Context) error {
	var payload storagedto.RoomChatRequest
	if err := c.Bind(&payload); err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "invalid request"})
	}
	room, _, err := h.rooms.SubmitChat(c.Param("code"), payload.Username, payload.Text, payload.Image)
	if err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": err.Error()})
	}
	return c.JSON(http.StatusOK, toDTORoom(room))
}

func (h *Handler) StreamRoomEvents(c echo.Context) error {
	if h.rooms == nil {
		return c.JSON(http.StatusServiceUnavailable, map[string]string{"error": "room events unavailable"})
	}

	c.Response().Header().Set(echo.HeaderContentType, "application/x-ndjson")
	c.Response().Header().Set("Cache-Control", "no-cache")
	c.Response().WriteHeader(http.StatusOK)

	flusher, ok := c.Response().Writer.(http.Flusher)
	if !ok {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "streaming unsupported"})
	}

	events := h.rooms.Subscribe(c.Request().Context())
	encoder := json.NewEncoder(c.Response())
	for {
		select {
		case <-c.Request().Context().Done():
			return nil
		case evt, ok := <-events:
			if !ok {
				return nil
			}
			if err := encoder.Encode(toDTORoomEvent(evt)); err != nil {
				return nil
			}
			flusher.Flush()
		}
	}
}

func toDTORoom(room *models.Room) *storagedto.Room {
	if room == nil {
		return nil
	}
	players := make(map[string]storagedto.RoomPlayer, len(room.Players))
	for key, player := range room.Players {
		if player == nil {
			continue
		}
		players[key] = storagedto.RoomPlayer{
			Username:    player.Username,
			AvatarColor: player.AvatarColor,
			Score:       player.Score,
		}
	}
	chat := make([]storagedto.RoomChatMessage, 0, len(room.ChatHistory))
	for _, item := range room.ChatHistory {
		chat = append(chat, storagedto.RoomChatMessage{
			User:      item.User,
			Text:      item.Text,
			Image:     item.Image,
			Timestamp: item.Timestamp,
		})
	}
	return &storagedto.Room{
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

func toDTORoomEvent(evt roomstate.Event) storagedto.RoomEvent {
	var chat *storagedto.RoomChatMessage
	if evt.ChatMessage != nil {
		chat = &storagedto.RoomChatMessage{
			User:      evt.ChatMessage.User,
			Text:      evt.ChatMessage.Text,
			Image:     evt.ChatMessage.Image,
			Timestamp: evt.ChatMessage.Timestamp,
		}
	}
	return storagedto.RoomEvent{
		Type:          string(evt.Type),
		RoomCode:      evt.RoomCode,
		Room:          toDTORoom(evt.Room),
		BroadcastType: evt.BroadcastType,
		QuizID:        evt.QuizID,
		ChatMessage:   chat,
	}
}
