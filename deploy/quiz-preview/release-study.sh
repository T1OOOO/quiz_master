#!/usr/bin/env bash
# Runtime-only release on the existing node; no source compilation or edge changes.
set -euo pipefail
quiz_build=${1:?build ID required}
[[ "$quiz_build" =~ ^quiz-2026\.10\.04-study-[a-f0-9]{7,12}$ ]]
test "$(hostname)" = racknerd-f0269d5
cd "/opt/quiz-master/releases/$quiz_build"
exec 9>/opt/quiz-master/DEPLOY.lock
flock -n 9
# Abort if another deployment changed the baseline after our preflight.
test "$(kubectl get deploy quiz-master -n quiz-master -o jsonpath='{.spec.template.spec.containers[0].image}')" = 'docker.io/library/quiz-master@sha256:6fd3e6d90203198b5a03975d9b3b6387821b504ae20a1bf63212ac8afd044b59'
sha256sum -c checksums.txt
python3 backup_sqlite.py "/opt/quiz-master/backups/$quiz_build.sqlite"
docker build --network=none --pull=false -t "quiz-master:$quiz_build" .
docker run --rm --network=none --read-only --tmpfs /tmp "quiz-master:$quiz_build" nginx -t
docker save "quiz-master:$quiz_build" | k3s ctr images import -
quiz_digest=$(k3s ctr images ls | awk -v tag="docker.io/library/quiz-master:$quiz_build" '$1==tag {print $3}')
[[ "$quiz_digest" =~ ^sha256:[a-f0-9]{64}$ ]]
k3s ctr images tag "docker.io/library/quiz-master:$quiz_build" "docker.io/library/quiz-master@$quiz_digest"
sed -i "s|^image:.*|image: docker.io/library/quiz-master@$quiz_digest|;s|^buildId:.*|buildId: $quiz_build|" release-values.yaml
helm lint --strict chart -n quiz-master -f release-values.yaml
helm template quiz-master chart -n quiz-master -f release-values.yaml > rendered.yaml
kubectl apply --dry-run=server -n quiz-master -f rendered.yaml
helm upgrade quiz-master chart -n quiz-master -f release-values.yaml --atomic --wait --timeout 180s
kubectl get deploy,pods,pvc -n quiz-master
test "$(kubectl get deploy quiz-master -n quiz-master -o jsonpath='{.spec.template.spec.containers[0].image}')" = "docker.io/library/quiz-master@$quiz_digest"
curl -fsS https://quiz.kotopedia.org/version.json | python3 -c 'import json,sys; actual=json.load(sys.stdin); expected=json.load(open("web/version.json")); (actual==expected and actual.get("buildId")==sys.argv[1]) or sys.exit("Public version mismatch"); print(actual)' "$quiz_build"
test "$(curl -fsS https://quiz.kotopedia.org/main.dart.js | sha256sum | cut -d ' ' -f 1)" = "$(sha256sum web/main.dart.js | cut -d ' ' -f 1)"
