package http

import "github.com/labstack/echo/v4"

func RegisterRoutes(apiGroup *echo.Group, handler *Handler, middleware *Middleware, authRateLimiter echo.MiddlewareFunc) {
	apiGroup.POST("/register", handler.Register, authRateLimiter)
	apiGroup.POST("/login", handler.Login, authRateLimiter)
	apiGroup.POST("/refresh", handler.Refresh, authRateLimiter)
	apiGroup.POST("/guest", handler.GuestLogin, authRateLimiter)
	apiGroup.GET("/leaderboard", handler.GetLeaderboard)
	apiGroup.POST("/submit", handler.SubmitResult, middleware.JWT)
	apiGroup.GET("/quota", handler.GetUserQuota, middleware.JWT)

	adminGroup := apiGroup.Group("/admin")
	adminGroup.Use(middleware.JWT)
	adminGroup.Use(Admin)
	adminGroup.GET("/leaderboard", handler.GetLeaderboard)
}
