"""Finite archive offload: require genuine source approval and revalidate every local copy."""
if not __debug__:
    raise RuntimeError('archive offload executor refuses optimized Python')

from pathlib import Path, PurePosixPath
import hashlib, json, subprocess
from offload import PATTERN, PROTECTED, ROOT as LOGICAL_ROOT

ROOT = Path('C:/ap/quiz_master')
DOCS = ROOT / 'docs/rewrite-agents/tasks/READER299_RELEASE_20261015/archive-offload'
WORK = ROOT / '.run/reader299_release_20261015/archive-offload'
TASK_ID = 'task-98be7a80dbb44f06adfdd5f066859952'


def digest(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def main():
    manifest = DOCS / 'approval-inputs.json'
    review = json.loads((DOCS / 'source-review.json').read_bytes())
    assert review['actual_cli_exit'] == 0 and review['actual_hub_state'] == 'ACCEPTED'
    item = review['actual_reviews'][TASK_ID]
    assert item['call']['arguments']['verdict'] == 'accept'
    assert item['actual_response']['state'] == 'ACCEPTED'
    assert item['actual_response']['reviewer'] != item['actual_response']['assignee']
    assert 'approval-inputs sha256 ' + digest(manifest) in item['call']['arguments']['note']
    inputs = json.loads(manifest.read_bytes())
    assert set(inputs) == {'offload.py', 'test_offload.py', 'execute.py', 'offload.sh', 'plan.json', 'copy-receipt.json', 'protected-hashes.json', 'tests.json'}
    assert all(digest(DOCS / name) == sha for name, sha in inputs.items())
    plan = json.loads((DOCS / 'plan.json').read_bytes())
    receipt = json.loads((DOCS / 'copy-receipt.json').read_bytes())
    assert receipt['plan_sha256'] == digest(DOCS / 'plan.json')
    assert len(plan['entries']) == receipt['count'] == len(receipt['copied']) == 10
    assert plan['total_bytes'] == receipt['bytes'] == 739922944
    for entry, copied in zip(plan['entries'], receipt['copied']):
        logical = PurePosixPath(entry['path'])
        assert logical.parent == LOGICAL_ROOT and logical.name not in PROTECTED
        assert logical.name in ['quiz-2026.10.12-singers-1c9b534.tar', 'quiz-2026.10.13-culture-384d798.tar', 'quiz-2026.10.13-culture-328f2f8.tar', 'quiz-2026.10.13-culture-e437661.tar', 'quiz-2026.10.13-article-only-ffa2716.tar', 'quiz-2026.10.13-film-craft-adf95a5.tar', 'quiz-2026.10.13-music-craft-f79555e.tar', 'quiz-2026.10.14-acting-craft-83748f5.tar', 'quiz-2026.10.14-screen-song-6866608.tar', 'quiz-2026.10.14-mixed-ecac092.tar'] and PATTERN.fullmatch(logical.name)
        assert entry['size'] > 0 and len(entry['sha256']) == 64
        local = WORK / 'offloaded' / Path(entry['path']).name
        assert str(local) == copied['local'] and copied['remote'] == entry['path']
        assert not local.is_symlink() and local.is_file() and local.resolve().parent == (WORK / 'offloaded').resolve()
        assert local.stat().st_size == copied['size'] == entry['size']
        assert digest(local) == copied['sha256'] == entry['sha256']
        assert copied['transfer_exit'] == 0 and copied['transfer_kind'] in ('scp', 'sftp-reget')
    stdout = DOCS / 'execution-stdout.jsonl'
    stderr = DOCS / 'execution-stderr.txt'
    exit_file = DOCS / 'execution-exit.json'
    assert not any(path.exists() for path in (stdout, stderr, exit_file))
    command = ['ssh', '-i', 'C:/Users/Alexey_Matvienko/.ssh/ll_deploy_ed25519', 'root@192.3.164.184', 'bash -s']
    code = 'not_started'
    with stdout.open('wb') as out, stderr.open('wb') as err:
        try:
            result = subprocess.run(command, input=(DOCS / 'offload.sh').read_bytes(), stdout=out, stderr=err, timeout=600)
            code = result.returncode
        except subprocess.TimeoutExpired:
            code = 'timeout'
            raise
        finally:
            exit_file.write_text(json.dumps({'actual_exit': code}) + '\n')
    assert code == 0, 'Inspect preserved partial execution logs; do not rerun blindly.'
    print(json.dumps({'actual_exit': code, 'local_verified_copies':10}))


if __name__ == '__main__':
    main()
