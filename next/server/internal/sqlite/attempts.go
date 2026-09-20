package sqlite

import (
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"github.com/google/uuid"
	"os"
	"quiz_master/next/server/internal/attempts"
	"quiz_master/next/server/internal/content"
	"time"
)

type Attempts struct {
	db           *sql.DB
	bundle       content.Bundle
	duration     time.Duration
	explanations map[string]string
}

func NewAttempts(db *sql.DB, path, manifestPath, schemas string, duration time.Duration) (*Attempts, error) {
	_, sourceStatErr := os.Stat(path)
	d, e := content.ReadDocument(path, schemas)
	if e != nil {
		if !errors.Is(sourceStatErr, os.ErrNotExist) {
			return nil, e
		}
		rows, queryErr := db.Query("select controlled_bundle,manifest from attempt_bundles")
		if queryErr != nil {
			return nil, e
		}
		defer rows.Close()
		var bundleRaw, manifestRaw string
		count := 0
		for rows.Next() {
			if queryErr = rows.Scan(&bundleRaw, &manifestRaw); queryErr != nil {
				return nil, queryErr
			}
			count++
		}
		if count != 1 || rows.Err() != nil {
			return nil, e
		}
		var bundle content.Bundle
		var manifest content.Manifest
		if json.Unmarshal([]byte(bundleRaw), &bundle) != nil || json.Unmarshal([]byte(manifestRaw), &manifest) != nil {
			return nil, attempts.ErrValidation
		}
		explanations := map[string]string{}
		for _, q := range manifest.Questions {
			explanations[q.CanonicalID] = q.Explanation
		}
		return &Attempts{db: db, bundle: bundle, duration: duration, explanations: explanations}, nil
	}
	if d.Bundle == nil {
		return nil, attempts.ErrValidation
	}
	explanations := map[string]string{}
	manifestRaw, manifestErr := os.ReadFile(manifestPath)
	if manifestErr != nil {
		return nil, manifestErr
	}
	explanations, err := attempts.ValidateManifest(manifestPath, *d.Bundle)
	if err != nil {
		return nil, err
	}
	raw, err := content.Canonical(*d.Bundle)
	if err != nil {
		return nil, err
	}
	if _, err = db.Exec("insert or ignore into attempt_bundles(bundle_sha256,bundle_version,controlled_bundle,manifest) values(?,?,?,?)", d.Bundle.BundleSHA256, d.Bundle.BundleVersion, string(raw), string(manifestRaw)); err != nil {
		return nil, err
	}
	var stored string
	if err = db.QueryRow("select manifest from attempt_bundles where bundle_sha256=? and bundle_version=?", d.Bundle.BundleSHA256, d.Bundle.BundleVersion).Scan(&stored); err != nil {
		return nil, err
	}
	if stored != string(manifestRaw) {
		return nil, attempts.ErrConflict
	}
	return &Attempts{db: db, bundle: *d.Bundle, duration: duration, explanations: explanations}, nil
}
func (s *Attempts) Catalog() attempts.Catalog {
	return attempts.Catalog{BundleVersion: s.bundle.BundleVersion, BundleSHA256: s.bundle.BundleSHA256, Quiz: s.bundle.Quiz}
}
func (s *Attempts) Start(ctx context.Context, owner string) (attempts.Attempt, error) {
	ext, e := attempts.ExternalParticipant(owner)
	if e != nil {
		return attempts.Attempt{}, e
	}
	if len(s.bundle.Quiz.Questions) == 0 {
		return attempts.Attempt{}, attempts.ErrValidation
	}
	id := "a-" + uuid.NewString()
	snaps, e := attempts.MakeSnapshots(s.bundle, attempts.RandomShuffle)
	if e != nil {
		return attempts.Attempt{}, e
	}
	now := time.Now().UTC().Truncate(time.Microsecond)
	a := attempts.Attempt{AttemptID: id, ParticipantID: ext, BundleVersion: s.bundle.BundleVersion, BundleSHA256: s.bundle.BundleSHA256, ScoringPolicyVersion: "scoring/v1", QuestionSnapshots: snaps, Status: "started", StartedAt: now, DeadlineAt: now.Add(s.duration)}
	tx, e := s.db.BeginTx(ctx, nil)
	if e != nil {
		return a, e
	}
	defer tx.Rollback()
	if _, e = tx.ExecContext(ctx, "insert into attempts(id,participant_id,external_id,bundle_sha256,bundle_version,started_at,deadline_at,status) values(?,?,?,?,?,?,?,?)", id, owner, ext, a.BundleSHA256, a.BundleVersion, a.StartedAt.Format(time.RFC3339Nano), a.DeadlineAt.Format(time.RFC3339Nano), "started"); e != nil {
		return a, e
	}
	for i, q := range s.bundle.Quiz.Questions {
		p, _ := json.Marshal(q)
		sn, _ := json.Marshal(snaps[i])
		rev, _ := json.Marshal(q.Revision)
		if _, e = tx.ExecContext(ctx, "insert into attempt_questions(attempt_id,question_id,revision,public_question,snapshot,position) values(?,?,?,?,?,?)", id, q.QuestionID, string(rev), string(p), string(sn), i); e != nil {
			return a, e
		}
	}
	return a, tx.Commit()
}
func (s *Attempts) Submit(ctx context.Context, owner, id string, r attempts.AnswerRequest) (attempts.Receipt, error) {
	if r.IdempotencyKey == "" || len(r.IdempotencyKey) > 200 {
		return attempts.Receipt{}, attempts.ErrValidation
	}
	tx, err := s.db.BeginTx(ctx, nil)
	if err != nil {
		return attempts.Receipt{}, err
	}
	defer tx.Rollback()
	external, err := attempts.ExternalParticipant(owner)
	if err != nil {
		return attempts.Receipt{}, attempts.ErrForbidden
	}
	var storedOwner string
	if err = tx.QueryRowContext(ctx, "select participant_id from attempts where id=?", id).Scan(&storedOwner); err != nil || storedOwner != owner {
		return attempts.Receipt{}, attempts.ErrForbidden
	}
	digest, err := attempts.PayloadDigest(id, external, r)
	if err != nil {
		return attempts.Receipt{}, attempts.ErrValidation
	}
	var storedDigest, stored string
	if err = tx.QueryRowContext(ctx, "select payload_digest,receipt from attempt_answers where attempt_id=? and idempotency_key=?", id, r.IdempotencyKey).Scan(&storedDigest, &stored); err == nil {
		if storedDigest != digest {
			return attempts.Receipt{}, attempts.ErrConflict
		}
		var replay attempts.Receipt
		if json.Unmarshal([]byte(stored), &replay) != nil {
			return attempts.Receipt{}, attempts.ErrValidation
		}
		return replay, nil
	} else if err != sql.ErrNoRows {
		return attempts.Receipt{}, err
	}
	var p, rev string
	var deadline string
	e := tx.QueryRowContext(ctx, "select q.public_question,q.revision,a.deadline_at from attempt_questions q join attempts a on a.id=q.attempt_id where a.id=? and a.participant_id=? and q.question_id=? and a.status='started'", id, owner, r.QuestionID).Scan(&p, &rev, &deadline)
	if e == sql.ErrNoRows {
		return attempts.Receipt{}, attempts.ErrForbidden
	}
	if e != nil {
		return attempts.Receipt{}, e
	}
	var q content.PublicQuestion
	var want content.Revision
	_ = json.Unmarshal([]byte(p), &q)
	_ = json.Unmarshal([]byte(rev), &want)
	if want != r.QuestionRevision {
		return attempts.Receipt{}, attempts.ErrRevision
	}
	if attempts.ValidateAnswer(q, r.Answer) != nil {
		return attempts.Receipt{}, attempts.ErrValidation
	}
	if digest != r.PayloadDigest {
		return attempts.Receipt{}, attempts.ErrValidation
	}
	if until, err := time.Parse(time.RFC3339Nano, deadline); err != nil || !time.Now().UTC().Before(until) {
		return attempts.Receipt{}, attempts.ErrDeadline
	}
	rec := attempts.Receipt{ReceiptID: "r-" + uuid.NewString(), AttemptID: id, ParticipantID: "p-" + owner[2:], QuestionID: r.QuestionID, QuestionRevision: want, AcceptedAt: time.Now().UTC()}
	raw, _ := json.Marshal(rec)
	answer, _ := json.Marshal(r.Answer)
	_, e = tx.ExecContext(ctx, "insert into attempt_answers(attempt_id,question_id,idempotency_key,payload_digest,answer,receipt) values(?,?,?,?,?,?)", id, r.QuestionID, r.IdempotencyKey, digest, string(answer), string(raw))
	if e != nil {
		var storedDigest, stored string
		if err := tx.QueryRowContext(ctx, "select payload_digest,receipt from attempt_answers where attempt_id=? and idempotency_key=?", id, r.IdempotencyKey).Scan(&storedDigest, &stored); err == nil {
			if storedDigest != digest {
				return attempts.Receipt{}, attempts.ErrConflict
			}
			var replay attempts.Receipt
			if json.Unmarshal([]byte(stored), &replay) != nil {
				return attempts.Receipt{}, attempts.ErrValidation
			}
			return replay, nil
		}
		return attempts.Receipt{}, attempts.ErrConflict
	}
	if err = tx.Commit(); err != nil {
		return attempts.Receipt{}, err
	}
	return rec, nil
}
func (s *Attempts) Finish(ctx context.Context, owner, id string) (attempts.Finish, error) {
	tx, err := s.db.BeginTx(ctx, nil)
	if err != nil {
		return attempts.Finish{}, err
	}
	defer tx.Rollback()
	var external, status, hash, version string
	if err := tx.QueryRowContext(ctx, "select external_id,status,bundle_sha256,bundle_version from attempts where id=? and participant_id=?", id, owner).Scan(&external, &status, &hash, &version); err != nil {
		return attempts.Finish{}, attempts.ErrForbidden
	}
	if status == "finished" {
		_ = tx.Rollback()
		return s.GetHistory(ctx, owner, id)
	}
	var bundleRaw, manifestRaw string
	if err := tx.QueryRowContext(ctx, "select controlled_bundle,manifest from attempt_bundles where bundle_sha256=? and bundle_version=?", hash, version).Scan(&bundleRaw, &manifestRaw); err != nil {
		return attempts.Finish{}, err
	}
	var bundle content.Bundle
	var manifest content.Manifest
	if json.Unmarshal([]byte(bundleRaw), &bundle) != nil || json.Unmarshal([]byte(manifestRaw), &manifest) != nil {
		return attempts.Finish{}, attempts.ErrValidation
	}
	rows, err := tx.QueryContext(ctx, "select q.question_id,q.revision,q.public_question,a.answer,a.receipt from attempt_answers a join attempt_questions q on q.attempt_id=a.attempt_id and q.question_id=a.question_id where a.attempt_id=? order by q.position", id)
	if err != nil {
		return attempts.Finish{}, err
	}
	defer rows.Close()
	f := attempts.Finish{AttemptID: id, ParticipantID: external, Status: "finished", FinishedAt: time.Now().UTC(), History: []attempts.HistoryEntry{}}
	for rows.Next() {
		var qid, rev, pub, ans, receipt string
		if err = rows.Scan(&qid, &rev, &pub, &ans, &receipt); err != nil {
			return f, err
		}
		var q content.PublicQuestion
		var r attempts.Receipt
		var a attempts.Answer
		json.Unmarshal([]byte(pub), &q)
		json.Unmarshal([]byte(receipt), &r)
		json.Unmarshal([]byte(ans), &a)
		f.ServerScore += attempts.Score(q, bundle.PrivateGrading[qid], a)
		f.History = append(f.History, attempts.HistoryEntry{QuestionID: qid, QuestionRevision: r.QuestionRevision, ReceiptID: r.ReceiptID})
	}
	if len(f.History) == 0 {
		return attempts.Finish{}, attempts.ErrValidation
	}
	raw, _ := json.Marshal(f.History)
	_, err = tx.ExecContext(ctx, "update attempts set status='finished',finished_at=?,server_score=?,history=? where id=? and participant_id=?", f.FinishedAt.Format(time.RFC3339Nano), f.ServerScore, string(raw), id, owner)
	if err != nil {
		return f, err
	}
	if err = tx.Commit(); err != nil {
		return f, err
	}
	return f, nil
}
func (s *Attempts) Reveals(ctx context.Context, owner, id string) ([]attempts.Reveal, error) {
	if _, err := s.GetHistory(ctx, owner, id); err != nil {
		return nil, err
	}
	var hash, version, bundleRaw, manifestRaw string
	if err := s.db.QueryRowContext(ctx, "select a.bundle_sha256,a.bundle_version,b.controlled_bundle,b.manifest from attempts a join attempt_bundles b on b.bundle_sha256=a.bundle_sha256 and b.bundle_version=a.bundle_version where a.id=? and a.participant_id=?", id, owner).Scan(&hash, &version, &bundleRaw, &manifestRaw); err != nil {
		return nil, attempts.ErrForbidden
	}
	_ = hash
	_ = version
	var bundle content.Bundle
	var manifest content.Manifest
	if json.Unmarshal([]byte(bundleRaw), &bundle) != nil || json.Unmarshal([]byte(manifestRaw), &manifest) != nil {
		return nil, attempts.ErrValidation
	}
	explanations := map[string]string{}
	for _, question := range manifest.Questions {
		explanations[question.CanonicalID] = question.Explanation
	}
	rows, err := s.db.QueryContext(ctx, "select a.question_id from attempt_answers a join attempt_questions q on q.attempt_id=a.attempt_id and q.question_id=a.question_id where a.attempt_id=? order by q.position", id)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := []attempts.Reveal{}
	for rows.Next() {
		var questionID string
		if err = rows.Scan(&questionID); err != nil {
			return nil, err
		}
		reveal, err := attempts.BuildReveal(bundle, explanations, questionID)
		if err != nil {
			return nil, err
		}
		out = append(out, reveal)
	}
	return out, rows.Err()
}
func (s *Attempts) GetHistory(ctx context.Context, owner, id string) (attempts.Finish, error) {
	var f attempts.Finish
	var when, history string
	err := s.db.QueryRowContext(ctx, "select id,external_id,status,finished_at,server_score,history from attempts where id=? and participant_id=? and status='finished'", id, owner).Scan(&f.AttemptID, &f.ParticipantID, &f.Status, &when, &f.ServerScore, &history)
	if err == sql.ErrNoRows {
		return f, attempts.ErrForbidden
	}
	if err != nil {
		return f, err
	}
	f.FinishedAt, err = time.Parse(time.RFC3339Nano, when)
	if err != nil {
		return f, err
	}
	err = json.Unmarshal([]byte(history), &f.History)
	return f, err
}
func (s *Attempts) ListHistory(ctx context.Context, owner string) ([]attempts.Finish, error) {
	rows, err := s.db.QueryContext(ctx, "select id from attempts where participant_id=? and status='finished' order by finished_at desc,id", owner)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := []attempts.Finish{}
	for rows.Next() {
		var id string
		if err = rows.Scan(&id); err != nil {
			return nil, err
		}
		f, e := s.GetHistory(ctx, owner, id)
		if e != nil {
			return nil, e
		}
		out = append(out, f)
	}
	return out, rows.Err()
}
