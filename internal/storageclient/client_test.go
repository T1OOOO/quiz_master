package storageclient

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	quizdomain "quiz_master/internal/quiz/domain"
	storagedto "quiz_master/internal/storageapi/dto"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestClientGetSummary_UsesContractDTO(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		assert.Equal(t, "/internal/storage/quizzes/quiz-1/summary", r.URL.Path)
		assert.Equal(t, "secret-token", r.Header.Get("X-Internal-Token"))
		assert.Equal(t, http.MethodGet, r.Method)
		require.NoError(t, json.NewEncoder(w).Encode(storagedto.Quiz{
			ID:             "quiz-1",
			Title:          "Quiz 1",
			Description:    "Desc",
			Category:       "General",
			QuestionsCount: 1,
			Questions: []storagedto.Question{
				{ID: "q1", Type: "choice", Text: "Question?", Difficulty: 2},
			},
		}))
	}))
	defer server.Close()

	client := New(server.URL, "secret-token")
	quiz, err := client.GetSummary("quiz-1")
	require.NoError(t, err)
	require.NotNil(t, quiz)
	assert.Equal(t, "quiz-1", quiz.ID)
	assert.Equal(t, "Quiz 1", quiz.Title)
	assert.Len(t, quiz.Questions, 1)
	assert.Equal(t, "q1", quiz.Questions[0].ID)
}

func TestClientSaveReport_UsesContractDTO(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		assert.Equal(t, "/internal/storage/reports", r.URL.Path)
		assert.Equal(t, http.MethodPost, r.Method)
		assert.Equal(t, "secret-token", r.Header.Get("X-Internal-Token"))

		var payload storagedto.ReportRequest
		require.NoError(t, json.NewDecoder(r.Body).Decode(&payload))
		assert.Equal(t, "quiz-1", payload.QuizID)
		assert.Equal(t, "question-1", payload.QuestionID)
		assert.Equal(t, "Broken answer", payload.Message)

		w.WriteHeader(http.StatusOK)
	}))
	defer server.Close()

	client := New(server.URL, "secret-token")
	err := client.SaveReport(&quizdomain.QuizReport{
		QuizID:       "quiz-1",
		QuestionID:   "question-1",
		Message:      "Broken answer",
		QuestionText: "Question?",
	})
	require.NoError(t, err)
}

func TestClientStreamRoomEvents_UsesNDJSONContract(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		assert.Equal(t, "/internal/storage/rooms/stream", r.URL.Path)
		assert.Equal(t, "secret-token", r.Header.Get("X-Internal-Token"))
		w.Header().Set("Content-Type", "application/x-ndjson")
		require.NoError(t, json.NewEncoder(w).Encode(storagedto.RoomEvent{
			Type:     "upsert",
			RoomCode: "ABCD",
			Room: &storagedto.Room{
				Code:   "ABCD",
				HostID: "host",
				State:  "waiting",
				Players: map[string]storagedto.RoomPlayer{
					"host": {Username: "host", AvatarColor: "#111111", Score: 0},
				},
			},
		}))
	}))
	defer server.Close()

	client := New(server.URL, "secret-token")
	var got RoomEvent
	err := client.StreamRoomEvents(context.Background(), func(evt RoomEvent) error {
		got = evt
		return context.Canceled
	})
	require.ErrorIs(t, err, context.Canceled)
	assert.Equal(t, "upsert", got.Type)
	require.NotNil(t, got.Room)
	assert.Equal(t, "ABCD", got.Room.Code)
}
