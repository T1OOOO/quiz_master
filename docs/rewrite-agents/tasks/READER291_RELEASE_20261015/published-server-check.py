from pathlib import Path
import subprocess,json
r=Path('C:/ap/quiz_master'); d=r/'docs/rewrite-agents/tasks/READER291_RELEASE_20261015'
s='''set -euo pipefail
test "$(hostname)" = racknerd-f0269d5
python3 - <<'PY'
import json,subprocess,sqlite3,hashlib,os
h=json.loads(subprocess.check_output(['helm','status','quiz-master','-n','quiz-master','-o','json']))
x=json.loads(subprocess.check_output(['kubectl','get','deploy','quiz-master','-n','quiz-master','-o','json']))
p=json.loads(subprocess.check_output(['kubectl','get','pvc','quiz-data','-n','quiz-master','-o','json']))
assert h['version']==61 and h['info']['status']=='deployed'
images=[c['image'] for c in x['spec']['template']['spec']['containers']];assert len(images)==2 and set(images)=={'docker.io/library/quiz-master@sha256:0f24677d8e499df9d21e80ce1dd50b8e830b37608c4c86e1c38e76ccc30d3228'}
assert x['status'].get('availableReplicas')==1 and p['metadata']['uid']=='7fc2428f-4146-4c78-a26d-2347d9f3b7bf'
import urllib.request
nodes=json.loads(subprocess.check_output(['kubectl','get','nodes','-o','json']))['items'];assert len(nodes)==1
node=nodes[0];conditions={c['type']:c['status'] for c in node['status']['conditions']};assert conditions['Ready']=='True' and conditions['DiskPressure']=='False';assert not any(t['effect'] in ['NoSchedule','NoExecute'] for t in node['spec'].get('taints',[]))
st=os.statvfs('/var/lib/rancher/k3s');available=st.f_bavail*st.f_frsize;total=st.f_blocks*st.f_frsize;assert available*5>=total
with urllib.request.urlopen('https://quiz.kotopedia.org/health/ready',timeout=15) as ready:assert ready.status==200
print(json.dumps({'node_ready':True,'disk_pressure':False,'blocking_taints':False,'disk_available':available,'disk_total':total,'disk_at_least20percent':True,'https_readiness_status':200}))
db=sqlite3.connect('file:/var/lib/rancher/k3s/storage/pvc-7fc2428f-4146-4c78-a26d-2347d9f3b7bf_quiz-master_quiz-data/quiz.db?mode=ro',uri=True)
rows=db.execute('select * from feedback_reports order by rowid').fetchall();sha=hashlib.sha256(json.dumps(rows,ensure_ascii=False,default=str).encode()).hexdigest();assert sha=='452929a2ea8dc34600eff8039571e2b0479ec7ad1ec52fa6e271b5c71008030e'
b='/opt/quiz-master/backups/quiz-2026.10.15-reader291-3482af9-publish-20261015T093511Z.sqlite';assert os.stat(b).st_mode & 0o777 == 0o600
backup=sqlite3.connect('file:'+b+'?mode=ro',uri=True);assert backup.execute('pragma integrity_check').fetchone()[0]=='ok'
print(json.dumps({'helm_revision':61,'status':'deployed','images':images,'available_replicas':1,'pvc_uid':p['metadata']['uid'],'feedback_count':len(rows),'all_open':db.execute("select count(*) from feedback_reports where status='open'").fetchone()[0]==29,'feedback_sha256':sha,'backup_mode':'0600','backup_integrity':'ok'}))
PY
'''
p=subprocess.run(['ssh','-i','C:/Users/Alexey_Matvienko/.ssh/ll_deploy_ed25519','root@192.3.164.184','bash -s'],input=s.encode(),capture_output=True,timeout=40);assert p.returncode==0,p.stderr.decode();(d/'published-server-verification.jsonl').write_bytes(p.stdout);print(p.stdout.decode())
