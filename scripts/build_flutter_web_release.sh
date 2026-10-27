#!/usr/bin/env bash
set -euo pipefail

# Production Web builds must always receive the API endpoint explicitly.  The
# Dart source intentionally keeps a loopback default for local development.
api_base_url="${QM_API_BASE_URL:-https://quiz.kotopedia.org}"
case "$api_base_url" in
  https://quiz.kotopedia.org) ;;
  *) echo "Refusing production Web build with QM_API_BASE_URL=$api_base_url" >&2; exit 2 ;;
esac

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root/next/apps/quiz_app"
flutter build web --release --no-pub \
  --dart-define="QM_API_BASE_URL=$api_base_url" \
  --pwa-strategy=none

"$repo_root/scripts/verify_flutter_web_api_base.sh" "build/web" "$api_base_url"
