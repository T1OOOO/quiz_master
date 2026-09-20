package main

import (
	"context"
	"errors"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"

	"github.com/jackc/pgx/v5/pgxpool"

	"quiz_master/next/server/internal/config"
	"quiz_master/next/server/internal/httpapi"
	"quiz_master/next/server/internal/migrate"
)

func main() {
	if err := run(); err != nil {
		log.Print(err)
		os.Exit(1)
	}
}
func run() error {
	cfg, err := config.FromEnv()
	if err != nil {
		return err
	}
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()
	pool, err := pgxpool.New(ctx, cfg.DatabaseURL)
	if err != nil {
		return err
	}
	defer pool.Close()
	startupCtx, cancelStartup := context.WithTimeout(ctx, cfg.DatabaseStartupTimeout)
	defer cancelStartup()
	if err := pool.Ping(startupCtx); err != nil {
		return err
	}
	if err := migrate.Apply(startupCtx, pool, migrate.Migrations()); err != nil {
		return err
	}
	srv := newServer(cfg, pool)
	errCh := make(chan error, 1)
	go func() { errCh <- srv.ListenAndServe() }()
	select {
	case <-ctx.Done():
		shutdownCtx, cancel := context.WithTimeout(context.Background(), cfg.ShutdownTimeout)
		defer cancel()
		return srv.Shutdown(shutdownCtx)
	case err := <-errCh:
		if errors.Is(err, http.ErrServerClosed) {
			return nil
		}
		return err
	}
}

func newServer(cfg config.Config, db httpapi.Pinger) *http.Server {
	return &http.Server{Addr: cfg.ListenAddr, Handler: httpapi.HealthRoutes(db), ReadHeaderTimeout: cfg.ReadHeaderTimeout, ReadTimeout: cfg.ReadTimeout, WriteTimeout: cfg.WriteTimeout, IdleTimeout: cfg.IdleTimeout}
}
