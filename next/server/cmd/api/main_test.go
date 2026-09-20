package main

import (
	"testing"
	"time"

	"quiz_master/next/server/internal/config"
)

func TestNewServerAppliesAllConfiguredHTTPTimeouts(t *testing.T) {
	cfg := config.Config{ListenAddr: "127.0.0.1:8088", ReadHeaderTimeout: time.Second, ReadTimeout: 2 * time.Second, WriteTimeout: 3 * time.Second, IdleTimeout: 4 * time.Second}
	srv := newServer(cfg, nil)
	if srv.ReadHeaderTimeout != time.Second || srv.ReadTimeout != 2*time.Second || srv.WriteTimeout != 3*time.Second || srv.IdleTimeout != 4*time.Second {
		t.Fatalf("server timeouts: %#v", srv)
	}
}
