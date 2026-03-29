#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
"$ROOT_DIR/scripts/stop-servers.ps1" >/dev/null 2>&1 || true
echo "dev api stopped"
