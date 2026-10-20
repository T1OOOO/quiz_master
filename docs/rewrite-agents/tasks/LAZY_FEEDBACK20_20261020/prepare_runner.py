from pathlib import Path
import subprocess,sys,json
r=Path('E:/Projects/quiz_master');o=r/'.run/lazy_feedback20_20261020';d=r/'docs/rewrite-agents/tasks/LAZY_FEEDBACK20_20261020'
cleaned=json.loads((o/'cache-cleanup-evidence.json').read_text());assert cleaned['images_backups_identical'] and cleaned['available_percent']>=20 and not cleaned['ext4_reserve_changed']
subprocess.run([sys.executable,str(o/'preflight_capture.py')],cwd=r,check=True)
args=[sys.executable,str(d/'release_executor.py'),'--preflight',str(o/'preflight.txt'),'--package',str(o/'package-2af0ab3f'),'--build-id','quiz-2026.10.20-lazy-2af0ab3f','--ssh-target','root@192.3.164.184','--identity-file','C:/Users/Alexey_Matvienko/.ssh/ll_deploy_ed25519','--execute','--acknowledge-production','--phase','prepare']
with (o/'prepare.log').open('w',encoding='utf-8') as log:subprocess.run(args,cwd=r,stdout=log,stderr=subprocess.STDOUT,check=True)
print('prepare controller EXIT0')
