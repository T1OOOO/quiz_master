"""Remove only two superseded, never-deployed candidates after independent review.

Run this script on the pinned server with Python. Default mode only inventories.
--execute repeats every guard under DEPLOY.lock before changing anything.
"""
import argparse
import fcntl
import json
import os
from pathlib import Path
import shutil
import socket
import stat
import subprocess
import urllib.request

HOST = 'racknerd-f0269d5'
ROOT = Path('/opt/quiz-master/releases')
CURRENT_BUILD = 'quiz-2026.10.19-feedback-5df1d538'
CURRENT_INDEX = 'sha256:ea1d2e9049f87f777df9b5b226dba5391aff4050bfd66c28690259d04b668561'
CURRENT_IMAGE = 'quiz-master:' + CURRENT_BUILD + '@' + CURRENT_INDEX
PVC = '7fc2428f-4146-4c78-a26d-2347d9f3b7bf'
TARGETS = {
    'quiz-2026.10.19-feedback-0c409557': {
        'index': 'sha256:8dc171e7e7dd75ce524a14a47cef91662ace1db4c6a0ab0b0cd748de54437b25',
        'config': 'sha256:dd0c5071d7bfd42592353ee995ce7f03572f83d1fb2b18ada78a72960f042372'},
    'quiz-2026.10.19-feedback-27d53b72': {
        'index': 'sha256:46352c0eabb2b11cec6944ec43cdcae358adc4481c29e613e9c0c38a49e37b42',
        'config': 'sha256:2068b71cb6d0e3294fc8126d5421209c65e98e5305f905def0ee00be2752b262'},
}


def run(*args):
    return subprocess.check_output(args, text=True)


def data(*args):
    return json.loads(run(*args))


def public():
    with urllib.request.urlopen('https://quiz.kotopedia.org/version.json', timeout=30) as r:
        assert json.load(r)['buildId'] == CURRENT_BUILD
    with urllib.request.urlopen('https://quiz.kotopedia.org/health/ready', timeout=30) as r:
        assert r.status == 200


def state():
    assert socket.gethostname() == HOST
    deploy = data('kubectl', 'get', 'deploy', 'quiz-master', '-n', 'quiz-master', '-o', 'json')
    assert deploy['metadata']['annotations']['deployment.kubernetes.io/revision'] == '65'
    assert deploy['spec']['template']['metadata']['annotations']['quiz-master/build-id'] == CURRENT_BUILD
    containers = deploy['spec']['template']['spec']['containers']
    assert {c['name'] for c in containers} == {'web', 'api'}
    assert all(c['image'] == CURRENT_IMAGE for c in containers)
    assert run('kubectl', 'get', 'pvc', 'quiz-data', '-n', 'quiz-master', '-o', 'jsonpath={.metadata.uid}') == PVC
    history = data('helm', 'history', 'quiz-master', '-n', 'quiz-master', '-o', 'json')
    assert history[-1]['revision'] == 67 and history[-1]['status'] == 'deployed'
    assert {66, 67} <= {h['revision'] for h in history}
    nodes = data('kubectl', 'get', 'nodes', '-o', 'json')['items']
    assert len(nodes) == 1
    node = nodes[0]
    conditions = {c['type']: c['status'] for c in node['status']['conditions']}
    assert conditions['Ready'] == 'True' and conditions['DiskPressure'] == 'False'
    assert not node['spec'].get('unschedulable')
    assert not any(t.get('effect') in ('NoSchedule', 'NoExecute') for t in node['spec'].get('taints', []))
    fs = os.statvfs('/var/lib/rancher/k3s/agent/containerd')
    assert fs.f_bavail * 5 >= fs.f_blocks
    public()
    return {'build_id': CURRENT_BUILD, 'helm_revision': 67, 'deployment_revision': 65,
            'imagefs_available_percent': 100 * fs.f_bavail / fs.f_blocks,
            'available_bytes': fs.f_bavail * fs.f_frsize}


def inventory():
    result = state()
    needles = [v for name, values in TARGETS.items() for v in (name, values['index'], values['config'])]
    def no_target(value):
        text = json.dumps(value, sort_keys=True)
        assert not any(s in text for s in needles), 'A target is referenced by a container or retained release'
    history = data('helm', 'history', 'quiz-master', '-n', 'quiz-master', '-o', 'json')
    for h in history:
        no_target(run('helm', 'get', 'manifest', 'quiz-master', '-n', 'quiz-master', '--revision', str(h['revision'])))
    no_target(data('kubectl', 'get', 'pods', '--all-namespaces', '-o', 'json'))
    docker_ids = run('docker', 'ps', '-aq').split()
    if docker_ids:
        no_target(data('docker', 'inspect', *docker_ids))
    no_target(data('k3s', 'crictl', 'ps', '-a', '-o', 'json'))
    ctr = {}
    for line in run('k3s', 'ctr', '-n', 'k8s.io', 'images', 'ls').splitlines()[1:]:
        cols = line.split()
        assert len(cols) >= 3
        ctr[cols[0]] = cols[2]
    result['targets'] = []
    for build, values in TARGETS.items():
        path = ROOT / build
        assert path.resolve(strict=True) == path and not path.is_symlink()
        info = path.stat()
        assert (info.st_uid, info.st_gid, stat.S_IMODE(info.st_mode)) == (0, 0, 0o700)
        receipt_path = path / 'prepared-receipt.json'
        assert receipt_path.is_file() and not receipt_path.is_symlink()
        receipt = json.loads(receipt_path.read_text())
        tag = 'quiz-master:' + build
        assert receipt['build_id'] == build and receipt['image'] == tag + '@' + values['index']
        image = data('docker', 'image', 'inspect', tag)[0]
        assert image['Id'] == values['index']
        assert image['RepoTags'] == [tag]
        assert set(image['RepoDigests']) == {'quiz-master@' + values['index']}
        expected = {'docker.io/library/' + tag, 'docker.io/library/quiz-master@' + values['index'], values['config']}
        aliases = {ref for ref, digest in ctr.items() if digest == values['index']}
        assert aliases == expected, 'Unexpected containerd alias set'
        result['targets'].append({'build_id': build, 'path': str(path), 'docker_tag': tag,
                                  'index': values['index'], 'ctr_aliases': sorted(aliases)})
    return result


def execute():
    with open('/opt/quiz-master/DEPLOY.lock', 'a') as lock:
        fcntl.flock(lock.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
        before = inventory()
        # Every action below uses only literal approved targets, freshly inventoried under lock.
        for item in before['targets']:
            subprocess.run(['docker', 'image', 'rm', item['docker_tag']], check=True)
            subprocess.run(['k3s', 'ctr', '-n', 'k8s.io', 'images', 'rm', *item['ctr_aliases']], check=True)
            path = ROOT / item['build_id']
            assert path.resolve(strict=True) == path and not path.is_symlink()
            assert str(path) == item['path']
            shutil.rmtree(path)
        after = state()
        after['removed_builds'] = list(TARGETS)
        after['available_bytes_before'] = before['available_bytes']
        after['recovered_bytes'] = after['available_bytes'] - before['available_bytes']
        print(json.dumps(after, sort_keys=True))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--execute', action='store_true')
    args = parser.parse_args()
    if args.execute:
        execute()
    else:
        print(json.dumps(inventory(), sort_keys=True))
