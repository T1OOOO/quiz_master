package http

import "github.com/labstack/echo/v4"

func RegisterRoutes(apiGroup *echo.Group, handler *Handler, middleware *Middleware) {
	apiGroup.POST("/register", handler.Register)
	apiGroup.POST("/login", handler.Login)
	apiGroup.POST("/guest", handler.GuestLogin)
	apiGroup.GET("/leaderboard", handler.GetLeaderboard)
	apiGroup.POST("/submit", handler.SubmitResult, middleware.JWT)

	adminGroup := apiGroup.Group("/admin")
	adminGroup.Use(middleware.JWT)
	adminGroup.Use(Admin)
}
