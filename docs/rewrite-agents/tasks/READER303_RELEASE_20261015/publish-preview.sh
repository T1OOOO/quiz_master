#!/usr/bin/env bash
# Default is preparation only. Publish only after browser and cross-provider gates.
set -euo pipefail
quiz_preflight() {
test "$(hostname)" = racknerd-f0269d5
python3 - <<'QUIZ_PREFLIGHT'
import json,os,subprocess,urllib.request,sqlite3,hashlib
helm=json.loads(subprocess.check_output(['helm','status','quiz-master','-n','quiz-master','-o','json']))
assert helm['version']==62 and helm['info']['status']=='deployed'
deploy=json.loads(subprocess.check_output(['kubectl','get','deploy','quiz-master','-n','quiz-master','-o','json']))
images=[c['image'] for c in deploy['spec']['template']['spec']['containers']]
assert len(images)==2 and set(images)=={'docker.io/library/quiz-master@sha256:e053b4c42c600a062d2dfff5c5152ccc70ff86b2d97b4f91b9784af7c8fc46d4'}
assert deploy['status'].get('availableReplicas')==1
pvc=json.loads(subprocess.check_output(['kubectl','get','pvc','quiz-data','-n','quiz-master','-o','json']))
assert pvc['metadata']['uid']=='7fc2428f-4146-4c78-a26d-2347d9f3b7bf' and pvc['status']['phase']=='Bound'
nodes=json.loads(subprocess.check_output(['kubectl','get','nodes','-o','json']))['items']
assert len(nodes)==1
node=nodes[0];conditions={c['type']:c['status'] for c in node['status']['conditions']}
assert conditions.get('Ready')=='True' and conditions.get('DiskPressure')=='False'
assert not node.get('spec',{}).get('unschedulable',False)
assert not any(t.get('effect') in ('NoSchedule','NoExecute') for t in node.get('spec',{}).get('taints',[]))
usage=os.statvfs('/var/lib/rancher/k3s/agent/containerd')
assert usage.f_bavail*usage.f_frsize*5>usage.f_blocks*usage.f_frsize
with urllib.request.urlopen('https://quiz.kotopedia.org/health/ready',timeout=15) as response: assert response.status==200
db_path='file:/var/lib/rancher/k3s/storage/pvc-7fc2428f-4146-4c78-a26d-2347d9f3b7bf_quiz-master_quiz-data/quiz.db?mode=ro'
with sqlite3.connect(db_path,uri=True) as db:
 rows=db.execute('select * from feedback_reports order by rowid').fetchall()
 assert len(rows)==29 and db.execute("select count(*) from feedback_reports where status='open'").fetchone()[0]==29
 assert hashlib.sha256(json.dumps(rows,ensure_ascii=False,default=str).encode()).hexdigest()=='452929a2ea8dc34600eff8039571e2b0479ec7ad1ec52fa6e271b5c71008030e'
QUIZ_PREFLIGHT
}
quiz_mode=${1:-prepare}
[[ "$quiz_mode" = publish ]]
quiz_build=quiz-2026.10.15-reader303-14b7da4
test "$(hostname)" = racknerd-f0269d5
cd "/opt/quiz-master/releases/$quiz_build"
chmod 755 api
exec 9>/opt/quiz-master/DEPLOY.lock
flock -n 9
quiz_preflight
test "$(kubectl get deploy quiz-master -n quiz-master -o jsonpath='{.spec.template.spec.containers[0].image}')" = docker.io/library/quiz-master@sha256:e053b4c42c600a062d2dfff5c5152ccc70ff86b2d97b4f91b9784af7c8fc46d4
test "$(kubectl get pvc quiz-data -n quiz-master -o jsonpath='{.metadata.uid}')" = 7fc2428f-4146-4c78-a26d-2347d9f3b7bf
sha256sum -c checksums.txt > cutover-checksums.log
echo 'f4d69555623aab2b8e1468fccb65256abefc9823d65214799b7e1475d4d9c850  api' | sha256sum -c -
echo '209c5e9f7ff7c2ad1cc9b3aa28b655b4782709ee7a99a2b5a204945e71f23732  web/main.dart.js' | sha256sum -c -
echo 'e9add812a138010e443463acb455295103dc69886ca32cd17dafbccfa676d6bc  nginx.conf' | sha256sum -c -
echo 'e9add812a138010e443463acb455295103dc69886ca32cd17dafbccfa676d6bc  nginx.conf' | sha256sum -c -
python3 - "$quiz_build" <<'PY'
from pathlib import Path
import json,sys
build=sys.argv[1];meta=json.loads(Path('web/version.json').read_text())
assert build=='quiz-2026.10.15-reader303-14b7da4' and meta['buildId']==build
assert meta['commit']==meta['source_commit']=='14b7da43c3e43642d60859f5053ee6d809c2379e'
assert (meta['packs'],meta['questions'],meta['question_articles'])==(136,4084,303)
assert meta['api_sha256']=='f4d69555623aab2b8e1468fccb65256abefc9823d65214799b7e1475d4d9c850' and meta['main_dart_js_sha256']=='209c5e9f7ff7c2ad1cc9b3aa28b655b4782709ee7a99a2b5a204945e71f23732'
assert (meta['taxonomy_id'],meta['taxonomy_sha256'],meta['taxonomy_file_sha256'])==('qm-tags-v1', '07e4bbb5c7afcdab3b41a26dca1bf0ba9a830d5f776a98ebceeaeb2bd8356151', '98f019902b5cce5161b5980f3338d9cd072b094b0a760fc93adb748832546f8c')
PY

    helm status quiz-master -n quiz-master -o json | python3 -c 'import json,sys;x=json.load(sys.stdin);assert x["version"]==62 and x["info"]["status"]=="deployed"'
    quiz_preflight
    echo 'c86b4632f0826f9a5a7d92b772ba1744846f23ff08d2b46403c23d1c18153bd3  /var/lib/rancher/k3s/agent/images/quiz-2026.10.15-reader303-14b7da4.tar' | sha256sum -c -
    echo '574a9278a4a202d1c8541b01e1cc23526c028bc1c883a099eb9986bc14d6053f  quiz-2026.10.15-reader303-14b7da4-cutover-20261015T171054Z-values.yaml' | sha256sum -c -
    quiz_digest='sha256:6c603a840b01c9c4605eba234e4af3d95a3f52fff12e65d9904b563db5722f14'
    quiz_values='quiz-2026.10.15-reader303-14b7da4-cutover-20261015T171054Z-values.yaml'
    k3s ctr images ls | awk -v image="docker.io/library/quiz-master@$quiz_digest" '$1==image {found=1} END {exit !found}'
    quiz_run="$quiz_build-publish-$(date -u +%Y%m%dT%H%M%SZ)"
    python3 backup_sqlite.py "/opt/quiz-master/backups/$quiz_run.sqlite"
    helm lint --strict chart -n quiz-master -f "$quiz_values"
    helm template quiz-master chart -n quiz-master -f "$quiz_values" > "$quiz_run-rendered.yaml"
    echo 'd6b42f6c2f7536335caf1687e93298f370282f2b7da4014c3719d1d7a68dfe48  '"$quiz_run-rendered.yaml" | sha256sum -c -
    kubectl apply --dry-run=server -n quiz-master -f "$quiz_run-rendered.yaml"
    quiz_preflight
    helm upgrade quiz-master chart -n quiz-master -f "$quiz_values" --atomic --wait --timeout 180s
    kubectl get deploy quiz-master -n quiz-master -o json | python3 -c 'import json,sys;x=json.load(sys.stdin);images=[c["image"] for c in x["spec"]["template"]["spec"]["containers"]];assert len(images)==2 and set(images)=={"docker.io/library/quiz-master@sha256:6c603a840b01c9c4605eba234e4af3d95a3f52fff12e65d9904b563db5722f14"};assert x["status"].get("availableReplicas")==1'
    curl -fsS https://quiz.kotopedia.org/health/ready >/dev/null
    curl -fsS https://quiz.kotopedia.org/version.json | python3 -c 'import json,sys;assert json.load(sys.stdin)==json.load(open("web/version.json"))'
    test "$(curl -fsS https://quiz.kotopedia.org/main.dart.js | sha256sum | cut -d ' ' -f 1)" = 209c5e9f7ff7c2ad1cc9b3aa28b655b4782709ee7a99a2b5a204945e71f23732
    test "$(curl -fsS https://quiz.kotopedia.org/assets/assets/study/question-articles.json | sha256sum | cut -d ' ' -f 1)" = 84f0cac186aa95c6abf910a396b88201e25cdf67a388130956f7548c4c567733
    printf 'PUBLISHED build=%s image=%s backup=%s\n' "$quiz_build" "$quiz_digest" "$quiz_run"
    