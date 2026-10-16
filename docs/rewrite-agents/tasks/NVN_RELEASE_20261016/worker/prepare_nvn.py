"""Fixed NVN successor adapter. Archive creation requires genuine source acceptance."""
from pathlib import Path
import argparse,ast,hashlib,importlib.util,json,sys
sys.dont_write_bytecode=True
OWN=Path(__file__).resolve().parent
REPO=OWN.parents[4]
ROOT=OWN.parent
WORK=REPO/'.run/nvn_release_20261016/worker'
INPUTS=ROOT/'release-inputs.json'
INPUTS_SHA='931b441a658962db1cc799f79280c070131664f58ee3c043c82700c7da738eb9'
LEGACY=REPO/'docs/rewrite-agents/tasks/COUNTRY483_RELEASE_20261015/worker/prepare_country483.py'
LEGACY_SHA='5b3ad3ddfd6141d4ace3c9269ef38cd594dfb0d7011621ec2048e199e433cc76'
BASE_BUILD='quiz-2026.10.15-country483-3c22818'
BASE_SOURCE='3c2281815b768271d9110f2d28fa415c0eefe06c'
BASE_ARCHIVE=REPO/f'.run/country483_release_20261015/worker/package-v1/{BASE_BUILD}.tar.gz'
BASE_ARCHIVE_SHA='15eb5d5710251b9aca4c2cee29bbd50822388435eeed618b3476f2b0b8841416'
BASE_CHECKS='423e8acf6967be596760f6bf472420907ebc47597a16d95d90270815162daa9b'
OLD_IMAGE='docker.io/library/quiz-master@sha256:6c603a840b01c9c4605eba234e4af3d95a3f52fff12e65d9904b563db5722f14'
IMAGE='docker.io/library/quiz-master@sha256:dc230d8cec6d555c3f0e67f17a8bdab4452cb546cdf29b50c4c6395717ba8c00'
BUILD='quiz-2026.10.16-nvn-5c5a5d9'
SOURCE='5c5a5d9b91d8b1100f7a5e60156b2f4b827bc4d1'
OLD_JS='845bda5a18381599b2db7eae384b07d6447daaa6976628a3a119ea722af7b522'
PRODUCTION_JS='d32a7b929bd7533dfce2c09abf473aae72cf28eabc5f1ef04b6ee448b291ace3'
QA_JS='eae77d69cb9976ea4dc30e4a83ccfcd78da5cf40df7553911f18140b63afaa7f'
COUNTS=dict(packs=136,questions=4084,reader_articles=303,reader_refs=184,playable_refs=182,noncatalog_refs=2)
RUNTIME=REPO/'docs/rewrite-agents/tasks/NVN_FOOTER_20261016'
ALLOWED={'cutover.sh','rehearse.py','expected-staging-revisions.json','checksums.txt','web/.last_build_id','web/main.dart.js','web/version.json'}
SOURCE_TASK='task-5244c406521143dd98464b707aa46868'

def require(ok,message):
    if not ok:raise ValueError(message)

def sha(path):
    with Path(path).open('rb') as stream:return hashlib.file_digest(stream,'sha256').hexdigest()

def read(path):return json.loads(Path(path).read_bytes())

def once(text,old,new):
    require(text.count(old)==1,'exact source anchor changed: '+old)
    return text.replace(old,new)

def source_hashes():return {p.name:sha(p) for p in sorted(OWN.glob('*.py'))}

def verify_source_acceptance(helper):
    proof=read(ROOT/'source-acceptance.json')
    require(proof.get('controller_source_sha256')==source_hashes() and proof.get('release_inputs_sha256')==INPUTS_SHA,'exact reviewed controller/input map required')
    helper.verify_acceptance(proof,SOURCE_TASK,helper.house())

def verify_delta(before,after,final=False):
    require(len(before)==len(after)==332 and set(after)==set(before),'332 unchanged package members required')
    changed={name for name in before if before[name]!=after[name]}
    require(changed<=ALLOWED and (not final or changed==ALLOWED),'only exact seven NVN payload changes permitted')
    return sorted(changed)

def controls(cutover,rehearsal,production_hash,helper,preflight):
    require(production_hash==PRODUCTION_JS,'frozen production JS differs')
    marker='quiz_preflight() {\n';start=cutover.find(marker);end=cutover.find('\n}\n',start)
    require(cutover.count(marker)==1 and start>=0 and end>start,'single inherited preflight required')
    cutover=cutover[:start]+marker+preflight+'\n}\n'+cutover[end+3:]
    cutover=once(cutover,OLD_IMAGE,IMAGE)
    require(cutover.count(BASE_BUILD)==2,'two inherited build anchors required');cutover=cutover.replace(BASE_BUILD,BUILD)
    cutover=once(cutover,BASE_SOURCE,SOURCE)
    require(cutover.count(OLD_JS)==3,'three inherited JS pins required');cutover=cutover.replace(OLD_JS,PRODUCTION_JS)
    require('helm upgrade' not in cutover and '[[ "$quiz_mode" = prepare ]]' in cutover and cutover.count('\nquiz_preflight\n')==3 and cutover.count('exit 0\n')==1,'prepare-only control changed')
    require(all(x in cutover for x in ('backup_sqlite.py','rehearse.py','verify_candidate_runtime.py','helm lint','helm template','--dry-run=server','docker save','PREPARED build=')),'inherited preparation gate missing')
    cutover=once(cutover,'set -euo pipefail','set -euo pipefail\nunset PYTHONOPTIMIZE PYTHONSTARTUP')
    rehearsal=once(rehearsal,'/opt/quiz-master/releases/quiz-2026.10.15-reader303-14b7da4','/opt/quiz-master/releases/'+BASE_BUILD)
    rehearsal=once(rehearsal,'06d3ff4fca6a5b9265164459c25e4abcdc8e4c2cf753c5d1768595d457de1304',BASE_CHECKS)
    require("'prep-musicals':5" in rehearsal and 'assert graded==335 and finished==15' in rehearsal and
        "assert len(req('/v1/history',token=token))==15" in rehearsal and helper.API in rehearsal,'copied database/rollback gates changed')
    return cutover.encode(),rehearsal.encode()

def implementation():
    require(sys.flags.optimize==0 and sha(LEGACY)==LEGACY_SHA,'normal Python and immutable Country483 producer required')
    spec=importlib.util.spec_from_file_location('pinned_country483_for_nvn',LEGACY);base=importlib.util.module_from_spec(spec);spec.loader.exec_module(base)
    preflight=base.preflight_shell()
    preflight=once(preflight,"helm['version']==63","helm['version']==64");preflight=once(preflight,OLD_IMAGE,IMAGE)
    # The isolated imported namespace is retargeted; historical files never change.
    for name in ('OWN','WORK','INPUTS','INPUTS_SHA','BASE_BUILD','BASE_SOURCE','BASE_ARCHIVE','BASE_ARCHIVE_SHA','BASE_CHECKS','OLD_IMAGE','IMAGE','BUILD','SOURCE','OLD_JS','RUNTIME'):
        setattr(base,name,globals()[name])
    base.preflight_shell=lambda:preflight
    base.verify_inputs=lambda:verify_inputs(base)
    base.verify_label_delta=lambda prior,current:require(prior==current,'atlas catalog changed')
    base.patch_controls=lambda cutover,rehearsal,js:controls(cutover,rehearsal,js,base,preflight)
    def preserved(before,stage):
        result=verify_delta(before,base.file_tree(stage),sha(stage/'checksums.txt')!=BASE_CHECKS)
        require(sha(stage/'api')==base.API and sha(stage/'nginx.conf')==base.NGINX,'API/Nginx changed')
        return result
    base.verify_preserved=preserved
    text=LEGACY.read_text();tree=ast.parse(text)
    for name,old,new in [('prepare','baseline_helm_revision=63','baseline_helm_revision=64'),
                         ('verify_package',"result.get('baseline_helm_revision') == 63","result.get('baseline_helm_revision') == 64")]:
        nodes=[n for n in tree.body if isinstance(n,ast.FunctionDef) and n.name==name];require(len(nodes)==1,'immutable archive function missing')
        selected=once(ast.get_source_segment(text,nodes[0]),old,new)
        exec(compile(selected,str(OWN/'prepare_nvn.py')+'::pinned-'+name,'exec'),base.__dict__)
    return base

def verify_inputs(base):
    require(sys.flags.optimize==0 and isinstance(INPUTS_SHA,str) and sha(INPUTS)==INPUTS_SHA,'immutable actual Root manifest required')
    pins=read(INPUTS)
    return validate_inputs(pins,base)

def bound(entry,expected=None,manifest=None):
    require(set(entry)=={'path','sha256'},'exact path/hash evidence binding required')
    path=Path(entry['path'])
    require(path.resolve().is_relative_to(REPO) and (expected is None or path.resolve()==expected.resolve()) and
        all(not p.is_symlink() and not p.is_junction() for p in (path,*path.parents)) and path.is_file() and path.stat().st_nlink==1 and
        sha(path)==entry['sha256'],'evidence path/hash/identity differs')
    if manifest is not None:require(manifest.get(path.resolve().relative_to(REPO).as_posix())==entry['sha256'],'evidence missing from full runtime manifest')
    return path

def verify_runtime(proof,base):
    require(proof.get('schema_version')=='qm-nvn-runtime/v1' and proof.get('frozen_source')==SOURCE and proof.get('build_id')==BUILD and
        set(proof['builds'])==set(proof['browser'])=={'production','qa'},'actual NVN runtime identity differs')
    manifest=read(bound(proof['evidence_manifest'],ROOT/'runtime-evidence-inputs.json'))
    require(isinstance(manifest,dict) and len(manifest)==103,'full103 runtime evidence required')
    for relative,expected in manifest.items():
        require(not Path(relative).is_absolute(),'relative runtime evidence path required')
        bound(dict(path=str(REPO/relative),sha256=expected))
    for label,js in [('production',PRODUCTION_JS),('qa',QA_JS)]:
        build=proof['builds'][label]
        require(Path(build['root']).resolve()==(REPO/f'.run/nvn_footer_20261016/{label}-web').resolve() and
            type(build.get('actual_exit')) is int and build['actual_exit']==0 and build['file_count']==74 and build['main_js_sha256']==js,'named compiled runtime build differs')
        for key,suffix in [('receipt','-build.json'),('artifacts','-build-artifacts.json'),('log','-build.log')]:
            bound(build[key],RUNTIME/(label+suffix),manifest)
        browser=proof['browser'][label]
        folder=RUNTIME/'release-browser' if label=='production' else ROOT/'runtime/browser'
        cleanup=read(bound(browser['cleanup'],folder/'native-cleanup.json',manifest))
        capture=read(folder/'identity-capture.json');close=read(folder/'close.json')
        rows=cleanup['rows'];count=browser['captured_identities_inactive']
        require(type(count) is int and count>=1 and cleanup.get('actual_exit')==0 and cleanup.get('inactive') is True and
            capture.get('actual_exit')==0 and capture.get('native_and_cim_recorded_separately') is True and
            capture['captured']==len(rows)==len({r['pid'] for r in rows})==count and
            all(r['outcome'] in ('absent','native_absent_after_stale_cim') for r in rows),'captured browser identities not inactive')
        require(type(close.get('actual_exit')) is int and close['actual_exit']==browser['official_close_actual_exit'] and close['actual_exit'] in (0,1),'actual browser close outcome differs')
        if close['actual_exit']!=0:
            fallback=read(folder/'exact-daemon-cleanup.json')
            require(fallback.get('actual_exit')==0 and fallback.get('other_processes_changed') is False and
                all(fallback.get(k) is True for k in ('cim_ticks_compared_only_to_cim_ticks','native_ticks_compared_only_to_native_ticks',
                    'native_has_exited','full_command_verified','named_pidfile_verified')) and
                fallback['pid'] in {r['pid'] for r in rows} and fallback['session']==cleanup['session'] and
                fallback['namespace']==cleanup['namespace'],'exact owned-daemon fallback missing')
        else:require(close.get('timed_out') is False,'successful close timed out')
        commands=[]
        for relative in manifest:
            path=REPO/relative
            if path.parent==folder and path.suffix=='.json':
                record=read(path)
                if isinstance(record.get('command'),list):commands.append(record)
        require(len(commands)==browser['command_count'] and browser['successful_non_close_commands'] is True and
            all(type(c.get('actual_exit')) is int and c['actual_exit']==0 and c.get('timed_out') is False
                for c in commands if c['command']!=['close']),'actual browser commands failed')
        errors=read(bound(browser['errors'],folder/'errors.json',manifest))
        require(errors.get('actual_exit')==0 and not errors['stdout'].strip() and browser['root_viewed_screenshots'] is True and browser['screenshots'],'browser errors or unseen screenshots')
        for shot in browser['screenshots']:bound(shot,manifest=manifest)
    fixture=read(bound(proof['fixture_exit'],ROOT/'runtime/fixture-exit.json',manifest));cleanup=read(ROOT/'runtime/fixture-cleanup.json')
    require(proof.get('ports_closed')=={'19090':True,'19093':True} and proof.get('actual_fixture_wrapper_exit')==fixture.get('actual_wrapper_exit')==0 and
        proof.get('actual_fixture_api_terminate_exit')==fixture.get('actual_api_terminate_exit')==cleanup.get('actual_api_exit')==1 and
        fixture.get('intentional_api_termination') is True and cleanup.get('stop_seen') is True and fixture.get('no_feedback_submit_ui_action') is True and
        proof.get('fixture_proxy_post_count')==fixture.get('fixture_proxy_post_count')==0,'actual fixture cleanup/no-submit differs')

def verify_builds(pins,base):
    for label,js,api in [('production',PRODUCTION_JS,'https://quiz.kotopedia.org'),('qa',QA_JS,'http://127.0.0.1:19090')]:
        root=REPO/f'.run/nvn_footer_20261016/{label}-web'
        require(Path(pins['web_roots'][label]).resolve()==root.resolve(),'actual compiled root differs')
        receipt=read(RUNTIME/(label+'-build.json'));artifacts=read(RUNTIME/(label+'-build-artifacts.json'));command=receipt['command']
        require(type(receipt.get('actual_exit')) is int and receipt['actual_exit']==0 and command[:4]==['flutter','build','web','--release'] and
            '--no-pub' in command and '--pwa-strategy=none' in command and command.count('--output')==1 and
            Path(command[command.index('--output')+1]).resolve()==root.resolve() and
            '--dart-define=QM_BUILD_ID='+BUILD in command and '--dart-define=QM_API_BASE_URL='+api in command,'actual release build receipt differs')
        require(artifacts.get('source_commit')==SOURCE and artifacts.get('build_id')==BUILD and
            type(artifacts.get('actual_build_exit')) is int and artifacts['actual_build_exit']==0 and artifacts.get('local_only') is True and
            (artifacts.get('package_candidate_deployment_verified') is False if label=='production' else artifacts.get('qa_runtime_not_yet_executed') is True) and len(artifacts['files'])==74 and
            base.file_tree(root)==artifacts['files'] and artifacts['files']['main.dart.js']==js,'actual full compiled tree changed')
        for relative in ('quizipedia/catalog.json','quizipedia/manifest.json','catalog.json','study/question-articles.json'):
            require((root/'assets/assets'/relative).read_bytes()==(REPO/'next/apps/quiz_app/assets'/relative).read_bytes(),'compiled source asset drift')

def verify_baseline(rows):
    require(len(rows)==2,'two actual baseline records required');node,live=rows
    require(node.get('node_ready') is True and node.get('disk_pressure') is False and node.get('blocking_taints') is False and
        node.get('https_readiness_status')==200 and type(node.get('disk_available')) is int and type(node.get('disk_total')) is int and
        node['disk_available']>0 and node['disk_total']>0 and node['disk_available']*5>node['disk_total'],'baseline readiness/strict20 differs')
    require(live.get('helm_revision')==64 and live.get('status')=='deployed' and live.get('images')==[IMAGE,IMAGE] and
        live.get('available_replicas')==1 and live.get('pvc_uid')=='7fc2428f-4146-4c78-a26d-2347d9f3b7bf' and
        live.get('feedback_count')==29 and live.get('all_open') is True and
        live.get('feedback_sha256')=='452929a2ea8dc34600eff8039571e2b0479ec7ad1ec52fa6e271b5c71008030e' and
        live.get('backup_mode')=='0600' and live.get('backup_integrity')=='ok' and live.get('mutation') is False and
        live.get('existing_published_backup')=='/opt/quiz-master/backups/'+BASE_BUILD+'-publish-20261015T230615Z.sqlite' and
        live.get('existing_published_backup_sha256')==live.get('independent_restore_sha256')==
            '6794975864e19369f7e41188ad98de43244bd34153451d158115210a6e52bd21','current64 baseline or preserved backup differs')

def validate_inputs(pins,base):
    require(pins.get('schema_version')=='qm-nvn-release-inputs/v1' and pins.get('source_commit')==SOURCE and pins.get('build_id')==BUILD and
        pins.get('counts')==COUNTS and pins.get('publication_performed') is False and pins['capacity'].get('remote_peak_certified') is False,'NVN source/schema/counts differ')
    expected_baseline=dict(build_id=BASE_BUILD,helm_revision=64,image=IMAGE,pvc_uid='7fc2428f-4146-4c78-a26d-2347d9f3b7bf',feedback_count=29,
        feedback_sha256='452929a2ea8dc34600eff8039571e2b0479ec7ad1ec52fa6e271b5c71008030e')
    require(pins['baseline']==expected_baseline,'current64 baseline pins differ')
    taskroot='docs/rewrite-agents/tasks/'
    expected={taskroot+'NVN_FOOTER_20261016/'+name for name in ('production-build.json','qa-build.json','production-build-artifacts.json','qa-build-artifacts.json','independent-source-recheck.json','independent-release-inspection-review.json')}
    expected|={taskroot+'NVN_RELEASE_20261016/'+name for name in ('production-baseline.jsonl','baseline-exit.json','baseline-readonly.sh','runtime-proof.json','runtime-evidence-inputs.json')}
    expected|={'next/apps/quiz_app/assets/'+name for name in ('quizipedia/catalog.json','quizipedia/manifest.json','catalog.json','study/question-articles.json')}
    expected|={'next/apps/quiz_app/lib/quizipedia.dart','next/apps/quiz_app/test/feedback_test.dart'}
    require(set(pins['proofs'])==expected and len(expected)==17,'exact17 actual proof/source inputs required')
    for relative,entry in pins['proofs'].items():bound(entry,REPO/relative)
    for filename,task in [('independent-source-recheck.json','task-530e00d17fb643c7853f65222fde7570'),
                          ('independent-release-inspection-review.json','task-e749d651cc234509b4bbfb9ca13f77d3')]:
        base.verify_acceptance(read(RUNTIME/filename),task,base.house())
    rows=[json.loads(line) for line in (ROOT/'production-baseline.jsonl').read_text().splitlines() if line.strip()];verify_baseline(rows)
    exit=read(ROOT/'baseline-exit.json')
    require(type(exit.get('actual_exit')) is int and exit['actual_exit']==0 and exit.get('read_only') is True and
        exit.get('script_sha256')==sha(ROOT/'baseline-readonly.sh'),'actual baseline exit/script differs')
    verify_builds(pins,base);verify_runtime(read(ROOT/'runtime-proof.json'),base)
    prior=pins['prior_archive']
    require(Path(prior['path']).resolve()==BASE_ARCHIVE.resolve() and prior['sha256']==BASE_ARCHIVE_SHA and
        BASE_ARCHIVE.stat().st_size==prior['bytes']==60989538 and prior['file_members']==332 and prior['uncompressed_bytes']==108100640 and
        sha(BASE_ARCHIVE)==BASE_ARCHIVE_SHA,'immutable published Country483 archive differs')
    base.house().verify_safe_archive(BASE_ARCHIVE)
    return pins

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    mode=parser.add_mutually_exclusive_group(required=True);mode.add_argument('--prepare',type=Path);mode.add_argument('--verify',type=Path);mode.add_argument('--verify-inputs',action='store_true')
    args=parser.parse_args();base=implementation()
    if args.verify_inputs:result=verify_inputs(base)
    else:
        verify_source_acceptance(base)
        result=base.prepare(args.prepare) if args.prepare else base.verify_package(args.verify)
    print(json.dumps(result,ensure_ascii=False))

if __name__=='__main__':main()
