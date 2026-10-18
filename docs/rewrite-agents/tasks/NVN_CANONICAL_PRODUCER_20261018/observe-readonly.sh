set -euo pipefail
unset PYTHONOPTIMIZE PYTHONSTARTUP
test "$(hostname)" = racknerd-f0269d5
python3 - <<'QM_OBSERVE'
import os,json,sqlite3,hashlib,subprocess,urllib.request,datetime
h=json.loads(subprocess.check_output(['helm','status','quiz-master','-n','quiz-master','-o','json']))
d=json.loads(subprocess.check_output(['kubectl','get','deploy','quiz-master','-n','quiz-master','-o','json']))
p=json.loads(subprocess.check_output(['kubectl','get','pvc','quiz-data','-n','quiz-master','-o','json']))
assert p['metadata']['uid']=='7fc2428f-4146-4c78-a26d-2347d9f3b7bf' and p['status']['phase']=='Bound'
n=json.loads(subprocess.check_output(['kubectl','get','nodes','-o','json']))['items'];assert len(n)==1
c={x['type']:x['status'] for x in n[0]['status']['conditions']}
s=os.statvfs('/var/lib/rancher/k3s/agent/containerd');free=s.f_bavail*s.f_frsize;total=s.f_blocks*s.f_frsize
with urllib.request.urlopen('https://quiz.kotopedia.org/health/ready',timeout=15) as response:status=response.status
with sqlite3.connect('file:/var/lib/rancher/k3s/storage/pvc-7fc2428f-4146-4c78-a26d-2347d9f3b7bf_quiz-master_quiz-data/quiz.db?mode=ro',uri=True) as db:
 rows=db.execute('select * from feedback_reports order by rowid').fetchall()
 opened=db.execute("select count(*) from feedback_reports where status='open'").fetchone()[0]
print(json.dumps(dict(observed_at_utc=datetime.datetime.now(datetime.timezone.utc).isoformat(),disk_available=free,disk_total=total,available_percent=round(free/total*100,3),strict20_pass=free*5>total,deficit_to20_bytes=max(0,total//5+1-free),conditions=c,taints=n[0].get('spec',{}).get('taints',[]),helm_revision=h['version'],helm_status=h['info']['status'],images=[x['image'] for x in d['spec']['template']['spec']['containers']],replicas=d['status'].get('availableReplicas'),readiness=status,feedback_count=len(rows),feedback_open=opened,feedback_sha256=hashlib.sha256(json.dumps(rows,ensure_ascii=False,default=str).encode()).hexdigest(),mutation=False)))
QM_OBSERVE
