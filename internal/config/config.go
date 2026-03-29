package config

import (
	"fmt"
	"os"
	"strconv"
	"strings"
	"time"
)

type Config struct {
	Port               string
	DBDriver           string
	DBDSN              string
	DBPath             string
	Env                string
	QuizzesDir         string
	JWTSecret          string
	AuthAPIURL         string
	AuthAPIToken       string
	StorageAPIURL      string
	StorageAPIToken    string
	CORSAllowedOrigins []string
	WSAllowedOrigins   []string
	JWTTTL             time.Duration
	ShutdownTimeout    time.Duration
	DBMaxOpenConns     int
	DBMaxIdleConns     int
	DBConnMaxIdle      time.Duration
	AuthRateLimitRPS   float64
	AuthRateLimitBurst int
}

func Load() *Config {
	corsOrigins := getEnvCSV("CORS_ALLOWED_ORIGINS", []string{
		"http://localhost:8090",
		"http://127.0.0.1:8090",
		"http://localhost:8091",
		"http://127.0.0.1:8091",
	})
	wsOrigins := getEnvCSV("WS_ALLOWED_ORIGINS", corsOrigins)
	return &Config{
		Port:               getEnv("PORT", "8090"),
		DBDriver:           getEnv("DB_DRIVER", "sqlite"),
		DBDSN:              getEnv("DB_DSN", ""),
		DBPath:             getEnv("DB_PATH", "quiz.db"),
		Env:                getEnv("ENV", "development"),
		QuizzesDir:         getEnv("QUIZZES_DIR", "quizzes"),
		JWTSecret:          getEnv("JWT_SECRET", "your-secret-key-change-this-in-prod"),
		AuthAPIURL:         getEnv("AUTH_API_URL", "http://localhost:8092"),
		AuthAPIToken:       getEnv("AUTH_API_TOKEN", "dev-auth-token"),
		StorageAPIURL:      getEnv("STORAGE_API_URL", "http://localhost:8093"),
		StorageAPIToken:    getEnv("STORAGE_API_TOKEN", "dev-storage-token"),
		CORSAllowedOrigins: corsOrigins,
		WSAllowedOrigins:   wsOrigins,
		JWTTTL:             getEnvDuration("JWT_TTL", 24*time.Hour),
		ShutdownTimeout:    getEnvDuration("SHUTDOWN_TIMEOUT", 10*time.Second),
		DBMaxOpenConns:     getEnvInt("DB_MAX_OPEN_CONNS", 1),
		DBMaxIdleConns:     getEnvInt("DB_MAX_IDLE_CONNS", 1),
		DBConnMaxIdle:      getEnvDuration("DB_CONN_MAX_IDLE", 5*time.Minute),
		AuthRateLimitRPS:   getEnvFloat("AUTH_RATE_LIMIT_RPS", 5),
		AuthRateLimitBurst: getEnvInt("AUTH_RATE_LIMIT_BURST", 10),
	}
}

func (c *Config) Validate() error {
	if c == nil {
		return fmt.Errorf("config is nil")
	}
	if c.AuthRateLimitRPS <= 0 {
		return fmt.Errorf("AUTH_RATE_LIMIT_RPS must be > 0")
	}
	if c.AuthRateLimitBurst <= 0 {
		return fmt.Errorf("AUTH_RATE_LIMIT_BURST must be > 0")
	}
	if strings.EqualFold(c.DBDriver, "postgres") && strings.TrimSpace(c.DBDSN) == "" {
		return fmt.Errorf("DB_DSN must be set when DB_DRIVER=postgres")
	}

	if strings.EqualFold(c.Env, "production") {
		for key, value := range map[string]string{
			"JWT_SECRET":        c.JWTSecret,
			"AUTH_API_TOKEN":    c.AuthAPIToken,
			"STORAGE_API_TOKEN": c.StorageAPIToken,
		} {
			if isWeakSecret(value) {
				return fmt.Errorf("%s must be explicitly configured for production", key)
			}
		}
		if len(c.CORSAllowedOrigins) == 0 {
			return fmt.Errorf("CORS_ALLOWED_ORIGINS must be set for production")
		}
		if len(c.WSAllowedOrigins) == 0 {
			return fmt.Errorf("WS_ALLOWED_ORIGINS must be set for production")
		}
	}

	return nil
}

func getEnv(key, fallback string) string {
	if value, ok := os.LookupEnv(key); ok {
		return value
	}
	return fallback
}

func getEnvInt(key string, fallback int) int {
	value := os.Getenv(key)
	if value == "" {
		return fallback
	}

	parsed, err := strconv.Atoi(value)
	if err != nil {
		return fallback
	}
	return parsed
}

func getEnvFloat(key string, fallback float64) float64 {
	value := os.Getenv(key)
	if value == "" {
		return fallback
	}

	parsed, err := strconv.ParseFloat(value, 64)
	if err != nil {
		return fallback
	}
	return parsed
}

func getEnvCSV(key string, fallback []string) []string {
	value := os.Getenv(key)
	if value == "" {
		return append([]string(nil), fallback...)
	}

	parts := strings.Split(value, ",")
	out := make([]string, 0, len(parts))
	for _, part := range parts {
		part = strings.TrimSpace(part)
		if part != "" {
			out = append(out, part)
		}
	}
	return out
}

func isWeakSecret(value string) bool {
	switch strings.TrimSpace(value) {
	case "", "change-me", "dev-auth-token", "dev-storage-token", "your-secret-key-change-this-in-prod":
		return true
	default:
		return false
	}
}

func getEnvDuration(key string, fallback time.Duration) time.Duration {
	value := os.Getenv(key)
	if value == "" {
		return fallback
	}

	parsed, err := time.ParseDuration(value)
	if err != nil {
		return fallback
	}
	return parsed
}
