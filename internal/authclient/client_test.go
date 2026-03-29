package authclient

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	authdto "quiz_master/internal/authapi/dto"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestClientSubmitResult_UsesContractDTO(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		assert.Equal(t, "/internal/auth/results", r.URL.Path)
		assert.Equal(t, "secret-token", r.Header.Get("X-Internal-Token"))
		assert.Equal(t, http.MethodPost, r.Method)

		var payload authdto.SubmitResultRequest
		require.NoError(t, json.NewDecoder(r.Body).Decode(&payload))
		assert.Equal(t, "user-1", payload.UserID)
		assert.Equal(t, "quiz-1", payload.QuizID)
		assert.Equal(t, 9, payload.Score)
		assert.Equal(t, 10, payload.TotalQuestions)
		w.WriteHeader(http.StatusOK)
	}))
	defer server.Close()

	client := New(server.URL, "secret-token")
	require.NoError(t, client.SubmitResult("user-1", "quiz-1", 9, 10))
}

func TestClientGetLeaderboard_UsesContractDTO(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		assert.Equal(t, "/internal/auth/leaderboard", r.URL.Path)
		assert.Equal(t, "limit=5", r.URL.RawQuery)
		assert.Equal(t, "secret-token", r.Header.Get("X-Internal-Token"))
		require.NoError(t, json.NewEncoder(w).Encode([]authdto.LeaderboardEntry{
			{Username: "alex", Score: 9, Total: 10, QuizTitle: "Quiz 1"},
		}))
	}))
	defer server.Close()

	client := New(server.URL, "secret-token")
	entries, err := client.GetLeaderboard(5)
	require.NoError(t, err)
	require.Len(t, entries, 1)
	assert.Equal(t, "alex", entries[0].Username)
}
