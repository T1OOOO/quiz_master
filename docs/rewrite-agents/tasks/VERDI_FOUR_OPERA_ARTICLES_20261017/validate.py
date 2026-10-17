from pathlib import Path
import json,hashlib,re,sys
from urllib.parse import urlsplit
r=Path('C:/ap/quiz_master'); d=r/'docs/rewrite-agents/tasks/VERDI_FOUR_OPERA_ARTICLES_20261017'
read=lambda p:json.loads(p.read_text(encoding='utf-8-sig'))
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
write=lambda p,x:p.write_text(json.dumps(x,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
s=read(d/'scope.json'); public=read(d/'public-pack.json')['quiz']['questions']; candidates=read(d/'candidate-questions.json')['questions']
key=lambda q:(q['quiz_id'],q['question_id'],q['revision']['sha256'])
refkey=lambda q:(q['quiz_id'],q['question_id'],q['revision_sha256'])
assert len(public)==20 and len(candidates)==4
assert {key(q) for q in candidates}<={key(q) for q in public}
assert sha(d/'public-pack.json')==s['public_snapshot_sha256']
assert sha(d/'sources.json')==s['sources_sha256']
pins={'next/apps/quiz_app/assets/study/question-articles.json':'runtime_articles_sha256','docs/rewrite-agents/tasks/NVN_RELEASE_20261016/release-inputs.json':'frozen_nvn_release_inputs_sha256','docs/rewrite-agents/tasks/CINEMA_ICON_ARTICLES_20261016/articles.json':'previous_movie_articles_sha256','docs/rewrite-agents/tasks/MUSICAL_COMPLETION_ARTICLES_20261016/articles.json':'previous_musical_articles_sha256','docs/rewrite-agents/tasks/CINEMA_CHARACTER_ARTICLES_20261016/articles.json':'previous_character_articles_sha256'}
pins['docs/rewrite-agents/tasks/CLASSIC_FILM_ARTICLES_20261016/articles.json']='previous_classic_articles_sha256'
pins['docs/rewrite-agents/tasks/SCREEN_ROLE_ARTICLES_20261016/articles.json']='previous_screen_articles_sha256'
pins['docs/rewrite-agents/tasks/ICONIC_ROLE_ARTICLES_20261016/articles.json']='previous_iconic_articles_sha256'
pins['docs/rewrite-agents/tasks/ACTRESS_ROLE_ARTICLES_20261016/articles.json']='previous_actress_articles_sha256'
pins['docs/rewrite-agents/tasks/STEWART_DENIRO_ARTICLES_20261016/articles-continuation.json']='previous_stewart_articles_sha256'
pins['docs/rewrite-agents/tasks/GOODFELLAS_SCARFACE_ARTICLES_20261016/articles.json']='previous_goodfellas_articles_sha256'
pins['docs/rewrite-agents/tasks/UNTOUCHABLES_PRINCESS_ARTICLES_20261016/articles.json']='previous_untouchables_articles_sha256'
pins['docs/rewrite-agents/tasks/EXORCIST_NETWORK_ARTICLES_20261016/articles.json']='previous_exorcist_articles_sha256'
pins['docs/rewrite-agents/tasks/STING_CONVERSATION_ARTICLES_20261016/articles.json']='previous_sting_articles_sha256'
pins['docs/rewrite-agents/tasks/FOUR_SCREEN_ROLE_ARTICLES_20261016/articles.json']='previous_four_screen_articles_sha256'
pins['docs/rewrite-agents/tasks/FINAL_ACTOR_ROLE_ARTICLES_20261016/articles.json']='previous_final_actor_articles_sha256'
pins['docs/rewrite-agents/tasks/OPERA_CARMEN_OTELLO_ARTICLES_20261017/articles.json']='previous_carmen_articles_sha256'
pins['docs/rewrite-agents/tasks/OPERA_FLUTE_TURANDOT_ARTICLES_20261017/articles.json']='previous_flute_articles_sha256'
for p,f in pins.items():assert sha(r/p)==s[f],p
packet=read(d/'articles.json'); articles=packet['articles']; assert packet['schema_version']=='qm-question-articles/v1' and len(articles)==4
expected={q['question_id']:q for q in candidates}; assert {a['id'] for a in articles}=={'question:'+k for k in expected}
words={}; counts={}
for a in articles:
 q=expected[a['id'][9:]]
 assert a['status']=='draft' and a['target_refs']==[]
 assert set(a['tag_ids'])=={'domain:arts'}
 assert len(a['question_refs'])==1 and refkey(a['question_refs'][0])==key(q)
 assert '\\n' not in a['body_ru']
 words[a['id']]=len(re.findall(r'\S+',a['body_ru'])); assert 150<=words[a['id']]<=220,(a['id'],words[a['id']])
 links=a['source_links'];counts[a['id']]=len(links);assert 2<=len(links)<=5
 assert len({l['url'] for l in links})==len(links)
 for l in links:
  u=urlsplit(l['url']);assert u.scheme=='https' and u.netloc and not u.username and not u.password
  assert all(isinstance(l[x],str) and l[x].strip() for x in ['title','supports']) and l['accessed']=='2026-10-17'
# Exact current public pack coverage, explicitly distinguishing private drafts.
locations=[('published','next/apps/quiz_app/assets/study/question-articles.json'),('private_draft','docs/rewrite-agents/tasks/CULTURE_ARTICLES_20261016/articles.json'),('private_draft','docs/rewrite-agents/tasks/CINEMA_ICON_ARTICLES_20261016/articles.json'),('private_draft','docs/rewrite-agents/tasks/CINEMA_CHARACTER_ARTICLES_20261016/articles.json'),('private_draft',str((d/'articles.json').relative_to(r)).replace('\\','/'))]
locations.insert(-1,('private_draft','docs/rewrite-agents/tasks/CLASSIC_FILM_ARTICLES_20261016/articles.json'))
locations.insert(-1,('private_draft','docs/rewrite-agents/tasks/SCREEN_ROLE_ARTICLES_20261016/articles.json'))
locations.insert(-1,('private_draft','docs/rewrite-agents/tasks/ICONIC_ROLE_ARTICLES_20261016/articles.json'))
locations.insert(-1,('private_draft','docs/rewrite-agents/tasks/ACTRESS_ROLE_ARTICLES_20261016/articles.json'))
locations.insert(-1,('private_draft','docs/rewrite-agents/tasks/STEWART_DENIRO_ARTICLES_20261016/articles-continuation.json'))
locations.insert(-1,('private_draft','docs/rewrite-agents/tasks/GOODFELLAS_SCARFACE_ARTICLES_20261016/articles.json'))
locations.insert(-1,('private_draft','docs/rewrite-agents/tasks/UNTOUCHABLES_PRINCESS_ARTICLES_20261016/articles.json'))
locations.insert(-1,('private_draft','docs/rewrite-agents/tasks/EXORCIST_NETWORK_ARTICLES_20261016/articles.json'))
locations.insert(-1,('private_draft','docs/rewrite-agents/tasks/STING_CONVERSATION_ARTICLES_20261016/articles.json'))
locations.insert(-1,('private_draft','docs/rewrite-agents/tasks/FOUR_SCREEN_ROLE_ARTICLES_20261016/articles.json'))
locations.insert(-1,('private_draft','docs/rewrite-agents/tasks/FINAL_ACTOR_ROLE_ARTICLES_20261016/articles.json'))
locations.insert(-1,('private_draft','docs/rewrite-agents/tasks/OPERA_CARMEN_OTELLO_ARTICLES_20261017/articles.json'))
locations.insert(-1,('private_draft','docs/rewrite-agents/tasks/OPERA_FLUTE_TURANDOT_ARTICLES_20261017/articles.json'))
bindings={key(q):[] for q in public}
for status,path in locations:
 for a in read(r/path)['articles']:
  for ref in a['question_refs']:
   k=refkey(ref)
   if k in bindings:bindings[k].append({'status':status,'article_id':a['id'],'source_path':path,'source_sha256':sha(r/path)})
assert all(len(v)<=1 for v in bindings.values())
assert all(len(bindings[key(q)])==1 for q in candidates)
coverage=[{'quiz_id':k[0],'question_id':k[1],'revision_sha256':k[2],**(v[0] if v else {'status':'missing'})} for k,v in bindings.items()]
coverage_counts={state:sum(e['status']==state for e in coverage) for state in ['published','private_draft','missing']}
write(d/'coverage.json',{'basis':'actual public API snapshot captured in this packet; no new production refresh','public_questions':len(public),'counts':coverage_counts,'export_or_publication_attempted':False,'questions':coverage})
result={'status':'pass_structural_only','article_sha256':sha(d/'articles.json'),'articles':4,'word_counts':words,'source_counts':counts,'exact_public_refs':True,'existing_tags_only':True,'source_metadata_valid':True,'coverage':coverage_counts,'runtime_previous_packets_and_frozen_nvn_unchanged':True,'genuine_different_provider_acceptance':'pending','export_or_publication_attempted':False}
obs=read(d/'disk-diagnosis.json');assert sha(d/'disk-diagnosis.json')==s['production_observation_sha256'] and obs['actual_exit']==0 and not obs['mutation']
o=json.loads(obs['stdout']);assert not o['mutation'] and o['readiness']==200 and o['helm_revision']==64 and o['helm_status']=='deployed' and o['replicas']==1
assert o['feedback_count']==o['feedback_open']==29 and o['feedback_sha256']=='452929a2ea8dc34600eff8039571e2b0479ec7ad1ec52fa6e271b5c71008030e'
assert o['disk_available']==18135998464 and o['disk_total']==102417174528 and not o['strict20_pass'] and o['disk_available']*5<o['disk_total']
assert o['deficit_to20_bytes']==o['disk_total']//5+1-o['disk_available']==2347436442
assert set(o['images'])=={'docker.io/library/quiz-master@sha256:dc230d8cec6d555c3f0e67f17a8bdab4452cb546cdf29b50c4c6395717ba8c00'} and o['conditions']['Ready']=='True' and o['conditions']['DiskPressure']=='False' and not o['taints']
result['production_observation']={'readiness':200,'feedback_unchanged_open':29,'strict20_gate':'FAIL','available_percent':o['available_percent'],'release_preflight':'not rerun','mutation':False}
if '--final' in sys.argv:
 review=read(d/'review.json');assert review['reviewed_file']['sha256']==sha(d/'articles.json')

 assert len(review['items'])==4 and {v['id'] for v in review['items']}=={a['id'] for a in articles}
 assert all(v['verdict']=='accepted_for_draft' for v in review['items'])
 legacy=read(r/'quizzes/Preparation/prep_opera.json'); local={q['id']:q for q in legacy['questions']}; integrity=[]
 for item in review['items']:
  q=expected[item['id'][9:]]; l=local[q['question_id']]; b=item['blind_answer']
  assert item['question_revision_sha256']==q['revision']['sha256']
  assert l['text']==q['stem'] and l['options']==[o['text'] for o in q['options']]
  assert len([o for o in q['options'] if o['option_id']==b['option_id'] and o['text']==b['text']])==1
  assert l['options'][l['correct_answer']]==b['text']
  integrity.append({'question_id':q['question_id'],'source_based_blind_answer_matches_local_key':True,'public_options_and_stem_match_local':True})
 write(d/'key-integrity.json',{'scope':'authorized editorial-only read; no key fetched via public API or exported to public DTO','legacy_source_sha256':sha(r/'quizzes/Preparation/prep_opera.json'),'questions':integrity,'production_scoring_exercised':False})
 result.update({'native_editorial_review':{'verdict':'accepted_for_draft','report_sha256':sha(d/'review.json'),'markdown_sha256':sha(d/'REVIEW_EN.md'),'different_provider_acceptance':False},'independent_answers_match_local_keys':4,'key_integrity_sha256':sha(d/'key-integrity.json')})
write(d/('validation-final.json' if '--final' in sys.argv else 'validation-structural.json'),result)
print(json.dumps(result,ensure_ascii=False))
