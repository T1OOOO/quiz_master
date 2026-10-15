set -euo pipefail
unset PYTHONOPTIMIZE PYTHONSTARTUP
exec 8>/opt/quiz-master/DEPLOY.lock
flock -n 8
test "$(hostname)" = racknerd-f0269d5
python3 - <<'QUIZ_PREFLIGHT'
import json,os,subprocess,urllib.request,sqlite3,hashlib
helm=json.loads(subprocess.check_output(['helm','status','quiz-master','-n','quiz-master','-o','json']))
assert helm['version']==64 and helm['info']['status']=='deployed'
deploy=json.loads(subprocess.check_output(['kubectl','get','deploy','quiz-master','-n','quiz-master','-o','json']))
images=[c['image'] for c in deploy['spec']['template']['spec']['containers']]
assert len(images)==2 and set(images)=={'docker.io/library/quiz-master@sha256:dc230d8cec6d555c3f0e67f17a8bdab4452cb546cdf29b50c4c6395717ba8c00'}
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

python3 - <<'BACKUP_PROOF'
import json,sqlite3,contextlib,hashlib,os,stat,subprocess,pathlib
backup=pathlib.Path('/opt/quiz-master/backups/quiz-2026.10.15-country483-3c22818-publish-20261015T230615Z.sqlite')
rows=[]
for path in [backup,backup.with_suffix('.restore-proof.sqlite')]:
 s=path.lstat();assert stat.S_ISREG(s.st_mode) and stat.S_IMODE(s.st_mode)==0o600 and s.st_nlink==1 and not path.is_symlink()
 with contextlib.closing(sqlite3.connect(path.as_uri()+'?mode=ro&immutable=1',uri=True)) as db:
  assert db.execute('pragma integrity_check').fetchone()==('ok',)
  counts={table:db.execute('select count(*) from '+table).fetchone()[0] for table in ['participants','attempts','attempt_bundles','feedback_reports']}
 with path.open('rb') as stream:digest=hashlib.file_digest(stream,'sha256').hexdigest()
 rows.append(dict(path=str(path),mode='0600',integrity='ok',counts=counts,sha256=digest))
assert rows[0]['counts']==rows[1]['counts']
h=json.loads(subprocess.check_output(['helm','status','quiz-master','-n','quiz-master','-o','json']))
x=json.loads(subprocess.check_output(['kubectl','get','deploy','quiz-master','-n','quiz-master','-o','json']))
p=json.loads(subprocess.check_output(['kubectl','get','pvc','quiz-data','-n','quiz-master','-o','json']))
u=os.statvfs('/var/lib/rancher/k3s/agent/containerd')
assert h['version']==64 and h['info']['status']=='deployed' and p['status']['phase']=='Bound'
assert u.f_bavail*u.f_frsize*5>u.f_blocks*u.f_frsize
print(json.dumps(dict(status='PUBLISHED_SERVER_VERIFIED',helm_revision=h['version'],images=[c['image'] for c in x['spec']['template']['spec']['containers']],available_replicas=x['status'].get('availableReplicas'),pvc_uid=p['metadata']['uid'],pvc_phase=p['status']['phase'],available=u.f_bavail*u.f_frsize,total=u.f_blocks*u.f_frsize,strict20=True,reviewed_full29OPEN_node_HTTPS_postflight_completed=True,backup_restore=rows)))

BACKUP_PROOF
