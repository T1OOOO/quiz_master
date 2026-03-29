#!/usr/bin/env bash
set -euo pipefail

SERVER_BASE_URL="${SERVER_BASE_URL:-http://localhost:8090}"
AUTH_BASE_URL="${AUTH_BASE_URL:-http://localhost:8092}"
STORAGE_BASE_URL="${STORAGE_BASE_URL:-http://localhost:8093}"

check() {
  local url="$1"
  curl -fsS "$url" >/dev/null
  echo "OK $url"
}

check "$SERVER_BASE_URL/healthz"
check "$SERVER_BASE_URL/readyz"
check "$SERVER_BASE_URL/metrics"
check "$SERVER_BASE_URL/api/quizzes"
check "$AUTH_BASE_URL/healthz"
check "$AUTH_BASE_URL/readyz"
check "$AUTH_BASE_URL/metrics"
check "$AUTH_BASE_URL/api/leaderboard"
check "$STORAGE_BASE_URL/healthz"
check "$STORAGE_BASE_URL/readyz"
check "$STORAGE_BASE_URL/metrics"
check "$STORAGE_BASE_URL/api/storage/stats"
