package attempts

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"quiz_master/next/server/internal/content"
)

type Options struct {
	Now          func() time.Time
	ID           func(string) (string, error)
	Shuffle      Shuffler
	ManifestPath string
}
type Service struct {
	pool         *pgxpool.Pool
	bundle       content.Bundle
	explanations map[string]string
	duration     time.Duration
	opts         Options
}

// NewService validates raw input before persistence and verifies any previously
// stored immutable version. Private content never passes through public DTOs.
func NewService(ctx context.Context, pool *pgxpool.Pool, path, schemaDir string, duration time.Duration, opts Options) (*Service, error) {
	if duration < 5*time.Minute || duration > 24*time.Hour {
		return nil, ErrValidation
	}
	doc, err := content.ReadDocument(path, schemaDir)
	if err != nil {
		return nil, fmt.Errorf("load controlled bundle: %w", err)
	}
	if doc.Bundle == nil {
		return nil, errors.New("controlled bundle required")
	}
	b := *doc.Bundle
	manifest, err := loadManifest(opts.ManifestPath, b)
	if err != nil {
		return nil, err
	}
	raw, err := content.Canonical(b)
	if err != nil {
		return nil, err
	}
	if _, err = pool.Exec(ctx, `insert into attempt_bundles(bundle_sha256,bundle_version,controlled_bundle,manifest_sha256) values($1,$2,$3,$4) on conflict do nothing`, b.BundleSHA256, b.BundleVersion, raw, manifest.SHA256); err != nil {
		return nil, fmt.Errorf("persist controlled bundle: %w", err)
	}
	var stored []byte
	var storedManifestHash *string
	if err = pool.QueryRow(ctx, `select controlled_bundle,manifest_sha256 from attempt_bundles where bundle_sha256=$1 and bundle_version=$2`, b.BundleSHA256, b.BundleVersion).Scan(&stored, &storedManifestHash); err != nil {
		return nil, errors.New("controlled bundle identity conflict")
	}
	if storedManifestHash == nil {
		if _, err = pool.Exec(ctx, `update attempt_bundles set manifest_sha256=$3 where bundle_sha256=$1 and bundle_version=$2 and manifest_sha256 is null`, b.BundleSHA256, b.BundleVersion, manifest.SHA256); err != nil {
			return nil, fmt.Errorf("adopt explanation manifest: %w", err)
		}
		if err = pool.QueryRow(ctx, `select manifest_sha256 from attempt_bundles where bundle_sha256=$1 and bundle_version=$2`, b.BundleSHA256, b.BundleVersion).Scan(&storedManifestHash); err != nil {
			return nil, errors.New("explanation manifest identity conflict")
		}
	}
	if storedManifestHash == nil || *storedManifestHash != manifest.SHA256 {
		return nil, errors.New("explanation manifest content conflict")
	}
	var value any
	if err = json.Unmarshal(stored, &value); err != nil {
		return nil, errors.New("stored bundle invalid")
	}
	canonical, err := content.Canonical(value)
	if err != nil || !bytes.Equal(canonical, raw) {
		return nil, errors.New("controlled bundle content conflict")
	}
	if opts.Now == nil {
		opts.Now = time.Now
	}
	if opts.ID == nil {
		opts.ID = randomID
	}
	if opts.Shuffle == nil {
		opts.Shuffle = randomShuffle
	}
	return &Service{pool: pool, bundle: b, explanations: manifest.Explanations, duration: duration, opts: opts}, nil
}

type Catalog struct {
	BundleVersion string             `json:"bundle_version"`
	BundleSHA256  string             `json:"bundle_sha256"`
	Quiz          content.PublicQuiz `json:"quiz"`
}

func (s *Service) Catalog() Catalog {
	// Return independent public data, so callers cannot mutate the pinned source.
	raw, _ := json.Marshal(s.bundle.Quiz)
	var q content.PublicQuiz
	_ = json.Unmarshal(raw, &q)
	return Catalog{BundleVersion: s.bundle.BundleVersion, BundleSHA256: s.bundle.BundleSHA256, Quiz: q}
}
func (s *Service) now() time.Time { return s.opts.Now().UTC().Truncate(time.Microsecond) }
func (s *Service) Start(ctx context.Context, owner string) (Attempt, error) {
	external, err := ExternalParticipant(owner)
	if err != nil {
		return Attempt{}, err
	}
	id, err := s.opts.ID("a")
	if err != nil {
		return Attempt{}, err
	}
	if !contractID.MatchString(id) {
		return Attempt{}, ErrValidation
	}
	snapshots, err := makeSnapshots(s.bundle, s.opts.Shuffle)
	if err != nil {
		return Attempt{}, err
	}
	a := Attempt{AttemptID: id, ParticipantID: external, BundleVersion: s.bundle.BundleVersion, BundleSHA256: s.bundle.BundleSHA256, ScoringPolicyVersion: "scoring/v1", QuestionSnapshots: snapshots, Status: "started"}
	tx, err := s.pool.Begin(ctx)
	if err != nil {
		return Attempt{}, err
	}
	defer func() { _ = tx.Rollback(ctx) }()
	a.StartedAt = s.now()
	a.DeadlineAt = a.StartedAt.Add(s.duration)
	if _, err = tx.Exec(ctx, `insert into attempts(id,participant_id,external_participant_id,bundle_sha256,bundle_version,scoring_policy_version,started_at,deadline_at,status) values($1,$2,$3,$4,$5,'scoring/v1',$6,$7,'started')`, id, owner, external, a.BundleSHA256, a.BundleVersion, a.StartedAt, a.DeadlineAt); err != nil {
		return Attempt{}, fmt.Errorf("start attempt: %w", err)
	}
	for i, q := range s.bundle.Quiz.Questions {
		snap, _ := json.Marshal(snapshots[i])
		public, _ := json.Marshal(q)
		if _, err = tx.Exec(ctx, `insert into attempt_questions(attempt_id,question_id,position,revision_number,revision_sha256,snapshot,public_question) values($1,$2,$3,$4,$5,$6,$7)`, id, q.QuestionID, i, q.Revision.Number, q.Revision.SHA256, snap, public); err != nil {
			return Attempt{}, fmt.Errorf("pin attempt question: %w", err)
		}
	}
	if err = tx.Commit(ctx); err != nil {
		return Attempt{}, err
	}
	return a, nil
}

type lockedAttempt struct {
	external, status, hash string
	start, deadline        time.Time
}

func lockAttempt(ctx context.Context, tx pgx.Tx, owner, id string) (lockedAttempt, error) {
	if _, err := ExternalParticipant(owner); err != nil {
		return lockedAttempt{}, ErrForbidden
	}
	var a lockedAttempt
	err := tx.QueryRow(ctx, `select external_participant_id,status,bundle_sha256,started_at,deadline_at from attempts where id=$1 and participant_id=$2 for update`, id, owner).Scan(&a.external, &a.status, &a.hash, &a.start, &a.deadline)
	if errors.Is(err, pgx.ErrNoRows) {
		return a, ErrForbidden
	}
	return a, err
}
func (s *Service) Submit(ctx context.Context, owner, id string, req AnswerRequest) (Receipt, error) {
	tx, err := s.pool.Begin(ctx)
	if err != nil {
		return Receipt{}, err
	}
	defer func() { _ = tx.Rollback(ctx) }()
	a, err := lockAttempt(ctx, tx, owner, id)
	if err != nil {
		return Receipt{}, err
	}
	digest, err := PayloadDigest(id, a.external, req)
	if err != nil {
		return Receipt{}, err
	}
	if req.IdempotencyKey == "" || len(req.IdempotencyKey) > 200 || digest != req.PayloadDigest {
		return Receipt{}, ErrValidation
	}
	var storedDigest string
	var raw []byte
	err = tx.QueryRow(ctx, `select payload_digest,receipt from attempt_answers where attempt_id=$1 and idempotency_key=$2`, id, req.IdempotencyKey).Scan(&storedDigest, &raw)
	if err == nil {
		if storedDigest != digest {
			return Receipt{}, ErrConflict
		}
		var r Receipt
		if err = json.Unmarshal(raw, &r); err != nil {
			return Receipt{}, err
		}
		return r, nil
	}
	if !errors.Is(err, pgx.ErrNoRows) {
		return Receipt{}, err
	}
	if a.status != "started" {
		return Receipt{}, ErrValidation
	}
	// Sample only after the row lock; queued transactions cannot use stale time.
	now := s.now()
	if !now.Before(a.deadline) {
		return Receipt{}, ErrDeadline
	}
	if now.Before(a.start) {
		return Receipt{}, ErrValidation
	}
	var public []byte
	err = tx.QueryRow(ctx, `select public_question from attempt_questions where attempt_id=$1 and question_id=$2`, id, req.QuestionID).Scan(&public)
	if errors.Is(err, pgx.ErrNoRows) {
		return Receipt{}, ErrValidation
	}
	if err != nil {
		return Receipt{}, err
	}
	var q content.PublicQuestion
	if err = json.Unmarshal(public, &q); err != nil {
		return Receipt{}, err
	}
	if q.Revision != req.QuestionRevision {
		return Receipt{}, ErrRevision
	}
	if err = validateAnswer(q, req.Answer); err != nil {
		return Receipt{}, err
	}
	var exists bool
	if err = tx.QueryRow(ctx, `select exists(select 1 from attempt_answers where attempt_id=$1 and question_id=$2)`, id, req.QuestionID).Scan(&exists); err != nil {
		return Receipt{}, err
	}
	if exists {
		return Receipt{}, ErrConflict
	}
	receiptID, err := s.opts.ID("r")
	if err != nil {
		return Receipt{}, err
	}
	if !contractID.MatchString(receiptID) {
		return Receipt{}, ErrValidation
	}
	r := Receipt{ReceiptID: receiptID, AttemptID: id, ParticipantID: a.external, QuestionID: req.QuestionID, QuestionRevision: q.Revision, AcceptedAt: now}
	raw, _ = json.Marshal(r)
	answer, _ := json.Marshal(req.Answer)
	if _, err = tx.Exec(ctx, `insert into attempt_answers(receipt_id,attempt_id,question_id,revision_number,revision_sha256,idempotency_key,payload_digest,answer,accepted_at,receipt) values($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)`, receiptID, id, req.QuestionID, q.Revision.Number, q.Revision.SHA256, req.IdempotencyKey, digest, answer, now, raw); err != nil {
		return Receipt{}, fmt.Errorf("record answer: %w", err)
	}
	if err = tx.Commit(ctx); err != nil {
		return Receipt{}, err
	}
	return r, nil
}
func (s *Service) Finish(ctx context.Context, owner, id string) (Finish, error) {
	tx, err := s.pool.Begin(ctx)
	if err != nil {
		return Finish{}, err
	}
	defer func() { _ = tx.Rollback(ctx) }()
	a, err := lockAttempt(ctx, tx, owner, id)
	if err != nil {
		return Finish{}, err
	}
	if a.status == "finished" {
		return readFinish(ctx, tx, owner, id)
	}
	var raw []byte
	if err = tx.QueryRow(ctx, `select controlled_bundle from attempt_bundles where bundle_sha256=$1`, a.hash).Scan(&raw); err != nil {
		return Finish{}, err
	}
	var b content.Bundle
	if err = json.Unmarshal(raw, &b); err != nil {
		return Finish{}, err
	}
	rows, err := tx.Query(ctx, `select q.public_question,r.answer,r.receipt_id from attempt_answers r join attempt_questions q using(attempt_id,question_id) where r.attempt_id=$1 order by q.position`, id)
	if err != nil {
		return Finish{}, err
	}
	f := Finish{AttemptID: id, ParticipantID: a.external, Status: "finished", FinishedAt: s.now(), History: []HistoryEntry{}}
	for rows.Next() {
		var question, answer []byte
		var receipt string
		if err = rows.Scan(&question, &answer, &receipt); err != nil {
			rows.Close()
			return Finish{}, err
		}
		var q content.PublicQuestion
		var v Answer
		if err = json.Unmarshal(question, &q); err != nil {
			rows.Close()
			return Finish{}, err
		}
		if err = json.Unmarshal(answer, &v); err != nil {
			rows.Close()
			return Finish{}, err
		}
		f.ServerScore += score(q, b.PrivateGrading[q.QuestionID], v)
		f.History = append(f.History, HistoryEntry{QuestionID: q.QuestionID, QuestionRevision: q.Revision, ReceiptID: receipt})
	}
	rows.Close()
	if err = rows.Err(); err != nil {
		return Finish{}, err
	}
	if len(f.History) == 0 || f.FinishedAt.Before(a.start) {
		return Finish{}, ErrValidation
	}
	history, _ := json.Marshal(f.History)
	if _, err = tx.Exec(ctx, `update attempts set status='finished',finished_at=$2,server_score=$3,finish_history=$4 where id=$1`, id, f.FinishedAt, f.ServerScore, history); err != nil {
		return Finish{}, err
	}
	if err = tx.Commit(ctx); err != nil {
		return Finish{}, err
	}
	return f, nil
}

// queryRow is satisfied by pgx transactions and pools; it keeps finish decoding
// identical for a locked idempotent finish and an owner-scoped history read.
type queryRow interface {
	QueryRow(context.Context, string, ...any) pgx.Row
}

func readFinish(ctx context.Context, db queryRow, owner, id string) (Finish, error) {
	var f Finish
	var history []byte
	err := db.QueryRow(ctx, `select id,external_participant_id,status,finished_at,server_score,finish_history from attempts where id=$1 and participant_id=$2 and status='finished'`, id, owner).Scan(&f.AttemptID, &f.ParticipantID, &f.Status, &f.FinishedAt, &f.ServerScore, &history)
	if errors.Is(err, pgx.ErrNoRows) {
		return Finish{}, ErrForbidden
	}
	if err != nil {
		return Finish{}, err
	}
	if err = json.Unmarshal(history, &f.History); err != nil {
		return Finish{}, err
	}
	f.FinishedAt = f.FinishedAt.UTC()
	return f, nil
}
func (s *Service) GetHistory(ctx context.Context, owner, id string) (Finish, error) {
	if _, err := ExternalParticipant(owner); err != nil {
		return Finish{}, ErrForbidden
	}
	return readFinish(ctx, s.pool, owner, id)
}
func (s *Service) ListHistory(ctx context.Context, owner string) ([]Finish, error) {
	if _, err := ExternalParticipant(owner); err != nil {
		return nil, ErrForbidden
	}
	rows, err := s.pool.Query(ctx, `select id,external_participant_id,status,finished_at,server_score,finish_history from attempts where participant_id=$1 and status='finished' order by finished_at desc,id`, owner)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := []Finish{}
	for rows.Next() {
		var f Finish
		var history []byte
		if err = rows.Scan(&f.AttemptID, &f.ParticipantID, &f.Status, &f.FinishedAt, &f.ServerScore, &history); err != nil {
			return nil, err
		}
		if err = json.Unmarshal(history, &f.History); err != nil {
			return nil, err
		}
		f.FinishedAt = f.FinishedAt.UTC()
		out = append(out, f)
	}
	return out, rows.Err()
}
