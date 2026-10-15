set -euo pipefail
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
test "$(hostname)" = racknerd-f0269d5
test "$(kubectl get deploy quiz-master -n quiz-master -o jsonpath='{.spec.template.spec.containers[0].image}')" = docker.io/library/quiz-master@sha256:0f24677d8e499df9d21e80ce1dd50b8e830b37608c4c86e1c38e76ccc30d3228
test "$(kubectl get pvc quiz-data -n quiz-master -o jsonpath='{.metadata.uid}')" = 7fc2428f-4146-4c78-a26d-2347d9f3b7bf
helm status quiz-master -n quiz-master -o json | python3 -c 'import json,sys;x=json.load(sys.stdin);assert x["version"]==61 and x["info"]["status"]=="deployed"'
cd /opt/quiz-master/releases/quiz-2026.10.15-reader299-9c670e9
python3 - <<'PY'
import pathlib,json,hashlib,sqlite3,stat,shutil
from verify_candidate_runtime import verify_runtime_receipt
root=pathlib.Path.cwd();run='quiz-2026.10.15-reader299-9c670e9-cutover-20261015T122746Z'
def h(path):return hashlib.sha256(path.read_bytes()).hexdigest()
backup=pathlib.Path('/opt/quiz-master/backups')/(run+'.sqlite')
with sqlite3.connect(backup.as_uri()+'?mode=ro',uri=True) as db:assert db.execute('pragma integrity_check').fetchone()==('ok',)
assert stat.S_IMODE(backup.stat().st_mode)==0o600
rehearsal=root/(run+'-rehearsal.json');a=json.loads(rehearsal.read_text())
assert a['migration']=='ok' and a['original_rows_preserved'] is True and a['integrity']=='ok' and a['feedback_lifecycle']=='ok' and a['old_api_rollback']=='ok'
assert a['post_migration_counts'][3]-a['original_counts'][3]==136
assert (a['canonical_packs'],a['canonical_questions'],a['newyear_questions'],a['total_graded'],a['practice_finished'])==(14,280,55,335,15)
with sqlite3.connect((root/('rehearsal-'+run)/'quiz.sqlite').as_uri()+'?mode=ro',uri=True) as db:
 practice=db.execute('select count(*),sum(server_score) from attempts where participant_id in (select id from participants where display_name="Release rehearsal") and status="finished"').fetchone()
assert practice==(15,335)
runtime=root/(run+'-candidate-runtime.json');gate=json.loads(runtime.read_text())
verify_runtime_receipt(gate,'quiz-master:quiz-2026.10.15-reader299-9c670e9',expected_packs=136,expected_questions=4084,expected_articles=299,expected_total_refs=180,expected_playable_refs=178)
durable=pathlib.Path('/var/lib/rancher/k3s/agent/images/quiz-2026.10.15-reader299-9c670e9.tar');assert h(durable)=='96b931aa9555ee83090a609235b181c884fb4e197bb3fb8c0510aa42da24d438'
values=root/(run+'-values.yaml');rendered=root/(run+'-rendered.yaml')
assert values.is_file() and rendered.is_file() and rendered.read_text().count('docker.io/library/quiz-master@sha256:e053b4c42c600a062d2dfff5c5152ccc70ff86b2d97b4f91b9784af7c8fc46d4')==2
import os;usage=os.statvfs('/var/lib/rancher/k3s/agent/containerd');free=usage.f_bavail*usage.f_frsize;assert free*5>usage.f_blocks*usage.f_frsize
print(json.dumps({'build_id':'quiz-2026.10.15-reader299-9c670e9','image':'sha256:e053b4c42c600a062d2dfff5c5152ccc70ff86b2d97b4f91b9784af7c8fc46d4','values':values.name,'values_sha256':h(values),'backup_path':str(backup),'backup_sha256':h(backup),'backup_mode':'0600','backup_integrity':'ok','copied_db_rehearsal':a,'copied_db_rehearsal_sha256':h(rehearsal),'candidate_runtime':gate,'candidate_runtime_sha256':h(runtime),'helm_dryrun_sha256':h(rendered),'durable_archive':str(durable),'durable_archive_sha256':h(durable),'disk_free_bytes':free,'baseline_helm_revision':61,'status':'PREPARED_NOT_PUBLISHED'}))
PY
