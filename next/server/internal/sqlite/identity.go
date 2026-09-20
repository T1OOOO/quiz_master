package sqlite

import (
	"context"
	"crypto/rand"
	"database/sql"
	"encoding/hex"
	"errors"
	"fmt"
	"time"

	"quiz_master/next/server/internal/identity"
)

type Identity struct {
	db     *sql.DB
	now    func() time.Time
	tokens identity.TokenSource
}

func NewIdentity(db *sql.DB, now func() time.Time, tokens identity.TokenSource) *Identity {
	if now == nil {
		now = time.Now
	}
	return &Identity{db: db, now: now, tokens: tokens}
}

func (s *Identity) CreateGuestSession(ctx context.Context, name string) (identity.GuestSession, error) {
	name, err := identity.CleanDisplayName(name)
	if err != nil {
		return identity.GuestSession{}, err
	}
	b := make([]byte, 16)
	if _, err = rand.Read(b); err != nil {
		return identity.GuestSession{}, err
	}
	id := "p_" + hex.EncodeToString(b)
	token, err := s.tokens.New()
	if err != nil {
		return identity.GuestSession{}, err
	}
	now := s.now().UTC()
	expires := now.Add(24 * time.Hour)
	tx, err := s.db.BeginTx(ctx, nil)
	if err != nil {
		return identity.GuestSession{}, err
	}
	defer tx.Rollback()
	if _, err = tx.ExecContext(ctx, "insert into participants(id,kind,display_name,created_at,updated_at) values(?,?,?,?,?)", id, "guest", name, now.Format(time.RFC3339Nano), now.Format(time.RFC3339Nano)); err != nil {
		return identity.GuestSession{}, fmt.Errorf("create guest: %w", err)
	}
	if _, err = tx.ExecContext(ctx, "insert into sessions(token_digest,participant_id,created_at,expires_at) values(?,?,?,?)", identity.Digest(token), id, now.Format(time.RFC3339Nano), expires.Format(time.RFC3339Nano)); err != nil {
		return identity.GuestSession{}, fmt.Errorf("issue session: %w", err)
	}
	if err = tx.Commit(); err != nil {
		return identity.GuestSession{}, err
	}
	return identity.GuestSession{Principal: identity.Principal{ID: id, Kind: "guest", DisplayName: name}, Token: token, ExpiresAt: expires}, nil
}
func (s *Identity) Authenticate(ctx context.Context, token string) (identity.Principal, error) {
	var p identity.Principal
	var expires string
	err := s.db.QueryRowContext(ctx, "select p.id,p.kind,p.display_name,s.expires_at from sessions s join participants p on p.id=s.participant_id where s.token_digest=? and s.revoked_at is null", identity.Digest(token)).Scan(&p.ID, &p.Kind, &p.DisplayName, &expires)
	if errors.Is(err, sql.ErrNoRows) {
		return identity.Principal{}, identity.ErrUnauthorized
	}
	if err != nil {
		return identity.Principal{}, err
	}
	expiry, err := time.Parse(time.RFC3339Nano, expires)
	if err != nil || !expiry.After(s.now().UTC()) {
		return identity.Principal{}, identity.ErrUnauthorized
	}
	return p, nil
}
