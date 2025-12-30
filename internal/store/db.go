package store

import (
	"database/sql"
	"fmt"
	"log"

	_ "modernc.org/sqlite"
)

var DB *sql.DB

func InitDB(filepath string) error {
	var err error
	DB, err = sql.Open("sqlite", filepath)
	if err != nil {
		return fmt.Errorf("failed to open db: %w", err)
	}

	if err := DB.Ping(); err != nil {
		return fmt.Errorf("failed to ping db: %w", err)
	}

	if err := createTables(); err != nil {
		return err
	}
	
	// Migration for existing tables
	migrateUsers()
	
	return nil
}

func createTables() error {
	queries := []string{
		`CREATE TABLE IF NOT EXISTS users (
			id TEXT PRIMARY KEY,
			username TEXT UNIQUE NOT NULL,
			password_hash TEXT NOT NULL,
			role TEXT DEFAULT 'user',
			created_at DATETIME DEFAULT CURRENT_TIMESTAMP
		);`,
		`CREATE TABLE IF NOT EXISTS quizzes (
			id TEXT PRIMARY KEY,
			title TEXT NOT NULL,
			description TEXT,
			category TEXT DEFAULT 'Разное',
			created_at DATETIME DEFAULT CURRENT_TIMESTAMP
		);`,
		`CREATE TABLE IF NOT EXISTS questions (
			id TEXT PRIMARY KEY,
			quiz_id TEXT NOT NULL,
			text TEXT NOT NULL,
			options TEXT NOT NULL, -- JSON array
			correct_answer_index INTEGER NOT NULL,
			correct_text TEXT,
			correct_multi TEXT, -- JSON array
			type TEXT DEFAULT 'choice',
			image_url TEXT,
			explanation TEXT,
			FOREIGN KEY(quiz_id) REFERENCES quizzes(id) ON DELETE CASCADE
		);`,
		`CREATE TABLE IF NOT EXISTS quiz_results (
			id TEXT PRIMARY KEY,
			user_id TEXT NOT NULL,
			quiz_id TEXT NOT NULL,
			score INTEGER NOT NULL,
			total_questions INTEGER NOT NULL,
			completed_at DATETIME DEFAULT CURRENT_TIMESTAMP,
			FOREIGN KEY(user_id) REFERENCES users(id)
		);`,
	}

	for _, query := range queries {
		if _, err := DB.Exec(query); err != nil {
			return fmt.Errorf("failed to execute migration: %w", err)
		}
	}

	log.Println("Database initialized successfully")
	return nil
}

func migrateUsers() {
	// Try to add role column if it doesn't exist (for older DBs)
	_, _ = DB.Exec("ALTER TABLE users ADD COLUMN role TEXT DEFAULT 'user'")
	// Try to add type column if it doesn't exist
	_, _ = DB.Exec("ALTER TABLE questions ADD COLUMN type TEXT DEFAULT 'choice'")
	_, _ = DB.Exec("ALTER TABLE questions ADD COLUMN correct_text TEXT")
	_, _ = DB.Exec("ALTER TABLE questions ADD COLUMN correct_multi TEXT")
	_, _ = DB.Exec("ALTER TABLE questions ADD COLUMN image_url TEXT")
	_, _ = DB.Exec("ALTER TABLE questions ADD COLUMN explanation TEXT")
	
	_, _ = DB.Exec("ALTER TABLE quizzes ADD COLUMN category TEXT DEFAULT 'Разное'")
	
	// Fix for legacy users table (password -> password_hash)
	// SQLite doesn't support IF EXISTS for column rename in older versions easily, 
	// so we try to rename and ignore error if it fails (e.g. if column doesn't exist)
	_, _ = DB.Exec("ALTER TABLE users RENAME COLUMN password TO password_hash")
}
