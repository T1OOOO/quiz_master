package db

import (
	"database/sql"
	"fmt"
)

func RunMigrations(database *sql.DB) error {
	queries := []string{
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
			options TEXT NOT NULL,
			correct_answer_index INTEGER NOT NULL,
			correct_text TEXT,
			correct_multi TEXT,
			type TEXT DEFAULT 'choice',
			image_url TEXT,
			explanation TEXT,
			difficulty INTEGER DEFAULT 0,
			FOREIGN KEY(quiz_id) REFERENCES quizzes(id) ON DELETE CASCADE
		);`,
		`CREATE TABLE IF NOT EXISTS reports (
			id TEXT PRIMARY KEY,
			quiz_id TEXT NOT NULL,
			question_id TEXT NOT NULL,
			message TEXT NOT NULL,
			question_text TEXT,
			created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
			FOREIGN KEY(quiz_id) REFERENCES quizzes(id) ON DELETE CASCADE
		);`,
	}

	for _, query := range queries {
		if _, err := database.Exec(query); err != nil {
			return fmt.Errorf("failed to execute migration: %w", err)
		}
	}

	for _, query := range []string{
		"ALTER TABLE questions ADD COLUMN type TEXT DEFAULT 'choice'",
		"ALTER TABLE questions ADD COLUMN correct_text TEXT",
		"ALTER TABLE questions ADD COLUMN correct_multi TEXT",
		"ALTER TABLE questions ADD COLUMN image_url TEXT",
		"ALTER TABLE questions ADD COLUMN explanation TEXT",
		"ALTER TABLE quizzes ADD COLUMN category TEXT DEFAULT 'Разное'",
		"ALTER TABLE questions ADD COLUMN difficulty INTEGER DEFAULT 0",
	} {
		_, _ = database.Exec(query)
	}

	return nil
}
