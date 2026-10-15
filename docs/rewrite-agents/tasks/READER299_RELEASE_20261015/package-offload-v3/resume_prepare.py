"""Continue the existing frozen stage with a fresh preparation run; Root execution only."""
if not __debug__:
    raise RuntimeError('preparation resume refuses optimized Python')

from pathlib import Path
import argparse, hashlib, importlib.util, json, re, subprocess, sys, uuid
import execute

DOCS = Path(__file__).resolve().parent
REPO = DOCS.parents[4]
SOURCE_A = DOCS.parent / 'release-worker'
FAILED = REPO / '.run/reader299_release_20261015/remote-v1'
PACKAGE_PATH = REPO / '.run/reader299_release_20261015/package-v1/package-preparation.json'
PINS_PATH = DOCS.parent / 'release-pins-v1.json'
BUILD = 'quiz-2026.10.15-reader299-9c670e9'
FAILED_RUN = BUILD + '-cutover-20261015T115837Z'
CANDIDATE = 'sha256:faef7c1c7486c437ed569a457dc71ad690342d4cd7010be143caa5bfcc2885f1'
PACKAGE_SHA = '01ddc3ee1cd7ef68376ec1dc84c06ad9c8ab88970995715edce3e631a5c7417d'
REMOTE_ROOT = '/opt/quiz-master/releases/' + BUILD


def load_source_a():
    if str(SOURCE_A) not in sys.path: sys.path.insert(0, str(SOURCE_A))
    spec = importlib.util.spec_from_file_location('reader299_resume_source_a', SOURCE_A / 'prepare_reader299_remote.py')
    module = importlib.util.module_from_spec(spec); spec.loader.exec_module(module)
    return module


def read(path): return json.loads(Path(path).read_bytes())


def verify_external_sources():
    hashes = read(DOCS / 'source-input-sha256.json')
    source_a = load_source_a()
    required = {str(path.resolve()) for path in source_a.reader.controller_sources()}
    required |= {str(path.resolve()) for path in (PACKAGE_PATH, PINS_PATH)}
    required |= {str((FAILED / name).resolve()) for name in ('remote-prepare-script.sh', 'remote-prepare-log.txt', 'remote-prepare-exit.json')}
    assert set(hashes) == required
    assert all(execute.digest(Path(path)) == sha for path, sha in hashes.items())
    return source_a


def verify_failure(bindings, source_a):
    assert bindings['build_id'] == BUILD and bindings['failed_run'] == FAILED_RUN and bindings['candidate_image_id'] == CANDIDATE
    expected = {REMOTE_ROOT + '/' + name for name in ('cutover.sh', 'checksums.txt', 'prepare.log', FAILED_RUN + '-candidate-runtime.json', FAILED_RUN + '-rehearsal.json')}
    assert set(bindings['files']) == expected
    assert all(re.fullmatch('[0-9a-f]{64}', sha) for sha in bindings['files'].values())
    assert bindings['failed_backup']['path'] == '/opt/quiz-master/backups/' + FAILED_RUN + '.sqlite'
    assert re.fullmatch('[0-9a-f]{64}', bindings['failed_backup']['sha256'])
    assert bindings['failed_local_evidence_sha256'] == {name: execute.digest(FAILED / name) for name in ('remote-prepare-script.sh', 'remote-prepare-log.txt', 'remote-prepare-exit.json')}
    assert read(FAILED / 'remote-prepare-exit.json') == {'actual_exit': 1}
    receipts = []
    for line in (FAILED / 'remote-prepare-log.txt').read_text(encoding='utf-8').splitlines():
        try: item = json.loads(line)
        except json.JSONDecodeError: continue
        if isinstance(item, dict) and item.get('schema_version') == 'qm-candidate-runtime/v1': receipts.append(item)
    assert len(receipts) == 1 and receipts[0]['image_id'] == CANDIDATE
    source_a.reader.runtime_house().verify_runtime_receipt(receipts[0], 'quiz-master:' + BUILD, expected_packs=136, expected_questions=4084, expected_articles=299, expected_total_refs=180, expected_playable_refs=178)
    return receipts[0]


def validate():
    source_a = verify_external_sources()
    bindings = read(DOCS / 'failed-stage-bindings.json')
    verify_failure(bindings, source_a)
    package = source_a.validate_package(PACKAGE_PATH, PINS_PATH)
    assert package['archive_sha256'] == PACKAGE_SHA
    archive = Path(package['archive']); archive = archive if archive.is_absolute() else REPO / archive
    stage = archive.resolve().parent / BUILD
    assert execute.digest(stage / 'checksums.txt') == bindings['files'][REMOTE_ROOT + '/checksums.txt']
    assert execute.digest(stage / 'cutover.sh') == bindings['files'][REMOTE_ROOT + '/cutover.sh']
    assert read(DOCS / 'protected-hashes.json')['/opt/quiz-master/releases/' + BUILD + '.tar.gz'] == PACKAGE_SHA
    assert read(DOCS / 'protected-hashes.json')[bindings['failed_backup']['path']] == bindings['failed_backup']['sha256']
    return source_a, package, bindings


def render_guard(bindings, strict_preflight):
    assert bindings['build_id'] == BUILD and bindings['failed_run'] == FAILED_RUN and bindings['candidate_image_id'] == CANDIDATE
    files = bindings['files']
    checks = dict(files)
    checks['/opt/quiz-master/releases/' + BUILD + '.tar.gz'] = PACKAGE_SHA
    checks[bindings['failed_backup']['path']] = bindings['failed_backup']['sha256']
    code = """from pathlib import Path
import json,hashlib,sqlite3,stat,subprocess
"""
    code += 'checks = ' + repr(checks) + '\n'
    code += """for text, expected in checks.items():
 p=Path(text)
 assert p.is_file() and not p.is_symlink() and p.resolve()==p.absolute()
 with p.open('rb') as stream: assert hashlib.file_digest(stream,'sha256').hexdigest()==expected
"""
    code += "backup=Path(" + repr(bindings['failed_backup']['path']) + ")\n"
    code += """assert stat.S_IMODE(backup.stat().st_mode)==0o600
with sqlite3.connect(backup.as_uri()+'?mode=ro',uri=True) as db: assert db.execute('pragma integrity_check').fetchone()==('ok',)
"""
    code += "assert subprocess.check_output(['docker','image','inspect','quiz-master:" + BUILD + "','--format','{{.Id}}'],text=True).strip()==" + repr(CANDIDATE) + '\n'
    code += "from verify_candidate_runtime import verify_runtime_receipt\n"
    code += "runtime=json.loads(Path(" + repr(REMOTE_ROOT+'/'+FAILED_RUN+'-candidate-runtime.json') + ").read_text())\n"
    code += "assert runtime['image_id']=="+repr(CANDIDATE)+'\n'
    code += "verify_runtime_receipt(runtime,'quiz-master:"+BUILD+"',expected_packs=136,expected_questions=4084,expected_articles=299,expected_total_refs=180,expected_playable_refs=178)\n"
    code += "rehearsal=json.loads(Path(" + repr(REMOTE_ROOT+'/'+FAILED_RUN+'-rehearsal.json') + ").read_text())\n"
    code += "assert rehearsal['original_rows_preserved'] is True and rehearsal['old_api_rollback']=='ok' and rehearsal['feedback_lifecycle']=='ok' and (rehearsal['total_graded'],rehearsal['practice_finished'])==(335,15)\n"
    compile(code, 'resume-stage-guard', 'exec')
    return ('set -euo pipefail\nunset PYTHONOPTIMIZE PYTHONSTARTUP\ntest "$(hostname)" = racknerd-f0269d5\nexec 8>/opt/quiz-master/DEPLOY.lock\nflock -n 8\n'
            + strict_preflight + '\ncd ' + REMOTE_ROOT + '\ntest "$(pwd -P)" = ' + REMOTE_ROOT
            + "\npython3 - <<'QUIZ_RESUME_GUARD'\n" + code
            + 'QUIZ_RESUME_GUARD\nsha256sum -c checksums.txt > /dev/null\ntest ! -e /var/lib/rancher/k3s/agent/images/' + BUILD + '.tar\n')


def render_script(bindings, strict_preflight, nonce):
    assert re.fullmatch('[0-9a-f]{32}', nonce)
    guard = render_guard(bindings, strict_preflight)
    log = 'resume-' + nonce + '.log'
    script = guard + 'umask 077\nset -o noclobber\n: > '+log+'\nset +o noclobber\nflock -u 8\nexec 8>&-\nbash cutover.sh prepare 2>&1 | tee '+log+'\n'
    # Preserve all failed-run bytes, including prepare.log, after the fresh run.
    post = 'from pathlib import Path\nimport hashlib\nchecks='+repr(bindings['files'])+'\nfor text,expected in checks.items():\n p=Path(text)\n with p.open("rb") as stream: assert hashlib.file_digest(stream,"sha256").hexdigest()==expected\n'
    return guard, script + "python3 - <<'QUIZ_PRESERVE_FAILED'\n" + post + 'QUIZ_PRESERVE_FAILED\n'


def ssh_capture(body, timeout, label, evidence, old):
    try:
        result = subprocess.run(['ssh','-i',old.SSH_KEY,old.SSH_TARGET,'bash -s'],
                                input=body.encode(),stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=timeout)
    except subprocess.TimeoutExpired as exc:
        partial = exc.stdout or b''
        (evidence/(label+'-log.txt')).write_bytes(partial.encode() if isinstance(partial,str) else partial)
        (evidence/(label+'-exit.json')).write_text(json.dumps({'actual_exit':'timeout'})+'\n')
        raise
    (evidence/(label+'-log.txt')).write_bytes(result.stdout)
    (evidence/(label+'-exit.json')).write_text(json.dumps({'actual_exit':result.returncode})+'\n')
    assert result.returncode==0,label+' failed; retain logs and do not rerun blindly'
    return result.stdout.decode('utf-8',errors='replace')


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--resume',action='store_true');parser.add_argument('--evidence-dir',type=Path)
    args=parser.parse_args()
    source_a,package,bindings=validate()
    guard,script=render_script(bindings,source_a.preflight_shell(),uuid.uuid4().hex)
    if not args.resume:
        print(json.dumps({'status':'LOCAL_PREVIEW_ONLY','build_id':BUILD,'resume_script_sha256':hashlib.sha256(script.encode()).hexdigest(),'failed_run_preserved':FAILED_RUN}));return
    execute.validate_inputs()
    assert args.evidence_dir is not None
    evidence=args.evidence_dir.resolve()
    assert evidence.is_relative_to(REPO/'.run') and not evidence.exists() and not args.evidence_dir.is_symlink()
    evidence.mkdir(parents=True)
    (evidence/'remote-resume-script.sh').write_bytes(script.encode())
    old=source_a.legacy_remote()
    def ssh(body,timeout,label):
        return ssh_capture(body,timeout,label,evidence,old)
    ssh(guard,60,'remote-resume-guard')
    log=ssh(script,600,'remote-resume')
    match=re.search(r'PREPARED build=(\S+) image=(sha256:[a-f0-9]{64}) values=(\S+) mode=prepare',log)
    assert match and match[1]==BUILD
    run=match[3].removesuffix('-values.yaml')
    assert re.fullmatch(re.escape(BUILD)+r'-cutover-\d{8}T\d{6}Z',run) and run!=FAILED_RUN
    durable=re.search(r'([a-f0-9]{64})  '+re.escape('/var/lib/rancher/k3s/agent/images/'+BUILD+'.tar'),log)
    assert durable
    collector=source_a.collection_script(run,match[2],durable[1])
    (evidence/'remote-collect-script.sh').write_bytes(collector.encode())
    proof=json.loads(ssh(collector,60,'remote-collect'))
    proof.update(source_commit=source_a.reader.FROZEN_COMMIT,package_sha256=PACKAGE_SHA,remote_prepare_exit=0,remote_log_sha256=execute.digest(evidence/'remote-resume-log.txt'),resumed_from_failed_run=FAILED_RUN,failed_binding_sha256=execute.digest(DOCS/'failed-stage-bindings.json'),source_review_sha256=execute.digest(DOCS/'source-review.json'),limits=['New preparation only. Original failed-v1 evidence is immutable. Independent execution and publication review remain.'])
    (evidence/'remote-preparation-verification.json').write_text(json.dumps(proof,indent=2)+'\n')
    print(json.dumps({'status':'PREPARED_NOT_PUBLISHED','build_id':BUILD,'image':match[2],'new_run':run,'resumed_from_failed_run':FAILED_RUN}))


if __name__=='__main__': main()
