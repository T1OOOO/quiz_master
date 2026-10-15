if not __debug__:
    raise RuntimeError('publication executor refuses optimized Python')

from pathlib import Path
import json,hashlib,subprocess,re
r=Path('C:/ap/quiz_master');d=r/'docs/rewrite-agents/tasks/READER303_RELEASE_20261015';w=r/'.run/reader303_release_20261015'
if any((d/name).exists() or (d/name).is_symlink() for name in ('publish-log.txt','publish-exit.json')):
 raise RuntimeError('existing publication evidence; inspect outcome before any repeat')
def read(p):return json.loads(p.read_bytes())
def h(p):return hashlib.sha256(p.read_bytes()).hexdigest()
a=read(d/'execution-acceptance.json');e=read(d/'execution-packet.json');assert a['actual_hub_state']=='ACCEPTED' and a['actual_cli_exit']==0 and a['reviewer_provider']=='claude'
package_pin=read(d/'package-receipt-pin.json');package_receipt=Path(package_pin['path']).resolve()
assert package_receipt.is_relative_to(w.resolve()) and package_receipt.name=='package-preparation.json' and h(package_receipt)==package_pin['sha256'],'actual package receipt pin differs'
assert str(package_receipt)==e['package_receipt_path'] and package_pin['sha256']==e['package_receipt_sha256'],'reviewed package receipt path/hash differs'
p=read(package_receipt)
assert p['status']=='PREPARED_NOT_EXECUTED' and p['build_id']==e['build_id']=='quiz-2026.10.15-reader303-14b7da4'
assert p['frozen_commit']==e['source_commit']=='14b7da43c3e43642d60859f5053ee6d809c2379e'
assert Path(p['archive']).resolve().parent==package_receipt.parent and Path(p['archive']).name==p['build_id']+'.tar.gz','package archive/receipt boundary differs'
assert a.get('publication_executor_sha256')==h(Path(__file__)), 'publication executor changed after review'
assert a['execution_packet_sha256']==h(d/'execution-packet.json') and a['publish_script_sha256']==e['publish_script_sha256']==h(d/'publish-preview.sh') and a['package_sha256']==e['package_sha256']==p['archive_sha256'] and a['image']==e['image']
task=a.get('execution_review_task_id','')
assert re.fullmatch('task-[0-9a-f]{32}',task) and task!='task-1f1ca79d0de24c93954406a82768c20f','a new exact execution review task is required'
callback=a['actual_reviews'][task];assert callback['actual_response']['state']=='ACCEPTED' and callback['call']['arguments']['verdict']=='accept' and callback['actual_response']['assignee']!=callback['actual_response']['reviewer']
assert callback['call']['action']=='review' and callback['call']['arguments']['task_id']==callback['actual_response']['id']==task
assert callback['call']['arguments']['error_count']==0 and 'execution-packet sha256 '+h(d/'execution-packet.json') in callback['call']['arguments']['note']
assert h(Path(p['archive']))==p['archive_sha256']
for pair in [('14b7da43c3e43642d60859f5053ee6d809c2379e','HEAD'),('14b7da43c3e43642d60859f5053ee6d809c2379e',)]:
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
