from pathlib import Path
import subprocess,json,base64
here=Path(__file__).parent;before=json.loads((here/'cache-cleanup-evidence.json').read_text())['protected_before']
encoded=base64.b64encode(json.dumps(before).encode()).decode()
code=r'''import json,base64,subprocess,pathlib,hashlib,os
before=json.loads(base64.b64decode('ENCODED'))
run=lambda *a:subprocess.check_output(a,text=True,timeout=60)
docker=[]
for line in run('docker','image','ls','-a','--no-trunc','--digests','--format','{{json .}}').splitlines():
 r=json.loads(line);docker.append([r[k] for k in ['ID','Repository','Tag','Digest']])
cri=run('k3s','ctr','-n','k8s.io','images','ls','-q').splitlines()
assert all(x in docker for x in before['docker']) and set(before['cri'])<=set(cri)
for name,expected in before['backups'].items():
 p=pathlib.Path(name);assert p.is_file() and not p.is_symlink() and p.stat().st_size==expected['size'];h=hashlib.sha256()
 with p.open('rb') as f:
  for b in iter(lambda:f.read(1024*1024),b''):h.update(b)
 assert h.hexdigest()==expected['sha256']
reserved=run('tune2fs','-l','/dev/vda2');assert 'Reserved block count:     1271337' in reserved
s=os.statvfs('/')
print(json.dumps(dict(retained_baseline_docker_references=len(before['docker']),retained_baseline_cri_references=len(before['cri']),retained_physical_backup_files=len(before['backups']),all_baseline_images_and_backup_hashes_preserved=True,current_docker_references=len(docker),current_cri_references=len(cri),ext4_reserved_blocks=1271337,ext4_reserve_still5percent=True,capacity_gate_passed=s.f_bavail*5>=s.f_blocks,available_bytes=s.f_bavail*s.f_frsize,available_percent=s.f_bavail*100/s.f_blocks)))
'''.replace('ENCODED',encoded)
r=subprocess.run(['ssh','-i','C:/Users/Alexey_Matvienko/.ssh/ll_deploy_ed25519','-o','BatchMode=yes','-o','StrictHostKeyChecking=yes','root@192.3.164.184','python3 -'],input=code,text=True,capture_output=True,timeout=90)
if r.returncode:print(r.stderr);raise SystemExit(r.returncode)
p=here.parents[1]/'docs/rewrite-agents/tasks/LAZY_FEEDBACK20_20261020/retention-latest.json';p.write_text(r.stdout,encoding='utf-8');print(r.stdout)
