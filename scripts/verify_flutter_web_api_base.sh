#!/usr/bin/env bash
set -euo pipefail

web_dir="${1:?web output directory required}"
expected="${2:?expected API base URL required}"
js="$web_dir/main.dart.js"
test -f "$js"

case "$expected" in
  https://quiz.kotopedia.org) ;;
  *) echo "Unsupported production API base: $expected" >&2; exit 2 ;;
esac

if grep -E -q 'https?://(127\.0\.0\.1|localhost|0\.0\.0|\[::1\])' "$js"; then
  echo "Production Web artifact contains a loopback API URL: $js" >&2
  exit 1
fi
grep -F -q "$expected" "$js"
echo "Flutter Web API base guard passed: $expected"
