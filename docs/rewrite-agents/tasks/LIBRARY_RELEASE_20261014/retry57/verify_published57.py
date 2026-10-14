from pathlib import Path
import urllib.request,urllib.parse,json,hashlib,importlib.util,concurrent.futures,http.client
r=Path('C:/ap/quiz_master');d=r/'docs/rewrite-agents/tasks/LIBRARY_RELEASE_20261014/retry57';base='https://quiz.kotopedia.org'
def raw(path):
 for attempt in range(3):
  try:
   with urllib.request.urlopen(base+path,timeout=90) as response:return response.read()
  except (http.client.IncompleteRead, TimeoutError):
   if attempt == 2:raise
def read(path):return json.loads(raw(path))
version=read('/version.json');assert version['buildId']=='quiz-2026.10.14-library-09b19cc' and version['question_articles']==278
assert raw('/health/ready')==b''
for path,sha in [('/main.dart.js','0c34332e394327aafa3ab6d158d35cf898931aac548af7a2763221d73ebd24cd'),('/assets/assets/study/question-articles.json','7fc2b6a1bac73847f75de1c5617cf055d645eb6a1466c9780477bc07c31abd74')]:assert hashlib.sha256(raw(path)).hexdigest()==sha
reader=read('/assets/assets/study/question-articles.json')['articles'];catalog=read('/assets/assets/catalog.json')
def fetch(row):return row['quiz_id'],read('/v1/catalog?quiz_id='+urllib.parse.quote(row['quiz_id'],safe=''))
with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:responses=dict(pool.map(fetch,catalog))
s=importlib.util.spec_from_file_location('house',r/'docs/rewrite-agents/tasks/MIXED_RELEASE_20261014/worker/verify_candidate_runtime.py');m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
a=m.verify_catalog_collection(catalog,responses,expected_packs=136,expected_questions=4084);b=m.verify_reader_bindings(reader,responses,expected_articles=278,expected_total_refs=159,expected_playable_refs=157)
(d/'published-http.json').write_text(json.dumps({'status':'PUBLISHED_HTTP_VERIFIED','version':version,'catalog':a,'reader':b,'https_ready_empty200':True,'production_js_reader_sha_match':True},indent=2)+'\n');print(json.dumps({'catalog':a,'reader':b,'actual_http_verified':True}))
