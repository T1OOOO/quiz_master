from pathlib import Path
import ast,json,subprocess
r=Path('C:/ap/quiz_master');d=r/'.run/planet_release_20261011';m=json.loads((d/'package.json').read_text());stage=Path(m['stage']);build=m['version']['buildId']
changed=subprocess.check_output(['git','diff','--name-only','317b339','d228c9e','--','next/server'],cwd=r,text=True).splitlines()
assert changed and all(p.endswith('_test.go') for p in changed)
s=(stage/'rehearse.py').read_text();sandbox='rehearsal-strict-revisions'
s=s.replace('rehearsal-final',sandbox).replace("'/opt/quiz-master/backups/'+build+'.sqlite'", "'/opt/quiz-master/backups/'+build+'-strict.sqlite'")
needle="   actual['source']['uri']=expected_uri";assert s.count(needle)==1
s=s.replace(needle,"   assert actual['revision']==json.loads((root/'expected-staging-revisions.json').read_text())[qid][actual['question_id']], 'Strict staging revision mismatch'\n"+needle)
s=s.replace(" for qid in ['cinema-encore-20261011'", " assert after[3]-before[3]==131, 'Unexpected bundle-cache growth'\n for qid in ['cinema-encore-20261011'",1)
s=s.replace("try:req('/v1/catalog?quiz_id=lotr')", "try:\n req('/v1/catalog?quiz_id=lotr')\n assert len(req('/v1/history',token=token))==3\n assert req('/v1/history/'+attempt['attempt_id'],token=token)==finish")
ast.parse(s);(d/'rehearse-strict.py').write_text(s)
key='C:/Users/Alexey_Matvienko/.ssh/ll_deploy_ed25519';target='root@192.3.164.184';remote='/opt/quiz-master/releases/'+build
for name in ['expected-staging-revisions.json','rehearse-strict.py']:subprocess.run(['scp','-i',key,str(d/name),target+':'+remote+'/'+name],check=True)
script=f'''set -euo pipefail
test "$(hostname)" = racknerd-f0269d5
cd {remote}
exec 9>/opt/quiz-master/DEPLOY.lock
flock -n 9
test "$(kubectl get deploy quiz-master -n quiz-master -o jsonpath='{{.spec.template.spec.containers[0].image}}')" = {m['baseline_image']}
python3 backup_sqlite.py /opt/quiz-master/backups/{build}-strict.sqlite
python3 rehearse-strict.py {build}
'''
res=subprocess.run(['ssh','-i',key,target,script],text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
(d/'strict-rehearsal.txt').write_text(res.stdout);print(res.stdout);assert res.returncode==0
