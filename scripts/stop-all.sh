#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

"$ROOT_DIR/scripts/stop-dev.sh" >/dev/null 2>&1 || true
"$ROOT_DIR/scripts/stop-api.sh" >/dev/null 2>&1 || true
rm -rf "$ROOT_DIR/.run"

echo "all local services stopped"
