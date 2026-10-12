#!/usr/bin/env bash
# Default is preparation only. Publish only after browser and cross-provider gates.
set -euo pipefail
quiz_mode=${1:-prepare}
[[ "$quiz_mode" = prepare || "$quiz_mode" = publish ]]
quiz_build=quiz-2026.10.13-culture-384d798
test "$(hostname)" = racknerd-f0269d5
cd "/opt/quiz-master/releases/$quiz_build"
chmod 755 api
exec 9>/opt/quiz-master/DEPLOY.lock
flock -n 9
test "$(kubectl get deploy quiz-master -n quiz-master -o jsonpath='{.spec.template.spec.containers[0].image}')" = docker.io/library/quiz-master@sha256:ee2b454c486c65d8e8ca7bc343f01736d78284871de39b62dc6260b19afcfbb1
test "$(kubectl get pvc quiz-data -n quiz-master -o jsonpath='{.metadata.uid}')" = 7fc2428f-4146-4c78-a26d-2347d9f3b7bf
sha256sum -c checksums.txt > cutover-checksums.log
echo '26e1657fd6259bdbbef9178cbe9343b775406d91c56cb9661d302ad530ab6f01  api' | sha256sum -c -
echo '1986ff2b6c73766652eafadf37fb79e58deee89b1878d1af90a6c6c43ec9ade4  web/main.dart.js' | sha256sum -c -
python3 - "$quiz_build" <<'PY'
from pathlib import Path
import json,re,sys
build=sys.argv[1]
meta=json.loads(Path('web/version.json').read_text())
assert re.fullmatch(r'quiz-2026\.10\.13-culture-[0-9a-f]{7}', build)
assert meta['buildId']==build
assert meta['commit']=='384d798a8c681f4940448877f18900cfb511d04a' and meta['source_commit']=='384d798a8c681f4940448877f18900cfb511d04a'
assert meta['packs']==131 and meta['questions']==4032 and meta['question_articles']==230
PY
quiz_run="$quiz_build-cutover-$(date -u +%Y%m%dT%H%M%SZ)"
python3 backup_sqlite.py "/opt/quiz-master/backups/$quiz_run.sqlite"
python3 - "$quiz_run" "$quiz_build" <<'PY'
from pathlib import Path
import re,sys
run, build = sys.argv[1:3]
assert re.fullmatch(re.escape(build) + r'-cutover-\d{8}T\d{6}Z', run)
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

quiz_digest='sha256:b3700cb1ccb2adfcfcb117b659b856b261d11ae5336c9e632fec2c839a08dcbc'
quiz_values='quiz-2026.10.13-culture-384d798-cutover-20261012T222554Z-values.yaml'
echo '23ff0eee496efea8d035747404037f297f058689592e01af62bf646d9bbf081b  /var/lib/rancher/k3s/agent/images/quiz-2026.10.13-culture-384d798.tar' | sha256sum -c -
k3s ctr images ls | awk -v image="docker.io/library/quiz-master@$quiz_digest" '$1==image {found=1} END {exit !found}'
helm lint --strict chart -n quiz-master -f "$quiz_values"
helm template quiz-master chart -n quiz-master -f "$quiz_values" > "$quiz_run-publish-rendered.yaml"
test "$(grep -Fc "docker.io/library/quiz-master@$quiz_digest" "$quiz_run-publish-rendered.yaml")" -eq 2
kubectl apply --dry-run=server -n quiz-master -f "$quiz_run-publish-rendered.yaml"
helm upgrade quiz-master chart -n quiz-master -f "$quiz_values" --atomic --wait --timeout 180s
test "$(kubectl get deploy quiz-master -n quiz-master -o jsonpath='{.spec.template.spec.containers[0].image}')" = "docker.io/library/quiz-master@$quiz_digest"
curl -fsS https://quiz.kotopedia.org/version.json | python3 -c 'import json,sys; actual=json.load(sys.stdin); expected=json.load(open("web/version.json")); actual==expected or sys.exit("Public version mismatch"); print(actual)'
test "$(curl -fsS https://quiz.kotopedia.org/main.dart.js | sha256sum | cut -d ' ' -f 1)" = 1986ff2b6c73766652eafadf37fb79e58deee89b1878d1af90a6c6c43ec9ade4
