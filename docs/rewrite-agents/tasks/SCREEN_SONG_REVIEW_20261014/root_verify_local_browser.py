from pathlib import Path
import json,hashlib,sqlite3,socket,subprocess
r=Path('C:/ap/quiz_master');w=Path(__file__).parent;d=r/'docs/rewrite-agents/tasks/SCREEN_SONG_REVIEW_20261014';b=d/'local-browser';load=lambda p:json.loads(p.read_text(encoding='utf-8-sig'));sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
build=load(d/'actual-flutter-builds.json');assert len(build['checks'])==2 and all(x['actual_exit']==0 for x in build['checks'])
for x in build['checks']:assert sha(Path(x['output'])/'main.dart.js')==x['main_dart_js_sha256']
flow=load(b/'song-flow-summary.json');assert flow['actual_flow_exit']==0 and len(flow['questions'])==4 and all(len(x['article_source_controls'])==2 for x in flow['questions'])
paths=json.loads(load(b/'song-own-attempt-paths.json')['stdout']);ids={p.split('/')[3] for p in paths};assert len(ids)==1;attempt=ids.pop()
with sqlite3.connect('file:'+str(w/'fixture.sqlite')+'?mode=ro',uri=True) as c:
 assert c.execute('select status,server_score from attempts where id=?',(attempt,)).fetchone()==('finished',4)
 assert c.execute('select count(*) from attempt_answers where attempt_id=?',(attempt,)).fetchone()[0]==4
 assert c.execute('select count(*) from feedback_reports').fetchone()[0]==0
pids=list(load(w/'screen-song-20261014-owned-pids.json').values())+[36408]+[x['ProcessId'] for x in load(w/'forced-own-browser-tree.json')]
for pid in set(pids):assert subprocess.run(['powershell','-NoProfile','-Command',f'if(Get-Process -Id {pid} -ErrorAction SilentlyContinue){{exit 1}}'],capture_output=True).returncode==0,pid
for port in [19090,19093]:
 with socket.socket() as s:s.bind(('127.0.0.1',port))
assert load(w/'screen-song-20261014-cleanup.json')['stop_seen']
assert not load(b/'songerrors.json')['stdout'].strip()
metrics=json.loads(load(b/'song-metrics.json')['stdout']);assert metrics=={'width':390,'height':844,'touch':0,'dpr':1}
proof={'frozen_source':build['frozen_source'],'build_id':build['build_id'],'actual_ui_score':4,'actual_server_score':4,'actual_saved_answers':4,'own_attempt_id':attempt,'article_sheets_opened_closed':4,'source_buttons_each':[2]*4,'root_visually_inspected_all_four_questions_and_source_footers_and_result':True,'actual_viewport':metrics,'feedback_submissions':0,'actual_console_errors':0,'server_wrapper_exit':0,'fixture_api_exit':load(w/'screen-song-20261014-cleanup.json')['actual_api_exit'],'browser_close_command':'timeout30s, preserved; not a passing close','browser_cleanup':'captured own36408 descendant tree forcibly stopped after official close/session-info hung; official session info subsequently active=false','owned_processes_gone':True,'ports19090_19093_free':True,'artifacts':{p.relative_to(d).as_posix():sha(p) for p in b.iterdir() if p.is_file()},'limits':['DesktopChrome390x844 touch0 DPR1, not physical Android','No production publication or real feedback closure','Source footer visibility and score visually inspected by Root']}
(d/'actual-local-browser-proof.json').write_text(json.dumps(proof,indent=2)+'\n')
print(json.dumps({k:v for k,v in proof.items() if k!='artifacts'}))
