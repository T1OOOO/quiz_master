#!/usr/bin/env bash
# Default is preparation only. Publish only after browser and cross-provider gates.
set -euo pipefail
quiz_mode=${1:-prepare}
[[ "$quiz_mode" = publish ]]
quiz_build=quiz-2026.10.14-acting-craft-83748f5
test "$(hostname)" = racknerd-f0269d5
cd "/opt/quiz-master/releases/$quiz_build"
chmod 755 api
exec 9>/opt/quiz-master/DEPLOY.lock
flock -n 9
test "$(kubectl get deploy quiz-master -n quiz-master -o jsonpath='{.spec.template.spec.containers[0].image}')" = docker.io/library/quiz-master@sha256:b94a399359f87024f5b00a53c47852a3e8f90f1ba6f4bb861385e9c2655f17d7
test "$(kubectl get pvc quiz-data -n quiz-master -o jsonpath='{.metadata.uid}')" = 7fc2428f-4146-4c78-a26d-2347d9f3b7bf
sha256sum -c checksums.txt > cutover-checksums.log
echo '26e1657fd6259bdbbef9178cbe9343b775406d91c56cb9661d302ad530ab6f01  api' | sha256sum -c -
echo 'a091340ebda85029c7f6d33fe382800d113feb9422c1b77f7647b6901223513a  web/main.dart.js' | sha256sum -c -
echo 'e9add812a138010e443463acb455295103dc69886ca32cd17dafbccfa676d6bc  nginx.conf' | sha256sum -c -
echo 'e9add812a138010e443463acb455295103dc69886ca32cd17dafbccfa676d6bc  nginx.conf' | sha256sum -c -
python3 - "$quiz_build" <<'PY'
from pathlib import Path
import json,re,sys
build=sys.argv[1]
meta=json.loads(Path('web/version.json').read_text())
assert re.fullmatch(r'quiz-2026\.10\.14-acting-craft-[0-9a-f]{7}', build)
assert meta['buildId']==build
assert meta['commit']=='83748f5a467092302184bcbeee1bd1d7d4b964fa' and meta['source_commit']=='83748f5a467092302184bcbeee1bd1d7d4b964fa'
assert meta['packs']==134 and meta['questions']==4060 and meta['question_articles']==260
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

quiz_digest='sha256:039474ddb2feac0986908a7681c18fcf39cb716428e9c8acf199e8f9e044c961'
quiz_values='quiz-2026.10.14-acting-craft-83748f5-cutover-20261013T230853Z-values.yaml'
echo 'ae11582ea734404812c250ef044ccb51dc2e35f49263d88d1a42285c409dab35  /var/lib/rancher/k3s/agent/images/quiz-2026.10.14-acting-craft-83748f5.tar' | sha256sum -c -
k3s ctr images ls | awk -v image="docker.io/library/quiz-master@$quiz_digest" '$1==image {found=1} END {exit !found}'
helm lint --strict chart -n quiz-master -f "$quiz_values"
helm template quiz-master chart -n quiz-master -f "$quiz_values" > "$quiz_run-publish-rendered.yaml"
test "$(grep -Fc "docker.io/library/quiz-master@$quiz_digest" "$quiz_run-publish-rendered.yaml")" -eq 2
kubectl apply --dry-run=server -n quiz-master -f "$quiz_run-publish-rendered.yaml"
helm upgrade quiz-master chart -n quiz-master -f "$quiz_values" --atomic --wait --timeout 180s
test "$(kubectl get deploy quiz-master -n quiz-master -o jsonpath='{.spec.template.spec.containers[0].image}')" = "docker.io/library/quiz-master@$quiz_digest"
curl -fsS https://quiz.kotopedia.org/version.json | python3 -c 'import json,sys; actual=json.load(sys.stdin); expected=json.load(open("web/version.json")); actual==expected or sys.exit("Public version mismatch"); print(actual)'
test "$(curl -fsS https://quiz.kotopedia.org/main.dart.js | sha256sum | cut -d ' ' -f 1)" = a091340ebda85029c7f6d33fe382800d113feb9422c1b77f7647b6901223513a
test "$(curl -fsS https://quiz.kotopedia.org/assets/assets/study/question-articles.json | sha256sum | cut -d ' ' -f 1)" = af443be9c529dc61c30a3edd9b51327e084dccfd2a69dc88d44aac152b1b4633
