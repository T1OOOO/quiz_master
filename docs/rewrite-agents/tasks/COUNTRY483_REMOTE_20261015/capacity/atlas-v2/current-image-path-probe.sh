set -euo pipefail
test "$(hostname)" = racknerd-f0269d5
test "$(docker image inspect quiz-master:quiz-2026.10.15-reader303-14b7da4 --format '{{.Id}}')" = sha256:6c603a840b01c9c4605eba234e4af3d95a3f52fff12e65d9904b563db5722f14
docker run --rm --network=none --read-only --cap-drop=ALL --security-opt=no-new-privileges --user=10001:10001 --entrypoint sh sha256:6c603a840b01c9c4605eba234e4af3d95a3f52fff12e65d9904b563db5722f14 -c 'test -f /usr/share/nginx/html/assets/assets/quizipedia/catalog.json && test -f /usr/share/nginx/html/assets/assets/quizipedia/manifest.json && test ! -e /app/web && printf "CURRENT_READER303_IMAGE_ATLAS_ROOT_CONFIRMED\n"'
