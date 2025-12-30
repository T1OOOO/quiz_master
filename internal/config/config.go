package config

import (
	"os"
)

type Config struct {
	Port   string
	DBPath string
}

func Load() *Config {
	return &Config{
		Port:   getEnv("PORT", "8080"),
		DBPath: getEnv("DB_PATH", "quiz.db"),
	}
}

func getEnv(key, fallback string) string {
	if value, ok := os.LookupEnv(key); ok {
		return value
	}
	return fallback
}
