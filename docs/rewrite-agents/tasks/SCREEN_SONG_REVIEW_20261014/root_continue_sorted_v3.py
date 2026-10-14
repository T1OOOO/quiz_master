from pathlib import Path
import json,hashlib,subprocess,copy,importlib.util
r=Path('C:/ap/quiz_master');w=Path(__file__).parent;d=r/'docs/rewrite-agents/tasks/SCREEN_SONG_REVIEW_20261014';p=r/'docs/rewrite-agents/tasks/SCREEN_SONG_PILOT_V3_20261014'
load=lambda x:json.loads(x.read_text(encoding='utf8'))
sha=lambda x:hashlib.sha256(x.read_bytes()).hexdigest()
canon=lambda x:hashlib.sha256(json.dumps(x,ensure_ascii=False,sort_keys=True,separators=(',',':')).encode()).hexdigest()
write=lambda x,v:x.write_bytes((json.dumps(v,ensure_ascii=False,sort_keys=True,indent=2)+'\n').encode())
review=load(d/'independent-v3-review.json');assert review['actual_cli_exit']==0 and review['actual_hub_state']=='ACCEPTED'
task=review['actual_reviews']['task-625137f2f5e64b4fab50fe24dedebadb']['actual_response'];assert task['assignee']!=task['reviewer']
assert all(sha(p/f) in task['review_note'] for f in ['candidate.json','editorial.json'])
binding=load(d/'independent-exact-binding.json');assert binding['actual_cli_exit']==0 and binding['actual_hub_state']=='ACCEPTED'
bt=binding['actual_reviews']['task-e56a479b16c64665999959b825a308f4']['actual_response'];assert bt['assignee']!=bt['reviewer']
assert all(sha(p/f) in bt['review_note'] for f in ['candidate.json','editorial.json','REPORT.json'])
assert sha(w/'apply_reviewed_v3.py') == '004bf2726d19b067d419f3584957cfe9894d97c446fbd12e9636b1993da017c6' and sha(w/'apply_reviewed_v3.py') in bt['review_note']
pr=load(d/'independent-proposal-review.json');assert pr['actual_cli_exit']==0 and pr['actual_hub_state']=='ACCEPTED'
pt=pr['actual_reviews']['task-64a7414eaa7c47778a69a7bdf62858c3']['actual_response'];script=r/'docs/rewrite-agents/tasks/SCREEN_SONG_INTEGRATION_20261014/proposal.py';assert pt['assignee']!=pt['reviewer'] and sha(script)=='0870dd16d513468af1225508dbd516b11f4bcb292eed4388a606d5f4bf40fb7e' and sha(script) in bt['review_note']
raw=r/'quizzes/Cinema/screen_song_20261014.json';content=r/'next/content/screen-song-20261014';reader=r/'study/question_articles/drafts/screen-song-20261014.json';projection=w/'v3-sorted-projection'
assert not any(x.exists() for x in [content,reader,projection]);backup=w/'failed-unsorted-raw.json';assert raw.exists() and not backup.exists() and sha(raw)==sha(w/'v3-projection/raw.json')
catalog=load(r/'next/apps/quiz_app/assets/catalog.json');articles=load(r/'next/apps/quiz_app/assets/study/question-articles.json');assert [len(catalog),sum(x['questions_count'] for x in catalog),len(articles['articles'])]==[134,4060,260]
assetpins={s:sha(r/s) for s in ['next/apps/quiz_app/assets/catalog.json','next/apps/quiz_app/assets/study/question-articles.json']}
oldraw={x.relative_to(r).as_posix():sha(x) for x in (r/'quizzes').rglob('*.json') if x!=raw};assert len(oldraw)==134
spec=importlib.util.spec_from_file_location('frozen_proposal',script);mod=importlib.util.module_from_spec(spec);spec.loader.exec_module(mod)
editorial=load(p/'editorial.json'); tag_order={x['question_id']:{'source':list(x['tags']),'converted':sorted(x['tags'])} for x in editorial['items']}
for x in editorial['items']:x['tags']=sorted(x['tags'])
data=mod.make_proposal(load(p/'candidate.json'),editorial,load(r/'metadata/tags.v1.json'))
assert raw.is_relative_to(r) and backup.is_relative_to(r);raw.rename(backup)
projection.mkdir();[write(projection/(key+'.json'),value) for key,value in data.items()]
write(raw,data['raw']);commands=[]
def run(cmd):
 q=subprocess.run(cmd,cwd=r,capture_output=True,text=True,timeout=120);commands.append({'command':cmd,'actual_exit':q.returncode,'stdout':q.stdout,'stderr':q.stderr});write(w/'v3-sorted-command-checkpoint.json',commands);assert q.returncode==0,commands[-1]
go=['go','run','-p=1','./next/server/cmd/quizctl']
run(go+['import','--in',raw.relative_to(r).as_posix(),'--out',content.relative_to(r).as_posix(),'--taxonomy','metadata/tags.v1.json'])
draft=load(content/'draft.json')
for q in draft['questions']:
 assert q['source']=={'uri':raw.relative_to(r).as_posix()};q['source']={'uri':'/app/'+raw.relative_to(r).as_posix()};q['revision']['sha256']=canon({k:v for k,v in q.items() if k!='revision'})
draft['revision']['sha256']=canon({k:v for k,v in draft.items() if k!='revision'});assert draft==data['draft'];write(content/'draft.json',draft)
assert load(content/'manifest.json')==data['manifest']
run(go+['validate','--in',str(content/'draft.json'),'--taxonomy','metadata/tags.v1.json'])
args=['--in',str(content/'draft.json'),'--version','2026.10.14.screen-song-v1','--published-at','2026-10-14T00:00:00Z','--taxonomy','metadata/tags.v1.json']
run(go+['build',*args,'--out',str(content/'bundle.json')]);run(go+['validate','--in',str(content/'bundle.json'),'--taxonomy','metadata/tags.v1.json'])
bundle=load(content/'bundle.json');assert bundle==data['bundle_projection']
run(go+['build',*args,'--out',str(w/'v3-rebuilt-bundle.json')]);run(go+['diff','--before',str(content/'bundle.json'),'--after',str(w/'v3-rebuilt-bundle.json')])
assert (content/'bundle.json').read_bytes()==(w/'v3-rebuilt-bundle.json').read_bytes()
assert all('grading' not in q and 'editorial_tag_ids' not in q for q in bundle['quiz']['questions'])
for i,q in enumerate(draft['questions']):assert bundle['private_grading'][q['question_id']]['correct_option_id']==q['options'][i]['option_id']
write(reader,data['reader']);assert all(sha(r/s)==h for s,h in oldraw.items()) and all(sha(r/s)==h for s,h in assetpins.items())
outputs=[raw,content/'draft.json',content/'manifest.json',content/'bundle.json',reader]
proof={'metadata_normalization':tag_order,'actual_unsorted_import_exit':1,'failed_raw_preserved_sha256':sha(backup),'root_contract_repair_separately_pending_result_review':True,'scope':'Actual reviewed-v3 raw/canonical/Reader drafts only. Catalog/Reader exported assets remain unchanged; no build/browser/production change.','commands':commands,'output_sha256':{x.relative_to(r).as_posix():sha(x) for x in outputs},'canonical_article_sha256':{x['id']:canon(x) for x in data['reader']['articles']},'question_revisions':{q['question_id']:q['revision']['sha256'] for q in draft['questions']},'old_raw_files_unchanged':134,'old_catalog_and_reader_unchanged':assetpins,'keys_balanced_and_private':True,'authoritative_quizctl_matches_inert_projection':True,'input_sha256':{f:sha(p/f) for f in ['candidate.json','editorial.json','REPORT.json']}}
write(d/'actual-v3-integration.json',proof);print(json.dumps({k:v for k,v in proof.items() if k!='commands'}))
