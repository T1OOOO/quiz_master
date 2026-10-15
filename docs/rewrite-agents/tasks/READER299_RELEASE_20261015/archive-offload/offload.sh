set -euo pipefail
unset PYTHONOPTIMIZE PYTHONSTARTUP
test "$(hostname)" = racknerd-f0269d5
exec 8>/opt/quiz-master/DEPLOY.lock
flock -n 8
set -euo pipefail
test "$(hostname)" = racknerd-f0269d5
python3 - <<'PY'
import json,subprocess,sqlite3,hashlib,os
h=json.loads(subprocess.check_output(['helm','status','quiz-master','-n','quiz-master','-o','json']))
x=json.loads(subprocess.check_output(['kubectl','get','deploy','quiz-master','-n','quiz-master','-o','json']))
p=json.loads(subprocess.check_output(['kubectl','get','pvc','quiz-data','-n','quiz-master','-o','json']))
assert h['version']==61 and h['info']['status']=='deployed'
images=[c['image'] for c in x['spec']['template']['spec']['containers']];assert len(images)==2 and set(images)=={'docker.io/library/quiz-master@sha256:0f24677d8e499df9d21e80ce1dd50b8e830b37608c4c86e1c38e76ccc30d3228'}
assert x['status'].get('availableReplicas')==1 and p['metadata']['uid']=='7fc2428f-4146-4c78-a26d-2347d9f3b7bf'
import urllib.request
nodes=json.loads(subprocess.check_output(['kubectl','get','nodes','-o','json']))['items'];assert len(nodes)==1
node=nodes[0];conditions={c['type']:c['status'] for c in node['status']['conditions']};assert conditions['Ready']=='True' and conditions['DiskPressure']=='False';assert not any(t['effect'] in ['NoSchedule','NoExecute'] for t in node['spec'].get('taints',[]))
st=os.statvfs('/var/lib/rancher/k3s');available=st.f_bavail*st.f_frsize;total=st.f_blocks*st.f_frsize;assert available>0
with urllib.request.urlopen('https://quiz.kotopedia.org/health/ready',timeout=15) as ready:assert ready.status==200
print(json.dumps({'node_ready':True,'disk_pressure':False,'blocking_taints':False,'disk_available':available,'disk_total':total,'disk_at_least20percent':available*5>=total,'https_readiness_status':200}))
db=sqlite3.connect('file:/var/lib/rancher/k3s/storage/pvc-7fc2428f-4146-4c78-a26d-2347d9f3b7bf_quiz-master_quiz-data/quiz.db?mode=ro',uri=True)
rows=db.execute('select * from feedback_reports order by rowid').fetchall();sha=hashlib.sha256(json.dumps(rows,ensure_ascii=False,default=str).encode()).hexdigest();assert sha=='452929a2ea8dc34600eff8039571e2b0479ec7ad1ec52fa6e271b5c71008030e'
b='/opt/quiz-master/backups/quiz-2026.10.15-reader291-3482af9-publish-20261015T093511Z.sqlite';assert os.stat(b).st_mode & 0o777 == 0o600
backup=sqlite3.connect('file:'+b+'?mode=ro',uri=True);assert backup.execute('pragma integrity_check').fetchone()[0]=='ok'
print(json.dumps({'helm_revision':61,'status':'deployed','images':images,'available_replicas':1,'pvc_uid':p['metadata']['uid'],'feedback_count':len(rows),'all_open':db.execute("select count(*) from feedback_reports where status='open'").fetchone()[0]==29,'feedback_sha256':sha,'backup_mode':'0600','backup_integrity':'ok'}))
PY
python3 - <<'PY'
from pathlib import Path
import hashlib,json,subprocess
for text,expected in {'/opt/quiz-master/releases/quiz-2026.10.14-library-09b19cc.tar.gz': '7d9d6c64763a64b811d942a9df3cdc489a4fc39a11ac8d628165e0636649791f', '/opt/quiz-master/releases/quiz-2026.10.14-reader-17be4ce.tar.gz': 'a67c8afa9d18dfe67c4651f50a84c0337998150d5236e9babfed551a212cfb6a', '/opt/quiz-master/releases/quiz-2026.10.15-reader-06dfa0b.tar.gz': '6ddd12317732d0fa5bf87f8a80ff24e7ef71b50a233d7d65fa4249421a6c79ab', '/opt/quiz-master/releases/quiz-2026.10.15-actors-d204f9b.tar.gz': '5ab6a34ea49b4078d952a311cf5468999b4b696108d1b4b6d6c285b3b74e04a2', '/var/lib/rancher/k3s/agent/images/quiz-2026.10.14-library-09b19cc.tar': '7d4566aab0df18b6a879ac94115e5b146ebcc1252ad7bef038d8ef1f37279b79', '/var/lib/rancher/k3s/agent/images/quiz-2026.10.14-reader-17be4ce.tar': 'ee77b4ccd5b9e05668e7759b8399c8943825f34181b3b480564d941097443812', '/var/lib/rancher/k3s/agent/images/quiz-2026.10.15-reader-06dfa0b.tar': 'b8bd7bc5fb382f7860ce141d05e467b0b426429e4355212d44b3e50cbda61684', '/var/lib/rancher/k3s/agent/images/quiz-2026.10.15-actors-d204f9b.tar': '04badd8485c8209919fe2a45937da0093f22dcb80fc6b379daa92fbbedcbc501', '/opt/quiz-master/backups/quiz-2026.10.14-library-09b19cc-publish-20261014T223958Z.sqlite': 'c811bcfdc4af694b9f638f6901ba9360c04261bd9def7049049303d9e3d4b291', '/opt/quiz-master/backups/quiz-2026.10.15-reader-06dfa0b-publish-20261015T034437Z.sqlite': '6794975864e19369f7e41188ad98de43244bd34153451d158115210a6e52bd21', '/opt/quiz-master/backups/quiz-2026.10.15-actors-d204f9b-publish-20261015T061630Z.sqlite': '6794975864e19369f7e41188ad98de43244bd34153451d158115210a6e52bd21', '/opt/quiz-master/releases/quiz-2026.10.15-reader291-3482af9.tar.gz': 'd926a276aeb60f2cd7181a2d0322f7ef0b16ec5d32863ab0afe1c6517b2e23ad', '/var/lib/rancher/k3s/agent/images/quiz-2026.10.15-reader291-3482af9.tar': 'e20d542615a12f07883b828dc166170948817dc723f5da7686ce63aa9b22400b', '/opt/quiz-master/backups/quiz-2026.10.15-reader291-3482af9-cutover-20261015T084302Z.sqlite': '6794975864e19369f7e41188ad98de43244bd34153451d158115210a6e52bd21', '/opt/quiz-master/releases/quiz-2026.10.15-reader291-3482af9/quiz-2026.10.15-reader291-3482af9-cutover-20261015T084302Z-values.yaml': '53f77283f65b00387ec3d3f7fe30a278e5c2a324d27506fa976ab14861cd3f7f', '/opt/quiz-master/releases/quiz-2026.10.15-reader291-3482af9/quiz-2026.10.15-reader291-3482af9-cutover-20261015T084302Z-rendered.yaml': '61194251e41088773f5e2b3da7b448d074f5a69f6caeb4343cb9a049d7824b98', '/opt/quiz-master/backups/quiz-2026.10.15-reader291-3482af9-publish-20261015T093511Z.sqlite': '6794975864e19369f7e41188ad98de43244bd34153451d158115210a6e52bd21'}.items():
 p=Path(text);assert p.is_file() and not p.is_symlink()
 with p.open('rb') as stream:assert hashlib.file_digest(stream,'sha256').hexdigest()==expected
print(json.dumps({'protected_files_verified':len({'/opt/quiz-master/releases/quiz-2026.10.14-library-09b19cc.tar.gz': '7d9d6c64763a64b811d942a9df3cdc489a4fc39a11ac8d628165e0636649791f', '/opt/quiz-master/releases/quiz-2026.10.14-reader-17be4ce.tar.gz': 'a67c8afa9d18dfe67c4651f50a84c0337998150d5236e9babfed551a212cfb6a', '/opt/quiz-master/releases/quiz-2026.10.15-reader-06dfa0b.tar.gz': '6ddd12317732d0fa5bf87f8a80ff24e7ef71b50a233d7d65fa4249421a6c79ab', '/opt/quiz-master/releases/quiz-2026.10.15-actors-d204f9b.tar.gz': '5ab6a34ea49b4078d952a311cf5468999b4b696108d1b4b6d6c285b3b74e04a2', '/var/lib/rancher/k3s/agent/images/quiz-2026.10.14-library-09b19cc.tar': '7d4566aab0df18b6a879ac94115e5b146ebcc1252ad7bef038d8ef1f37279b79', '/var/lib/rancher/k3s/agent/images/quiz-2026.10.14-reader-17be4ce.tar': 'ee77b4ccd5b9e05668e7759b8399c8943825f34181b3b480564d941097443812', '/var/lib/rancher/k3s/agent/images/quiz-2026.10.15-reader-06dfa0b.tar': 'b8bd7bc5fb382f7860ce141d05e467b0b426429e4355212d44b3e50cbda61684', '/var/lib/rancher/k3s/agent/images/quiz-2026.10.15-actors-d204f9b.tar': '04badd8485c8209919fe2a45937da0093f22dcb80fc6b379daa92fbbedcbc501', '/opt/quiz-master/backups/quiz-2026.10.14-library-09b19cc-publish-20261014T223958Z.sqlite': 'c811bcfdc4af694b9f638f6901ba9360c04261bd9def7049049303d9e3d4b291', '/opt/quiz-master/backups/quiz-2026.10.15-reader-06dfa0b-publish-20261015T034437Z.sqlite': '6794975864e19369f7e41188ad98de43244bd34153451d158115210a6e52bd21', '/opt/quiz-master/backups/quiz-2026.10.15-actors-d204f9b-publish-20261015T061630Z.sqlite': '6794975864e19369f7e41188ad98de43244bd34153451d158115210a6e52bd21', '/opt/quiz-master/releases/quiz-2026.10.15-reader291-3482af9.tar.gz': 'd926a276aeb60f2cd7181a2d0322f7ef0b16ec5d32863ab0afe1c6517b2e23ad', '/var/lib/rancher/k3s/agent/images/quiz-2026.10.15-reader291-3482af9.tar': 'e20d542615a12f07883b828dc166170948817dc723f5da7686ce63aa9b22400b', '/opt/quiz-master/backups/quiz-2026.10.15-reader291-3482af9-cutover-20261015T084302Z.sqlite': '6794975864e19369f7e41188ad98de43244bd34153451d158115210a6e52bd21', '/opt/quiz-master/releases/quiz-2026.10.15-reader291-3482af9/quiz-2026.10.15-reader291-3482af9-cutover-20261015T084302Z-values.yaml': '53f77283f65b00387ec3d3f7fe30a278e5c2a324d27506fa976ab14861cd3f7f', '/opt/quiz-master/releases/quiz-2026.10.15-reader291-3482af9/quiz-2026.10.15-reader291-3482af9-cutover-20261015T084302Z-rendered.yaml': '61194251e41088773f5e2b3da7b448d074f5a69f6caeb4343cb9a049d7824b98', '/opt/quiz-master/backups/quiz-2026.10.15-reader291-3482af9-publish-20261015T093511Z.sqlite': '6794975864e19369f7e41188ad98de43244bd34153451d158115210a6e52bd21'})}))
def inv(command):
 rows=sorted(subprocess.check_output(command,text=True).splitlines());return {'count':len(rows),'sha256':hashlib.sha256(('\n'.join(rows)+'\n').encode()).hexdigest()}
actual={'containerd':inv(['k3s','ctr','images','list','-q']),'docker':inv(['docker','image','ls','--no-trunc','--format','{{.Repository}}:{{.Tag}} {{.ID}}'])};assert actual=={'containerd': {'count': 203, 'sha256': '44b389b4240d984975f247016fa66afbc6fd44b8865681575b25de2ec9550665'}, 'docker': {'count': 48, 'sha256': '5d89c6bb3ed71d9ea73cdc540943b0d0aafd525d54b5d5a2a8a79a2bdc806839'}}
print(json.dumps({'loaded_image_inventories_unchanged':actual}))

PY
python3 - <<'PY'
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
PATTERN = re.compile(r'quiz-2026[.]10[.](0[2-9]|1[0-4])-[a-z0-9-]+-[0-9a-f]{7}[.]tar')


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


def remove_verified(entries, root=Path(str(ROOT))):
    assert entries and len({e['path'] for e in entries}) == len(entries)
    root = Path(root)
    assert root.is_dir() and not root.is_symlink() and root.resolve() == root.absolute()
    # Validate every file before removing any, then recheck at each unlink.
    for entry in entries:
        verify(entry, root)
    removed = []
    for entry in entries:
        path = verify(entry, root)
        path.unlink()
        removed.append(entry['path'])
        print(json.dumps({'removed': entry['path'], 'bytes': entry['size']}), flush=True)
    return removed

entries=[{'path': '/var/lib/rancher/k3s/agent/images/quiz-2026.10.12-singers-1c9b534.tar', 'size': 73764352, 'dev': 64770, 'ino': 1310785, 'mtime_ns': 1791776425227602368, 'sha256': 'fbf1621337caf9f693969962a074094a1834c9fb7d57795df9bd4579e9539b9c'}, {'path': '/var/lib/rancher/k3s/agent/images/quiz-2026.10.13-culture-384d798.tar', 'size': 73974272, 'dev': 64770, 'ino': 1310790, 'mtime_ns': 1791844002745372538, 'sha256': '23ff0eee496efea8d035747404037f297f058689592e01af62bf646d9bbf081b'}, {'path': '/var/lib/rancher/k3s/agent/images/quiz-2026.10.13-culture-328f2f8.tar', 'size': 73980416, 'dev': 64770, 'ino': 1310792, 'mtime_ns': 1791861738918033108, 'sha256': '522ce6ecb54d72151d7d3d117fdb818e790652d32ad525a1f3a73831969713a6'}, {'path': '/var/lib/rancher/k3s/agent/images/quiz-2026.10.13-culture-e437661.tar', 'size': 73999872, 'dev': 64770, 'ino': 1310793, 'mtime_ns': 1791869516718120965, 'sha256': '5012c719535e6e44b93555227c42c1c7ef40780a9fc03ca354148a12e96e54a3'}, {'path': '/var/lib/rancher/k3s/agent/images/quiz-2026.10.13-article-only-ffa2716.tar', 'size': 74004480, 'dev': 64770, 'ino': 1310795, 'mtime_ns': 1791900779931523311, 'sha256': 'f439c49cf2fcb8b9de7cdb585b2343eb356d334ac6bab37b9ab3c4b1e61a45a2'}, {'path': '/var/lib/rancher/k3s/agent/images/quiz-2026.10.13-film-craft-adf95a5.tar', 'size': 74014720, 'dev': 64770, 'ino': 1310796, 'mtime_ns': 1791914733041683199, 'sha256': 'a9a674a644d3ba2955210673e01e401fa9cdfd541a6f6d8aa6986c2d73eccbf3'}, {'path': '/var/lib/rancher/k3s/agent/images/quiz-2026.10.13-music-craft-f79555e.tar', 'size': 74023936, 'dev': 64770, 'ino': 1310797, 'mtime_ns': 1791924244652190471, 'sha256': '14a5d5badcbcb6f927eae44bb6a1c266353294a32843b84ec3d9359dfa503cf6'}, {'path': '/var/lib/rancher/k3s/agent/images/quiz-2026.10.14-acting-craft-83748f5.tar', 'size': 74039296, 'dev': 64770, 'ino': 1310798, 'mtime_ns': 1791932985292592548, 'sha256': 'ae11582ea734404812c250ef044ccb51dc2e35f49263d88d1a42285c409dab35'}, {'path': '/var/lib/rancher/k3s/agent/images/quiz-2026.10.14-screen-song-6866608.tar', 'size': 74048512, 'dev': 64770, 'ino': 1310800, 'mtime_ns': 1791946145303908321, 'sha256': 'df721bb780a7d4253dd6c5fa529cf2c1a389ae2c95b7794cb3145bff0a03dacb'}, {'path': '/var/lib/rancher/k3s/agent/images/quiz-2026.10.14-mixed-ecac092.tar', 'size': 74073088, 'dev': 64770, 'ino': 1310740, 'mtime_ns': 1791978528279431160, 'sha256': 'ee7c913e5b75764452488f39b18ce3b2d0e34bf0767070112c2e979dcf666d68'}]
remove_verified(entries)
from pathlib import Path
import hashlib,json,subprocess
for text,expected in {'/opt/quiz-master/releases/quiz-2026.10.14-library-09b19cc.tar.gz': '7d9d6c64763a64b811d942a9df3cdc489a4fc39a11ac8d628165e0636649791f', '/opt/quiz-master/releases/quiz-2026.10.14-reader-17be4ce.tar.gz': 'a67c8afa9d18dfe67c4651f50a84c0337998150d5236e9babfed551a212cfb6a', '/opt/quiz-master/releases/quiz-2026.10.15-reader-06dfa0b.tar.gz': '6ddd12317732d0fa5bf87f8a80ff24e7ef71b50a233d7d65fa4249421a6c79ab', '/opt/quiz-master/releases/quiz-2026.10.15-actors-d204f9b.tar.gz': '5ab6a34ea49b4078d952a311cf5468999b4b696108d1b4b6d6c285b3b74e04a2', '/var/lib/rancher/k3s/agent/images/quiz-2026.10.14-library-09b19cc.tar': '7d4566aab0df18b6a879ac94115e5b146ebcc1252ad7bef038d8ef1f37279b79', '/var/lib/rancher/k3s/agent/images/quiz-2026.10.14-reader-17be4ce.tar': 'ee77b4ccd5b9e05668e7759b8399c8943825f34181b3b480564d941097443812', '/var/lib/rancher/k3s/agent/images/quiz-2026.10.15-reader-06dfa0b.tar': 'b8bd7bc5fb382f7860ce141d05e467b0b426429e4355212d44b3e50cbda61684', '/var/lib/rancher/k3s/agent/images/quiz-2026.10.15-actors-d204f9b.tar': '04badd8485c8209919fe2a45937da0093f22dcb80fc6b379daa92fbbedcbc501', '/opt/quiz-master/backups/quiz-2026.10.14-library-09b19cc-publish-20261014T223958Z.sqlite': 'c811bcfdc4af694b9f638f6901ba9360c04261bd9def7049049303d9e3d4b291', '/opt/quiz-master/backups/quiz-2026.10.15-reader-06dfa0b-publish-20261015T034437Z.sqlite': '6794975864e19369f7e41188ad98de43244bd34153451d158115210a6e52bd21', '/opt/quiz-master/backups/quiz-2026.10.15-actors-d204f9b-publish-20261015T061630Z.sqlite': '6794975864e19369f7e41188ad98de43244bd34153451d158115210a6e52bd21', '/opt/quiz-master/releases/quiz-2026.10.15-reader291-3482af9.tar.gz': 'd926a276aeb60f2cd7181a2d0322f7ef0b16ec5d32863ab0afe1c6517b2e23ad', '/var/lib/rancher/k3s/agent/images/quiz-2026.10.15-reader291-3482af9.tar': 'e20d542615a12f07883b828dc166170948817dc723f5da7686ce63aa9b22400b', '/opt/quiz-master/backups/quiz-2026.10.15-reader291-3482af9-cutover-20261015T084302Z.sqlite': '6794975864e19369f7e41188ad98de43244bd34153451d158115210a6e52bd21', '/opt/quiz-master/releases/quiz-2026.10.15-reader291-3482af9/quiz-2026.10.15-reader291-3482af9-cutover-20261015T084302Z-values.yaml': '53f77283f65b00387ec3d3f7fe30a278e5c2a324d27506fa976ab14861cd3f7f', '/opt/quiz-master/releases/quiz-2026.10.15-reader291-3482af9/quiz-2026.10.15-reader291-3482af9-cutover-20261015T084302Z-rendered.yaml': '61194251e41088773f5e2b3da7b448d074f5a69f6caeb4343cb9a049d7824b98', '/opt/quiz-master/backups/quiz-2026.10.15-reader291-3482af9-publish-20261015T093511Z.sqlite': '6794975864e19369f7e41188ad98de43244bd34153451d158115210a6e52bd21'}.items():
 p=Path(text);assert p.is_file() and not p.is_symlink()
 with p.open('rb') as stream:assert hashlib.file_digest(stream,'sha256').hexdigest()==expected
print(json.dumps({'protected_files_verified':len({'/opt/quiz-master/releases/quiz-2026.10.14-library-09b19cc.tar.gz': '7d9d6c64763a64b811d942a9df3cdc489a4fc39a11ac8d628165e0636649791f', '/opt/quiz-master/releases/quiz-2026.10.14-reader-17be4ce.tar.gz': 'a67c8afa9d18dfe67c4651f50a84c0337998150d5236e9babfed551a212cfb6a', '/opt/quiz-master/releases/quiz-2026.10.15-reader-06dfa0b.tar.gz': '6ddd12317732d0fa5bf87f8a80ff24e7ef71b50a233d7d65fa4249421a6c79ab', '/opt/quiz-master/releases/quiz-2026.10.15-actors-d204f9b.tar.gz': '5ab6a34ea49b4078d952a311cf5468999b4b696108d1b4b6d6c285b3b74e04a2', '/var/lib/rancher/k3s/agent/images/quiz-2026.10.14-library-09b19cc.tar': '7d4566aab0df18b6a879ac94115e5b146ebcc1252ad7bef038d8ef1f37279b79', '/var/lib/rancher/k3s/agent/images/quiz-2026.10.14-reader-17be4ce.tar': 'ee77b4ccd5b9e05668e7759b8399c8943825f34181b3b480564d941097443812', '/var/lib/rancher/k3s/agent/images/quiz-2026.10.15-reader-06dfa0b.tar': 'b8bd7bc5fb382f7860ce141d05e467b0b426429e4355212d44b3e50cbda61684', '/var/lib/rancher/k3s/agent/images/quiz-2026.10.15-actors-d204f9b.tar': '04badd8485c8209919fe2a45937da0093f22dcb80fc6b379daa92fbbedcbc501', '/opt/quiz-master/backups/quiz-2026.10.14-library-09b19cc-publish-20261014T223958Z.sqlite': 'c811bcfdc4af694b9f638f6901ba9360c04261bd9def7049049303d9e3d4b291', '/opt/quiz-master/backups/quiz-2026.10.15-reader-06dfa0b-publish-20261015T034437Z.sqlite': '6794975864e19369f7e41188ad98de43244bd34153451d158115210a6e52bd21', '/opt/quiz-master/backups/quiz-2026.10.15-actors-d204f9b-publish-20261015T061630Z.sqlite': '6794975864e19369f7e41188ad98de43244bd34153451d158115210a6e52bd21', '/opt/quiz-master/releases/quiz-2026.10.15-reader291-3482af9.tar.gz': 'd926a276aeb60f2cd7181a2d0322f7ef0b16ec5d32863ab0afe1c6517b2e23ad', '/var/lib/rancher/k3s/agent/images/quiz-2026.10.15-reader291-3482af9.tar': 'e20d542615a12f07883b828dc166170948817dc723f5da7686ce63aa9b22400b', '/opt/quiz-master/backups/quiz-2026.10.15-reader291-3482af9-cutover-20261015T084302Z.sqlite': '6794975864e19369f7e41188ad98de43244bd34153451d158115210a6e52bd21', '/opt/quiz-master/releases/quiz-2026.10.15-reader291-3482af9/quiz-2026.10.15-reader291-3482af9-cutover-20261015T084302Z-values.yaml': '53f77283f65b00387ec3d3f7fe30a278e5c2a324d27506fa976ab14861cd3f7f', '/opt/quiz-master/releases/quiz-2026.10.15-reader291-3482af9/quiz-2026.10.15-reader291-3482af9-cutover-20261015T084302Z-rendered.yaml': '61194251e41088773f5e2b3da7b448d074f5a69f6caeb4343cb9a049d7824b98', '/opt/quiz-master/backups/quiz-2026.10.15-reader291-3482af9-publish-20261015T093511Z.sqlite': '6794975864e19369f7e41188ad98de43244bd34153451d158115210a6e52bd21'})}))
def inv(command):
 rows=sorted(subprocess.check_output(command,text=True).splitlines());return {'count':len(rows),'sha256':hashlib.sha256(('\n'.join(rows)+'\n').encode()).hexdigest()}
actual={'containerd':inv(['k3s','ctr','images','list','-q']),'docker':inv(['docker','image','ls','--no-trunc','--format','{{.Repository}}:{{.Tag}} {{.ID}}'])};assert actual=={'containerd': {'count': 203, 'sha256': '44b389b4240d984975f247016fa66afbc6fd44b8865681575b25de2ec9550665'}, 'docker': {'count': 48, 'sha256': '5d89c6bb3ed71d9ea73cdc540943b0d0aafd525d54b5d5a2a8a79a2bdc806839'}}
print(json.dumps({'loaded_image_inventories_unchanged':actual}))

PY
set -euo pipefail
test "$(hostname)" = racknerd-f0269d5
python3 - <<'PY'
import json,subprocess,sqlite3,hashlib,os
h=json.loads(subprocess.check_output(['helm','status','quiz-master','-n','quiz-master','-o','json']))
x=json.loads(subprocess.check_output(['kubectl','get','deploy','quiz-master','-n','quiz-master','-o','json']))
p=json.loads(subprocess.check_output(['kubectl','get','pvc','quiz-data','-n','quiz-master','-o','json']))
assert h['version']==61 and h['info']['status']=='deployed'
images=[c['image'] for c in x['spec']['template']['spec']['containers']];assert len(images)==2 and set(images)=={'docker.io/library/quiz-master@sha256:0f24677d8e499df9d21e80ce1dd50b8e830b37608c4c86e1c38e76ccc30d3228'}
assert x['status'].get('availableReplicas')==1 and p['metadata']['uid']=='7fc2428f-4146-4c78-a26d-2347d9f3b7bf'
import urllib.request
nodes=json.loads(subprocess.check_output(['kubectl','get','nodes','-o','json']))['items'];assert len(nodes)==1
node=nodes[0];conditions={c['type']:c['status'] for c in node['status']['conditions']};assert conditions['Ready']=='True' and conditions['DiskPressure']=='False';assert not any(t['effect'] in ['NoSchedule','NoExecute'] for t in node['spec'].get('taints',[]))
st=os.statvfs('/var/lib/rancher/k3s');available=st.f_bavail*st.f_frsize;total=st.f_blocks*st.f_frsize;assert available>0
with urllib.request.urlopen('https://quiz.kotopedia.org/health/ready',timeout=15) as ready:assert ready.status==200
print(json.dumps({'node_ready':True,'disk_pressure':False,'blocking_taints':False,'disk_available':available,'disk_total':total,'disk_at_least20percent':available*5>=total,'https_readiness_status':200}))
db=sqlite3.connect('file:/var/lib/rancher/k3s/storage/pvc-7fc2428f-4146-4c78-a26d-2347d9f3b7bf_quiz-master_quiz-data/quiz.db?mode=ro',uri=True)
rows=db.execute('select * from feedback_reports order by rowid').fetchall();sha=hashlib.sha256(json.dumps(rows,ensure_ascii=False,default=str).encode()).hexdigest();assert sha=='452929a2ea8dc34600eff8039571e2b0479ec7ad1ec52fa6e271b5c71008030e'
b='/opt/quiz-master/backups/quiz-2026.10.15-reader291-3482af9-publish-20261015T093511Z.sqlite';assert os.stat(b).st_mode & 0o777 == 0o600
backup=sqlite3.connect('file:'+b+'?mode=ro',uri=True);assert backup.execute('pragma integrity_check').fetchone()[0]=='ok'
print(json.dumps({'helm_revision':61,'status':'deployed','images':images,'available_replicas':1,'pvc_uid':p['metadata']['uid'],'feedback_count':len(rows),'all_open':db.execute("select count(*) from feedback_reports where status='open'").fetchone()[0]==29,'feedback_sha256':sha,'backup_mode':'0600','backup_integrity':'ok'}))
PY
