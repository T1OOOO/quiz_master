set -euo pipefail
unset PYTHONOPTIMIZE PYTHONSTARTUP
test "$(hostname)" = racknerd-f0269d5
exec 8>/opt/quiz-master/DEPLOY.lock
flock -n 8
test "$(hostname)" = racknerd-f0269d5
python3 - <<'QUIZ_PREFLIGHT'
import json,os,subprocess,urllib.request,sqlite3,hashlib
helm=json.loads(subprocess.check_output(['helm','status','quiz-master','-n','quiz-master','-o','json']))
assert helm['version']==61 and helm['info']['status']=='deployed'
deploy=json.loads(subprocess.check_output(['kubectl','get','deploy','quiz-master','-n','quiz-master','-o','json']))
images=[c['image'] for c in deploy['spec']['template']['spec']['containers']]
assert len(images)==2 and set(images)=={'docker.io/library/quiz-master@sha256:0f24677d8e499df9d21e80ce1dd50b8e830b37608c4c86e1c38e76ccc30d3228'}
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
cd /opt/quiz-master/releases/quiz-2026.10.15-reader299-9c670e9
test "$(pwd -P)" = /opt/quiz-master/releases/quiz-2026.10.15-reader299-9c670e9
python3 - <<'QUIZ_RESUME_GUARD'
from pathlib import Path
import json,hashlib,sqlite3,stat,subprocess
checks = {'/opt/quiz-master/releases/quiz-2026.10.15-reader299-9c670e9/cutover.sh': 'c9e9ca54fb458b28235c3b237db94ea67a7513067645ff65827b540fa777cb95', '/opt/quiz-master/releases/quiz-2026.10.15-reader299-9c670e9/checksums.txt': '34229f2765d0fffb0ab5fa14be6a7d0d01c9bc11b712531964a1fcf0247c15d8', '/opt/quiz-master/releases/quiz-2026.10.15-reader299-9c670e9/quiz-2026.10.15-reader299-9c670e9-cutover-20261015T115837Z-candidate-runtime.json': '5e0f2cb669b86bd827a266e9dbe8f311a99467fcd98c43380f9915b620e8e853', '/opt/quiz-master/releases/quiz-2026.10.15-reader299-9c670e9/quiz-2026.10.15-reader299-9c670e9-cutover-20261015T115837Z-rehearsal.json': 'e5431954162e3dea0f7050bac8f3248f704d4c76a4ab5b4fa49229c4d1d8bfc8', '/opt/quiz-master/releases/quiz-2026.10.15-reader299-9c670e9/prepare.log': '8a0ce058d79b883199063e4ec1834df5786eeec562a91a81ed8e6109729a25b8', '/opt/quiz-master/releases/quiz-2026.10.15-reader299-9c670e9.tar.gz': '01ddc3ee1cd7ef68376ec1dc84c06ad9c8ab88970995715edce3e631a5c7417d', '/opt/quiz-master/backups/quiz-2026.10.15-reader299-9c670e9-cutover-20261015T115837Z.sqlite': '6794975864e19369f7e41188ad98de43244bd34153451d158115210a6e52bd21'}
for text, expected in checks.items():
 p=Path(text)
 assert p.is_file() and not p.is_symlink() and p.resolve()==p.absolute()
 with p.open('rb') as stream: assert hashlib.file_digest(stream,'sha256').hexdigest()==expected
backup=Path('/opt/quiz-master/backups/quiz-2026.10.15-reader299-9c670e9-cutover-20261015T115837Z.sqlite')
assert stat.S_IMODE(backup.stat().st_mode)==0o600
with sqlite3.connect(backup.as_uri()+'?mode=ro',uri=True) as db: assert db.execute('pragma integrity_check').fetchone()==('ok',)
assert subprocess.check_output(['docker','image','inspect','quiz-master:quiz-2026.10.15-reader299-9c670e9','--format','{{.Id}}'],text=True).strip()=='sha256:faef7c1c7486c437ed569a457dc71ad690342d4cd7010be143caa5bfcc2885f1'
from verify_candidate_runtime import verify_runtime_receipt
runtime=json.loads(Path('/opt/quiz-master/releases/quiz-2026.10.15-reader299-9c670e9/quiz-2026.10.15-reader299-9c670e9-cutover-20261015T115837Z-candidate-runtime.json').read_text())
assert runtime['image_id']=='sha256:faef7c1c7486c437ed569a457dc71ad690342d4cd7010be143caa5bfcc2885f1'
verify_runtime_receipt(runtime,'quiz-master:quiz-2026.10.15-reader299-9c670e9',expected_packs=136,expected_questions=4084,expected_articles=299,expected_total_refs=180,expected_playable_refs=178)
rehearsal=json.loads(Path('/opt/quiz-master/releases/quiz-2026.10.15-reader299-9c670e9/quiz-2026.10.15-reader299-9c670e9-cutover-20261015T115837Z-rehearsal.json').read_text())
assert rehearsal['original_rows_preserved'] is True and rehearsal['old_api_rollback']=='ok' and rehearsal['feedback_lifecycle']=='ok' and (rehearsal['total_graded'],rehearsal['practice_finished'])==(335,15)
QUIZ_RESUME_GUARD
sha256sum -c checksums.txt > /dev/null
test ! -e /var/lib/rancher/k3s/agent/images/quiz-2026.10.15-reader299-9c670e9.tar
umask 077
set -o noclobber
: > resume-e0e61b34841d4293bc1799984c37f89a.log
set +o noclobber
flock -u 8
exec 8>&-
bash cutover.sh prepare 2>&1 | tee resume-e0e61b34841d4293bc1799984c37f89a.log
python3 - <<'QUIZ_PRESERVE_FAILED'
from pathlib import Path
import hashlib
checks={'/opt/quiz-master/releases/quiz-2026.10.15-reader299-9c670e9/cutover.sh': 'c9e9ca54fb458b28235c3b237db94ea67a7513067645ff65827b540fa777cb95', '/opt/quiz-master/releases/quiz-2026.10.15-reader299-9c670e9/checksums.txt': '34229f2765d0fffb0ab5fa14be6a7d0d01c9bc11b712531964a1fcf0247c15d8', '/opt/quiz-master/releases/quiz-2026.10.15-reader299-9c670e9/quiz-2026.10.15-reader299-9c670e9-cutover-20261015T115837Z-candidate-runtime.json': '5e0f2cb669b86bd827a266e9dbe8f311a99467fcd98c43380f9915b620e8e853', '/opt/quiz-master/releases/quiz-2026.10.15-reader299-9c670e9/quiz-2026.10.15-reader299-9c670e9-cutover-20261015T115837Z-rehearsal.json': 'e5431954162e3dea0f7050bac8f3248f704d4c76a4ab5b4fa49229c4d1d8bfc8', '/opt/quiz-master/releases/quiz-2026.10.15-reader299-9c670e9/prepare.log': '8a0ce058d79b883199063e4ec1834df5786eeec562a91a81ed8e6109729a25b8'}
for text,expected in checks.items():
 p=Path(text)
 with p.open("rb") as stream: assert hashlib.file_digest(stream,"sha256").hexdigest()==expected
QUIZ_PRESERVE_FAILED
