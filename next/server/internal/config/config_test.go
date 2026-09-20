package config

import (
	"testing"
	"time"
)

func TestFromEnvRejectsMissingDatabaseURL(t *testing.T) {
	t.Setenv("QM_LISTEN_ADDR", "127.0.0.1:8088")
	t.Setenv("QM_DATABASE_URL", "")
	if _, err := FromEnv(); err == nil {
		t.Fatal("FromEnv accepted a missing database URL")
	}
}

func TestFromEnvReadsValidatedValues(t *testing.T) {
	t.Setenv("QM_LISTEN_ADDR", "127.0.0.1:8088")
	t.Setenv("QM_DATABASE_URL", "postgres://user:pass@host/db")
	t.Setenv("QM_SHUTDOWN_TIMEOUT", "3s")
	cfg, err := FromEnv()
	if err != nil {
		t.Fatal(err)
	}
	if cfg.ListenAddr != "127.0.0.1:8088" || cfg.ShutdownTimeout != 3*time.Second {
		t.Fatalf("unexpected config: %#v", cfg)
	}
}

func TestFromEnvProvidesPositiveNetworkTimeoutDefaults(t *testing.T) {
	t.Setenv("QM_LISTEN_ADDR", "127.0.0.1:8088")
	t.Setenv("QM_DATABASE_URL", "postgres://user:pass@host/db")
	cfg, err := FromEnv()
	if err != nil {
		t.Fatal(err)
	}
	for name, value := range map[string]time.Duration{"database startup": cfg.DatabaseStartupTimeout, "read header": cfg.ReadHeaderTimeout, "read": cfg.ReadTimeout, "write": cfg.WriteTimeout, "idle": cfg.IdleTimeout} {
		if value <= 0 {
			t.Fatalf("%s timeout = %s", name, value)
		}
	}
}

func TestFromEnvRejectsInvalidNetworkTimeouts(t *testing.T) {
	for _, key := range []string{"QM_DATABASE_STARTUP_TIMEOUT", "QM_READ_HEADER_TIMEOUT", "QM_READ_TIMEOUT", "QM_WRITE_TIMEOUT", "QM_IDLE_TIMEOUT"} {
		t.Run(key, func(t *testing.T) {
			t.Setenv("QM_LISTEN_ADDR", "127.0.0.1:8088")
			t.Setenv("QM_DATABASE_URL", "postgres://user:pass@host/db")
			t.Setenv(key, "0s")
			if _, err := FromEnv(); err == nil {
				t.Fatal("zero timeout was accepted")
			}
			t.Setenv(key, "not-a-duration")
			if _, err := FromEnv(); err == nil {
				t.Fatal("invalid timeout was accepted")
			}
		})
	}
}
