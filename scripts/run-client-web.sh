#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SERVER_BASE_URL="${SERVER_BASE_URL:-http://localhost:8090}"
API_BASE_URL="${API_BASE_URL:-$SERVER_BASE_URL/api}"
WEB_PORT="${WEB_PORT:-8091}"

SERVER_BASE_URL="$SERVER_BASE_URL" API_BASE_URL="$API_BASE_URL" DEVICE=chrome WEB_PORT="$WEB_PORT" "$ROOT_DIR/scripts/run-client.sh"
