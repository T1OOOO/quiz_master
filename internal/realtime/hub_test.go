package realtime

import (
	"net/http"
	"net/http/httptest"
	"testing"

	authdomain "quiz_master/internal/auth/domain"
	authtoken "quiz_master/internal/auth/token"
)

func TestAuthorizeWebSocketRequestRequiresToken(t *testing.T) {
	req := httptest.NewRequest(http.MethodGet, "/ws", nil)
	if err := authorizeWebSocketRequest(req, authtoken.NewLegacyManager()); err == nil {
		t.Fatal("expected websocket auth to reject missing token")
	}
}

func TestAuthorizeWebSocketRequestAcceptsQueryToken(t *testing.T) {
	tokens := authtoken.NewLegacyManager()
	token, err := tokens.Generate(authdomain.Claims{
		UserID:   "user-1",
		Username: "alex",
		Role:     "user",
	})
	if err != nil {
		t.Fatalf("failed to generate token: %v", err)
	}

	req := httptest.NewRequest(http.MethodGet, "/ws?access_token="+token, nil)
	if err := authorizeWebSocketRequest(req, tokens); err != nil {
		t.Fatalf("expected websocket auth to accept valid token: %v", err)
	}
}
