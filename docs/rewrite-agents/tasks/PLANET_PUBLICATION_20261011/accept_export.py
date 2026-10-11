from pathlib import Path
import json,hashlib,subprocess,shutil
r=Path('C:/ap/quiz_master');d=r/'.run/planet_publication_20261011'
read=lambda p:json.loads(p.read_text(encoding='utf-8-sig'))
rows={x['article_id']:x for x in read(d/'binding-map.json')};claude=read(d/'claude-review.json');assert claude['verdict']=='accept' and claude['binding_map_verified'] is True
seen=set()
for p in (r/'study/question_articles/reviews').glob('*.json'):
 data=read(p);affected=[a for a in data.get('articles',[]) if a['article_id'] in rows]
 if not affected:continue
 backup=d/'old-reviews'/p.name;backup.parent.mkdir(exist_ok=True);shutil.copyfile(p,backup)
 for a in affected:
  row=rows[a['article_id']];assert a['verdict']=='accept' and a['article_sha256']==row['old_sha256']
  a['previous_article_sha256']=a['article_sha256'];a['article_sha256']=row['new_sha256']
  a['binding_review']={'scope':'URI/revision-only; body and sources unchanged','native_task':'task-18bf1548a0d34abb901b7d38c8278746','native_hash_message':28202,'independent_provider':'Actual Claude Sonnet5 official CLI supplied-evidence review','packet_sha256':claude['packet_sha256'],'limitations':'Claude did not recompute hashes or fetch URLs; native checker recomputed all10 canonical hashes. No release approval.'};seen.add(a['article_id'])
 p.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
assert seen==set(rows) and len(seen)==10
for flag in ['--write','--check']:subprocess.run(['python','study/question_articles/build.py',flag],cwd=r,check=True)
old=read(d/'articles-before.json')['articles'];new=read(r/'next/apps/quiz_app/assets/study/question-articles.json')['articles'];byid={a['id']:a for a in new}
assert len(old)==len(new)==len(byid)==206
for a in old:
 current=byid[a['id']]
 if a['id'] not in rows:assert current==a
 else:assert {k:v for k,v in current.items() if k!='question_refs'}=={k:v for k,v in a.items() if k!='question_refs'}
old=read(d/'catalog-before.json');new=read(r/'next/apps/quiz_app/assets/catalog.json');byid={a['quiz_id']:a for a in new}
assert len(old)==130 and len(new)==len(byid)==131 and sum(a['questions_count'] for a in new)==4008
assert all(byid[a['quiz_id']]==a for a in old)
foreign=read(r/'.run/feedback_triage_20261006/foreign-1321.json');assert all(hashlib.sha256((r/p).read_bytes()).hexdigest()==h for p,h in foreign.items())
print('PASS131packs4008questions206articles;130oldcatalogrows and196otherarticles unchanged;10planetbodies/sources/keys preserved;69foreignfiles unchanged')
