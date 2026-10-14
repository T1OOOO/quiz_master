#!/usr/bin/env bash
# Default is preparation only. Publish only after browser and cross-provider gates.
set -euo pipefail
quiz_mode=${1:-prepare}
[[ "$quiz_mode" = publish ]]
quiz_build=quiz-2026.10.14-screen-song-6866608
test "$(hostname)" = racknerd-f0269d5
cd "/opt/quiz-master/releases/$quiz_build"
chmod 755 api
exec 9>/opt/quiz-master/DEPLOY.lock
flock -n 9
test "$(kubectl get deploy quiz-master -n quiz-master -o jsonpath='{.spec.template.spec.containers[0].image}')" = docker.io/library/quiz-master@sha256:039474ddb2feac0986908a7681c18fcf39cb716428e9c8acf199e8f9e044c961
test "$(kubectl get pvc quiz-data -n quiz-master -o jsonpath='{.metadata.uid}')" = 7fc2428f-4146-4c78-a26d-2347d9f3b7bf
sha256sum -c checksums.txt > cutover-checksums.log
echo '26e1657fd6259bdbbef9178cbe9343b775406d91c56cb9661d302ad530ab6f01  api' | sha256sum -c -
echo 'aed8b728b1d019b86432075f96c6fec48414fc8351079c1f9c53519e0e4373e9  web/main.dart.js' | sha256sum -c -
echo 'e9add812a138010e443463acb455295103dc69886ca32cd17dafbccfa676d6bc  nginx.conf' | sha256sum -c -
echo 'e9add812a138010e443463acb455295103dc69886ca32cd17dafbccfa676d6bc  nginx.conf' | sha256sum -c -
python3 - "$quiz_build" <<'PY'
from pathlib import Path
import json,re,sys
build=sys.argv[1]
meta=json.loads(Path('web/version.json').read_text())
assert re.fullmatch(r'quiz-2026\.10\.14-screen-song-[0-9a-f]{7}', build)
assert meta['buildId']==build
assert meta['commit']=='6866608bd7c20ceff2b454970b315eaee86329a9' and meta['source_commit']=='6866608bd7c20ceff2b454970b315eaee86329a9'
assert meta['packs']==135 and meta['questions']==4064 and meta['question_articles']==264
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

quiz_digest='sha256:a97cf777b2015c595fd1307017246a2806cce597e0233da75e496a433761e074'
quiz_values='quiz-2026.10.14-screen-song-6866608-cutover-20261014T024810Z-values.yaml'
echo 'df721bb780a7d4253dd6c5fa529cf2c1a389ae2c95b7794cb3145bff0a03dacb  /var/lib/rancher/k3s/agent/images/quiz-2026.10.14-screen-song-6866608.tar' | sha256sum -c -
k3s ctr images ls | awk -v image="docker.io/library/quiz-master@$quiz_digest" '$1==image {found=1} END {exit !found}'
helm lint --strict chart -n quiz-master -f "$quiz_values"
helm template quiz-master chart -n quiz-master -f "$quiz_values" > "$quiz_run-publish-rendered.yaml"
test "$(grep -Fc "docker.io/library/quiz-master@$quiz_digest" "$quiz_run-publish-rendered.yaml")" -eq 2
kubectl apply --dry-run=server -n quiz-master -f "$quiz_run-publish-rendered.yaml"
helm upgrade quiz-master chart -n quiz-master -f "$quiz_values" --atomic --wait --timeout 180s
test "$(kubectl get deploy quiz-master -n quiz-master -o jsonpath='{.spec.template.spec.containers[0].image}')" = "docker.io/library/quiz-master@$quiz_digest"
curl -fsS https://quiz.kotopedia.org/version.json | python3 -c 'import json,sys; actual=json.load(sys.stdin); expected=json.load(open("web/version.json")); actual==expected or sys.exit("Public version mismatch"); print(actual)'
test "$(curl -fsS https://quiz.kotopedia.org/main.dart.js | sha256sum | cut -d ' ' -f 1)" = aed8b728b1d019b86432075f96c6fec48414fc8351079c1f9c53519e0e4373e9
test "$(curl -fsS https://quiz.kotopedia.org/assets/assets/study/question-articles.json | sha256sum | cut -d ' ' -f 1)" = a58255548240b489873d8ad944522a53757454627081b76e11d6031f35776c14
