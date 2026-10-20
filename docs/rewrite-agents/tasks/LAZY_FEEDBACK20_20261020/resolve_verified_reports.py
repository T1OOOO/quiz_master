"""Resolve only exact reviewed comments after scoped public78 proof."""
import base64,json,subprocess,hashlib
from pathlib import Path
r=Path('E:/Projects/quiz_master');d=r/'docs/rewrite-agents/tasks/LAZY_FEEDBACK20_20261020'
proof=json.loads((d/'postpublish-state.json').read_text());assert proof['helm_revision']==78 and proof['deployment_revision']==76
mobile=json.loads((d/'public-mobile-checks.json').read_text(encoding='utf-8'));assert mobile['build_id']=='quiz-2026.10.20-lazy-2af0ab3f' and mobile['status']=='scoped_mobile_checks_pass_with_open_followups'
review=json.loads((d/'feedback-resolution-review.json').read_text());assert review['decision']=='ACCEPT' and review['reviewer_provider']=='google'
assert review['evidence_packet_sha256']==hashlib.sha256((d/'feedback-review-packet.json').read_bytes()).hexdigest()
candidates=json.loads((d/'feedback-resolution-candidates.json').read_text(encoding='utf-8'))
assert [x['ordinal'] for x in candidates]==review['accepted_ordinals']
rows=json.loads((r/'.run/photo_catalog_20261019/private/reports-latest.json').read_text(encoding='utf-8'))['reports']
chosen=[]
for item in candidates:
 row=rows[item['ordinal']-1]
 assert hashlib.sha256(row['comment'].encode()).hexdigest()==item['comment_sha256']
 chosen.append(dict(ordinal=item['ordinal'],id=row['id'],comment=row['comment']))
assert [x['ordinal'] for x in chosen]==[67,69,70]
payload=base64.b64encode(json.dumps(chosen,ensure_ascii=False).encode()).decode()
code=r'''import base64,json,sqlite3,subprocess,urllib.request,fcntl,socket,re
assert socket.gethostname()=='racknerd-f0269d5'
run=lambda *a:subprocess.check_output(a,text=True)
items=json.loads(base64.b64decode('PAYLOAD'))
dbpath='/var/lib/rancher/k3s/storage/pvc-7fc2428f-4146-4c78-a26d-2347d9f3b7bf_quiz-master_quiz-data/quiz.db'
with open('/opt/quiz-master/DEPLOY.lock','a') as lock:
 fcntl.flock(lock.fileno(),fcntl.LOCK_EX|fcntl.LOCK_NB)
 dep=json.loads(run('kubectl','get','deploy','quiz-master','-n','quiz-master','-o','json'))
 assert dep['metadata']['annotations']['deployment.kubernetes.io/revision']=='76'
 assert dep['spec']['template']['metadata']['annotations']['quiz-master/build-id']=='quiz-2026.10.20-lazy-2af0ab3f'
 assert run('kubectl','get','pvc','quiz-data','-n','quiz-master','-o','jsonpath={.metadata.uid}')=='7fc2428f-4146-4c78-a26d-2347d9f3b7bf'
 with urllib.request.urlopen('https://quiz.kotopedia.org/version.json',timeout=30) as response:assert json.load(response)['buildId']=='quiz-2026.10.20-lazy-2af0ab3f'
 assert {c['image'] for c in dep['spec']['template']['spec']['containers']}=={'quiz-master:quiz-2026.10.20-lazy-2af0ab3f@sha256:088725db5d3cc0c03031d394094076bda15366c5951a67c47501b05e5cbd6a01'}
 api=next(x for x in dep['spec']['template']['spec']['containers'] if x['name']=='api')
 env=next(x for x in api['env'] if x['name']=='QM_FEEDBACK_ADMIN_TOKEN')
 if 'value' in env:token=env['value']
 else:
  ref=env['valueFrom']['secretKeyRef'];secret=json.loads(run('kubectl','get','secret',ref['name'],'-n','quiz-master','-o','json'));token=base64.b64decode(secret['data'][ref['key']]).decode()
 assert len(token)>=32 and not any(c.isspace() for c in token)
 conn=sqlite3.connect('file:'+dbpath+'?mode=ro',uri=True);before=dict(conn.execute('select status,count(*) from feedback_reports group by status').fetchall());out=[]
 for item in items:
  assert re.fullmatch(r'rep_[0-9a-f]{32}',item['id'])
  row=conn.execute('select comment,status from feedback_reports where id=?',(item['id'],)).fetchone();assert row and row[0]==item['comment']
  if row[1]=='open':
   req=urllib.request.Request('https://quiz.kotopedia.org/v1/admin/reports/'+item['id']+'/status',data=b'{"status":"resolved"}',method='POST',headers={'Authorization':'Bearer '+token,'Content-Type':'application/json'})
   with urllib.request.urlopen(req,timeout=30) as response:answer=json.load(response)
   assert answer['id']==item['id'] and answer['status']=='resolved' and answer['comment']==item['comment']
  else:assert row[1]=='resolved'
  assert conn.execute('select status from feedback_reports where id=?',(item['id'],)).fetchone()[0]=='resolved'
  out.append({'ordinal':item['ordinal'],'status':'resolved'})
 after=dict(conn.execute('select status,count(*) from feedback_reports group by status').fetchall());conn.close()
 print(json.dumps({'resolved':out,'before':before,'after':after,'only_individually_verified_reports':True}))
'''.replace('PAYLOAD',payload)
p=subprocess.run(['ssh','-i','C:/Users/Alexey_Matvienko/.ssh/ll_deploy_ed25519','-o','BatchMode=yes','-o','StrictHostKeyChecking=yes','root@192.3.164.184','python3 -'],input=code.encode(),capture_output=True,timeout=90)
if p.returncode:raise RuntimeError(p.stderr.decode()[-1200:])
out=json.loads(p.stdout);(d/'feedback-status-outcome.json').write_text(json.dumps(out,indent=2)+'\n',encoding='utf-8');print(json.dumps(out))
