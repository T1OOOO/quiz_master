#!/usr/bin/env bash
# Default is preparation only. Publish only after browser and cross-provider gates.
set -euo pipefail
quiz_preflight() {
test "$(hostname)" = racknerd-f0269d5
python3 - <<'QUIZ_PREFLIGHT'
import json,os,subprocess,urllib.request
helm=json.loads(subprocess.check_output(['helm','status','quiz-master','-n','quiz-master','-o','json']))
assert helm['version']==60 and helm['info']['status']=='deployed'
deploy=json.loads(subprocess.check_output(['kubectl','get','deploy','quiz-master','-n','quiz-master','-o','json']))
images=[c['image'] for c in deploy['spec']['template']['spec']['containers']]
assert len(images)==2 and set(images)=={'docker.io/library/quiz-master@sha256:c4b5ba6564678b986bc74cb59b3d660e14bfc733a5633eab83c8d47cbffa4922'}
assert deploy['status'].get('availableReplicas')==1
pvc=json.loads(subprocess.check_output(['kubectl','get','pvc','quiz-data','-n','quiz-master','-o','json']))
assert pvc['metadata']['uid']=='7fc2428f-4146-4c78-a26d-2347d9f3b7bf'
nodes=json.loads(subprocess.check_output(['kubectl','get','nodes','-o','json']))['items']
assert len(nodes)==1
node=nodes[0];conditions={c['type']:c['status'] for c in node['status']['conditions']}
assert conditions.get('Ready')=='True' and conditions.get('DiskPressure')=='False'
assert not node.get('spec',{}).get('unschedulable',False)
assert not any(t.get('effect') in ('NoSchedule','NoExecute') for t in node.get('spec',{}).get('taints',[]))
usage=os.statvfs('/var/lib/rancher/k3s/agent/containerd')
assert usage.f_bavail*usage.f_frsize*5>=usage.f_blocks*usage.f_frsize
with urllib.request.urlopen('https://quiz.kotopedia.org/health/ready',timeout=15) as response: assert response.status==200
QUIZ_PREFLIGHT
}
quiz_mode=${1:-prepare}
[[ "$quiz_mode" = publish ]]
quiz_build=quiz-2026.10.15-reader291-3482af9
test "$(hostname)" = racknerd-f0269d5
cd "/opt/quiz-master/releases/$quiz_build"
chmod 755 api
exec 9>/opt/quiz-master/DEPLOY.lock
flock -n 9
quiz_preflight
test "$(kubectl get deploy quiz-master -n quiz-master -o jsonpath='{.spec.template.spec.containers[0].image}')" = docker.io/library/quiz-master@sha256:c4b5ba6564678b986bc74cb59b3d660e14bfc733a5633eab83c8d47cbffa4922
test "$(kubectl get pvc quiz-data -n quiz-master -o jsonpath='{.metadata.uid}')" = 7fc2428f-4146-4c78-a26d-2347d9f3b7bf
sha256sum -c checksums.txt > cutover-checksums.log
echo 'f4d69555623aab2b8e1468fccb65256abefc9823d65214799b7e1475d4d9c850  api' | sha256sum -c -
echo 'e41399b7ca3a6ed6918df6330c7d75cdb97c9f7c9d51b87ae1e642a066914625  web/main.dart.js' | sha256sum -c -
echo 'e9add812a138010e443463acb455295103dc69886ca32cd17dafbccfa676d6bc  nginx.conf' | sha256sum -c -
echo 'e9add812a138010e443463acb455295103dc69886ca32cd17dafbccfa676d6bc  nginx.conf' | sha256sum -c -
python3 - "$quiz_build" <<'PY'
from pathlib import Path
import json,sys
build=sys.argv[1];meta=json.loads(Path('web/version.json').read_text())
assert build=='quiz-2026.10.15-reader291-3482af9' and meta['buildId']==build
assert meta['commit']==meta['source_commit']=='3482af9a8b7b7119f14069a791a77b36a8014c49'
assert (meta['packs'],meta['questions'],meta['question_articles'])==(136,4084,291)
assert meta['api_sha256']=='f4d69555623aab2b8e1468fccb65256abefc9823d65214799b7e1475d4d9c850' and meta['main_dart_js_sha256']=='e41399b7ca3a6ed6918df6330c7d75cdb97c9f7c9d51b87ae1e642a066914625'
assert (meta['taxonomy_id'],meta['taxonomy_sha256'],meta['taxonomy_file_sha256'])==('qm-tags-v1', '07e4bbb5c7afcdab3b41a26dca1bf0ba9a830d5f776a98ebceeaeb2bd8356151', '98f019902b5cce5161b5980f3338d9cd072b094b0a760fc93adb748832546f8c')
PY

helm status quiz-master -n quiz-master -o json | python3 -c 'import json,sys;x=json.load(sys.stdin);assert x["version"]==60 and x["info"]["status"]=="deployed"'
quiz_preflight
echo 'e20d542615a12f07883b828dc166170948817dc723f5da7686ce63aa9b22400b  /var/lib/rancher/k3s/agent/images/quiz-2026.10.15-reader291-3482af9.tar' | sha256sum -c -
echo '53f77283f65b00387ec3d3f7fe30a278e5c2a324d27506fa976ab14861cd3f7f  quiz-2026.10.15-reader291-3482af9-cutover-20261015T084302Z-values.yaml' | sha256sum -c -
quiz_digest='sha256:0f24677d8e499df9d21e80ce1dd50b8e830b37608c4c86e1c38e76ccc30d3228'
quiz_values='quiz-2026.10.15-reader291-3482af9-cutover-20261015T084302Z-values.yaml'
k3s ctr images ls | awk -v image="docker.io/library/quiz-master@$quiz_digest" '$1==image {found=1} END {exit !found}'
quiz_run="$quiz_build-publish-$(date -u +%Y%m%dT%H%M%SZ)"
python3 backup_sqlite.py "/opt/quiz-master/backups/$quiz_run.sqlite"
helm lint --strict chart -n quiz-master -f "$quiz_values"
helm template quiz-master chart -n quiz-master -f "$quiz_values" > "$quiz_run-rendered.yaml"
echo '61194251e41088773f5e2b3da7b448d074f5a69f6caeb4343cb9a049d7824b98  '"$quiz_run-rendered.yaml" | sha256sum -c -
kubectl apply --dry-run=server -n quiz-master -f "$quiz_run-rendered.yaml"
quiz_preflight
helm upgrade quiz-master chart -n quiz-master -f "$quiz_values" --atomic --wait --timeout 180s
test "$(kubectl get deploy quiz-master -n quiz-master -o jsonpath='{.spec.template.spec.containers[0].image}')" = "docker.io/library/quiz-master@$quiz_digest"
curl -fsS https://quiz.kotopedia.org/version.json | python3 -c 'import json,sys;assert json.load(sys.stdin)==json.load(open("web/version.json"))'
test "$(curl -fsS https://quiz.kotopedia.org/main.dart.js | sha256sum | cut -d ' ' -f 1)" = e41399b7ca3a6ed6918df6330c7d75cdb97c9f7c9d51b87ae1e642a066914625
test "$(curl -fsS https://quiz.kotopedia.org/assets/assets/study/question-articles.json | sha256sum | cut -d ' ' -f 1)" = dfe520221cbf15438cd449004c26fb82c52cd7d4ed0cfc9954b792aa97de142c
printf 'PUBLISHED build=%s image=%s backup=%s\n' "$quiz_build" "$quiz_digest" "$quiz_run"
