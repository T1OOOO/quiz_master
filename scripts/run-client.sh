#!/usr/bin/env bash
set -euo pipefail

SERVER_BASE_URL="${SERVER_BASE_URL:-http://localhost:8090}"
API_BASE_URL="${API_BASE_URL:-$SERVER_BASE_URL/api}"
DEVICE="${DEVICE:-chrome}"
WEB_PORT="${WEB_PORT:-8091}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR/flutter"

flutter pub get
FLUTTER_ARGS=(
  run
  -d "$DEVICE"
  --dart-define="SERVER_BASE_URL=$SERVER_BASE_URL"
  --dart-define="API_BASE_URL=$API_BASE_URL"
)

if [[ "$DEVICE" == "chrome" || "$DEVICE" == "edge" || "$DEVICE" == "web-server" ]]; then
  FLUTTER_ARGS+=(--web-port "$WEB_PORT")
fi

flutter "${FLUTTER_ARGS[@]}"
