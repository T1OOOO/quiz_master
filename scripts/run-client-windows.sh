#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SERVER_BASE_URL="${SERVER_BASE_URL:-http://localhost:8090}"
API_BASE_URL="${API_BASE_URL:-$SERVER_BASE_URL/api}"

SERVER_BASE_URL="$SERVER_BASE_URL" API_BASE_URL="$API_BASE_URL" DEVICE=windows "$ROOT_DIR/scripts/run-client.sh"
