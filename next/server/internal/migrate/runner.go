package migrate

import (
	"context"
	"crypto/sha256"
	_ "embed"
	"encoding/hex"
	"errors"
	"fmt"
	"sort"

	"github.com/jackc/pgx/v5"
)

//go:embed migrations/0001_identity.sql
var identitySQL string

//go:embed migrations/0002_attempts.sql
var attemptsSQL string

type Migration struct {
	Version       int64
	SQL, Checksum string
}

func Migrations() []Migration {
	return []Migration{{Version: 1, SQL: identitySQL, Checksum: checksum(identitySQL)}, {Version: 2, SQL: attemptsSQL, Checksum: checksum(attemptsSQL)}}
}
func checksum(s string) string { sum := sha256.Sum256([]byte(s)); return hex.EncodeToString(sum[:]) }

type DB interface {
	Begin(context.Context) (pgx.Tx, error)
}

func Apply(ctx context.Context, db DB, migrations []Migration) error {
	sort.Slice(migrations, func(i, j int) bool { return migrations[i].Version < migrations[j].Version })
	for i, m := range migrations {
		if m.Version <= 0 || m.Checksum == "" || (i > 0 && migrations[i-1].Version == m.Version) {
			return fmt.Errorf("invalid migration list")
		}
	}
	tx, err := db.Begin(ctx)
	if err != nil {
		return fmt.Errorf("begin migrations: %w", err)
	}
	defer func() { _ = tx.Rollback(ctx) }()
	if _, err = tx.Exec(ctx, "select pg_advisory_xact_lock($1)", int64(5905001)); err != nil {
		return fmt.Errorf("lock migrations: %w", err)
	}
	if _, err = tx.Exec(ctx, "create table if not exists schema_migrations (version bigint primary key, checksum text not null, applied_at timestamptz not null default now())"); err != nil {
		return fmt.Errorf("create migration bookkeeping: %w", err)
	}
	for _, m := range migrations {
		var stored string
		err = tx.QueryRow(ctx, "select checksum from schema_migrations where version=$1", m.Version).Scan(&stored)
		if err == nil {
			if stored != m.Checksum {
				return fmt.Errorf("migration %d checksum drift", m.Version)
			}
			continue
		}
		if !errors.Is(err, pgx.ErrNoRows) {
			return fmt.Errorf("read migration %d: %w", m.Version, err)
		}
		if _, err = tx.Exec(ctx, m.SQL); err != nil {
			return fmt.Errorf("apply migration %d: %w", m.Version, err)
		}
		if _, err = tx.Exec(ctx, "insert into schema_migrations(version, checksum) values ($1,$2)", m.Version, m.Checksum); err != nil {
			return fmt.Errorf("record migration %d: %w", m.Version, err)
		}
	}
	if err = tx.Commit(ctx); err != nil {
		return fmt.Errorf("commit migrations: %w", err)
	}
	return nil
}
