package main

import (
	"log/slog"
	"net/http"
	"os"

	"quiz_master/internal/config"
	"quiz_master/internal/store"
	"quiz_master/internal/service"
	"quiz_master/internal/api"
	"quiz_master/internal/realtime"

	"github.com/gorilla/websocket"
	"github.com/labstack/echo/v4"
	"github.com/labstack/echo/v4/middleware"
)

var upgrader = websocket.Upgrader{
	CheckOrigin: func(r *http.Request) bool { return true },
}

func main() {
	// 1. Init Structured Logger
	logger := slog.New(slog.NewJSONHandler(os.Stdout, nil))
	slog.SetDefault(logger)

	// 2. Load Config
	cfg := config.Load()
	slog.Info("Starting Quiz Master API (Simplified Arch)", "port", cfg.Port, "env", "development")

	// 3. Storage
	if err := store.InitDB(cfg.DBPath); err != nil {
		slog.Error("Failed to init DB", "error", err)
		os.Exit(1)
	}
	defer store.DB.Close()

	// 4. Stores (Repositories)
	quizStore := store.NewQuizStore(store.DB)
	userStore := store.NewUserStore(store.DB)

	// 5. Services
	quizService := service.NewQuizService(quizStore)
	authService := service.NewAuthService(userStore)
	
	// Realtime Hub (injects store into global Manager)
	hub := realtime.NewHub(quizStore)
	// Start hub loop
	go hub.Run()

	// Initial Sync
	if err := quizService.SyncFromFiles("quizzes"); err != nil {
		slog.Warn("failed to sync quizzes from files", "error", err)
	}

	// 6. Handlers
	quizHandler := api.NewQuizHandler(quizService)
	authHandler := api.NewAuthHandler(authService)

	// 7. Echo Setup
	e := echo.New()
	e.HideBanner = true
	
	// Middleware with slog
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

	// API Routes
	apiGroup := e.Group("/api")
	{
		apiGroup.POST("/register", authHandler.Register)
		apiGroup.POST("/login", authHandler.Login)
		apiGroup.POST("/guest", authHandler.GuestLogin)
		apiGroup.GET("/leaderboard", authHandler.GetLeaderboard)

		apiGroup.GET("/quizzes", quizHandler.List)
		apiGroup.GET("/quizzes/:id", quizHandler.Get)
		apiGroup.POST("/quizzes/:id/check", quizHandler.CheckAnswer)
		
		// Protected routes
		apiGroup.POST("/submit", authHandler.SubmitResult, api.JWTMiddleware)
	}

	// Admin API (Protected)
	adminGroup := apiGroup.Group("/admin")
	adminGroup.Use(api.JWTMiddleware)
	adminGroup.Use(api.AdminMiddleware)
	{
		adminGroup.POST("/quizzes", quizHandler.Create)
		adminGroup.PUT("/quizzes/:id", quizHandler.Update)
		adminGroup.DELETE("/quizzes/:id", quizHandler.Delete)
	}

	// WebSocket Transport
	e.GET("/ws", func(c echo.Context) error {
		// Use the handler from realtime package which uses GlobalHub
		return realtime.HandleWebSocket(c)
	})

	// Static Files
	e.Static("/assets", "web/dist/assets")
	
	// SPA Fallback for all non-API routes
	e.GET("/*", func(c echo.Context) error {
		c.Response().Header().Set("Cache-Control", "no-cache, no-store, must-revalidate")
		return c.File("web/dist/index.html")
	})

	// 8. Start Server
	if err := e.Start(":" + cfg.Port); err != nil {
		slog.Error("server shutdown", "error", err)
	}
}
