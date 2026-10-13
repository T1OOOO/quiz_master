from pathlib import Path
import hashlib,json,re,subprocess
r=Path('C:/ap/quiz_master');w=r/'.run/home_alone_release_20261013';m=json.loads((w/'package.json').read_text());e=json.loads((w/'execution-packet.json').read_text());review=json.loads((w/'execution-acceptance.json').read_text()) if '--preview' not in __import__('sys').argv else {'actual_hub_state':'PREVIEW_ONLY','package_sha256':m['archive_sha256'],'image':e['image']}
assert (review['actual_hub_state']=='ACCEPTED' or '--preview' in __import__('sys').argv) and review['package_sha256']==m['archive_sha256'] and review['image']==e['image']
assert hashlib.sha256(Path(m['archive']).read_bytes()).hexdigest()==m['archive_sha256']
assert hashlib.sha256((w/'remote-prepare.txt').read_bytes()).hexdigest()==e['remote_log_sha256']
subprocess.run(['git','merge-base','--is-ancestor',m['metadata']['commit'],'HEAD'],cwd=r,check=True)
assert not subprocess.check_output(['git','diff','--name-only',m['metadata']['commit'],'HEAD','--','next','quizzes','metadata','study/question_articles'],cwd=r,text=True).strip(), 'Committed runtime source changed after frozen release source'
qa_path=r/'docs/rewrite-agents/tasks/HOME_ALONE_RELEASE_20261013/browser-proof.json';qa=json.loads(qa_path.read_text());assert qa['new_article_sheets_opened_closed']==2 and qa['actual_ui_correct_answers']==2 and qa['source_controls_each']==[2,3] and qa['sdk3_actual_exit']==0 and qa['feedback_submit_requests']==0 and qa['ports18089_18092_free'];assert hashlib.sha256(qa_path.read_bytes()).hexdigest()==e['local_browser_evidence_sha256']
stage=Path(m['stage']);script=(stage/'cutover.sh').read_text();split='quiz_image="quiz-master:$quiz_build"';assert script.count(split)==1
prefix=script.split(split)[0]
capacity_anchor='quiz_run="$quiz_build-cutover-$(date -u +%Y%m%dT%H%M%SZ)"'
assert prefix.count(capacity_anchor)==1
prefix=prefix.replace(capacity_anchor,'test "$(df --output=avail -B1 /opt/quiz-master | tail -1)" -gt 4000000000\n'+capacity_anchor)
assert re.fullmatch(r'sha256:[a-f0-9]{64}',e['image']) and re.fullmatch(re.escape(m['metadata']['buildId'])+r'-cutover-\d{8}T\d{6}Z-values\.yaml',e['values'])
append=f"""
quiz_digest='{e['image']}'
quiz_values='{e['values']}'
echo '{e['durable_archive_sha256']}  {e['durable_archive']}' | sha256sum -c -
k3s ctr images ls | awk -v image="docker.io/library/quiz-master@$quiz_digest" '$1==image {{found=1}} END {{exit !found}}'
helm lint --strict chart -n quiz-master -f "$quiz_values"
helm template quiz-master chart -n quiz-master -f "$quiz_values" > "$quiz_run-publish-rendered.yaml"
test "$(grep -Fc "docker.io/library/quiz-master@$quiz_digest" "$quiz_run-publish-rendered.yaml")" -eq 2
kubectl apply --dry-run=server -n quiz-master -f "$quiz_run-publish-rendered.yaml"
helm upgrade quiz-master chart -n quiz-master -f "$quiz_values" --atomic --wait --timeout 180s
test "$(kubectl get deploy quiz-master -n quiz-master -o jsonpath='{{.spec.template.spec.containers[0].image}}')" = "docker.io/library/quiz-master@$quiz_digest"
curl -fsS https://quiz.kotopedia.org/version.json | python3 -c 'import json,sys; actual=json.load(sys.stdin); expected=json.load(open("web/version.json")); actual==expected or sys.exit("Public version mismatch"); print(actual)'
test "$(curl -fsS https://quiz.kotopedia.org/main.dart.js | sha256sum | cut -d ' ' -f 1)" = {m['metadata']['main_dart_js_sha256']}
test "$(curl -fsS https://quiz.kotopedia.org/assets/assets/study/question-articles.json | sha256sum | cut -d ' ' -f 1)" = 98f69869f0188cdc92ecd93c4fc7d269a71800bcb2263a25fb060721cf21c433
"""
# Reuse the reviewed identity/lock/checksum/fresh backup/rehearsal prefix; consume the already reviewed immutable image without rebuilding it.
script=prefix+append
if '--preview' not in __import__('sys').argv: assert hashlib.sha256(script.encode('utf-8')).hexdigest()==e['publish_script_sha256'], 'Publisher differs from reviewed shell script'
(w/'publish-prepared-preview.sh').write_text(script,newline='\n')
subprocess.run(['ssh','-i','C:/Users/Alexey_Matvienko/.ssh/ll_deploy_ed25519','root@192.3.164.184','bash -n'],input=script.encode('utf8'),check=True)
if '--preview' in __import__('sys').argv: print('Preview syntax passed; no publication'); raise SystemExit(0)
assert 'docker build' not in script, 'Publication must consume the reviewed immutable image'
res=subprocess.run(['ssh','-i','C:/Users/Alexey_Matvienko/.ssh/ll_deploy_ed25519','root@192.3.164.184','bash -s -- publish'],input=script.encode('utf-8'),stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=600)
output=res.stdout.decode('utf-8',errors='replace')
(w/'publish.txt').write_text(output);(w/'publish-exit.json').write_text(json.dumps({'actual_exit':res.returncode}));print(output);assert res.returncode==0
