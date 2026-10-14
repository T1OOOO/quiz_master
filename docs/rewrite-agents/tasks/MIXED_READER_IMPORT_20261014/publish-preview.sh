#!/usr/bin/env bash
# Default is preparation only. Publish only after browser and cross-provider gates.
set -euo pipefail
quiz_mode=${1:-prepare}
[[ "$quiz_mode" = publish ]]
quiz_build=quiz-2026.10.14-reader-17be4ce
test "$(hostname)" = racknerd-f0269d5
cd "/opt/quiz-master/releases/$quiz_build"
chmod 755 api
exec 9>/opt/quiz-master/DEPLOY.lock
flock -n 9
test "$(kubectl get deploy quiz-master -n quiz-master -o jsonpath='{.spec.template.spec.containers[0].image}')" = docker.io/library/quiz-master@sha256:2d1ea6bcb0f92bf62b7173bb23ff0133cfd457ebd4746f08cbcdd73e3f221727
test "$(kubectl get pvc quiz-data -n quiz-master -o jsonpath='{.metadata.uid}')" = 7fc2428f-4146-4c78-a26d-2347d9f3b7bf
sha256sum -c checksums.txt > cutover-checksums.log
echo 'f4d69555623aab2b8e1468fccb65256abefc9823d65214799b7e1475d4d9c850  api' | sha256sum -c -
echo '8dd33980259b5e72b9a2cb208b993d3613812a3e1d874540be360bdcd526aa27  web/main.dart.js' | sha256sum -c -
echo 'e9add812a138010e443463acb455295103dc69886ca32cd17dafbccfa676d6bc  nginx.conf' | sha256sum -c -
echo 'e9add812a138010e443463acb455295103dc69886ca32cd17dafbccfa676d6bc  nginx.conf' | sha256sum -c -
python3 - "$quiz_build" <<'PY'
from pathlib import Path
import json,re,sys
build=sys.argv[1]
meta=json.loads(Path('web/version.json').read_text())
assert re.fullmatch('quiz\-2026\.10\.14\-reader\-17be4ce', build)
assert meta['buildId']==build
assert meta['commit']=='17be4ce706cc27956c09d362cc5dc5803dd53570' and meta['source_commit']=='17be4ce706cc27956c09d362cc5dc5803dd53570'
assert meta['packs']==136 and meta['questions']==4084 and meta['question_articles']==272
assert meta['api_sha256']=='f4d69555623aab2b8e1468fccb65256abefc9823d65214799b7e1475d4d9c850' and meta['main_dart_js_sha256']=='8dd33980259b5e72b9a2cb208b993d3613812a3e1d874540be360bdcd526aa27'
assert meta['taxonomy_id']=='qm-tags-v1' and meta['taxonomy_sha256']=='07e4bbb5c7afcdab3b41a26dca1bf0ba9a830d5f776a98ebceeaeb2bd8356151' and meta['taxonomy_file_sha256']=='98f019902b5cce5161b5980f3338d9cd072b094b0a760fc93adb748832546f8c'
PY

helm status quiz-master -n quiz-master -o json | python3 -c 'import json,sys;x=json.load(sys.stdin);assert x["version"]==53 and x["info"]["status"]=="deployed"'
test "$(df --output=avail -B1 /opt/quiz-master | tail -1)" -gt 4000000000
echo 'ee77b4ccd5b9e05668e7759b8399c8943825f34181b3b480564d941097443812  /var/lib/rancher/k3s/agent/images/quiz-2026.10.14-reader-17be4ce.tar' | sha256sum -c -
echo 'b16795efc754631beef907153dfe83a0f245d1d2d33149579082ead102116b0c  quiz-2026.10.14-reader-17be4ce-cutover-20261014T155409Z-values.yaml' | sha256sum -c -
quiz_digest='sha256:ac4fd7624a22762d2c169c748b8553e1fd31247db7125038b0c72e0afec9bdd4'
quiz_values='quiz-2026.10.14-reader-17be4ce-cutover-20261014T155409Z-values.yaml'
k3s ctr images ls | awk -v image="docker.io/library/quiz-master@$quiz_digest" '$1==image {found=1} END {exit !found}'
quiz_run="$quiz_build-publish-$(date -u +%Y%m%dT%H%M%SZ)"
python3 backup_sqlite.py "/opt/quiz-master/backups/$quiz_run.sqlite"
helm lint --strict chart -n quiz-master -f "$quiz_values"
helm template quiz-master chart -n quiz-master -f "$quiz_values" > "$quiz_run-rendered.yaml"
echo 'a4a26d81d55b90a7614c8bebefc87a5ddd23db21532a5e99983a59ab9cc7dc7b  '"$quiz_run-rendered.yaml" | sha256sum -c -
kubectl apply --dry-run=server -n quiz-master -f "$quiz_run-rendered.yaml"
helm upgrade quiz-master chart -n quiz-master -f "$quiz_values" --atomic --wait --timeout 180s
test "$(kubectl get deploy quiz-master -n quiz-master -o jsonpath='{.spec.template.spec.containers[0].image}')" = "docker.io/library/quiz-master@$quiz_digest"
curl -fsS https://quiz.kotopedia.org/version.json | python3 -c 'import json,sys;assert json.load(sys.stdin)==json.load(open("web/version.json"))'
test "$(curl -fsS https://quiz.kotopedia.org/main.dart.js | sha256sum | cut -d ' ' -f 1)" = 8dd33980259b5e72b9a2cb208b993d3613812a3e1d874540be360bdcd526aa27
test "$(curl -fsS https://quiz.kotopedia.org/assets/assets/study/question-articles.json | sha256sum | cut -d ' ' -f 1)" = 41b7f73493aa96e6153b3a1ff2cf522ead47d8b2c5e7b3240ec95b2f9b4e8e82
printf 'PUBLISHED build=%s image=%s backup=%s\n' "$quiz_build" "$quiz_digest" "$quiz_run"
