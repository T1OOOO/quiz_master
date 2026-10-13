#!/usr/bin/env bash
# Default is preparation only. Publish only after browser and cross-provider gates.
set -euo pipefail
quiz_mode=${1:-prepare}
[[ "$quiz_mode" = prepare || "$quiz_mode" = publish ]]
quiz_build=quiz-2026.10.13-film-craft-adf95a5
test "$(hostname)" = racknerd-f0269d5
cd "/opt/quiz-master/releases/$quiz_build"
chmod 755 api
exec 9>/opt/quiz-master/DEPLOY.lock
flock -n 9
test "$(kubectl get deploy quiz-master -n quiz-master -o jsonpath='{.spec.template.spec.containers[0].image}')" = docker.io/library/quiz-master@sha256:8e3c6bd77ab94945093e2ca4394d8364cca9e306b91c791ce2b4461d2a0f0018
test "$(kubectl get pvc quiz-data -n quiz-master -o jsonpath='{.metadata.uid}')" = 7fc2428f-4146-4c78-a26d-2347d9f3b7bf
sha256sum -c checksums.txt > cutover-checksums.log
echo '26e1657fd6259bdbbef9178cbe9343b775406d91c56cb9661d302ad530ab6f01  api' | sha256sum -c -
echo 'c883c9032972fc729feffe33034cd84f5b0f3e8297ae3364257fce6be4fa2296  web/main.dart.js' | sha256sum -c -
echo 'e9add812a138010e443463acb455295103dc69886ca32cd17dafbccfa676d6bc  nginx.conf' | sha256sum -c -
echo 'e9add812a138010e443463acb455295103dc69886ca32cd17dafbccfa676d6bc  nginx.conf' | sha256sum -c -
python3 - "$quiz_build" <<'PY'
from pathlib import Path
import json,re,sys
build=sys.argv[1]
meta=json.loads(Path('web/version.json').read_text())
assert re.fullmatch(r'quiz-2026\.10\.13-film-craft-[0-9a-f]{7}', build)
assert meta['buildId']==build
assert meta['commit']=='adf95a57594158308c94ee2bff1cb5ca9c9c0684' and meta['source_commit']=='adf95a57594158308c94ee2bff1cb5ca9c9c0684'
assert meta['packs']==132 and meta['questions']==4048 and meta['question_articles']==248
PY
test "$(df --output=avail -B1 /opt/quiz-master | tail -1)" -gt 4000000000
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

quiz_digest='sha256:6d2a206a6994b792bcc08fb0c05b5f36cbcb8c6983a6b76088a63471ab75daa6'
quiz_values='quiz-2026.10.13-film-craft-adf95a5-cutover-20261013T180438Z-values.yaml'
echo 'a9a674a644d3ba2955210673e01e401fa9cdfd541a6f6d8aa6986c2d73eccbf3  /var/lib/rancher/k3s/agent/images/quiz-2026.10.13-film-craft-adf95a5.tar' | sha256sum -c -
k3s ctr images ls | awk -v image="docker.io/library/quiz-master@$quiz_digest" '$1==image {found=1} END {exit !found}'
helm lint --strict chart -n quiz-master -f "$quiz_values"
helm template quiz-master chart -n quiz-master -f "$quiz_values" > "$quiz_run-publish-rendered.yaml"
test "$(grep -Fc "docker.io/library/quiz-master@$quiz_digest" "$quiz_run-publish-rendered.yaml")" -eq 2
kubectl apply --dry-run=server -n quiz-master -f "$quiz_run-publish-rendered.yaml"
helm upgrade quiz-master chart -n quiz-master -f "$quiz_values" --atomic --wait --timeout 180s
test "$(kubectl get deploy quiz-master -n quiz-master -o jsonpath='{.spec.template.spec.containers[0].image}')" = "docker.io/library/quiz-master@$quiz_digest"
curl -fsS https://quiz.kotopedia.org/version.json | python3 -c 'import json,sys; actual=json.load(sys.stdin); expected=json.load(open("web/version.json")); actual==expected or sys.exit("Public version mismatch"); print(actual)'
test "$(curl -fsS https://quiz.kotopedia.org/main.dart.js | sha256sum | cut -d ' ' -f 1)" = c883c9032972fc729feffe33034cd84f5b0f3e8297ae3364257fce6be4fa2296
test "$(curl -fsS https://quiz.kotopedia.org/assets/assets/study/question-articles.json | sha256sum | cut -d ' ' -f 1)" = d56144d16d2307cf581f64d55e146381f165726de0d6a59c99250e43901ebb07
