"""Reuse the house remote preparation flow for the frozen Reader-only release."""
from pathlib import Path, PurePosixPath
import argparse
import hashlib
import importlib.util
import json
import re
import subprocess
import sys
import tarfile
import tempfile
import shutil
import uuid
import prepare_reader638_release as reader
from reader638_guard import preflight_shell

REPO = Path(__file__).parents[5]
LEGACY = REPO / 'docs/rewrite-agents/tasks/MIXED_RELEASE_20261014/worker'
# The existing renderer validates mixed IDs; rename only this fixed render alias.
RENDER_ALIAS = 'quiz-2026.10.14-mixed-09b19cc'


def legacy_remote():
    if str(LEGACY) not in sys.path:
        sys.path.insert(0, str(LEGACY))
    spec = importlib.util.spec_from_file_location('reader_legacy_remote', LEGACY / 'prepare_remote_mixed.py')
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    module.BASELINE_IMAGE = reader.BASELINE_IMAGE
    return module


def replace_once(text, old, new):
    reader.require(text.count(old) == 1, 'house renderer contract changed: ' + old)
    return text.replace(old, new)


def remote_scripts(package, nonce):
    reader.require(package['build_id'] == reader.BUILD_ID, 'fixed Reader build differs')
    guard, script = legacy_remote().remote_scripts({**package, 'build_id': RENDER_ALIAS}, nonce)
    def successor(text):
        text = text.replace(RENDER_ALIAS, reader.BUILD_ID)
        return replace_once(text, 'version==52 and status=="deployed"', 'version==58 and status=="deployed"')
    def guarded(text):
        text=successor(text)
        old='test "$(df --output=avail -B1 /opt/quiz-master | tail -1)" -gt 4000000000'
        return replace_once(text,old,preflight_shell())
    return guarded(guard), guarded(script)


def collection_script(run, image_digest, durable_sha):
    reader.require(re.fullmatch(re.escape(reader.BUILD_ID) + r'-cutover-\d{8}T\d{6}Z', run), 'Reader run identity differs')
    alias_run = run.replace(reader.BUILD_ID, RENDER_ALIAS, 1)
    text = legacy_remote().collection_script(RENDER_ALIAS, alias_run, image_digest, durable_sha)
    text = text.replace(RENDER_ALIAS, reader.BUILD_ID)
    text = replace_once(text, 'x["version"]==52', 'x["version"]==58')
    text = replace_once(text, "'baseline_helm_revision':52", "'baseline_helm_revision':58")
    text=replace_once(text,"free=shutil.disk_usage('/opt/quiz-master').free;assert free>4000000000","import os;usage=os.statvfs('/var/lib/rancher/k3s/agent/containerd');free=usage.f_bavail*usage.f_frsize;assert free*5>=usage.f_blocks*usage.f_frsize")
    return replace_once(text, 'expected_packs=136,expected_questions=4084)',
                        'expected_packs=136,expected_questions=4084,expected_articles=279,expected_total_refs=160,expected_playable_refs=158)')


def verify_stage_web(stage, pins, metadata):
    expected = reader.bound_json(pins, 'web_trees')['trees']['production']['file_sha256']
    actual = reader.file_tree(stage / 'web')
    reader.require({k: v for k, v in actual.items() if k != 'version.json'} ==
                   {k: v for k, v in expected.items() if k != 'version.json'}, 'staged Web payload differs from verified production build')
    receipt = reader.bound_json(pins, 'build_receipt')
    production = next(row for row in receipt['checks'] if row['label'] == 'production')
    reader.require(metadata['main_dart_js_sha256'] == production['main_dart_js_sha256'], 'staged JS differs from actual build receipt')


def validate_package(package_path, pins_path):
    pins, package = reader.read(pins_path), reader.read(package_path)
    helper = reader.house()
    reader.verify_inputs(pins, helper)
    reader.require(package['status'] == 'PREPARED_NOT_EXECUTED' and package['build_id'] == reader.BUILD_ID
                   and package['frozen_commit'] == reader.FROZEN_COMMIT, 'package source identity differs')
    declared = Path(package['archive'])
    archive = (declared if declared.is_absolute() else REPO / declared).resolve()
    stage = archive.parent / reader.BUILD_ID
    reader.require(stage.parent == package_path.resolve().parent and stage.is_relative_to(REPO / '.run')
                   and archive.name == reader.BUILD_ID + '.tar.gz', 'package path boundary differs')
    reader.require(reader.digest(archive) == package['archive_sha256'], 'archive hash differs')
    helper.verify_checksum_manifest(stage)
    baseline = REPO / '.run/library_release_20261014/package-v1' / (reader.BASELINE_BUILD + '.tar.gz')
    helper.BASELINE_BUILD = reader.BASELINE_BUILD
    helper.BASELINE_ARCHIVE_SHA256 = reader.BASELINE_ARCHIVE_SHA256
    helper.verify_safe_archive(baseline)
    with tarfile.open(baseline, 'r:gz') as tar:
        before = {PurePosixPath(member.name).relative_to(reader.BASELINE_BUILD).as_posix():
                  hashlib.sha256(tar.extractfile(member).read()).hexdigest() for member in tar.getmembers()}
        baseline_controls = {name: tar.extractfile(reader.BASELINE_BUILD + '/' + name).read()
                             for name in ('cutover.sh', 'rehearse.py', 'checksums.txt')}
    reader.verify_preserved(before, stage)
    reader.verify_staging_revisions(stage, helper)
    with tarfile.open(archive, 'r:gz') as tar:
        members = tar.getmembers()
        helper.validate_archive_members(members, reader.BUILD_ID)
        expected = {reader.BUILD_ID + '/' + p.relative_to(stage).as_posix() for p in stage.rglob('*') if p.is_file()}
        reader.require({m.name for m in members} == expected, 'archive/stage membership differs')
        for member in members:
            relative = Path(*PurePosixPath(member.name).parts[1:])
            payload = tar.extractfile(member)
            reader.require(payload is not None and hashlib.sha256(payload.read()).hexdigest() == reader.digest(stage / relative), 'archive/stage bytes differ')
            if relative.as_posix() == 'api':
                reader.require(member.mode == 0o755, 'API executable mode differs')
    metadata = reader.read(stage / 'web/version.json')
    verify_stage_web(stage, pins, metadata)
    reader.require(metadata['buildId'] == reader.BUILD_ID and metadata['commit'] == metadata['source_commit'] == reader.FROZEN_COMMIT
                   and (metadata['packs'], metadata['questions'], metadata['question_articles']) == (136, 4084, 279), 'release metadata differs')
    reader.require(reader.digest(stage / 'api') == metadata['api_sha256'] == reader.API_SHA256
                   and reader.digest(stage / 'nginx.conf') == reader.NGINX_SHA256
                   and reader.digest(stage / 'web/main.dart.js') == metadata['main_dart_js_sha256'], 'release components differ')
    for source in (reader.READER_SOURCE, reader.CATALOG_SOURCE):
        payload = helper.git_bytes(REPO, reader.FROZEN_COMMIT, source)
        reader.require((stage / source).read_bytes() == (stage / 'web/assets/assets' / source.split('assets/', 1)[1]).read_bytes() == payload, 'shipped frozen assets differ')
    reader.require(reader.digest(stage / 'verify_candidate_runtime.py') == reader.digest(reader.runtime_verifier_path()), 'shipped runtime verifier differs')
    helper.BUILD_ID = reader.BUILD_ID
    helper.TARGET_SOURCE = reader.FROZEN_COMMIT
    helper.TARGET_API_SHA256 = reader.API_SHA256
    with tempfile.TemporaryDirectory() as directory:
        scratch = Path(directory)
        (scratch / 'api').touch()
        (scratch / 'web').mkdir()
        shutil.copyfile(stage / 'web/main.dart.js', scratch / 'web/main.dart.js')
        for name, payload in baseline_controls.items():
            (scratch / name).write_bytes(payload)
        reader.install_runtime_verifier(scratch, helper, metadata['main_dart_js_sha256'])
        reader.require(all((scratch / name).read_bytes() == (stage / name).read_bytes()
                           for name in ('cutover.sh', 'rehearse.py')), 'prepared control scripts differ from reviewed producer')
    shell = (stage / 'cutover.sh').read_bytes()
    reader.require(b'\r' not in shell and b'[[ "$quiz_mode" = prepare ]]' in shell
                   and b'helm upgrade' not in shell, 'Linux prepare-only shell boundary differs')
    changed = subprocess.check_output(['git', '-C', str(REPO), 'diff', '--name-only', reader.FROZEN_COMMIT,
                                       '--', 'next', 'quizzes', 'metadata', 'study/question_articles'], text=True)
    reader.require(not changed.strip(), 'runtime source changed after frozen source')
    return package


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--pins', type=Path, required=True)
    parser.add_argument('--package', type=Path, required=True)
    parser.add_argument('--helper-review', type=Path)
    parser.add_argument('--evidence-dir', type=Path)
    parser.add_argument('--prepare', action='store_true')
    args = parser.parse_args()
    package = validate_package(args.package, args.pins)
    nonce = uuid.uuid4().hex
    guard, script = remote_scripts(package, nonce)
    if not args.prepare:
        print(json.dumps({'status': 'LOCAL_PREVIEW_ONLY', 'build_id': reader.BUILD_ID, 'archive_sha256': package['archive_sha256'],
                          'remote_script_sha256': hashlib.sha256(script.encode('utf8')).hexdigest()}))
        return
    old = legacy_remote()
    sources = [Path(__file__), Path(__file__).with_name('test_prepare_reader638_remote.py'), LEGACY / 'prepare_remote_mixed.py', Path(__file__).with_name('reader638_guard.py')]
    hashes = {str(path.resolve()): reader.digest(path) for path in sources}
    reader.require(args.helper_review is not None and args.evidence_dir is not None, 'prepare requires review and fresh evidence directory')
    old.verify_helper_review(reader.read(args.helper_review), hashes)
    evidence = args.evidence_dir.resolve()
    reader.require(evidence.is_relative_to(REPO / '.run') and not evidence.exists(), 'fresh owned evidence directory required')
    evidence.mkdir(parents=True)
    (evidence / 'remote-prepare-script.sh').write_bytes(script.encode('utf8'))
    def ssh(body, timeout, label):
        result = subprocess.run(['ssh', '-i', old.SSH_KEY, old.SSH_TARGET, 'bash -s'], input=body.encode('utf8'),
                                stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=timeout)
        (evidence / (label + '-log.txt')).write_bytes(result.stdout)
        (evidence / (label + '-exit.json')).write_bytes((json.dumps({'actual_exit': result.returncode}) + '\n').encode('utf8'))
        reader.require(result.returncode == 0, label + ' failed; retain exact owned logs for inspection')
        return result.stdout.decode('utf8', errors='replace')
    ssh(guard, 40, 'remote-guard')
    upload = '/opt/quiz-master/releases/' + reader.BUILD_ID + '.tar.gz.upload-' + nonce
    subprocess.run(['scp', '-i', old.SSH_KEY, str(Path(package['archive']).resolve()), old.SSH_TARGET + ':' + upload], check=True, timeout=120)
    log = ssh(script, 600, 'remote-prepare')
    match = re.search(r'PREPARED build=(\S+) image=(sha256:[a-f0-9]{64}) values=(\S+) mode=prepare', log)
    reader.require(match is not None and match[1] == reader.BUILD_ID, 'actual prepare marker differs')
    run = match[3].removesuffix('-values.yaml')
    durable_path = '/var/lib/rancher/k3s/agent/images/' + reader.BUILD_ID + '.tar'
    durable = re.search(r'([a-f0-9]{64})  ' + re.escape(durable_path), log)
    reader.require(durable is not None, 'durable image hash missing')
    collector = collection_script(run, match[2], durable[1])
    (evidence / 'remote-collect-script.sh').write_bytes(collector.encode('utf8'))
    proof = json.loads(ssh(collector, 60, 'remote-collect'))
    proof.update(source_commit=reader.FROZEN_COMMIT, package_sha256=package['archive_sha256'], remote_prepare_exit=0,
                 remote_log_sha256=reader.digest(evidence / 'remote-prepare-log.txt'),
                 helper_source_sha256=hashes, helper_review_sha256=reader.digest(args.helper_review),
                 limits=['Preparation only; actual independent execution review and publication checks remain.'])
    (evidence / 'remote-preparation-verification.json').write_bytes((json.dumps(proof, indent=2) + '\n').encode('utf8'))
    print(json.dumps({'status': 'PREPARED_NOT_PUBLISHED', 'build_id': reader.BUILD_ID, 'image': match[2]}))


if __name__ == '__main__':
    main()
