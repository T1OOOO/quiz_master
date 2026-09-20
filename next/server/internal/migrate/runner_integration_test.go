//go:build integration

package migrate

import (
	"context"
	"os"
	"testing"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

func TestApplyCreatesTrackedSchemaAndRejectsChecksumDrift(t *testing.T) {
	ctx := context.Background()
	pool, err := pgxpool.New(ctx, os.Getenv("QM_TEST_DATABASE_URL"))
	if err != nil {
		t.Fatal(err)
	}
	defer pool.Close()
	if err := Apply(ctx, pool, Migrations()); err != nil {
		t.Fatal(err)
	}
	var count int
	if err := pool.QueryRow(ctx, "select count(*) from schema_migrations").Scan(&count); err != nil {
		t.Fatal(err)
	}
	if count != len(Migrations()) {
		t.Fatalf("migration count = %d", count)
	}
	m := Migrations()
	m[0].Checksum = "changed"
	if err := Apply(ctx, pool, m); err == nil {
		t.Fatal("checksum drift was accepted")
	}
	if _, err := pool.Exec(ctx, "truncate attempt_answers, attempt_questions, attempts, sessions, participants"); err != nil {
		t.Fatal(err)
	}
	_ = pgx.ErrNoRows
}
