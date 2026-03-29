package db

import (
	"database/sql"
	"fmt"

	"quiz_master/internal/dbx"
)

type migration struct {
	version int
	name    string
	up      func(*sql.Tx, string) error
}

func RunMigrations(database *sql.DB) error {
	driver := dbx.Driver(database)
	if err := ensureMigrationLedger(database, driver); err != nil {
		return err
	}

	applied, err := loadAppliedMigrations(database)
	if err != nil {
		return err
	}

	for _, item := range storageMigrations() {
		if applied[item.version] {
			continue
		}

		tx, err := database.Begin()
		if err != nil {
			return fmt.Errorf("begin migration %d: %w", item.version, err)
		}

		if err := item.up(tx, driver); err != nil {
			_ = tx.Rollback()
			return fmt.Errorf("run migration %d (%s): %w", item.version, item.name, err)
		}

		if _, err := tx.Exec(dbx.Rebind(database,
			"INSERT INTO schema_migrations (version, name) VALUES (?, ?)"),
			item.version, item.name,
		); err != nil {
			_ = tx.Rollback()
			return fmt.Errorf("record migration %d: %w", item.version, err)
		}

		if err := tx.Commit(); err != nil {
			return fmt.Errorf("commit migration %d: %w", item.version, err)
		}
	}

	return nil
}

func storageMigrations() []migration {
	return []migration{
		{
			version: 1,
			name:    "create_quizzes",
			up: func(tx *sql.Tx, driver string) error {
				return execDDL(tx, `
CREATE TABLE IF NOT EXISTS quizzes (
	id TEXT PRIMARY KEY,
	title TEXT NOT NULL,
	description TEXT,
	category TEXT DEFAULT 'Разное',
	created_at %s DEFAULT CURRENT_TIMESTAMP
);`, timestampType(driver))
			},
		},
		{
			version: 2,
			name:    "create_questions",
			up: func(tx *sql.Tx, driver string) error {
				return execDDL(tx, `
CREATE TABLE IF NOT EXISTS questions (
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
);`)
			},
		},
		{
			version: 3,
			name:    "create_reports",
			up: func(tx *sql.Tx, driver string) error {
				return execDDL(tx, `
CREATE TABLE IF NOT EXISTS reports (
	id TEXT PRIMARY KEY,
	quiz_id TEXT NOT NULL,
	question_id TEXT NOT NULL,
	message TEXT NOT NULL,
	question_text TEXT,
	created_at %s DEFAULT CURRENT_TIMESTAMP,
	FOREIGN KEY(quiz_id) REFERENCES quizzes(id) ON DELETE CASCADE
);`, timestampType(driver))
			},
		},
		{
			version: 4,
			name:    "questions_add_type",
			up: func(tx *sql.Tx, driver string) error {
				return ensureColumn(tx, driver, "questions", "type", "TEXT DEFAULT 'choice'")
			},
		},
		{
			version: 5,
			name:    "questions_add_correct_text",
			up: func(tx *sql.Tx, driver string) error {
				return ensureColumn(tx, driver, "questions", "correct_text", "TEXT")
			},
		},
		{
			version: 6,
			name:    "questions_add_correct_multi",
			up: func(tx *sql.Tx, driver string) error {
				return ensureColumn(tx, driver, "questions", "correct_multi", "TEXT")
			},
		},
		{
			version: 7,
			name:    "questions_add_image_url",
			up: func(tx *sql.Tx, driver string) error {
				return ensureColumn(tx, driver, "questions", "image_url", "TEXT")
			},
		},
		{
			version: 8,
			name:    "questions_add_explanation",
			up: func(tx *sql.Tx, driver string) error {
				return ensureColumn(tx, driver, "questions", "explanation", "TEXT")
			},
		},
		{
			version: 9,
			name:    "quizzes_add_category",
			up: func(tx *sql.Tx, driver string) error {
				return ensureColumn(tx, driver, "quizzes", "category", "TEXT DEFAULT 'Разное'")
			},
		},
		{
			version: 10,
			name:    "questions_add_difficulty",
			up: func(tx *sql.Tx, driver string) error {
				return ensureColumn(tx, driver, "questions", "difficulty", "INTEGER DEFAULT 0")
			},
		},
	}
}

func ensureMigrationLedger(database *sql.DB, driver string) error {
	query := `
CREATE TABLE IF NOT EXISTS schema_migrations (
	version INTEGER PRIMARY KEY,
	name TEXT NOT NULL,
	applied_at %s DEFAULT CURRENT_TIMESTAMP
);`
	_, err := database.Exec(fmt.Sprintf(query, timestampType(driver)))
	if err != nil {
		return fmt.Errorf("create schema_migrations: %w", err)
	}
	return nil
}

func loadAppliedMigrations(database *sql.DB) (map[int]bool, error) {
	rows, err := database.Query(`SELECT version FROM schema_migrations`)
	if err != nil {
		return nil, fmt.Errorf("query schema_migrations: %w", err)
	}
	defer rows.Close()

	out := make(map[int]bool)
	for rows.Next() {
		var version int
		if err := rows.Scan(&version); err != nil {
			return nil, fmt.Errorf("scan schema_migrations: %w", err)
		}
		out[version] = true
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("iterate schema_migrations: %w", err)
	}
	return out, nil
}

func ensureColumn(tx *sql.Tx, driver, table, column, definition string) error {
	exists, err := columnExists(tx, driver, table, column)
	if err != nil {
		return err
	}
	if exists {
		return nil
	}

	query := fmt.Sprintf("ALTER TABLE %s ADD COLUMN %s %s", table, column, definition)
	if _, err := tx.Exec(query); err != nil {
		return fmt.Errorf("add column %s.%s: %w", table, column, err)
	}
	return nil
}

func columnExists(tx *sql.Tx, driver, table, column string) (bool, error) {
	switch driver {
	case dbx.DriverPostgres:
		var exists bool
		err := tx.QueryRow(`
SELECT EXISTS (
	SELECT 1
	FROM information_schema.columns
	WHERE table_schema = current_schema()
	  AND table_name = $1
	  AND column_name = $2
)`, table, column).Scan(&exists)
		if err != nil {
			return false, fmt.Errorf("check postgres column %s.%s: %w", table, column, err)
		}
		return exists, nil
	default:
		rows, err := tx.Query(fmt.Sprintf("PRAGMA table_info(%s)", table))
		if err != nil {
			return false, fmt.Errorf("check sqlite column %s.%s: %w", table, column, err)
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
				return false, fmt.Errorf("scan sqlite table_info for %s: %w", table, err)
			}
			if name == column {
				return true, nil
			}
		}
		if err := rows.Err(); err != nil {
			return false, fmt.Errorf("iterate sqlite table_info for %s: %w", table, err)
		}
		return false, nil
	}
}

func execDDL(tx *sql.Tx, query string, args ...any) error {
	_, err := tx.Exec(fmt.Sprintf(query, args...))
	if err != nil {
		return err
	}
	return nil
}

func timestampType(driver string) string {
	if driver == dbx.DriverPostgres {
		return "TIMESTAMPTZ"
	}
	return "DATETIME"
}
