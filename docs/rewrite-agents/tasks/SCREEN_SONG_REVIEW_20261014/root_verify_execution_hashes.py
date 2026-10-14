from pathlib import Path
import json,hashlib
r=Path('C:/ap/quiz_master');w=Path(__file__).parent;d=r/'docs/rewrite-agents/tasks/SCREEN_SONG_RELEASE_20261014';e=r/'docs/rewrite-agents/tasks/SCREEN_SONG_REVIEW_20261014';sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
rows=[json.loads(s) for s in (w/'screensong37.jsonl').read_text(encoding='utf8').splitlines() if s.startswith('{')];calls={};checks=[]
for row in rows:
 if not isinstance(row.get('message'),dict):continue
 for b in row['message'].get('content',[]):
  if not isinstance(b,dict):continue
  if b.get('type')=='tool_use':calls[b['id']]=b
  if b.get('type')=='tool_result' and not b.get('is_error'):
   call=calls.get(b.get('tool_use_id'),{});command=call.get('input',{}).get('command','')
   if call.get('name')=='Bash' and 'sha256sum' in command:checks.append({'command':command,'actual_result':b.get('content','')})
assert checks,'No actual independent sha256sum tool results'
text='\n'.join(str(x['actual_result']) for x in checks);pins={p:sha(d/p) for p in ['execution-packet.json','publish-prepared-preview.sh','worker-resumed/publish_prepared.py','remote-preparation-verification.json']}
assert all(h in text for h in pins.values()),'Full execution hashes not present in actual independent hash-command output'
(e/'execution-full-hash-bindings.json').write_text(json.dumps({'actual_full_hashes':pins,'actual_independent_hash_command_results':checks,'trace_sha256':sha(w/'screensong37.jsonl'),'scope':'Reviewer note abbreviates values and has a malformed publisher abbreviation; full hashes are bound from actual successful independent sha256sum results, not expanded/invented from that prose.'},ensure_ascii=False,indent=2)+'\n',encoding='utf8')
print('All4critical full SHA match actual independent hash-command outputs; abbreviated prose is not used as a binding.')
