"""Verify the fixed canonical copy of historical NVN evidence; never prepare a release."""
from pathlib import Path
import ast
import hashlib
import importlib.util
import json
import sys

sys.dont_write_bytecode = True
REPO = Path(__file__).resolve().parents[5]
PACKET = Path(__file__).resolve().parent.parent
EVIDENCE = PACKET / 'evidence'
OLD = REPO / 'docs/rewrite-agents/tasks/NVN_RELEASE_20261016'
OLD_INPUT_SHA = '931b441a658962db1cc799f79280c070131664f58ee3c043c82700c7da738eb9'
OLD_SOURCE_SHA = '3942ba48a8cc18de23c18586490697d98f75a589216c40958c5fa2c43bd701e8'
OLD_TEST_SHA = '66ea3ab8e973f706499a4fc827726b446a3671367b76efd0402e2a39ec1bbd69'
INPUT_SHA = 'ff528319354792eb7521531931ad32918be665692e6154e929a7f47098008918'
MAP_SHA = 'b675c6a606fcf379c5df7d4af630e3e95cc898dbd0c1589fecd11273d22cc313'


def require(ok, message):
    if not ok:
        raise ValueError(message)


def sha(path):
    with Path(path).open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def read(path):
    return json.loads(Path(path).read_bytes())


def checked_file(path, digest):
    path = Path(path)
    require(path.is_absolute() and path == path.resolve() and path.is_relative_to(REPO)
            and all(not p.is_symlink() and not p.is_junction() for p in (path, *path.parents))
            and path.is_file() and path.stat().st_nlink == 1 and sha(path) == digest,
            'canonical file path/hash/identity differs')
    return path


def destination(path):
    """Only the fixed historical release evidence needs copies for inherited ROOT reads."""
    path = Path(path)
    if path.is_relative_to(OLD):
        return EVIDENCE / path.relative_to(OLD)
    return path


def historical():
    require(sys.flags.optimize == 0, 'normal Python required')
    source = checked_file(OLD / 'worker/prepare_nvn.py', OLD_SOURCE_SHA)
    checked_file(OLD / 'worker/test_nvn.py', OLD_TEST_SHA)
    inputs = read(checked_file(OLD / 'release-inputs.json', OLD_INPUT_SHA))
    spec = importlib.util.spec_from_file_location('frozen_nvn_canonical_instance', source)
    n = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(n)
    checked_file(n.LEGACY, n.LEGACY_SHA)
    legacy_tree = ast.parse(n.LEGACY.read_bytes())
    dependencies = [node for node in legacy_tree.body if isinstance(node, ast.Assign)
                    and any(isinstance(t, ast.Name) and t.id == 'DEPENDENCIES' for t in node.targets)]
    require(len(dependencies) == 1, 'pinned dependency map differs')
    for relative, digest in ast.literal_eval(dependencies[0].value).items():
        checked_file(REPO / 'docs/rewrite-agents/tasks' / relative, digest)
    for relative, entry in inputs['proofs'].items():
        n.bound(dict(path=str(REPO / relative), sha256=entry['sha256']), REPO / relative)
    runtime_entry = inputs['proofs']['docs/rewrite-agents/tasks/NVN_RELEASE_20261016/runtime-evidence-inputs.json']
    runtime = read(checked_file(OLD / 'runtime-evidence-inputs.json', runtime_entry['sha256']))
    for relative, digest in runtime.items():
        n.bound(dict(path=str(REPO / relative), sha256=digest), REPO / relative)
    return n, inputs, runtime


def member_read(n, path, manifest):
    path = Path(path)
    relative = path.relative_to(REPO).as_posix()
    require(relative in manifest, 'lifecycle file missing from complete runtime manifest')
    return n.read(n.bound(dict(path=str(path), sha256=manifest[relative]), path, manifest))


def validate_manifest(manifest, original_runtime):
    expected = {destination(REPO / key).relative_to(REPO).as_posix(): value
                for key, value in original_runtime.items()}
    require(manifest == expected, 'exact historical runtime closure differs')


def validate_mapping(mapping, original, runtime):
    require(mapping['historical_input_raw_sha256'] == OLD_INPUT_SHA
            and mapping['scope'] == 'historical evidence only; no release acceptance', 'migration provenance differs')
    expected = {str(REPO / relative): entry['sha256'] for relative, entry in original['proofs'].items()}
    expected.update({str(REPO / relative): digest for relative, digest in runtime.items()})
    expected[str(OLD / 'release-inputs.json')] = OLD_INPUT_SHA
    rows = mapping['files']
    require(len(rows) == len(expected) and {row['old_path'] for row in rows} == set(expected),
            'exact migration row coverage required')
    metadata = {str(OLD / name) for name in ('release-inputs.json', 'runtime-proof.json', 'runtime-evidence-inputs.json')}
    for entry in mapping['files']:
        kind = 'canonical_binding_metadata' if entry['old_path'] in metadata else 'unchanged_bytes'
        require(set(entry) == {'old_path', 'new_path', 'old_raw_byte_sha256', 'new_raw_byte_sha256', 'kind'}
                and entry['kind'] == kind and entry['old_raw_byte_sha256'] == expected[entry['old_path']],
                'exact migration kind and historical hash required')
        checked_file(entry['old_path'], entry['old_raw_byte_sha256'])
        checked_file(entry['new_path'], entry['new_raw_byte_sha256'])
        require(Path(entry['new_path']) == destination(Path(entry['old_path'])), 'unexpected evidence migration')
        if entry['kind'] == 'unchanged_bytes':
            require(entry['old_raw_byte_sha256'] == entry['new_raw_byte_sha256'], 'historical capture bytes changed')


def adapted():
    n, original_inputs, original_runtime = historical()
    original_bound = n.bound

    def bound(entry, expected=None, manifest=None):
        path = Path(entry['path'])
        require(path.is_absolute() and path == path.resolve(), 'canonical evidence path required')
        return original_bound(entry, destination(expected) if expected is not None else None, manifest)

    n.bound = bound
    n.ROOT = EVIDENCE
    runtime_tree = ast.parse((OLD / 'worker/prepare_nvn.py').read_bytes())
    node = next(node for node in runtime_tree.body if isinstance(node, ast.FunctionDef) and node.name == 'verify_runtime')
    text = ast.get_source_segment((OLD / 'worker/prepare_nvn.py').read_text(), node)
    for old, new in [
        ("read(folder/'identity-capture.json')", "member_read(folder/'identity-capture.json',manifest)"),
        ("read(folder/'close.json')", "member_read(folder/'close.json',manifest)"),
        ("read(folder/'exact-daemon-cleanup.json')", "member_read(folder/'exact-daemon-cleanup.json',manifest)"),
        ("read(ROOT/'runtime/fixture-cleanup.json')", "member_read(ROOT/'runtime/fixture-cleanup.json',manifest)"),
    ]:
        text = n.once(text, old, new)
    n.member_read = lambda path, manifest: member_read(n, path, manifest)
    exec(compile(text, str(Path(__file__)) + '::pinned-runtime', 'exec'), n.__dict__)
    inherited_runtime = n.verify_runtime
    def verify_runtime(proof, base):
        manifest = read(n.bound(proof['evidence_manifest'], EVIDENCE / 'runtime-evidence-inputs.json'))
        validate_manifest(manifest, original_runtime)
        return inherited_runtime(proof, base)

    n.verify_runtime = verify_runtime
    return n, n.implementation(), original_inputs, original_runtime


def verify():
    n, base, original, runtime = adapted()
    inputs = read(checked_file(EVIDENCE / 'release-inputs.json', INPUT_SHA))
    n.validate_inputs(inputs, base)
    mapping = read(checked_file(EVIDENCE / 'migration-map.json', MAP_SHA))
    validate_mapping(mapping, original, runtime)
    return dict(status='PASS_HISTORICAL_EVIDENCE_ONLY', direct_pins=len(inputs['proofs']),
                runtime_files=len(runtime), compiled_files=148, release_ready=False,
                archive_generated=False, historical_feedback_count=29,
                limitations=['Historical recorded baseline only', 'No new runtime, candidate or publication',
                             'Current feedback and disk gates require fresh separate evidence'])


def main():
    require(len(sys.argv) == 1, 'verify-only command takes no arguments; preparation is unavailable')
    print(json.dumps(verify(), indent=2))


if __name__ == '__main__':
    main()
