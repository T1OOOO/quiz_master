#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PID_FILE="$ROOT_DIR/.run/api.pid"

if [[ ! -f "$PID_FILE" ]]; then
  echo "api is not running"
  exit 0
fi

PID="$(cat "$PID_FILE")"
kill "$PID" 2>/dev/null || true
rm -f "$PID_FILE"
echo "api stopped"
