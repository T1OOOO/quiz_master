package httpapp

import (
	"time"

	"quiz_master/internal/observability"

	"github.com/labstack/echo/v4"
)

func MetricsMiddleware(service string) echo.MiddlewareFunc {
	observability.MarkService(service)
	return func(next echo.HandlerFunc) echo.HandlerFunc {
		return func(c echo.Context) error {
			start := time.Now()
			err := next(c)

			route := c.Path()
			if route == "" {
				route = c.Request().URL.Path
			}

			status := c.Response().Status
			if status == 0 {
				status = 200
			}
			observability.RecordHTTPRequest(service, c.Request().Method, route, status, time.Since(start))
			return err
		}
	}
}
