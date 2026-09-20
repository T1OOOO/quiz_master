package httpapi

import (
	"context"
	"errors"
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestWriteErrorDoesNotExposeInternalDetails(t *testing.T) {
	r := httptest.NewRecorder()
	WriteError(r, http.StatusUnauthorized, ErrUnauthorized)
	if got := r.Body.String(); got != "{\"code\":\"forbidden\",\"message\":\"request is not authorized\",\"retryable\":false,\"details\":{}}\n" {
		t.Fatalf("body = %q", got)
	}
}

func TestAuthenticateUsesBearerTokenAndPassesStablePrincipal(t *testing.T) {
	h := Authenticate(func(ctx context.Context, token string) (Principal, error) {
		if token != "opaque-token" {
			return Principal{}, errors.New("unexpected token")
		}
		return Principal{ID: "p_0123456789abcdef0123456789abcdef", Kind: "guest"}, nil
	}, http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		p, ok := PrincipalFromContext(r.Context())
		if !ok || p.ID != "p_0123456789abcdef0123456789abcdef" {
			t.Fatal("stable principal was not passed")
		}
		w.WriteHeader(http.StatusNoContent)
	}))
	r := httptest.NewRequest(http.MethodGet, "/", nil)
	r.Header.Set("Authorization", "Bearer opaque-token")
	w := httptest.NewRecorder()
	h.ServeHTTP(w, r)
	if w.Code != http.StatusNoContent {
		t.Fatalf("status = %d", w.Code)
	}
}

func TestRequirePrincipalRejectsDisplayNameHeader(t *testing.T) {
	h := RequirePrincipal(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) { w.WriteHeader(http.StatusNoContent) }))
	r := httptest.NewRequest(http.MethodGet, "/", nil)
	r.Header.Set("X-Display-Name", "someone else")
	w := httptest.NewRecorder()
	h.ServeHTTP(w, r)
	if w.Code != http.StatusUnauthorized {
		t.Fatalf("status = %d", w.Code)
	}
}
