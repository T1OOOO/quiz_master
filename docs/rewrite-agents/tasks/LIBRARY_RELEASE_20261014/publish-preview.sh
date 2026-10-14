#!/usr/bin/env bash
# Default is preparation only. Publish only after browser and cross-provider gates.
set -euo pipefail
quiz_mode=${1:-prepare}
[[ "$quiz_mode" = publish ]]
quiz_build=quiz-2026.10.14-library-09b19cc
test "$(hostname)" = racknerd-f0269d5
cd "/opt/quiz-master/releases/$quiz_build"
chmod 755 api
exec 9>/opt/quiz-master/DEPLOY.lock
flock -n 9
test "$(kubectl get deploy quiz-master -n quiz-master -o jsonpath='{.spec.template.spec.containers[0].image}')" = docker.io/library/quiz-master@sha256:ac4fd7624a22762d2c169c748b8553e1fd31247db7125038b0c72e0afec9bdd4
test "$(kubectl get pvc quiz-data -n quiz-master -o jsonpath='{.metadata.uid}')" = 7fc2428f-4146-4c78-a26d-2347d9f3b7bf
sha256sum -c checksums.txt > cutover-checksums.log
echo 'f4d69555623aab2b8e1468fccb65256abefc9823d65214799b7e1475d4d9c850  api' | sha256sum -c -
echo '0c34332e394327aafa3ab6d158d35cf898931aac548af7a2763221d73ebd24cd  web/main.dart.js' | sha256sum -c -
echo 'e9add812a138010e443463acb455295103dc69886ca32cd17dafbccfa676d6bc  nginx.conf' | sha256sum -c -
echo 'e9add812a138010e443463acb455295103dc69886ca32cd17dafbccfa676d6bc  nginx.conf' | sha256sum -c -
python3 - "$quiz_build" <<'PY'
from pathlib import Path
import json,re,sys
build=sys.argv[1]
meta=json.loads(Path('web/version.json').read_text())
assert build=='quiz-2026.10.14-library-09b19cc'
assert meta['buildId']==build
assert meta['commit']=='09b19cc2d0fa8463a3e53e9a5f51981e657e2a48' and meta['source_commit']=='09b19cc2d0fa8463a3e53e9a5f51981e657e2a48'
assert meta['packs']==136 and meta['questions']==4084 and meta['question_articles']==278
assert meta['api_sha256']=='f4d69555623aab2b8e1468fccb65256abefc9823d65214799b7e1475d4d9c850' and meta['main_dart_js_sha256']=='0c34332e394327aafa3ab6d158d35cf898931aac548af7a2763221d73ebd24cd'
assert meta['taxonomy_id']=='qm-tags-v1' and meta['taxonomy_sha256']=='07e4bbb5c7afcdab3b41a26dca1bf0ba9a830d5f776a98ebceeaeb2bd8356151' and meta['taxonomy_file_sha256']=='98f019902b5cce5161b5980f3338d9cd072b094b0a760fc93adb748832546f8c'
PY

helm status quiz-master -n quiz-master -o json | python3 -c 'import json,sys;x=json.load(sys.stdin);assert x["version"]==54 and x["info"]["status"]=="deployed"'
test "$(df --output=avail -B1 /opt/quiz-master | tail -1)" -gt 4000000000
echo '7d4566aab0df18b6a879ac94115e5b146ebcc1252ad7bef038d8ef1f37279b79  /var/lib/rancher/k3s/agent/images/quiz-2026.10.14-library-09b19cc.tar' | sha256sum -c -
echo 'a2ba0075c44fcf19b08878ae79d406067e88c27b6792416ef7120cd5ec047c06  quiz-2026.10.14-library-09b19cc-cutover-20261014T205022Z-values.yaml' | sha256sum -c -
quiz_digest='sha256:4878f824f4b0fb23fa20a8f246541ca4dfa7a1750715f64176cfba4faead0a50'
quiz_values='quiz-2026.10.14-library-09b19cc-cutover-20261014T205022Z-values.yaml'
k3s ctr images ls | awk -v image="docker.io/library/quiz-master@$quiz_digest" '$1==image {found=1} END {exit !found}'
quiz_run="$quiz_build-publish-$(date -u +%Y%m%dT%H%M%SZ)"
python3 backup_sqlite.py "/opt/quiz-master/backups/$quiz_run.sqlite"
helm lint --strict chart -n quiz-master -f "$quiz_values"
helm template quiz-master chart -n quiz-master -f "$quiz_values" > "$quiz_run-rendered.yaml"
echo 'bdc488634c554a264c567f41220ed8a3834ea48111a48b21c0e30526a4c9ac75  '"$quiz_run-rendered.yaml" | sha256sum -c -
kubectl apply --dry-run=server -n quiz-master -f "$quiz_run-rendered.yaml"
helm upgrade quiz-master chart -n quiz-master -f "$quiz_values" --atomic --wait --timeout 180s
test "$(kubectl get deploy quiz-master -n quiz-master -o jsonpath='{.spec.template.spec.containers[0].image}')" = "docker.io/library/quiz-master@$quiz_digest"
curl -fsS https://quiz.kotopedia.org/version.json | python3 -c 'import json,sys;assert json.load(sys.stdin)==json.load(open("web/version.json"))'
test "$(curl -fsS https://quiz.kotopedia.org/main.dart.js | sha256sum | cut -d ' ' -f 1)" = 0c34332e394327aafa3ab6d158d35cf898931aac548af7a2763221d73ebd24cd
test "$(curl -fsS https://quiz.kotopedia.org/assets/assets/study/question-articles.json | sha256sum | cut -d ' ' -f 1)" = 7fc2b6a1bac73847f75de1c5617cf055d645eb6a1466c9780477bc07c31abd74
printf 'PUBLISHED build=%s image=%s backup=%s\n' "$quiz_build" "$quiz_digest" "$quiz_run"
