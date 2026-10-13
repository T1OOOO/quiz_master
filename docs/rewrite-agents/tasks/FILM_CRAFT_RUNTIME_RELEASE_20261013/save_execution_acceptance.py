"""Write the approval artifact only after an actual independent ACCEPTED callback."""
from pathlib import Path
import json,hashlib
R=Path('C:/ap/quiz_master');D=Path(__file__).parent;W=R/'.run/film_craft_release_20261013';NAME='runtime-execution-review3'
def main():
 assert json.loads((W/(NAME+'-exit.json')).read_text())['actual_exit']==0
 trace=W/(NAME+'.jsonl');rows=[json.loads(x) for x in trace.read_text(encoding='utf8').splitlines() if x.strip()];calls={};record=None
 for x in rows:
  if not isinstance(x.get('message'),dict):continue
  for c in x['message'].get('content',[]):
   if not isinstance(c,dict):continue
   if c.get('type')=='tool_use':calls[c['id']]=c
   if c.get('type')=='tool_result':
    a=calls.get(c.get('tool_use_id'),{});inp=a.get('input',{});args=inp.get('arguments',{})
    if a.get('name','').endswith('hub_task') and inp.get('action')=='review' and args.get('task_id')=='task-fae2e3a4efa646f6bf2b47f286f71901' and args.get('verdict')=='accept':
     assert not c.get('is_error',False),c
     response=json.loads(c['content']);assert response['id']==args['task_id'] and response['state']=='ACCEPTED'
     record={'call':inp,'actual_response':response}
 assert record,'No actual independent acceptance: refuse to write approval artifact'
 final=next(x for x in reversed(rows) if x.get('type')=='result');assert not final['is_error']
 e=json.loads((D/'execution-packet.json').read_text());m=json.loads((D/'package-current.json').read_text());assert e['package_sha256']==m['archive_sha256']
 out={'actual_hub_state':'ACCEPTED','actual_cli_exit':0,'actual_review':record,'package_sha256':e['package_sha256'],'image':e['image'],'publish_script_sha256':e['publish_script_sha256'],'publisher_controller_sha256':e['publisher_controller_sha256'],'local_browser_evidence_sha256':e['local_browser_evidence_sha256'],'report':final['result'],'trace_sha256':hashlib.sha256(trace.read_bytes()).hexdigest(),'scope':'Independent approval of this exact prepared image/publication command; public execution and verification follow separately.'}
 (D/'execution-acceptance.json').write_bytes(json.dumps(out,indent=2).encode()+b'\n');print('Actual execution ACCEPTED callback saved; no deployment executed.')
if __name__=='__main__':main()
