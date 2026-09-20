package main

import (
	"context"
	"database/sql"
	"errors"
	"log"
	_ "modernc.org/sqlite"
	"net/http"
	"os"
	"os/signal"
	"strings"
	"syscall"

	"github.com/jackc/pgx/v5/pgxpool"

	"quiz_master/next/server/internal/attempts"
	"quiz_master/next/server/internal/config"
	"quiz_master/next/server/internal/content"
	"quiz_master/next/server/internal/httpapi"
	"quiz_master/next/server/internal/identity"
	"quiz_master/next/server/internal/migrate"
	localsqlite "quiz_master/next/server/internal/sqlite"
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
	if strings.HasPrefix(cfg.DatabaseURL, "sqlite:") {
		return runSQLite(ctx, cfg)
	}
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
	attemptService, err := attempts.NewService(startupCtx, pool, cfg.ContentBundlePath, content.DefaultSchemas, cfg.AttemptDuration, attempts.Options{ManifestPath: cfg.ContentManifestPath})
	if err != nil {
		return err
	}
	identities := identity.NewService(pool, nil, identity.NewTokenSource(nil))
	auth := func(ctx context.Context, token string) (httpapi.Principal, error) {
		p, err := identities.Authenticate(ctx, token)
		return httpapi.Principal{ID: p.ID, Kind: p.Kind}, err
	}
	srv := newServer(cfg, pool, httpapi.Routes(attemptService, auth, identities.CreateGuestSession))
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

func runSQLite(ctx context.Context, cfg config.Config) error {
	db, err := sql.Open("sqlite", strings.TrimPrefix(cfg.DatabaseURL, "sqlite:"))
	if err != nil {
		return err
	}
	defer db.Close()
	if err = localsqlite.Apply(ctx, db); err != nil {
		return err
	}
	attemptService, err := localsqlite.NewAttempts(db, cfg.ContentBundlePath, cfg.ContentManifestPath, content.DefaultSchemas, cfg.AttemptDuration)
	if err != nil {
		return err
	}
	identities := localsqlite.NewIdentity(db, nil, identity.NewTokenSource(nil))
	auth := func(ctx context.Context, token string) (httpapi.Principal, error) {
		p, e := identities.Authenticate(ctx, token)
		return httpapi.Principal{ID: p.ID, Kind: p.Kind}, e
	}
	srv := newServer(cfg, sqlitePinger{db}, httpapi.Routes(attemptService, auth, identities.CreateGuestSession))
	errCh := make(chan error, 1)
	go func() { errCh <- srv.ListenAndServe() }()
	select {
	case <-ctx.Done():
		shutdown, cancel := context.WithTimeout(context.Background(), cfg.ShutdownTimeout)
		defer cancel()
		return srv.Shutdown(shutdown)
	case err := <-errCh:
		if errors.Is(err, http.ErrServerClosed) {
			return nil
		}
		return err
	}
}

type sqlitePinger struct{ db *sql.DB }

func (p sqlitePinger) Ping(ctx context.Context) error { return p.db.PingContext(ctx) }

func newServer(cfg config.Config, db httpapi.Pinger, api ...http.Handler) *http.Server {
	mux := http.NewServeMux()
	mux.Handle("/", httpapi.HealthRoutes(db))
	if len(api) > 0 {
		mux.Handle("/v1/", api[0])
	}
	return &http.Server{Addr: cfg.ListenAddr, Handler: mux, ReadHeaderTimeout: cfg.ReadHeaderTimeout, ReadTimeout: cfg.ReadTimeout, WriteTimeout: cfg.WriteTimeout, IdleTimeout: cfg.IdleTimeout}
}
