"""Render a fixed Country483 publication packet only from actual pinned preparation evidence."""
from pathlib import Path
import hashlib,importlib.util,json,re,sys
sys.dont_write_bytecode=True
OWN=Path(__file__).resolve().parent
REPO=OWN.parents[4]
TASK=OWN.parent
DOCS=TASK/'publication'
WORK=REPO/'.run/country483_remote_20261015'
PACKAGE=REPO/'.run/country483_release_20261015/worker/package-v1/package-preparation.json'
PREPARATION=WORK/'remote-preparation-verification.json'
PREP_EXIT=TASK/'retry/actual/exit.json'
COLLECT_EXIT=TASK/'retry/collection/exit.json'
CORRECT=TASK/'capacity/atlas-v2/correct_atlas_paths.py'
CORRECT_SHA='dba111f870aa09129e68d329886c16efd75736a965da9ed067b28c2c476dc6e0'
RETRY_SHA='0d6dc91aea513eb10afca4a4ef24a029938b93971fdbf4e638395a400f1aa5e4'
BUILD='quiz-2026.10.15-country483-3c22818'
SOURCE='3c2281815b768271d9110f2d28fa415c0eefe06c'
ARCHIVE_SHA='15eb5d5710251b9aca4c2cee29bbd50822388435eeed618b3476f2b0b8841416'
CHECKSUMS_SHA='423e8acf6967be596760f6bf472420907ebc47597a16d95d90270815162daa9b'
BASE_IMAGE='docker.io/library/quiz-master@sha256:6c603a840b01c9c4605eba234e4af3d95a3f52fff12e65d9904b563db5722f14'
BROWSER=REPO/'docs/rewrite-agents/tasks/COUNTRY483_RUNTIME_20261015/browser-proof.json'
BROWSER_SHA='164c6a9e42d2e6e652c02baf8f944743109126f2a03513aa5db7f2d9d94feb6e'
ATLAS={name:value for name,value in [('catalog.json','09ddb9adc380cb935d35ba6b2f5ea55b9ee6b5675b8c7c6c6cddf2c25679a7dc'),
    ('manifest.json','226f75de88b696a4b173540abf7dc457cadcd91694f5113a60ee85f302a45be7')]}
SSH_PREFIX=['ssh','-o','BatchMode=yes','-o','IdentitiesOnly=yes','-i','C:/Users/Alexey_Matvienko/.ssh/ll_deploy_ed25519','root@192.3.164.184']

def require(ok,message):
    if not ok:raise ValueError(message)

def h(path):
    with Path(path).open('rb') as stream:return hashlib.file_digest(stream,'sha256').hexdigest()

def digest(raw):return hashlib.sha256(raw).hexdigest()
def read(path):return json.loads(Path(path).read_bytes())
def hexhash(value):return isinstance(value,str) and re.fullmatch('[0-9a-f]{64}',value) is not None and value!='0'*64

def publication_boundary():
    require(DOCS.resolve().parent==TASK.resolve() and all(not p.is_symlink() and not p.is_junction() for p in (DOCS,*DOCS.parents)),
        'linked/outside publication output forbidden')

def load(path,name):
    spec=importlib.util.spec_from_file_location(name,path);module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module);return module

def pin(name,expected):
    entry=read(DOCS/name)
    require(set(entry)=={'path','sha256'} and Path(entry['path']).resolve()==expected.resolve() and hexhash(entry['sha256']),'receipt path binding differs: '+name)
    require(all(not p.is_symlink() and not p.is_junction() for p in (expected,*expected.parents)),'linked evidence forbidden')
    require(h(expected)==entry['sha256'],'receipt hash differs: '+name)
    return read(expected),dict(path=str(expected.resolve()),sha256=entry['sha256'])

def validate_evidence(e,prep,prep_stdout,collection,collection_stdout,receipt_sha):
    require(e.get('build_id')==BUILD and e.get('source_commit')==SOURCE and e.get('package_sha256')==ARCHIVE_SHA and
        e.get('status')=='PREPARED_NOT_PUBLISHED' and e.get('baseline_helm_revision')==63,'actual preparation identity differs')
    image=e['image'];require(isinstance(image,str) and re.fullmatch('sha256:[0-9a-f]{64}',image) is not None and hexhash(image[7:]),'actual immutable image required')
    values=e['values'];require(re.fullmatch(re.escape(BUILD)+r'-cutover-\d{8}T\d{6}Z-values.yaml',values) is not None,'unsafe actual values name')
    run=values.removesuffix('-values.yaml')
    for key in ('values_sha256','backup_sha256','copied_db_rehearsal_sha256','candidate_runtime_sha256','candidate_atlas_sha256','helm_dryrun_sha256','durable_archive_sha256'):
        require(hexhash(e[key]),'missing actual hash: '+key)
    require(e['backup_path']=='/opt/quiz-master/backups/'+run+'.sqlite' and e['backup_mode']=='0600' and e['backup_integrity']=='ok' and
        e['durable_archive']=='/var/lib/rancher/k3s/agent/images/'+BUILD+'.tar','actual backup/durable boundary differs')
    a=e['copied_db_rehearsal']
    require(all(a.get(k)==v for k,v in {'migration':'ok','original_rows_preserved':True,'integrity':'ok','feedback_lifecycle':'ok','old_api_rollback':'ok',
        'canonical_packs':14,'canonical_questions':280,'newyear_questions':55,'total_graded':335,'practice_finished':15}.items()) and
        a['post_migration_counts'][3]-a['original_counts'][3]==136,'copied database gates differ')
    expected_atlas=dict(schema_version='qm-country483-candidate-atlas/v1',status='VERIFIED_CANDIDATE_ATLAS_NOT_PUBLISHED',build_id=BUILD,
        source_commit=SOURCE,package_sha256=ARCHIVE_SHA,package_checksums_sha256=CHECKSUMS_SHA,run=run,image=image,
        candidate_runtime_sha256=e['candidate_runtime_sha256'],atlas_sha256={'/usr/share/nginx/html/assets/assets/quizipedia/'+n:v for n,v in ATLAS.items()},
        actual_exit=0,stateless=True,production_db_mounted=False)
    require(e['candidate_atlas']==expected_atlas and type(e['candidate_atlas']['actual_exit']) is int,'candidate atlas binding differs')
    require(digest((json.dumps(expected_atlas,sort_keys=True,indent=2)+'\n').encode())==e['candidate_atlas_sha256'],'candidate atlas raw receipt hash differs')
    for exit_receipt,stdout in ((prep,prep_stdout),(collection,collection_stdout)):
        require(type(exit_receipt.get('actual_exit')) is int and exit_receipt['actual_exit']==0 and
            exit_receipt['stdout_sha256']==digest(stdout),'actual transport exit/stdout binding differs')
        require(exit_receipt['command']==SSH_PREFIX+['env -u PYTHONOPTIMIZE -u PYTHONSTARTUP bash -s'],'reviewed exact normal-Python SSH command required')
    require(prep['script_sha256']==RETRY_SHA,'retry source hash differs')
    matches=re.findall(r'PREPARED build=(\S+) image=(sha256:[a-f0-9]{64}) values=(\S+) mode=prepare',prep_stdout.decode())
    require(matches==[(BUILD,image,values)],'actual preparation stdout marker differs')
    require(json.loads(collection_stdout.decode().strip().splitlines()[-1])==e,'collector final JSON differs from saved receipt')
    require(all(collection.get(k)==v for k,v in dict(build_id=BUILD,source_commit=SOURCE,image=image,run=run,prepared_receipt_sha256=receipt_sha).items()),'collection transport identity differs')
    return run

def context():
    require(sys.flags.optimize==0,'optimized Python forbidden')
    p,pin_package=pin('package-receipt-pin.json',PACKAGE)
    e,pin_preparation=pin('preparation-receipt-pin.json',PREPARATION)
    prep,pin_prep=pin('preparation-execution-pin.json',PREP_EXIT)
    collection,pin_collection=pin('collection-execution-pin.json',COLLECT_EXIT)
    require(h(CORRECT)==CORRECT_SHA and h(BROWSER)==BROWSER_SHA,'accepted corrected renderer/QA changed')
    corrected=load(CORRECT,'country483_corrected_publication');remote,pins,local,package=corrected.context()
    require(package==p and p['archive_sha256']==ARCHIVE_SHA and p['checksums_sha256']==CHECKSUMS_SHA,'accepted actual package differs')
    run=validate_evidence(e,prep,(PREP_EXIT.parent/'stdout.txt').read_bytes(),collection,(COLLECT_EXIT.parent/'stdout.txt').read_bytes(),pin_preparation['sha256'])
    collector=COLLECT_EXIT.parent/'script.sh';expected=corrected.collection_script(run,e['image'],e['durable_archive_sha256']).encode()
    require(collector.read_bytes()==expected and h(collector)==collection['script_sha256'],'actual collector source differs')
    stage=Path(p['archive']).parent/BUILD
    runtime=load(stage/'verify_candidate_runtime.py','country483_publication_runtime')
    runtime.verify_runtime_receipt(e['candidate_runtime'],'quiz-master:'+BUILD,expected_packs=136,expected_questions=4084,
        expected_articles=303,expected_total_refs=184,expected_playable_refs=182)
    binding=dict(package_receipt=pin_package,preparation_receipt=pin_preparation,preparation_execution=pin_prep,collection_execution=pin_collection,
        local_browser_sha256=BROWSER_SHA,corrected_renderer_sha256=CORRECT_SHA,collector_script_sha256=h(collector))
    return p,e,stage,binding,local.preflight_shell()

def script(p,e,stage,preflight):
    text=(stage/'cutover.sh').read_text();anchor='quiz_run="$quiz_build-cutover-'
    require(text.count(anchor)==1,'cutover boundary changed');prefix=text.split(anchor)[0]
    require('docker build' not in prefix and 'backup_sqlite' not in prefix and prefix.count('[[ "$quiz_mode" = prepare ]]')==1 and
        'quiz_preflight()' in prefix and 'f_bavail' in prefix,'prepare/publish prefix contract differs')
    prefix=prefix.replace('[[ "$quiz_mode" = prepare ]]','[[ "$quiz_mode" = publish ]]').replace('set -euo pipefail','set -euo pipefail\nunset PYTHONOPTIMIZE PYTHONSTARTUP',1)
    require(preflight.count("helm['version']==63")==1 and preflight.count(BASE_IMAGE)==1,'current63 postflight anchor differs')
    postflight=preflight.replace("helm['version']==63","helm['version']==64").replace(BASE_IMAGE,'docker.io/library/quiz-master@'+e['image'])
    shell=prefix+f'''\nquiz_preflight
echo '{e['durable_archive_sha256']}  {e['durable_archive']}' | sha256sum -c -
echo '{e['values_sha256']}  {e['values']}' | sha256sum -c -
quiz_digest='{e['image']}'
quiz_values='{e['values']}'
k3s ctr images ls | awk -v image="docker.io/library/quiz-master@$quiz_digest" '$1==image {{found=1}} END {{exit !found}}'
quiz_run="$quiz_build-publish-$(date -u +%Y%m%dT%H%M%SZ)"
python3 backup_sqlite.py "/opt/quiz-master/backups/$quiz_run.sqlite"
helm lint --strict chart -n quiz-master -f "$quiz_values"
helm template quiz-master chart -n quiz-master -f "$quiz_values" > "$quiz_run-rendered.yaml"
echo '{e['helm_dryrun_sha256']}  '"$quiz_run-rendered.yaml" | sha256sum -c -
kubectl apply --dry-run=server -n quiz-master -f "$quiz_run-rendered.yaml"
quiz_preflight
helm upgrade quiz-master chart -n quiz-master -f "$quiz_values" --atomic --wait --timeout 180s
{postflight}
curl -fsS https://quiz.kotopedia.org/version.json | python3 -c 'import json,sys;assert json.load(sys.stdin)==json.load(open("web/version.json"))'
'''
    for public,local in [('main.dart.js','web/main.dart.js'),('assets/assets/study/question-articles.json','web/assets/assets/study/question-articles.json')]:
        shell+=f'test "$(curl -fsS https://quiz.kotopedia.org/{public} | sha256sum | cut -d \' \' -f 1)" = {h(stage/local)}\n'
    for name,value in ATLAS.items():shell+=f'test "$(curl -fsS https://quiz.kotopedia.org/assets/assets/quizipedia/{name} | sha256sum | cut -d \' \' -f 1)" = {value}\n'
    shell+='printf \'PUBLISHED build=%s image=%s backup=%s\\n\' "$quiz_build" "$quiz_digest" "$quiz_run"\n'
    require(shell.count('helm upgrade')==1 and all(x not in shell for x in ('docker build','flutter build','rehearse-')),'publication must not rebuild or rehearse')
    return shell

def packet(p,e,binding,shell):
    return dict(e,publication_bindings=binding,publish_script_sha256=digest(shell.encode()),publication_renderer_sha256=h(Path(__file__)),
        package_receipt_path=binding['package_receipt']['path'],package_receipt_sha256=binding['package_receipt']['sha256'])

def main():
    require(sys.flags.optimize==0,'optimized Python forbidden');publication_boundary()
    require(all(not (DOCS/n).exists() and not (DOCS/n).is_symlink() for n in ('publish-preview.sh','execution-packet.json')),'existing publication outputs forbidden')
    p,e,stage,binding,preflight=context();shell=script(p,e,stage,preflight);out=packet(p,e,binding,shell)
    DOCS.mkdir(parents=True,exist_ok=True)
    with (DOCS/'publish-preview.sh').open('xb') as stream:stream.write(shell.encode())
    with (DOCS/'execution-packet.json').open('x',encoding='utf8') as stream:stream.write(json.dumps(out,indent=2)+'\n')
    print('LOCAL_PUBLICATION_PACKET_ONLY; no publication performed')

if __name__=='__main__':main()
