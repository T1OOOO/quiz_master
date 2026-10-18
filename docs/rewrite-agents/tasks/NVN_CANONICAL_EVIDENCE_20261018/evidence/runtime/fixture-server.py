from pathlib import Path
import subprocess,json,os,sys,time,urllib.request,urllib.error,http.server,socket
r=Path('C:/ap/quiz_master');w=Path(__file__).parent;pack=sys.argv[1];assert pack in ['lotr','mixed'];stop=w/('stop-'+pack);assert not stop.exists();web=r/'.run/nvn_footer_20261016/qa-web'
for port in [19090,19093]:
 with socket.socket() as s:s.bind(('127.0.0.1',port))
env=os.environ.copy();env.update(QM_LISTEN_ADDR='127.0.0.1:19093',QM_DATABASE_URL='sqlite:.run/nvn_release_20261016/fixture/'+pack+'-fixture.sqlite',QM_CONTENT_BUNDLE_PATH=str(w/'qa-lotr-targets-bundle.json') if pack=='lotr' else str(w/'qa-actors-public-bundle.json'),QM_CONTENT_MANIFEST_PATH=str(w/'qa-lotr-targets-manifest.json') if pack=='lotr' else str(w/'qa-actors-public-manifest.json'),QM_CONTENT_TAXONOMY_PATH='metadata/tags.v1.json');env.pop('QM_FEEDBACK_ADMIN_TOKEN',None)
class Handler(http.server.SimpleHTTPRequestHandler):
 def __init__(self,*a,**k):super().__init__(*a,directory=str(web),**k)
 def proxy(self):
  body=self.rfile.read(int(self.headers.get('Content-Length','0'))) if self.command=='POST' else None;headers={k:v for k,v in self.headers.items() if k.lower() in ['authorization','content-type']};req=urllib.request.Request('http://127.0.0.1:19093'+self.path,data=body,headers=headers,method=self.command)
  try:response=urllib.request.urlopen(req,timeout=15)
  except urllib.error.HTTPError as e:response=e
  with response:
   raw=response.read();self.send_response(response.code);self.send_header('Content-Type',response.headers.get('Content-Type','application/json'));self.send_header('Content-Length',str(len(raw)));self.end_headers();self.wfile.write(raw)
  with (w/'requests.jsonl').open('a',encoding='utf8') as f:f.write(json.dumps({'method':self.command,'path':self.path,'status':response.code})+'\n')
 def do_GET(self):return self.proxy() if self.path.startswith(('/v1/','/health/')) else super().do_GET()
 def do_POST(self):assert self.path.startswith('/v1/');return self.proxy()
with (w/(pack+'-api.log')).open('w') as log:
 api=subprocess.Popen([str(w/'qa-api.exe')],cwd=r,env=env,stdout=log,stderr=log,creationflags=subprocess.CREATE_NO_WINDOW);(w/(pack+'-owned-pids.json')).write_text(json.dumps({'server_pid':os.getpid(),'api_pid':api.pid}))
 try:
  deadline=time.monotonic()+30
  while True:
   assert api.poll() is None
   try:
    with urllib.request.urlopen('http://127.0.0.1:19093/health/ready',timeout=2):break
   except Exception:assert time.monotonic()<deadline;time.sleep(.2)
  with urllib.request.urlopen('http://127.0.0.1:19093/v1/catalog?quiz_id='+('lotr-return-king-bts-100' if pack=='lotr' else 'prep-musicals')) as f:public=json.load(f)
  expected=json.loads((w/'qa-lotr-targets-bundle.json' if pack=='lotr' else w/'qa-actors-public-bundle.json').read_text(encoding='utf8'))['quiz']['questions'];assert public['quiz']['questions']==expected
  (w/(pack+'-preflight.json')).write_text(json.dumps({'question_count':len(expected),'exact_current_public_questions':True,'api_pid':api.pid,'scope':'Actual local Go public questions match the4exactcapturedmusicalquestions/options/revisions with recomputedsubsetquizrevision; isolated bundle fixture, not immutable Linux image proof'}))
  with http.server.ThreadingHTTPServer(('127.0.0.1',19090),Handler) as server:
   server.timeout=1;print('Owned local QA ready: '+pack,flush=True);deadline=time.monotonic()+1800
   while not stop.exists() and time.monotonic()<deadline:server.handle_request()
 finally:
  api.terminate();code=api.wait(timeout=10);(w/(pack+'-cleanup.json')).write_text(json.dumps({'actual_api_pid':api.pid,'actual_api_exit':code,'stop_seen':stop.exists()}))
