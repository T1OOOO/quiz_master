from pathlib import Path
import json,hashlib,urllib.request,urllib.parse,importlib.util,datetime
r=Path('C:/ap/quiz_master'); d=r/'docs/rewrite-agents/tasks/MIXED_READER_IMPORT_20261014'
stage=r/'.run/reader_import_20261014/package-v3/quiz-2026.10.14-reader-17be4ce/web'
base='https://quiz.kotopedia.org'
def fetch(path):
    with urllib.request.urlopen(base+path,timeout=30) as response:
        assert response.status==200
        return response.read()
assets={}
for remote,local in {'/version.json':'version.json','/main.dart.js':'main.dart.js','/assets/assets/catalog.json':'assets/assets/catalog.json','/assets/assets/study/question-articles.json':'assets/assets/study/question-articles.json'}.items():
    body=fetch(remote); expected=(stage/local).read_bytes()
    assert body==expected,remote
    assets[remote]={'status':200,'sha256':hashlib.sha256(body).hexdigest()}
assert fetch('/health/ready')==b''
catalog=json.loads((stage/'assets/assets/catalog.json').read_bytes())
ids={x['quiz_id'] for x in catalog}
assert len(ids)==136 and sum(x['questions_count'] for x in catalog)==4084
articles=json.loads((stage/'assets/assets/study/question-articles.json').read_bytes())['articles']
assert len(articles)==272
spec=importlib.util.spec_from_file_location('published_reader_contract',r/'docs/rewrite-agents/tasks/MIXED_RELEASE_20261014/worker/verify_candidate_runtime.py')
contract=importlib.util.module_from_spec(spec);spec.loader.exec_module(contract)
cache={}; skipped=[]; checked=0
for article in articles:
    for ref in article['question_refs']:
        quiz=ref['quiz_id']
        if quiz not in ids:
            skipped.append(ref);continue
        if quiz not in cache:
            payload=json.loads(fetch('/v1/catalog?'+urllib.parse.urlencode({'quiz_id':quiz})))
            cache[quiz]={q['question_id']:q['revision']['sha256'] for q in payload['quiz']['questions']}
        assert cache[quiz].get(ref['question_id'])==ref['revision_sha256'],ref['question_id']
        checked+=1
assert checked==151 and skipped==contract.NONCATALOG_READER_REFS
out={'utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'status':'PUBLISHED_HTTPS_VERIFIED','normal_tls':True,'assets':assets,'health_ready':True,'packs':136,'questions':4084,'reader_articles':272,'playable_refs_checked':checked,'known_noncatalog_refs':skipped,'source_commit':'17be4ce706cc27956c09d362cc5dc5803dd53570','scope':'Actual public TLS bytes and every playable Reader revision; browser and server history checks separate'}
(d/'published-https-verification.json').write_text(json.dumps(out,indent=2)+'\n',encoding='utf8')
print(json.dumps({'status':out['status'],'reader_articles':272,'playable_refs_checked':151}))
