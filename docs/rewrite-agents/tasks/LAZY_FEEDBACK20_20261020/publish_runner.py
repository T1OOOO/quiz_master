from pathlib import Path
import subprocess,sys,json
r=Path('E:/Projects/quiz_master');o=r/'.run/lazy_feedback20_20261020';d=r/'docs/rewrite-agents/tasks/LAZY_FEEDBACK20_20261020'
events=[json.loads(x) for x in (r/'.run/photo_catalog_20261019/lazy20-image-review.jsonl').read_text(encoding='utf-8').splitlines() if x.startswith('{')]
result=next(x['result'] for x in events if x.get('event')=='result');response=result['response']
assert result['status']=='SUCCESS' and 'ACCEPT' in response and json.loads((o/'prepared-receipt.json').read_text())['image'].rsplit('sha256:',1)[1] in response
(d/'prepared-image-review.md').write_text(response.rstrip()+'\n',encoding='utf-8',newline='\n')
receipt=(o/'prepared-receipt.json').read_bytes();assert json.loads(receipt)==json.loads((d/'prepared-image-evidence.json').read_text())['receipt']
(o/'reviewed-receipt.json').write_bytes(receipt)
subprocess.run([sys.executable,str(o/'preflight_capture.py')],cwd=r,check=True)
x=json.loads((o/'preflight.txt').read_text().splitlines()[0]);assert x['revision']=='77' and x['disk']['available_percent']>=20
(d/'prepublish-state.json').write_text(json.dumps(x,indent=2)+'\n',encoding='utf-8')
args=[sys.executable,str(d/'release_executor.py'),'--preflight',str(o/'preflight.txt'),'--package',str(o/'package-2af0ab3f'),'--build-id','quiz-2026.10.20-lazy-2af0ab3f','--ssh-target','root@192.3.164.184','--identity-file','C:/Users/Alexey_Matvienko/.ssh/ll_deploy_ed25519','--execute','--acknowledge-production','--phase','publish','--reviewed-receipt',str(o/'reviewed-receipt.json')]
with (o/'publish.log').open('w',encoding='utf-8') as log:subprocess.run(args,cwd=r,stdout=log,stderr=subprocess.STDOUT,check=True)
print('publish controller EXIT0')
