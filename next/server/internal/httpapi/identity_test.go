package httpapi

import (
	"context"
	"errors"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"quiz_master/next/server/internal/identity"
)

func TestGuestBootstrapReturnsOnlyClosedCredentialResponse(t *testing.T) {
	expires := time.Date(2026, 9, 21, 12, 0, 0, 0, time.UTC)
	called := 0
	h := IdentityRoutes(func(_ context.Context, displayName string) (identity.GuestSession, error) {
		called++
		if displayName != "Ada" {
			t.Fatalf("display name = %q", displayName)
		}
		return identity.GuestSession{Principal: identity.Principal{ID: "p_0123456789abcdef0123456789abcdef", Kind: "guest", DisplayName: displayName}, Token: "opaque-token", ExpiresAt: expires}, nil
	})
	r := httptest.NewRequest(http.MethodPost, "/v1/guests", strings.NewReader(`{"display_name":" Ada "}`))
	r.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	h.ServeHTTP(w, r)
	if w.Code != http.StatusCreated || called != 1 {
		t.Fatalf("status=%d calls=%d", w.Code, called)
	}
	want := "{\"participant_id\":\"p-0123456789abcdef0123456789abcdef\",\"kind\":\"guest\",\"display_name\":\"Ada\",\"token\":\"opaque-token\",\"expires_at\":\"2026-09-21T12:00:00Z\"}\n"
	if w.Body.String() != want {
		t.Fatalf("body = %s", w.Body.String())
	}
	if w.Header().Get("Cache-Control") != "no-store" {
		t.Fatal("credential response is cacheable")
	}
}

func TestGuestBootstrapRejectsAmbiguousOrInvalidBodiesWithoutEcho(t *testing.T) {
	called := 0
	h := IdentityRoutes(func(_ context.Context, _ string) (identity.GuestSession, error) {
		called++
		return identity.GuestSession{}, errors.New("not called")
	})
	invalid := []string{
		`null`,
		`{}`,
		`{"display_name":null}`,
		`{"display_name":" "}`,
		`{"display_name":"private-name","display_name":"duplicate"}`,
		`{"display_name":"private-name","Display_Name":"alias"}`,
		`{"display_name":"private-name","unknown":true}`,
		string([]byte{'{', '"', 'd', 'i', 's', 'p', 'l', 'a', 'y', '_', 'n', 'a', 'm', 'e', '"', ':', '"', 0xff, '"', '}'}),
		`{"display_name":"` + strings.Repeat("x", 65536) + `"}`,
	}
	for i, body := range invalid {
		r := httptest.NewRequest(http.MethodPost, "/v1/guests", strings.NewReader(body))
		r.Header.Set("Content-Type", "application/json")
		w := httptest.NewRecorder()
		h.ServeHTTP(w, r)
		if w.Code != http.StatusBadRequest || strings.Contains(w.Body.String(), "private-name") || strings.Contains(w.Body.String(), "duplicate") {
			t.Fatalf("case %d status=%d body=%q", i, w.Code, w.Body.String())
		}
	}
	if called != 0 {
		t.Fatalf("creator called %d times", called)
	}
}

func TestGuestBootstrapDoesNotExposeCreationFailure(t *testing.T) {
	h := IdentityRoutes(func(_ context.Context, _ string) (identity.GuestSession, error) {
		return identity.GuestSession{}, errors.New("database private detail")
	})
	r := httptest.NewRequest(http.MethodPost, "/v1/guests", strings.NewReader(`{"display_name":"Ada"}`))
	r.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	h.ServeHTTP(w, r)
	if w.Code != http.StatusInternalServerError || strings.Contains(w.Body.String(), "database") || strings.Contains(w.Body.String(), "Ada") {
		t.Fatalf("status=%d body=%q", w.Code, w.Body.String())
	}
}

func TestRoutesComposeGuestAndProtectedAttemptPatterns(t *testing.T) {
	expires := time.Date(2026, 9, 21, 12, 0, 0, 0, time.UTC)
	h := Routes(nil, func(context.Context, string) (Principal, error) { return Principal{}, ErrUnauthorized }, func(_ context.Context, displayName string) (identity.GuestSession, error) {
		return identity.GuestSession{Principal: identity.Principal{ID: "p_0123456789abcdef0123456789abcdef", Kind: "guest", DisplayName: displayName}, Token: "opaque", ExpiresAt: expires}, nil
	})
	r := httptest.NewRequest(http.MethodPost, "/v1/guests", strings.NewReader(`{"display_name":"Ada"}`))
	r.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	h.ServeHTTP(w, r)
	if w.Code != http.StatusCreated {
		t.Fatalf("guest status = %d", w.Code)
	}
	w = httptest.NewRecorder()
	h.ServeHTTP(w, httptest.NewRequest(http.MethodPost, "/v1/attempts", strings.NewReader(`{}`)))
	if w.Code != http.StatusUnauthorized {
		t.Fatalf("attempt status = %d", w.Code)
	}
}

// This exercises the public contract before reports are wired: an authenticated
// participant must be able to submit a bounded feedback report.
func TestRoutesAcceptsAuthenticatedFeedbackReport(t *testing.T) {
	h := Routes(nil, func(_ context.Context, token string) (Principal, error) {
		if token != "guest-token" {
			return Principal{}, ErrUnauthorized
		}
		return Principal{ID: "p_0123456789abcdef0123456789abcdef", Kind: "guest"}, nil
	}, func(context.Context, string) (identity.GuestSession, error) { return identity.GuestSession{}, nil }, FeedbackConfig{Store: newFeedbackStore(t)})
	r := httptest.NewRequest(http.MethodPost, "/v1/reports", strings.NewReader(`{"request_id":"frq_0123456789abcdef0123456789abcdef","type":"ui","item_ids":["screen:/library"],"comment":"Button overlaps the answer","context":{"route":"/library","viewport":{"width":390,"height":844,"dpr":2},"locale":"en","theme":"light","platform":"web","app_version":"test","timestamp":"2026-10-06T00:00:00Z"}}`))
	r.Header.Set("Content-Type", "application/json")
	r.Header.Set("Authorization", "Bearer guest-token")
	w := httptest.NewRecorder()
	h.ServeHTTP(w, r)
	if w.Code != http.StatusCreated {
		t.Fatalf("report status = %d, body=%q", w.Code, w.Body.String())
	}
}
