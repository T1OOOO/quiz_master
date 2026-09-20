//go:build integration

package store

import (
	"context"
	"errors"
	"os"
	"testing"

	"github.com/jackc/pgx/v5/pgxpool"
	"quiz_master/next/server/internal/migrate"
)

func TestWithTxCommitsAndRollsBack(t *testing.T) {
	ctx := context.Background()
	pool, err := pgxpool.New(ctx, os.Getenv("QM_TEST_DATABASE_URL"))
	if err != nil {
		t.Fatal(err)
	}
	defer pool.Close()
	if err := migrate.Apply(ctx, pool, migrate.Migrations()); err != nil {
		t.Fatal(err)
	}
	if _, err := pool.Exec(ctx, "drop table if exists tx_probe"); err != nil {
		t.Fatal(err)
	}
	if _, err := pool.Exec(ctx, "create table tx_probe (id integer primary key)"); err != nil {
		t.Fatal(err)
	}
	b := PgxBeginner{Pool: pool}
	if err := WithTx(ctx, b, func(ctx context.Context, tx Tx) error {
		_, err := tx.Exec(ctx, "insert into tx_probe values (1)")
		return err
	}); err != nil {
		t.Fatal(err)
	}
	if err := WithTx(ctx, b, func(ctx context.Context, tx Tx) error {
		_, err := tx.Exec(ctx, "insert into tx_probe values (2)")
		if err != nil {
			return err
		}
		return errors.New("force rollback")
	}); err == nil {
		t.Fatal("callback error was accepted")
	}
	var count int
	if err := pool.QueryRow(ctx, "select count(*) from tx_probe").Scan(&count); err != nil {
		t.Fatal(err)
	}
	if count != 1 {
		t.Fatalf("rows = %d", count)
	}
}
