#!/usr/bin/env bash
set -euo pipefail

PORT="${PORT:-8092}"
DB_DRIVER="${DB_DRIVER:-sqlite}"
DB_DSN="${DB_DSN:-}"
DB_PATH="${DB_PATH:-.data/auth.db}"
JWT_SECRET="${JWT_SECRET:-dev-secret}"
AUTH_API_TOKEN="${AUTH_API_TOKEN:-dev-auth-token}"
STORAGE_API_URL="${STORAGE_API_URL:-http://localhost:8093}"
STORAGE_API_TOKEN="${STORAGE_API_TOKEN:-dev-storage-token}"
DETACH="${DETACH:-false}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
RUN_DIR="$ROOT_DIR/.run"
PID_FILE="$RUN_DIR/auth.pid"

mkdir -p "$RUN_DIR"

export PORT
export DB_DRIVER
export DB_DSN
export DB_PATH
export JWT_SECRET
export AUTH_API_TOKEN
export STORAGE_API_URL
export STORAGE_API_TOKEN
export ENV=development

if [[ "$DETACH" == "true" ]]; then
  go run ./cmd/auth &
  echo $! > "$PID_FILE"
  echo "auth started on port $PORT (pid=$(cat "$PID_FILE"))"
  exit 0
fi

echo $$ > "$PID_FILE"
trap 'rm -f "$PID_FILE"' EXIT
go run ./cmd/auth
