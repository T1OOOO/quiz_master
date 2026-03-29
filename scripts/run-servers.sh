#!/usr/bin/env bash
set -euo pipefail

SERVER_PORT="${SERVER_PORT:-8090}"
AUTH_PORT="${AUTH_PORT:-8092}"
STORAGE_PORT="${STORAGE_PORT:-8093}"
AUTH_DB_PATH="${AUTH_DB_PATH:-.data/auth.db}"
STORAGE_DB_PATH="${STORAGE_DB_PATH:-.data/storage.db}"
JWT_SECRET="${JWT_SECRET:-dev-secret}"
AUTH_API_TOKEN="${AUTH_API_TOKEN:-dev-auth-token}"
STORAGE_API_TOKEN="${STORAGE_API_TOKEN:-dev-storage-token}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

"$ROOT_DIR/scripts/db.sh" init "$STORAGE_DB_PATH"
PORT="$STORAGE_PORT" DB_PATH="$STORAGE_DB_PATH" STORAGE_API_TOKEN="$STORAGE_API_TOKEN" DETACH=true "$ROOT_DIR/scripts/run-storage.sh"
PORT="$AUTH_PORT" DB_PATH="$AUTH_DB_PATH" JWT_SECRET="$JWT_SECRET" AUTH_API_TOKEN="$AUTH_API_TOKEN" STORAGE_API_URL="http://localhost:$STORAGE_PORT" STORAGE_API_TOKEN="$STORAGE_API_TOKEN" DETACH=true "$ROOT_DIR/scripts/run-auth.sh"
PORT="$SERVER_PORT" JWT_SECRET="$JWT_SECRET" AUTH_API_URL="http://localhost:$AUTH_PORT" AUTH_API_TOKEN="$AUTH_API_TOKEN" STORAGE_API_URL="http://localhost:$STORAGE_PORT" STORAGE_API_TOKEN="$STORAGE_API_TOKEN" DETACH=true "$ROOT_DIR/scripts/run-server.sh"

echo "all backend services started: server=$SERVER_PORT auth=$AUTH_PORT storage=$STORAGE_PORT"
