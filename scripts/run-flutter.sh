#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

export AUTH_API_BASE_URL="${AUTH_API_BASE_URL:-http://localhost:8092/api}"
export QUIZ_API_BASE_URL="${QUIZ_API_BASE_URL:-http://localhost:8090/api}"

exec "$ROOT_DIR/scripts/run-client.sh" "$@"
