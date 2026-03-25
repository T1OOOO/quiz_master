package service

import (
	authrepo "quiz_master/internal/auth/repository"
	authservice "quiz_master/internal/auth/service"
	authtoken "quiz_master/internal/auth/token"
)

var SecretKey = authtoken.DefaultSecretKey

type AuthService = authservice.Service

func NewAuthService(repo authrepo.UserRepository) *AuthService {
	return authservice.New(repo, authtoken.NewLegacyManager())
}
