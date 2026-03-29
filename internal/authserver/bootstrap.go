package authserver

import (
	"context"
	"errors"
	"log/slog"
	"os"

	authhttp "quiz_master/internal/auth/http"
	authservice "quiz_master/internal/auth/service"
	authtoken "quiz_master/internal/auth/token"
	"quiz_master/internal/authapi"
	"quiz_master/internal/authdb"
	"quiz_master/internal/config"
	"quiz_master/internal/httpapp"
	storagerepo "quiz_master/internal/storage/repository"
	"quiz_master/internal/storageclient"
	"quiz_master/internal/tracing"

	"github.com/labstack/echo/v4"
)

func Build(cfg *config.Config) (*httpapp.App, error) {
	logger := slog.New(slog.NewJSONHandler(os.Stdout, nil))
	slog.SetDefault(logger)

	dbConn, err := authdb.Open(context.Background(), authdb.Config{
		Path:         cfg.DBPath,
		MaxOpenConns: cfg.DBMaxOpenConns,
		MaxIdleConns: cfg.DBMaxIdleConns,
		ConnMaxIdle:  cfg.DBConnMaxIdle,
	})
	if err != nil {
		return nil, err
	}

	userRepo := storagerepo.NewUserRepository(dbConn)
	tokenManager := authtoken.NewManager(cfg.JWTSecret, cfg.JWTTTL)
	quizTitles := storageclient.NewForService("auth", cfg.StorageAPIURL, cfg.StorageAPIToken)
	authSvc := authservice.New(userRepo, tokenManager, quizTitles)
	authHandler := authhttp.NewHandler(authSvc, nil)
	internalHandler := authapi.NewHandler(authSvc)
	authMiddleware := authhttp.NewMiddleware(tokenManager)
	traceShutdown, err := tracing.Init(context.Background(), "quiz-master-auth")
	if err != nil {
		_ = dbConn.Close()
		return nil, err
	}

	e := echo.New()
	e.HideBanner = true
	httpapp.ConfigureDefaultMiddleware(e)
	e.Use(httpapp.MetricsMiddleware("auth"))
	registerRoutes(e, cfg, dbConn, authHandler, authMiddleware, internalHandler)

	return httpapp.New(
		e,
		tracing.WrapHandler(e, "quiz-master-auth"),
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

	return httpapp.Run(app, "quiz-master-auth", cfg.Port, cfg.Env)
}
