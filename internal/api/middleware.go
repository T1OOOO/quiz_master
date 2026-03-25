package api

import (
	authhttp "quiz_master/internal/auth/http"
	authtoken "quiz_master/internal/auth/token"

	"github.com/labstack/echo/v4"
)

var legacyMiddleware = authhttp.NewMiddleware(authtoken.NewLegacyManager())

func JWTMiddleware(next echo.HandlerFunc) echo.HandlerFunc {
	return legacyMiddleware.JWT(next)
}

func AdminMiddleware(next echo.HandlerFunc) echo.HandlerFunc {
	return authhttp.Admin(next)
}
