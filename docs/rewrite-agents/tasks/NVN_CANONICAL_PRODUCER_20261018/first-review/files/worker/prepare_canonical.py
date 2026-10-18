"""Fixed canonical NVN producer. Actual source AND fresh current-input review are mandatory."""
from pathlib import Path
import argparse
import ast
import copy
import datetime as dt
import hashlib
import importlib.util
import json
import sys

sys.dont_write_bytecode = True
OWN = Path(__file__).resolve().parent
ROOT = OWN.parent
REPO = OWN.parents[4]
WORK = REPO / '.run/heartbeat_20261018_0327/worker'
HISTORY = REPO / 'docs/rewrite-agents/tasks/NVN_CANONICAL_EVIDENCE_20261018'
CONTRACT_SHA = '233f181dcbd30c839e539b3b57c1e195a10b7fc5930ae233eb9960c6d87b8223'
HISTORY_SOURCE_SHA = '9f6606f73bc5870704333d0eda0b91401221f8bc2a9e3ded97893ec52ea84b24'
COLLECTOR_SHA = 'abe99d84c37f48206d814967b3993bed14e4fde0f48315b4be52833dd97c6afd'


def require(ok, message):
    if not ok:
        raise ValueError(message)


def regular(path):
    path = Path(path)
    require(path.is_absolute() and path.is_relative_to(REPO) and '..' not in path.parts
            and all(not p.is_symlink() and not p.is_junction() for p in (path, *path.parents))
            and path == path.resolve() and path.is_file() and path.stat().st_nlink == 1,
            'raw canonical single-link file required')
    return path


def sha(path):
    with regular(path).open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def read(path):
    return json.loads(regular(path).read_bytes())


def sources():
    return {path.name: sha(path) for path in sorted(OWN.glob('*.py'))}


def bind(entry, expected):
    require(set(entry) == {'path', 'raw_byte_sha256'} and Path(entry['path']) == expected,
            'exact current evidence binding required')
    require(sha(entry['path']) == entry['raw_byte_sha256'], 'current evidence raw hash differs')
    return expected


def load_history():
    contract = read(OWN / 'current-contract.json')
    require(sha(OWN / 'current-contract.json') == CONTRACT_SHA, 'fixed contract differs')
    require(sha(ROOT / 'CONTRACT_EN.md') == contract['root_contract_raw_sha256'], 'Root scope contract differs')
    path = HISTORY / 'worker/verify_historical.py'
    require(sha(path) == HISTORY_SOURCE_SHA == contract['historical_verifier_raw_sha256'], 'historical verifier differs')
    spec = importlib.util.spec_from_file_location('accepted_canonical_history', path)
    h = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(h)
    require(sha(HISTORY / 'review-inputs.json') == contract['historical_review_inputs_raw_sha256'], 'historical review map differs')
    for relative, digest in read(HISTORY / 'review-inputs.json')['files_raw_sha256'].items():
        h.checked_file(HISTORY / relative, digest)
    require(sha(HISTORY / 'actual-review-callbacks.json') == contract['historical_acceptance_raw_sha256'], 'historical acceptance differs')
    callbacks = read(HISTORY / 'actual-review-callbacks.json')
    require(any(not row['is_error'] and json.loads(row['result']).get('state') == 'ACCEPTED'
                and json.loads(row['result']).get('id') == 'task-d6fc7bef25a04407b57330354e7c464e'
                for row in callbacks), 'accepted historical task required')
    h.verify()
    n, base, original, runtime = h.adapted()
    equivalent_metadata(h, n, original)
    provenance = dict(direct_pins=len(original['proofs']), runtime_files=len(runtime),
                      compiled_files=sum(len(read(n.RUNTIME / (label + '-build-artifacts.json'))['files'])
                                         for label in ('production', 'qa')),
                      historical_feedback_count=original['baseline']['feedback_count'])
    return h, n, base, contract, provenance


def equivalent_metadata(h, n, original):
    expected = copy.deepcopy(read(h.OLD / 'runtime-proof.json'))

    def rebind(value):
        if isinstance(value, dict):
            if set(value) == {'path', 'sha256'}:
                # This lexical prefix belongs only to the digest-pinned historical record, never an incoming path.
                relative = Path(value['path']).relative_to(Path('C:/ap/quiz_master'))
                path = h.destination(REPO / relative)
                value.update(path=str(path), sha256=sha(path))
            else:
                for child in value.values():
                    rebind(child)
        elif isinstance(value, list):
            for child in value:
                rebind(child)

    rebind(expected)
    expected['sha256_semantics'] = 'raw file bytes in all new path/hash bindings'
    for label in ('production', 'qa'):
        expected['builds'][label]['root'] = str(REPO / f'.run/nvn_footer_20261016/{label}-web')
    require(read(h.EVIDENCE / 'runtime-proof.json') == expected, 'historical runtime metadata structural drift')
    expected = copy.deepcopy(original)
    expected['sha256_semantics'] = 'raw file bytes in all new path/hash bindings'
    for relative, entry in expected['proofs'].items():
        path = h.destination(REPO / relative)
        entry.update(path=str(path), sha256=sha(path))
    expected['web_roots'] = {label: str(REPO / f'.run/nvn_footer_20261016/{label}-web') for label in ('production', 'qa')}
    expected['prior_archive']['path'] = str(n.BASE_ARCHIVE)
    require(read(h.EVIDENCE / 'release-inputs.json') == expected, 'historical input metadata structural drift')


def acceptance(path, task, expected_bindings, base):
    require(path.is_file(), 'source acceptance missing' if path.name == 'source-acceptance.json' else 'current-input acceptance missing')
    proof = read(path)
    require(type(proof.get('actual_cli_exit')) is int and proof['actual_cli_exit'] == 0
            and proof.get('reviewer_provider') in ('claude', 'antigravity')
            and proof.get('bound_raw_sha256') == expected_bindings, 'exact independent acceptance bindings required')
    require(any(type(row.get('call', {}).get('arguments', {}).get('error_count')) is int
                and row['call']['arguments']['error_count'] == 0
                and row['call']['arguments'].get('task_id') == task for row in proof.get('actual_reviews', {}).values()),
            'integer zero task-bound review required')
    base.verify_acceptance(proof, task, base.house())


def utc(value):
    stamp = dt.datetime.fromisoformat(value)
    require(stamp.tzinfo is not None and stamp.utcoffset() == dt.timedelta(0), 'UTC capture required')
    return stamp


def current_inputs(h, n, base, contract, source_bindings, now=None):
    manifest_path = ROOT / 'current-inputs.json'
    certificate_path = ROOT / 'current-certificate.json'
    require(manifest_path.is_file() and certificate_path.is_file(), 'current baseline certificate missing')
    manifest = read(manifest_path)
    require(set(manifest) == {'schema_version', 'source_commit', 'build_id', 'historical_inputs_raw_sha256', 'collector', 'stdout', 'receipt'}
            and manifest['schema_version'] == contract['current_manifest_schema']
            and manifest['source_commit'] == n.SOURCE and manifest['build_id'] == n.BUILD
            and manifest['historical_inputs_raw_sha256'] == h.INPUT_SHA, 'current manifest contract differs')
    paths = {'collector': OWN / 'current-baseline-readonly.sh', 'stdout': ROOT / 'current-baseline.jsonl',
             'receipt': ROOT / 'current-baseline-exit.json'}
    for name, path in paths.items():
        bind(manifest[name], path)
    require(sha(paths['collector']) == contract['collector_raw_sha256'] == COLLECTOR_SHA, 'reviewed read-only collector differs')
    digests = {name: sha(path) for name, path in paths.items()}
    receipt = read(paths['receipt'])
    certificate = read(certificate_path)
    require(type(receipt.get('actual_exit')) is int and receipt['actual_exit'] == 0 and receipt.get('read_only') is True
            and receipt.get('script_raw_sha256') == digests['collector'] and receipt.get('stdout_raw_sha256') == digests['stdout'],
            'actual read-only collector exit/raw receipt required')
    require(certificate.get('schema_version') == 'qm-nvn-canonical-current-certificate/v1'
            and certificate.get('release_baseline_certificate') is True
            and type(certificate.get('actual_exit')) is int and certificate['actual_exit'] == 0
            and certificate.get('read_only') is True and certificate.get('manifest_raw_sha256') == sha(manifest_path)
            and certificate.get('bindings_raw_sha256') == digests, 'authoritative current certificate binding required')
    rows = [json.loads(line) for line in regular(paths['stdout']).read_text().splitlines() if line.strip()]
    require(len(rows) == 2, 'two current node/live records required')
    captured = certificate['observed_at_utc']
    require(receipt.get('observed_at_utc') == captured and all(row.get('observed_at_utc') == captured for row in rows), 'capture timestamp receipts differ')
    age = ((now or dt.datetime.now(dt.timezone.utc)) - utc(captured)).total_seconds()
    require(0 <= age <= contract['max_capture_age_seconds'], 'current capture stale or future')
    require(rows[0].get('target_host') == 'racknerd-f0269d5' and rows[0].get('memory_pressure') is False
            and rows[0].get('pid_pressure') is False, 'current target/node differs')
    source = (h.OLD / 'worker/prepare_nvn.py').read_text()
    node = next(node for node in ast.parse(source).body if isinstance(node, ast.FunctionDef) and node.name == 'verify_baseline')
    text = ast.get_source_segment(source, node)
    text = n.once(text, 'def verify_baseline(', 'def verify_current_baseline(')
    text = n.once(text, "live.get('feedback_count')==29", "live.get('feedback_count')==43")
    text = n.once(text, '452929a2ea8dc34600eff8039571e2b0479ec7ad1ec52fa6e271b5c71008030e', contract['feedback_sha256'])
    namespace = dict(n.__dict__)
    exec(compile(text, str(OWN / 'prepare_canonical.py') + '::current-baseline', 'exec'), namespace)
    namespace['verify_current_baseline'](rows)
    bindings = {**source_bindings, **digests, 'manifest': sha(manifest_path), 'certificate': sha(certificate_path)}
    acceptance(ROOT / 'current-input-acceptance.json', contract['current_input_task'], bindings, base)
    return sha(manifest_path)


def authorize():
    require(sys.flags.optimize == 0, 'normal Python required')
    require((ROOT / 'source-acceptance.json').is_file(), 'source acceptance missing')
    h, n, base, contract, provenance = load_history()
    source_bindings = {'sources': sources(), 'contract': CONTRACT_SHA}
    acceptance(ROOT / 'source-acceptance.json', contract['source_task'], source_bindings, base)
    manifest_sha = current_inputs(h, n, base, contract, source_bindings)
    pins = read(h.EVIDENCE / 'release-inputs.json')
    base.OWN, base.WORK = OWN, WORK
    base.INPUTS, base.INPUTS_SHA = ROOT / 'current-inputs.json', manifest_sha
    base.verify_inputs = lambda: pins
    preflight = base.preflight_shell()
    for old, new in [('len(rows)==29', 'len(rows)==43'), ('fetchone()[0]==29', 'fetchone()[0]==43'),
                     ('452929a2ea8dc34600eff8039571e2b0479ec7ad1ec52fa6e271b5c71008030e', contract['feedback_sha256'])]:
        preflight = n.once(preflight, old, new)
    base.preflight_shell = lambda: preflight
    base.patch_controls = lambda cutover, rehearsal, js: n.controls(cutover, rehearsal, js, base, preflight)
    return n, base, provenance


def output_boundary(path):
    path = Path(path)
    require(path.is_absolute() and path.is_relative_to(WORK) and path != WORK and '..' not in path.parts
            and all(not p.is_symlink() and not p.is_junction() for p in (path, *path.parents))
            and path == path.resolve(), 'raw canonical owned output required')
    return path


def operate(mode, path):
    n, base, _ = authorize()
    if mode == 'prepare':
        return base.prepare(output_boundary(path))
    require(mode == 'verify', 'unknown package operation')
    receipt = regular(path)
    output_boundary(receipt.parent)
    require(receipt.name == 'package-preparation.json', 'fixed package receipt name required')
    record = read(receipt)
    archive = regular(record['archive'])
    require(archive == receipt.parent / (n.BUILD + '.tar.gz'), 'fixed canonical archive path required')
    stage = output_boundary(receipt.parent / n.BUILD)
    for member in stage.rglob('*'):
        require(not member.is_symlink() and not member.is_junction(), 'linked package member forbidden')
    return base.verify_package(receipt)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    modes = parser.add_mutually_exclusive_group(required=True)
    modes.add_argument('--prepare', type=Path)
    modes.add_argument('--verify', type=Path)
    args = parser.parse_args()
    print(json.dumps(operate('prepare' if args.prepare else 'verify', args.prepare or args.verify), indent=2))


if __name__ == '__main__':
    main()
