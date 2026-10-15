set -euo pipefail
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
assert h['version']==60 and h['info']['status']=='deployed'
images=[c['image'] for c in x['spec']['template']['spec']['containers']];assert len(images)==2 and set(images)=={'docker.io/library/quiz-master@sha256:c4b5ba6564678b986bc74cb59b3d660e14bfc733a5633eab83c8d47cbffa4922'}
assert x['status'].get('availableReplicas')==1 and p['metadata']['uid']=='7fc2428f-4146-4c78-a26d-2347d9f3b7bf'
import urllib.request
nodes=json.loads(subprocess.check_output(['kubectl','get','nodes','-o','json']))['items'];assert len(nodes)==1
node=nodes[0];conditions={c['type']:c['status'] for c in node['status']['conditions']};assert conditions['Ready']=='True' and conditions['DiskPressure']=='False';assert not any(t['effect'] in ['NoSchedule','NoExecute'] for t in node['spec'].get('taints',[]))
st=os.statvfs('/var/lib/rancher/k3s');available=st.f_bavail*st.f_frsize;total=st.f_blocks*st.f_frsize
with urllib.request.urlopen('https://quiz.kotopedia.org/health/ready',timeout=15) as ready:assert ready.status==200
print(json.dumps({'node_ready':True,'disk_pressure':False,'blocking_taints':False,'disk_available':available,'disk_total':total,'disk_at_least20percent':available*5>=total,'https_readiness_status':200}))
db=sqlite3.connect('file:/var/lib/rancher/k3s/storage/pvc-7fc2428f-4146-4c78-a26d-2347d9f3b7bf_quiz-master_quiz-data/quiz.db?mode=ro',uri=True)
rows=db.execute('select * from feedback_reports order by rowid').fetchall();sha=hashlib.sha256(json.dumps(rows,ensure_ascii=False,default=str).encode()).hexdigest();assert sha=='452929a2ea8dc34600eff8039571e2b0479ec7ad1ec52fa6e271b5c71008030e'
b='/opt/quiz-master/backups/quiz-2026.10.15-actors-d204f9b-publish-20261015T061630Z.sqlite';assert os.stat(b).st_mode & 0o777 == 0o600
backup=sqlite3.connect('file:'+b+'?mode=ro',uri=True);assert backup.execute('pragma integrity_check').fetchone()[0]=='ok'
print(json.dumps({'helm_revision':60,'status':'deployed','images':images,'available_replicas':1,'pvc_uid':p['metadata']['uid'],'feedback_count':len(rows),'all_open':db.execute("select count(*) from feedback_reports where status='open'").fetchone()[0]==29,'feedback_sha256':sha,'backup_mode':'0600','backup_integrity':'ok'}))
PY
python3 - <<'PY'
from pathlib import Path
import hashlib,json
result={}
for text in ['/opt/quiz-master/releases/quiz-2026.10.14-library-09b19cc.tar.gz', '/opt/quiz-master/releases/quiz-2026.10.14-reader-17be4ce.tar.gz', '/opt/quiz-master/releases/quiz-2026.10.15-reader-06dfa0b.tar.gz', '/opt/quiz-master/releases/quiz-2026.10.15-actors-d204f9b.tar.gz', '/var/lib/rancher/k3s/agent/images/quiz-2026.10.14-library-09b19cc.tar', '/var/lib/rancher/k3s/agent/images/quiz-2026.10.14-reader-17be4ce.tar', '/var/lib/rancher/k3s/agent/images/quiz-2026.10.15-reader-06dfa0b.tar', '/var/lib/rancher/k3s/agent/images/quiz-2026.10.15-actors-d204f9b.tar', '/opt/quiz-master/backups/quiz-2026.10.14-library-09b19cc-publish-20261014T223958Z.sqlite', '/opt/quiz-master/backups/quiz-2026.10.15-reader-06dfa0b-publish-20261015T034437Z.sqlite', '/opt/quiz-master/backups/quiz-2026.10.15-actors-d204f9b-publish-20261015T061630Z.sqlite']:
 p=Path(text);assert p.is_file() and not p.is_symlink()
 h=hashlib.sha256()
 with p.open('rb') as stream:
  for chunk in iter(lambda:stream.read(1024*1024),b''):h.update(chunk)
 result[text]=h.hexdigest()
assert result == {'/opt/quiz-master/releases/quiz-2026.10.14-library-09b19cc.tar.gz': '7d9d6c64763a64b811d942a9df3cdc489a4fc39a11ac8d628165e0636649791f', '/opt/quiz-master/releases/quiz-2026.10.14-reader-17be4ce.tar.gz': 'a67c8afa9d18dfe67c4651f50a84c0337998150d5236e9babfed551a212cfb6a', '/opt/quiz-master/releases/quiz-2026.10.15-reader-06dfa0b.tar.gz': '6ddd12317732d0fa5bf87f8a80ff24e7ef71b50a233d7d65fa4249421a6c79ab', '/opt/quiz-master/releases/quiz-2026.10.15-actors-d204f9b.tar.gz': '5ab6a34ea49b4078d952a311cf5468999b4b696108d1b4b6d6c285b3b74e04a2', '/var/lib/rancher/k3s/agent/images/quiz-2026.10.14-library-09b19cc.tar': '7d4566aab0df18b6a879ac94115e5b146ebcc1252ad7bef038d8ef1f37279b79', '/var/lib/rancher/k3s/agent/images/quiz-2026.10.14-reader-17be4ce.tar': 'ee77b4ccd5b9e05668e7759b8399c8943825f34181b3b480564d941097443812', '/var/lib/rancher/k3s/agent/images/quiz-2026.10.15-reader-06dfa0b.tar': 'b8bd7bc5fb382f7860ce141d05e467b0b426429e4355212d44b3e50cbda61684', '/var/lib/rancher/k3s/agent/images/quiz-2026.10.15-actors-d204f9b.tar': '04badd8485c8209919fe2a45937da0093f22dcb80fc6b379daa92fbbedcbc501', '/opt/quiz-master/backups/quiz-2026.10.14-library-09b19cc-publish-20261014T223958Z.sqlite': 'c811bcfdc4af694b9f638f6901ba9360c04261bd9def7049049303d9e3d4b291', '/opt/quiz-master/backups/quiz-2026.10.15-reader-06dfa0b-publish-20261015T034437Z.sqlite': '6794975864e19369f7e41188ad98de43244bd34153451d158115210a6e52bd21', '/opt/quiz-master/backups/quiz-2026.10.15-actors-d204f9b-publish-20261015T061630Z.sqlite': '6794975864e19369f7e41188ad98de43244bd34153451d158115210a6e52bd21'}
print(json.dumps({'protected_files_verified':len(result)}))

PY
python3 - <<'PY'
"""Unlink only frozen, hash-verified old package files after off-server copying."""
from pathlib import Path, PurePosixPath
import hashlib
import json
import os
import re
import stat

ROOT = PurePosixPath('/opt/quiz-master/releases')
PROTECTED = {
    'quiz-2026.10.14-library-09b19cc.tar.gz',
    'quiz-2026.10.14-reader-17be4ce.tar.gz',
    'quiz-2026.10.15-reader-06dfa0b.tar.gz',
    'quiz-2026.10.15-actors-d204f9b.tar.gz',
}
PATTERN = re.compile(r'quiz-2026[.]10[.](0[2-9]|1[0-4])-[a-z0-9-]+-[0-9a-f]{7}[.]tar[.]gz')


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

entries=[{'path': '/opt/quiz-master/releases/quiz-2026.10.03-capitals-ebab492.tar.gz', 'size': 21513259, 'sha256': 'd2b0e5c785e93ea3dd57852419966d1d7d2757aadec5bf9f67dcc06f89b2abb8', 'dev': 64770, 'ino': 400240, 'mtime_ns': 1791002751510256436}, {'path': '/opt/quiz-master/releases/quiz-2026.10.04-study-5536e77.tar.gz', 'size': 28347353, 'sha256': 'b1b40f560b644e44df48ef9dda8f9e1dc638e41f2903cc88b20a3c48fd86531b', 'dev': 64770, 'ino': 401978, 'mtime_ns': 1791080389748903231}, {'path': '/opt/quiz-master/releases/quiz-2026.10.04-thematic-61b47ea.tar.gz', 'size': 39683215, 'sha256': 'aa87d3775d0ccec057cce185b584ac7072481d055b07dc21bbe26cc68ed16937', 'dev': 64770, 'ino': 441910, 'mtime_ns': 1791140026605805125}, {'path': '/opt/quiz-master/releases/quiz-2026.10.05-quizipedia-486df89.tar.gz', 'size': 40941495, 'sha256': '2f820588291349228990f758c5dba7e5756223ac73d8b2280b1fe3a06d5313db', 'dev': 64770, 'ino': 445272, 'mtime_ns': 1791203928124394777}, {'path': '/opt/quiz-master/releases/quiz-2026.10.06-feedback-e0f89cf.tar.gz', 'size': 41106483, 'sha256': '589f1e9f674ffc9b865e59c416a8d98d9174624af7e7e8d6745064f744208f06', 'dev': 64770, 'ino': 446327, 'mtime_ns': 1791276591952303167}, {'path': '/opt/quiz-master/releases/quiz-2026.10.07-articles-30702d1.tar.gz', 'size': 41170577, 'sha256': '7ba6aa5644d6a6e23bab4481e8cd0a4932b898c9cf3932791fb6bb9004abfd95', 'dev': 64770, 'ino': 446736, 'mtime_ns': 1791395228648857278}, {'path': '/opt/quiz-master/releases/quiz-2026.10.09-articles-f57191b.tar.gz', 'size': 41205981, 'sha256': '44c6f3e5b2a554f2f88683c7a6759cc95382f9d8035355a63803e37a86d16232', 'dev': 64770, 'ino': 395308, 'mtime_ns': 1791503740600266458}, {'path': '/opt/quiz-master/releases/quiz-2026.10.10-articles-3ec0a33.tar.gz', 'size': 47280752, 'sha256': '42795a0f2d9d17beb08cc9c8a3ee77d4393e02b26f94a37d5423bde93acdedb6', 'dev': 64770, 'ino': 394037, 'mtime_ns': 1791664001917527513}, {'path': '/opt/quiz-master/releases/quiz-2026.10.11-culture-2e3516f.tar.gz', 'size': 47306841, 'sha256': '14e78f3e4a9e13517e65a40ee9f6c848bfc9a3f216d00f69cf072bacdfbc86ce', 'dev': 64770, 'ino': 413741, 'mtime_ns': 1791668658354720264}, {'path': '/opt/quiz-master/releases/quiz-2026.10.11-culture-486901a.tar.gz', 'size': 47307396, 'sha256': '879a80993320b260467721cb711901efa4030098c574256914abe4dd5e00a890', 'dev': 64770, 'ino': 414499, 'mtime_ns': 1791670458197039384}, {'path': '/opt/quiz-master/releases/quiz-2026.10.11-culture-ba80671.tar.gz', 'size': 47307282, 'sha256': 'cc795d7da617649940aec1ad373103e757a34af8c082b265b22f80e5359413db', 'dev': 64770, 'ino': 414122, 'mtime_ns': 1791669397396001482}, {'path': '/opt/quiz-master/releases/quiz-2026.10.11-dedup-ddf47be.tar.gz', 'size': 47351344, 'sha256': '9ce207d74a29a27030333bea9710263432b949d92146bcbdb6ea2425fc53af01', 'dev': 64770, 'ino': 416351, 'mtime_ns': 1791694386550955096}, {'path': '/opt/quiz-master/releases/quiz-2026.10.11-encore-317b339.tar.gz', 'size': 47327903, 'sha256': 'd4a6b6d10c2ad49c92c427898a67b2ee49a4001ec405351578556c6f368842ff', 'dev': 64770, 'ino': 415359, 'mtime_ns': 1791674546185914285}, {'path': '/opt/quiz-master/releases/quiz-2026.10.11-home-alone-e0d13f4.tar.gz', 'size': 47357303, 'sha256': 'db36f7cb6df508f8f8231e492f72481ebc7c87ba29cac5a5db5e694250b8c221', 'dev': 64770, 'ino': 417729, 'mtime_ns': 1791711784753617795}, {'path': '/opt/quiz-master/releases/quiz-2026.10.11-phobias-1537ff5.tar.gz', 'size': 47352199, 'sha256': '6b70777681511e8c27c5d9956240eb11a2679f99127a49c755638fa295224e0f', 'dev': 64770, 'ino': 417150, 'mtime_ns': 1791698036093613390}, {'path': '/opt/quiz-master/releases/quiz-2026.10.11-planets-d228c9e.tar.gz', 'size': 47338345, 'sha256': '309498227e1374d3f3e82a28081cca25643d9721668de195534ad0ca9f800bad', 'dev': 64770, 'ino': 415961, 'mtime_ns': 1791686360208454397}, {'path': '/opt/quiz-master/releases/quiz-2026.10.12-actors-3556b59.tar.gz', 'size': 47363548, 'sha256': 'fd206f196cacda844bf662d99c8816ae9c6e915d556990b6c9c2336e1ddee747', 'dev': 64770, 'ino': 418385, 'mtime_ns': 1791767052072582662}, {'path': '/opt/quiz-master/releases/quiz-2026.10.12-culture-42a2aaf.tar.gz', 'size': 47597654, 'sha256': '83ab67928dbe0ee0cad02b5a570d4131f07a1b60c7b75a9fa3713dd76960059b', 'dev': 64770, 'ino': 397523, 'mtime_ns': 1791817631411473212}, {'path': '/opt/quiz-master/releases/quiz-2026.10.12-culture-7d7a163.tar.gz', 'size': 47551335, 'sha256': '963506713317c279bb1b4490b4f52eee59d68445cc8526ac99c7d3d10179af66', 'dev': 64770, 'ino': 419812, 'mtime_ns': 1791791166750039871}, {'path': '/opt/quiz-master/releases/quiz-2026.10.12-culture-939f231.tar.gz', 'size': 47962385, 'sha256': 'ffd22dea3d6263f35d474f840ec3d0e3448c46b815e27fe1ded8fe0d439b7d78', 'dev': 64770, 'ino': 418360, 'mtime_ns': 1791810376399947584}, {'path': '/opt/quiz-master/releases/quiz-2026.10.12-culture-c15eefc.tar.gz', 'size': 47959863, 'sha256': '07381d7486878f7b50ad063957ba8ba4292caf5190db6847797b17b027ad1f25', 'dev': 64770, 'ino': 419881, 'mtime_ns': 1791797759675698638}, {'path': '/opt/quiz-master/releases/quiz-2026.10.12-culture-f219916.tar.gz', 'size': 47471256, 'sha256': '67b6872578b85f94b5cc9718ff98c129817bb412ecc6d79d03932d2127ec7007', 'dev': 64770, 'ino': 397718, 'mtime_ns': 1791832110835166164}, {'path': '/opt/quiz-master/releases/quiz-2026.10.12-culture-variety-b015251.tar.gz', 'size': 47362086, 'sha256': '722a6ba1085824a2537c297be0792204a7c49c624fb346a108bd7b4d9ee966af', 'dev': 64770, 'ino': 413430, 'mtime_ns': 1791760391102811601}, {'path': '/opt/quiz-master/releases/quiz-2026.10.12-reader-4207ef5.tar.gz', 'size': 47959821, 'sha256': '829bceeb809bd7d53da62de2088c2587afc52aa1e8ccc1cea1a9a4455496dc76', 'dev': 64770, 'ino': 419886, 'mtime_ns': 1791800549462722409}, {'path': '/opt/quiz-master/releases/quiz-2026.10.12-singers-1c9b534.tar.gz', 'size': 47365362, 'sha256': '498bda87b62d86b8bb731a75532a0592edd88fe91d99873f84e575bfcfb3372f', 'dev': 64770, 'ino': 419802, 'mtime_ns': 1791776367678400963}, {'path': '/opt/quiz-master/releases/quiz-2026.10.13-article-only-ffa2716.tar.gz', 'size': 47519395, 'sha256': '009e3c09fb72d82ddc9775b31e2774bc21f39da157607ba78732abb61eda7bf5', 'dev': 64770, 'ino': 419178, 'mtime_ns': 1791900718001326767}, {'path': '/opt/quiz-master/releases/quiz-2026.10.13-culture-328f2f8.tar.gz', 'size': 47498646, 'sha256': '04ed7163fab6ab61e4d0d7caeaa44175cf12abf146c9d3b660b5333f6cfad79c', 'dev': 64770, 'ino': 417603, 'mtime_ns': 1791859469594969509}, {'path': '/opt/quiz-master/releases/quiz-2026.10.13-culture-384d798.tar.gz', 'size': 47470289, 'sha256': 'f1b89f2d8a77c751dfd968a23b1c67ab791ea1957e7635850e55eb2358933e45', 'dev': 64770, 'ino': 413495, 'mtime_ns': 1791843949345129206}, {'path': '/opt/quiz-master/releases/quiz-2026.10.13-culture-e437661.tar.gz', 'size': 47501653, 'sha256': '10e62998bc6d279c535b6cb860067d7755e934c4f5729505d0839fdd394ec60e', 'dev': 64770, 'ino': 419173, 'mtime_ns': 1791869460492800639}, {'path': '/opt/quiz-master/releases/quiz-2026.10.13-film-craft-adf95a5.tar.gz', 'size': 47520882, 'sha256': '5ed5fdf6a6cbe2d7521544573bee9fc25afdf0053ad6eedd0fff8377e3654c85', 'dev': 64770, 'ino': 419189, 'mtime_ns': 1791914671781467151}, {'path': '/opt/quiz-master/releases/quiz-2026.10.13-film-craft-c74253f.tar.gz', 'size': 47521285, 'sha256': '6c016f7aa708e419af7afef13ccccec4c49e1a8c6806df7f9fa56b82ed25d621', 'dev': 64770, 'ino': 419186, 'mtime_ns': 1791912396734591447}, {'path': '/opt/quiz-master/releases/quiz-2026.10.13-music-craft-f79555e.tar.gz', 'size': 47530821, 'sha256': 'ae4768f4a73d94976066f24bc80dcc31636d449428660706a91154c84930f9f7', 'dev': 64770, 'ino': 419192, 'mtime_ns': 1791924184565033818}, {'path': '/opt/quiz-master/releases/quiz-2026.10.14-acting-craft-83748f5.tar.gz', 'size': 47561714, 'sha256': '9d9fdb8dff8ec88b51c8adcd987a093a3a10150cb7c6f7e667c89f416933c934', 'dev': 64770, 'ino': 419197, 'mtime_ns': 1791932926553411331}, {'path': '/opt/quiz-master/releases/quiz-2026.10.14-mixed-ecac092.tar.gz', 'size': 47675334, 'sha256': 'ede81db6dfa1dfb2c0f61e53d4749d378a8fe00467f87ebb3fda353d161e8ead', 'dev': 64770, 'ino': 394123, 'mtime_ns': 1791978461520398111}, {'path': '/opt/quiz-master/releases/quiz-2026.10.14-screen-song-6866608.tar.gz', 'size': 47584856, 'sha256': '64e50bf9f49bd1287b0964f234cb9545508b878315e8fd577c262dc5c5ade6df', 'dev': 64770, 'ino': 393269, 'mtime_ns': 1791946082847701600}]
assert len(entries)==35 and sum(e['size'] for e in entries)==1583875913
before=os.statvfs('/opt/quiz-master/releases')
removed=remove_verified(entries)
after=os.statvfs('/opt/quiz-master/releases')
print(json.dumps({'removed_count':len(removed),'expected_bytes':1583875913,'available_before':before.f_bavail*before.f_frsize,'available_after':after.f_bavail*after.f_frsize,'release_headroom_ready':after.f_bavail*5>=after.f_blocks and after.f_bavail*after.f_frsize-after.f_blocks*after.f_frsize/5>=1500000000}))
PY
python3 - <<'PY'
from pathlib import Path
import hashlib,json
result={}
for text in ['/opt/quiz-master/releases/quiz-2026.10.14-library-09b19cc.tar.gz', '/opt/quiz-master/releases/quiz-2026.10.14-reader-17be4ce.tar.gz', '/opt/quiz-master/releases/quiz-2026.10.15-reader-06dfa0b.tar.gz', '/opt/quiz-master/releases/quiz-2026.10.15-actors-d204f9b.tar.gz', '/var/lib/rancher/k3s/agent/images/quiz-2026.10.14-library-09b19cc.tar', '/var/lib/rancher/k3s/agent/images/quiz-2026.10.14-reader-17be4ce.tar', '/var/lib/rancher/k3s/agent/images/quiz-2026.10.15-reader-06dfa0b.tar', '/var/lib/rancher/k3s/agent/images/quiz-2026.10.15-actors-d204f9b.tar', '/opt/quiz-master/backups/quiz-2026.10.14-library-09b19cc-publish-20261014T223958Z.sqlite', '/opt/quiz-master/backups/quiz-2026.10.15-reader-06dfa0b-publish-20261015T034437Z.sqlite', '/opt/quiz-master/backups/quiz-2026.10.15-actors-d204f9b-publish-20261015T061630Z.sqlite']:
 p=Path(text);assert p.is_file() and not p.is_symlink()
 h=hashlib.sha256()
 with p.open('rb') as stream:
  for chunk in iter(lambda:stream.read(1024*1024),b''):h.update(chunk)
 result[text]=h.hexdigest()
assert result == {'/opt/quiz-master/releases/quiz-2026.10.14-library-09b19cc.tar.gz': '7d9d6c64763a64b811d942a9df3cdc489a4fc39a11ac8d628165e0636649791f', '/opt/quiz-master/releases/quiz-2026.10.14-reader-17be4ce.tar.gz': 'a67c8afa9d18dfe67c4651f50a84c0337998150d5236e9babfed551a212cfb6a', '/opt/quiz-master/releases/quiz-2026.10.15-reader-06dfa0b.tar.gz': '6ddd12317732d0fa5bf87f8a80ff24e7ef71b50a233d7d65fa4249421a6c79ab', '/opt/quiz-master/releases/quiz-2026.10.15-actors-d204f9b.tar.gz': '5ab6a34ea49b4078d952a311cf5468999b4b696108d1b4b6d6c285b3b74e04a2', '/var/lib/rancher/k3s/agent/images/quiz-2026.10.14-library-09b19cc.tar': '7d4566aab0df18b6a879ac94115e5b146ebcc1252ad7bef038d8ef1f37279b79', '/var/lib/rancher/k3s/agent/images/quiz-2026.10.14-reader-17be4ce.tar': 'ee77b4ccd5b9e05668e7759b8399c8943825f34181b3b480564d941097443812', '/var/lib/rancher/k3s/agent/images/quiz-2026.10.15-reader-06dfa0b.tar': 'b8bd7bc5fb382f7860ce141d05e467b0b426429e4355212d44b3e50cbda61684', '/var/lib/rancher/k3s/agent/images/quiz-2026.10.15-actors-d204f9b.tar': '04badd8485c8209919fe2a45937da0093f22dcb80fc6b379daa92fbbedcbc501', '/opt/quiz-master/backups/quiz-2026.10.14-library-09b19cc-publish-20261014T223958Z.sqlite': 'c811bcfdc4af694b9f638f6901ba9360c04261bd9def7049049303d9e3d4b291', '/opt/quiz-master/backups/quiz-2026.10.15-reader-06dfa0b-publish-20261015T034437Z.sqlite': '6794975864e19369f7e41188ad98de43244bd34153451d158115210a6e52bd21', '/opt/quiz-master/backups/quiz-2026.10.15-actors-d204f9b-publish-20261015T061630Z.sqlite': '6794975864e19369f7e41188ad98de43244bd34153451d158115210a6e52bd21'}
print(json.dumps({'protected_files_verified':len(result)}))

PY
set -euo pipefail
test "$(hostname)" = racknerd-f0269d5
python3 - <<'PY'
import json,subprocess,sqlite3,hashlib,os
h=json.loads(subprocess.check_output(['helm','status','quiz-master','-n','quiz-master','-o','json']))
x=json.loads(subprocess.check_output(['kubectl','get','deploy','quiz-master','-n','quiz-master','-o','json']))
p=json.loads(subprocess.check_output(['kubectl','get','pvc','quiz-data','-n','quiz-master','-o','json']))
assert h['version']==60 and h['info']['status']=='deployed'
images=[c['image'] for c in x['spec']['template']['spec']['containers']];assert len(images)==2 and set(images)=={'docker.io/library/quiz-master@sha256:c4b5ba6564678b986bc74cb59b3d660e14bfc733a5633eab83c8d47cbffa4922'}
assert x['status'].get('availableReplicas')==1 and p['metadata']['uid']=='7fc2428f-4146-4c78-a26d-2347d9f3b7bf'
import urllib.request
nodes=json.loads(subprocess.check_output(['kubectl','get','nodes','-o','json']))['items'];assert len(nodes)==1
node=nodes[0];conditions={c['type']:c['status'] for c in node['status']['conditions']};assert conditions['Ready']=='True' and conditions['DiskPressure']=='False';assert not any(t['effect'] in ['NoSchedule','NoExecute'] for t in node['spec'].get('taints',[]))
st=os.statvfs('/var/lib/rancher/k3s');available=st.f_bavail*st.f_frsize;total=st.f_blocks*st.f_frsize
with urllib.request.urlopen('https://quiz.kotopedia.org/health/ready',timeout=15) as ready:assert ready.status==200
print(json.dumps({'node_ready':True,'disk_pressure':False,'blocking_taints':False,'disk_available':available,'disk_total':total,'disk_at_least20percent':available*5>=total,'https_readiness_status':200}))
db=sqlite3.connect('file:/var/lib/rancher/k3s/storage/pvc-7fc2428f-4146-4c78-a26d-2347d9f3b7bf_quiz-master_quiz-data/quiz.db?mode=ro',uri=True)
rows=db.execute('select * from feedback_reports order by rowid').fetchall();sha=hashlib.sha256(json.dumps(rows,ensure_ascii=False,default=str).encode()).hexdigest();assert sha=='452929a2ea8dc34600eff8039571e2b0479ec7ad1ec52fa6e271b5c71008030e'
b='/opt/quiz-master/backups/quiz-2026.10.15-actors-d204f9b-publish-20261015T061630Z.sqlite';assert os.stat(b).st_mode & 0o777 == 0o600
backup=sqlite3.connect('file:'+b+'?mode=ro',uri=True);assert backup.execute('pragma integrity_check').fetchone()[0]=='ok'
print(json.dumps({'helm_revision':60,'status':'deployed','images':images,'available_replicas':1,'pvc_uid':p['metadata']['uid'],'feedback_count':len(rows),'all_open':db.execute("select count(*) from feedback_reports where status='open'").fetchone()[0]==29,'feedback_sha256':sha,'backup_mode':'0600','backup_integrity':'ok'}))
PY
