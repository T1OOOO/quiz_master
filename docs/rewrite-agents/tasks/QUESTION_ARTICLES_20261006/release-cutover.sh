#!/usr/bin/env bash
# Default is preparation only. Publish only after browser and cross-provider gates.
set -euo pipefail
quiz_mode=${1:-prepare}
[[ "$quiz_mode" = prepare || "$quiz_mode" = publish ]]
quiz_build=quiz-2026.10.07-articles-30702d1
test "$(hostname)" = racknerd-f0269d5
cd "/opt/quiz-master/releases/$quiz_build"
exec 9>/opt/quiz-master/DEPLOY.lock
flock -n 9
test "$(kubectl get deploy quiz-master -n quiz-master -o jsonpath='{.spec.template.spec.containers[0].image}')" = docker.io/library/quiz-master@sha256:de8c71716add4f88aa678abb8a7b05e1a649b3c94f86befd3a406c94662af4e2
test "$(kubectl get pvc quiz-data -n quiz-master -o jsonpath='{.metadata.uid}')" = 7fc2428f-4146-4c78-a26d-2347d9f3b7bf
sha256sum -c checksums.txt > cutover-checksums.log
echo 'edb8e1d7c0c38bb16e6173a9fba19826870927398d5c608a97c41f08a2bb982f  api' | sha256sum -c -
echo '7fdb4d8909cb551c7a873125982507e6e55e71b55477222f2c83c18b6a691811  web/main.dart.js' | sha256sum -c -
test -f "/opt/quiz-master/backups/$quiz_build.sqlite"
test -d rehearsal-final
quiz_run="$quiz_build-cutover-$(date -u +%Y%m%dT%H%M%SZ)"
python3 backup_sqlite.py "/opt/quiz-master/backups/$quiz_run.sqlite"
python3 - "$quiz_run" <<'PY'
from pathlib import Path
import re,sys
run=sys.argv[1]
assert re.fullmatch(r'quiz-2026\.10\.07-articles-30702d1-cutover-\d{8}T\d{6}Z',run)
s=Path('rehearse.py').read_text()
a="sandbox=root/'rehearsal-final'"
b="'/opt/quiz-master/backups/'+build+'.sqlite'"
c="sqlite:rehearsal-final/quiz.sqlite"
assert s.count(a)==1 and s.count(b)==1 and s.count(c)==1
s=s.replace(a,"sandbox=root/"+repr('rehearsal-'+run)).replace(b,repr('/opt/quiz-master/backups/'+run+'.sqlite'))
s=s.replace(c,'sqlite:rehearsal-'+run+'/quiz.sqlite')
p=Path('rehearse-'+run+'.py')
with p.open('x') as f:f.write(s)
PY
python3 "rehearse-$quiz_run.py" "$quiz_build" | tee "$quiz_run-rehearsal.json"
quiz_image="quiz-master:$quiz_build"
docker build --network=none --pull=false -t "$quiz_image" .
docker run --rm --network=none --read-only --entrypoint sha256sum "$quiz_image" /app/api | grep '^edb8e1d7c0c38bb16e6173a9fba19826870927398d5c608a97c41f08a2bb982f '
docker run --rm --network=none --read-only --entrypoint sha256sum "$quiz_image" /usr/share/nginx/html/main.dart.js | grep '^7fdb4d8909cb551c7a873125982507e6e55e71b55477222f2c83c18b6a691811 '
docker run --rm --network=none --read-only --tmpfs /tmp "$quiz_image" nginx -t
docker save "$quiz_image" | k3s ctr images import -
quiz_digest=$(k3s ctr images ls | awk -v tag="docker.io/library/$quiz_image" '$1==tag {print $3}')
[[ "$quiz_digest" =~ ^sha256:[a-f0-9]{64}$ ]]
k3s ctr images tag --force "docker.io/library/$quiz_image" "docker.io/library/quiz-master@$quiz_digest"
quiz_values="$quiz_run-values.yaml"
cp --no-clobber release-values.yaml "$quiz_values"
sed -i "s|^image:.*|image: docker.io/library/quiz-master@$quiz_digest|;s|^buildId:.*|buildId: $quiz_build|" "$quiz_values"
helm lint --strict chart -n quiz-master -f "$quiz_values"
helm template quiz-master chart -n quiz-master -f "$quiz_values" > "$quiz_run-rendered.yaml"
kubectl apply --dry-run=server -n quiz-master -f "$quiz_run-rendered.yaml"
printf 'PREPARED build=%s image=%s values=%s mode=%s\n' "$quiz_build" "$quiz_digest" "$quiz_values" "$quiz_mode"
if [[ "$quiz_mode" = prepare ]]; then exit 0; fi
helm upgrade quiz-master chart -n quiz-master -f "$quiz_values" --atomic --wait --timeout 180s
test "$(kubectl get deploy quiz-master -n quiz-master -o jsonpath='{.spec.template.spec.containers[0].image}')" = "docker.io/library/quiz-master@$quiz_digest"
curl -fsS https://quiz.kotopedia.org/version.json | python3 -c 'import json,sys; actual=json.load(sys.stdin); expected=json.load(open("web/version.json")); actual==expected or sys.exit("Public version mismatch"); print(actual)'
test "$(curl -fsS https://quiz.kotopedia.org/main.dart.js | sha256sum | cut -d ' ' -f 1)" = 7fdb4d8909cb551c7a873125982507e6e55e71b55477222f2c83c18b6a691811
