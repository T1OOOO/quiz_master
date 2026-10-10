import os,pathlib,shutil,sqlite3,subprocess,time,json,urllib.request,urllib.error,base64,hashlib,zlib,struct,sys,socket
build=sys.argv[1];root=pathlib.Path('/opt/quiz-master/releases')/build
assert root==pathlib.Path.cwd() and subprocess.check_output(['hostname'],text=True).strip()=='racknerd-f0269d5'
sandbox=root/'rehearsal-final';sandbox.mkdir(mode=0o755)
db=sandbox/'quiz.sqlite'
with sqlite3.connect('/opt/quiz-master/backups/'+build+'.sqlite') as src, sqlite3.connect(db) as dst:src.backup(dst)
os.chown(db,10001,10001);os.chown(sandbox,10001,10001)
tables=['participants','sessions','attempts','attempt_bundles','attempt_questions','attempt_answers']
with sqlite3.connect(db) as c:
 before=[c.execute('select count(*) from '+t).fetchone()[0] for t in tables]
 old_rows={t:{hashlib.sha256(json.dumps(row).encode()).hexdigest() for row in c.execute('select * from '+t)} for t in tables}
secret=pathlib.Path('/opt/quiz-master/secrets/feedback-admin.token').read_text().strip()
env=os.environ.copy();env.update({'QM_LISTEN_ADDR':'127.0.0.1:18088','QM_DATABASE_URL':'sqlite:rehearsal-final/quiz.sqlite','QM_CONTENT_BUNDLE_PATH':str(root/'quizzes'),'QM_CONTENT_MANIFEST_PATH':str(root/'next/content/home-alone-1-part-1/manifest.json'),'QM_CONTENT_TAXONOMY_PATH':str(root/'metadata/tags.v1.json'),'QM_FEEDBACK_ADMIN_TOKEN':secret,'GOMAXPROCS':'1'})
def req(path,body=None,token=None,method=None,expect=200):
 headers={'Content-Type':'application/json'}
 if token:headers['Authorization']='Bearer '+token
 data=None if body is None else json.dumps(body).encode()
 try:
  with urllib.request.urlopen(urllib.request.Request('http://127.0.0.1:18088'+path,data=data,headers=headers,method=method),timeout=10) as r:code,raw=r.status,r.read()
 except urllib.error.HTTPError as e:code,raw=e.code,e.read()
 assert code==expect,(path,code,expect)
 return json.loads(raw) if raw and not path.endswith('/screenshot') else raw
def start(binary):
 with open(sandbox/'api.log','a') as log:
  p=subprocess.Popen([str(binary)],cwd=root,env=env,stdout=log,stderr=log,user=10001,group=10001)
 for _ in range(50):
  if p.poll() is not None:raise RuntimeError('Staging API exited; inspect rehearsal/api.log')
  try:req('/health/ready');return p
  except Exception:time.sleep(.2)
 p.terminate();p.wait();raise RuntimeError('staging readiness failed')
p=start(root/'api')
try:
 with sqlite3.connect(db) as c:
  after=[c.execute('select count(*) from '+t).fetchone()[0] for t in tables]
  for t in tables:
   current={hashlib.sha256(json.dumps(row).encode()).hexdigest() for row in c.execute('select * from '+t)}
   assert old_rows[t] <= current, 'Existing rows changed in '+t
   if t != 'attempt_bundles':assert len(current)==len(old_rows[t]), 'Unexpected write in '+t
  assert c.execute('pragma integrity_check').fetchone()==('ok',)
 for qid in ['cinema-people-20261011','music-people-20261011']:req('/v1/catalog?quiz_id='+qid)
 guest=req('/v1/guests',{'display_name':'Release rehearsal'},expect=201);token=guest['token']
 for qid in ['cinema-people-20261011','music-people-20261011']:
  bundle=json.loads((root/'next/content'/qid/'bundle.json').read_text())
  attempt=req('/v1/attempts',{'quiz_id':qid,'mode':'practice'},token,expect=201)
  assert len(attempt['question_snapshots'])==10
  for snap in attempt['question_snapshots']:
   answer={'option_id':bundle['private_grading'][snap['question_id']]['correct_option_id']}
   core={'attempt_id':attempt['attempt_id'],'participant_id':attempt['participant_id'],'question_id':snap['question_id'],'question_revision':snap['question_revision'],'answer':answer}
   payload={'question_id':snap['question_id'],'question_revision':snap['question_revision'],'answer':answer,'idempotency_key':'culture-'+snap['question_id'],'payload_digest':hashlib.sha256(json.dumps(core,sort_keys=True,separators=(',',':')).encode()).hexdigest()}
   req('/v1/attempts/'+attempt['attempt_id']+'/answers',payload,token)
   feedback=req('/v1/attempts/'+attempt['attempt_id']+'/feedback/'+snap['question_id'],token=token)
   assert feedback['correct'] is True
  finish=req('/v1/attempts/'+attempt['attempt_id']+'/finish',{},token)
  assert len(finish['history'])==10 and finish['server_score']>0
 body={'request_id':'frq_'+'a'*32,'type':'ui','item_ids':['screen:/library'],'comment':'Release rehearsal only','context':{'route':'/library','viewport':{'width':390,'height':844,'dpr':1},'locale':'ru','theme':'light','platform':'web','app_version':build,'timestamp':'2026-10-11T00:00:00Z'}}
 first=req('/v1/reports',body,token,expect=201);assert req('/v1/reports',body,token)==first
 req('/v1/admin/reports',token=token,expect=401)
 req('/v1/admin/reports/'+first['id']+'/status',{'status':'resolved'},secret)
 req('/v1/admin/reports/'+first['id'],token=secret,method='DELETE',expect=204)
finally:p.terminate();p.wait(timeout=10)
# Previous immutable API can still open the expanded schema for rollback.
rollback=sandbox/'rollback-api'
shutil.copyfile('/opt/quiz-master/releases/quiz-2026.10.06-feedback-e0f89cf/api',rollback)
os.chmod(rollback,0o755)
p=start(rollback)
try:req('/v1/catalog?quiz_id=lotr')
finally:p.terminate();p.wait(timeout=10)
print(json.dumps({'migration':'ok','original_counts':before,'post_migration_counts':after,'original_rows_preserved':True,'integrity':'ok','feedback_lifecycle':'ok','old_api_rollback':'ok'}))
