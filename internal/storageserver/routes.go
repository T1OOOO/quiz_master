package storageserver

import (
	"database/sql"
	"net/http"

	"quiz_master/internal/config"
	"quiz_master/internal/httpapp"
	"quiz_master/internal/observability"
	"quiz_master/internal/storageapi"

	"github.com/labstack/echo/v4"
)

func registerRoutes(e *echo.Echo, cfg *config.Config, db *sql.DB, storageHandler *storageapi.Handler) {
	e.GET("/healthz", func(c echo.Context) error {
		return c.JSON(http.StatusOK, map[string]string{"status": "ok"})
	})
	e.GET("/readyz", func(c echo.Context) error {
		if err := db.Ping(); err != nil {
			return c.JSON(http.StatusServiceUnavailable, map[string]string{
				"status": "not_ready",
				"error":  err.Error(),
			})
		}
		return c.JSON(http.StatusOK, map[string]string{"status": "ready"})
	})
	e.GET("/metrics", echo.WrapHandler(observability.MetricsHandler("storage", db)))

	e.GET("/api/storage/stats", func(c echo.Context) error {
		stats, err := loadStats(db)
		if err != nil {
			return c.JSON(http.StatusInternalServerError, map[string]string{"error": err.Error()})
		}
		return c.JSON(http.StatusOK, stats)
	})

	internalGroup := e.Group("/internal/storage")
	internalGroup.Use(httpapp.InternalTokenMiddleware(cfg.StorageAPIToken))
	internalGroup.GET("/quizzes", storageHandler.List)
	internalGroup.POST("/quizzes", storageHandler.Create)
	internalGroup.GET("/quizzes/:id", storageHandler.Get)
	internalGroup.GET("/quizzes/:id/summary", storageHandler.GetSummary)
	internalGroup.PUT("/quizzes/:id", storageHandler.Update)
	internalGroup.DELETE("/quizzes/:id", storageHandler.Delete)
	internalGroup.GET("/quizzes/:id/questions/:qid", storageHandler.GetQuestion)
	internalGroup.POST("/reports", storageHandler.Report)
	internalGroup.POST("/rooms", storageHandler.CreateRoom)
	internalGroup.GET("/rooms/:code", storageHandler.GetRoom)
	internalGroup.POST("/rooms/:code/join", storageHandler.JoinRoom)
	internalGroup.POST("/rooms/:code/leave", storageHandler.LeaveRoom)
	internalGroup.POST("/rooms/:code/start", storageHandler.StartRoom)
	internalGroup.POST("/rooms/:code/vote", storageHandler.VoteRoom)
	internalGroup.POST("/rooms/:code/chat", storageHandler.ChatRoom)
	internalGroup.GET("/rooms/stream", storageHandler.StreamRoomEvents)
}

func loadStats(db *sql.DB) (map[string]int64, error) {
	tables := []string{"quizzes", "questions", "reports"}
	stats := make(map[string]int64, len(tables))

	for _, table := range tables {
		var count int64
		if err := db.QueryRow("SELECT COUNT(*) FROM " + table).Scan(&count); err != nil {
			return nil, err
		}
		stats[table] = count
	}

	return stats, nil
}
