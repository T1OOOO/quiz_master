package authserver

import (
	"database/sql"
	"net/http"

	authhttp "quiz_master/internal/auth/http"
	"quiz_master/internal/authapi"
	"quiz_master/internal/config"
	"quiz_master/internal/httpapp"
	"quiz_master/internal/observability"

	"github.com/labstack/echo/v4"
)

func registerRoutes(e *echo.Echo, cfg *config.Config, db *sql.DB, authHandler *authhttp.Handler, authMiddleware *authhttp.Middleware, internalHandler *authapi.Handler) {
	e.GET("/healthz", func(c echo.Context) error {
		return c.JSON(http.StatusOK, map[string]string{"status": "ok"})
	})
	e.GET("/readyz", func(c echo.Context) error {
		return c.JSON(http.StatusOK, map[string]string{"status": "ready"})
	})
	e.GET("/metrics", echo.WrapHandler(observability.MetricsHandler("auth", db)))

	apiGroup := e.Group("/api")
	authhttp.RegisterRoutes(apiGroup, authHandler, authMiddleware)

	internalGroup := e.Group("/internal/auth")
	internalGroup.Use(httpapp.InternalTokenMiddleware(cfg.AuthAPIToken))
	internalGroup.POST("/results", internalHandler.SubmitResult)
	internalGroup.GET("/leaderboard", internalHandler.GetLeaderboard)
	internalGroup.GET("/quota/:userID", internalHandler.GetUserQuota)
}
