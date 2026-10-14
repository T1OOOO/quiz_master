from pathlib import Path
import subprocess,json,hashlib,time
r=Path('C:/ap/quiz_master');app=r/'next/apps/quiz_app';w=r/'.run/screen_song_build_20261014';w.mkdir(exist_ok=True);d=r/'docs/rewrite-agents/tasks/SCREEN_SONG_REVIEW_20261014'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
review=json.loads((d/'independent-export-review.json').read_text(encoding='utf8'));assert review['actual_hub_state']=='ACCEPTED' and review['actual_cli_exit']==0
source=subprocess.check_output(['git','rev-parse','HEAD'],cwd=r).decode().strip();assert not source.startswith(('25be93a','83748f5'))
assert subprocess.check_output(['git','rev-list','--left-right','--count','HEAD...@{upstream}'],cwd=r).strip()==b'0\t0'
build='quiz-2026.10.14-screen-song-'+source[:7]
for rel in ['assets/catalog.json','assets/study/question-articles.json']:
 assert (app/rel).read_bytes()==subprocess.check_output(['git','show',source+':next/apps/quiz_app/'+rel],cwd=r)
checks=[]
for label,url in [('production','https://quiz.kotopedia.org'),('qa','http://127.0.0.1:19090')]:
 out=w/(label+'-web');assert not out.exists()
 cmd=['cmd','/c','flutter','build','web','--release','--no-pub','--pwa-strategy=none','--output',str(out),'--dart-define=QM_BUILD_ID='+build,'--dart-define=QM_API_BASE_URL='+url]
 start=time.monotonic();p=subprocess.run(cmd,cwd=app,capture_output=True,text=True,timeout=240)
 log=w/(label+'-build.log.txt');log.write_text(p.stdout+p.stderr,encoding='utf8');assert p.returncode==0,(p.stdout+p.stderr)[-1500:]
 for rel in ['assets/catalog.json','assets/study/question-articles.json']:assert (out/'assets'/rel).read_bytes()==(app/rel).read_bytes()
 checks.append({'label':label,'actual_exit':0,'command':cmd,'elapsed_seconds':round(time.monotonic()-start,2),'output':str(out),'log_sha256':sha(log),'main_dart_js_sha256':sha(out/'main.dart.js'),'frozen_assets_byte_identical':True})
 (d/'actual-flutter-builds.json').write_text(json.dumps({'frozen_source':source,'build_id':build,'checks':checks,'scope':'Actual compiled Flutter Web outputs; browser, rehearsal and server publication remain gated.'},indent=2)+'\n')
assert checks[0]['main_dart_js_sha256']!=checks[1]['main_dart_js_sha256']
print(json.dumps({'frozen_source':source,'build_id':build,'actual_builds':2}))
