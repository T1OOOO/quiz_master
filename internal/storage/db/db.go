package db

import (
	"context"
	"database/sql"
	"fmt"
	"time"

	"quiz_master/internal/dbx"

	_ "github.com/jackc/pgx/v5/stdlib"
	_ "modernc.org/sqlite"
)

type Config struct {
	Driver       string
	DSN          string
	Path         string
	MaxOpenConns int
	MaxIdleConns int
	ConnMaxIdle  time.Duration
}

func Open(ctx context.Context, cfg Config) (*sql.DB, error) {
	driverName, dsn := resolveDriver(cfg.Driver, cfg.DSN, cfg.Path)
	database, err := sql.Open(driverName, dsn)
	if err != nil {
		return nil, fmt.Errorf("failed to open db: %w", err)
	}
	dbx.Register(database, driverName)

	if cfg.MaxOpenConns > 0 {
		database.SetMaxOpenConns(cfg.MaxOpenConns)
	}
	if cfg.MaxIdleConns > 0 {
		database.SetMaxIdleConns(cfg.MaxIdleConns)
	}
	if cfg.ConnMaxIdle > 0 {
		database.SetConnMaxIdleTime(cfg.ConnMaxIdle)
	}

	if err := Ping(ctx, database, 3, 200*time.Millisecond); err != nil {
		_ = database.Close()
		return nil, err
	}

	if err := RunMigrations(database); err != nil {
		_ = database.Close()
		return nil, err
	}

	return database, nil
}

func resolveDriver(driver, dsn, path string) (string, string) {
	switch dbx.NormalizeDriver(driver) {
	case dbx.DriverPostgres:
		return "pgx", dsn
	default:
		return "sqlite", path
	}
}

func Ping(ctx context.Context, database *sql.DB, attempts int, delay time.Duration) error {
	if attempts <= 0 {
		attempts = 1
	}

	var err error
	for i := 0; i < attempts; i++ {
		err = database.PingContext(ctx)
		if err == nil {
			return nil
		}

		select {
		case <-ctx.Done():
			return ctx.Err()
		case <-time.After(delay):
		}
	}

	return fmt.Errorf("failed to ping db: %w", err)
}

func Close(database *sql.DB) error {
	if database == nil {
		return nil
	}
	return database.Close()
}
