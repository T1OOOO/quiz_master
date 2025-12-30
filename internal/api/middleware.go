package api

import (
	"net/http"
	"strings"

	"quiz_master/internal/service"

	"github.com/golang-jwt/jwt/v5"
	"github.com/labstack/echo/v4"
)

// JWTMiddleware validates the bearer token and sets the user in context
func JWTMiddleware(next echo.HandlerFunc) echo.HandlerFunc {
	return func(c echo.Context) error {
		authHeader := c.Request().Header.Get("Authorization")
		if authHeader == "" {
			return c.JSON(http.StatusUnauthorized, map[string]string{"error": "Missing authorization token"})
		}

		parts := strings.Split(authHeader, " ")
		if len(parts) != 2 || parts[0] != "Bearer" {
			return c.JSON(http.StatusUnauthorized, map[string]string{"error": "Invalid token format"})
		}

		tokenString := parts[1]
		token, err := jwt.Parse(tokenString, func(token *jwt.Token) (interface{}, error) {
			if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
				return nil, echo.NewHTTPError(http.StatusUnauthorized, "Unexpected signing method")
			}
			return service.SecretKey, nil
		})

		if err != nil || !token.Valid {
			return c.JSON(http.StatusUnauthorized, map[string]string{"error": "Invalid or expired token"})
		}

		c.Set("user", token)
		return next(c)
	}
}

func AdminMiddleware(next echo.HandlerFunc) echo.HandlerFunc {
	return func(c echo.Context) error {
		// Ensure user is in context (JWTMiddleware must run before this)
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
