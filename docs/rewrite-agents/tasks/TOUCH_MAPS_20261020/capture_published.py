import subprocess,json
from pathlib import Path
root=Path('E:/Projects/quiz_master')
code=r'''import subprocess,json,socket,os,sqlite3,urllib.request
from pathlib import Path
run=lambda *a:subprocess.check_output(a,text=True)
assert socket.gethostname()=='racknerd-f0269d5'
build='quiz-2026.10.20-touch-b5863403';stage=Path('/opt/quiz-master/releases')/build
d=json.loads(run('kubectl','get','deployment','quiz-master','-n','quiz-master','-o','json'))
h=json.loads(run('helm','history','quiz-master','-n','quiz-master','-o','json'))
pods=json.loads(run('kubectl','get','pods','-n','quiz-master','-l','app=quiz-master','-o','json'))
assert str(h[-1]['revision'])=='76' and h[-1]['status']=='deployed'
assert d['metadata']['annotations']['deployment.kubernetes.io/revision']=='74'
assert run('kubectl','get','pvc','quiz-data','-n','quiz-master','-o','jsonpath={.metadata.uid}')=='7fc2428f-4146-4c78-a26d-2347d9f3b7bf'
statuses=[{'name':c['name'],'ready':c['ready'],'restartCount':c['restartCount'],'imageID':c['imageID']} for p in pods['items'] if not p['metadata'].get('deletionTimestamp') for c in p['status'].get('containerStatuses',[])]
assert len(statuses)==2 and all(c['ready'] and c['restartCount']==0 for c in statuses)
backup=Path('/opt/quiz-master/backups')/(build+'.sqlite')
c=sqlite3.connect(backup.as_uri()+'?mode=ro&immutable=1',uri=True);assert c.execute('pragma integrity_check').fetchone()[0]=='ok'
restored=sqlite3.connect(':memory:');c.backup(restored);assert restored.execute('pragma integrity_check').fetchone()[0]=='ok';restored.close();c.close()
integrity={'physical_backup':'ok','independent_full_memory_restore':'ok'}
proofs=[json.loads(p.read_text()) for p in stage.glob('sql-proof-publish-restore-*.json')];assert len(proofs)==1
import hashlib
proof=proofs[0];assert proof['backup_sha256']==proof['restored_sha256']==hashlib.sha256(backup.read_bytes()).hexdigest()
assert proof['image_docker_id']==json.loads(run('docker','image','inspect','quiz-master:'+build))[0]['Id']
assert proof['input_sha256']==hashlib.sha256((stage/'release-inputs.json').read_bytes()).hexdigest()
check=subprocess.run(['findmnt','--mountpoint',str(stage/'volatile-checks')],capture_output=True);assert check.returncode==1
assert json.loads((stage/'publish-unmount.json').read_text())['mounted'] is False
n=json.loads(run('kubectl','get','nodes','-o','json'))['items'][0];conditions={c['type']:c['status'] for c in n['status']['conditions']}
assert conditions['Ready']=='True' and conditions['DiskPressure']=='False'
s=os.statvfs('/var/lib/rancher/k3s/agent/containerd');percent=s.f_bavail*100/s.f_blocks
with urllib.request.urlopen('https://quiz.kotopedia.org/version.json',timeout=30) as r:v=json.load(r)
assert v['buildId']==build
print(json.dumps({'helm_revision':76,'deployment_revision':74,'version':v,'containers':statuses,'pvc_unchanged':True,'integrity':integrity,'sql_restore_proof':proof,'candidate_ram_unmounted':True,'node_conditions':conditions,'imagefs_available_percent':percent,'capacity_meets_20_percent':s.f_bavail*5>=s.f_blocks},indent=2))
'''
r=subprocess.run(['ssh','-i','C:/Users/Alexey_Matvienko/.ssh/ll_deploy_ed25519','-o','BatchMode=yes','-o','StrictHostKeyChecking=yes','root@192.3.164.184','python3 -'],input=code.encode(),capture_output=True,timeout=60)
if r.returncode: raise RuntimeError(r.stderr.decode())
p=root/'docs/rewrite-agents/tasks/TOUCH_MAPS_20261020/postpublish-state.json';p.write_bytes(r.stdout)
x=json.loads(r.stdout);print(json.dumps({k:x[k] for k in ['helm_revision','deployment_revision','containers','integrity','imagefs_available_percent','capacity_meets_20_percent']}))
