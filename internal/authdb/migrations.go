package authdb

import (
	"database/sql"
	"fmt"

	"quiz_master/internal/dbx"
)

func RunMigrations(database *sql.DB) error {
	queries := sqliteMigrations
	if dbx.Driver(database) == dbx.DriverPostgres {
		queries = postgresMigrations
	}

	for _, query := range queries {
		if _, err := database.Exec(query); err != nil {
			return fmt.Errorf("failed to execute migration: %w", err)
		}
	}

	for _, query := range []string{
		"ALTER TABLE users ADD COLUMN role TEXT DEFAULT 'user'",
		"ALTER TABLE users RENAME COLUMN password TO password_hash",
		"ALTER TABLE quiz_results ADD COLUMN quiz_title TEXT",
	} {
		_, _ = database.Exec(query)
	}

	return nil
}

var sqliteMigrations = []string{
	`CREATE TABLE IF NOT EXISTS users (
		id TEXT PRIMARY KEY,
		username TEXT UNIQUE NOT NULL,
		password_hash TEXT NOT NULL,
		role TEXT DEFAULT 'user',
		created_at DATETIME DEFAULT CURRENT_TIMESTAMP
	);`,
	`CREATE TABLE IF NOT EXISTS quiz_results (
		id TEXT PRIMARY KEY,
		user_id TEXT NOT NULL,
		quiz_id TEXT NOT NULL,
		quiz_title TEXT,
		score INTEGER NOT NULL,
		total_questions INTEGER NOT NULL,
		completed_at DATETIME DEFAULT CURRENT_TIMESTAMP,
		FOREIGN KEY(user_id) REFERENCES users(id)
	);`,
	`CREATE TABLE IF NOT EXISTS refresh_tokens (
		token TEXT PRIMARY KEY,
		user_id TEXT NOT NULL,
		expires_at DATETIME NOT NULL,
		created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
		FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
	);`,
}

var postgresMigrations = []string{
	`CREATE TABLE IF NOT EXISTS users (
		id TEXT PRIMARY KEY,
		username TEXT UNIQUE NOT NULL,
		password_hash TEXT NOT NULL,
		role TEXT DEFAULT 'user',
		created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
	);`,
	`CREATE TABLE IF NOT EXISTS quiz_results (
		id TEXT PRIMARY KEY,
		user_id TEXT NOT NULL,
		quiz_id TEXT NOT NULL,
		quiz_title TEXT,
		score INTEGER NOT NULL,
		total_questions INTEGER NOT NULL,
		completed_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
		FOREIGN KEY(user_id) REFERENCES users(id)
	);`,
	`CREATE TABLE IF NOT EXISTS refresh_tokens (
		token TEXT PRIMARY KEY,
		user_id TEXT NOT NULL,
		expires_at TIMESTAMPTZ NOT NULL,
		created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
		FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
	);`,
}
