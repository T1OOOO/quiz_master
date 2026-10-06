package reports

import (
	"context"
	"crypto/rand"
	"database/sql"
	"encoding/hex"
	"encoding/json"
	"errors"
	"time"
)

// Store uses the existing database/sql driver for SQLite or pgx's SQL adapter.
// Both databases enforce the participant/request uniqueness constraint.
type Store struct{ db *sql.DB }

func NewStore(db *sql.DB) *Store { return &Store{db: db} }

const storedTime = "2006-01-02T15:04:05.000000000Z"

func (s *Store) Create(ctx context.Context, participant string, input Request) (Receipt, bool, error) {
	in, shot, digest, err := Normalize(input)
	if err != nil {
		return Receipt{}, false, err
	}
	if participant == "" {
		return Receipt{}, false, ErrValidation
	}
	var random [16]byte
	if _, err = rand.Read(random[:]); err != nil {
		return Receipt{}, false, err
	}
	id := "rep_" + hex.EncodeToString(random[:])
	now := time.Now().UTC().Format(storedTime)
	items, _ := json.Marshal(in.ItemIDs)
	contextJSON, _ := json.Marshal(in.Context)
	result, err := s.db.ExecContext(ctx, `INSERT INTO feedback_reports(id,participant_id,request_id,payload_digest,type,item_ids,comment,context,screenshot,status,created_at,updated_at) VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9,'open',$10,$10) ON CONFLICT(participant_id,request_id) DO NOTHING`, id, participant, in.RequestID, digest, in.Type, string(items), in.Comment, string(contextJSON), shot, now)
	if err != nil {
		return Receipt{}, false, err
	}
	affected, err := result.RowsAffected()
	if err != nil {
		return Receipt{}, false, err
	}
	var receipt Receipt
	var existingDigest, created string
	err = s.db.QueryRowContext(ctx, `SELECT id,payload_digest,status,created_at FROM feedback_reports WHERE participant_id=$1 AND request_id=$2`, participant, in.RequestID).Scan(&receipt.ID, &existingDigest, &receipt.Status, &created)
	if err != nil {
		return Receipt{}, false, err
	}
	if existingDigest != digest {
		return Receipt{}, false, ErrConflict
	}
	receipt.CreatedAt, err = time.Parse(time.RFC3339Nano, created)
	return receipt, affected == 1, err
}

const reportColumns = `id,participant_id,type,item_ids,comment,context,status,created_at,updated_at,COALESCE(length(screenshot),0)>0`

type scanner interface{ Scan(...any) error }

func scanReport(row scanner) (Report, error) {
	var r Report
	var items, contextJSON, created, updated string
	if err := row.Scan(&r.ID, &r.ParticipantID, &r.Type, &items, &r.Comment, &contextJSON, &r.Status, &created, &updated, &r.HasScreenshot); err != nil {
		return Report{}, err
	}
	if err := json.Unmarshal([]byte(items), &r.ItemIDs); err != nil {
		return Report{}, err
	}
	if err := json.Unmarshal([]byte(contextJSON), &r.Context); err != nil {
		return Report{}, err
	}
	var err error
	if r.CreatedAt, err = time.Parse(time.RFC3339Nano, created); err != nil {
		return Report{}, err
	}
	if r.UpdatedAt, err = time.Parse(time.RFC3339Nano, updated); err != nil {
		return Report{}, err
	}
	return r, nil
}

func (s *Store) List(ctx context.Context, status string, limit, offset int) (Page, error) {
	if (!ValidStatus(status) && status != "all") || limit < 1 || limit > 100 || offset < 0 || offset > 100000 {
		return Page{}, ErrValidation
	}
	p := Page{Reports: []Report{}, Limit: limit, Offset: offset}
	if err := s.db.QueryRowContext(ctx, `SELECT count(*) FROM feedback_reports WHERE ($1='all' OR status=$1)`, status).Scan(&p.Total); err != nil {
		return Page{}, err
	}
	rows, err := s.db.QueryContext(ctx, `SELECT `+reportColumns+` FROM feedback_reports WHERE ($1='all' OR status=$1) ORDER BY created_at DESC,id DESC LIMIT $2 OFFSET $3`, status, limit, offset)
	if err != nil {
		return Page{}, err
	}
	defer rows.Close()
	for rows.Next() {
		r, err := scanReport(rows)
		if err != nil {
			return Page{}, err
		}
		p.Reports = append(p.Reports, r)
	}
	return p, rows.Err()
}

func (s *Store) SetStatus(ctx context.Context, id, status string) (Report, error) {
	if !ValidID(id) || !ValidStatus(status) {
		return Report{}, ErrValidation
	}
	r, err := scanReport(s.db.QueryRowContext(ctx, `UPDATE feedback_reports SET status=$1,updated_at=$2 WHERE id=$3 RETURNING `+reportColumns, status, time.Now().UTC().Format(storedTime), id))
	if errors.Is(err, sql.ErrNoRows) {
		return Report{}, ErrNotFound
	}
	return r, err
}

func (s *Store) Screenshot(ctx context.Context, id string) ([]byte, error) {
	if !ValidID(id) {
		return nil, ErrValidation
	}
	var data []byte
	err := s.db.QueryRowContext(ctx, `SELECT screenshot FROM feedback_reports WHERE id=$1`, id).Scan(&data)
	if errors.Is(err, sql.ErrNoRows) || (err == nil && len(data) == 0) {
		return nil, ErrNotFound
	}
	return data, err
}

func (s *Store) Delete(ctx context.Context, id string) error {
	if !ValidID(id) {
		return ErrValidation
	}
	r, err := s.db.ExecContext(ctx, `DELETE FROM feedback_reports WHERE id=$1`, id)
	if err != nil {
		return err
	}
	n, err := r.RowsAffected()
	if err != nil {
		return err
	}
	if n == 0 {
		return ErrNotFound
	}
	return nil
}
