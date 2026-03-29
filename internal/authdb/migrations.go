package authdb

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

	for _, item := range authMigrations() {
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

func authMigrations() []migration {
	return []migration{
		{
			version: 1,
			name:    "create_users",
			up: func(tx *sql.Tx, driver string) error {
				return execDDL(tx, `
CREATE TABLE IF NOT EXISTS users (
	id TEXT PRIMARY KEY,
	username TEXT UNIQUE NOT NULL,
	password_hash TEXT NOT NULL,
	role TEXT DEFAULT 'user',
	created_at %s DEFAULT CURRENT_TIMESTAMP
);`, timestampType(driver))
			},
		},
		{
			version: 2,
			name:    "create_quiz_results",
			up: func(tx *sql.Tx, driver string) error {
				return execDDL(tx, `
CREATE TABLE IF NOT EXISTS quiz_results (
	id TEXT PRIMARY KEY,
	user_id TEXT NOT NULL,
	quiz_id TEXT NOT NULL,
	quiz_title TEXT,
	score INTEGER NOT NULL,
	total_questions INTEGER NOT NULL,
	completed_at %s DEFAULT CURRENT_TIMESTAMP,
	FOREIGN KEY(user_id) REFERENCES users(id)
);`, timestampType(driver))
			},
		},
		{
			version: 3,
			name:    "create_refresh_tokens",
			up: func(tx *sql.Tx, driver string) error {
				ts := timestampType(driver)
				return execDDL(tx, `
CREATE TABLE IF NOT EXISTS refresh_tokens (
	token TEXT PRIMARY KEY,
	user_id TEXT NOT NULL,
	expires_at %s NOT NULL,
	created_at %s DEFAULT CURRENT_TIMESTAMP,
	FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
);`, ts, ts)
			},
		},
		{
			version: 4,
			name:    "users_add_role",
			up: func(tx *sql.Tx, driver string) error {
				return ensureColumn(tx, driver, "users", "role", "TEXT DEFAULT 'user'")
			},
		},
		{
			version: 5,
			name:    "users_rename_password_hash",
			up: func(tx *sql.Tx, driver string) error {
				return ensurePasswordHashColumn(tx, driver)
			},
		},
		{
			version: 6,
			name:    "quiz_results_add_quiz_title",
			up: func(tx *sql.Tx, driver string) error {
				return ensureColumn(tx, driver, "quiz_results", "quiz_title", "TEXT")
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

func ensurePasswordHashColumn(tx *sql.Tx, driver string) error {
	hasPasswordHash, err := columnExists(tx, driver, "users", "password_hash")
	if err != nil {
		return err
	}
	if hasPasswordHash {
		return nil
	}

	hasPassword, err := columnExists(tx, driver, "users", "password")
	if err != nil {
		return err
	}
	if !hasPassword {
		return nil
	}

	if _, err := tx.Exec(`ALTER TABLE users RENAME COLUMN password TO password_hash`); err != nil {
		return fmt.Errorf("rename users.password to password_hash: %w", err)
	}
	return nil
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
	formatted := fmt.Sprintf(query, args...)
	_, err := tx.Exec(formatted)
	return err
}

func timestampType(driver string) string {
	if driver == dbx.DriverPostgres {
		return "TIMESTAMPTZ"
	}
	return "DATETIME"
}
