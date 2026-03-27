#!/usr/bin/env bash
set -euo pipefail

ACTION="${1:-init}"
DB_PATH="${2:-}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

ARGS=("./cmd/dbtool" "-action" "$ACTION")
if [[ -n "$DB_PATH" ]]; then
  ARGS+=("-db" "$DB_PATH")
fi

go run "${ARGS[@]}"
