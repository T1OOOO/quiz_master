CREATE TABLE feedback_reports (
  id text PRIMARY KEY CHECK (id ~ '^rep_[0-9a-f]{32}$'),
  participant_id text NOT NULL REFERENCES participants(id),
  request_id text NOT NULL CHECK (request_id ~ '^frq_[0-9a-f]{32}$'),
  payload_digest text NOT NULL CHECK (payload_digest ~ '^[0-9a-f]{64}$'),
  type text NOT NULL CHECK (type IN ('ui','content','idea')),
  item_ids text NOT NULL,
  comment text NOT NULL CHECK (length(comment) BETWEEN 1 AND 5000),
  context text NOT NULL,
  screenshot bytea CHECK (octet_length(screenshot) <= 2097152),
  status text NOT NULL CHECK (status IN ('open','resolved')),
  created_at text NOT NULL,
  updated_at text NOT NULL,
  UNIQUE(participant_id,request_id)
);
CREATE INDEX feedback_reports_status_time ON feedback_reports(status,created_at DESC,id DESC);
