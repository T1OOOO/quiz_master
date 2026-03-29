#!/usr/bin/env bash
set -euo pipefail

PORT="${PORT:-8093}"
DB_DRIVER="${DB_DRIVER:-sqlite}"
DB_DSN="${DB_DSN:-}"
DB_PATH="${DB_PATH:-.data/storage.db}"
QUIZZES_DIR="${QUIZZES_DIR:-quizzes}"
STORAGE_API_TOKEN="${STORAGE_API_TOKEN:-dev-storage-token}"
DETACH="${DETACH:-false}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
RUN_DIR="$ROOT_DIR/.run"
PID_FILE="$RUN_DIR/storage.pid"

mkdir -p "$RUN_DIR"

export PORT
export DB_DRIVER
export DB_DSN
export DB_PATH
export QUIZZES_DIR
export STORAGE_API_TOKEN
export ENV=development

if [[ "$DETACH" == "true" ]]; then
  go run ./cmd/storage &
  echo $! > "$PID_FILE"
  echo "storage started on port $PORT (pid=$(cat "$PID_FILE"))"
  exit 0
fi

echo $$ > "$PID_FILE"
trap 'rm -f "$PID_FILE"' EXIT
go run ./cmd/storage
