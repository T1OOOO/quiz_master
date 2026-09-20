package main

import (
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"quiz_master/next/server/internal/config"
)

func TestNewServerMountsAttemptsAndPreservesLiveness(t *testing.T) {
	srv := newServer(config.Config{}, nil, http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) { w.WriteHeader(204) }))
	for path, want := range map[string]int{"/v1/catalog": 204, "/health/live": 200} {
		w := httptest.NewRecorder()
		srv.Handler.ServeHTTP(w, httptest.NewRequest("GET", path, nil))
		if w.Code != want {
			t.Fatal(path, w.Code)
		}
	}
}

func TestNewServerAppliesAllConfiguredHTTPTimeouts(t *testing.T) {
	cfg := config.Config{ListenAddr: "127.0.0.1:8088", ReadHeaderTimeout: time.Second, ReadTimeout: 2 * time.Second, WriteTimeout: 3 * time.Second, IdleTimeout: 4 * time.Second}
	srv := newServer(cfg, nil)
	if srv.ReadHeaderTimeout != time.Second || srv.ReadTimeout != 2*time.Second || srv.WriteTimeout != 3*time.Second || srv.IdleTimeout != 4*time.Second {
		t.Fatalf("server timeouts: %#v", srv)
	}
}
