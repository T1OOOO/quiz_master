set -euo pipefail
unset PYTHONOPTIMIZE PYTHONSTARTUP
test "$(hostname)" = racknerd-f0269d5
python3 - <<'QUIZ_PREFLIGHT'
import json,os,subprocess,urllib.request,sqlite3,hashlib,datetime,socket
captured=datetime.datetime.now(datetime.timezone.utc).isoformat()
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
assert conditions.get('Ready')=='True' and conditions.get('DiskPressure')=='False' and conditions.get('MemoryPressure')=='False' and conditions.get('PIDPressure')=='False'
assert not node.get('spec',{}).get('unschedulable',False)
assert not any(t.get('effect') in ('NoSchedule','NoExecute') for t in node.get('spec',{}).get('taints',[]))
usage=os.statvfs('/var/lib/rancher/k3s/agent/containerd')
assert usage.f_bavail*usage.f_frsize*5>usage.f_blocks*usage.f_frsize
with urllib.request.urlopen('https://quiz.kotopedia.org/health/ready',timeout=15) as response: assert response.status==200
db_path='file:/var/lib/rancher/k3s/storage/pvc-7fc2428f-4146-4c78-a26d-2347d9f3b7bf_quiz-master_quiz-data/quiz.db?mode=ro'
with sqlite3.connect(db_path,uri=True) as db:
 rows=db.execute('select * from feedback_reports order by rowid').fetchall()
 open_count=db.execute("select count(*) from feedback_reports where status='open'").fetchone()[0]
 assert len(rows)==43 and open_count==43
 assert hashlib.sha256(json.dumps(rows,ensure_ascii=False,default=str).encode()).hexdigest()=='58f336a3bec6034396b8af587e1268d1ad19f5983591dcac0b0778a2e4737157'
import pathlib,stat,contextlib
backup=pathlib.Path('/opt/quiz-master/backups/quiz-2026.10.15-country483-3c22818-publish-20261015T230615Z.sqlite')
proof=backup.with_suffix('.restore-proof.sqlite')
digests=[];modes=[];integrity_results=[]
for path in [backup,proof]:
 s=path.lstat()
 modes.append(stat.S_IMODE(s.st_mode))
 assert stat.S_ISREG(s.st_mode) and not path.is_symlink() and s.st_nlink==1 and stat.S_IMODE(s.st_mode)==0o600
 with path.open('rb') as stream: digests.append(hashlib.file_digest(stream,'sha256').hexdigest())
 with contextlib.closing(sqlite3.connect(path.as_uri()+'?mode=ro&immutable=1',uri=True)) as db:
  integrity=db.execute('pragma integrity_check').fetchone()
  integrity_results.append(integrity[0])
  assert integrity==('ok',)
assert digests==['6794975864e19369f7e41188ad98de43244bd34153451d158115210a6e52bd21']*2
print(json.dumps(dict(observed_at_utc=captured,target_host=socket.gethostname(),conditions=conditions,taints=node.get('spec',{}).get('taints',[]),unschedulable=node.get('spec',{}).get('unschedulable',False),memory_pressure=conditions.get('MemoryPressure')!='False',pid_pressure=conditions.get('PIDPressure')!='False',node_ready=conditions.get('Ready')=='True',disk_pressure=conditions.get('DiskPressure')!='False',blocking_taints=any(t.get('effect') in ('NoSchedule','NoExecute') for t in node.get('spec',{}).get('taints',[])),disk_available=usage.f_bavail*usage.f_frsize,disk_total=usage.f_blocks*usage.f_frsize,disk_at_least20percent=usage.f_bavail*usage.f_frsize*5>usage.f_blocks*usage.f_frsize,https_readiness_status=response.status)))
print(json.dumps(dict(observed_at_utc=captured,helm_revision=helm['version'],status=helm['info']['status'],images=images,available_replicas=deploy['status']['availableReplicas'],pvc_uid=pvc['metadata']['uid'],feedback_count=len(rows),feedback_open_count=open_count,all_open=open_count==len(rows),feedback_sha256=hashlib.sha256(json.dumps(rows,ensure_ascii=False,default=str).encode()).hexdigest(),backup_modes=modes,backup_integrity_results=integrity_results,backup_mode=format(modes[0],'04o'),backup_integrity='ok' if integrity_results==['ok','ok'] else 'failed',existing_published_backup=str(backup),existing_published_backup_sha256=digests[0],independent_restore_sha256=digests[1],mutation=False)))

QUIZ_PREFLIGHT
