package config

import (
	"fmt"
	"net"
	"net/url"
	"os"
	"time"
)

type Config struct {
	ListenAddr, DatabaseURL                                                 string
	ShutdownTimeout, DatabaseStartupTimeout, ReadHeaderTimeout, ReadTimeout time.Duration
	WriteTimeout, IdleTimeout                                               time.Duration
}

func FromEnv() (Config, error) {
	c := Config{ListenAddr: os.Getenv("QM_LISTEN_ADDR"), DatabaseURL: os.Getenv("QM_DATABASE_URL"), ShutdownTimeout: 10 * time.Second, DatabaseStartupTimeout: 15 * time.Second, ReadHeaderTimeout: 5 * time.Second, ReadTimeout: 15 * time.Second, WriteTimeout: 15 * time.Second, IdleTimeout: 60 * time.Second}
	if c.ListenAddr == "" {
		return Config{}, fmt.Errorf("QM_LISTEN_ADDR is required")
	}
	if _, _, err := net.SplitHostPort(c.ListenAddr); err != nil {
		return Config{}, fmt.Errorf("QM_LISTEN_ADDR: %w", err)
	}
	if c.DatabaseURL == "" {
		return Config{}, fmt.Errorf("QM_DATABASE_URL is required")
	}
	u, err := url.Parse(c.DatabaseURL)
	if err != nil || u.Scheme == "" || u.Host == "" {
		return Config{}, fmt.Errorf("QM_DATABASE_URL must be an absolute URL")
	}
	for _, setting := range []struct {
		name   string
		target *time.Duration
	}{{"QM_SHUTDOWN_TIMEOUT", &c.ShutdownTimeout}, {"QM_DATABASE_STARTUP_TIMEOUT", &c.DatabaseStartupTimeout}, {"QM_READ_HEADER_TIMEOUT", &c.ReadHeaderTimeout}, {"QM_READ_TIMEOUT", &c.ReadTimeout}, {"QM_WRITE_TIMEOUT", &c.WriteTimeout}, {"QM_IDLE_TIMEOUT", &c.IdleTimeout}} {
		if err := readDuration(setting.name, setting.target); err != nil {
			return Config{}, err
		}
	}
	return c, nil
}

func readDuration(name string, target *time.Duration) error {
	if raw := os.Getenv(name); raw != "" {
		value, err := time.ParseDuration(raw)
		if err != nil || value <= 0 {
			return fmt.Errorf("%s must be a positive duration", name)
		}
		*target = value
	}
	return nil
}
