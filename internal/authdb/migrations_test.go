package authdb

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
	if count != len(authMigrations()) {
		t.Fatalf("expected %d migrations, got %d", len(authMigrations()), count)
	}
}

func TestRunMigrationsUpgradesLegacySchema(t *testing.T) {
	database, err := sql.Open("sqlite", ":memory:")
	if err != nil {
		t.Fatalf("open sqlite db: %v", err)
	}
	defer database.Close()

	if _, err := database.Exec(`
CREATE TABLE users (
	id TEXT PRIMARY KEY,
	username TEXT UNIQUE NOT NULL,
	password TEXT NOT NULL,
	created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE quiz_results (
	id TEXT PRIMARY KEY,
	user_id TEXT NOT NULL,
	quiz_id TEXT NOT NULL,
	score INTEGER NOT NULL,
	total_questions INTEGER NOT NULL,
	completed_at DATETIME DEFAULT CURRENT_TIMESTAMP,
	FOREIGN KEY(user_id) REFERENCES users(id)
);
CREATE TABLE refresh_tokens (
	token TEXT PRIMARY KEY,
	user_id TEXT NOT NULL,
	expires_at DATETIME NOT NULL,
	created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
	FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
);`); err != nil {
		t.Fatalf("create legacy schema: %v", err)
	}

	if err := RunMigrations(database); err != nil {
		t.Fatalf("run migrations: %v", err)
	}

	for _, column := range []string{"password_hash", "role"} {
		exists, err := sqliteColumnExists(database, "users", column)
		if err != nil {
			t.Fatalf("check users.%s: %v", column, err)
		}
		if !exists {
			t.Fatalf("expected users.%s to exist", column)
		}
	}

	exists, err := sqliteColumnExists(database, "quiz_results", "quiz_title")
	if err != nil {
		t.Fatalf("check quiz_results.quiz_title: %v", err)
	}
	if !exists {
		t.Fatal("expected quiz_results.quiz_title to exist")
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
