set -euo pipefail
unset PYTHONOPTIMIZE PYTHONSTARTUP
test "$(hostname)" = racknerd-f0269d5
exec 8>/opt/quiz-master/DEPLOY.lock
flock -n 8
python3 - <<'READER303_OFFLOAD'
"""Exact28 cold-package offload source; render is inert, execution is Root-only."""
if not __debug__:
    raise RuntimeError('offload refuses optimized Python')
from pathlib import Path,PurePosixPath
import hashlib,json,os,re,stat
ROOT=PurePosixPath('/opt/quiz-master/releases')
GIB=1073741824
GROWTH_LIMIT=67108864
EXPECTED_BYTES=1518083884
EXPECTED_NAMES={'quiz-2026.10.02-2327-5121fbd.recovery-20261015.tar.gz', 'quiz-2026.10.04-lotr-e38bb24.recovery-20261015.tar.gz', 'quiz-2026.10.14-mixed-ecac092-failed-112137.tar.gz', 'quiz-2026.10.14-reader-17be4ce-failed-20261014T153204Z.tar.gz', 'quiz-2026.10.11-phobias-1537ff5.recovery-20261015.tar.gz', 'quiz-2026.10.13-culture-328f2f8-v8.tar.gz', 'quiz-2026.10.12-culture-f219916-v2.tar.gz', 'quiz-2026.10.12-culture-variety-b015251.recovery-20261015.tar.gz', 'quiz-2026.10.12-culture-f219916-v3.tar.gz', 'quiz-2026.10.14-mixed-ecac092-failed-111030.tar.gz', 'quiz-2026.10.14-mixed-ecac092-failed-v4.tar.gz', 'quiz-2026.10.13-culture-328f2f8-v7.tar.gz', 'failed-readiness-quiz-2026.10.11-encore-317b339-20261010T231811Z.tar.gz', 'quiz-2026.10.04-study-3ebba4e.recovery-20261015.tar.gz', 'quiz-2026.10.11-dedup-ddf47be-failed-fixture-aliasing.recovery-20261015.tar.gz', 'quiz-2026.10.12-culture-f219916-v2-02e645a0.recovery-20261015.tar.gz', 'rejected-quiz-2026.10.12-singers-1c9b534-identity-032842.tar.gz', 'quiz-2026.10.02-2308-9359647.recovery-20261015.tar.gz', 'quiz-2026.10.12-culture-7d7a163.recovery-20261015.tar.gz', 'quiz-2026.10.12-singers-1c9b534.recovery-20261015.tar.gz', 'quiz-rounds20.tar.gz', 'quiz-2026.10.13-film-craft-c74253f.recovery-20261015.tar.gz', 'quiz-2026.10.13-film-craft-c74253f.failed-v1-171556Z.tar.gz', 'quiz-2026.10.11-dedup-ddf47be.recovery-20261015.tar.gz', 'quiz-2026.10.12-actors-3556b59.recovery-20261015.tar.gz', 'quiz-2026.10.12-culture-c15eefc.recovery-20261015.tar.gz', 'quiz-2026.10.12-culture-f219916-v1-67b68725.recovery-20261015.tar.gz', 'quiz-2026.10.03-culture260-8c90873.recovery-20261015.tar.gz'}
PROTECTED_HASHES={'/opt/quiz-master/releases/quiz-2026.10.14-library-09b19cc.tar.gz': '7d9d6c64763a64b811d942a9df3cdc489a4fc39a11ac8d628165e0636649791f', '/opt/quiz-master/releases/quiz-2026.10.14-reader-17be4ce.tar.gz': 'a67c8afa9d18dfe67c4651f50a84c0337998150d5236e9babfed551a212cfb6a', '/opt/quiz-master/releases/quiz-2026.10.15-reader-06dfa0b.tar.gz': '6ddd12317732d0fa5bf87f8a80ff24e7ef71b50a233d7d65fa4249421a6c79ab', '/opt/quiz-master/releases/quiz-2026.10.15-actors-d204f9b.tar.gz': '5ab6a34ea49b4078d952a311cf5468999b4b696108d1b4b6d6c285b3b74e04a2', '/var/lib/rancher/k3s/agent/images/quiz-2026.10.14-library-09b19cc.tar': '7d4566aab0df18b6a879ac94115e5b146ebcc1252ad7bef038d8ef1f37279b79', '/var/lib/rancher/k3s/agent/images/quiz-2026.10.14-reader-17be4ce.tar': 'ee77b4ccd5b9e05668e7759b8399c8943825f34181b3b480564d941097443812', '/var/lib/rancher/k3s/agent/images/quiz-2026.10.15-reader-06dfa0b.tar': 'b8bd7bc5fb382f7860ce141d05e467b0b426429e4355212d44b3e50cbda61684', '/var/lib/rancher/k3s/agent/images/quiz-2026.10.15-actors-d204f9b.tar': '04badd8485c8209919fe2a45937da0093f22dcb80fc6b379daa92fbbedcbc501', '/opt/quiz-master/backups/quiz-2026.10.14-library-09b19cc-publish-20261014T223958Z.sqlite': 'c811bcfdc4af694b9f638f6901ba9360c04261bd9def7049049303d9e3d4b291', '/opt/quiz-master/backups/quiz-2026.10.15-reader-06dfa0b-publish-20261015T034437Z.sqlite': '6794975864e19369f7e41188ad98de43244bd34153451d158115210a6e52bd21', '/opt/quiz-master/backups/quiz-2026.10.15-actors-d204f9b-publish-20261015T061630Z.sqlite': '6794975864e19369f7e41188ad98de43244bd34153451d158115210a6e52bd21', '/opt/quiz-master/releases/quiz-2026.10.15-reader291-3482af9.tar.gz': 'd926a276aeb60f2cd7181a2d0322f7ef0b16ec5d32863ab0afe1c6517b2e23ad', '/var/lib/rancher/k3s/agent/images/quiz-2026.10.15-reader291-3482af9.tar': 'e20d542615a12f07883b828dc166170948817dc723f5da7686ce63aa9b22400b', '/opt/quiz-master/backups/quiz-2026.10.15-reader291-3482af9-cutover-20261015T084302Z.sqlite': '6794975864e19369f7e41188ad98de43244bd34153451d158115210a6e52bd21', '/opt/quiz-master/releases/quiz-2026.10.15-reader291-3482af9/quiz-2026.10.15-reader291-3482af9-cutover-20261015T084302Z-values.yaml': '53f77283f65b00387ec3d3f7fe30a278e5c2a324d27506fa976ab14861cd3f7f', '/opt/quiz-master/releases/quiz-2026.10.15-reader291-3482af9/quiz-2026.10.15-reader291-3482af9-cutover-20261015T084302Z-rendered.yaml': '61194251e41088773f5e2b3da7b448d074f5a69f6caeb4343cb9a049d7824b98', '/opt/quiz-master/backups/quiz-2026.10.15-reader291-3482af9-publish-20261015T093511Z.sqlite': '6794975864e19369f7e41188ad98de43244bd34153451d158115210a6e52bd21', '/opt/quiz-master/releases/quiz-2026.10.15-reader299-9c670e9.tar.gz': '01ddc3ee1cd7ef68376ec1dc84c06ad9c8ab88970995715edce3e631a5c7417d', '/opt/quiz-master/backups/quiz-2026.10.15-reader299-9c670e9-cutover-20261015T115837Z.sqlite': '6794975864e19369f7e41188ad98de43244bd34153451d158115210a6e52bd21', '/var/lib/rancher/k3s/agent/images/quiz-2026.10.15-reader299-9c670e9.tar': '96b931aa9555ee83090a609235b181c884fb4e197bb3fb8c0510aa42da24d438', '/opt/quiz-master/releases/quiz-2026.10.15-reader299-9c670e9/quiz-2026.10.15-reader299-9c670e9-cutover-20261015T122746Z-values.yaml': '52a88e38981a994bc3d04f0239b4454ac4935e88e6f04886214d050c18330f42', '/opt/quiz-master/backups/quiz-2026.10.15-reader299-9c670e9-cutover-20261015T122746Z.sqlite': '6794975864e19369f7e41188ad98de43244bd34153451d158115210a6e52bd21', '/opt/quiz-master/backups/quiz-2026.10.15-reader299-9c670e9-publish-20261015T124056Z.sqlite': '6794975864e19369f7e41188ad98de43244bd34153451d158115210a6e52bd21'}

def marker(st):
    return st.st_dev,st.st_ino,st.st_size,st.st_mtime_ns

def digest_file(path,before,nlink=None):
    fd=os.open(path,os.O_RDONLY|getattr(os,'O_NOFOLLOW',0))
    with os.fdopen(fd,'rb') as stream:
        for snapshot in (os.fstat(stream.fileno()),):
            assert stat.S_ISREG(snapshot.st_mode) and marker(snapshot)==before
            assert nlink is None or snapshot.st_nlink==nlink
        value=hashlib.file_digest(stream,'sha256').hexdigest()
        snapshot=os.fstat(stream.fileno())
        assert marker(snapshot)==before and (nlink is None or snapshot.st_nlink==nlink)
    return value

def validate_plan(plan,protected):
    assert protected==PROTECTED_HASHES and len(protected)==23
    assert plan.get('schema_version')=='qm-reader303-exact-cold-offload/v1'
    entries=plan['entries']
    assert len(entries)==len({e['path'] for e in entries})==28
    assert {PurePosixPath(e['path']).name for e in entries}==EXPECTED_NAMES
    assert plan['total_bytes']==sum(e['size'] for e in entries)==EXPECTED_BYTES
    for e in entries:
        logical=PurePosixPath(e['path'])
        assert logical.parent==ROOT and str(logical)==e['path'] and logical.name in EXPECTED_NAMES
        assert e['path'] not in protected and logical.name not in {PurePosixPath(p).name for p in protected}
        assert set(e)=={'path','size','dev','ino','mtime_ns','sha256'}
        assert all(type(e[k]) is int for k in ('size','dev','ino','mtime_ns'))
        assert e['size']>0 and e['dev']>=0 and e['ino']>0 and e['mtime_ns']>0
        assert re.fullmatch('[0-9a-f]{64}',e['sha256'])
    return entries

def parent_identity(root):
    assert not root.is_symlink() and root.resolve()==root.absolute()
    st=root.lstat();assert stat.S_ISDIR(st.st_mode)
    return st.st_dev,st.st_ino

def verify_entry(entry,root=Path(str(ROOT))):
    logical=PurePosixPath(entry['path'])
    assert logical.parent==ROOT and str(logical)==entry['path'] and logical.name in EXPECTED_NAMES
    assert entry['path'] not in PROTECTED_HASHES
    path=root/logical.name;assert not path.is_symlink()
    st=path.lstat();expected=entry['dev'],entry['ino'],entry['size'],entry['mtime_ns']
    assert stat.S_ISREG(st.st_mode) and st.st_nlink==1 and marker(st)==expected
    assert digest_file(path,expected,nlink=1)==entry['sha256']
    after=path.lstat();assert marker(after)==expected and after.st_nlink==1 and not path.is_symlink()
    return path

def verify_protected(protected):
    assert protected==PROTECTED_HASHES and len(protected)==23
    for text,sha in protected.items():
        path=Path(text);assert path.resolve()==path.absolute() and not path.is_symlink()
        st=path.lstat();assert stat.S_ISREG(st.st_mode)
        assert digest_file(path,marker(st))==sha and marker(path.lstat())==marker(st) and not path.is_symlink()
    print(json.dumps({'protected_files_verified':len(protected)}),flush=True)

def remove_verified(entries,protected,root=Path(str(ROOT)),before_unlink=None):
    assert protected==PROTECTED_HASHES and entries and len({e['path'] for e in entries})==len(entries)
    parent=parent_identity(root)
    for e in entries:
        assert parent_identity(root)==parent
        verify_entry(e,root)
    if before_unlink is not None:before_unlink()
    removed=[]
    for e in entries:
        assert parent_identity(root)==parent
        path=verify_entry(e,root)
        assert parent_identity(root)==parent
        st=path.lstat();assert marker(st)==(e['dev'],e['ino'],e['size'],e['mtime_ns']) and st.st_nlink==1
        os.unlink(path)
        removed.append(e['path'])
        print(json.dumps({'removed':e['path'],'bytes':e['size']}),flush=True)
    return removed

def check_capacity(before,after=None,reclaim=EXPECTED_BYTES):
    available,total=before['disk_available'],before['disk_total']
    assert type(available) is int and type(total) is int and available>0 and total>0
    assert (available+reclaim-GIB)*5>total,'projected reserve must exceed20percent plus1GiB'
    if after is not None:
        assert after['disk_total']==total and (after['disk_available']-GIB)*5>total,'actual reserve must exceed20percent plus1GiB'
        assert after['disk_available']>=available+reclaim-GROWTH_LIMIT,'concurrent growth exceeded64MiB allowance'

def preflight():
    import subprocess, sqlite3, urllib.request
    h = json.loads(subprocess.check_output(['helm', 'status', 'quiz-master', '-n', 'quiz-master', '-o', 'json']))
    x = json.loads(subprocess.check_output(['kubectl', 'get', 'deploy', 'quiz-master', '-n', 'quiz-master', '-o', 'json']))
    p = json.loads(subprocess.check_output(['kubectl', 'get', 'pvc', 'quiz-data', '-n', 'quiz-master', '-o', 'json']))
    assert h['version'] == 62 and h['info']['status'] == 'deployed'
    images = [c['image'] for c in x['spec']['template']['spec']['containers']]
    assert len(images) == 2 and set(images) == {'docker.io/library/quiz-master@sha256:e053b4c42c600a062d2dfff5c5152ccc70ff86b2d97b4f91b9784af7c8fc46d4'}
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
    assert os.stat(str(ROOT)).st_dev==os.stat('/var/lib/rancher/k3s/agent/containerd').st_dev,'reclaimed files must share the measured capacity filesystem'
    with urllib.request.urlopen('https://quiz.kotopedia.org/health/ready', timeout=15) as ready:
        assert ready.status == 200
    with sqlite3.connect('file:/var/lib/rancher/k3s/storage/pvc-7fc2428f-4146-4c78-a26d-2347d9f3b7bf_quiz-master_quiz-data/quiz.db?mode=ro', uri=True) as db:
        rows = db.execute('select * from feedback_reports order by rowid').fetchall()
        assert len(rows) == 29 and db.execute("select count(*) from feedback_reports where status='open'").fetchone()[0] == 29
        sha = hashlib.sha256(json.dumps(rows, ensure_ascii=False, default=str).encode()).hexdigest()
        assert sha == '452929a2ea8dc34600eff8039571e2b0479ec7ad1ec52fa6e271b5c71008030e'
    backup = '/opt/quiz-master/backups/quiz-2026.10.15-reader299-9c670e9-publish-20261015T124056Z.sqlite'
    assert stat.S_IMODE(os.stat(backup).st_mode) == 0o600
    with sqlite3.connect('file:' + backup + '?mode=ro', uri=True) as db:
        assert db.execute('pragma integrity_check').fetchone()[0] == 'ok'
    result = {'helm_revision': 62, 'status': 'deployed', 'images': images, 'available_replicas': 1, 'pvc_uid': p['metadata']['uid'], 'feedback_count': len(rows), 'all_open': True, 'feedback_sha256': sha, 'node_ready': True, 'disk_pressure': False, 'blocking_taints': False, 'disk_available': available, 'disk_total': total, 'disk_at_least20percent': available * 5 >= total, 'https_readiness_status': 200, 'backup_mode': '0600', 'backup_integrity': 'ok'}
    print(json.dumps(result), flush=True)
    return result

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

def inventory_summary(inventory):
    return {key: {'count': len(rows), 'sha256': hashlib.sha256(json.dumps(sorted(rows), separators=(',', ':')).encode()).hexdigest()} for key, rows in inventory.items()}

def run_offload(plan,protected):
    entries=validate_plan(plan,protected)
    initial=preflight();print(json.dumps({'phase':'initial','observed':initial}),flush=True)
    verify_protected(protected)
    before=None;inventory=None
    def immediately_before_unlink():
        nonlocal before,inventory
        before=preflight();check_capacity(before,reclaim=plan['total_bytes'])
        # Snapshot under this project's lock immediately before unlink; additions by other projects are allowed.
        inventory=loaded_images()
        print(json.dumps({'phase':'before_unlink','observed':before,'loaded_images':inventory_summary(inventory)}),flush=True)
    removed=remove_verified(entries,protected,before_unlink=immediately_before_unlink)
    after_inventory=loaded_images();images_preserved(inventory,after_inventory)
    print(json.dumps({'preexisting_loaded_images_preserved':True,'loaded_images_after':inventory_summary(after_inventory),'loaded_images_added':{k:len(after_inventory[k]-inventory[k]) for k in inventory}}),flush=True)
    verify_protected(protected)
    after=preflight();check_capacity(before,after,plan['total_bytes'])
    assert removed==[e['path'] for e in entries] and len(removed)==28
    print(json.dumps({'status':'EXACT_COLD_PACKAGES_OFFLOADED','removed_count':len(removed),'removed_bytes':plan['total_bytes'],'before_available':before['disk_available'],'after_available':after['disk_available'],'total':after['disk_total'],'reserve_bytes':GIB,'concurrent_growth_limit':GROWTH_LIMIT,'release_preparation_capacity_gate_still_required':True}),flush=True)

def render(plan,protected):
    validate_plan(plan,protected)
    source=Path(__file__).read_text(encoding='utf-8')
    body=source+'\nplan='+repr(plan)+'\nprotected='+repr(protected)+'\nrun_offload(plan, protected)\n'
    compile(body,'reader303-exact-offload','exec')
    return 'set -euo pipefail\nunset PYTHONOPTIMIZE PYTHONSTARTUP\ntest "$(hostname)" = racknerd-f0269d5\nexec 8>/opt/quiz-master/DEPLOY.lock\nflock -n 8\npython3 - <<\'READER303_OFFLOAD\'\n'+body+'\nREADER303_OFFLOAD\n'

plan={'schema_version': 'qm-reader303-exact-cold-offload/v1', 'entries': [{'path': '/opt/quiz-master/releases/failed-readiness-quiz-2026.10.11-encore-317b339-20261010T231811Z.tar.gz', 'size': 47327929, 'dev': 64770, 'ino': 414994, 'mtime_ns': 1791674286285288694, 'sha256': '6a1921bc15203454e0ad94d9bbb62c076e88209a130dd794bcdbf0712333ad84'}, {'path': '/opt/quiz-master/releases/rejected-quiz-2026.10.12-singers-1c9b534-identity-032842.tar.gz', 'size': 47365350, 'dev': 64770, 'ino': 419799, 'mtime_ns': 1791775716216403468, 'sha256': '5c9ea7ddae6385a1ff79176cd200be7c71c513f96f551b68978338b0d6e39efc'}, {'path': '/opt/quiz-master/releases/quiz-2026.10.12-culture-f219916-v2.tar.gz', 'size': 47471269, 'dev': 64770, 'ino': 413438, 'mtime_ns': 1791832615836570701, 'sha256': '02e645a0d202c4d66bd9ae080874440d56fd6dbd9d58c5a90a5b63bc5046dc37'}, {'path': '/opt/quiz-master/releases/quiz-2026.10.12-culture-f219916-v3.tar.gz', 'size': 47471274, 'dev': 64770, 'ino': 413480, 'mtime_ns': 1791833819627041028, 'sha256': '4bd7722af219cfc3511e64c290d7e7a6cf3fe46e48fe99775798da6ae152a341'}, {'path': '/opt/quiz-master/releases/quiz-2026.10.13-culture-328f2f8-v7.tar.gz', 'size': 47499212, 'dev': 64770, 'ino': 417604, 'mtime_ns': 1791860665562957388, 'sha256': 'adb49338059c8c7ed39480dd95e0d2d230f9ecda35e0aac3e7746b67e3d4f3fe'}, {'path': '/opt/quiz-master/releases/quiz-2026.10.13-culture-328f2f8-v8.tar.gz', 'size': 47499366, 'dev': 64770, 'ino': 419168, 'mtime_ns': 1791861680884797924, 'sha256': 'f1c8df8edb9b73f7b84dd2ea6bacfc1d80082df8eff97bd287e768b7bdfd140c'}, {'path': '/opt/quiz-master/releases/quiz-2026.10.13-film-craft-c74253f.failed-v1-171556Z.tar.gz', 'size': 47521295, 'dev': 64770, 'ino': 419183, 'mtime_ns': 1791911750091705243, 'sha256': 'e6a26225619149708c8fb2c3ac93a42cadf095efb68c9b6d9136549a20163083'}, {'path': '/opt/quiz-master/releases/quiz-2026.10.14-mixed-ecac092-failed-111030.tar.gz', 'size': 47675025, 'dev': 64770, 'ino': 397490, 'mtime_ns': 1791976223196219200, 'sha256': '16b5f2f827b1dcd391028833a532459235f80a6d208411a18dfe33f1d86a4851'}, {'path': '/opt/quiz-master/releases/quiz-2026.10.14-mixed-ecac092-failed-112137.tar.gz', 'size': 47675114, 'dev': 64770, 'ino': 420241, 'mtime_ns': 1791976890545157842, 'sha256': '3d89b19b97c438291ffd94474b28b44596ebf8d35edab408d770d47ef874a55e'}, {'path': '/opt/quiz-master/releases/quiz-2026.10.14-mixed-ecac092-failed-v4.tar.gz', 'size': 47675311, 'dev': 64770, 'ino': 420244, 'mtime_ns': 1791977627106186905, 'sha256': '37be23b766836afe7628b9cc72cee4c9ad6dfcfe556bed48be8ca7c459787522'}, {'path': '/opt/quiz-master/releases/quiz-2026.10.14-reader-17be4ce-failed-20261014T153204Z.tar.gz', 'size': 47680850, 'dev': 64770, 'ino': 395856, 'mtime_ns': 1791991916545686947, 'sha256': '052791b502cc068c57831473ff200cbd8fdc756018942c500508ca81a0b7f872'}, {'path': '/opt/quiz-master/releases/quiz-2026.10.12-culture-c15eefc.recovery-20261015.tar.gz', 'size': 94923615, 'dev': 64770, 'ino': 398167, 'mtime_ns': 1792012660505408024, 'sha256': '7979e969218d5d1fd1e9b721f803d6896195d76b36fd0df9b0faf2c02d9efb4c'}, {'path': '/opt/quiz-master/releases/quiz-2026.10.12-culture-f219916-v2-02e645a0.recovery-20261015.tar.gz', 'size': 69884727, 'dev': 64770, 'ino': 398392, 'mtime_ns': 1792012670654269382, 'sha256': '299d670273d0a3e978092c3d25c8accd59ba00362014019d9e2869ec8c50d7ca'}, {'path': '/opt/quiz-master/releases/quiz-2026.10.13-film-craft-c74253f.recovery-20261015.tar.gz', 'size': 60666465, 'dev': 64770, 'ino': 397470, 'mtime_ns': 1792012690050004308, 'sha256': 'a90ac5dda4c240e8e8ff6b3cd6ead9501343ff84b3e7fe7da9dd6b480a6cec15'}, {'path': '/opt/quiz-master/releases/quiz-2026.10.11-dedup-ddf47be-failed-fixture-aliasing.recovery-20261015.tar.gz', 'size': 59648611, 'dev': 64770, 'ino': 397472, 'mtime_ns': 1792012698260892051, 'sha256': 'fd902a8e04169a6dfe5e2687159bdaabd413df53bb523e2e871c795691fa3015'}, {'path': '/opt/quiz-master/releases/quiz-2026.10.03-culture260-8c90873.recovery-20261015.tar.gz', 'size': 50287435, 'dev': 64770, 'ino': 398623, 'mtime_ns': 1792012706584778224, 'sha256': '82fced90e14fc26ec2f550e9e5e378caabfa71a47a4d6cb7ff7668f4c0c101f9'}, {'path': '/opt/quiz-master/releases/quiz-2026.10.04-lotr-e38bb24.recovery-20261015.tar.gz', 'size': 82267466, 'dev': 64770, 'ino': 398625, 'mtime_ns': 1792012715421657355, 'sha256': '51b6745e14fc02948d3c503ce3760b97869c6d20e241091c43ff1cbe12727d8f'}, {'path': '/opt/quiz-master/releases/quiz-2026.10.04-study-3ebba4e.recovery-20261015.tar.gz', 'size': 81870212, 'dev': 64770, 'ino': 398626, 'mtime_ns': 1792012722993553767, 'sha256': '6806dd9b306071ed3a1281d209626d2bd5540f1e9d3508d6c7f1a6c9bba30c0b'}, {'path': '/opt/quiz-master/releases/quiz-2026.10.02-2327-5121fbd.recovery-20261015.tar.gz', 'size': 58238522, 'dev': 64770, 'ino': 398851, 'mtime_ns': 1792012729534464266, 'sha256': 'a3c4eda3b50f4b76735824f359a2c05e35e0e01d5ae5d241b6bb8139d44c6281'}, {'path': '/opt/quiz-master/releases/quiz-2026.10.02-2308-9359647.recovery-20261015.tar.gz', 'size': 58240538, 'dev': 64770, 'ino': 398164, 'mtime_ns': 1792012735508382510, 'sha256': 'd20ae27be2921a56a00e97b5a990978de60a498e9f615957230113f8aaf91ecd'}, {'path': '/opt/quiz-master/releases/quiz-2026.10.12-culture-f219916-v1-67b68725.recovery-20261015.tar.gz', 'size': 50586101, 'dev': 64770, 'ino': 396146, 'mtime_ns': 1792012741703297717, 'sha256': 'af4d6715bd2b709b031572e9d94a4ec630a34de4fa5ceac57a1a9674163d75f1'}, {'path': '/opt/quiz-master/releases/quiz-2026.10.12-culture-7d7a163.recovery-20261015.tar.gz', 'size': 50533534, 'dev': 64770, 'ino': 397719, 'mtime_ns': 1792012747525218017, 'sha256': '6bf6e20ab20d0e41123c089d9c8d4f1c721fdfc98efe6e9216bed192aa2bf67c'}, {'path': '/opt/quiz-master/releases/quiz-2026.10.12-culture-variety-b015251.recovery-20261015.tar.gz', 'size': 50283489, 'dev': 64770, 'ino': 397813, 'mtime_ns': 1792012753408137472, 'sha256': '671af904e17ff8069fbb051937ca35b472d4795206cd797cb24fc27538a319a8'}, {'path': '/opt/quiz-master/releases/quiz-2026.10.11-dedup-ddf47be.recovery-20261015.tar.gz', 'size': 50268130, 'dev': 64770, 'ino': 397814, 'mtime_ns': 1792012759237057654, 'sha256': '93abd236b843bd96e15bbe89f736cb6cba26b00d4ede8c4d7e4368073f09ea4a'}, {'path': '/opt/quiz-master/releases/quiz-2026.10.12-singers-1c9b534.recovery-20261015.tar.gz', 'size': 50270126, 'dev': 64770, 'ino': 397815, 'mtime_ns': 1792012764757982044, 'sha256': '631aa16dec802b3fe89267abfdb3c73519534965022dd8657cc06d67d721dc0a'}, {'path': '/opt/quiz-master/releases/quiz-2026.10.12-actors-3556b59.recovery-20261015.tar.gz', 'size': 50284156, 'dev': 64770, 'ino': 397816, 'mtime_ns': 1792012770879898191, 'sha256': 'c284a35bef44dc2a01b7841c8ff4265894224ef45bdea5c3517deaf83585c726'}, {'path': '/opt/quiz-master/releases/quiz-2026.10.11-phobias-1537ff5.recovery-20261015.tar.gz', 'size': 50267037, 'dev': 64770, 'ino': 397817, 'mtime_ns': 1792012776945815094, 'sha256': '70bc6ab052dd1fddac80871d94fd938f2971f50e543fd37c1c097a93f3d7bbb3'}, {'path': '/opt/quiz-master/releases/quiz-rounds20.tar.gz', 'size': 26701725, 'dev': 64770, 'ino': 398384, 'mtime_ns': 1790974855702491541, 'sha256': '51efa969086e170ad59cc066e2f935978f9ae63961847ec67ac10eb5d9fe7faf'}], 'total_bytes': 1518083884, 'scope': '28exact historical project release archives only; no stage/backups/loadedimages/otherproject changes.'}
protected={'/opt/quiz-master/releases/quiz-2026.10.14-library-09b19cc.tar.gz': '7d9d6c64763a64b811d942a9df3cdc489a4fc39a11ac8d628165e0636649791f', '/opt/quiz-master/releases/quiz-2026.10.14-reader-17be4ce.tar.gz': 'a67c8afa9d18dfe67c4651f50a84c0337998150d5236e9babfed551a212cfb6a', '/opt/quiz-master/releases/quiz-2026.10.15-reader-06dfa0b.tar.gz': '6ddd12317732d0fa5bf87f8a80ff24e7ef71b50a233d7d65fa4249421a6c79ab', '/opt/quiz-master/releases/quiz-2026.10.15-actors-d204f9b.tar.gz': '5ab6a34ea49b4078d952a311cf5468999b4b696108d1b4b6d6c285b3b74e04a2', '/var/lib/rancher/k3s/agent/images/quiz-2026.10.14-library-09b19cc.tar': '7d4566aab0df18b6a879ac94115e5b146ebcc1252ad7bef038d8ef1f37279b79', '/var/lib/rancher/k3s/agent/images/quiz-2026.10.14-reader-17be4ce.tar': 'ee77b4ccd5b9e05668e7759b8399c8943825f34181b3b480564d941097443812', '/var/lib/rancher/k3s/agent/images/quiz-2026.10.15-reader-06dfa0b.tar': 'b8bd7bc5fb382f7860ce141d05e467b0b426429e4355212d44b3e50cbda61684', '/var/lib/rancher/k3s/agent/images/quiz-2026.10.15-actors-d204f9b.tar': '04badd8485c8209919fe2a45937da0093f22dcb80fc6b379daa92fbbedcbc501', '/opt/quiz-master/backups/quiz-2026.10.14-library-09b19cc-publish-20261014T223958Z.sqlite': 'c811bcfdc4af694b9f638f6901ba9360c04261bd9def7049049303d9e3d4b291', '/opt/quiz-master/backups/quiz-2026.10.15-reader-06dfa0b-publish-20261015T034437Z.sqlite': '6794975864e19369f7e41188ad98de43244bd34153451d158115210a6e52bd21', '/opt/quiz-master/backups/quiz-2026.10.15-actors-d204f9b-publish-20261015T061630Z.sqlite': '6794975864e19369f7e41188ad98de43244bd34153451d158115210a6e52bd21', '/opt/quiz-master/releases/quiz-2026.10.15-reader291-3482af9.tar.gz': 'd926a276aeb60f2cd7181a2d0322f7ef0b16ec5d32863ab0afe1c6517b2e23ad', '/var/lib/rancher/k3s/agent/images/quiz-2026.10.15-reader291-3482af9.tar': 'e20d542615a12f07883b828dc166170948817dc723f5da7686ce63aa9b22400b', '/opt/quiz-master/backups/quiz-2026.10.15-reader291-3482af9-cutover-20261015T084302Z.sqlite': '6794975864e19369f7e41188ad98de43244bd34153451d158115210a6e52bd21', '/opt/quiz-master/releases/quiz-2026.10.15-reader291-3482af9/quiz-2026.10.15-reader291-3482af9-cutover-20261015T084302Z-values.yaml': '53f77283f65b00387ec3d3f7fe30a278e5c2a324d27506fa976ab14861cd3f7f', '/opt/quiz-master/releases/quiz-2026.10.15-reader291-3482af9/quiz-2026.10.15-reader291-3482af9-cutover-20261015T084302Z-rendered.yaml': '61194251e41088773f5e2b3da7b448d074f5a69f6caeb4343cb9a049d7824b98', '/opt/quiz-master/backups/quiz-2026.10.15-reader291-3482af9-publish-20261015T093511Z.sqlite': '6794975864e19369f7e41188ad98de43244bd34153451d158115210a6e52bd21', '/opt/quiz-master/releases/quiz-2026.10.15-reader299-9c670e9.tar.gz': '01ddc3ee1cd7ef68376ec1dc84c06ad9c8ab88970995715edce3e631a5c7417d', '/opt/quiz-master/backups/quiz-2026.10.15-reader299-9c670e9-cutover-20261015T115837Z.sqlite': '6794975864e19369f7e41188ad98de43244bd34153451d158115210a6e52bd21', '/var/lib/rancher/k3s/agent/images/quiz-2026.10.15-reader299-9c670e9.tar': '96b931aa9555ee83090a609235b181c884fb4e197bb3fb8c0510aa42da24d438', '/opt/quiz-master/releases/quiz-2026.10.15-reader299-9c670e9/quiz-2026.10.15-reader299-9c670e9-cutover-20261015T122746Z-values.yaml': '52a88e38981a994bc3d04f0239b4454ac4935e88e6f04886214d050c18330f42', '/opt/quiz-master/backups/quiz-2026.10.15-reader299-9c670e9-cutover-20261015T122746Z.sqlite': '6794975864e19369f7e41188ad98de43244bd34153451d158115210a6e52bd21', '/opt/quiz-master/backups/quiz-2026.10.15-reader299-9c670e9-publish-20261015T124056Z.sqlite': '6794975864e19369f7e41188ad98de43244bd34153451d158115210a6e52bd21'}
run_offload(plan, protected)

READER303_OFFLOAD
