from pathlib import Path
import json,hashlib,subprocess,re
r=Path('C:/ap/quiz_master');w=Path(__file__).parent;d=r/'docs/rewrite-agents/tasks/ACTING_CRAFT_RELEASE_20261014';b=d/'root-public-browser';load=lambda p:json.loads(p.read_text(encoding='utf-8-sig'));sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
assert load(d/'publish-exit.json')['actual_exit']==0 and load(d/'published-server-verification.json')['helm']['revision']==51
assert load(d/'public-verification.json')['live_question_article_bindings']==139
wants=[];pids=[]
for mode,count in [('actor',8),('music',4)]:
 flow=load(b/(mode+'-flow-summary.json'));assert flow['actual_flow_exit']==0 and flow['starting_question']==1 and len(flow['questions'])==count and all(len(q['article_source_controls'])==2 for q in flow['questions'])
 paths=json.loads(load(b/(mode+'-own-attempt-paths.json'))['stdout']);ids={p.split('/')[3] for p in paths};assert len(ids)==1;attempt=ids.pop();assert re.fullmatch(r'a-[a-f0-9]{8}-(?:[a-f0-9]{4}-){3}[a-f0-9]{12}',attempt)
 wants.append({'mode':mode,'id':attempt,'expected_score':count})
 assert load(b/(mode+'-close.json'))['actual_exit']==0 and not json.loads(load(b/(mode+'-inactive.json'))['stdout'])['data']['active']
 assert load(b/(mode+'-console-errors.json'))['actual_exit']==0 and not load(b/(mode+'-console-errors.json'))['stdout'].strip()
 pids.append(json.loads(load(b/(mode+'-active-session.json'))['stdout'])['data']['pid'])
for pid in pids:assert subprocess.run(['powershell','-NoProfile','-Command',f'if (Get-Process -Id {pid} -ErrorAction SilentlyContinue) {{ exit 1 }}'],capture_output=True).returncode==0
script='''set -euo pipefail
test "$(hostname)" = racknerd-f0269d5
python3 - <<'PY'
import sqlite3,json,hashlib,re
db='/var/lib/rancher/k3s/storage/pvc-7fc2428f-4146-4c78-a26d-2347d9f3b7bf_quiz-master_quiz-data/quiz.db'
c=sqlite3.connect('file:'+db+'?mode=ro',uri=True)
wanted=WANTED_LITERAL
out=[]
for a in wanted:
 assert re.fullmatch(r'a-[a-f0-9]{8}-(?:[a-f0-9]{4}-){3}[a-f0-9]{12}',a['id'])
 row=c.execute('SELECT status,server_score FROM attempts WHERE id=?',(a['id'],)).fetchone();assert row==('finished',a['expected_score']),row
 answers=c.execute('SELECT count(*) FROM attempt_answers WHERE attempt_id=?',(a['id'],)).fetchone()[0];assert answers==a['expected_score']
 out.append({**a,'actual_status':row[0],'actual_server_score':row[1],'actual_saved_answers':answers})
cols=[r[1] for r in c.execute('pragma table_info(feedback_reports)')];rows=c.execute('select * from feedback_reports order by rowid').fetchall()
feedback={'columns':cols,'count':len(rows),'status_counts':c.execute('select status,count(*) from feedback_reports group by status').fetchall(),'reports_sha256':hashlib.sha256(json.dumps(rows,ensure_ascii=False,default=str).encode()).hexdigest()}
print(json.dumps({'own_attempts':out,'feedback_inventory':feedback}))
PY
'''.replace('WANTED_LITERAL',json.dumps(wants))
p=subprocess.run(['ssh','-i','C:/Users/Alexey_Matvienko/.ssh/ll_deploy_ed25519','root@192.3.164.184','bash -s'],input=script.encode(),stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=40);assert p.returncode==0,p.stdout.decode(errors='replace')[-300:];actual=json.loads(p.stdout)
assert actual['feedback_inventory']==load(d/'baseline-feedback-inventory.json')
metrics=json.loads(load(b/'actor-metrics.json')['stdout']);assert metrics=={'dpr':1,'height':844,'touch':0,'width':390}
proof={'published_build':'quiz-2026.10.14-acting-craft-83748f5','published_source':'83748f5a467092302184bcbeee1bd1d7d4b964fa','actual_public_ui_scores':[8,4],'actor_questions_root_visually_verified':8,'actor_article_source_footers_root_visually_verified':8,'music_article_source_titles_root_visually_verified':4,'source_controls_each':[2]*12,'literal_paragraph_artifacts_visually_absent':True,'actual_flow_exits':[0,0],'actual_named_browser_close_exits':[0,0],'actual_sessions_inactive':True,'actual_captured_browser_pids_gone':pids,'actual_console_error_messages':0,'actual_ssh_readonly_verification_exit':p.returncode,'actual_viewport':metrics,**actual,'artifact_sha256':{p.name:sha(p) for p in sorted(b.glob('*')) if p.is_file()},'public_artifact_verification_sha256':sha(d/'public-verification.json'),'public_server_verification_sha256':sha(d/'published-server-verification.json'),'limits':['Twelve real public anonymous practice answers, only exact browser-observed ownattempt rows queried','No feedback report submitted or closed;26real reports stayOPEN unchanged','DesktopChrome390x844 touch0; no physicalAndroid or all4060fact certification']}
(d/'published-root-browser-verification.json').write_text(json.dumps(proof,indent=2)+'\n')
(b/'feedback-inventory.json').write_text(json.dumps(actual['feedback_inventory'],indent=2)+'\n')
print(json.dumps({k:v for k,v in proof.items() if k!='artifact_sha256'}))
