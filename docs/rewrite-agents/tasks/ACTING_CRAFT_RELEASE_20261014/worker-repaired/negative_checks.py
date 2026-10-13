#!/usr/bin/env python3
"""Verify actual local staging and tamper guards, without network calls."""
import argparse
import copy
import json
import subprocess
import sys
import tempfile
from pathlib import Path
import prepare_acting_craft_release as producer
import prepare_remote as remote
import publish_prepared as publisher


def rejected(label, function, contains):
    try:
        function()
    except (RuntimeError, FileNotFoundError) as error:
        assert contains in str(error), (label, str(error))
        print(f"PASS rejection: {label}")
        return
    raise AssertionError(f"guard failed to reject: {label}")


def mutated(path, mutation, function, contains, label):
    original=path.read_bytes(); value=json.loads(original)
    mutation(value)
    try:
        producer.write_json_lf(path,value)
        rejected(label,function,contains)
    finally:
        path.write_bytes(original)


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--package-json',type=Path,required=True)
    parser.add_argument('--scratch',type=Path,required=True)
    args=parser.parse_args();scratch=args.scratch.resolve()
    package=remote.load(args.package_json);stage=Path(package['stage']).resolve()
    assert stage.is_relative_to(scratch) and scratch.as_posix().endswith('.run/acting_craft_controller_repaired_20261014')
    evidence=scratch/'validation-evidence';evidence.mkdir(exist_ok=True)
    producer.write_json_lf(evidence/'package-current.json',package)
    assert publisher.BUILD_ID==remote.BUILD_ID=='quiz-2026.10.14-acting-craft-83748f5'
    assert publisher.SOURCE_COMMIT==producer.FROZEN_COMMIT
    remote.validate_package(evidence)
    print('PASS positive: actual archive/stage checksums, frozen Git blobs and working source checked')
    producer.verify_actor_raw_parity(stage)
    expected,proof=producer.expected_staging_revisions(stage,remote.BUILD_ID)
    assert sum(map(len,expected.values()))==len(proof)==156
    assert expected==remote.load(stage/'expected-staging-revisions.json')
    print('PASS positive: 156 private/staging revisions reconstructed; raw/runtime parity checked')
    # A real historical callback tests parsing and grants this package no approval.
    remote.require_actual_acceptance(remote.load(Path('C:/ap/quiz_master/docs/rewrite-agents/tasks/FILM_CRAFT_RUNTIME_RELEASE_20261013/execution-acceptance.json')))
    rejected('status-only invented acceptance',lambda:remote.require_actual_acceptance({'actual_hub_state':'ACCEPTED'}),'callback')
    rejected('missing code/package/QA acceptance',lambda:remote.reviewed_package(evidence),'static-review.json')
    rejected('missing execution approval',lambda:publisher.prepare(evidence),'execution-packet.json')
    raw=stage/'quizzes/Cinema/acting_craft_20261014.json'
    mutated(raw,lambda v:v['questions'][0].update(correct_answer=1),lambda:producer.verify_actor_raw_parity(stage),'grading mismatch','wrong raw answer')
    mutated(raw,lambda v:v['questions'][0].update(editorial_tag_ids=[]),lambda:producer.verify_actor_raw_parity(stage),'tags or explanation','raw tags removed')
    mutated(raw,lambda v:v['questions'][0].update(text='changed stem'),lambda:producer.verify_actor_raw_parity(stage),'stem mismatch','raw stem changed')
    bundle=stage/'next/content/acting-craft-20261014/bundle.json'
    mutated(bundle,lambda v:v['quiz']['questions'][0]['source'].update(title='runtime drift'),lambda:producer.verify_actor_raw_parity(stage),'revision mismatch','canonical source title drift')
    mutated(bundle,lambda v:v['quiz']['questions'][0]['revision'].update(sha256='0'*64),lambda:producer.expected_staging_revisions(stage,remote.BUILD_ID),'reconstruction mismatch','canonical revision corruption')
    mutated(stage/'web/version.json',lambda v:v.update(packs=999),lambda:remote.validate_package(evidence),'staged package changed','staged metadata tampered')
    catalog=producer.rows(producer.read_json(stage/'web/assets/assets/catalog.json'),'catalog')
    articles=producer.rows(producer.read_json(stage/'web/assets/assets/study/question-articles.json'),'articles')
    baseline_stage=Path(package['baseline_input']['archive']).with_suffix('').with_suffix('')
    old_catalog,old_articles,old_cache,old_content=producer.preserved_helm50(baseline_stage)
    actor_articles=[row for row in articles if any(ref.get('quiz_id')==producer.ACTING_CRAFT_ID for ref in row.get('question_refs',[]))]
    assert len(actor_articles)==8 and all('\\n\\n' not in row['body_ru'] for row in actor_articles)
    assert all('\\n\\n' not in row['body_ru'] for row in producer.rows(producer.read_json(stage/'study/question_articles/drafts/acting-craft-20261014.json'),'Actor draft'))
    print('PASS positive: all eight repaired Actor draft/export paragraphs contain no literal escapes')
    producer.assert_preserved(old_catalog,old_articles,catalog,articles,'actual target')
    producer.assert_content_preserved(stage,old_content)
    cache=producer.read_json(stage/'runtime-bundles.json')
    assert len(cache)==11 and all(cache[k]==v for k,v in old_cache.items())
    changed=copy.deepcopy(catalog);changed[0]['questions_count']+=1
    rejected('old catalog object changed',lambda:producer.assert_preserved(old_catalog,old_articles,changed,articles,'test'),'preserve all 133')
    changed=copy.deepcopy(articles)
    next(row for row in changed if row['id']==old_articles[0]['id'])['title_ru']='changed'
    rejected('old Reader object changed',lambda:producer.assert_preserved(old_catalog,old_articles,catalog,changed,'test'),'changed an existing')
    changed=copy.deepcopy(articles)
    music=next(row for row in changed if row['id']=='question:music-craft-pilot-001')
    music['source_links'][0]['title']='unapproved title'
    rejected('unapproved Music source title',lambda:producer.assert_preserved(old_catalog,old_articles,catalog,changed,'test'),'beyond approved source titles')
    changed=copy.deepcopy(articles)
    music=next(row for row in changed if row['id']=='question:music-craft-pilot-002')
    music['source_links'][0]['url']='https://example.invalid/changed'
    rejected('Music link URL changed',lambda:producer.assert_preserved(old_catalog,old_articles,catalog,changed,'test'),'beyond approved source titles')
    changed=[row for row in articles if row['id']!='question:acting-craft-pilot-008']
    rejected('missing eighth Actor article',lambda:producer.assert_preserved(old_catalog,old_articles,catalog,changed,'test'),'eight approved')
    mutated(stage/'next/content/acting-craft-20261014/manifest.json',lambda v:v.update(source_sha256=producer.FROZEN_ACTING_FILES[producer.RAW_PATH]),lambda:producer.verify_actor_raw_parity(stage),'identity mismatch','Git bytes digest substituted for normalized manifest digest')
    rejected('old SDK-only browser schema',lambda:remote.verify_browser_proof({'clean_sdk2_stop_acknowledged':True},{}),'fixture lifecycle')
    rejected('missing different-provider runtime',lambda:remote.require_different_provider({'actual_cli_exit':0,'reviewer_provider':'codex'}),'different-provider')
    mutated(stage/'runtime-bundles.json',lambda v:v['home-alone-1-part-1'].update(test_tamper=True),lambda:remote.validate_package(evidence),'staged package changed','old runtime cache tampered')
    with tempfile.TemporaryDirectory(dir=scratch,prefix='guards-') as directory:
        temporary=Path(directory)
        rejected('wrong baseline archive',lambda:producer.extract_immutable(raw,temporary/'stage'),'archive SHA-256')
        bad_web=temporary/'bad-web';bad_web.mkdir();(bad_web/'main.dart.js').write_bytes(b'wrong compiled output')
        rejected('wrong compiled JS',lambda:producer.copy_and_check_actor_web(Path('C:/ap/quiz_master'),producer.FROZEN_COMMIT,stage,bad_web,bad_web,old_catalog,old_articles),'JavaScript differs')
        writer=Path(__file__).parent/'save_execution_acceptance.py'
        trace=temporary/'review.jsonl';trace.write_text(json.dumps({'type':'result','is_error':False,'result':'No review callback'})+'\n')
        exit_json=temporary/'exit.json';producer.write_json_lf(exit_json,{'actual_exit':0})
        result=subprocess.run([sys.executable,str(writer),'--release-dir',str(evidence),'--trace',str(trace),'--exit-json',str(exit_json),'--task-id','missing-test-task','--reviewer-provider','claude'],capture_output=True,text=True)
        assert result.returncode!=0 and 'no actual independent ACCEPTED callback' in result.stderr
        assert not (evidence/'execution-acceptance.json').exists()
        print('PASS rejection: acceptance writer rejects missing real callback and writes nothing')
        archive,digest,members=producer.archive_and_verify(stage,temporary)
        assert digest==package['archive_sha256'] and members==package['tar_members'] and archive.is_file()
        print('PASS positive: repeat archive byte-determinism and full member count')
    guard,script=remote.remote_scripts(package)
    assert producer.BASELINE_IMAGE in guard and producer.PVC_UID in script
    assert 'bash cutover.sh prepare' in script and 'helm upgrade' not in script
    cutover=(stage/'cutover.sh').read_text()
    assert '[[ "$quiz_mode" = prepare ]]' in cutover and 'helm upgrade' not in cutover
    # Historical output pins are rendering-test data, never future image proof.
    previous_execution=remote.load(Path('C:/ap/quiz_master/docs/rewrite-agents/tasks/MUSIC_CRAFT_RELEASE_20261013/execution-packet.json'))
    for key in ('values','durable_archive'):
        previous_execution[key]=previous_execution[key].replace(producer.BASELINE_BUILD, remote.BUILD_ID)
    prefix=cutover.split('quiz_image="quiz-master:$quiz_build"')[0]
    rendered=publisher.publish_script(package,previous_execution,stage,prefix,verify_hash=False)
    assert '[[ "$quiz_mode" = publish ]]' in rendered and '[[ "$quiz_mode" = prepare ]]' not in rendered
    assert 'helm upgrade' in rendered and 'docker build' not in rendered
    bash=Path('C:/Program Files/Git/bin/bash.exe')
    assert bash.is_file(), 'native Git Bash needed for actual mode-branch check'
    for body,expected_mode in ((cutover,'prepare'),(rendered,'publish')):
        syntax=subprocess.run([str(bash),'-n'],input=body,capture_output=True,text=True)
        assert syntax.returncode==0,(expected_mode,syntax.stderr)
        print(f'PASS Bash syntax: {expected_mode} full shell exit={syntax.returncode}')
        mode_line=next(line for line in body.splitlines() if line.startswith('quiz_mode='))
        mode_guard=next(line for line in body.splitlines() if line.startswith('[[ "$quiz_mode"'))
        for mode in ('prepare','publish'):
            result=subprocess.run([str(bash),'-s','--',mode],input='set -euo pipefail\n'+mode_line+'\n'+mode_guard+'\n',capture_output=True,text=True)
            assert (result.returncode==0)==(mode==expected_mode),(expected_mode,mode,result.returncode,result.stderr)
            print(f'PASS Bash mode: {expected_mode} controller with {mode} actual exit={result.returncode}')
    for name,body in (('remote guard',guard),('remote preparation',script)):
        syntax=subprocess.run([str(bash),'-n'],input=body,capture_output=True,text=True)
        assert syntax.returncode==0,(name,syntax.stderr)
        print(f'PASS Bash syntax: {name} exit={syntax.returncode}')
    print('PASS positive: actual Bash branches permit prepare-only staging and publish-only publication')
    rejected('publisher missing preparation-only anchor',lambda:publisher.publish_script(package,previous_execution,stage,prefix.replace('[[ "$quiz_mode" = prepare ]]',''),verify_hash=False),'mode guard')
    rehearsal=(stage/'rehearse.py').read_text();compile(rehearsal,'rehearse.py','exec')
    assert 'assert graded==211 and finished==12' in rehearsal
    assert "==134, 'Unexpected bundle-cache growth'" in rehearsal and 'token=token))==12' in rehearsal
    print('PASS positive: prepare-only shell, baseline/PVC guards, 211 grading/12 history guards')
    remote.validate_package(evidence)
    report={'status':'LOCAL_POSITIVE_AND_NEGATIVE_PASS','package_sha256':package['archive_sha256'],'producer_sha256':remote.sha(Path(producer.__file__)),'prepare_controller_sha256':remote.sha(Path(remote.__file__)),'publisher_controller_sha256':remote.sha(Path(publisher.__file__)),'archive_member_count':package['tar_members'],'strict_staging_revisions':156,'remote_calls':0,'image_builds':0,'approval_artifacts_written':0,'remaining_gates':['actual independent code/package acceptance','actual local browser/Root acceptance','lead remote preparation and copied-DB/image/Helm evidence','actual independent execution acceptance','authorized lead publication']}
    producer.write_json_lf(scratch/'local-verification.json',report)
    print(json.dumps(report))


if __name__=='__main__':
    main()
