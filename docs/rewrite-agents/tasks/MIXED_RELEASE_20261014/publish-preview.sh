#!/usr/bin/env bash
# Default is preparation only. Publish only after browser and cross-provider gates.
set -euo pipefail
quiz_mode=${1:-prepare}
[[ "$quiz_mode" = publish ]]
quiz_build=quiz-2026.10.14-mixed-ecac092
test "$(hostname)" = racknerd-f0269d5
cd "/opt/quiz-master/releases/$quiz_build"
chmod 755 api
exec 9>/opt/quiz-master/DEPLOY.lock
flock -n 9
test "$(kubectl get deploy quiz-master -n quiz-master -o jsonpath='{.spec.template.spec.containers[0].image}')" = docker.io/library/quiz-master@sha256:a97cf777b2015c595fd1307017246a2806cce597e0233da75e496a433761e074
test "$(kubectl get pvc quiz-data -n quiz-master -o jsonpath='{.metadata.uid}')" = 7fc2428f-4146-4c78-a26d-2347d9f3b7bf
sha256sum -c checksums.txt > cutover-checksums.log
echo 'f4d69555623aab2b8e1468fccb65256abefc9823d65214799b7e1475d4d9c850  api' | sha256sum -c -
echo '25bc17ea0e2901bb1e64213ae8c719e7104a14db279b9b923946d996bb26b18c  web/main.dart.js' | sha256sum -c -
echo 'e9add812a138010e443463acb455295103dc69886ca32cd17dafbccfa676d6bc  nginx.conf' | sha256sum -c -
echo 'e9add812a138010e443463acb455295103dc69886ca32cd17dafbccfa676d6bc  nginx.conf' | sha256sum -c -
python3 - "$quiz_build" <<'PY'
from pathlib import Path
import json,re,sys
build=sys.argv[1]
meta=json.loads(Path('web/version.json').read_text())
assert re.fullmatch('quiz\\-2026\\.10\\.14\\-mixed\\-ecac092', build)
assert meta['buildId']==build
assert meta['commit']=='ecac092a9ab9af5ac39b4879b8249675b3cca9a2' and meta['source_commit']=='ecac092a9ab9af5ac39b4879b8249675b3cca9a2'
assert meta['packs']==136 and meta['questions']==4084 and meta['question_articles']==266
PY

helm status quiz-master -n quiz-master -o json | python3 -c 'import json,sys;x=json.load(sys.stdin);assert x["version"]==52 and x["info"]["status"]=="deployed"'
test "$(df --output=avail -B1 /opt/quiz-master | tail -1)" -gt 4000000000
echo 'ee7c913e5b75764452488f39b18ce3b2d0e34bf0767070112c2e979dcf666d68  /var/lib/rancher/k3s/agent/images/quiz-2026.10.14-mixed-ecac092.tar' | sha256sum -c -
echo '1d1923fee844152b96b0117217dd04017e477621713aa8279cb2b08a867cc84f  quiz-2026.10.14-mixed-ecac092-cutover-20261014T114748Z-values.yaml' | sha256sum -c -
quiz_digest='sha256:2d1ea6bcb0f92bf62b7173bb23ff0133cfd457ebd4746f08cbcdd73e3f221727'
quiz_values='quiz-2026.10.14-mixed-ecac092-cutover-20261014T114748Z-values.yaml'
k3s ctr images ls | awk -v image="docker.io/library/quiz-master@$quiz_digest" '$1==image {found=1} END {exit !found}'
quiz_run="$quiz_build-publish-$(date -u +%Y%m%dT%H%M%SZ)"
python3 backup_sqlite.py "/opt/quiz-master/backups/$quiz_run.sqlite"
helm lint --strict chart -n quiz-master -f "$quiz_values"
helm template quiz-master chart -n quiz-master -f "$quiz_values" > "$quiz_run-rendered.yaml"
echo '9406b6b036ff30ff37701477f3e15cb59871815339e5c6d427b7a7bf8757c7c0  '"$quiz_run-rendered.yaml" | sha256sum -c -
kubectl apply --dry-run=server -n quiz-master -f "$quiz_run-rendered.yaml"
helm upgrade quiz-master chart -n quiz-master -f "$quiz_values" --atomic --wait --timeout 180s
test "$(kubectl get deploy quiz-master -n quiz-master -o jsonpath='{.spec.template.spec.containers[0].image}')" = "docker.io/library/quiz-master@$quiz_digest"
curl -fsS https://quiz.kotopedia.org/version.json | python3 -c 'import json,sys;assert json.load(sys.stdin)==json.load(open("web/version.json"))'
test "$(curl -fsS https://quiz.kotopedia.org/main.dart.js | sha256sum | cut -d ' ' -f 1)" = 25bc17ea0e2901bb1e64213ae8c719e7104a14db279b9b923946d996bb26b18c
test "$(curl -fsS https://quiz.kotopedia.org/assets/assets/study/question-articles.json | sha256sum | cut -d ' ' -f 1)" = efe902040347192eebc3c494e42b672ae1c3832c784bd51e9ca14f28378cd419
printf 'PUBLISHED build=%s image=%s backup=%s\n' "$quiz_build" "$quiz_digest" "$quiz_run"
