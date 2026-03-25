package config

import (
	"os"
	"strconv"
	"time"
)

type Config struct {
	Port            string
	DBPath          string
	Env             string
	QuizzesDir      string
	JWTSecret       string
	JWTTTL          time.Duration
	ShutdownTimeout time.Duration
	DBMaxOpenConns  int
	DBMaxIdleConns  int
	DBConnMaxIdle   time.Duration
}

func Load() *Config {
	return &Config{
		Port:            getEnv("PORT", "8080"),
		DBPath:          getEnv("DB_PATH", "quiz.db"),
		Env:             getEnv("ENV", "development"),
		QuizzesDir:      getEnv("QUIZZES_DIR", "quizzes"),
		JWTSecret:       getEnv("JWT_SECRET", "your-secret-key-change-this-in-prod"),
		JWTTTL:          getEnvDuration("JWT_TTL", 24*time.Hour),
		ShutdownTimeout: getEnvDuration("SHUTDOWN_TIMEOUT", 10*time.Second),
		DBMaxOpenConns:  getEnvInt("DB_MAX_OPEN_CONNS", 1),
		DBMaxIdleConns:  getEnvInt("DB_MAX_IDLE_CONNS", 1),
		DBConnMaxIdle:   getEnvDuration("DB_CONN_MAX_IDLE", 5*time.Minute),
	}
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
