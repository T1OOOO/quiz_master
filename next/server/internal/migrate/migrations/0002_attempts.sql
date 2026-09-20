CREATE TABLE attempt_bundles (
 bundle_sha256 text PRIMARY KEY CHECK (bundle_sha256 ~ '^[0-9a-f]{64}$'),
 bundle_version text NOT NULL UNIQUE CHECK (length(bundle_version)>0),
 controlled_bundle jsonb NOT NULL CHECK (jsonb_typeof(controlled_bundle)='object'),
 UNIQUE (bundle_sha256,bundle_version)
);

CREATE TABLE attempts (
 id text PRIMARY KEY CHECK (id ~ '^[a-z][a-z0-9-]{2,63}$'),
 participant_id text NOT NULL REFERENCES participants(id),
 external_participant_id text NOT NULL CHECK (external_participant_id ~ '^p-[0-9a-f]{32}$'),
 bundle_sha256 text NOT NULL,
 bundle_version text NOT NULL,
 scoring_policy_version text NOT NULL CHECK (scoring_policy_version='scoring/v1'),
 started_at timestamptz NOT NULL,
 deadline_at timestamptz NOT NULL CHECK (deadline_at>=started_at+interval '5 minutes' AND deadline_at<=started_at+interval '24 hours'),
 status text NOT NULL CHECK (status IN ('started','finished')),
 finished_at timestamptz,
 server_score integer CHECK (server_score>=0),
 finish_history jsonb,
 FOREIGN KEY (bundle_sha256,bundle_version) REFERENCES attempt_bundles(bundle_sha256,bundle_version),
 CHECK (external_participant_id = 'p-' || substring(participant_id from 3)),
 CHECK ((status='started' AND finished_at IS NULL AND server_score IS NULL AND finish_history IS NULL) OR
        (status='finished' AND finished_at IS NOT NULL AND finished_at>=started_at AND server_score IS NOT NULL AND finish_history IS NOT NULL AND jsonb_typeof(finish_history)='array' AND jsonb_array_length(finish_history)>0))
);
CREATE INDEX attempts_participant_history ON attempts(participant_id,finished_at DESC,id) WHERE status='finished';

CREATE TABLE attempt_questions (
 attempt_id text NOT NULL REFERENCES attempts(id),
 question_id text NOT NULL CHECK (question_id ~ '^[a-z][a-z0-9-]{2,63}$'),
 position integer NOT NULL CHECK(position>=0),
 revision_number integer NOT NULL CHECK(revision_number>0),
 revision_sha256 text NOT NULL CHECK(revision_sha256 ~ '^[0-9a-f]{64}$'),
 snapshot jsonb NOT NULL CHECK(jsonb_typeof(snapshot)='object'),
 public_question jsonb NOT NULL CHECK(jsonb_typeof(public_question)='object'),
 PRIMARY KEY(attempt_id,question_id),
 UNIQUE(attempt_id,position),
 UNIQUE(attempt_id,question_id,revision_number,revision_sha256)
);

CREATE TABLE attempt_answers (
 receipt_id text PRIMARY KEY CHECK(receipt_id ~ '^[a-z][a-z0-9-]{2,63}$'),
 attempt_id text NOT NULL,
 question_id text NOT NULL,
 revision_number integer NOT NULL,
 revision_sha256 text NOT NULL,
 idempotency_key text NOT NULL CHECK(length(idempotency_key) BETWEEN 1 AND 200),
 payload_digest text NOT NULL CHECK(payload_digest ~ '^[0-9a-f]{64}$'),
 answer jsonb NOT NULL CHECK(jsonb_typeof(answer)='object'),
 accepted_at timestamptz NOT NULL,
 receipt jsonb NOT NULL CHECK(jsonb_typeof(receipt)='object'),
 UNIQUE(attempt_id,question_id),
 UNIQUE(attempt_id,idempotency_key),
 FOREIGN KEY(attempt_id,question_id,revision_number,revision_sha256) REFERENCES attempt_questions(attempt_id,question_id,revision_number,revision_sha256)
);

CREATE FUNCTION reject_attempt_immutable_mutation() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
 RAISE EXCEPTION 'immutable attempt data';
END;
$$;
CREATE TRIGGER immutable_attempt_bundle BEFORE UPDATE OR DELETE ON attempt_bundles FOR EACH ROW EXECUTE FUNCTION reject_attempt_immutable_mutation();
CREATE TRIGGER immutable_attempt_question BEFORE UPDATE OR DELETE ON attempt_questions FOR EACH ROW EXECUTE FUNCTION reject_attempt_immutable_mutation();
CREATE TRIGGER immutable_attempt_answer BEFORE UPDATE OR DELETE ON attempt_answers FOR EACH ROW EXECUTE FUNCTION reject_attempt_immutable_mutation();

CREATE FUNCTION guard_attempt_transition() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
 IF OLD.status <> 'started' OR NEW.status <> 'finished' OR
  ROW(NEW.id,NEW.participant_id,NEW.external_participant_id,NEW.bundle_sha256,NEW.bundle_version,NEW.scoring_policy_version,NEW.started_at,NEW.deadline_at)
  IS DISTINCT FROM ROW(OLD.id,OLD.participant_id,OLD.external_participant_id,OLD.bundle_sha256,OLD.bundle_version,OLD.scoring_policy_version,OLD.started_at,OLD.deadline_at)
 THEN RAISE EXCEPTION 'invalid attempt transition'; END IF;
 RETURN NEW;
END;
$$;
CREATE TRIGGER immutable_attempt_pin BEFORE UPDATE ON attempts FOR EACH ROW EXECUTE FUNCTION guard_attempt_transition();
