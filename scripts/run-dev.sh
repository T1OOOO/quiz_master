#!/usr/bin/env bash
set -euo pipefail

PORT="${PORT:-8090}"
DB_PATH="${DB_PATH:-.data/quiz_master.db}"
DEVICE="${DEVICE:-chrome}"
WEB_PORT="${WEB_PORT:-8091}"
DETACH="${DETACH:-false}"
SERVER_BASE_URL="http://localhost:$PORT"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
RUN_DIR="$ROOT_DIR/.run"
PID_FILE="$RUN_DIR/dev-api.pid"

mkdir -p "$RUN_DIR"

INIT_DB=true DETACH=true PORT="$PORT" DB_PATH="$DB_PATH" "$ROOT_DIR/scripts/run-api.sh" &
API_PID=$!
echo "$API_PID" > "$PID_FILE"

cleanup() {
  kill "$API_PID" 2>/dev/null || true
  rm -f "$PID_FILE"
}
trap cleanup EXIT

sleep 3
if [[ "$DETACH" == "true" ]]; then
  echo "dev api started on $SERVER_BASE_URL (pid=$API_PID); run client separately"
  exit 0
fi

SERVER_BASE_URL="$SERVER_BASE_URL" API_BASE_URL="$SERVER_BASE_URL/api" DEVICE="$DEVICE" WEB_PORT="$WEB_PORT" "$ROOT_DIR/scripts/run-client.sh"
