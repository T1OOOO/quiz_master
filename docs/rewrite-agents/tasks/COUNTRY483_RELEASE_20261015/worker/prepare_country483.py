"""Create and verify a local Country483 archive; never contact a server."""
from __future__ import annotations
import argparse
import ast
import copy
import hashlib
import importlib.util
import json
import re
import shutil
import sys
import tarfile
from pathlib import Path, PurePosixPath

sys.dont_write_bytecode = True
REPO = Path(__file__).resolve().parents[5]
OWN = Path(__file__).resolve().parent
WORK = REPO / '.run/country483_release_20261015/worker'
TASKS = REPO / 'docs/rewrite-agents/tasks'
INPUTS = OWN.parent / 'release-inputs.json'
INPUTS_SHA = 'bfc85e10404b9bf82971c0e406c022c11ae256bf22aff89c24d0d0eb81725cdb'
DEPENDENCIES = {'MIXED_RELEASE_20261014/worker/prepare_lotr_package.py': 'c9e4dc75574232a8f36f6ac1ee3e7a6039c398e721641335c54f4fb07332d0e0',
                'READER303_RELEASE_20261015/release-worker/reader303_guard.py': '877c6c37fcb1c94a5886298813dc7801da22d110e6d928cb9a1dd33795f64bcc'}
BASE_BUILD = 'quiz-2026.10.15-reader303-14b7da4'
BASE_SOURCE = '14b7da43c3e43642d60859f5053ee6d809c2379e'
BASE_ARCHIVE = REPO / f'.run/reader303_release_20261015/package-v2/{BASE_BUILD}.tar.gz'
BASE_ARCHIVE_SHA = '0df5f4496ab163a0cbeefaedce2c62af8d7d8b322b19dd41c4bc16e50cc79a0b'
BASE_CHECKS = '06d3ff4fca6a5b9265164459c25e4abcdc8e4c2cf753c5d1768595d457de1304'
OLD_IMAGE = 'docker.io/library/quiz-master@sha256:e053b4c42c600a062d2dfff5c5152ccc70ff86b2d97b4f91b9784af7c8fc46d4'
IMAGE = 'docker.io/library/quiz-master@sha256:6c603a840b01c9c4605eba234e4af3d95a3f52fff12e65d9904b563db5722f14'
BUILD = 'quiz-2026.10.15-country483-3c22818'
SOURCE = '3c2281815b768271d9110f2d28fa415c0eefe06c'
OLD_JS = '209c5e9f7ff7c2ad1cc9b3aa28b655b4782709ee7a99a2b5a204945e71f23732'
API = 'f4d69555623aab2b8e1468fccb65256abefc9823d65214799b7e1475d4d9c850'
NGINX = 'e9add812a138010e443463acb455295103dc69886ca32cd17dafbccfa676d6bc'
PVC = '7fc2428f-4146-4c78-a26d-2347d9f3b7bf'
FEEDBACK = '452929a2ea8dc34600eff8039571e2b0479ec7ad1ec52fa6e271b5c71008030e'
RUNTIME = TASKS / 'COUNTRY483_RUNTIME_20261015'
ATLAS = 'assets/assets/quizipedia/catalog.json'
MANIFEST = 'assets/assets/quizipedia/manifest.json'
COUNTS = dict(packs=136, questions=4084, reader_articles=303, reader_refs=184, playable_refs=182, noncatalog_refs=2)
LABELS = {'ne-sah': 'Западная Сахара', 'ne-flk': 'Фолклендские острова', 'ne-grl': 'Гренландия',
 'ne-atf': 'Французские Южные и Антарктические территории', 'ne-pri': 'Пуэрто-Рико',
 'ne-ncl': 'Новая Каледония', 'ne-twn': 'Тайвань', 'ne-ata': 'Антарктида',
 'ne-cyn': 'Турецкая Республика Северного Кипра', 'ne-sol': 'Сомалиленд', 'ne-kos': 'Республика Косово'}
PROOFS = tuple('docs/rewrite-agents/tasks/' + p for p in (
 'COUNTRY_LABELS_483_20261015/native-source-review.json', 'COUNTRY_LABELS_483_20261015/integration-review.json',
 'COUNTRY483_RUNTIME_20261015/actual-flutter-builds.json', 'COUNTRY483_RUNTIME_20261015/browser-proof.json',
 'COUNTRY483_RUNTIME_20261015/review-inputs.json', 'COUNTRY483_RUNTIME_20261015/independent-runtime-review.json',
 'COUNTRY483_RUNTIME_20261015/final-checks.json', 'COUNTRY483_RELEASE_20261015/production-baseline.jsonl',
 'COUNTRY483_RELEASE_20261015/baseline-exit.json')) + tuple('next/apps/quiz_app/assets/' + p for p in (
 'quizipedia/catalog.json', 'quizipedia/manifest.json', 'catalog.json', 'study/question-articles.json'))


def require(ok, message):
    if not ok:
        raise RuntimeError(message)


def sha(path):
    with Path(path).open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def read(path):
    return json.loads(Path(path).read_text(encoding='utf8'))


def load_dependency(relative):
    path = TASKS / relative
    require(sha(path) == DEPENDENCIES[relative], 'historical dependency hash changed')
    spec = importlib.util.spec_from_file_location('country483_' + path.stem, path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def house():
    helper = load_dependency('MIXED_RELEASE_20261014/worker/prepare_lotr_package.py')
    helper.BASELINE_BUILD, helper.BASELINE_ARCHIVE_SHA256 = BASE_BUILD, BASE_ARCHIVE_SHA
    helper.BUILD_ID, helper.TARGET_SOURCE, helper.TARGET_API_SHA256 = BUILD, SOURCE, API
    return helper


def preflight_shell():
    guard = load_dependency('READER303_RELEASE_20261015/release-worker/reader303_guard.py').preflight_shell()
    helper = house()
    guard = helper.replace_once(guard, "helm['version']==62", "helm['version']==63")
    return helper.replace_once(guard, OLD_IMAGE, IMAGE)


def verify_acceptance(proof, task, helper):
    helper.require_actual_acceptance(proof, task)
    for callback in proof['actual_reviews'].values():
        call, response = callback.get('call', {}), callback.get('actual_response', {})
        args = call.get('arguments', {})
        if (call.get('action') == 'review' and args.get('task_id') == task and args.get('verdict') == 'accept'
                and args.get('error_count') == 0 and response.get('id') == task and response.get('state') == 'ACCEPTED'
                and response.get('reviewer') and response.get('assignee') and response['reviewer'] != response['assignee']):
            return
    raise RuntimeError('actual task-bound independent acceptance is missing')


def file_tree(root):
    root = Path(root)
    require(root.is_dir() and not root.is_symlink(), 'real tree required')
    result = {}
    for path in root.rglob('*'):
        require(not path.is_symlink(), 'symlink forbidden')
        if path.is_file():
            require(path.stat().st_nlink == 1, 'hardlinked file forbidden')
            result[path.relative_to(root).as_posix()] = sha(path)
    return result


def verify_baseline(rows):
    require(len(rows) == 2, 'two actual baseline records required')
    node, live = rows
    require(node.get('node_ready') is True and node.get('disk_pressure') is False and
            node.get('blocking_taints') is False and node.get('https_readiness_status') == 200 and
            type(node.get('disk_available')) is int and type(node.get('disk_total')) is int and
            node['disk_available'] * 5 > node['disk_total'], 'current baseline readiness or strict20 capacity differs')
    require(live.get('helm_revision') == 63 and live.get('status') == 'deployed' and live.get('images') == [IMAGE, IMAGE]
            and live.get('available_replicas') == 1 and live.get('pvc_uid') == PVC and live.get('feedback_count') == 29
            and live.get('all_open') is True and live.get('feedback_sha256') == FEEDBACK
            and live.get('backup_mode') == '0600' and live.get('backup_integrity') == 'ok', 'current63 baseline differs')


def verify_inputs():
    require(sys.flags.optimize == 0, 'optimized Python would disable inherited guards')
    require(sha(INPUTS) == INPUTS_SHA, 'Root release-inputs changed')
    pins = read(INPUTS)
    require(pins.get('schema_version') == 'qm-country483-release-inputs/v1' and pins.get('source_commit') == SOURCE
            and pins.get('build_id') == BUILD and pins.get('counts') == COUNTS and pins.get('publication_performed') is False,
            'release source/count identity differs')
    expected_baseline = dict(build_id=BASE_BUILD, helm_revision=63, image=IMAGE, pvc_uid=PVC, feedback_count=29, feedback_sha256=FEEDBACK)
    require(pins.get('baseline') == expected_baseline and pins['capacity'].get('remote_peak_certified') is False, 'baseline pins differ')
    proofs = pins['proofs']
    require(set(proofs) == set(PROOFS), 'exact13 proof/source pins required')
    for relative, entry in proofs.items():
        require(set(entry) == {'path', 'sha256'} and Path(entry['path']).resolve() == (REPO / relative).resolve()
                and sha(entry['path']) == entry['sha256'], 'proof/source path or hash differs: ' + relative)
    helper = house()
    for relative, task in (('COUNTRY_LABELS_483_20261015/native-source-review.json', 'task-c01453fa983c45139c63c6764592ac5d'),
                           ('COUNTRY_LABELS_483_20261015/integration-review.json', 'task-bc814406f1ca4b4e8bb7331220799ee6'),
                           ('COUNTRY483_RUNTIME_20261015/independent-runtime-review.json', 'task-96da0af0c5ef4d3da1b5a09e30a0cd8c')):
        verify_acceptance(read(TASKS / relative), task, helper)
    manifest = read(RUNTIME / 'review-inputs.json')
    require(isinstance(manifest, dict) and len(manifest) == 149, 'reviewed runtime manifest cardinality differs')
    for relative, expected in manifest.items():
        path = REPO / relative
        require(path.resolve().is_relative_to(REPO) and not Path(relative).is_absolute() and sha(path) == expected,
                'reviewed runtime evidence changed: ' + relative)
    rows = [json.loads(line) for line in (INPUTS.parent / 'production-baseline.jsonl').read_text().splitlines() if line.strip()]
    verify_baseline(rows)
    require(read(INPUTS.parent / 'baseline-exit.json')['actual_exit'] == 0, 'baseline command did not succeed')
    build, browser = read(RUNTIME / 'actual-flutter-builds.json'), read(RUNTIME / 'browser-proof.json')
    require(build.get('frozen_source') == browser.get('frozen_source') == SOURCE and
            build.get('build_id') == browser.get('build_id') == BUILD, 'actual build/browser provenance differs')
    require(len(build['checks']) == 2 and {x['label'] for x in build['checks']} == {'production', 'qa'}, 'two distinct builds required')
    for row in build['checks']:
        label = row['label']; root = REPO / f'.run/country483_runtime_20261015/{label}-web'
        command = row['command']
        require(command.count('--output') == 1 and Path(command[command.index('--output') + 1]).resolve() ==
                Path(pins['web_roots'][label]).resolve() == root.resolve(), 'actual web root differs')
        require(row.get('actual_exit') == row.get('root_process_exit') == 0 and file_tree(root) == row['file_sha256']
                and len(row['file_sha256']) == 74, 'actual full compiled tree changed')
        log = RUNTIME / row['log']
        require(log.resolve().parent == RUNTIME.resolve() and sha(log) == row['log_sha256'], 'actual build log changed')
        for relative in ('quizipedia/catalog.json', 'quizipedia/manifest.json', 'catalog.json', 'study/question-articles.json'):
            require((root / 'assets/assets' / relative).read_bytes() == (REPO / 'next/apps/quiz_app/assets' / relative).read_bytes(),
                    'compiled source asset changed')
    require(browser.get('actual_build_exits') == [0, 0] and browser.get('runtime_errors') == [] and
            browser.get('browser_close_actual_exit') == browser.get('fixture_wrapper_actual_exit') == 0 and
            browser.get('captured_native_identities_inactive') == 13 and browser.get('no_browser_api_post_or_feedback') is True and
            browser.get('ports_closed') == {'19090': True, '19093': True}, 'actual country browser/cleanup checks missing')
    prior = pins['prior_archive']
    require(Path(prior['path']).resolve() == BASE_ARCHIVE.resolve() and prior['sha256'] == BASE_ARCHIVE_SHA and
            BASE_ARCHIVE.stat().st_size == prior['bytes'] == 60989154, 'prior archive pin differs')
    helper.verify_safe_archive(BASE_ARCHIVE)
    return pins


def verify_label_delta(prior, current):
    expected = copy.deepcopy(prior)
    rows = expected['countries']
    require(len(rows) == 177 and len({x['id'] for x in rows}) == 177, 'baseline177 country identity differs')
    found = set()
    for row in rows:
        if row['id'] in LABELS:
            require(row['name_ru'] == row['name_en'] and row['name_ru'] != LABELS[row['id']], 'old background fallback differs')
            row['name_ru'] = LABELS[row['id']]; found.add(row['id'])
    require(found == set(LABELS) and current == expected, 'only exact11 name_ru changes are permitted')


def patch_controls(cutover, rehearsal, production_hash):
    helper = house()
    # Replacing the entire inherited preflight prevents a stale function definition from overriding63.
    marker = 'quiz_preflight() {\n'; start = cutover.find(marker); end = cutover.find('\n}\n', start)
    require(cutover.count(marker) == 1 and start >= 0 and end > start, 'baseline preflight contract changed')
    cutover = cutover[:start] + marker + preflight_shell() + '\n}\n' + cutover[end + 3:]
    cutover = helper.replace_once(cutover, OLD_IMAGE, IMAGE)
    cutover = helper.replace_once(cutover, BASE_BUILD, BUILD, 2)
    cutover = helper.replace_once(cutover, BASE_SOURCE, SOURCE)
    cutover = helper.replace_once(cutover, OLD_JS, production_hash, 3)
    require('helm upgrade' not in cutover and '[[ "$quiz_mode" = prepare ]]' in cutover and
            cutover.count('\nquiz_preflight\n') == 3 and cutover.count('exit 0\n') == 1, 'prepare-only boundary changed')
    require(all(x in cutover for x in ('backup_sqlite.py', 'rehearse.py', 'verify_candidate_runtime.py', 'helm lint', 'helm template',
                                     '--dry-run=server', 'docker save', 'PREPARED build=')), 'inherited preparation gate missing')
    rehearsal = helper.replace_once(rehearsal, '/opt/quiz-master/releases/quiz-2026.10.15-reader299-9c670e9',
                                   '/opt/quiz-master/releases/' + BASE_BUILD)
    rehearsal = helper.replace_once(rehearsal, '34229f2765d0fffb0ab5fa14be6a7d0d01c9bc11b712531964a1fcf0247c15d8', BASE_CHECKS)
    require("'prep-musicals':5" in rehearsal and 'assert graded==335 and finished==15' in rehearsal and
            "assert len(req('/v1/history',token=token))==15" in rehearsal and API in rehearsal,
            'copied-DB335/15 or rollback gates changed')
    return cutover.encode(), rehearsal.encode()


def verify_preserved(before, stage):
    after = file_tree(stage)
    require(set(after) == set(before), 'stage membership changed')
    allowed = {'cutover.sh', 'rehearse.py', 'expected-staging-revisions.json', 'checksums.txt',
               'web/.last_build_id', 'web/main.dart.js', 'web/version.json', 'web/' + ATLAS, 'web/' + MANIFEST}
    changed = {key for key in before if before[key] != after[key]}
    require(changed <= allowed, 'unrelated content/binary/Reader/schema change: ' + ','.join(sorted(changed - allowed)))
    require(sha(stage / 'api') == API and sha(stage / 'nginx.conf') == NGINX, 'API/Nginx changed')
    return sorted(changed)


def verify_counts(stage):
    catalog = read(stage / 'next/apps/quiz_app/assets/catalog.json')
    articles = read(stage / 'next/apps/quiz_app/assets/study/question-articles.json')['articles']
    refs = [(r['quiz_id'], r['question_id'], r['revision_sha256']) for a in articles for r in a.get('question_refs', [])]
    constants = [node for node in ast.parse((stage / 'verify_candidate_runtime.py').read_text()).body
                 if isinstance(node, ast.Assign) and any(isinstance(t, ast.Name) and t.id == 'NONCATALOG_READER_REFS' for t in node.targets)]
    require(len(constants) == 1, 'immutable runtime noncatalog contract missing')
    noncatalog = ast.literal_eval(constants[0].value)
    known = {(r['quiz_id'], r['question_id'], r['revision_sha256']) for r in noncatalog}
    require(len(catalog) == len({r['quiz_id'] for r in catalog}) == 136 and sum(r['questions_count'] for r in catalog) == 4084,
            'unchanged catalog counts differ')
    require(len(articles) == len({a['id'] for a in articles}) == 303 and len(refs) == len(set(refs)) == 184 and
            len(noncatalog) == len(known) == 2 and known <= set(refs) and len(set(refs) - known) == 182,
            'unchanged Reader counts/references differ')
    return COUNTS.copy()


def validate_output(output):
    output = Path(output)
    require(output.resolve().is_relative_to(WORK) and output.resolve() != WORK.resolve(), 'output escapes worker scratch')
    for ancestor in (output, *output.parents):
        require(not ancestor.is_symlink() and not ancestor.is_junction(), 'linked output path forbidden')
        if ancestor == REPO:
            break
    house().require_new_output_root(output)


def prepare(output):
    pins = verify_inputs()
    validate_output(output)
    output = Path(output); helper = house(); stage = output / BUILD
    helper.extract_immutable(BASE_ARCHIVE, stage)
    helper.verify_checksum_manifest(stage)
    before = file_tree(stage)
    require(before['checksums.txt'] == BASE_CHECKS and len(before) == 332, 'baseline archive checksum/member contract differs')
    prior_atlas = read(stage / 'web' / ATLAS); prior_manifest = read(stage / 'web' / MANIFEST)
    production = Path(pins['web_roots']['production'])
    verify_label_delta(prior_atlas, read(production / ATLAS))
    current_manifest = read(production / MANIFEST)
    expected_manifest = {**prior_manifest, 'generated_catalog_sha256': sha(production / ATLAS)}
    require(current_manifest == expected_manifest, 'atlas manifest unrelated field changed')
    cutover, rehearsal = patch_controls((stage / 'cutover.sh').read_text(), (stage / 'rehearse.py').read_text(), sha(production / 'main.dart.js'))
    # The destination is newly extracted beneath this worker's absent output root.
    helper.copy_compiled_web(stage, production)
    (stage / 'cutover.sh').write_bytes(cutover); (stage / 'rehearse.py').write_bytes(rehearsal)
    helper.inject_version(stage, {'packs':136, 'questions':4084, 'reader_articles':303}, sha(production / 'main.dart.js'))
    revisions, _ = helper.expected_staging_revisions_from_bundles(read(stage / 'runtime-bundles.json'), BUILD)
    helper.write_json_lf(stage / 'expected-staging-revisions.json', revisions)
    verify_preserved(before, stage); verify_counts(stage)
    helper.write_checksums(stage); helper.verify_checksum_manifest(stage)
    delta = verify_preserved(before, stage)
    artifact, digest, members = helper.archive_and_verify(stage, output)
    result = dict(status='PREPARED_NOT_EXECUTED', local_only=True, build_id=BUILD, frozen_commit=SOURCE,
                  release_inputs_sha256=INPUTS_SHA, archive=str(artifact), archive_sha256=digest, file_members=members,
                  counts=COUNTS, changed_paths=delta, unchanged_nonweb_content=True, baseline_helm_revision=63,
                  baseline_image=IMAGE, baseline_checksums_sha256=BASE_CHECKS,
                  controller_source_sha256={p.name:sha(p) for p in OWN.glob('*.py')},
                  dependencies_sha256=DEPENDENCIES, checksums_sha256=sha(stage / 'checksums.txt'),
                  qa_checked_not_packaged=pins['web_roots']['qa'], remote_preparation_performed=False,
                  execution_approval_required=True, remote_peak_certified=False)
    (output / 'package-preparation.json').write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n', encoding='utf8')
    return result


def verify_package(receipt_path):
    """Recheck actual local archive, stage, reviewed inputs and unchanged payload."""
    pins = verify_inputs(); helper = house(); receipt_path = Path(receipt_path)
    require(receipt_path.name == 'package-preparation.json' and receipt_path.resolve().is_relative_to(WORK), 'receipt boundary differs')
    result = read(receipt_path); output = receipt_path.resolve().parent; stage = output / BUILD
    archive = output / (BUILD + '.tar.gz')
    require(result.get('status') == 'PREPARED_NOT_EXECUTED' and result.get('local_only') is True and
            result.get('build_id') == BUILD and result.get('frozen_commit') == SOURCE and
            result.get('release_inputs_sha256') == INPUTS_SHA and result.get('counts') == COUNTS and
            result.get('baseline_helm_revision') == 63 and result.get('baseline_image') == IMAGE and
            result.get('baseline_checksums_sha256') == BASE_CHECKS and result.get('remote_preparation_performed') is False and
            result.get('execution_approval_required') is True and result.get('remote_peak_certified') is False,
            'local receipt identity/claims differ')
    require(result.get('controller_source_sha256') == {p.name:sha(p) for p in OWN.glob('*.py')} and
            result.get('dependencies_sha256') == DEPENDENCIES, 'package controller/dependencies drifted')
    require(Path(result['archive']).resolve() == archive and not archive.is_symlink() and sha(archive) == result['archive_sha256'], 'local archive differs')
    with tarfile.open(BASE_ARCHIVE, 'r:gz') as baseline:
        before = {PurePosixPath(x.name).relative_to(BASE_BUILD).as_posix():hashlib.sha256(baseline.extractfile(x).read()).hexdigest()
                  for x in baseline.getmembers()}
        original = lambda name: baseline.extractfile(BASE_BUILD + '/' + name).read().decode()
        cutover, rehearsal = patch_controls(original('cutover.sh'), original('rehearse.py'), sha(stage / 'web/main.dart.js'))
    require((stage / 'cutover.sh').read_bytes() == cutover and (stage / 'rehearse.py').read_bytes() == rehearsal,
            'local prepare/rehearsal guards drifted')
    delta = verify_preserved(before, stage)
    verify_counts(stage)
    require(result.get('changed_paths') == delta and result.get('checksums_sha256') == sha(stage / 'checksums.txt'), 'local delta/checksum receipt differs')
    helper.verify_checksum_manifest(stage)
    production = file_tree(pins['web_roots']['production']); shipped = file_tree(stage / 'web')
    require({k:v for k,v in production.items() if k != 'version.json'} == {k:v for k,v in shipped.items() if k != 'version.json'},
            'shipped web differs from actual production build')
    meta = read(stage / 'web/version.json')
    require(meta.get('buildId') == BUILD and meta.get('source_commit') == meta.get('commit') == SOURCE and
            meta.get('api_sha256') == API and meta.get('main_dart_js_sha256') == shipped['main.dart.js'] and
            (meta.get('packs'), meta.get('questions'), meta.get('question_articles')) == (136,4084,303), 'shipped metadata differs')
    revisions, _ = helper.expected_staging_revisions_from_bundles(read(stage / 'runtime-bundles.json'), BUILD)
    require(read(stage / 'expected-staging-revisions.json') == revisions, 'runtime staging revisions drifted')
    with tarfile.open(archive, 'r:gz') as tar:
        members = tar.getmembers(); helper.validate_archive_members(members, BUILD)
        actual = {PurePosixPath(x.name).relative_to(BUILD).as_posix():hashlib.sha256(tar.extractfile(x).read()).hexdigest() for x in members}
        require(actual == file_tree(stage) and len(members) == result['file_members'] == 332, 'archive/stage membership or bytes differ')
        require(all(x.mode == (0o755 if x.name == BUILD + '/api' else 0o644) for x in members), 'archive permissions differ')
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument('--output-root', type=Path)
    mode.add_argument('--verify', type=Path)
    args = parser.parse_args()
    print(json.dumps(verify_package(args.verify) if args.verify else prepare(args.output_root), ensure_ascii=False))


if __name__ == '__main__':
    main()
