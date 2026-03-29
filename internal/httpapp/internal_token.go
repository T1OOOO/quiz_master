package httpapp

import (
	"net/http"

	"github.com/labstack/echo/v4"
)

func InternalTokenMiddleware(expectedToken string) echo.MiddlewareFunc {
	return func(next echo.HandlerFunc) echo.HandlerFunc {
		return func(c echo.Context) error {
			if expectedToken == "" {
				return next(c)
			}
			if c.Request().Header.Get("X-Internal-Token") != expectedToken {
				return c.JSON(http.StatusUnauthorized, map[string]string{"error": "invalid internal token"})
			}
			return next(c)
		}
	}
}
