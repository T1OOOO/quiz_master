from pathlib import Path
import json,hashlib,subprocess
r=Path('C:/ap/quiz_master');w=Path(__file__).parent;d=r/'docs/rewrite-agents/tasks/SCREEN_SONG_REVIEW_20261014'
load=lambda p:json.loads(p.read_text(encoding='utf-8-sig'))
ah=lambda a:hashlib.sha256(json.dumps(a,ensure_ascii=False,sort_keys=True,separators=(',',':')).encode()).hexdigest()
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
accept=load(d/'independent-actual-integration.json');assert accept['actual_cli_exit']==0 and accept['actual_hub_state']=='ACCEPTED'
t=accept['actual_reviews']['task-b3db2fb1428a4723adaa944ed413ebeb']['actual_response'];assert t['assignee']!=t['reviewer']
evidence=load(d/'actual-v3-integration.json')
assert sha(d/'actual-v3-integration.json') in t['review_note']
for p,h in evidence['output_sha256'].items():assert sha(r/p)==h,p
articles=load(r/'study/question_articles/drafts/screen-song-20261014.json')['articles']
assert len(articles)==4
assert accept['reviewed_whole_file_hashes']['study/question_articles/drafts/screen-song-20261014.json']==sha(r/'study/question_articles/drafts/screen-song-20261014.json')
reviewpath=r/'study/question_articles/reviews/screen-song-20261014-review.json';assert not reviewpath.exists()
review={'author':t['assignee'],'reviewer':t['reviewer'],'review_task_id':t['id'],'review_scope':'Actual independently accepted v3 conversion and whole Reader draft byte hash. Root derives canonical article hashes from that accepted whole file; reviewer explicitly did not independently verify sub-hashes. SourceURI normalization and lexicographic tag ordering preserve memberships. Separate primary-source factual/editorial review retained; release remains gated.','articles':[{'article_id':a['id'],'article_sha256':ah(a),'verdict':'accept'} for a in articles]}
reviewpath.write_text(json.dumps(review,indent=2)+'\n')
oldcat=load(r/'next/apps/quiz_app/assets/catalog.json');oldarticles=load(r/'next/apps/quiz_app/assets/study/question-articles.json')['articles'];assert [len(oldcat),sum(a['questions_count'] for a in oldcat),len(oldarticles)]==[134,4060,260]
logs=[]
def run(cmd,cwd=r,timeout=120):
 p=subprocess.run(cmd,cwd=cwd,capture_output=True,text=True,timeout=timeout);logs.append({'command':cmd,'cwd':str(cwd),'actual_exit':p.returncode,'stdout':p.stdout,'stderr':p.stderr});(w/'export-checkpoint.json').write_text(json.dumps(logs,indent=2)+'\n');assert p.returncode==0,logs[-1]
run(['go','run','-p=1','./next/server/cmd/quizctl','catalog','--in','quizzes','--out','next/apps/quiz_app/assets/catalog.json','--force','--taxonomy','metadata/tags.v1.json'])
run(['python','study/question_articles/build.py','--write']);run(['python','study/question_articles/build.py','--check']);run(['python','-m','unittest','discover','-s','study/question_articles','-p','test_*.py'])
cat=load(r/'next/apps/quiz_app/assets/catalog.json');a=load(r/'next/apps/quiz_app/assets/study/question-articles.json')['articles'];cm={x['quiz_id']:x for x in cat};am={x['id']:x for x in a}
assert [len(cat),sum(x['questions_count'] for x in cat),len(a)]==[135,4064,264]
assert all(cm[x['quiz_id']]==x for x in oldcat) and all(am[x['id']]==x for x in oldarticles)
assert all(am[x['id']]==dict(x,status='accepted') for x in articles)
fixture=r/'next/apps/quiz_app/test/question_articles_test.dart';s=fixture.read_text();assert s.count('hasLength(260)')==1 and 'screen-song-pilot-001' not in s
newrefs=''.join("        (\n          'screen-song-20261014',\n          '"+x['question_refs'][0]['question_id']+"',\n          '"+x['question_refs'][0]['revision_sha256']+"',\n        ),\n" for x in articles)
s=s.replace('hasLength(260)','hasLength(264)').replace('Acting Craft and published Home Alone','Acting Craft, Screen Song and published Home Alone').replace('for (final (quizId, questionId, revision) in [\n','for (final (quizId, questionId, revision) in [\n'+newrefs)
fixture.write_text(s)
run(['cmd','/c','dart','format','test/question_articles_test.dart'],r/'next/apps/quiz_app')
run(['cmd','/c','flutter','test','--no-pub','test/question_articles_test.dart'],r/'next/apps/quiz_app',180)
proof={'actual_counts':[135,4064,264],'all_prior_catalog_rows_unchanged':134,'all_prior_reader_objects_unchanged':260,'new_screen_song_articles':4,'new_source_links':8,'actual_review_task':t['id'],'commands':logs,'asset_sha256':{p:sha(r/p) for p in ['next/apps/quiz_app/assets/catalog.json','next/apps/quiz_app/assets/study/question-articles.json','next/apps/quiz_app/test/question_articles_test.dart']},'scope':'Actual source exports and Python/Flutter Reader gates only; compiled builds, browser and production release remain pending.'}
(d/'actual-v3-export.json').write_text(json.dumps(proof,ensure_ascii=False,indent=2)+'\n',encoding='utf8');print(json.dumps({k:v for k,v in proof.items() if k!='commands'}))
