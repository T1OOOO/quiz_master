package api

import (
	authhttp "quiz_master/internal/auth/http"
	"quiz_master/internal/realtime"
	"quiz_master/internal/service"
)

type AuthHandler = authhttp.Handler

func NewAuthHandler(s *service.AuthService) *AuthHandler {
	return authhttp.NewHandler(s, realtime.GlobalHub)
}
