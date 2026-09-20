package migrate

import (
	"regexp"
	"strings"
	"testing"
)

func TestMigrationsRegisterRevealManifestInOrder(t *testing.T) {
	migrations := Migrations()
	if len(migrations) != 3 {
		t.Fatalf("migration count = %d, want 3", len(migrations))
	}
	for index, migration := range migrations {
		if migration.Version != int64(index+1) {
			t.Fatalf("migration %d has version %d", index, migration.Version)
		}
		if !regexp.MustCompile(`^[0-9a-f]{64}$`).MatchString(migration.Checksum) {
			t.Fatalf("migration %d checksum = %q", migration.Version, migration.Checksum)
		}
	}
}

func TestRevealManifestMigrationHasOneTimeAdoptionGuard(t *testing.T) {
	migrations := Migrations()
	if len(migrations) < 3 {
		t.Fatal("migration 0003 is not registered")
	}
	sql := migrations[2].SQL
	for _, required := range []string{
		"ADD COLUMN manifest_sha256",
		"manifest_sha256 ~ '^[0-9a-f]{64}$'",
		"DROP TRIGGER immutable_attempt_bundle",
		"OLD.manifest_sha256 IS NULL",
		"NEW.manifest_sha256 IS NOT NULL",
		"NEW.bundle_sha256 IS NOT DISTINCT FROM OLD.bundle_sha256",
		"NEW.bundle_version IS NOT DISTINCT FROM OLD.bundle_version",
		"NEW.controlled_bundle IS NOT DISTINCT FROM OLD.controlled_bundle",
		"TG_OP = 'DELETE'",
	} {
		if !strings.Contains(sql, required) {
			t.Fatalf("migration 0003 lacks %q", required)
		}
	}
}
