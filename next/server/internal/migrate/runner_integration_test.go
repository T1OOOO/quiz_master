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
	migrations := Migrations()
	if err := Apply(ctx, pool, migrations[:2]); err != nil {
		t.Fatal(err)
	}
	legacyHash := "1111111111111111111111111111111111111111111111111111111111111111"
	if _, err := pool.Exec(ctx, `insert into attempt_bundles(bundle_sha256,bundle_version,controlled_bundle) values($1,'legacy-before-manifest','{}')`, legacyHash); err != nil {
		t.Fatal(err)
	}
	if err := Apply(ctx, pool, migrations); err != nil {
		t.Fatal(err)
	}
	var count int
	if err := pool.QueryRow(ctx, "select count(*) from schema_migrations").Scan(&count); err != nil {
		t.Fatal(err)
	}
	if count != len(Migrations()) {
		t.Fatalf("migration count = %d", count)
	}
	firstManifest := "2222222222222222222222222222222222222222222222222222222222222222"
	secondManifest := "3333333333333333333333333333333333333333333333333333333333333333"
	if _, err := pool.Exec(ctx, `update attempt_bundles set manifest_sha256=$2 where bundle_sha256=$1`, legacyHash, firstManifest); err != nil {
		t.Fatal("legacy manifest adoption failed", err)
	}
	for name, statement := range map[string]string{
		"second adoption": `update attempt_bundles set manifest_sha256='3333333333333333333333333333333333333333333333333333333333333333' where bundle_sha256='1111111111111111111111111111111111111111111111111111111111111111'`,
		"other column":    `update attempt_bundles set bundle_version='changed' where bundle_sha256='1111111111111111111111111111111111111111111111111111111111111111'`,
		"delete":          `delete from attempt_bundles where bundle_sha256='1111111111111111111111111111111111111111111111111111111111111111'`,
		"new null hash":   `insert into attempt_bundles(bundle_sha256,bundle_version,controlled_bundle) values('4444444444444444444444444444444444444444444444444444444444444444','missing-manifest','{}')`,
	} {
		if _, err := pool.Exec(ctx, statement); err == nil {
			t.Fatal(name, "was accepted")
		}
	}
	if _, err := pool.Exec(ctx, `insert into attempt_bundles(bundle_sha256,bundle_version,controlled_bundle,manifest_sha256) values('5555555555555555555555555555555555555555555555555555555555555555','new-with-manifest','{}',$1)`, secondManifest); err != nil {
		t.Fatal("new bundle with manifest rejected", err)
	}
	m := Migrations()
	m[0].Checksum = "changed"
	if err := Apply(ctx, pool, m); err == nil {
		t.Fatal("checksum drift was accepted")
	}
	if _, err := pool.Exec(ctx, "truncate attempt_answers, attempt_questions, attempts, attempt_bundles, sessions, participants"); err != nil {
		t.Fatal(err)
	}
	_ = pgx.ErrNoRows
}
