set -euo pipefail
exec 8>/opt/quiz-master/DEPLOY.lock
flock -n 8
test "$(hostname)" = racknerd-f0269d5
python3 - <<'QUIZ_PREFLIGHT'
import json,os,subprocess,urllib.request,sqlite3,hashlib
helm=json.loads(subprocess.check_output(['helm','status','quiz-master','-n','quiz-master','-o','json']))
assert helm['version']==63 and helm['info']['status']=='deployed'
deploy=json.loads(subprocess.check_output(['kubectl','get','deploy','quiz-master','-n','quiz-master','-o','json']))
images=[c['image'] for c in deploy['spec']['template']['spec']['containers']]
assert len(images)==2 and set(images)=={'docker.io/library/quiz-master@sha256:6c603a840b01c9c4605eba234e4af3d95a3f52fff12e65d9904b563db5722f14'}
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
test "$(kubectl get deploy quiz-master -n quiz-master -o jsonpath='{.spec.template.spec.containers[0].image}')" = docker.io/library/quiz-master@sha256:6c603a840b01c9c4605eba234e4af3d95a3f52fff12e65d9904b563db5722f14
test "$(kubectl get pvc quiz-data -n quiz-master -o jsonpath='{.metadata.uid}')" = 7fc2428f-4146-4c78-a26d-2347d9f3b7bf
helm status quiz-master -n quiz-master -o json | python3 -c 'import json,sys;x=json.load(sys.stdin);assert x["version"]==63 and x["info"]["status"]=="deployed"'
cd /opt/quiz-master/releases/quiz-2026.10.15-country483-3c22818
python3 - <<'PY'
import pathlib,json,hashlib,sqlite3,stat,shutil
from verify_candidate_runtime import verify_runtime_receipt
root=pathlib.Path.cwd();run='quiz-2026.10.15-country483-3c22818-cutover-20990101T000000Z'
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
verify_runtime_receipt(gate,'quiz-master:quiz-2026.10.15-country483-3c22818',expected_packs=136,expected_questions=4084,expected_articles=303,expected_total_refs=184,expected_playable_refs=182)
durable=pathlib.Path('/var/lib/rancher/k3s/agent/images/quiz-2026.10.15-country483-3c22818.tar');assert h(durable)=='0000000000000000000000000000000000000000000000000000000000000000'
values=root/(run+'-values.yaml');rendered=root/(run+'-rendered.yaml')
assert values.is_file() and rendered.is_file() and rendered.read_text().count('docker.io/library/quiz-master@sha256:0000000000000000000000000000000000000000000000000000000000000000')==2
import os;usage=os.statvfs('/var/lib/rancher/k3s/agent/containerd');free=usage.f_bavail*usage.f_frsize;assert free*5>usage.f_blocks*usage.f_frsize
import json,re,hashlib,pathlib,subprocess
from datetime import datetime
BUILD='quiz-2026.10.15-country483-3c22818'
SOURCE='3c2281815b768271d9110f2d28fa415c0eefe06c'
ARCHIVE_SHA='15eb5d5710251b9aca4c2cee29bbd50822388435eeed618b3476f2b0b8841416'
CHECKSUMS_SHA='423e8acf6967be596760f6bf472420907ebc47597a16d95d90270815162daa9b'
ATLAS={'/usr/share/nginx/html/assets/assets/quizipedia/catalog.json': '09ddb9adc380cb935d35ba6b2f5ea55b9ee6b5675b8c7c6c6cddf2c25679a7dc', '/usr/share/nginx/html/assets/assets/quizipedia/manifest.json': '226f75de88b696a4b173540abf7dc457cadcd91694f5113a60ee85f302a45be7'}
def require(ok, message):
    if not ok:
        raise RuntimeError(message)

def validate_identity(run, image, durable=None):
    require(isinstance(run, str) and re.fullmatch(re.escape(BUILD) + r'-cutover-\d{8}T\d{6}Z', run) is not None, 'unsafe preparation run')
    datetime.strptime(run.rsplit('-cutover-',1)[1], '%Y%m%dT%H%M%SZ')
    require(isinstance(image, str) and re.fullmatch('sha256:[0-9a-f]{64}', image) is not None, 'immutable image ID required')
    if durable is not None: require(isinstance(durable, str) and re.fullmatch('[0-9a-f]{64}', durable) is not None, 'unsafe durable digest')

def candidate_command(image):
    require(isinstance(image, str) and re.fullmatch('sha256:[0-9a-f]{64}', image) is not None, 'immutable image ID required')
    return ['docker','run','--rm','--network=none','--read-only','--cap-drop=ALL','--security-opt=no-new-privileges',
            '--user=10001:10001','--entrypoint=sha256sum',image,*ATLAS]

def verify_atlas_receipt(receipt, run, image, runtime_sha):
    validate_identity(run, image)
    require(isinstance(runtime_sha,str) and re.fullmatch('[0-9a-f]{64}',runtime_sha) is not None, 'invalid runtime receipt hash')
    expected = dict(schema_version='qm-country483-candidate-atlas/v1', status='VERIFIED_CANDIDATE_ATLAS_NOT_PUBLISHED',
                    build_id=BUILD, source_commit=SOURCE, package_sha256=ARCHIVE_SHA, package_checksums_sha256=CHECKSUMS_SHA,
                    run=run, image=image, candidate_runtime_sha256=runtime_sha, atlas_sha256=ATLAS, actual_exit=0,
                    stateless=True, production_db_mounted=False)
    require(isinstance(receipt,dict) and receipt == expected and type(receipt.get('actual_exit')) is int,
            'candidate atlas receipt/image/package/hash mismatch')

require(hashlib.sha256((root/'checksums.txt').read_bytes()).hexdigest()==CHECKSUMS_SHA,'collected package checksums differ')
require(subprocess.check_output(['docker','image','inspect','quiz-master:'+BUILD,'--format','{{.Id}}'],text=True).strip()=='sha256:0000000000000000000000000000000000000000000000000000000000000000','collected candidate tag changed')
atlas_path=root/(run+'-candidate-atlas.json');atlas=json.loads(atlas_path.read_text())
verify_atlas_receipt(atlas,run,'sha256:0000000000000000000000000000000000000000000000000000000000000000',h(runtime))

print(json.dumps({'build_id':'quiz-2026.10.15-country483-3c22818','image':'sha256:0000000000000000000000000000000000000000000000000000000000000000','values':values.name,'values_sha256':h(values),'backup_path':str(backup),'backup_sha256':h(backup),'backup_mode':'0600','backup_integrity':'ok','copied_db_rehearsal':a,'copied_db_rehearsal_sha256':h(rehearsal),'candidate_runtime':gate,'candidate_runtime_sha256':h(runtime),'helm_dryrun_sha256':h(rendered),'durable_archive':str(durable),'durable_archive_sha256':h(durable),'disk_free_bytes':free,'baseline_helm_revision':63,'status':'PREPARED_NOT_PUBLISHED','source_commit':SOURCE,'package_sha256':ARCHIVE_SHA,'candidate_atlas':atlas,'candidate_atlas_sha256':h(atlas_path)}))
PY
