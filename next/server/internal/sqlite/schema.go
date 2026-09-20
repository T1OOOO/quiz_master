// Package sqlite provides the deliberately local persistence primitive used by
// the rewrite API. PostgreSQL remains the production backend.
package sqlite

import (
	"context"
	"database/sql"
	"fmt"
)

const schema = `
CREATE TABLE IF NOT EXISTS participants (
 id TEXT PRIMARY KEY CHECK (id GLOB 'p_[0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]'),
 kind TEXT NOT NULL CHECK (kind IN ('guest','account')),
 display_name TEXT NOT NULL CHECK (length(display_name) BETWEEN 1 AND 100),
 created_at TEXT NOT NULL,
 updated_at TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS sessions (
 token_digest TEXT PRIMARY KEY CHECK (length(token_digest)=64),
 participant_id TEXT NOT NULL REFERENCES participants(id),
 created_at TEXT NOT NULL,
 expires_at TEXT NOT NULL,
 revoked_at TEXT
);
CREATE INDEX IF NOT EXISTS sessions_active_lookup ON sessions(token_digest, expires_at) WHERE revoked_at IS NULL;
CREATE TABLE IF NOT EXISTS attempt_bundles (bundle_sha256 TEXT NOT NULL, bundle_version TEXT NOT NULL, controlled_bundle TEXT NOT NULL, manifest TEXT NOT NULL, PRIMARY KEY(bundle_sha256,bundle_version));
CREATE TABLE IF NOT EXISTS attempts (id TEXT PRIMARY KEY, participant_id TEXT NOT NULL REFERENCES participants(id), external_id TEXT NOT NULL, bundle_sha256 TEXT NOT NULL, bundle_version TEXT NOT NULL, started_at TEXT NOT NULL, deadline_at TEXT NOT NULL, status TEXT NOT NULL CHECK(status IN ('started','finished')), finished_at TEXT, server_score INTEGER, history TEXT);
CREATE TABLE IF NOT EXISTS attempt_questions (attempt_id TEXT NOT NULL REFERENCES attempts(id), question_id TEXT NOT NULL, revision TEXT NOT NULL, public_question TEXT NOT NULL, snapshot TEXT NOT NULL, position INTEGER NOT NULL, PRIMARY KEY(attempt_id,question_id));
CREATE TABLE IF NOT EXISTS attempt_answers (attempt_id TEXT NOT NULL, question_id TEXT NOT NULL, idempotency_key TEXT NOT NULL, payload_digest TEXT NOT NULL, answer TEXT NOT NULL, receipt TEXT NOT NULL, PRIMARY KEY(attempt_id,question_id), UNIQUE(attempt_id,idempotency_key), FOREIGN KEY(attempt_id,question_id) REFERENCES attempt_questions(attempt_id,question_id));
`

// Apply installs the local schema in one transaction. Callers must use a file
// database, not an implicit in-memory fallback, when restart durability matters.
func Apply(ctx context.Context, db *sql.DB) error {
	db.SetMaxOpenConns(1)
	db.SetMaxIdleConns(1)
	if _, err := db.ExecContext(ctx, "PRAGMA foreign_keys = ON"); err != nil {
		return fmt.Errorf("enable SQLite foreign keys: %w", err)
	}
	tx, err := db.BeginTx(ctx, nil)
	if err != nil {
		return fmt.Errorf("begin SQLite schema: %w", err)
	}
	defer tx.Rollback()
	if _, err = tx.ExecContext(ctx, "PRAGMA foreign_keys = ON"); err != nil {
		return fmt.Errorf("enable SQLite foreign keys: %w", err)
	}
	if _, err = tx.ExecContext(ctx, schema); err != nil {
		return fmt.Errorf("apply SQLite schema: %w", err)
	}
	if err = tx.Commit(); err != nil {
		return fmt.Errorf("commit SQLite schema: %w", err)
	}
	return nil
}
