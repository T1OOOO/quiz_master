"""Root-only single execution; genuine exact approval and cold-copy verification precede SSH."""
if not __debug__:
    raise RuntimeError('execute refuses optimized Python')
from pathlib import Path,PurePosixPath
import hashlib,json,os,re,stat,subprocess
import offload
DOCS=Path(__file__).resolve().parent
ROOT=Path('C:/ap/quiz_master')
WORK=ROOT/'.run/reader303_release_20261015/offload-v1'
TASK_ID='task-6cb78640e3504ebd88aae1ff99f609d7'
ASSIGNEE='session-293ef5f514b24416b57853188e8bf5ce'
INPUT_FILES={'offload.py','execute.py','test_offload.py','plan.json','protected-hashes.json','copy-receipt.json','tests.json','tests-stdout.txt','offload.sh'}
SOURCE_FILES={'offload.py','execute.py','test_offload.py'}
SSH_KEY='C:/Users/Alexey_Matvienko/.ssh/ll_deploy_ed25519'
SSH_TARGET='root@192.3.164.184'

def digest(path):
    assert path.is_file() and not path.is_symlink()
    st=path.lstat()
    assert stat.S_ISREG(st.st_mode)
    value=offload.digest_file(path,offload.marker(st))
    assert offload.marker(path.lstat())==offload.marker(st) and not path.is_symlink()
    return value

def read(path):return json.loads(path.read_bytes())

def verify_copies(plan,receipt,plan_sha,protected=None):
    if protected is None:protected=read(DOCS/'protected-hashes.json')
    entries=offload.validate_plan(plan,protected)
    assert receipt['plan_sha256']==plan_sha and receipt['count']==len(entries)==len(receipt['copied'])==28
    assert receipt['bytes']==plan['total_bytes']
    copies=WORK/'copies';assert copies.is_dir() and not copies.is_symlink() and copies.resolve()==copies.absolute()
    for e,c in zip(entries,receipt['copied']):
        local=Path(c['local'])
        assert c['remote']==e['path'] and local.parent==copies and local.resolve().parent==copies.resolve()
        assert local.name==PurePosixPath(e['path']).name and not local.is_symlink()
        st=local.lstat();assert stat.S_ISREG(st.st_mode) and st.st_nlink==1 and st.st_size==e['size']==c['size']
        assert offload.digest_file(local,offload.marker(st),nlink=1)==e['sha256']==c['sha256']
        assert offload.marker(local.lstat())==offload.marker(st) and local.lstat().st_nlink==1 and not local.is_symlink()
        assert c['transfer_exit']==0 and c['transfer_kind'] in ('scp','ssh-tar','sftp-reget')

def verify_manifest(inputs):
    assert set(inputs)==INPUT_FILES,'exact approval manifest file set required'
    for name,sha in inputs.items():
        assert re.fullmatch('[0-9a-f]{64}',sha) and digest(DOCS/name)==sha,'reviewed input changed: '+name

def validate_inputs():
    manifest=DOCS/'approval-inputs.json';review_path=DOCS/'source-review.json'
    review=read(review_path)
    assert review.get('actual_cli_exit')==0 and review.get('actual_hub_state')=='ACCEPTED'
    item=review.get('actual_reviews',{}).get(TASK_ID,{})
    call,response=item.get('call',{}),item.get('actual_response',{});args=call.get('arguments',{})
    assert call.get('action')=='review' and args.get('task_id')==TASK_ID and args.get('verdict')=='accept' and args.get('error_count')==0
    assert response.get('id')==TASK_ID and response.get('state')=='ACCEPTED' and response.get('assignee')==ASSIGNEE
    assert response.get('reviewer') and response['reviewer']!=ASSIGNEE
    assert 'approval-inputs sha256 '+digest(manifest) in args.get('note','')
    inputs=read(manifest);verify_manifest(inputs)
    tests=read(DOCS/'tests.json');raw=(DOCS/'tests-stdout.txt').read_bytes()
    assert tests.get('actual_exit')==0 and type(tests.get('tests')) is int and tests['tests']>0
    assert tests.get('stdout_sha256')==hashlib.sha256(raw).hexdigest()
    assert tests.get('source_sha256')=={name:inputs[name] for name in SOURCE_FILES}
    assert re.search(rb'Ran '+str(tests['tests']).encode()+rb' tests? in ',raw) and re.search(rb'\nOK\s*$',raw)
    plan=read(DOCS/'plan.json');protected=read(DOCS/'protected-hashes.json');receipt=read(DOCS/'copy-receipt.json')
    verify_copies(plan,receipt,digest(DOCS/'plan.json'),protected)
    assert (DOCS/'offload.sh').read_bytes()==offload.render(plan,protected).encode('utf-8'),'rendered remote source differs'
    return plan,protected,receipt,inputs,digest(review_path),digest(manifest)

def main():
    logs=[WORK/name for name in ('execution-stdout.txt','execution-stderr.txt','execution-exit.json')]
    assert not any(p.exists() or p.is_symlink() for p in logs),'existing execution evidence; inspect before any retry'
    plan,protected,receipt,inputs,review_sha,manifest_sha=validate_inputs()
    assert WORK.is_dir() and not WORK.is_symlink() and WORK.resolve()==WORK.absolute()
    # Repeat every source/evidence hash and cold-file hash immediately before the single SSH operation.
    verify_manifest(inputs)
    assert digest(DOCS/'source-review.json')==review_sha and digest(DOCS/'approval-inputs.json')==manifest_sha
    verify_copies(plan,receipt,digest(DOCS/'plan.json'),protected)
    script=(DOCS/'offload.sh').read_bytes();assert hashlib.sha256(script).hexdigest()==inputs['offload.sh']
    command=['ssh','-o','BatchMode=yes','-o','ConnectTimeout=15','-i',SSH_KEY,SSH_TARGET,'bash -s']
    code='not_started';output=b''
    with logs[0].open('xb') as out,logs[1].open('xb') as err:
        try:
            result=subprocess.run(command,input=script,stdout=out,stderr=err,timeout=600)
            code=result.returncode
        except subprocess.TimeoutExpired as exc:
            # Real redirection retains partial bytes in the files; mocks may supply captured bytes instead.
            if exc.stdout and out.tell()==0:out.write(exc.stdout)
            if exc.stderr and err.tell()==0:err.write(exc.stderr)
            code='timeout'
            raise
        finally:
            with logs[2].open('x',encoding='utf-8') as stream:stream.write(json.dumps({'actual_exit':code})+'\n')
    assert code==0,'Inspect retained partial execution logs; do not retry blindly'
    print(json.dumps({'actual_exit':code,'local_verified_copies':28}))

if __name__=='__main__':main()
