package server

import (
	"context"
	"log/slog"
	"os"

	authhttp "quiz_master/internal/auth/http"
	authtoken "quiz_master/internal/auth/token"
	"quiz_master/internal/authclient"
	"quiz_master/internal/config"
	"quiz_master/internal/httpapp"
	quizhttp "quiz_master/internal/quiz/http"
	quizservice "quiz_master/internal/quiz/service"
	"quiz_master/internal/realtime"
	"quiz_master/internal/storageclient"
	"quiz_master/internal/tracing"

	"github.com/labstack/echo/v4"
)

func Build(cfg *config.Config) (*httpapp.App, error) {
	logger := slog.New(slog.NewJSONHandler(os.Stdout, nil))
	slog.SetDefault(logger)

	quizRepo := storageclient.New(cfg.StorageAPIURL, cfg.StorageAPIToken)
	authClient := authclient.New(cfg.AuthAPIURL, cfg.AuthAPIToken)
	tokenManager := authtoken.NewManager(cfg.JWTSecret, cfg.JWTTTL)
	quizSvc := quizservice.New(quizRepo)
	traceShutdown, err := tracing.Init(context.Background(), "quiz-master-server")
	if err != nil {
		return nil, err
	}

	hub := realtime.NewHub(quizRepo)
	go hub.Run()

	authMiddleware := authhttp.NewMiddleware(tokenManager)
	authGateway := newAuthGatewayHandler(authClient, hub)
	quizHandler := quizhttp.NewHandler(quizSvc)

	e := echo.New()
	e.HideBanner = true
	httpapp.ConfigureDefaultMiddleware(e)
	e.Use(httpapp.MetricsMiddleware("server"))
	registerRoutes(e, nil, authMiddleware, authGateway, quizHandler)

	return httpapp.New(
		e,
		tracing.WrapHandler(e, "quiz-master-server"),
		cfg.Port,
		cfg.ShutdownTimeout,
		func() error { return traceShutdown(context.Background()) },
	), nil
}

func Run(cfg *config.Config) error {
	app, err := Build(cfg)
	if err != nil {
		return err
	}

	return httpapp.Run(app, "quiz-master-server", cfg.Port, cfg.Env)
}
