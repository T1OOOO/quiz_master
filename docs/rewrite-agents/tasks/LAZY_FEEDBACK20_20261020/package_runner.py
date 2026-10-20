from pathlib import Path
import subprocess,sys,json
r=Path('E:/Projects/quiz_master');o=r/'.run/lazy_feedback20_20261020';d=r/'docs/rewrite-agents/tasks/LAZY_FEEDBACK20_20261020'
args=[sys.executable,str(d/'prepare_package.py'),'--source',str(r/'.run/feedback43_20261019/verify-source'),'--destination',str(o/'package-2af0ab3f'),'--baseline-package',str(r/'.run/atlas_mobile_20261020/package-4fc2fd02'),'--baseline-inputs',str(o/'baseline-inputs77.json'),'--preflight',str(o/'preflight.txt')]
with (o/'package.log').open('w',encoding='utf-8') as f:subprocess.run(args,cwd=r,stdout=f,stderr=subprocess.STDOUT,check=True)
args=[sys.executable,str(d/'release_executor.py'),'--preflight',str(o/'preflight.txt'),'--package',str(o/'package-2af0ab3f'),'--build-id','quiz-2026.10.20-lazy-2af0ab3f']
with (o/'release-plan.json').open('w',encoding='utf-8') as f:subprocess.run(args,cwd=r,stdout=f,check=True)
print((o/'package.log').read_text())
