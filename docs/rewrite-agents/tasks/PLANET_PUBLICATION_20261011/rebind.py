from pathlib import Path
import json,hashlib,shutil
r=Path('C:/ap/quiz_master');d=r/'.run/planet_publication_20261011';qid='planet-paradoxes-20261010'
read=lambda p:json.loads(p.read_text(encoding='utf-8-sig'))
sha=lambda a:hashlib.sha256(json.dumps(a,ensure_ascii=False,sort_keys=True,separators=(',',':')).encode()).hexdigest()
b=read(r/'next/content'/qid/'bundle.json');old=read(d/'bundle-before.json');previous={q['question_id']:q for q in old['quiz']['questions']}
assert len(b['quiz']['questions'])==10 and b['private_grading']==old['private_grading']
for q in b['quiz']['questions']:
 before=previous[q['question_id']]
 assert q['source']['uri']=='/app/quizzes/Science/planet_paradoxes_20261010.json'
 assert {k:v for k,v in q.items() if k not in ['revision','source']}=={k:v for k,v in before.items() if k not in ['revision','source']}
questions={q['question_id']:q['revision']['sha256'] for q in b['quiz']['questions']};rows=[]
for p in (r/'study/question_articles/drafts').glob('*.json'):
 data=read(p);affected=[a for a in data.get('articles',[]) if a['id'].startswith('quiz:'+qid+':')]
 if not affected:continue
 backup=d/'old-drafts'/p.name;backup.parent.mkdir(exist_ok=True);shutil.copyfile(p,backup)
 for a in affected:
  old_hash=sha(a);ref=a['question_refs'][0];assert len(a['question_refs'])==1 and ref['revision_sha256']==previous[ref['question_id']]['revision']['sha256']
  ref['revision_sha256']=questions[ref['question_id']];rows.append({'article_id':a['id'],'old_sha256':old_hash,'new_sha256':sha(a),'draft':str(p.relative_to(r)).replace('\\','/'),'question_id':ref['question_id']})
 p.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
assert len(rows)==10 and len({x['article_id'] for x in rows})==10
(d/'binding-map.json').write_text(json.dumps(rows,indent=2)+'\n',encoding='utf-8')
print('PASS: ten article refs rebound; original drafts preserved; review hashes remain pending independent verification')
