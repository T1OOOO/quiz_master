"""Root-only executor; importing this module performs no I/O or publication."""
from pathlib import Path
import json,re,subprocess,sys
sys.dont_write_bytecode=True
import render_publication as r

def validate_acceptance(a,e,executor_sha,packet_sha,script_sha):
    r.require(type(a.get('actual_cli_exit')) is int and a['actual_cli_exit']==0 and a.get('actual_hub_state')=='ACCEPTED' and
        a.get('reviewer_provider')=='claude','actual independent acceptance required')
    r.require(a.get('publication_executor_sha256')==executor_sha and a.get('execution_packet_sha256')==packet_sha and
        a.get('publish_script_sha256')==e['publish_script_sha256']==script_sha and a.get('package_sha256')==e['package_sha256']==r.ARCHIVE_SHA and
        a.get('image')==e['image'],'exact execution source/packet/package/image binding differs')
    task=a.get('execution_review_task_id','')
    r.require(isinstance(task,str) and re.fullmatch('task-[0-9a-f]{32}',task) is not None and task not in {
        'task-c6511c146826432dbfc37acdcef563d0','task-c00ba35afa2d4f82ac88ff2936b47dfa','task-1f1ca79d0de24c93954406a82768c20f'},'new exact execution review task required')
    callback=a['actual_reviews'][task];call=callback['call'];response=callback['actual_response'];args=call['arguments']
    r.require(call['action']=='review' and args['task_id']==response['id']==task and args['verdict']=='accept' and
        type(args['error_count']) is int and args['error_count']==0 and response['state']=='ACCEPTED' and
        isinstance(response.get('assignee'),str) and isinstance(response.get('reviewer'),str) and response['assignee']!=response['reviewer'] and
        r.BUILD in args['note'] and 'execution-packet sha256 '+packet_sha in args['note'],'actual exact different-provider callback differs')

def main():
    r.require(sys.flags.optimize==0,'optimized Python forbidden')
    r.publication_boundary()
    r.require(all(not (r.DOCS/n).exists() and not (r.DOCS/n).is_symlink() for n in ('publish-log.txt','publish-exit.json')),'existing publication evidence; inspect before repeat')
    a=r.read(r.DOCS/'execution-acceptance.json');e=r.read(r.DOCS/'execution-packet.json')
    validate_acceptance(a,e,r.h(Path(__file__)),r.h(r.DOCS/'execution-packet.json'),r.h(r.DOCS/'publish-preview.sh'))
    p,current,stage,binding,preflight=r.context()
    script=r.script(p,current,stage,preflight)
    r.require(r.packet(p,current,binding,script)==e and (r.DOCS/'publish-preview.sh').read_bytes()==script.encode(),'reviewed packet or fresh receipt/source binding drift')
    for revisions in ((r.SOURCE,'HEAD'),(r.SOURCE,)):
        changed=subprocess.check_output(['git','diff','--name-only',*revisions,'--','next','quizzes','metadata','study/question_articles','quizipedia'],cwd=r.REPO)
        r.require(not changed.strip(),'protected application source drift')
    command=r.SSH_PREFIX+['env -u PYTHONOPTIMIZE -u PYTHONSTARTUP bash -s -- publish']
    packet_sha=r.h(r.DOCS/'execution-packet.json')
    output=b'';code='not_started'
    try:
        result=subprocess.run(command,input=script.encode(),stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=600)
        output=result.stdout;code=result.returncode
    except subprocess.TimeoutExpired as exc:
        output=exc.stdout or b'';code='timeout';raise
    finally:
        with (r.DOCS/'publish-log.txt').open('xb') as stream:stream.write(output)
        receipt=dict(actual_exit=code,command=command,execution_packet_sha256=packet_sha,
            script_sha256=r.digest(script.encode()),stdout_sha256=r.digest(output))
        with (r.DOCS/'publish-exit.json').open('x',encoding='utf8') as stream:stream.write(json.dumps(receipt,indent=2)+'\n')
    print(output.decode(errors='replace'));r.require(type(code) is int and code==0,'actual publication command failed')

if __name__=='__main__':main()
