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
[[ "$quiz_mode" = prepare ]]
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
quiz_run='quiz-2026.10.15-reader-06dfa0b-cutover-20261015T030942Z'
quiz_image='quiz-master:quiz-2026.10.15-reader-06dfa0b'
python3 - <<'RESUME_VERIFY'
from pathlib import Path
import json,hashlib,sqlite3,subprocess,stat
from verify_candidate_runtime import verify_runtime_receipt
root=Path.cwd();run='quiz-2026.10.15-reader-06dfa0b-cutover-20261015T030942Z'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
assert sha(root/'cutover.sh')=='9f24ed9517dcac1ea4860b41c2677e930fba27cbe02eac19701a4a454242fb14'
assert sha(root.parent/'quiz-2026.10.15-reader-06dfa0b.tar.gz')=='6ddd12317732d0fa5bf87f8a80ff24e7ef71b50a233d7d65fa4249421a6c79ab'
runtime=json.loads((root/(run+'-candidate-runtime.json')).read_bytes())
verify_runtime_receipt(runtime,'quiz-master:quiz-2026.10.15-reader-06dfa0b',expected_packs=136,expected_questions=4084,expected_articles=279,expected_total_refs=160,expected_playable_refs=158)
assert runtime['image_id']=='sha256:95ad1112d272b6cec48d517b350285ed560687cec4a8fc8f7d1b99e6d27cf2af'
assert subprocess.check_output(['docker','image','inspect','--format','{{.Id}}','quiz-master:quiz-2026.10.15-reader-06dfa0b'],text=True).strip()=='sha256:95ad1112d272b6cec48d517b350285ed560687cec4a8fc8f7d1b99e6d27cf2af'
backup=Path('/opt/quiz-master/backups')/(run+'.sqlite')
assert stat.S_IMODE(backup.stat().st_mode)==0o600 and sha(backup)=='6794975864e19369f7e41188ad98de43244bd34153451d158115210a6e52bd21'
with sqlite3.connect(backup.as_uri()+'?mode=ro',uri=True) as db:assert db.execute('pragma integrity_check').fetchone()==('ok',)
rehearsal=json.loads((root/(run+'-rehearsal.json')).read_bytes())
assert rehearsal['migration']=='ok' and rehearsal['old_api_rollback']=='ok' and rehearsal['original_rows_preserved'] and rehearsal['integrity']=='ok' and rehearsal['total_graded']==335
with sqlite3.connect((root/('rehearsal-'+run)/'quiz.sqlite').as_uri()+'?mode=ro',uri=True) as db:
 assert db.execute('select count(*),sum(server_score) from attempts where participant_id in (select id from participants where display_name="Release rehearsal") and status="finished"').fetchone()==(15,335)
print('RESUME verified unchanged immutable source, real runtime100/20, copiedDB335 and backup; no rebuild or test bypass')
RESUME_VERIFY
quiz_preflight
quiz_archive="/var/lib/rancher/k3s/agent/images/$quiz_build.tar"
if test -e "$quiz_archive"; then
 sha256sum -c "$quiz_build-image.sha256"
 k3s ctr images import "$quiz_archive"
else
 docker save "$quiz_image" | tee "$quiz_archive" | k3s ctr images import -
 sha256sum "$quiz_archive" > "$quiz_build-image.sha256"
fi
cat "$quiz_build-image.sha256"
quiz_digest=$(k3s ctr images ls | awk -v tag="docker.io/library/$quiz_image" '$1==tag {print $3}')
[[ "$quiz_digest" =~ ^sha256:[a-f0-9]{64}$ ]]
k3s ctr images tag --force "docker.io/library/$quiz_image" "docker.io/library/quiz-master@$quiz_digest"
quiz_values="$quiz_run-values.yaml"
cp --no-clobber release-values.yaml "$quiz_values"
sed -i "s|^image:.*|image: docker.io/library/quiz-master@$quiz_digest|;s|^buildId:.*|buildId: $quiz_build|" "$quiz_values"
helm lint --strict chart -n quiz-master -f "$quiz_values"
helm template quiz-master chart -n quiz-master -f "$quiz_values" > "$quiz_run-rendered.yaml"
test "$(grep -Fc "docker.io/library/quiz-master@$quiz_digest" "$quiz_run-rendered.yaml")" -eq 2
kubectl apply --dry-run=server -n quiz-master -f "$quiz_run-rendered.yaml"
printf 'PREPARED build=%s image=%s values=%s mode=%s\n' "$quiz_build" "$quiz_digest" "$quiz_values" "$quiz_mode"
exit 0
