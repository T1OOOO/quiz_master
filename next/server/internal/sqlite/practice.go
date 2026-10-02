package sqlite

import (
	"context"
	"database/sql"
	"encoding/json"
	"quiz_master/next/server/internal/attempts"
	"quiz_master/next/server/internal/content"
)

// Only an owned, accepted practice answer can reveal its pinned grading data.
// Ranked and unanswered questions never join this result.
func (s *Attempts) Feedback(ctx context.Context, owner, id, question string) (attempts.Reveal, bool, error) {
	var publicRaw, answerRaw, bundleRaw, manifestRaw string
	err := s.db.QueryRowContext(ctx, `select q.public_question,a.answer,b.controlled_bundle,b.manifest
 from attempts t join practice_attempts p on p.attempt_id=t.id
 join attempt_questions q on q.attempt_id=t.id
 join attempt_answers a on a.attempt_id=t.id and a.question_id=q.question_id
 join attempt_bundles b on b.bundle_sha256=t.bundle_sha256 and b.bundle_version=t.bundle_version
 where t.id=? and t.participant_id=? and q.question_id=?`, id, owner, question).Scan(&publicRaw, &answerRaw, &bundleRaw, &manifestRaw)
	if err == sql.ErrNoRows {
		return attempts.Reveal{}, false, attempts.ErrForbidden
	}
	if err != nil {
		return attempts.Reveal{}, false, err
	}
	var q content.PublicQuestion
	var answer attempts.Answer
	var bundle content.Bundle
	var manifest content.Manifest
	if json.Unmarshal([]byte(publicRaw), &q) != nil || json.Unmarshal([]byte(answerRaw), &answer) != nil || json.Unmarshal([]byte(bundleRaw), &bundle) != nil || json.Unmarshal([]byte(manifestRaw), &manifest) != nil {
		return attempts.Reveal{}, false, attempts.ErrValidation
	}
	explanations := map[string]string{}
	for _, item := range manifest.Questions {
		explanations[item.CanonicalID] = item.Explanation
	}
	reveal, err := attempts.BuildReveal(bundle, explanations, question)
	if err != nil {
		return attempts.Reveal{}, false, err
	}
	return reveal, attempts.Score(q, bundle.PrivateGrading[question], answer) > 0, nil
}
