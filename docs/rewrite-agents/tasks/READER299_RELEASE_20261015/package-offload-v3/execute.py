"""Root-only executor: actual independent approval and exact verified copies precede SSH."""
if not __debug__:
    raise RuntimeError('archive offload executor refuses optimized Python')

from pathlib import Path, PurePosixPath
import hashlib, json, os, subprocess, stat, tarfile, re
from offload import validate_plan, marker, PROTECTED_HASHES
from generate import render

ROOT = Path('C:/ap/quiz_master')
DOCS = Path(__file__).resolve().parent
WORK = ROOT / '.run/reader299_release_20261015/package-offload-v3'
COPY_ROOTS = (WORK / 'offloaded',)
TASK_ID = 'task-42c16dbd80cd461f8dd54cb512a30641'
ASSIGNEE = 'session-293ef5f514b24416b57853188e8bf5ce'
INPUT_FILES = {'resume_prepare.py', 'copy-receipt.json', 'protected-hashes.json', 'source-input-sha256.json', 'failed-stage-bindings.json', 'generate.py', 'tests.json', 'test_offload.py', 'offload.sh', 'plan.json', 'test_resume_prepare.py', 'offload.py', 'execute.py'}


def digest(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def verify_copies(plan, receipt, plan_hash):
    entries = validate_plan(plan)
    assert receipt['plan_sha256'] == plan_hash
    assert len(entries) == receipt['count'] == len(receipt['copied']) == 12
    assert plan['total_bytes'] == receipt['bytes'] == sum(entry['size'] for entry in entries)
    for entry, copied in zip(entries, receipt['copied']):
        local = Path(copied['local'])
        allowed = [root for root in COPY_ROOTS if local.parent == root]
        assert len(allowed) == 1 and local.name == PurePosixPath(entry['path']).name
        root = allowed[0]
        assert root.is_dir() and not root.is_symlink() and root.resolve() == root.absolute()
        assert copied['remote'] == entry['path'] and not local.is_symlink()
        assert local.resolve().parent == root.resolve()
        before = local.lstat()
        assert stat.S_ISREG(before.st_mode) and before.st_size == copied['size'] == entry['size']
        with local.open('rb') as stream:
            assert marker(os.fstat(stream.fileno())) == marker(before)
            assert hashlib.file_digest(stream, 'sha256').hexdigest() == copied['sha256'] == entry['sha256']
            assert marker(os.fstat(stream.fileno())) == marker(before)
        assert marker(local.lstat()) == marker(before) and not local.is_symlink()
        assert copied['transfer_exit'] == 0 and copied['transfer_kind'] in ('ssh-tar',)


def validate_inputs():
    manifest = DOCS / 'approval-inputs.json'
    review = json.loads((DOCS / 'source-review.json').read_bytes())
    assert review.get('actual_cli_exit') == 0 and review.get('actual_hub_state') == 'ACCEPTED'
    item = review.get('actual_reviews', {}).get(TASK_ID, {})
    call, response = item.get('call', {}), item.get('actual_response', {})
    args = call.get('arguments', {})
    assert call.get('action') == 'review' and args.get('task_id') == TASK_ID
    assert args.get('verdict') == 'accept' and args.get('error_count') == 0
    assert response.get('id') == TASK_ID and response.get('state') == 'ACCEPTED'
    assert response.get('assignee') == ASSIGNEE and response.get('reviewer') and response['reviewer'] != response['assignee']
    assert 'approval-inputs sha256 ' + digest(manifest) in args.get('note', '')
    inputs = json.loads(manifest.read_bytes())
    assert set(inputs) == INPUT_FILES
    assert all(digest(DOCS / name) == sha for name, sha in inputs.items())
    plan = json.loads((DOCS / 'plan.json').read_bytes())
    receipt = json.loads((DOCS / 'copy-receipt.json').read_bytes())
    protected = json.loads((DOCS / 'protected-hashes.json').read_bytes())
    assert protected == PROTECTED_HASHES
    verify_copies(plan, receipt, digest(DOCS / 'plan.json'))
    assert (DOCS / 'offload.sh').read_bytes() == render(plan, protected).encode('utf-8')
    tests = json.loads((DOCS / 'tests.json').read_bytes())
    assert tests.get('actual_exit') == 0
    return plan, receipt, inputs


def main():
    plan, receipt, inputs = validate_inputs()
    stdout, stderr, exit_file = [DOCS / name for name in ('execution-stdout.jsonl', 'execution-stderr.txt', 'execution-exit.json')]
    assert not any(path.exists() or path.is_symlink() for path in (stdout, stderr, exit_file))
    # Rehash frozen inputs and local copies immediately before the one execution.
    assert all(digest(DOCS / name) == sha for name, sha in inputs.items())
    verify_copies(plan, receipt, digest(DOCS / 'plan.json'))
    command = ['ssh', '-i', 'C:/Users/Alexey_Matvienko/.ssh/ll_deploy_ed25519', 'root@192.3.164.184', 'bash -s']
    code = 'not_started'
    with stdout.open('xb') as out, stderr.open('xb') as err:
        try:
            result = subprocess.run(command, input=(DOCS / 'offload.sh').read_bytes(), stdout=out, stderr=err, timeout=600)
            code = result.returncode
        except subprocess.TimeoutExpired:
            code = 'timeout'
            raise
        finally:
            with exit_file.open('x') as stream:
                stream.write(json.dumps({'actual_exit': code}) + '\n')
    assert code == 0, 'Inspect preserved partial execution logs; do not rerun blindly.'
    print(json.dumps({'actual_exit': code, 'local_verified_copies': 12}))


if __name__ == '__main__':
    main()
