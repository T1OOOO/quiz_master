#!/usr/bin/env bash
set -euo pipefail

SERVICE="${1:-storage}"
DB_DRIVER="${DB_DRIVER:-}"
DB_PATH="${DB_PATH:-}"
DB_DSN="${DB_DSN:-}"
OUTPUT="${OUTPUT:-}"

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

stamp="$(date +%Y%m%d-%H%M%S)"
if [[ -z "$OUTPUT" ]]; then
  ext="db"
  if [[ "$DB_DRIVER" == "postgres" ]]; then
    ext="sql"
  fi
  OUTPUT=".backup/${SERVICE}-${stamp}.${ext}"
fi

mkdir -p "$(dirname "$OUTPUT")"

if [[ "$DB_DRIVER" == "postgres" ]]; then
  if [[ -z "$DB_DSN" ]]; then
    echo "DB_DSN is required for postgres backups" >&2
    exit 1
  fi
  pg_dump --dbname="$DB_DSN" --file="$OUTPUT" --format=plain --no-owner --no-privileges
else
  if [[ ! -f "$DB_PATH" ]]; then
    echo "SQLite database not found: $DB_PATH" >&2
    exit 1
  fi
  cp "$DB_PATH" "$OUTPUT"
fi

echo "Backup created: $OUTPUT"
