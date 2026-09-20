package httpapi

import (
	"context"
	"errors"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"quiz_master/next/server/internal/attempts"
)

func TestStrictAttemptJSON(t *testing.T) {
	for _, raw := range []string{`{"score":99}`, `{} {}`, `null`, `{"question_id":"q-one","question_id":"q-two"}`, `{"Question_ID":"q-one"}`, `{"answer":{"option_id":"opt-one","correct":true}}`, `{"answer":{"option_id":"opt-one","text":null}}`, string([]byte{'{', '"', 'x', '"', ':', '"', 0xff, '"', '}'}), strings.Repeat(" ", 65537) + `{}`} {
		t.Run(raw[:min(len(raw), 50)], func(t *testing.T) {
			r := httptest.NewRequest("POST", "/", strings.NewReader(raw))
			r.Header.Set("Content-Type", "application/json")
			var req attempts.AnswerRequest
			if decodeAttemptJSON(httptest.NewRecorder(), r, &req) == nil {
				t.Fatal("accepted invalid JSON")
			}
		})
	}
	r := httptest.NewRequest("POST", "/", strings.NewReader(`{"question_id":"q-one","question_revision":{"number":1,"sha256":"hash"},"answer":{"text":""},"idempotency_key":"key","payload_digest":"digest"}`))
	r.Header.Set("Content-Type", "application/json")
	var req attempts.AnswerRequest
	if err := decodeAttemptJSON(httptest.NewRecorder(), r, &req); err != nil || req.Answer.Text == nil {
		t.Fatal(err)
	}
}
func TestAttemptErrorsAreStableAndNonLeaking(t *testing.T) {
	for _, tt := range []struct {
		err    error
		status int
		code   string
	}{{attempts.ErrForbidden, 404, "forbidden"}, {attempts.ErrValidation, 400, "validation_failed"}, {attempts.ErrRevision, 409, "stale_revision"}, {attempts.ErrDeadline, 409, "deadline_exceeded"}, {attempts.ErrConflict, 409, "idempotency_conflict"}, {errors.New("private_grading=secret"), 500, "validation_failed"}} {
		w := httptest.NewRecorder()
		writeAttemptError(w, tt.err)
		if w.Code != tt.status || !strings.Contains(w.Body.String(), `"code":"`+tt.code+`"`) || strings.Contains(w.Body.String(), "secret") {
			t.Fatal("unsafe error", w.Code, w.Body.String())
		}
	}
}
func TestAttemptRoutesRequireBearerForParticipantOperations(t *testing.T) {
	h := AttemptRoutes(nil, func(_ context.Context, _ string) (Principal, error) { return Principal{}, ErrUnauthorized })
	for _, path := range []string{"/v1/attempts", "/v1/attempts/a-one/answers", "/v1/attempts/a-one/finish", "/v1/attempts/a-one/reveals", "/v1/history", "/v1/history/a-one"} {
		method := http.MethodPost
		if strings.Contains(path, "history") || strings.Contains(path, "reveals") {
			method = http.MethodGet
		}
		w := httptest.NewRecorder()
		h.ServeHTTP(w, httptest.NewRequest(method, path, nil))
		if w.Code != 401 {
			t.Fatal(path, w.Code)
		}
		if strings.Contains(path, "reveals") && w.Header().Get("Cache-Control") != "no-store" {
			t.Fatal("unauthenticated reveal response is cacheable")
		}
	}
}

func TestEveryRevealResponseIsNoStore(t *testing.T) {
	h := AttemptRoutes(nil, func(_ context.Context, _ string) (Principal, error) { return Principal{}, ErrUnauthorized })
	for _, tt := range []struct {
		method, authorization string
	}{{http.MethodGet, ""}, {http.MethodGet, "Basic invalid"}, {http.MethodGet, "Bearer invalid"}, {http.MethodPost, "Bearer invalid"}} {
		r := httptest.NewRequest(tt.method, "/v1/attempts/a-one/reveals", nil)
		if tt.authorization != "" {
			r.Header.Set("Authorization", tt.authorization)
		}
		w := httptest.NewRecorder()
		h.ServeHTTP(w, r)
		if w.Header().Get("Cache-Control") != "no-store" {
			t.Fatalf("%s %q status=%d is cacheable", tt.method, tt.authorization, w.Code)
		}
	}
}
