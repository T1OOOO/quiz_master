"""Render and verify a Country483 preparation preview; no network execution."""
from __future__ import annotations
import argparse
from datetime import datetime
import hashlib
import importlib.util
import inspect
import json
from pathlib import Path
import re
import subprocess
import sys

sys.dont_write_bytecode = True
OWN = Path(__file__).resolve().parent
REPO = OWN.parents[4]
TASKS = REPO / 'docs/rewrite-agents/tasks'
WORK = REPO / '.run/country483_remote_20261015/worker'
INPUTS = OWN.parent / 'remote-inputs.json'
INPUTS_SHA = '5d91042be65803abf07cb8ee3f97db259f6c99a7b0dd5784104c8c964c9dff11'
BUILD = 'quiz-2026.10.15-country483-3c22818'
SOURCE = '3c2281815b768271d9110f2d28fa415c0eefe06c'
ARCHIVE_SHA = '15eb5d5710251b9aca4c2cee29bbd50822388435eeed618b3476f2b0b8841416'
CHECKSUMS_SHA = '423e8acf6967be596760f6bf472420907ebc47597a16d95d90270815162daa9b'
ALIAS = 'quiz-2026.10.14-mixed-09b19cc'
ATLAS = {'/app/web/assets/assets/quizipedia/catalog.json':'09ddb9adc380cb935d35ba6b2f5ea55b9ee6b5675b8c7c6c6cddf2c25679a7dc',
         '/app/web/assets/assets/quizipedia/manifest.json':'226f75de88b696a4b173540abf7dc457cadcd91694f5113a60ee85f302a45be7'}
EXAMPLE = (BUILD + '-cutover-20990101T000000Z', 'sha256:' + '0'*64, '0'*64)


def require(ok, message):
    if not ok:
        raise RuntimeError(message)


def sha(path):
    with Path(path).open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def read(path):
    return json.loads(Path(path).read_text(encoding='utf8'))


def load(path, name):
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec); spec.loader.exec_module(module)
    return module


def bound(entry, expected):
    require(set(entry) == {'path', 'sha256'} and Path(entry['path']).resolve() == expected.resolve() and
            sha(expected) == entry['sha256'], 'pinned input path/hash changed: ' + str(expected))


def local_producer(pins):
    root = TASKS / 'COUNTRY483_RELEASE_20261015'
    expected = {'worker/prepare_country483.py', 'worker/test_country483_release.py', 'release-inputs.json',
                'review-inputs.json', 'independent-native-review.json', 'independent-integration-review.json'}
    require(set(pins['local_proofs']) == expected, 'exact accepted local proof set required')
    for relative, entry in pins['local_proofs'].items(): bound(entry, root / relative)
    return load(root / 'worker/prepare_country483.py', 'accepted_country483_package')


def validate_inputs():
    require(sys.flags.optimize == 0, 'optimized Python is forbidden')
    require(sha(INPUTS) == INPUTS_SHA, 'immutable remote inputs changed')
    pins = read(INPUTS)
    require(pins.get('schema_version') == 'qm-country483-remote-inputs/v1' and Path(pins['repo']).resolve() == REPO and
            pins.get('source_commit') == SOURCE and pins.get('build_id') == BUILD and
            pins.get('actual_candidate_image') is None and pins.get('remote_execution_authorized_by_this_file') is False and
            pins.get('remote_peak_certified') is False, 'remote preview provenance/authority differs')
    require(re.fullmatch('[0-9a-f]{32}', pins['nonce']) is not None, 'unsafe upload nonce')
    local = local_producer(pins)
    require(pins['baseline'] == dict(build_id=local.BASE_BUILD, helm_revision=63, image=local.IMAGE, pvc_uid=local.PVC,
                                   feedback_count=29, feedback_sha256=local.FEEDBACK) and pins['counts'] == local.COUNTS,
            'current63 baseline/counts differ')
    for name, task in [('independent-native-review.json','task-a1f401964fd4405bb7584efa14d2fdb8'),
                       ('independent-integration-review.json','task-ba977daca1a8416a855563f8fa717e97')]:
        local.verify_acceptance(read(TASKS/'COUNTRY483_RELEASE_20261015'/name), task, local.house())
    manifest = read(TASKS/'COUNTRY483_RELEASE_20261015/review-inputs.json')
    require(len(manifest) == 29, 'accepted local review manifest differs')
    for relative, digest in manifest.items():
        path = REPO / relative
        require(not Path(relative).is_absolute() and path.resolve().is_relative_to(REPO) and sha(path) == digest,
                'accepted local review input changed')
    receipt = local.WORK / 'package-v1/package-preparation.json'
    bound(pins['package_receipt'], receipt)
    package = local.verify_package(receipt)
    archive = Path(package['archive'])
    require(Path(pins['archive']['path']).resolve() == archive.resolve() and pins['archive']['sha256'] ==
            package['archive_sha256'] == ARCHIVE_SHA and archive.stat().st_size == pins['archive']['bytes'], 'accepted archive changed')
    historical = pins['historical_renderers']
    expected = {'docs/rewrite-agents/tasks/MIXED_RELEASE_20261014/worker/prepare_remote_mixed.py',
                'docs/rewrite-agents/tasks/READER303_RELEASE_20261015/release-worker/prepare_reader303_remote.py'}
    require(set(historical) == expected, 'exact historical renderer pins required')
    for relative, entry in historical.items(): bound(entry, REPO/relative)
    stage = archive.parent / BUILD
    expected_assets = {name:dict(package_path='web/assets/assets/quizipedia/'+name,
                                image_path='/app/web/assets/assets/quizipedia/'+name,
                                public_path='/assets/assets/quizipedia/'+name, sha256=digest)
                       for name,digest in [('catalog.json',ATLAS['/app/web/assets/assets/quizipedia/catalog.json']),
                                           ('manifest.json',ATLAS['/app/web/assets/assets/quizipedia/manifest.json'])]}
    require(pins['atlas_assets'] == expected_assets and all(sha(stage/row['package_path']) == row['sha256']
            for row in expected_assets.values()) and package['checksums_sha256'] == CHECKSUMS_SHA, 'exact candidate atlas/checksums differ')
    require(pins['ssh_target'] == 'root@192.3.164.184' and pins['ssh_key_path'] == 'C:/Users/Alexey_Matvienko/.ssh/ll_deploy_ed25519',
            'reviewed command destination differs')
    return pins, local, package


def legacy_remote(pins, local):
    path = TASKS/'MIXED_RELEASE_20261014/worker/prepare_remote_mixed.py'
    bound(pins['historical_renderers'][path.relative_to(REPO).as_posix()], path)
    require(sha(path.parent/'prepare_lotr_package.py') == local.DEPENDENCIES['MIXED_RELEASE_20261014/worker/prepare_lotr_package.py'],
            'house import dependency changed')
    stage = Path(pins['archive']['path']).parent/BUILD
    require(sha(path.parent/'verify_candidate_runtime.py') == sha(stage/'verify_candidate_runtime.py'), 'historical verifier import changed')
    sys.path.insert(0, str(path.parent))
    old = load(path, 'country483_legacy_remote')
    old.BASELINE_IMAGE = local.IMAGE
    return old


def replace(text, old, new):
    require(text.count(old) == 1, 'historical renderer anchor absent/duplicated: ' + old)
    return text.replace(old, new)


def validate_identity(run, image, durable=None):
    require(isinstance(run, str) and re.fullmatch(re.escape(BUILD) + r'-cutover-\d{8}T\d{6}Z', run) is not None, 'unsafe preparation run')
    datetime.strptime(run.rsplit('-cutover-',1)[1], '%Y%m%dT%H%M%SZ')
    require(isinstance(image, str) and re.fullmatch('sha256:[0-9a-f]{64}', image) is not None, 'immutable image ID required')
    if durable is not None: require(isinstance(durable, str) and re.fullmatch('[0-9a-f]{64}', durable) is not None, 'unsafe durable digest')


def candidate_command(image):
    require(isinstance(image, str) and re.fullmatch('sha256:[0-9a-f]{64}', image) is not None, 'immutable image ID required')
    return ['docker','run','--rm','--network=none','--read-only','--cap-drop=ALL','--security-opt=no-new-privileges',
            '--user=10001:10001','--entrypoint=sha256sum',image,*ATLAS]


def verify_atlas_receipt(receipt, run, image, runtime_sha):
    validate_identity(run, image)
    require(isinstance(runtime_sha,str) and re.fullmatch('[0-9a-f]{64}',runtime_sha) is not None, 'invalid runtime receipt hash')
    expected = dict(schema_version='qm-country483-candidate-atlas/v1', status='VERIFIED_CANDIDATE_ATLAS_NOT_PUBLISHED',
                    build_id=BUILD, source_commit=SOURCE, package_sha256=ARCHIVE_SHA, package_checksums_sha256=CHECKSUMS_SHA,
                    run=run, image=image, candidate_runtime_sha256=runtime_sha, atlas_sha256=ATLAS, actual_exit=0,
                    stateless=True, production_db_mounted=False)
    require(isinstance(receipt,dict) and receipt == expected and type(receipt.get('actual_exit')) is int,
            'candidate atlas receipt/image/package/hash mismatch')


def atlas_library():
    # The same pure validation functions are reviewed locally and embedded verbatim in both remote Python blocks.
    imports = 'import json,re,hashlib,pathlib,subprocess\nfrom datetime import datetime\n'
    constants = ''.join(name+'='+repr(globals()[name])+'\n' for name in ('BUILD','SOURCE','ARCHIVE_SHA','CHECKSUMS_SHA','ATLAS'))
    return imports + constants + '\n'.join(inspect.getsource(fn) for fn in (require,validate_identity,candidate_command,verify_atlas_receipt))


def atlas_check_shell():
    code = atlas_library() + '''
root=pathlib.Path.cwd()
matches=re.findall(r'PREPARED build=(\\S+) image=(sha256:[a-f0-9]{64}) values=(\\S+) mode=prepare', (root/'prepare.log').read_text())
require(len(matches)==1 and matches[0][0]==BUILD,'one exact successful preparation marker required')
image=matches[0][1];values=matches[0][2]
require(values.endswith('-values.yaml'),'prepared values name differs')
run=values.removesuffix('-values.yaml');validate_identity(run,image)
require(subprocess.check_output(['docker','image','inspect','quiz-master:'+BUILD,'--format','{{.Id}}'],text=True).strip()==image,'candidate tag changed')
runtime=root/(run+'-candidate-runtime.json');runtime_sha=hashlib.sha256(runtime.read_bytes()).hexdigest()
require(json.loads(runtime.read_text()).get('image')=='quiz-master:'+BUILD,'runtime image binding differs')
require(hashlib.sha256((root/'checksums.txt').read_bytes()).hexdigest()==CHECKSUMS_SHA,'candidate package checksums changed')
raw=subprocess.check_output(candidate_command(image),text=True,timeout=45)
lines=raw.splitlines();require(len(lines)==2,'exact two atlas output rows required')
observed={}
for line in lines:
 digest,path=line.split('  ',1);require(path not in observed,'duplicate atlas path');observed[path]=digest
require(observed==ATLAS,'candidate atlas hash mismatch')
receipt=dict(schema_version='qm-country483-candidate-atlas/v1',status='VERIFIED_CANDIDATE_ATLAS_NOT_PUBLISHED',build_id=BUILD,
 source_commit=SOURCE,package_sha256=ARCHIVE_SHA,package_checksums_sha256=CHECKSUMS_SHA,run=run,image=image,
 candidate_runtime_sha256=runtime_sha,atlas_sha256=observed,actual_exit=0,stateless=True,production_db_mounted=False)
verify_atlas_receipt(receipt,run,image,runtime_sha)
path=root/(run+'-candidate-atlas.json')
with path.open('x',encoding='utf8') as stream:stream.write(json.dumps(receipt,sort_keys=True,indent=2)+'\\n')
print('CANDIDATE_ATLAS_VERIFIED build='+BUILD+' image='+image+' run='+run)
'''
    return "python3 - <<'COUNTRY483_ATLAS'\n" + code + '\nCOUNTRY483_ATLAS\n'


def remote_scripts(pins, local, package, nonce):
    require(sha(INPUTS) == INPUTS_SHA and pins == read(INPUTS), 'render inputs changed')
    require(package.get('build_id') == BUILD and package.get('archive_sha256') == ARCHIVE_SHA and
            isinstance(nonce,str) and re.fullmatch('[0-9a-f]{32}',nonce) is not None, 'fixed package/nonce differs')
    old = legacy_remote(pins,local)
    guard, script = old.remote_scripts({**package,'build_id':ALIAS}, nonce)
    def adapt(text):
        text = text.replace(ALIAS, BUILD)
        text = replace(text, 'version==52 and status=="deployed"', 'version==63 and status=="deployed"')
        return replace(text, 'test "$(df --output=avail -B1 /opt/quiz-master | tail -1)" -gt 4000000000', local.preflight_shell())
    guard, script = adapt(guard), adapt(script)
    script += '\nexec 8>/opt/quiz-master/DEPLOY.lock\nflock -n 8\n'+local.preflight_shell()+'\n'
    script += atlas_check_shell() + local.preflight_shell() + '\n'
    require('helm upgrade' not in script and 'kubectl apply -n' not in script and ALIAS not in script, 'publication or stale alias in preparation')
    return guard,script


def collection_script(pins, local, run, image, durable):
    require(sha(INPUTS) == INPUTS_SHA and pins == read(INPUTS), 'collection inputs changed')
    validate_identity(run,image,durable)
    old = legacy_remote(pins,local)
    script = old.collection_script(ALIAS,run.replace(BUILD,ALIAS,1),image,durable).replace(ALIAS,BUILD)
    script = replace(script,'x["version"]==52','x["version"]==63')
    script = replace(script,"'baseline_helm_revision':52","'baseline_helm_revision':63")
    script = replace(script,"free=shutil.disk_usage('/opt/quiz-master').free;assert free>4000000000",
                     "import os;usage=os.statvfs('/var/lib/rancher/k3s/agent/containerd');free=usage.f_bavail*usage.f_frsize;assert free*5>usage.f_blocks*usage.f_frsize")
    script = replace(script,'expected_packs=136,expected_questions=4084)',
                     'expected_packs=136,expected_questions=4084,expected_articles=303,expected_total_refs=184,expected_playable_refs=182)')
    prefix = "set -euo pipefail\nexec 8>/opt/quiz-master/DEPLOY.lock\nflock -n 8\n"+local.preflight_shell()+'\n'
    script = replace(script,'set -euo pipefail\n',prefix)
    binding = atlas_library() + f'''
require(hashlib.sha256((root/'checksums.txt').read_bytes()).hexdigest()==CHECKSUMS_SHA,'collected package checksums differ')
require(subprocess.check_output(['docker','image','inspect','quiz-master:'+BUILD,'--format','{{{{.Id}}}}'],text=True).strip()=={image!r},'collected candidate tag changed')
atlas_path=root/(run+'-candidate-atlas.json');atlas=json.loads(atlas_path.read_text())
verify_atlas_receipt(atlas,run,{image!r},h(runtime))
'''
    script = replace(script,'print(json.dumps({',binding+'\nprint(json.dumps({')
    script = replace(script,"'status':'PREPARED_NOT_PUBLISHED'", "'status':'PREPARED_NOT_PUBLISHED','source_commit':SOURCE,'package_sha256':ARCHIVE_SHA,'candidate_atlas':atlas,'candidate_atlas_sha256':h(atlas_path)")
    require('helm upgrade' not in script and ALIAS not in script, 'publication or alias in collection')
    return script


def source_hashes():
    return {p.name:sha(p) for p in sorted(OWN.glob('*.py'))}


def render_bodies(pins, local, package):
    guard,prepare = remote_scripts(pins,local,package,pins['nonce'])
    return {'guard.sh':guard,'prepare.sh':prepare,'collection-INERT-EXAMPLE.sh':collection_script(pins,local,*EXAMPLE)}


def preview_record(output, pins, package, bodies):
    target=pins['ssh_target'];key=pins['ssh_key_path'];upload='/opt/quiz-master/releases/'+BUILD+'.tar.gz.upload-'+pins['nonce']
    ssh=['ssh','-o','BatchMode=yes','-o','IdentitiesOnly=yes','-i',key,target,'bash -s']
    return dict(status='LOCAL_PREVIEW_ONLY',build_id=BUILD,source_commit=SOURCE,inputs_sha256=INPUTS_SHA,nonce=pins['nonce'],
                archive_sha256=ARCHIVE_SHA,package_receipt_sha256=pins['package_receipt']['sha256'],upload_destination=upload,
                source_sha256=source_hashes(),artifacts_sha256={n:hashlib.sha256(v.encode()).hexdigest() for n,v in bodies.items()},
                commands=[dict(label='guard',argv=ssh,stdin=str(output/'guard.sh'),timeout_seconds=40),
                          dict(label='upload',argv=['scp','-o','BatchMode=yes','-o','IdentitiesOnly=yes','-i',key,package['archive'],target+':'+upload],timeout_seconds=120),
                          dict(label='prepare',argv=ssh,stdin=str(output/'prepare.sh'),timeout_seconds=600)],
                actual_candidate_image=None,collection_example_only=True,inert_example_bindings=dict(zip(('run','image','durable_sha256'),EXAMPLE)),
                later_collection_renderer='collection_script(pins, local, actual_run, actual_immutable_image, actual_durable_sha256)',
                remote_execution_performed=False,execution_authorized=False,new_remote_helper_review_required=True,
                remote_peak_certified=False,publication_path=False)


def render(output):
    pins,local,package=validate_inputs();output=Path(output)
    require(output.resolve().is_relative_to(WORK) and output.resolve()!=WORK.resolve() and not output.exists(), 'fresh worker preview output required')
    require(all(not p.is_symlink() and not p.is_junction() for p in (output,*output.parents)), 'linked preview output forbidden')
    bodies=render_bodies(pins,local,package);record=preview_record(output,pins,package,bodies)
    output.mkdir(parents=True)
    for name,body in bodies.items(): (output/name).write_bytes(body.encode())
    (output/'preview.json').write_text(json.dumps(record,indent=2)+'\n',encoding='utf8')
    return record


def verify_preview(path):
    pins,local,package=validate_inputs();path=Path(path)
    require(path.name=='preview.json' and path.resolve().is_relative_to(WORK) and not path.is_symlink(), 'preview boundary differs')
    bodies=render_bodies(pins,local,package)
    require(read(path)==preview_record(path.parent,pins,package,bodies), 'preview contract or reviewed source changed')
    require({p.name for p in path.parent.iterdir()}==set(bodies)|{'preview.json'}, 'preview membership differs')
    for name,body in bodies.items(): require((path.parent/name).read_bytes()==body.encode(), 'rendered preview source changed: '+name)
    return read(path)


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    mode=parser.add_mutually_exclusive_group(required=True);mode.add_argument('--output-root',type=Path);mode.add_argument('--verify-preview',type=Path)
    args=parser.parse_args()
    print(json.dumps(verify_preview(args.verify_preview) if args.verify_preview else render(args.output_root)))


if __name__=='__main__':main()
