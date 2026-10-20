"""Execute only the separately reviewed, human-authorized cache ID allowlist."""
import base64,hashlib,json,subprocess,sys
from pathlib import Path
here=Path(__file__).parent;plan_bytes=(here/'cache-cleanup-plan.json').read_bytes()
assert hashlib.sha256(plan_bytes).hexdigest()=='3a249e1cc2a51bcbb5860f10dfb72a5a2c572a2a4a41c18e3b6b544f0c9ea42b'
if '--execute' not in sys.argv:print('PLAN ONLY');raise SystemExit(0)
review=[json.loads(l) for l in (here.parent/'photo_catalog_20261019/lazy20-cache-code-review.jsonl').read_text(encoding='utf-8').splitlines() if l.startswith('{')][-1]
assert review['event']=='result' and review['result']['status']=='SUCCESS' and 'ACCEPT' in review['result']['response'] and 'REVISE' not in review['result']['response'].splitlines()[0]
encoded=base64.b64encode(plan_bytes).decode()
code=r'''import base64,json,socket,subprocess,os,fcntl,pathlib,hashlib,re,urllib.request
PLAN=json.loads(base64.b64decode('ENCODED'))
def run(*args):return subprocess.check_output(args,text=True,timeout=90)
assert socket.gethostname()==PLAN['hostname']=='racknerd-f0269d5'
lock=open('/opt/quiz-master/DEPLOY.lock','a');fcntl.flock(lock,fcntl.LOCK_EX|fcntl.LOCK_NB)
def live():
 h=json.loads(run('helm','list','-n','quiz-master','-o','json'));assert len(h)==1 and str(h[0]['revision'])=='77' and h[0]['status']=='deployed'
 d=json.loads(run('kubectl','get','deploy','quiz-master','-n','quiz-master','-o','json'));assert d['metadata']['annotations']['deployment.kubernetes.io/revision']=='75'
 expected='quiz-master:quiz-2026.10.20-atlas-4fc2fd02@sha256:ff432a5964e36a9ad56fd7d60e6b1dbfa87a553ebfe191e180bdf48aa4f8f95f'
 assert {c['image'] for c in d['spec']['template']['spec']['containers']}=={expected}
 assert run('kubectl','get','pvc','quiz-data','-n','quiz-master','-o','jsonpath={.metadata.uid}')=='7fc2428f-4146-4c78-a26d-2347d9f3b7bf'
 with urllib.request.urlopen('https://quiz.kotopedia.org/version.json',timeout=30) as r:assert json.load(r)['buildId']==PLAN['baseline_build']
 return dict(helm_revision=77,deployment_revision=75,pvc_unchanged=True)
def snapshot():
 docker=[]
 for line in run('docker','image','ls','-a','--no-trunc','--digests','--format','{{json .}}').splitlines():
  row=json.loads(line);docker.append(tuple(row[k] for k in ['ID','Repository','Tag','Digest']))
 images=sorted(run('k3s','ctr','-n','k8s.io','images','ls','-q').splitlines())
 backups={}
 for p in sorted(pathlib.Path('/opt/quiz-master/backups').rglob('*')):
  assert not p.is_symlink()
  if p.is_file():
   h=hashlib.sha256()
   with p.open('rb') as f:
    for b in iter(lambda:f.read(1024*1024),b''):h.update(b)
   backups[str(p)]=dict(size=p.stat().st_size,sha256=h.hexdigest())
 return dict(docker=sorted(docker),cri=images,backups=backups)
baseline=live();before=snapshot();free_before=os.statvfs('/').f_bavail*os.statvfs('/').f_frsize
out=[]
for target in PLAN['targets']:
 cache_id=target['ID'];assert re.fullmatch('[a-z0-9]{20,40}',cache_id)
 rows=[json.loads(l) for l in run('docker','buildx','du','--builder','default','--format','json','--filter','id='+cache_id).splitlines() if l.startswith('{')]
 if not rows:out.append(dict(id=cache_id,action='already absent'));continue
 assert len(rows)==1 and rows[0]['ID']==cache_id
 row=rows[0];age=re.fullmatch(r'(\d+) days ago',row['LastUsedAt'])
 assert row['Reclaimable'] and not row['Shared'] and age and int(age[1])>=4
 result=run('docker','buildx','prune','--builder','default','--force','--filter','id='+cache_id,'--filter','until=72h')
 out.append(dict(id=cache_id,result=result))
after=snapshot();assert before==after,'Protected images/backups changed: stop and investigate'
live();s=os.statvfs('/');assert s.f_bavail*5>=s.f_blocks
print(json.dumps(dict(baseline=baseline,actions=out,protected_before=before,protected_after=after,images_backups_identical=True,free_before=free_before,free_after=s.f_bavail*s.f_frsize,available_percent=s.f_bavail*100/s.f_blocks,ext4_reserve_changed=False),indent=2))
'''.replace('ENCODED',encoded)
r=subprocess.run(['ssh','-i','C:/Users/Alexey_Matvienko/.ssh/ll_deploy_ed25519','-o','BatchMode=yes','-o','StrictHostKeyChecking=yes','root@192.3.164.184','python3 -'],input=code,text=True,capture_output=True,timeout=500)
(here/'cache-cleanup.stdout').write_text(r.stdout,encoding='utf-8');(here/'cache-cleanup.stderr').write_text(r.stderr,encoding='utf-8')
if r.returncode:print(r.stderr[-2200:]);raise SystemExit(r.returncode)
d=json.loads(r.stdout);(here/'cache-cleanup-evidence.json').write_text(json.dumps(d,indent=2),encoding='utf-8');print(json.dumps({k:v for k,v in d.items() if k not in ['actions','protected_before','protected_after']},indent=2))
