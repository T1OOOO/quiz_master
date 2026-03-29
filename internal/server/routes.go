package server

import (
	"database/sql"
	"net/http"

	authhttp "quiz_master/internal/auth/http"
	"quiz_master/internal/observability"
	quizhttp "quiz_master/internal/quiz/http"
	"quiz_master/internal/realtime"

	"github.com/labstack/echo/v4"
)

func registerRoutes(e *echo.Echo, db *sql.DB, authMiddleware *authhttp.Middleware, authHandler *authGatewayHandler, quizHandler *quizhttp.Handler) {
	e.GET("/healthz", func(c echo.Context) error {
		return c.JSON(http.StatusOK, map[string]string{"status": "ok"})
	})
	e.GET("/readyz", func(c echo.Context) error {
		return c.JSON(http.StatusOK, map[string]string{"status": "ready"})
	})
	e.GET("/metrics", echo.WrapHandler(observability.MetricsHandler("server", db)))

	apiGroup := e.Group("/api")
	apiGroup.POST("/register", authHandler.Register)
	apiGroup.POST("/login", authHandler.Login)
	apiGroup.POST("/refresh", authHandler.Refresh)
	apiGroup.POST("/guest", authHandler.GuestLogin)
	apiGroup.GET("/leaderboard", authHandler.GetLeaderboard)
	apiGroup.POST("/submit", authHandler.SubmitResult, authMiddleware.JWT)
	apiGroup.GET("/quota", authHandler.GetUserQuota, authMiddleware.JWT)
	apiGroup.GET("/quizzes", quizHandler.List)
	apiGroup.GET("/quizzes/:id", quizHandler.Get)
	apiGroup.GET("/quizzes/:id/questions/:qid", quizHandler.GetQuestion)
	apiGroup.POST("/quizzes/:id/check", quizHandler.CheckAnswer)
	apiGroup.POST("/report", quizHandler.Report)

	adminGroup := apiGroup.Group("/admin")
	adminGroup.Use(authMiddleware.JWT)
	adminGroup.Use(authhttp.Admin)
	adminGroup.GET("/leaderboard", authHandler.GetLeaderboard)
	adminGroup.GET("/quizzes", quizHandler.List)
	adminGroup.POST("/quizzes", quizHandler.Create)
	adminGroup.PUT("/quizzes/:id", quizHandler.Update)
	adminGroup.DELETE("/quizzes/:id", quizHandler.Delete)

	e.GET("/ws", realtime.HandleWebSocket)
	e.Static("/assets", "web/dist/assets")
	e.Static("/_expo", "web/dist/_expo")
	e.GET("/*", func(c echo.Context) error {
		c.Response().Header().Set("Cache-Control", "no-cache, no-store, must-revalidate")
		return c.File("web/dist/index.html")
	})
}
