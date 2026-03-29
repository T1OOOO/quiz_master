package api

import (
	authhttp "quiz_master/internal/auth/http"
	authservice "quiz_master/internal/auth/service"
	"quiz_master/internal/realtime"
)

type AuthHandler = authhttp.Handler

func NewAuthHandler(s *authservice.Service) *AuthHandler {
	return authhttp.NewHandler(s, realtime.GlobalHub)
}
