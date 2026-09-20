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

	"quiz_master/next/server/internal/attempts"
	"quiz_master/next/server/internal/config"
	"quiz_master/next/server/internal/content"
	"quiz_master/next/server/internal/httpapi"
	"quiz_master/next/server/internal/identity"
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
	attemptService, err := attempts.NewService(startupCtx, pool, cfg.ContentBundlePath, content.DefaultSchemas, cfg.AttemptDuration, attempts.Options{})
	if err != nil {
		return err
	}
	identities := identity.NewService(pool, nil, identity.NewTokenSource(nil))
	auth := func(ctx context.Context, token string) (httpapi.Principal, error) {
		p, err := identities.Authenticate(ctx, token)
		return httpapi.Principal{ID: p.ID, Kind: p.Kind}, err
	}
	srv := newServer(cfg, pool, httpapi.AttemptRoutes(attemptService, auth))
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

func newServer(cfg config.Config, db httpapi.Pinger, api ...http.Handler) *http.Server {
	mux := http.NewServeMux()
	mux.Handle("/", httpapi.HealthRoutes(db))
	if len(api) > 0 {
		mux.Handle("/v1/", api[0])
	}
	return &http.Server{Addr: cfg.ListenAddr, Handler: mux, ReadHeaderTimeout: cfg.ReadHeaderTimeout, ReadTimeout: cfg.ReadTimeout, WriteTimeout: cfg.WriteTimeout, IdleTimeout: cfg.IdleTimeout}
}
