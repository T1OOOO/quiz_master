//go:build integration

package identity

import (
	"context"
	"errors"
	"os"
	"testing"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"quiz_master/next/server/internal/migrate"
)

func TestGuestSessionLifecycleAndDatabaseConstraints(t *testing.T) {
	ctx := context.Background()
	pool, err := pgxpool.New(ctx, os.Getenv("QM_TEST_DATABASE_URL"))
	if err != nil {
		t.Fatal(err)
	}
	defer pool.Close()
	if err := migrate.Apply(ctx, pool, migrate.Migrations()); err != nil {
		t.Fatal(err)
	}
	if _, err := pool.Exec(ctx, "truncate sessions, participants"); err != nil {
		t.Fatal(err)
	}
	now := time.Date(2026, 9, 20, 12, 0, 0, 0, time.UTC)
	svc := NewService(pool, func() time.Time { return now }, NewTokenSource(nil))
	p, raw, err := svc.CreateGuest(ctx, "Ada")
	if err != nil {
		t.Fatal(err)
	}
	if raw == "" || p.ID == "" || p.Kind != "guest" {
		t.Fatalf("bad guest/session: %#v", p)
	}
	got, err := svc.Authenticate(ctx, raw)
	if err != nil || got.ID != p.ID {
		t.Fatalf("authenticate: %#v %v", got, err)
	}
	if _, err := svc.Authenticate(ctx, "unknown"); !errors.Is(err, ErrUnauthorized) {
		t.Fatalf("unknown token: %v", err)
	}
	if err := svc.Revoke(ctx, raw); err != nil {
		t.Fatal(err)
	}
	if _, err := svc.Authenticate(ctx, raw); !errors.Is(err, ErrUnauthorized) {
		t.Fatalf("revoked token: %v", err)
	}
	if _, err := pool.Exec(ctx, "insert into sessions (token_digest, participant_id, created_at, expires_at) values ($1,$2,$3,$4)", Digest("duplicate"), p.ID, now, now.Add(time.Hour)); err != nil {
		t.Fatal(err)
	}
	if _, err := pool.Exec(ctx, "insert into sessions (token_digest, participant_id, created_at, expires_at) values ($1,$2,$3,$4)", Digest("duplicate"), p.ID, now, now.Add(time.Hour)); err == nil {
		t.Fatal("duplicate digest was accepted")
	}
	_, expiring, err := svc.CreateGuest(ctx, "Grace")
	if err != nil {
		t.Fatal(err)
	}
	now = now.Add(25 * time.Hour)
	if _, err := svc.Authenticate(ctx, expiring); !errors.Is(err, ErrUnauthorized) {
		t.Fatalf("expired token: %v", err)
	}
	_ = pgx.ErrNoRows
}
