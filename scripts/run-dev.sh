#!/usr/bin/env bash
set -euo pipefail

SERVER_PORT="${SERVER_PORT:-8090}"
AUTH_PORT="${AUTH_PORT:-8092}"
STORAGE_PORT="${STORAGE_PORT:-8093}"
AUTH_DB_PATH="${AUTH_DB_PATH:-.data/auth.db}"
STORAGE_DB_PATH="${STORAGE_DB_PATH:-.data/storage.db}"
DEVICE="${DEVICE:-chrome}"
WEB_PORT="${WEB_PORT:-8091}"
AUTH_API_TOKEN="${AUTH_API_TOKEN:-dev-auth-token}"
STORAGE_API_TOKEN="${STORAGE_API_TOKEN:-dev-storage-token}"
SERVER_BASE_URL="http://localhost:$SERVER_PORT"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

cleanup() {
  "$ROOT_DIR/scripts/stop-servers.sh" >/dev/null 2>&1 || true
}
trap cleanup EXIT

AUTH_DB_PATH="$AUTH_DB_PATH" STORAGE_DB_PATH="$STORAGE_DB_PATH" AUTH_API_TOKEN="$AUTH_API_TOKEN" STORAGE_API_TOKEN="$STORAGE_API_TOKEN" "$ROOT_DIR/scripts/run-servers.sh"
sleep 3
SERVER_BASE_URL="$SERVER_BASE_URL" API_BASE_URL="$SERVER_BASE_URL/api" AUTH_API_BASE_URL="$SERVER_BASE_URL/api" QUIZ_API_BASE_URL="$SERVER_BASE_URL/api" DEVICE="$DEVICE" WEB_PORT="$WEB_PORT" "$ROOT_DIR/scripts/run-client.sh"
