package httpapi

import (
	"context"
	"errors"
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestHealthRoutesDistinguishLivenessFromDatabaseReadiness(t *testing.T) {
	h := HealthRoutes(failingPinger{})
	for _, tc := range []struct {
		path string
		want int
	}{{"/health/live", 200}, {"/health/ready", 503}} {
		w := httptest.NewRecorder()
		h.ServeHTTP(w, httptest.NewRequest(http.MethodGet, tc.path, nil))
		if w.Code != tc.want {
			t.Fatalf("%s = %d", tc.path, w.Code)
		}
	}
}

type failingPinger struct{}

func (failingPinger) Ping(context.Context) error { return errors.New("database unavailable") }
