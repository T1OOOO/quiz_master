package server

import (
	"context"
	"fmt"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	legacyapi "quiz_master/internal/api"
	authhttp "quiz_master/internal/auth/http"
	authservice "quiz_master/internal/auth/service"
	authtoken "quiz_master/internal/auth/token"
	"quiz_master/internal/config"
	"quiz_master/internal/realtime"
	"quiz_master/internal/service"
	storagedb "quiz_master/internal/storage/db"
	storagerepo "quiz_master/internal/storage/repository"

	"github.com/labstack/echo/v4"
	"github.com/labstack/echo/v4/middleware"
)

func Build(cfg *config.Config) (*App, error) {
	logger := slog.New(slog.NewJSONHandler(os.Stdout, nil))
	slog.SetDefault(logger)

	dbConn, err := storagedb.Open(context.Background(), storagedb.Config{
		Path:         cfg.DBPath,
		MaxOpenConns: cfg.DBMaxOpenConns,
		MaxIdleConns: cfg.DBMaxIdleConns,
		ConnMaxIdle:  cfg.DBConnMaxIdle,
	})
	if err != nil {
		return nil, err
	}

	quizRepo := storagerepo.NewQuizRepository(dbConn)
	userRepo := storagerepo.NewUserRepository(dbConn)

	tokenManager := authtoken.NewManager(cfg.JWTSecret, cfg.JWTTTL)
	authSvc := authservice.New(userRepo, tokenManager)
	quizSvc := service.NewQuizService(quizRepo)

	hub := realtime.NewHub(quizRepo)
	go hub.Run()

	if err := quizSvc.SyncFromFiles(cfg.QuizzesDir); err != nil {
		slog.Warn("failed to sync quizzes from files", "error", err)
	}

	authHandler := authhttp.NewHandler(authSvc, hub)
	authMiddleware := authhttp.NewMiddleware(tokenManager)
	quizHandler := legacyapi.NewQuizHandler(quizSvc)

	e := echo.New()
	e.HideBanner = true
	configureMiddleware(e)
	registerRoutes(e, authHandler, authMiddleware, quizHandler)

	app := &App{
		echo: e,
		server: &http.Server{
			Addr:              ":" + cfg.Port,
			Handler:           e,
			ReadHeaderTimeout: 5 * time.Second,
		},
		db:             dbConn,
		shutdownTimout: cfg.ShutdownTimeout,
	}

	return app, nil
}

func Run(cfg *config.Config) error {
	app, err := Build(cfg)
	if err != nil {
		return err
	}

	errCh := make(chan error, 1)
	go func() {
		slog.Info("starting quiz master api", "port", cfg.Port, "env", cfg.Env)
		errCh <- app.Start()
	}()

	sigCh := make(chan os.Signal, 1)
	signal.Notify(sigCh, os.Interrupt, syscall.SIGTERM)

	select {
	case sig := <-sigCh:
		slog.Info("shutdown signal received", "signal", sig.String())
		return app.Shutdown(context.Background())
	case err := <-errCh:
		if err == nil || err == http.ErrServerClosed {
			return nil
		}
		return fmt.Errorf("server failed: %w", err)
	}
}

func configureMiddleware(e *echo.Echo) {
	e.Use(middleware.RequestLoggerWithConfig(middleware.RequestLoggerConfig{
		LogStatus: true,
		LogURI:    true,
		LogValuesFunc: func(c echo.Context, v middleware.RequestLoggerValues) error {
			slog.Info("request",
				"status", v.Status,
				"uri", v.URI,
				"method", c.Request().Method,
			)
			return nil
		},
	}))
	e.Use(middleware.Recover())
	e.Use(middleware.CORS())
}
