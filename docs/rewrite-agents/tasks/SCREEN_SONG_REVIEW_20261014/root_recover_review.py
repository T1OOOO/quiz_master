from pathlib import Path
import json,hashlib
w=Path(__file__).parent;r=Path('C:/ap/quiz_master');d=r/'docs/rewrite-agents/tasks/SCREEN_SONG_REVIEW_20261014'
load=lambda p:json.loads(p.read_text(encoding='utf8'))
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
task='task-b3db2fb1428a4723adaa944ed413ebeb'
assert load(w/'screensong30-exit.json')['actual_exit']=='timeout'
assert load(w/'screensong31-resume-exit.json')['actual_exit']==0
rows=[json.loads(s) for s in (w/'screensong30.jsonl').read_text(encoding='utf8').splitlines() if s.startswith('{')]
calls={};records=[]
for row in rows:
 if not isinstance(row.get('message'),dict):continue
 for b in row['message'].get('content',[]):
  if not isinstance(b,dict):continue
  if b.get('type')=='tool_use':calls[b['id']]=b
  if b.get('type')!='tool_result' or b.get('is_error'):continue
  call=calls.get(b.get('tool_use_id'),{});inp=call.get('input',{});args=inp.get('arguments',{})
  if call.get('name','').endswith('hub_task') and inp.get('action')=='review' and args.get('task_id')==task:
   response=json.loads(b['content']);assert response['state']=='ACCEPTED' and response['reviewer']!=response['assignee']
   records.append({'call':inp,'actual_response':response})
assert records
resumed=[json.loads(s) for s in (w/'screensong31-resume.jsonl').read_text(encoding='utf8').splitlines() if s.startswith('{')]
final=next(x for x in reversed(resumed) if x.get('type')=='result');assert not final.get('is_error') and final.get('result')
original_id=next(x['session_id'] for x in rows if x.get('type')=='system' and x.get('subtype')=='init')
assert load(w/'screensong31-resume-own-pid.json')['resumed_conversation']==original_id
e=load(d/'actual-v3-integration.json')
assert sha(d/'actual-v3-integration.json') in records[-1]['actual_response']['review_note']
for p,h in e['output_sha256'].items():assert sha(r/p)==h,p
proof={'actual_cli_exit':0,'cli_exit_scope':'Successful resumed final report delivery only; original review process timed out after its successful callback.','original_cli_exit':'timeout','actual_resume_exit':0,'actual_hub_state':'ACCEPTED','actual_reviews':{task:records[-1]},'report':final['result'],'original_trace_sha256':sha(w/'screensong30.jsonl'),'resume_trace_sha256':sha(w/'screensong31-resume.jsonl'),'reviewed_whole_file_hashes':e['output_sha256'],'canonical_article_hash_scope':'Root computes per-article canonical hashes from the independently byte-hash-verified whole Reader draft. Reviewer explicitly did not verify these sub-hashes; jq serialization mismatch is unresolved. Whole file content and factual/editorial reviews are accepted.','scope':'Source conversion only; exports and deployment remain separately gated.'}
(d/'independent-actual-integration.json').write_text(json.dumps(proof,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
print('Recovered real accepted callback and successful resumed delivery; no original exit or sub-hash certification fabricated.')
