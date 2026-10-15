from pathlib import Path
import json,hashlib,subprocess
r=Path('C:/ap/quiz_master');d=r/'docs/rewrite-agents/tasks/READER_PUBLIC_RELEASE_20261015';w=r/'.run/reader_public_release_20261015'
def read(p):return json.loads(p.read_bytes())
def h(p):return hashlib.sha256(p.read_bytes()).hexdigest()
a=read(d/'execution-acceptance.json');e=read(d/'execution-packet.json');p=read(w/'package-v1/package-preparation.json');assert a['actual_hub_state']=='ACCEPTED' and a['actual_cli_exit']==0 and a['reviewer_provider']=='claude'
assert a.get('publication_executor_sha256')==h(Path(__file__)), 'publication executor changed after review'
assert a['execution_packet_sha256']==h(d/'execution-packet.json') and a['publish_script_sha256']==e['publish_script_sha256']==h(d/'publish-preview.sh') and a['package_sha256']==e['package_sha256']==p['archive_sha256'] and a['image']==e['image']
callback=a['actual_reviews']['task-25944ceb58344d32958bf3e43788c86c'];assert callback['actual_response']['state']=='ACCEPTED' and callback['call']['arguments']['verdict']=='accept' and callback['actual_response']['assignee']!=callback['actual_response']['reviewer']
assert h(Path(p['archive']))==p['archive_sha256']
for pair in [('06dfa0bca56c144e4f6c8c06cb1e7b258e032c9b','HEAD'),('06dfa0bca56c144e4f6c8c06cb1e7b258e032c9b',)]:
 assert not subprocess.check_output(['git','diff','--name-only',*pair,'--','next','quizzes','metadata','study/question_articles'],cwd=r).strip()
script=(d/'publish-preview.sh').read_bytes();output=b'';code='not_started'
try:
 result=subprocess.run(['ssh','-i','C:/Users/Alexey_Matvienko/.ssh/ll_deploy_ed25519','root@192.3.164.184','bash -s -- publish'],input=script,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=600)
 output=result.stdout;code=result.returncode
except subprocess.TimeoutExpired as exc:
 output=exc.stdout or b'';code='timeout'
 raise
finally:
 (d/'publish-log.txt').write_bytes(output);(d/'publish-exit.json').write_text(json.dumps({'actual_exit':code}))
print(output.decode(errors='replace'));assert code==0
