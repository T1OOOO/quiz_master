from pathlib import Path
import json,hashlib,subprocess
r=Path('C:/ap/quiz_master');d=r/'docs/rewrite-agents/tasks/LIBRARY_RELEASE_20261014';w=Path(__file__).parent
def read(p):return json.loads(p.read_bytes())
def h(p):return hashlib.sha256(p.read_bytes()).hexdigest()
a=read(d/'execution-acceptance.json');e=read(d/'execution-packet.json');p=read(w/'publication-package.json');assert a['actual_hub_state']=='ACCEPTED' and a['actual_cli_exit']==0 and a['reviewer_provider']=='claude'
assert a.get('publication_executor_sha256')==h(Path(__file__)), 'publication executor changed after review'
assert a['execution_packet_sha256']==h(d/'execution-packet.json') and a['publish_script_sha256']==e['publish_script_sha256']==h(d/'publish-preview.sh') and a['package_sha256']==e['package_sha256']==p['archive_sha256'] and a['image']==e['image']
callback=a['actual_reviews']['task-1b436d92277c476f8d741a6e2b109eee'];assert callback['actual_response']['state']=='ACCEPTED' and callback['call']['arguments']['verdict']=='accept' and callback['actual_response']['assignee']!=callback['actual_response']['reviewer']
assert h(Path(p['archive']))==p['archive_sha256']
for pair in [('09b19cc2d0fa8463a3e53e9a5f51981e657e2a48','HEAD'),('09b19cc2d0fa8463a3e53e9a5f51981e657e2a48',)]:
 assert not subprocess.check_output(['git','diff','--name-only',*pair,'--','next','quizzes','metadata','study/question_articles'],cwd=r).strip()
script=(d/'publish-preview.sh').read_bytes();result=subprocess.run(['ssh','-i','C:/Users/Alexey_Matvienko/.ssh/ll_deploy_ed25519','root@192.3.164.184','bash -s -- publish'],input=script,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=300)
(d/'publish-log.txt').write_bytes(result.stdout);(d/'publish-exit.json').write_text(json.dumps({'actual_exit':result.returncode}));print(result.stdout.decode(errors='replace'));assert result.returncode==0
