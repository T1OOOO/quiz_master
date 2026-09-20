#!/usr/bin/env bash
set -u

scan() {
  local root=$1 status marker
  local markers=(private_grading accepted_variants correct_option_id correct_option_ids published_bundle '"draft"')
  for marker in "${markers[@]}"; do
    if grep -R -F -n -- "$marker" "$root"; then
      return 10
    else
      status=$?
      if [ "$status" -eq 1 ]; then
        continue
      fi
      return "$status"
    fi
  done
}

temp=$(mktemp -d)
trap 'rm -rf "$temp"' EXIT
mkdir -p "$temp/clean" "$temp/matched"

scan "$temp/clean"
clean_status=$?
printf 'clean=%s\n' "$clean_status"
[ "$clean_status" -eq 0 ]

printf 'const marker = "published_bundle";\n' > "$temp/matched/app.js"
if scan "$temp/matched"; then
  echo 'matched=unexpected-clean' >&2
  exit 1
else
  matched_status=$?
fi
printf 'matched=%s\n' "$matched_status"
[ "$matched_status" -eq 10 ]

if scan "$temp/missing"; then
  echo 'scanner_error=unexpected-clean' >&2
  exit 1
else
  error_status=$?
fi
printf 'scanner_error=%s\n' "$error_status"
[ "$error_status" -gt 1 ]
