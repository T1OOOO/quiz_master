#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

"$ROOT_DIR/scripts/stop-auth.sh" >/dev/null 2>&1 || true
"$ROOT_DIR/scripts/stop-storage.sh" >/dev/null 2>&1 || true
"$ROOT_DIR/scripts/stop-server.sh" >/dev/null 2>&1 || true

echo "all backend services stopped"
