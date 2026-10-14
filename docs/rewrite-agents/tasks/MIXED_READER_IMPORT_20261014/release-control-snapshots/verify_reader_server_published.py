from pathlib import Path
import json,subprocess,hashlib,re
w=Path(__file__).parent;r=Path('C:/ap/quiz_master');d=r/'docs/rewrite-agents/tasks/MIXED_READER_IMPORT_20261014';e=json.loads((d/'execution-packet.json').read_bytes());p=json.loads((w/'publication-package.json').read_bytes());log=(d/'publish-log.txt').read_text();match=re.search(r'PUBLISHED build=(\S+) image=(sha256:[a-f0-9]{64}) backup=(\S+)',log);assert match and match[1]==p['build_id'] and match[2]==e['image'];backup=match[3]
assert re.fullmatch(re.escape(p['build_id'])+r'-publish-\d{8}T\d{6}Z',backup)
script="set -euo pipefail\ntest \"$(hostname)\" = racknerd-f0269d5\npython3 - <<'PY'\n"+f'''
import subprocess,json,sqlite3,pathlib,hashlib,shutil
def cmd(args):return subprocess.check_output(args,text=True).strip()
dep=json.loads(cmd(['kubectl','get','deploy','quiz-master','-n','quiz-master','-o','json']));assert dep['status']['readyReplicas']==dep['status']['availableReplicas']==1
images={{c['name']:c['image'] for c in dep['spec']['template']['spec']['containers']}};assert images=={{'api':'docker.io/library/quiz-master@{e['image']}','web':'docker.io/library/quiz-master@{e['image']}'}}
pvc=json.loads(cmd(['kubectl','get','pvc','quiz-data','-n','quiz-master','-o','json']));assert pvc['metadata']['uid']=='7fc2428f-4146-4c78-a26d-2347d9f3b7bf' and pvc['status']['phase']=='Bound'
helm=json.loads(cmd(['helm','status','quiz-master','-n','quiz-master','-o','json']));assert helm['version']==54 and helm['info']['status']=='deployed'
api=cmd(['kubectl','exec','-n','quiz-master','deploy/quiz-master','-c','api','--','sha256sum','/app/api']).split()[0];assert api=='f4d69555623aab2b8e1468fccb65256abefc9823d65214799b7e1475d4d9c850'
nginx=cmd(['kubectl','exec','-n','quiz-master','deploy/quiz-master','-c','web','--','sha256sum','/etc/nginx/nginx.conf']).split()[0];assert nginx=='e9add812a138010e443463acb455295103dc69886ca32cd17dafbccfa676d6bc'
nodes=json.loads(cmd(['kubectl','get','nodes','-o','json']));assert all(c['status']==('True' if c['type']=='Ready' else 'False') for n in nodes['items'] for c in n['status']['conditions'] if c['type']=='Ready' or c['type'].endswith('Pressure'))
path=pathlib.Path('/opt/quiz-master/backups/{backup}.sqlite');assert path.parent==pathlib.Path('/opt/quiz-master/backups')
old=sqlite3.connect(path.as_uri()+'?mode=ro',uri=True);live=sqlite3.connect('file:/var/lib/rancher/k3s/storage/pvc-7fc2428f-4146-4c78-a26d-2347d9f3b7bf_quiz-master_quiz-data/quiz.db?mode=ro',uri=True);assert live.execute('pragma integrity_check').fetchone()==('ok',)
preserved={{}}
for table in ['participants','sessions','attempt_bundles','attempt_questions','attempt_answers','feedback_reports']:
 prior=set(old.execute('select * from '+table));current=set(live.execute('select * from '+table));assert prior<=current,table;preserved[table]=len(prior)
prior=set(old.execute("select * from attempts where status='finished'"));current=set(live.execute("select * from attempts where status='finished'"));assert prior<=current;preserved['finished_attempts']=len(prior)
assert {{row[0] for row in old.execute('select id from attempts')}}<={{row[0] for row in live.execute('select id from attempts')}}
rows=live.execute('select * from feedback_reports order by rowid').fetchall();feedback={{'count':len(rows),'status_counts':live.execute('select status,count(*) from feedback_reports group by status').fetchall(),'reports_sha256':hashlib.sha256(json.dumps(rows,ensure_ascii=False,default=str).encode()).hexdigest()}}
assert feedback['count']==26 and feedback['status_counts']==[('open',26)] and feedback['reports_sha256']=='1321177f7fea41271bc0123f3dd67a6abd5242abdb1b7b58ff08c2047880fb13'
free=shutil.disk_usage('/opt/quiz-master').free;assert free>4000000000
print(json.dumps({{'helm_revision':54,'helm_status':'deployed','images':images,'ready':1,'available':1,'pvc_uid':pvc['metadata']['uid'],'api_sha256':api,'nginx_sha256':nginx,'node_ready_no_pressure':True,'disk_free_bytes':free,'backup_sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'preserved_old_rows':preserved,'all_old_attempt_ids_preserved':True,'live_integrity':'ok','feedback':feedback,'scope':'Actual postpublication immutablecomponent/PVC/history/cache/feedback preservation; real open attempts may legitimately finish.'}}))
PY
'''
s=subprocess.run(['ssh','-i','C:/Users/Alexey_Matvienko/.ssh/ll_deploy_ed25519','root@192.3.164.184','bash -s'],input=script.encode(),stdout=subprocess.PIPE,stderr=subprocess.PIPE,timeout=55);assert s.returncode==0,s.stderr.decode();out=json.loads(s.stdout);out['actual_ssh_exit']=s.returncode;(d/'published-server-verification.json').write_text(json.dumps(out,indent=2)+'\n',encoding='utf8');print(json.dumps(out))
