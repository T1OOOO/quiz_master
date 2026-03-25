package http

import (
	"net/http"
	"strings"

	authtoken "quiz_master/internal/auth/token"

	"github.com/golang-jwt/jwt/v5"
	"github.com/labstack/echo/v4"
)

type Middleware struct {
	tokens *authtoken.Manager
}

func NewMiddleware(tokens *authtoken.Manager) *Middleware {
	if tokens == nil {
		tokens = authtoken.NewLegacyManager()
	}
	return &Middleware{tokens: tokens}
}

func (m *Middleware) JWT(next echo.HandlerFunc) echo.HandlerFunc {
	return func(c echo.Context) error {
		authHeader := c.Request().Header.Get("Authorization")
		if authHeader == "" {
			return c.JSON(http.StatusUnauthorized, map[string]string{"error": "Missing authorization token"})
		}

		parts := strings.Split(authHeader, " ")
		if len(parts) != 2 || parts[0] != "Bearer" {
			return c.JSON(http.StatusUnauthorized, map[string]string{"error": "Invalid token format"})
		}

		token, err := m.tokens.Parse(parts[1])
		if err != nil {
			return c.JSON(http.StatusUnauthorized, map[string]string{"error": "Invalid or expired token"})
		}

		c.Set("user", token)
		return next(c)
	}
}

func Admin(next echo.HandlerFunc) echo.HandlerFunc {
	return func(c echo.Context) error {
		u := c.Get("user")
		if u == nil {
			return c.JSON(http.StatusUnauthorized, map[string]string{"error": "Missing authentication"})
		}

		user := u.(*jwt.Token)
		claims := user.Claims.(jwt.MapClaims)
		role, ok := claims["role"].(string)
		if !ok || role != "admin" {
			return c.JSON(http.StatusForbidden, map[string]string{"error": "Admin access required"})
		}

		return next(c)
	}
}
