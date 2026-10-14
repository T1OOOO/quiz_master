"""Prepare a reviewed mixed release remotely; default is local preview only."""
from __future__ import annotations
import argparse
import hashlib
import json
from pathlib import Path, PurePosixPath
import re
import subprocess
import tarfile
import uuid
import prepare_lotr_package as p
import verify_candidate_runtime as v

BASELINE_IMAGE = 'docker.io/library/quiz-master@sha256:a97cf777b2015c595fd1307017246a2806cce597e0233da75e496a433761e074'
PVC_UID = '7fc2428f-4146-4c78-a26d-2347d9f3b7bf'
SSH_KEY = 'C:/Users/Alexey_Matvienko/.ssh/ll_deploy_ed25519'
SSH_TARGET = 'root@192.3.164.184'
HELPER_FILES = {'prepare_remote_mixed.py', 'test_prepare_remote_mixed.py'}


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def verify_helper_review(review, hashes):
    require(review.get('schema_version') == 'qm-mixed-remote-helper-review/v1' and review.get('actual_cli_exit') == 0 and review.get('actual_hub_state') == 'ACCEPTED', 'helper review actual outcome is missing')
    author, reviewer = str(review.get('author_provider', '')).lower(), str(review.get('reviewer_provider', '')).lower()
    require(author in ('openai', 'codex') and reviewer in ('claude', 'anthropic', 'antigravity') and review.get('reviewed_worker_sha256') == hashes, 'helper review provider/source hashes differ')
    for callback in review.get('actual_reviews', {}).values():
        call, response = callback.get('call', {}), callback.get('actual_response', {})
        arguments = call.get('arguments', {})
        if (call.get('action') == 'review' and arguments.get('verdict') == 'accept' and response.get('state') == 'ACCEPTED'
                and response.get('id') == arguments.get('task_id') and response.get('reviewer') and response.get('assignee') and response['reviewer'] != response['assignee']):
            return
    raise RuntimeError('helper review successful independent callback is missing')


def validate_package(package_path, pins_path):
    pins = p.load_release_pins(pins_path)
    package = p.read_json(package_path)
    repo = Path(pins['repo']).resolve()
    require(repo == Path('C:/ap/quiz_master').resolve(), 'actual repository identity differs')
    require(package.get('status') == 'PREPARED_NOT_EXECUTED' and package.get('build_id') == p.BUILD_ID and package.get('frozen_commit') == p.TARGET_SOURCE and package.get('release_pins_sha256') == p.sha256_file(pins_path), 'package identity/pins differ')
    meta = package.get('metadata', {})
    require(meta.get('buildId') == p.BUILD_ID and meta.get('commit') == meta.get('source_commit') == p.TARGET_SOURCE and {key: meta.get(key) for key in ('packs', 'questions', 'question_articles')} == {'packs': 136, 'questions': 4084, 'question_articles': 266}, 'package metadata identity/counts differ')
    baseline = package.get('baseline_input', {})
    require(baseline.get('archive_sha256') == p.BASELINE_ARCHIVE_SHA256 and baseline.get('image') == BASELINE_IMAGE and baseline.get('pvc_uid') == PVC_UID, 'package baseline identity differs')
    stage, archive = Path(package['stage']).resolve(), Path(package['archive']).resolve()
    require(stage.name == p.BUILD_ID and stage.parent == package_path.resolve().parent and stage.is_relative_to(repo / '.run') and archive == stage.parent / (p.BUILD_ID + '.tar.gz'), 'local stage/archive boundaries differ')
    require(p.sha256_file(archive) == package.get('archive_sha256') and p.sha256_file(stage / 'checksums.txt') == package.get('manifest_sha256'), 'package archive/checksums identity differs')
    p.verify_checksum_manifest(stage)
    with tarfile.open(archive, 'r:gz') as tar:
        members = tar.getmembers()
        p.validate_archive_members(members, p.BUILD_ID)
        actual = {f'{p.BUILD_ID}/' + file.relative_to(stage).as_posix() for file in stage.rglob('*') if file.is_file()}
        require({member.name for member in members} == actual, 'archive/stage membership differs')
        for member in members:
            relative = Path(*PurePosixPath(member.name).parts[1:])
            source = tar.extractfile(member)
            require(source is not None and hashlib.sha256(source.read()).hexdigest() == p.sha256_file(stage / relative), 'archive/stage bytes differ')
            if relative.as_posix() == 'api':
                require(member.mode == 0o755, 'archive API executable mode differs')
    p.verify_commit(repo, p.TARGET_SOURCE)
    p.verify_api_source(repo, p.TARGET_SOURCE)
    frozen = p.frozen_source_bytes(repo, pins)
    prod_sha, _ = p.verify_build_evidence(pins, frozen)
    p.verify_target_api(pins)
    p.verify_browser_receipt(p.read_json(Path(pins['browser_proof']['path'])))
    require(meta.get('api_sha256') == p.TARGET_API_SHA256 and p.sha256_file(stage / 'api') == p.TARGET_API_SHA256 and p.sha256_file(stage / 'nginx.conf') == p.NGINX_SHA256 and p.sha256_file(stage / 'web/main.dart.js') == prod_sha == meta.get('main_dart_js_sha256'), 'staged component hashes differ')
    for relative, name in (('next/apps/quiz_app/assets/catalog.json', 'web/assets/assets/catalog.json'), ('next/apps/quiz_app/assets/study/question-articles.json', 'web/assets/assets/study/question-articles.json')):
        require((stage / name).read_bytes() == frozen[relative], 'staged compiled assets differ')
    require((stage / 'runtime-public-baseline.json').read_bytes() == Path(pins['public_baseline']['path']).read_bytes() and p.sha256_file(stage / 'verify_candidate_runtime.py') == p.sha256_file(Path(__file__).parent / 'verify_candidate_runtime.py'), 'staged runtime gate inputs differ')
    for revisions in ((p.TARGET_SOURCE, 'HEAD'), (p.TARGET_SOURCE,)):
        changed = subprocess.check_output(['git', '-C', str(repo), 'diff', '--name-only', *revisions, '--', 'next', 'quizzes', 'metadata', 'study/question_articles'], text=True)
        require(not changed.strip(), 'runtime source changed after frozen source')
    require((stage / 'cutover.sh').read_text(encoding='utf-8').count('[[ "$quiz_mode" = prepare ]]') == 1 and 'helm upgrade' not in (stage / 'cutover.sh').read_text(encoding='utf-8'), 'staged cutover must remain prepare only')
    return package, stage


def remote_scripts(package, nonce='0' * 32):
    build, digest = package.get('build_id'), package.get('archive_sha256')
    require(isinstance(build, str) and re.fullmatch(r'quiz-2026\.10\.14-mixed-[0-9a-f]{7}', build) and isinstance(digest, str) and re.fullmatch(r'[0-9a-f]{64}', digest) and re.fullmatch(r'[0-9a-f]{32}', nonce), 'remote build/archive identity differs')
    root = '/opt/quiz-master/releases'
    final_archive = f'{root}/{build}.tar.gz'
    upload = final_archive + '.upload-' + nonce
    guard = f'''set -euo pipefail
test "$(hostname)" = racknerd-f0269d5
test "$(readlink -f {root})" = {root}
test "$(kubectl get deploy quiz-master -n quiz-master -o jsonpath='{{.spec.template.spec.containers[0].image}}')" = {BASELINE_IMAGE}
test "$(kubectl get pvc quiz-data -n quiz-master -o jsonpath='{{.metadata.uid}}')" = {PVC_UID}
helm status quiz-master -n quiz-master -o json | python3 -c 'import json,sys; x=json.load(sys.stdin); version=x["version"];status=x["info"]["status"];assert version==52 and status=="deployed"'
test "$(df --output=avail -B1 /opt/quiz-master | tail -1)" -gt 4000000000
test ! -e {root}/{build}
test ! -e {final_archive}
'''
    script = 'set -euo pipefail\ntest "$(hostname)" = racknerd-f0269d5\nexec 8>/opt/quiz-master/DEPLOY.lock\nflock -n 8\n' + guard.removeprefix('set -euo pipefail\n')
    script += f'''echo '{digest}  {upload}' | sha256sum -c -
test ! -L {upload}
mv -- {upload} {final_archive}
mkdir {root}/{build}
test "$(readlink -f {root}/{build})" = {root}/{build}
tar -xzf {final_archive} --no-same-owner --strip-components=1 -C {root}/{build}
cd {root}/{build}
sha256sum -c checksums.txt > candidate-checksums.log
test -f runtime-public-baseline.json
bash -n cutover.sh
python3 -c 'from pathlib import Path; compile(Path("rehearse.py").read_text(),"rehearse.py","exec"); compile(Path("verify_candidate_runtime.py").read_text(),"verify_candidate_runtime.py","exec")'
flock -u 8
exec 8>&-
bash cutover.sh prepare 2>&1 | tee prepare.log
'''
    require('helm upgrade' not in script and 'kubectl apply -n' not in script, 'remote script must stay prepare only')
    return guard + f'test ! -e {upload}\n', script


def collection_script(build, run, image_digest, durable_sha):
    require(re.fullmatch(r'quiz-2026\.10\.14-mixed-[0-9a-f]{7}', build) and re.fullmatch(re.escape(build) + r'-cutover-\d{8}T\d{6}Z', run) and re.fullmatch(r'sha256:[0-9a-f]{64}', image_digest) and re.fullmatch(r'[0-9a-f]{64}', durable_sha), 'execution identity differs')
    return f'''set -euo pipefail
test "$(hostname)" = racknerd-f0269d5
test "$(kubectl get deploy quiz-master -n quiz-master -o jsonpath='{{.spec.template.spec.containers[0].image}}')" = {BASELINE_IMAGE}
test "$(kubectl get pvc quiz-data -n quiz-master -o jsonpath='{{.metadata.uid}}')" = {PVC_UID}
helm status quiz-master -n quiz-master -o json | python3 -c 'import json,sys;x=json.load(sys.stdin);assert x["version"]==52 and x["info"]["status"]=="deployed"'
cd /opt/quiz-master/releases/{build}
python3 - <<'PY'
import pathlib,json,hashlib,sqlite3,stat,shutil
from verify_candidate_runtime import verify_runtime_receipt
root=pathlib.Path.cwd();run='{run}'
def h(path):return hashlib.sha256(path.read_bytes()).hexdigest()
backup=pathlib.Path('/opt/quiz-master/backups')/(run+'.sqlite')
with sqlite3.connect(backup.as_uri()+'?mode=ro',uri=True) as db:assert db.execute('pragma integrity_check').fetchone()==('ok',)
assert stat.S_IMODE(backup.stat().st_mode)==0o600
rehearsal=root/(run+'-rehearsal.json');a=json.loads(rehearsal.read_text())
assert a['migration']=='ok' and a['original_rows_preserved'] is True and a['integrity']=='ok' and a['feedback_lifecycle']=='ok' and a['old_api_rollback']=='ok'
assert a['post_migration_counts'][3]-a['original_counts'][3]==136
assert (a['canonical_packs'],a['canonical_questions'],a['newyear_questions'],a['total_graded'],a['practice_finished'])==(14,280,55,335,15)
with sqlite3.connect((root/('rehearsal-'+run)/'quiz.sqlite').as_uri()+'?mode=ro',uri=True) as db:
 practice=db.execute('select count(*),sum(server_score) from attempts where participant_id in (select id from participants where display_name="Release rehearsal") and status="finished"').fetchone()
assert practice==(15,335)
runtime=root/(run+'-candidate-runtime.json');gate=json.loads(runtime.read_text())
verify_runtime_receipt(gate,'quiz-master:{build}',expected_packs=136,expected_questions=4084)
durable=pathlib.Path('/var/lib/rancher/k3s/agent/images/{build}.tar');assert h(durable)=='{durable_sha}'
values=root/(run+'-values.yaml');rendered=root/(run+'-rendered.yaml')
assert values.is_file() and rendered.is_file() and rendered.read_text().count('docker.io/library/quiz-master@{image_digest}')==2
free=shutil.disk_usage('/opt/quiz-master').free;assert free>4000000000
print(json.dumps({{'build_id':'{build}','image':'{image_digest}','values':values.name,'values_sha256':h(values),'backup_path':str(backup),'backup_sha256':h(backup),'backup_mode':'0600','backup_integrity':'ok','copied_db_rehearsal':a,'copied_db_rehearsal_sha256':h(rehearsal),'candidate_runtime':gate,'candidate_runtime_sha256':h(runtime),'helm_dryrun_sha256':h(rendered),'durable_archive':str(durable),'durable_archive_sha256':h(durable),'disk_free_bytes':free,'baseline_helm_revision':52,'status':'PREPARED_NOT_PUBLISHED'}}))
PY
'''


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--pins', type=Path, required=True)
    parser.add_argument('--package', type=Path, required=True)
    parser.add_argument('--helper-review', type=Path)
    parser.add_argument('--evidence-dir', type=Path)
    parser.add_argument('--prepare', action='store_true')
    args = parser.parse_args()
    package, _ = validate_package(args.package, args.pins)
    nonce = uuid.uuid4().hex
    guard, script = remote_scripts(package, nonce)
    if not args.prepare:
        print(json.dumps({'status': 'LOCAL_PREVIEW_ONLY', 'ssh_target': SSH_TARGET, 'build_id': package['build_id'], 'archive_sha256': package['archive_sha256'], 'remote_script_sha256': hashlib.sha256(script.encode()).hexdigest()}))
        return
    require(args.helper_review is not None and args.evidence_dir is not None, 'prepare requires exact helper review and new evidence directory')
    hashes = {name: p.sha256_file(Path(__file__).parent / name) for name in HELPER_FILES}
    verify_helper_review(p.read_json(args.helper_review), hashes)
    evidence = args.evidence_dir.resolve()
    require(evidence.is_relative_to(Path('C:/ap/quiz_master/.run').resolve()) and not evidence.exists(), 'evidence directory must be new inside actual repository .run')
    evidence.mkdir(parents=True)
    (evidence / 'remote-prepare-script.sh').write_bytes(script.encode())
    def ssh(body, timeout):
        return subprocess.run(['ssh', '-i', SSH_KEY, SSH_TARGET, 'bash -s'], input=body.encode(), stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=timeout)
    result = ssh(guard, 40)
    (evidence / 'remote-guard-log.txt').write_bytes(result.stdout)
    p.write_json_lf(evidence / 'remote-guard-exit.json', {'actual_exit': result.returncode})
    require(result.returncode == 0, 'remote preparation identity guard failed')
    upload = f'/opt/quiz-master/releases/{package["build_id"]}.tar.gz.upload-{nonce}'
    subprocess.run(['scp', '-i', SSH_KEY, package['archive'], SSH_TARGET + ':' + upload], check=True, timeout=120)
    result = ssh(script, 600)
    (evidence / 'remote-prepare-log.txt').write_bytes(result.stdout)
    p.write_json_lf(evidence / 'remote-prepare-exit.json', {'actual_exit': result.returncode})
    require(result.returncode == 0, 'remote preparation failed; retain exact stage/logs for inspection')
    log = result.stdout.decode('utf-8', 'replace')
    match = re.search(r'PREPARED build=(\S+) image=(sha256:[a-f0-9]{64}) values=(\S+) mode=prepare', log)
    require(match is not None and match[1] == package['build_id'], 'actual prepare identity marker missing')
    run = match[3].removesuffix('-values.yaml')
    durable_path = '/var/lib/rancher/k3s/agent/images/' + package['build_id'] + '.tar'
    durable = re.search(r'([a-f0-9]{64})  ' + re.escape(durable_path), log)
    require(durable is not None, 'actual durable image archive hash missing')
    collector = collection_script(package['build_id'], run, match[2], durable[1])
    (evidence / 'remote-collect-script.sh').write_bytes(collector.encode())
    result = ssh(collector, 60)
    (evidence / 'remote-collect-log.txt').write_bytes(result.stdout)
    p.write_json_lf(evidence / 'remote-collect-exit.json', {'actual_exit': result.returncode})
    require(result.returncode == 0, 'remote evidence collection failed')
    proof = json.loads(result.stdout)
    proof.update(source_commit=package['frozen_commit'], package_sha256=package['archive_sha256'], remote_prepare_exit=0, remote_log_sha256=p.sha256_file(evidence / 'remote-prepare-log.txt'), helper_source_sha256=hashes, helper_review_sha256=p.sha256_file(args.helper_review), limits=['Preparation only; independent execution acceptance/publication/public verification remain separate.'])
    p.write_json_lf(evidence / 'remote-preparation-verification.json', proof)
    print(json.dumps({'status': 'PREPARED_NOT_PUBLISHED', 'evidence': str(evidence), 'build_id': package['build_id'], 'image': match[2]}))


if __name__ == '__main__':
    main()
