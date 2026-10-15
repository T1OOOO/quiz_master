set -euo pipefail
unset PYTHONOPTIMIZE PYTHONSTARTUP
test "$(hostname)" = racknerd-f0269d5
exec 8>/opt/quiz-master/DEPLOY.lock
flock -n 8
python3 - <<'QUIZ_OFFLOAD_V2'
"""Unlink only frozen, hash-verified old Quiz Master image archives after copying."""
if not __debug__:
    raise RuntimeError('archive offload refuses optimized Python')

from pathlib import Path, PurePosixPath
import hashlib
import json
import os
import re
import stat

ROOT = PurePosixPath('/var/lib/rancher/k3s/agent/images')
PROTECTED = {
    'quiz-2026.10.14-library-09b19cc.tar',
    'quiz-2026.10.14-reader-17be4ce.tar',
    'quiz-2026.10.15-reader-06dfa0b.tar',
    'quiz-2026.10.15-actors-d204f9b.tar',
    'quiz-2026.10.15-reader291-3482af9.tar',
}
PATTERN = re.compile(r'(?:quiz-2026[.]10[.](?:0[2-9]|1[0-4])-[a-z0-9-]+-[0-9a-f]{7}|quiz-master-[0-9a-f]{7}-[0-9a-f]{4})[.]tar')


def marker(st):
    return (st.st_dev, st.st_ino, st.st_size, st.st_mtime_ns)


def verify(entry, root):
    logical = PurePosixPath(entry['path'])
    assert logical.parent == ROOT and logical.name not in PROTECTED
    assert PATTERN.fullmatch(logical.name) and str(logical) == entry['path']
    assert re.fullmatch('[0-9a-f]{64}', entry['sha256']) and entry['size'] > 0
    path = root / logical.name
    assert not path.is_symlink()
    before = path.lstat()
    assert stat.S_ISREG(before.st_mode)
    expected = (entry['dev'], entry['ino'], entry['size'], entry['mtime_ns'])
    assert marker(before) == expected
    fd = os.open(path, os.O_RDONLY | getattr(os, 'O_NOFOLLOW', 0))
    with os.fdopen(fd, 'rb') as stream:
        assert marker(os.fstat(stream.fileno())) == expected
        assert hashlib.file_digest(stream, 'sha256').hexdigest() == entry['sha256']
        assert marker(os.fstat(stream.fileno())) == expected
    assert marker(path.lstat()) == expected and not path.is_symlink()
    return path


def remove_verified(entries, root=Path(str(ROOT)), *, before_unlink=None):
    assert entries and len({e['path'] for e in entries}) == len(entries)
    root = Path(root)
    assert root.is_dir() and not root.is_symlink() and root.resolve() == root.absolute()
    # Validate every file before removing any, then recheck at each unlink.
    for entry in entries:
        verify(entry, root)
    removed = []
    for entry in entries:
        path = verify(entry, root)
        if not removed and before_unlink is not None:
            before_unlink()
            assert marker(path.lstat()) == (entry['dev'], entry['ino'], entry['size'], entry['mtime_ns']) and not path.is_symlink()
        path.unlink()
        removed.append(entry['path'])
        print(json.dumps({'removed': entry['path'], 'bytes': entry['size']}), flush=True)
    return removed


PROTECTED_HASHES = {'/opt/quiz-master/releases/quiz-2026.10.14-library-09b19cc.tar.gz': '7d9d6c64763a64b811d942a9df3cdc489a4fc39a11ac8d628165e0636649791f', '/opt/quiz-master/releases/quiz-2026.10.14-reader-17be4ce.tar.gz': 'a67c8afa9d18dfe67c4651f50a84c0337998150d5236e9babfed551a212cfb6a', '/opt/quiz-master/releases/quiz-2026.10.15-reader-06dfa0b.tar.gz': '6ddd12317732d0fa5bf87f8a80ff24e7ef71b50a233d7d65fa4249421a6c79ab', '/opt/quiz-master/releases/quiz-2026.10.15-actors-d204f9b.tar.gz': '5ab6a34ea49b4078d952a311cf5468999b4b696108d1b4b6d6c285b3b74e04a2', '/var/lib/rancher/k3s/agent/images/quiz-2026.10.14-library-09b19cc.tar': '7d4566aab0df18b6a879ac94115e5b146ebcc1252ad7bef038d8ef1f37279b79', '/var/lib/rancher/k3s/agent/images/quiz-2026.10.14-reader-17be4ce.tar': 'ee77b4ccd5b9e05668e7759b8399c8943825f34181b3b480564d941097443812', '/var/lib/rancher/k3s/agent/images/quiz-2026.10.15-reader-06dfa0b.tar': 'b8bd7bc5fb382f7860ce141d05e467b0b426429e4355212d44b3e50cbda61684', '/var/lib/rancher/k3s/agent/images/quiz-2026.10.15-actors-d204f9b.tar': '04badd8485c8209919fe2a45937da0093f22dcb80fc6b379daa92fbbedcbc501', '/opt/quiz-master/backups/quiz-2026.10.14-library-09b19cc-publish-20261014T223958Z.sqlite': 'c811bcfdc4af694b9f638f6901ba9360c04261bd9def7049049303d9e3d4b291', '/opt/quiz-master/backups/quiz-2026.10.15-reader-06dfa0b-publish-20261015T034437Z.sqlite': '6794975864e19369f7e41188ad98de43244bd34153451d158115210a6e52bd21', '/opt/quiz-master/backups/quiz-2026.10.15-actors-d204f9b-publish-20261015T061630Z.sqlite': '6794975864e19369f7e41188ad98de43244bd34153451d158115210a6e52bd21', '/opt/quiz-master/releases/quiz-2026.10.15-reader291-3482af9.tar.gz': 'd926a276aeb60f2cd7181a2d0322f7ef0b16ec5d32863ab0afe1c6517b2e23ad', '/var/lib/rancher/k3s/agent/images/quiz-2026.10.15-reader291-3482af9.tar': 'e20d542615a12f07883b828dc166170948817dc723f5da7686ce63aa9b22400b', '/opt/quiz-master/backups/quiz-2026.10.15-reader291-3482af9-cutover-20261015T084302Z.sqlite': '6794975864e19369f7e41188ad98de43244bd34153451d158115210a6e52bd21', '/opt/quiz-master/releases/quiz-2026.10.15-reader291-3482af9/quiz-2026.10.15-reader291-3482af9-cutover-20261015T084302Z-values.yaml': '53f77283f65b00387ec3d3f7fe30a278e5c2a324d27506fa976ab14861cd3f7f', '/opt/quiz-master/releases/quiz-2026.10.15-reader291-3482af9/quiz-2026.10.15-reader291-3482af9-cutover-20261015T084302Z-rendered.yaml': '61194251e41088773f5e2b3da7b448d074f5a69f6caeb4343cb9a049d7824b98', '/opt/quiz-master/backups/quiz-2026.10.15-reader291-3482af9-publish-20261015T093511Z.sqlite': '6794975864e19369f7e41188ad98de43244bd34153451d158115210a6e52bd21'}


EXPECTED_TOTAL_BYTES = 1397289472
OLD_NAMES = {'quiz-2026.10.14-acting-craft-83748f5.tar', 'quiz-2026.10.13-article-only-ffa2716.tar', 'quiz-2026.10.12-singers-1c9b534.tar', 'quiz-2026.10.13-culture-384d798.tar', 'quiz-2026.10.13-music-craft-f79555e.tar', 'quiz-2026.10.13-culture-328f2f8.tar', 'quiz-2026.10.14-mixed-ecac092.tar', 'quiz-2026.10.13-film-craft-adf95a5.tar', 'quiz-2026.10.14-screen-song-6866608.tar', 'quiz-2026.10.13-culture-e437661.tar'}


def validate_plan(plan):
    assert plan['schema'] == 'qm-exact-archive-offload/v2'
    entries = plan['entries']
    assert len(entries) == len({entry['path'] for entry in entries}) == 19
    assert plan['total_bytes'] == sum(entry['size'] for entry in entries) == EXPECTED_TOTAL_BYTES
    assert {PurePosixPath(entry['path']).name for entry in entries if not PurePosixPath(entry['path']).name.startswith('quiz-master-')} == OLD_NAMES
    assert sum(PurePosixPath(entry['path']).name.startswith('quiz-master-') for entry in entries) == 9
    for entry in entries:
        logical = PurePosixPath(entry['path'])
        assert logical.parent == ROOT and str(logical) == entry['path']
        assert logical.name not in PROTECTED and PATTERN.fullmatch(logical.name)
        assert set(entry) == {'path', 'size', 'sha256', 'dev', 'ino', 'mtime_ns'}
        assert all(type(entry[key]) is int for key in ('size', 'dev', 'ino', 'mtime_ns'))
        assert entry['size'] > 0 and entry['dev'] >= 0 and entry['ino'] > 0 and entry['mtime_ns'] > 0
        assert re.fullmatch('[0-9a-f]{64}', entry['sha256'])
    assert not {entry['path'] for entry in entries}.intersection(PROTECTED_HASHES)
    return entries


def loaded_images():
    import subprocess
    lines = subprocess.check_output(['k3s', 'ctr', 'images', 'list'], text=True).splitlines()
    assert lines and lines[0].split()[:3] == ['REF', 'TYPE', 'DIGEST']
    containerd = set()
    for line in lines[1:]:
        row = line.split()
        assert len(row) >= 3 and re.fullmatch('sha256:[0-9a-f]{64}', row[2])
        containerd.add((row[0], row[2]))
    lines = subprocess.check_output(['docker', 'image', 'ls', '--no-trunc', '--digests', '--format', '{{.Repository}}:{{.Tag}} {{.Digest}} {{.ID}}'], text=True).splitlines()
    docker = set()
    for line in lines:
        row = line.split()
        assert len(row) == 3 and re.fullmatch('sha256:[0-9a-f]{64}', row[2])
        assert row[1] == '<none>' or re.fullmatch('sha256:[0-9a-f]{64}', row[1])
        docker.add(tuple(row))
    assert containerd and docker
    return {'containerd': containerd, 'docker': docker}


def images_preserved(before, after):
    assert set(before) == set(after) == {'containerd', 'docker'}
    for kind in before:
        assert before[kind] and before[kind] <= after[kind], 'preexisting loaded image/reference disappeared: ' + kind


def verify_protected(protected):
    assert protected == PROTECTED_HASHES and len(protected) == 17
    for text, expected in protected.items():
        path = Path(text)
        assert path.is_file() and not path.is_symlink() and path.resolve() == path.absolute()
        before = path.lstat()
        assert stat.S_ISREG(before.st_mode)
        fd = os.open(path, os.O_RDONLY | getattr(os, 'O_NOFOLLOW', 0))
        with os.fdopen(fd, 'rb') as stream:
            assert marker(os.fstat(stream.fileno())) == marker(before)
            assert hashlib.file_digest(stream, 'sha256').hexdigest() == expected
            assert marker(os.fstat(stream.fileno())) == marker(before)
        assert marker(path.lstat()) == marker(before) and not path.is_symlink()
    print(json.dumps({'protected_files_verified': len(protected)}), flush=True)


def preflight():
    import subprocess, sqlite3, urllib.request
    h = json.loads(subprocess.check_output(['helm', 'status', 'quiz-master', '-n', 'quiz-master', '-o', 'json']))
    x = json.loads(subprocess.check_output(['kubectl', 'get', 'deploy', 'quiz-master', '-n', 'quiz-master', '-o', 'json']))
    p = json.loads(subprocess.check_output(['kubectl', 'get', 'pvc', 'quiz-data', '-n', 'quiz-master', '-o', 'json']))
    assert h['version'] == 61 and h['info']['status'] == 'deployed'
    images = [c['image'] for c in x['spec']['template']['spec']['containers']]
    assert len(images) == 2 and set(images) == {'docker.io/library/quiz-master@sha256:0f24677d8e499df9d21e80ce1dd50b8e830b37608c4c86e1c38e76ccc30d3228'}
    assert x['status'].get('availableReplicas') == 1
    assert p['metadata']['uid'] == '7fc2428f-4146-4c78-a26d-2347d9f3b7bf' and p['status']['phase'] == 'Bound'
    nodes = json.loads(subprocess.check_output(['kubectl', 'get', 'nodes', '-o', 'json']))['items']
    assert len(nodes) == 1
    node = nodes[0]; conditions = {c['type']: c['status'] for c in node['status']['conditions']}
    assert conditions['Ready'] == 'True' and conditions['DiskPressure'] == 'False'
    assert not node.get('spec', {}).get('unschedulable', False)
    assert not any(t['effect'] in ('NoSchedule', 'NoExecute') for t in node.get('spec', {}).get('taints', []))
    st = os.statvfs('/var/lib/rancher/k3s/agent/containerd')
    available, total = st.f_bavail * st.f_frsize, st.f_blocks * st.f_frsize
    assert available > 0 and total > 0
    with urllib.request.urlopen('https://quiz.kotopedia.org/health/ready', timeout=15) as ready:
        assert ready.status == 200
    with sqlite3.connect('file:/var/lib/rancher/k3s/storage/pvc-7fc2428f-4146-4c78-a26d-2347d9f3b7bf_quiz-master_quiz-data/quiz.db?mode=ro', uri=True) as db:
        rows = db.execute('select * from feedback_reports order by rowid').fetchall()
        assert len(rows) == 29 and db.execute("select count(*) from feedback_reports where status='open'").fetchone()[0] == 29
        sha = hashlib.sha256(json.dumps(rows, ensure_ascii=False, default=str).encode()).hexdigest()
        assert sha == '452929a2ea8dc34600eff8039571e2b0479ec7ad1ec52fa6e271b5c71008030e'
    backup = '/opt/quiz-master/backups/quiz-2026.10.15-reader291-3482af9-publish-20261015T093511Z.sqlite'
    assert stat.S_IMODE(os.stat(backup).st_mode) == 0o600
    with sqlite3.connect('file:' + backup + '?mode=ro', uri=True) as db:
        assert db.execute('pragma integrity_check').fetchone()[0] == 'ok'
    result = {'helm_revision': 61, 'status': 'deployed', 'images': images, 'available_replicas': 1, 'pvc_uid': p['metadata']['uid'], 'feedback_count': len(rows), 'all_open': True, 'feedback_sha256': sha, 'node_ready': True, 'disk_pressure': False, 'blocking_taints': False, 'disk_available': available, 'disk_total': total, 'disk_at_least20percent': available * 5 >= total, 'https_readiness_status': 200, 'backup_mode': '0600', 'backup_integrity': 'ok'}
    print(json.dumps(result), flush=True)
    return result


def inventory_summary(inventory):
    return {key: {'count': len(rows), 'sha256': hashlib.sha256(json.dumps(sorted(rows), separators=(',', ':')).encode()).hexdigest()} for key, rows in inventory.items()}

plan = {'schema': 'qm-exact-archive-offload/v2', 'entries': [{'path': '/var/lib/rancher/k3s/agent/images/quiz-2026.10.12-singers-1c9b534.tar', 'size': 73764352, 'dev': 64770, 'ino': 1310785, 'mtime_ns': 1791776425227602368, 'sha256': 'fbf1621337caf9f693969962a074094a1834c9fb7d57795df9bd4579e9539b9c'}, {'path': '/var/lib/rancher/k3s/agent/images/quiz-2026.10.13-culture-384d798.tar', 'size': 73974272, 'dev': 64770, 'ino': 1310790, 'mtime_ns': 1791844002745372538, 'sha256': '23ff0eee496efea8d035747404037f297f058689592e01af62bf646d9bbf081b'}, {'path': '/var/lib/rancher/k3s/agent/images/quiz-2026.10.13-culture-328f2f8.tar', 'size': 73980416, 'dev': 64770, 'ino': 1310792, 'mtime_ns': 1791861738918033108, 'sha256': '522ce6ecb54d72151d7d3d117fdb818e790652d32ad525a1f3a73831969713a6'}, {'path': '/var/lib/rancher/k3s/agent/images/quiz-2026.10.13-culture-e437661.tar', 'size': 73999872, 'dev': 64770, 'ino': 1310793, 'mtime_ns': 1791869516718120965, 'sha256': '5012c719535e6e44b93555227c42c1c7ef40780a9fc03ca354148a12e96e54a3'}, {'path': '/var/lib/rancher/k3s/agent/images/quiz-2026.10.13-article-only-ffa2716.tar', 'size': 74004480, 'dev': 64770, 'ino': 1310795, 'mtime_ns': 1791900779931523311, 'sha256': 'f439c49cf2fcb8b9de7cdb585b2343eb356d334ac6bab37b9ab3c4b1e61a45a2'}, {'path': '/var/lib/rancher/k3s/agent/images/quiz-2026.10.13-film-craft-adf95a5.tar', 'size': 74014720, 'dev': 64770, 'ino': 1310796, 'mtime_ns': 1791914733041683199, 'sha256': 'a9a674a644d3ba2955210673e01e401fa9cdfd541a6f6d8aa6986c2d73eccbf3'}, {'path': '/var/lib/rancher/k3s/agent/images/quiz-2026.10.13-music-craft-f79555e.tar', 'size': 74023936, 'dev': 64770, 'ino': 1310797, 'mtime_ns': 1791924244652190471, 'sha256': '14a5d5badcbcb6f927eae44bb6a1c266353294a32843b84ec3d9359dfa503cf6'}, {'path': '/var/lib/rancher/k3s/agent/images/quiz-2026.10.14-acting-craft-83748f5.tar', 'size': 74039296, 'dev': 64770, 'ino': 1310798, 'mtime_ns': 1791932985292592548, 'sha256': 'ae11582ea734404812c250ef044ccb51dc2e35f49263d88d1a42285c409dab35'}, {'path': '/var/lib/rancher/k3s/agent/images/quiz-2026.10.14-screen-song-6866608.tar', 'size': 74048512, 'dev': 64770, 'ino': 1310800, 'mtime_ns': 1791946145303908321, 'sha256': 'df721bb780a7d4253dd6c5fa529cf2c1a389ae2c95b7794cb3145bff0a03dacb'}, {'path': '/var/lib/rancher/k3s/agent/images/quiz-2026.10.14-mixed-ecac092.tar', 'size': 74073088, 'dev': 64770, 'ino': 1310740, 'mtime_ns': 1791978528279431160, 'sha256': 'ee7c913e5b75764452488f39b18ce3b2d0e34bf0767070112c2e979dcf666d68'}, {'path': '/var/lib/rancher/k3s/agent/images/quiz-master-e0f89cf-de8c.tar', 'size': 67491328, 'dev': 64770, 'ino': 1364047, 'mtime_ns': 1791563295522244305, 'sha256': '3fa16626b37c138941f0eed41d39442c8059dd75be8900de3f645e50228a71d5'}, {'path': '/var/lib/rancher/k3s/agent/images/quiz-master-3ec0a33-6115.tar', 'size': 73691136, 'dev': 64770, 'ino': 1312975, 'mtime_ns': 1791664192100870372, 'sha256': '514e7e78b05842c47216270816d84a582d0b3bd9af6a5c895801d86f6af6b764'}, {'path': '/var/lib/rancher/k3s/agent/images/quiz-master-ba80671-f746.tar', 'size': 73714176, 'dev': 64770, 'ino': 414135, 'mtime_ns': 1791669620858830767, 'sha256': 'f9fa927ec323ca934b75a70beadbb53470476dfd557b551311a7ffe8f216bebf'}, {'path': '/var/lib/rancher/k3s/agent/images/quiz-master-486901a-528a.tar', 'size': 73714176, 'dev': 64770, 'ino': 414962, 'mtime_ns': 1791670602291990737, 'sha256': 'e4f252d1d4eee747379e4247ea5d52580633bc9ad10fb154c4a139c0dadc7941'}, {'path': '/var/lib/rancher/k3s/agent/images/quiz-master-317b339-3e94.tar', 'size': 73736704, 'dev': 64770, 'ino': 415748, 'mtime_ns': 1791674895641156292, 'sha256': '62f9e5e526a810cb503eb438fcf8b6ef3941e0b60226498ecd7b2dffb49ead21'}, {'path': '/var/lib/rancher/k3s/agent/images/quiz-master-d228c9e-0c6b.tar', 'size': 73747968, 'dev': 64770, 'ino': 416350, 'mtime_ns': 1791687291880877871, 'sha256': '84e3e1fe79de482eb36dcfaf74ba97234c1ac0747774237ff1a1e667ccf21225'}, {'path': '/var/lib/rancher/k3s/agent/images/quiz-master-ddf47be-a3b9.tar', 'size': 73755136, 'dev': 64770, 'ino': 417149, 'mtime_ns': 1791695737434264273, 'sha256': '667c87d21cb1f9d0cca5e47632d004abf8fd382b6944497227aacecb26a33ab9'}, {'path': '/var/lib/rancher/k3s/agent/images/quiz-master-1537ff5-b16f.tar', 'size': 73756160, 'dev': 64770, 'ino': 417557, 'mtime_ns': 1791698829632702750, 'sha256': '52274034c6a4aed092e83edfbb903dff2e7f3db05262291e7aa789650a8da4a4'}, {'path': '/var/lib/rancher/k3s/agent/images/quiz-master-e0d13f4-5d41.tar', 'size': 73759744, 'dev': 64770, 'ino': 413436, 'mtime_ns': 1791754020880741186, 'sha256': 'b6dabd85ecfa2fdff885cdb5be6fa341948a58577cdadb7d4d127179e83d6764'}], 'total_bytes': 1397289472, 'scope': 'Only19exactcopiedoldQuizMastertars, noDB/backups/packages/stages/loadedimages/processes/otherprojectmutation'}
protected = {'/opt/quiz-master/releases/quiz-2026.10.14-library-09b19cc.tar.gz': '7d9d6c64763a64b811d942a9df3cdc489a4fc39a11ac8d628165e0636649791f', '/opt/quiz-master/releases/quiz-2026.10.14-reader-17be4ce.tar.gz': 'a67c8afa9d18dfe67c4651f50a84c0337998150d5236e9babfed551a212cfb6a', '/opt/quiz-master/releases/quiz-2026.10.15-reader-06dfa0b.tar.gz': '6ddd12317732d0fa5bf87f8a80ff24e7ef71b50a233d7d65fa4249421a6c79ab', '/opt/quiz-master/releases/quiz-2026.10.15-actors-d204f9b.tar.gz': '5ab6a34ea49b4078d952a311cf5468999b4b696108d1b4b6d6c285b3b74e04a2', '/var/lib/rancher/k3s/agent/images/quiz-2026.10.14-library-09b19cc.tar': '7d4566aab0df18b6a879ac94115e5b146ebcc1252ad7bef038d8ef1f37279b79', '/var/lib/rancher/k3s/agent/images/quiz-2026.10.14-reader-17be4ce.tar': 'ee77b4ccd5b9e05668e7759b8399c8943825f34181b3b480564d941097443812', '/var/lib/rancher/k3s/agent/images/quiz-2026.10.15-reader-06dfa0b.tar': 'b8bd7bc5fb382f7860ce141d05e467b0b426429e4355212d44b3e50cbda61684', '/var/lib/rancher/k3s/agent/images/quiz-2026.10.15-actors-d204f9b.tar': '04badd8485c8209919fe2a45937da0093f22dcb80fc6b379daa92fbbedcbc501', '/opt/quiz-master/backups/quiz-2026.10.14-library-09b19cc-publish-20261014T223958Z.sqlite': 'c811bcfdc4af694b9f638f6901ba9360c04261bd9def7049049303d9e3d4b291', '/opt/quiz-master/backups/quiz-2026.10.15-reader-06dfa0b-publish-20261015T034437Z.sqlite': '6794975864e19369f7e41188ad98de43244bd34153451d158115210a6e52bd21', '/opt/quiz-master/backups/quiz-2026.10.15-actors-d204f9b-publish-20261015T061630Z.sqlite': '6794975864e19369f7e41188ad98de43244bd34153451d158115210a6e52bd21', '/opt/quiz-master/releases/quiz-2026.10.15-reader291-3482af9.tar.gz': 'd926a276aeb60f2cd7181a2d0322f7ef0b16ec5d32863ab0afe1c6517b2e23ad', '/var/lib/rancher/k3s/agent/images/quiz-2026.10.15-reader291-3482af9.tar': 'e20d542615a12f07883b828dc166170948817dc723f5da7686ce63aa9b22400b', '/opt/quiz-master/backups/quiz-2026.10.15-reader291-3482af9-cutover-20261015T084302Z.sqlite': '6794975864e19369f7e41188ad98de43244bd34153451d158115210a6e52bd21', '/opt/quiz-master/releases/quiz-2026.10.15-reader291-3482af9/quiz-2026.10.15-reader291-3482af9-cutover-20261015T084302Z-values.yaml': '53f77283f65b00387ec3d3f7fe30a278e5c2a324d27506fa976ab14861cd3f7f', '/opt/quiz-master/releases/quiz-2026.10.15-reader291-3482af9/quiz-2026.10.15-reader291-3482af9-cutover-20261015T084302Z-rendered.yaml': '61194251e41088773f5e2b3da7b448d074f5a69f6caeb4343cb9a049d7824b98', '/opt/quiz-master/backups/quiz-2026.10.15-reader291-3482af9-publish-20261015T093511Z.sqlite': '6794975864e19369f7e41188ad98de43244bd34153451d158115210a6e52bd21'}

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

QUIZ_OFFLOAD_V2
