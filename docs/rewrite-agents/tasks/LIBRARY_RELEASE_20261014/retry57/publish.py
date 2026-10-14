from pathlib import Path
import hashlib
import json
import subprocess

r = Path('C:/ap/quiz_master')
d = Path(__file__).parent
def h(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()

a = json.loads((d/'acceptance.json').read_bytes())
assert a['actual_cli_exit'] == 0 and a['actual_hub_state'] == 'ACCEPTED'
callback = a['actual_reviews']['task-6474e4f08654470c8353f59b52be2f05']
assert callback['call']['arguments']['verdict'] == 'accept'
assert callback['actual_response']['reviewer'] != callback['actual_response']['assignee']
for name in ['publish.py', 'publish.sh', 'packet.json']:
    assert a['reviewed_sha256'][name] == h(d/name), 'Reviewed source changed'
packet = json.loads((d/'packet.json').read_bytes())
assert packet['baseline_helm_revision'] == 57 and packet['target_helm_revision'] == 58
assert packet['publish_script_sha256'] == h(d/'publish.sh')
package = json.loads((r/'.run/library_release_20261014/publication-package.json').read_bytes())
assert h(Path(package['archive'])) == packet['package_sha256'] == package['archive_sha256']
for revisions in [('09b19cc2d0fa8463a3e53e9a5f51981e657e2a48', 'HEAD'), ('09b19cc2d0fa8463a3e53e9a5f51981e657e2a48',)]:
    assert not subprocess.check_output(['git', 'diff', '--name-only', *revisions, '--', 'next', 'quizzes', 'metadata', 'study/question_articles'], cwd=r).strip()
try:
    p = subprocess.run(['ssh', '-i', 'C:/Users/Alexey_Matvienko/.ssh/ll_deploy_ed25519', 'root@192.3.164.184', 'bash -s -- publish'], input=(d/'publish.sh').read_bytes(), stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=600)
except subprocess.TimeoutExpired as error:
    (d/'publish-log.txt').write_bytes(error.stdout or b'')
    (d/'publish-exit.json').write_text(json.dumps({'actual_exit': 'timeout', 'published_verified': False}))
    raise
(d/'publish-log.txt').write_bytes(p.stdout)
(d/'publish-exit.json').write_text(json.dumps({'actual_exit': p.returncode}))
print(p.stdout.decode(errors='replace'))
assert p.returncode == 0
