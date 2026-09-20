package identity

import (
	"context"
	"crypto/rand"
	"encoding/hex"
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

var ErrUnauthorized = errors.New("unauthorized")

type Principal struct{ ID, Kind, DisplayName string }
type Service struct {
	pool   *pgxpool.Pool
	now    func() time.Time
	tokens TokenSource
}

func NewService(pool *pgxpool.Pool, now func() time.Time, tokens TokenSource) *Service {
	if now == nil {
		now = time.Now
	}
	return &Service{pool: pool, now: now, tokens: tokens}
}
func (s *Service) CreateGuest(ctx context.Context, displayName string) (Principal, string, error) {
	displayName = strings.TrimSpace(displayName)
	if displayName == "" || len(displayName) > 100 {
		return Principal{}, "", fmt.Errorf("display name is invalid")
	}
	id, err := participantID()
	if err != nil {
		return Principal{}, "", err
	}
	token, err := s.tokens.New()
	if err != nil {
		return Principal{}, "", err
	}
	now := s.now().UTC()
	expires := now.Add(24 * time.Hour)
	tx, err := s.pool.Begin(ctx)
	if err != nil {
		return Principal{}, "", fmt.Errorf("begin guest: %w", err)
	}
	defer func() { _ = tx.Rollback(ctx) }()
	if _, err = tx.Exec(ctx, "insert into participants(id,kind,display_name,created_at,updated_at) values ($1,'guest',$2,$3,$3)", id, displayName, now); err != nil {
		return Principal{}, "", fmt.Errorf("create guest: %w", err)
	}
	if _, err = tx.Exec(ctx, "insert into sessions(token_digest,participant_id,created_at,expires_at) values ($1,$2,$3,$4)", Digest(token), id, now, expires); err != nil {
		return Principal{}, "", fmt.Errorf("issue session: %w", err)
	}
	if err = tx.Commit(ctx); err != nil {
		return Principal{}, "", fmt.Errorf("commit guest: %w", err)
	}
	return Principal{ID: id, Kind: "guest", DisplayName: displayName}, token, nil
}
func (s *Service) Authenticate(ctx context.Context, token string) (Principal, error) {
	var p Principal
	err := s.pool.QueryRow(ctx, "select p.id,p.kind,p.display_name from sessions s join participants p on p.id=s.participant_id where s.token_digest=$1 and s.revoked_at is null and s.expires_at>$2", Digest(token), s.now().UTC()).Scan(&p.ID, &p.Kind, &p.DisplayName)
	if errors.Is(err, pgx.ErrNoRows) {
		return Principal{}, ErrUnauthorized
	}
	if err != nil {
		return Principal{}, fmt.Errorf("authenticate session: %w", err)
	}
	return p, nil
}
func (s *Service) Revoke(ctx context.Context, token string) error {
	tag, err := s.pool.Exec(ctx, "update sessions set revoked_at=$2 where token_digest=$1 and revoked_at is null", Digest(token), s.now().UTC())
	if err != nil {
		return fmt.Errorf("revoke session: %w", err)
	}
	if tag.RowsAffected() == 0 {
		return ErrUnauthorized
	}
	return nil
}
func participantID() (string, error) {
	b := make([]byte, 16)
	if _, err := rand.Read(b); err != nil {
		return "", fmt.Errorf("generate participant id: %w", err)
	}
	return "p_" + hex.EncodeToString(b), nil
}
