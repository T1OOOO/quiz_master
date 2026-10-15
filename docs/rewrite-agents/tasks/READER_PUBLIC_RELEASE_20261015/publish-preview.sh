#!/usr/bin/env bash
# Default is preparation only. Publish only after browser and cross-provider gates.
set -euo pipefail
quiz_preflight() {
test "$(hostname)" = racknerd-f0269d5
python3 - <<'QUIZ_PREFLIGHT'
import json,os,subprocess,urllib.request
helm=json.loads(subprocess.check_output(['helm','status','quiz-master','-n','quiz-master','-o','json']))
assert helm['version']==58 and helm['info']['status']=='deployed'
deploy=json.loads(subprocess.check_output(['kubectl','get','deploy','quiz-master','-n','quiz-master','-o','json']))
images=[c['image'] for c in deploy['spec']['template']['spec']['containers']]
assert len(images)==2 and set(images)=={'docker.io/library/quiz-master@sha256:4878f824f4b0fb23fa20a8f246541ca4dfa7a1750715f64176cfba4faead0a50'}
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
quiz_build=quiz-2026.10.15-reader-06dfa0b
test "$(hostname)" = racknerd-f0269d5
cd "/opt/quiz-master/releases/$quiz_build"
chmod 755 api
exec 9>/opt/quiz-master/DEPLOY.lock
flock -n 9
quiz_preflight
test "$(kubectl get deploy quiz-master -n quiz-master -o jsonpath='{.spec.template.spec.containers[0].image}')" = docker.io/library/quiz-master@sha256:4878f824f4b0fb23fa20a8f246541ca4dfa7a1750715f64176cfba4faead0a50
test "$(kubectl get pvc quiz-data -n quiz-master -o jsonpath='{.metadata.uid}')" = 7fc2428f-4146-4c78-a26d-2347d9f3b7bf
sha256sum -c checksums.txt > cutover-checksums.log
echo 'f4d69555623aab2b8e1468fccb65256abefc9823d65214799b7e1475d4d9c850  api' | sha256sum -c -
echo '71930a6a9343efbc28f2ad647f9685d05bf2a4c8cdb4d2d9c6dca745085c6331  web/main.dart.js' | sha256sum -c -
echo 'e9add812a138010e443463acb455295103dc69886ca32cd17dafbccfa676d6bc  nginx.conf' | sha256sum -c -
echo 'e9add812a138010e443463acb455295103dc69886ca32cd17dafbccfa676d6bc  nginx.conf' | sha256sum -c -
python3 - "$quiz_build" <<'PY'
from pathlib import Path
import json,sys
build=sys.argv[1];meta=json.loads(Path('web/version.json').read_text())
assert build=='quiz-2026.10.15-reader-06dfa0b' and meta['buildId']==build
assert meta['commit']==meta['source_commit']=='06dfa0bca56c144e4f6c8c06cb1e7b258e032c9b'
assert (meta['packs'],meta['questions'],meta['question_articles'])==(136,4084,279)
assert meta['api_sha256']=='f4d69555623aab2b8e1468fccb65256abefc9823d65214799b7e1475d4d9c850' and meta['main_dart_js_sha256']=='71930a6a9343efbc28f2ad647f9685d05bf2a4c8cdb4d2d9c6dca745085c6331'
assert (meta['taxonomy_id'],meta['taxonomy_sha256'],meta['taxonomy_file_sha256'])==('qm-tags-v1', '07e4bbb5c7afcdab3b41a26dca1bf0ba9a830d5f776a98ebceeaeb2bd8356151', '98f019902b5cce5161b5980f3338d9cd072b094b0a760fc93adb748832546f8c')
PY

helm status quiz-master -n quiz-master -o json | python3 -c 'import json,sys;x=json.load(sys.stdin);assert x["version"]==58 and x["info"]["status"]=="deployed"'
quiz_preflight
echo 'b8bd7bc5fb382f7860ce141d05e467b0b426429e4355212d44b3e50cbda61684  /var/lib/rancher/k3s/agent/images/quiz-2026.10.15-reader-06dfa0b.tar' | sha256sum -c -
echo '6ce58bf2b3885868740d5f85f77112a4412349012b9f7ea7ed4ff126339cf5c9  quiz-2026.10.15-reader-06dfa0b-cutover-20261015T030942Z-values.yaml' | sha256sum -c -
quiz_digest='sha256:95ad1112d272b6cec48d517b350285ed560687cec4a8fc8f7d1b99e6d27cf2af'
quiz_values='quiz-2026.10.15-reader-06dfa0b-cutover-20261015T030942Z-values.yaml'
k3s ctr images ls | awk -v image="docker.io/library/quiz-master@$quiz_digest" '$1==image {found=1} END {exit !found}'
quiz_run="$quiz_build-publish-$(date -u +%Y%m%dT%H%M%SZ)"
python3 backup_sqlite.py "/opt/quiz-master/backups/$quiz_run.sqlite"
helm lint --strict chart -n quiz-master -f "$quiz_values"
helm template quiz-master chart -n quiz-master -f "$quiz_values" > "$quiz_run-rendered.yaml"
echo '64357e6b21d61aea7f24fc30f4394672f77656b6066de18c0a0db801ec1b089a  '"$quiz_run-rendered.yaml" | sha256sum -c -
kubectl apply --dry-run=server -n quiz-master -f "$quiz_run-rendered.yaml"
quiz_preflight
helm upgrade quiz-master chart -n quiz-master -f "$quiz_values" --atomic --wait --timeout 180s
test "$(kubectl get deploy quiz-master -n quiz-master -o jsonpath='{.spec.template.spec.containers[0].image}')" = "docker.io/library/quiz-master@$quiz_digest"
curl -fsS https://quiz.kotopedia.org/version.json | python3 -c 'import json,sys;assert json.load(sys.stdin)==json.load(open("web/version.json"))'
test "$(curl -fsS https://quiz.kotopedia.org/main.dart.js | sha256sum | cut -d ' ' -f 1)" = 71930a6a9343efbc28f2ad647f9685d05bf2a4c8cdb4d2d9c6dca745085c6331
test "$(curl -fsS https://quiz.kotopedia.org/assets/assets/study/question-articles.json | sha256sum | cut -d ' ' -f 1)" = b05cffdd277af88618db52da4fbb4d3b2ae369b849b87ba847b8d491b9eb8828
printf 'PUBLISHED build=%s image=%s backup=%s\n' "$quiz_build" "$quiz_digest" "$quiz_run"
