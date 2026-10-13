from pathlib import Path
import subprocess,json,hashlib,re
r=Path('C:/ap/quiz_master');w=r/'.run/film_craft_release_20261013';d=r/'docs/rewrite-agents/tasks/FILM_CRAFT_RELEASE_20261013';m=json.loads((d/'package-current.json').read_text());b=m['metadata']['buildId'];sha=m['archive_sha256'];review=json.loads((d/'static-review-v3.json').read_text())
assert review['actual_hub_state']=='ACCEPTED' and review['package_sha256']==sha and review['producer_sha256']==hashlib.sha256((r/'docs/rewrite-agents/tasks/FILM_CRAFT_RELEASE_20261013/worker/prepare_film_craft_release.py').read_bytes()).hexdigest()
assert re.fullmatch(r'quiz-2026\.10\.13-film-craft-[a-f0-9]{7}',b)
assert hashlib.sha256(Path(m['archive']).read_bytes()).hexdigest()==sha
qa=json.loads((d/'browser-proof.json').read_text());assert qa['new_article_sheets_opened_closed']==4 and qa['actual_clean_ui_answers']==4 and qa['actual_clean_server_score']==4 and qa['source_controls_each']==[2,2,2,2] and qa['clean_sdk2_actual_exit']==0 and qa['clean_qa_wrapper_actual_exit']==0 and qa['feedback_submissions']==0 and qa['ports18090_18093_free']
key='C:/Users/Alexey_Matvienko/.ssh/ll_deploy_ed25519';target='root@192.3.164.184'
guard=f'''set -euo pipefail
test "$(hostname)" = racknerd-f0269d5
test "$(readlink -f /opt/quiz-master/releases)" = /opt/quiz-master/releases
test "$(kubectl get deploy quiz-master -n quiz-master -o jsonpath='{{.spec.template.spec.containers[0].image}}')" = {m['baseline_input']['image']}
test "$(kubectl get pvc quiz-data -n quiz-master -o jsonpath='{{.metadata.uid}}')" = 7fc2428f-4146-4c78-a26d-2347d9f3b7bf
exec 7>/opt/quiz-master/DEPLOY.lock
flock -n 7
test "$(readlink -f /opt/quiz-master/releases/{b})" = /opt/quiz-master/releases/{b}
echo 'e6a26225619149708c8fb2c3ac93a42cadf095efb68c9b6d9136549a20163083  /opt/quiz-master/releases/{b}.tar.gz' | sha256sum -c -
test ! -e /opt/quiz-master/releases/{b}.failed-v1-171556Z
test ! -e /opt/quiz-master/releases/{b}.failed-v1-171556Z.tar.gz
mv -- /opt/quiz-master/releases/{b} /opt/quiz-master/releases/{b}.failed-v1-171556Z
mv -- /opt/quiz-master/releases/{b}.tar.gz /opt/quiz-master/releases/{b}.failed-v1-171556Z.tar.gz
test ! -e /opt/quiz-master/releases/{b}
test ! -e /opt/quiz-master/releases/{b}.tar.gz
flock -u 7
exec 7>&-
test "$(df --output=avail -B1 /opt/quiz-master | tail -1)" -gt 4000000000
'''
p=subprocess.run(['ssh','-i',key,target,'bash -s'],input=guard.encode(),stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=40);assert p.returncode==0,p.stdout.decode(errors='replace')[-800:]
subprocess.run(['scp','-i',key,m['archive'],target+':/opt/quiz-master/releases/'+b+'.tar.gz'],check=True,timeout=90)
script=f'''set -euo pipefail
test "$(hostname)" = racknerd-f0269d5
exec 8>/opt/quiz-master/DEPLOY.lock
flock -n 8
test "$(readlink -f /opt/quiz-master/releases)" = /opt/quiz-master/releases
test "$(kubectl get deploy quiz-master -n quiz-master -o jsonpath='{{.spec.template.spec.containers[0].image}}')" = {m['baseline_input']['image']}
test "$(kubectl get pvc quiz-data -n quiz-master -o jsonpath='{{.metadata.uid}}')" = 7fc2428f-4146-4c78-a26d-2347d9f3b7bf
echo '{sha}  /opt/quiz-master/releases/{b}.tar.gz' | sha256sum -c -
test ! -e /opt/quiz-master/releases/{b}
mkdir /opt/quiz-master/releases/{b}
test "$(readlink -f /opt/quiz-master/releases/{b})" = /opt/quiz-master/releases/{b}
tar -xzf /opt/quiz-master/releases/{b}.tar.gz --no-same-owner --strip-components=1 -C /opt/quiz-master/releases/{b}
cd /opt/quiz-master/releases/{b}
sha256sum -c checksums.txt > candidate-v3-checksums.log
bash -n cutover.sh
python3 -c 'from pathlib import Path; compile(Path("rehearse.py").read_text(), "rehearse.py", "exec")'
flock -u 8
exec 8>&-
test "$(df --output=avail -B1 /opt/quiz-master | tail -1)" -gt 4000000000
bash cutover.sh prepare 2>&1 | tee prepare-v3.log
'''
(w/'remote-prepare-v3-script.sh').write_bytes(script.encode())
p=subprocess.run(['ssh','-i',key,target,'bash -s'],input=script.encode(),stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=600)
(w/'remote-prepare-v3.txt').write_bytes(p.stdout);(w/'remote-prepare-v3-exit.json').write_bytes(json.dumps({'actual_exit':p.returncode}).encode());print(p.stdout.decode(errors='replace')[-2200:]);assert p.returncode==0,'Actual preparation failed; preserve artifacts and logs, no publication.'
