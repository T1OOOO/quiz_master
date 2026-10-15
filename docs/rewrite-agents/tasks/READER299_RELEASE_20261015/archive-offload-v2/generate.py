"""Render the exact nineteen-file plan. This module performs no remote operation."""
if not __debug__:
    raise RuntimeError('archive offload generator refuses optimized Python')

from pathlib import Path
import json
import offload

DOCS = Path(__file__).resolve().parent


def render(plan, protected):
    offload.validate_plan(plan)
    assert protected == offload.PROTECTED_HASHES and len(protected) == 17
    source = Path(offload.__file__).read_text(encoding='utf-8')
    body = source + "\nplan = " + repr(plan) + "\nprotected = " + repr(protected) + "\n"
    body += """
entries = validate_plan(plan)
preflight()
verify_protected(protected)
# Other projects may add images. Keep identities in memory, publish only counts/hashes.
before = None
def snapshot_before_unlink():
    global before
    before = loaded_images()
    print(json.dumps({'loaded_images_before': inventory_summary(before)}), flush=True)
removed = remove_verified(entries, before_unlink=snapshot_before_unlink)
after = loaded_images()
images_preserved(before, after)
print(json.dumps({'preexisting_loaded_images_preserved': True, 'loaded_images_after': inventory_summary(after), 'loaded_images_added': {key: len(after[key] - before[key]) for key in before}}), flush=True)
verify_protected(protected)
state = preflight()
assert removed == [entry['path'] for entry in entries] and len(removed) == 19
print(json.dumps({'status': 'ARCHIVES_OFFLOADED', 'removed_count': len(removed), 'removed_bytes': sum(entry['size'] for entry in entries), 'release_preparation_capacity_gate_still_required': True, 'disk_available': state['disk_available'], 'disk_total': state['disk_total']}), flush=True)
"""
    compile(body, 'exact-archive-offload-v2', 'exec')
    return "set -euo pipefail\nunset PYTHONOPTIMIZE PYTHONSTARTUP\ntest \"$(hostname)\" = racknerd-f0269d5\nexec 8>/opt/quiz-master/DEPLOY.lock\nflock -n 8\npython3 - <<'QUIZ_OFFLOAD_V2'\n" + body + "\nQUIZ_OFFLOAD_V2\n"


def main():
    plan = json.loads((DOCS / 'plan.json').read_bytes())
    protected = json.loads((DOCS / 'protected-hashes.json').read_bytes())
    script = render(plan, protected)
    with (DOCS / 'offload.sh').open('xb') as stream:
        stream.write(script.encode('utf-8'))


if __name__ == '__main__':
    main()
