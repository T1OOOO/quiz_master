package sqlite

import (
	"context"
	"database/sql"
	"strings"
	"testing"

	_ "modernc.org/sqlite"
)

func TestApplyCreatesDurableIdentityTables(t *testing.T) {
	db, err := sql.Open("sqlite", "file:"+t.TempDir()+"/quiz.db")
	if err != nil {
		t.Fatal(err)
	}
	defer db.Close()
	if err := Apply(context.Background(), db); err != nil {
		t.Fatal(err)
	}
	var name string
	err = db.QueryRowContext(context.Background(), "select name from sqlite_master where type='table' and name='participants'").Scan(&name)
	if err != nil {
		t.Fatal(err)
	}
	if name != "participants" {
		t.Fatalf("participants table = %q", name)
	}
	if _, err = db.ExecContext(context.Background(), "insert into participants(id,kind,display_name,created_at,updated_at) values(?,?,?,?,?)", "p_0123456789abcdef0123456789abcdef", "guest", "guest", "2026-09-21T00:00:00Z", "2026-09-21T00:00:00Z"); err != nil {
		t.Fatal(err)
	}
	if _, err = db.ExecContext(context.Background(), "insert into participants(id,kind,display_name,created_at,updated_at) values(?,?,?,?,?)", "bad", "guest", "guest", "2026-09-21T00:00:00Z", "2026-09-21T00:00:00Z"); err == nil || !strings.Contains(err.Error(), "constraint") {
		t.Fatalf("invalid participant error = %v", err)
	}
	if _, err = db.ExecContext(context.Background(), "insert into attempt_answers(attempt_id,question_id,idempotency_key,payload_digest,answer,receipt) values(?,?,?,?,?,?)", "missing", "q-missing", "key", strings.Repeat("0", 64), "{}", "{}"); err == nil {
		t.Fatal("accepted answer without pinned question")
	}
}
