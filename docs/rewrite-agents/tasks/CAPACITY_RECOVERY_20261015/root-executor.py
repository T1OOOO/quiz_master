from pathlib import Path
import hashlib,json,subprocess,time

root=Path('docs/rewrite-agents/tasks/CAPACITY_RECOVERY_20261015')
review=json.loads((root/'acceptance.json').read_text(encoding='utf8'))
assert review['actual_cli_exit']==0 and review['actual_hub_state']=='ACCEPTED'
record=review['actual_reviews']['task-23a9a9b414d54b7986c83d2c4b760f0b']
assert record['call']['arguments']['verdict']=='accept'
note=record['call']['arguments']['note']
pins=json.loads((root/'source-pins.json').read_text())['sha256']
for name,expected in pins.items():
    assert hashlib.sha256((root/name).read_bytes()).hexdigest()==expected
    assert expected in note
trace=Path('.run/reader_public_release_20261015/cold-backup-review-01.jsonl')
assert hashlib.sha256(trace.read_bytes()).hexdigest()==review['trace_sha256']
receipt={'started_unix':time.time(),'review_trace_sha256':review['trace_sha256'],'source_pins':pins}
try:
    result=subprocess.run(['ssh','-i','C:/Users/Alexey_Matvienko/.ssh/ll_deploy_ed25519','root@192.3.164.184','bash -s'],input=(root/'execute.sh').read_bytes(),capture_output=True,timeout=240)
    receipt.update(actual_exit=result.returncode,stdout=result.stdout.decode(),stderr=result.stderr.decode())
except subprocess.TimeoutExpired as error:
    receipt.update(actual_exit=None,timed_out=True,stdout=(error.stdout or b'').decode(),stderr=(error.stderr or b'').decode())
finally:
    receipt['ended_unix']=time.time()
    (root/'execution-receipt.json').write_text(json.dumps(receipt,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
assert receipt.get('actual_exit')==0,receipt
print(receipt['stdout'])
