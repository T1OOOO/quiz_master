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
cd /opt/quiz-master/releases/quiz-2026.10.15-country483-3c22818
test "$(readlink -f "$PWD")" = /opt/quiz-master/releases/quiz-2026.10.15-country483-3c22818
sha256sum -c checksums.txt > country483-resume-checksums.log
echo '423e8acf6967be596760f6bf472420907ebc47597a16d95d90270815162daa9b  checksums.txt' | sha256sum -c -
test -f prepare.log
test ! -e prepare-resume-66fe6ea9640447beacc9aec8fe6166ac.log
bash -n cutover.sh
flock -u 8
exec 8>&-
bash cutover.sh prepare 2>&1 | tee prepare-resume-66fe6ea9640447beacc9aec8fe6166ac.log
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
python3 - <<'COUNTRY483_ATLAS'
import json,re,hashlib,pathlib,subprocess
from datetime import datetime
BUILD='quiz-2026.10.15-country483-3c22818'
SOURCE='3c2281815b768271d9110f2d28fa415c0eefe06c'
ARCHIVE_SHA='15eb5d5710251b9aca4c2cee29bbd50822388435eeed618b3476f2b0b8841416'
CHECKSUMS_SHA='423e8acf6967be596760f6bf472420907ebc47597a16d95d90270815162daa9b'
ATLAS={'/app/web/assets/assets/quizipedia/catalog.json': '09ddb9adc380cb935d35ba6b2f5ea55b9ee6b5675b8c7c6c6cddf2c25679a7dc', '/app/web/assets/assets/quizipedia/manifest.json': '226f75de88b696a4b173540abf7dc457cadcd91694f5113a60ee85f302a45be7'}
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

root=pathlib.Path.cwd()
matches=re.findall(r'PREPARED build=(\S+) image=(sha256:[a-f0-9]{64}) values=(\S+) mode=prepare', (root/'prepare-resume-66fe6ea9640447beacc9aec8fe6166ac.log').read_text())
require(len(matches)==1 and matches[0][0]==BUILD,'one exact successful preparation marker required')
image=matches[0][1];values=matches[0][2]
require(values.endswith('-values.yaml'),'prepared values name differs')
run=values.removesuffix('-values.yaml');validate_identity(run,image)
require(subprocess.check_output(['docker','image','inspect','quiz-master:'+BUILD,'--format','{{.Id}}'],text=True).strip()==image,'candidate tag changed')
runtime=root/(run+'-candidate-runtime.json');runtime_sha=hashlib.sha256(runtime.read_bytes()).hexdigest()
require(json.loads(runtime.read_text()).get('image')=='quiz-master:'+BUILD,'runtime image binding differs')
require(hashlib.sha256((root/'checksums.txt').read_bytes()).hexdigest()==CHECKSUMS_SHA,'candidate package checksums changed')
raw=subprocess.check_output(candidate_command(image),text=True,timeout=45)
lines=raw.splitlines();require(len(lines)==2,'exact two atlas output rows required')
observed={}
for line in lines:
 digest,path=line.split('  ',1);require(path not in observed,'duplicate atlas path');observed[path]=digest
require(observed==ATLAS,'candidate atlas hash mismatch')
receipt=dict(schema_version='qm-country483-candidate-atlas/v1',status='VERIFIED_CANDIDATE_ATLAS_NOT_PUBLISHED',build_id=BUILD,
 source_commit=SOURCE,package_sha256=ARCHIVE_SHA,package_checksums_sha256=CHECKSUMS_SHA,run=run,image=image,
 candidate_runtime_sha256=runtime_sha,atlas_sha256=observed,actual_exit=0,stateless=True,production_db_mounted=False)
verify_atlas_receipt(receipt,run,image,runtime_sha)
path=root/(run+'-candidate-atlas.json')
with path.open('x',encoding='utf8') as stream:stream.write(json.dumps(receipt,sort_keys=True,indent=2)+'\n')
print('CANDIDATE_ATLAS_VERIFIED build='+BUILD+' image='+image+' run='+run)

COUNTRY483_ATLAS
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
