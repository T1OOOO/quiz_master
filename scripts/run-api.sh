#!/usr/bin/env bash
set -euo pipefail

PORT="${PORT:-8090}"
DB_PATH="${DB_PATH:-.data/quiz_master.db}"
JWT_SECRET="${JWT_SECRET:-dev-secret}"
INIT_DB="${INIT_DB:-true}"
DETACH="${DETACH:-false}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
RUN_DIR="$ROOT_DIR/.run"
PID_FILE="$RUN_DIR/api.pid"

mkdir -p "$RUN_DIR"

if [[ "$INIT_DB" == "true" ]]; then
  "$ROOT_DIR/scripts/db.sh" init "$DB_PATH"
fi

export PORT
export DB_PATH
export JWT_SECRET
export ENV=development
export QUIZZES_DIR=quizzes

if [[ "$DETACH" == "true" ]]; then
  go run ./cmd/api &
  echo $! > "$PID_FILE"
  echo "api started on port $PORT (pid=$(cat "$PID_FILE"))"
  exit 0
fi

echo $$ > "$PID_FILE"
trap 'rm -f "$PID_FILE"' EXIT
go run ./cmd/api
