from pathlib import Path
import subprocess,json
r=Path('C:/ap/quiz_master'); d=r/'docs/rewrite-agents/tasks/LIBRARY_RELEASE_20261014/retry57'
s='''set -euo pipefail
test "$(hostname)" = racknerd-f0269d5
python3 - <<'PY'
import json,subprocess,sqlite3,hashlib,os
h=json.loads(subprocess.check_output(['helm','status','quiz-master','-n','quiz-master','-o','json']))
x=json.loads(subprocess.check_output(['kubectl','get','deploy','quiz-master','-n','quiz-master','-o','json']))
p=json.loads(subprocess.check_output(['kubectl','get','pvc','quiz-data','-n','quiz-master','-o','json']))
assert h['version']==58 and h['info']['status']=='deployed'
images=[c['image'] for c in x['spec']['template']['spec']['containers']];assert len(images)==2 and set(images)=={'docker.io/library/quiz-master@sha256:4878f824f4b0fb23fa20a8f246541ca4dfa7a1750715f64176cfba4faead0a50'}
assert x['status'].get('availableReplicas')==1 and p['metadata']['uid']=='7fc2428f-4146-4c78-a26d-2347d9f3b7bf'
db=sqlite3.connect('file:/var/lib/rancher/k3s/storage/pvc-7fc2428f-4146-4c78-a26d-2347d9f3b7bf_quiz-master_quiz-data/quiz.db?mode=ro',uri=True)
rows=db.execute('select * from feedback_reports order by rowid').fetchall();sha=hashlib.sha256(json.dumps(rows,ensure_ascii=False,default=str).encode()).hexdigest();assert sha=='452929a2ea8dc34600eff8039571e2b0479ec7ad1ec52fa6e271b5c71008030e'
b='/opt/quiz-master/backups/quiz-2026.10.14-library-09b19cc-publish-20261014T223958Z.sqlite';assert os.stat(b).st_mode & 0o777 == 0o600
backup=sqlite3.connect('file:'+b+'?mode=ro',uri=True);assert backup.execute('pragma integrity_check').fetchone()[0]=='ok'
print(json.dumps({'helm_revision':58,'status':'deployed','images':images,'available_replicas':1,'pvc_uid':p['metadata']['uid'],'feedback_count':len(rows),'all_open':db.execute("select count(*) from feedback_reports where status='open'").fetchone()[0]==29,'feedback_sha256':sha,'backup_mode':'0600','backup_integrity':'ok'}))
PY
'''
p=subprocess.run(['ssh','-i','C:/Users/Alexey_Matvienko/.ssh/ll_deploy_ed25519','root@192.3.164.184','bash -s'],input=s.encode(),capture_output=True,timeout=40);assert p.returncode==0,p.stderr.decode();(d/'published-server.json').write_bytes(p.stdout);print(p.stdout.decode())
