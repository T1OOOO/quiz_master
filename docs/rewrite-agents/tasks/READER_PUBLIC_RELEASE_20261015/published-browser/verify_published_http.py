from pathlib import Path
import json,hashlib,urllib.request
d=Path('docs/rewrite-agents/tasks/READER_PUBLIC_RELEASE_20261015');root='https://quiz.kotopedia.org'
def get(path):
 with urllib.request.urlopen(root+path,timeout=40) as r:
  assert r.status==200
  return r.read()
meta=json.loads(get('/version.json'))
assert meta['buildId']=='quiz-2026.10.15-reader-06dfa0b'
assert meta['commit']==meta['source_commit']=='06dfa0bca56c144e4f6c8c06cb1e7b258e032c9b'
assert (meta['packs'],meta['questions'],meta['question_articles'])==(136,4084,279)
js=hashlib.sha256(get('/main.dart.js')).hexdigest()
assert js==meta['main_dart_js_sha256']=='71930a6a9343efbc28f2ad647f9685d05bf2a4c8cdb4d2d9c6dca745085c6331'
reader=get('/assets/assets/study/question-articles.json')
assert hashlib.sha256(reader).hexdigest()=='b05cffdd277af88618db52da4fbb4d3b2ae369b849b87ba847b8d491b9eb8828'
articles=json.loads(reader)['articles'];assert len(articles)==279
a=next(x for x in articles if x['id']=='question:greek-002')
assert a['question_refs'][0]['revision_sha256']=='038a7a47982dd284760ac2183c58f29d6a054ad708f8139fd5e0b9f74a0e5d5d'
assert len(a['source_links'])==5 and len([x for x in a['body_ru'].splitlines() if x.startswith('## ')])==4
public=json.loads(get('/v1/catalog?quiz_id=prep-greek-mythology'))
captured=json.loads(Path('study/question_articles/snapshots/prep-greek-mythology.json').read_bytes())
assert public['quiz']['questions']==captured['quiz']['questions']
assert len(public['quiz']['questions'])==20
proof={'status':'PUBLISHED_HTTP_VERIFIED','build':meta,'main_sha256':js,'reader_sha256':hashlib.sha256(reader).hexdigest(),'articles':len(articles),'greek002_public_bound_revision':a['question_refs'][0]['revision_sha256'],'article_sections':4,'article_sources':5,'method':'Public GET requests only; no guest or attempt creation.'}
proof['actual_public_quiz20_equals_captured_and_local_tested_fixture']=True
(d/'published-http-verification.json').write_text(json.dumps(proof,indent=2)+'\n')
print(json.dumps({'status':proof['status'],'build':meta['buildId'],'articles':279}))
