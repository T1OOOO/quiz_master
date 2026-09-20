CREATE TABLE participants (
  id text PRIMARY KEY CHECK (id ~ '^p_[0-9a-f]{32}$'),
  kind text NOT NULL CHECK (kind IN ('guest', 'account')),
  display_name text NOT NULL CHECK (length(display_name) BETWEEN 1 AND 100),
  account_reference text UNIQUE,
  created_at timestamptz NOT NULL,
  updated_at timestamptz NOT NULL
);

CREATE TABLE sessions (
  token_digest char(64) PRIMARY KEY CHECK (token_digest ~ '^[0-9a-f]{64}$'),
  participant_id text NOT NULL REFERENCES participants(id),
  created_at timestamptz NOT NULL,
  expires_at timestamptz NOT NULL CHECK (expires_at > created_at),
  revoked_at timestamptz NULL CHECK (revoked_at IS NULL OR revoked_at >= created_at)
);
CREATE INDEX sessions_active_lookup ON sessions (token_digest, expires_at) WHERE revoked_at IS NULL;
