#!/usr/bin/env bash
set -euo pipefail

SERVICE="${1:-storage}"
INPUT="${2:-}"
DB_DRIVER="${DB_DRIVER:-}"
DB_PATH="${DB_PATH:-}"
DB_DSN="${DB_DSN:-}"

if [[ -z "$INPUT" || ! -f "$INPUT" ]]; then
  echo "backup file is required: scripts/restore-db.sh <auth|storage> <backup-file>" >&2
  exit 1
fi

case "$SERVICE" in
  auth)
    DB_DRIVER="${DB_DRIVER:-${AUTH_DB_DRIVER:-sqlite}}"
    DB_PATH="${DB_PATH:-${AUTH_DB_PATH:-.data/auth.db}}"
    DB_DSN="${DB_DSN:-${AUTH_DB_DSN:-}}"
    ;;
  storage)
    DB_DRIVER="${DB_DRIVER:-${STORAGE_DB_DRIVER:-sqlite}}"
    DB_PATH="${DB_PATH:-${STORAGE_DB_PATH:-.data/storage.db}}"
    DB_DSN="${DB_DSN:-${STORAGE_DB_DSN:-}}"
    ;;
  *)
    echo "unsupported service: $SERVICE" >&2
    exit 1
    ;;
esac

if [[ "$DB_DRIVER" == "postgres" ]]; then
  if [[ -z "$DB_DSN" ]]; then
    echo "DB_DSN is required for postgres restore" >&2
    exit 1
  fi
  psql "$DB_DSN" < "$INPUT"
else
  mkdir -p "$(dirname "$DB_PATH")"
  cp "$INPUT" "$DB_PATH"
fi

echo "Restore complete for $SERVICE"
