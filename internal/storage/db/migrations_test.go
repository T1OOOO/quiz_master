package db

import (
	"context"
	"database/sql"
	"testing"
	"time"
)

func TestRunMigrationsIsIdempotent(t *testing.T) {
	database, err := Open(context.Background(), Config{
		Driver:       "sqlite",
		Path:         ":memory:",
		MaxOpenConns: 1,
		MaxIdleConns: 1,
		ConnMaxIdle:  time.Minute,
	})
	if err != nil {
		t.Fatalf("open db: %v", err)
	}
	defer database.Close()

	if err := RunMigrations(database); err != nil {
		t.Fatalf("rerun migrations: %v", err)
	}

	var count int
	if err := database.QueryRow(`SELECT COUNT(*) FROM schema_migrations`).Scan(&count); err != nil {
		t.Fatalf("count schema migrations: %v", err)
	}
	if count != len(storageMigrations()) {
		t.Fatalf("expected %d migrations, got %d", len(storageMigrations()), count)
	}

	if _, err := database.Query(`SELECT code, state_json, version FROM rooms_state`); err != nil {
		t.Fatalf("rooms_state table should exist: %v", err)
	}
}

func TestRunMigrationsUpgradesLegacySchema(t *testing.T) {
	database, err := sql.Open("sqlite", ":memory:")
	if err != nil {
		t.Fatalf("open sqlite db: %v", err)
	}
	defer database.Close()

	if _, err := database.Exec(`
CREATE TABLE quizzes (
	id TEXT PRIMARY KEY,
	title TEXT NOT NULL,
	description TEXT,
	created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE questions (
	id TEXT PRIMARY KEY,
	quiz_id TEXT NOT NULL,
	text TEXT NOT NULL,
	options TEXT NOT NULL,
	correct_answer_index INTEGER NOT NULL,
	FOREIGN KEY(quiz_id) REFERENCES quizzes(id) ON DELETE CASCADE
);
CREATE TABLE reports (
	id TEXT PRIMARY KEY,
	quiz_id TEXT NOT NULL,
	question_id TEXT NOT NULL,
	message TEXT NOT NULL,
	question_text TEXT,
	created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
	FOREIGN KEY(quiz_id) REFERENCES quizzes(id) ON DELETE CASCADE
);`); err != nil {
		t.Fatalf("create legacy schema: %v", err)
	}

	if err := RunMigrations(database); err != nil {
		t.Fatalf("run migrations: %v", err)
	}

	for _, column := range []string{"type", "correct_text", "correct_multi", "image_url", "explanation", "difficulty"} {
		exists, err := sqliteColumnExists(database, "questions", column)
		if err != nil {
			t.Fatalf("check questions.%s: %v", column, err)
		}
		if !exists {
			t.Fatalf("expected questions.%s to exist", column)
		}
	}

	exists, err := sqliteColumnExists(database, "quizzes", "category")
	if err != nil {
		t.Fatalf("check quizzes.category: %v", err)
	}
	if !exists {
		t.Fatal("expected quizzes.category to exist")
	}
}

func sqliteColumnExists(database *sql.DB, table, column string) (bool, error) {
	rows, err := database.Query("PRAGMA table_info(" + table + ")")
	if err != nil {
		return false, err
	}
	defer rows.Close()

	for rows.Next() {
		var (
			cid      int
			name     string
			dataType string
			notNull  int
			defaultV sql.NullString
			pk       int
		)
		if err := rows.Scan(&cid, &name, &dataType, &notNull, &defaultV, &pk); err != nil {
			return false, err
		}
		if name == column {
			return true, nil
		}
	}

	return false, rows.Err()
}
