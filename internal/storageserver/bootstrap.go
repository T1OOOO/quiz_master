package storageserver

import (
	"context"
	"errors"
	"log/slog"
	"os"

	"quiz_master/internal/config"
	"quiz_master/internal/httpapp"
	quizservice "quiz_master/internal/quiz/service"
	"quiz_master/internal/roomstate"
	storagedb "quiz_master/internal/storage/db"
	storagerepo "quiz_master/internal/storage/repository"
	"quiz_master/internal/storageapi"
	"quiz_master/internal/tracing"

	"github.com/labstack/echo/v4"
)

func Build(cfg *config.Config) (*httpapp.App, error) {
	logger := slog.New(slog.NewJSONHandler(os.Stdout, nil))
	slog.SetDefault(logger)
	if err := cfg.Validate(); err != nil {
		return nil, err
	}
	if cfg.Env == "production" && cfg.DBDriver == "sqlite" {
		slog.Warn("storage is running in limited production mode with sqlite", "db_driver", cfg.DBDriver)
	}

	dbConn, err := storagedb.Open(context.Background(), storagedb.Config{
		Driver:       cfg.DBDriver,
		DSN:          cfg.DBDSN,
		Path:         cfg.DBPath,
		MaxOpenConns: cfg.DBMaxOpenConns,
		MaxIdleConns: cfg.DBMaxIdleConns,
		ConnMaxIdle:  cfg.DBConnMaxIdle,
	})
	if err != nil {
		return nil, err
	}

	quizRepo := storagerepo.NewQuizRepository(dbConn)
	roomRepo := storagerepo.NewRoomStateRepository(dbConn)
	quizSvc := quizservice.New(quizRepo)
	roomSvc := roomstate.New(roomRepo)
	if err := quizSvc.SyncFromFiles(cfg.QuizzesDir, quizservice.SyncOptions{}); err != nil {
		slog.Warn("failed to sync quizzes from files", "error", err)
	}
	storageHandler := storageapi.NewHandler(quizSvc, roomSvc)
	traceShutdown, err := tracing.Init(context.Background(), "quiz-master-storage")
	if err != nil {
		_ = dbConn.Close()
		return nil, err
	}

	e := echo.New()
	e.HideBanner = true
	httpapp.ConfigureDefaultMiddleware(e, cfg)
	e.Use(httpapp.MetricsMiddleware("storage"))
	registerRoutes(e, cfg, dbConn, storageHandler)

	return httpapp.New(
		e,
		tracing.WrapHandler(e, "quiz-master-storage"),
		cfg.Port,
		cfg.ShutdownTimeout,
		func() error {
			return errors.Join(traceShutdown(context.Background()), dbConn.Close())
		},
	), nil
}

func Run(cfg *config.Config) error {
	app, err := Build(cfg)
	if err != nil {
		return err
	}

	return httpapp.Run(app, "quiz-master-storage", cfg.Port, cfg.Env)
}
