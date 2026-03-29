package config

import "testing"

func TestValidateRejectsWeakProductionSecrets(t *testing.T) {
	cfg := &Config{
		Env:                "production",
		JWTSecret:          "change-me",
		AuthAPIToken:       "dev-auth-token",
		StorageAPIToken:    "dev-storage-token",
		CORSAllowedOrigins: []string{"https://app.example.com"},
		WSAllowedOrigins:   []string{"https://app.example.com"},
		AuthRateLimitRPS:   5,
		AuthRateLimitBurst: 10,
	}

	if err := cfg.Validate(); err == nil {
		t.Fatalf("expected weak production secrets to fail validation")
	}
}

func TestValidateAcceptsProductionSecurityConfig(t *testing.T) {
	cfg := &Config{
		Env:                "production",
		JWTSecret:          "super-secret-jwt-key",
		AuthAPIToken:       "super-secret-auth-token",
		StorageAPIToken:    "super-secret-storage-token",
		CORSAllowedOrigins: []string{"https://app.example.com"},
		WSAllowedOrigins:   []string{"https://app.example.com"},
		AuthRateLimitRPS:   5,
		AuthRateLimitBurst: 10,
	}

	if err := cfg.Validate(); err != nil {
		t.Fatalf("expected config to validate: %v", err)
	}
}
