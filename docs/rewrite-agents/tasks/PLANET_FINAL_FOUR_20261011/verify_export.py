from pathlib import Path
import hashlib,json
r=Path('C:/ap/quiz_master'); d=r/'.run/planet_final_four_20261011'
def read(p): return json.loads(p.read_text(encoding='utf-8-sig'))
def sha(a): return hashlib.sha256(json.dumps(a,ensure_ascii=False,sort_keys=True,separators=(',',':')).encode()).hexdigest()
draft=read(r/'study/question_articles/drafts/planet-final-four-20261011.json'); review=read(r/'study/question_articles/reviews/planet-final-four-20261011-review.json')
expected={f'quiz:planet-paradoxes-20261010:planet-paradox-{i:03d}' for i in range(7,11)}
assert {a['id'] for a in draft['articles']}==expected and len(draft['articles'])==4
assert review['author']!=review['reviewer']
verdicts={x['article_id']:x for x in review['articles']}; assert set(verdicts)==expected
questions={q['question_id']:q for q in read(r/'next/content/planet-paradoxes-20261010/bundle.json')['quiz']['questions']}
for a in draft['articles']:
    v=verdicts[a['id']]; assert v['verdict']=='accept' and v['article_sha256']==sha(a)
    assert 150<=len(a['body_ru'].split())<=210 and len(a['source_links'])==2 and len(a['question_refs'])==1
    ref=a['question_refs'][0]; assert ref['quiz_id']=='planet-paradoxes-20261010' and ref['revision_sha256']==questions[ref['question_id']]['revision']['sha256']
before=read(d/'articles-before.json')['articles']; current=read(r/'next/apps/quiz_app/assets/study/question-articles.json')['articles']; byid={a['id']:a for a in current}
assert len(before)==202 and len(current)==206 and len(byid)==206
assert all(byid[a['id']]==a for a in before)
assert {a['id'] for a in current}-{a['id'] for a in before}==expected
assert len([a for a in current if a['id'].startswith('quiz:planet-paradoxes-20261010:')])==10
foreign=read(r/'.run/feedback_triage_20261006/foreign-1321.json')
assert all((r/p).is_file() and hashlib.sha256((r/p).read_bytes()).hexdigest()==h for p,h in foreign.items())
print('PASS: 4 exact-hash/revision articles; 206 local articles, original202 unchanged; all10 planet questions covered;69 unrelated files preserved')
