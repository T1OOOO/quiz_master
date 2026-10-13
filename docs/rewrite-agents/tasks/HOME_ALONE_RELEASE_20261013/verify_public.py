from pathlib import Path
import json,hashlib,urllib.request
r=Path('.run/home_alone_release_20261013');m=json.loads((r/'package.json').read_text());stage=Path(m['stage']);base='https://quiz.kotopedia.org/'
def get(p):
 with urllib.request.urlopen(base+p,timeout=30) as f:return f.read()
assert json.loads(get('version.json'))==m['metadata'];results={}
for remote,local in [('main.dart.js','web/main.dart.js'),('assets/assets/catalog.json','web/assets/assets/catalog.json'),('assets/assets/study/question-articles.json','web/assets/assets/study/question-articles.json')]:
 raw=get(remote);assert raw==(stage/local).read_bytes(),remote;results[remote]=hashlib.sha256(raw).hexdigest()
a=json.loads(get('assets/assets/study/question-articles.json'))['articles']
count=0
for pack,expected in [('home-alone-1-part-1',2),('planet-paradoxes-20261010',10),('cinema-encore-20261011',10),('music-encore-20261011',10),('cinema-people-20261011',28),('music-people-20261011',28),('lotr',3),('prep-ballet',1),('prep-musicals',1),('theme-harry-potter',10),('theme-terminator',10),('gastronomy-traditions-and-etiquette',10)]:
 cat=json.loads(get('v1/catalog?quiz_id='+pack))
 if pack in ['planet-paradoxes-20261010','cinema-people-20261011','music-people-20261011']:
  expected_questions=json.loads((stage/'next/content'/pack/'bundle.json').read_text())['quiz']['questions']
  assert cat['quiz']['questions']==expected_questions, 'Exact production question/revision mismatch'
 qs={q['question_id']:q['revision']['sha256'] for q in cat['quiz']['questions']}
 refs=[ref for article in a for ref in article['question_refs'] if ref['quiz_id']==pack]
 assert len(refs)==expected
 assert all(qs.get(ref['question_id'])==ref['revision_sha256'] for ref in refs),pack
 assert not any(secret in json.dumps(cat) for secret in ['private_grading','correct_option_id','correct_answer_index'])
 count+=len(refs)
assert count==123
fixed=[]
old=json.loads((Path('docs/rewrite-agents/tasks/ANSWER_AUDIT_20261011')/'production-duplicates.json').read_text())['questions']
for pack in ['philias-lifestyle-part-1','phobias-nature']:
 cat=json.loads(get('v1/catalog?quiz_id='+pack))
 expected_questions=json.loads((stage/'next/content'/pack/'bundle.json').read_text())['quiz']['questions']
 assert cat['quiz']['questions']==expected_questions
 for q in cat['quiz']['questions']:
  labels=[o['text'].strip().casefold() for o in q['options']]
  assert len(labels)==len(set(labels))
  prior=next((x for x in old if x['question_id']==q['question_id']),None)
  if prior:
   assert len(q['options'])==(4 if pack=='phobias-nature' else 5) and q['revision']!=prior['revision']
   fixed.append(q)
 assert not any(secret in json.dumps(cat) for secret in ['private_grading','correct_option_id','correct_answer_index'])
assert len(fixed)==3
results['repaired_questions']=fixed
baseline=json.loads((Path('.run/duplicate_repair_20261011/quiz-2026.10.11-dedup-ddf47be/next/content/phobias-nature/bundle.json')).read_text())['quiz']['questions']
current=json.loads(get('v1/catalog?quiz_id=phobias-nature'))['quiz']['questions']
assert len(current)==len(baseline)==9
assert all(q['revision']!=next(oldq for oldq in baseline if oldq['question_id']==q['question_id'])['revision'] for q in current)
results['phobias_new_revisions']=9

home=json.loads(get('v1/catalog?quiz_id=home-alone-1-part-1'))
expected=json.loads((stage/'next/content/home-alone-1-part-1/bundle.json').read_text())['quiz']['questions']
assert home['quiz']['questions']==expected
assert not any(secret in json.dumps(home) for secret in ['private_grading','correct_option_id','correct_answer_index'])
assert len(expected)==25
for q in expected:
 if q['question_id'] in ['q-ha1-p1-7','q-ha1-p1-15','q-ha1-p1-17']:assert len(q['options'])==4
results['home_alone_exact_questions']=25
results.update(version=m['metadata'],live_question_article_bindings=count)
(r/'public-verification.json').write_bytes(json.dumps(results,indent=2).encode()+b'\n');Path('docs/rewrite-agents/tasks/HOME_ALONE_RELEASE_20261013/public-verification.json').write_bytes((r/'public-verification.json').read_bytes());print(json.dumps({'version':results['version'],'live_question_article_bindings':count,'retained_repairs_verified':True}))
