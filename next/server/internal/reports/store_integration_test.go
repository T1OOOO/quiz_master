//go:build integration

package reports_test

import (
	"context"
	"crypto/rand"
	"encoding/hex"
	"os"
	"testing"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/jackc/pgx/v5/stdlib"
	"quiz_master/next/server/internal/migrate"
	"quiz_master/next/server/internal/reports"
)

func TestPostgresFeedbackConcurrencyAndReconnect(t *testing.T) {
	url := os.Getenv("QM_TEST_DATABASE_URL")
	if url == "" {
		t.Skip("isolated PostgreSQL test database is not configured")
	}
	ctx := context.Background()
	control, err := pgxpool.New(ctx, url)
	if err != nil {
		t.Fatal(err)
	}
	defer control.Close()
	var random [16]byte
	if _, err = rand.Read(random[:]); err != nil {
		t.Fatal(err)
	}
	schema := "qm_feedback_test_" + hex.EncodeToString(random[:])
	if _, err = control.Exec(ctx, "CREATE SCHEMA "+schema); err != nil {
		t.Fatal(err)
	}
	defer func() {
		if _, e := control.Exec(context.Background(), "DROP SCHEMA "+schema+" CASCADE"); e != nil {
			t.Error(e)
		}
	}()
	config, err := pgxpool.ParseConfig(url)
	if err != nil {
		t.Fatal(err)
	}
	config.ConnConfig.RuntimeParams["search_path"] = schema
	pool, err := pgxpool.NewWithConfig(ctx, config)
	if err != nil {
		t.Fatal(err)
	}
	if err = migrate.Apply(ctx, pool, migrate.Migrations()); err != nil {
		pool.Close()
		t.Fatal(err)
	}
	db := stdlib.OpenDBFromPool(pool)
	seedParticipant(t, db, participant)
	r := checkConcurrentRetries(t, reports.NewStore(db))
	if err = db.Close(); err != nil {
		pool.Close()
		t.Fatal(err)
	}
	pool.Close()
	pool, err = pgxpool.NewWithConfig(ctx, config.Copy())
	if err != nil {
		t.Fatal(err)
	}
	defer pool.Close()
	db = stdlib.OpenDBFromPool(pool)
	defer db.Close()
	again, fresh, err := reports.NewStore(db).Create(ctx, participant, sampleReport())
	if err != nil || fresh || again != r {
		t.Fatalf("reconnect lost report: %v", err)
	}
}
