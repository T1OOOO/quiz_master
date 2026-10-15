"""Exact failed-stage cold offload. Rendering is inert; only reviewed Root execution may remove files."""
if not __debug__:
    raise RuntimeError('stage offload refuses optimized Python')
from pathlib import Path,PurePosixPath
import hashlib,json,os,re,stat,tarfile
RELEASE_ROOT=PurePosixPath('/opt/quiz-master/releases')
COLD_ROOT=PurePosixPath('/opt/quiz-master/stage-offload-20261015')
PREPARED_NAME='quiz-2026.10.15-reader303-14b7da4'
FAILED_NAME=PREPARED_NAME+'.failed-20261015T162707Z'
PROC_ROOT=Path('/proc')
MOUNT_INFO=Path('/proc/self/mountinfo')
GUARD_SHA256='7d8637d9a646f306aa41cf90a496d3216933a4f0b8c717cc2db5b9c3e41c66d5'
COLD_NAMES={'quiz-2026.10.15-reader303-14b7da4.failed-20261015T162707Z', 'quiz-2026.10.13-film-craft-c74253f.failed-v1-171556Z', 'rejected-quiz-2026.10.12-singers-1c9b534-identity-032842', 'failed-readiness-quiz-2026.10.11-encore-317b339-20261010T231811Z', 'rejected-quiz-2026.10.12-actors-3556b59-staging-004924', 'quiz-2026.10.14-mixed-ecac092-failed-v4', 'quiz-2026.10.14-reader-17be4ce-failed-20261014T153204Z', 'quiz-2026.10.14-mixed-ecac092-failed-112137', 'quiz-2026.10.14-mixed-ecac092-failed-111030'}
EXPECTED_PROTECTED_FILES={'/opt/quiz-master/releases/quiz-2026.10.14-library-09b19cc.tar.gz': '7d9d6c64763a64b811d942a9df3cdc489a4fc39a11ac8d628165e0636649791f', '/opt/quiz-master/releases/quiz-2026.10.14-reader-17be4ce.tar.gz': 'a67c8afa9d18dfe67c4651f50a84c0337998150d5236e9babfed551a212cfb6a', '/opt/quiz-master/releases/quiz-2026.10.15-reader-06dfa0b.tar.gz': '6ddd12317732d0fa5bf87f8a80ff24e7ef71b50a233d7d65fa4249421a6c79ab', '/opt/quiz-master/releases/quiz-2026.10.15-actors-d204f9b.tar.gz': '5ab6a34ea49b4078d952a311cf5468999b4b696108d1b4b6d6c285b3b74e04a2', '/var/lib/rancher/k3s/agent/images/quiz-2026.10.14-library-09b19cc.tar': '7d4566aab0df18b6a879ac94115e5b146ebcc1252ad7bef038d8ef1f37279b79', '/var/lib/rancher/k3s/agent/images/quiz-2026.10.14-reader-17be4ce.tar': 'ee77b4ccd5b9e05668e7759b8399c8943825f34181b3b480564d941097443812', '/var/lib/rancher/k3s/agent/images/quiz-2026.10.15-reader-06dfa0b.tar': 'b8bd7bc5fb382f7860ce141d05e467b0b426429e4355212d44b3e50cbda61684', '/var/lib/rancher/k3s/agent/images/quiz-2026.10.15-actors-d204f9b.tar': '04badd8485c8209919fe2a45937da0093f22dcb80fc6b379daa92fbbedcbc501', '/opt/quiz-master/backups/quiz-2026.10.14-library-09b19cc-publish-20261014T223958Z.sqlite': 'c811bcfdc4af694b9f638f6901ba9360c04261bd9def7049049303d9e3d4b291', '/opt/quiz-master/backups/quiz-2026.10.15-reader-06dfa0b-publish-20261015T034437Z.sqlite': '6794975864e19369f7e41188ad98de43244bd34153451d158115210a6e52bd21', '/opt/quiz-master/backups/quiz-2026.10.15-actors-d204f9b-publish-20261015T061630Z.sqlite': '6794975864e19369f7e41188ad98de43244bd34153451d158115210a6e52bd21', '/opt/quiz-master/releases/quiz-2026.10.15-reader291-3482af9.tar.gz': 'd926a276aeb60f2cd7181a2d0322f7ef0b16ec5d32863ab0afe1c6517b2e23ad', '/var/lib/rancher/k3s/agent/images/quiz-2026.10.15-reader291-3482af9.tar': 'e20d542615a12f07883b828dc166170948817dc723f5da7686ce63aa9b22400b', '/opt/quiz-master/backups/quiz-2026.10.15-reader291-3482af9-cutover-20261015T084302Z.sqlite': '6794975864e19369f7e41188ad98de43244bd34153451d158115210a6e52bd21', '/opt/quiz-master/releases/quiz-2026.10.15-reader291-3482af9/quiz-2026.10.15-reader291-3482af9-cutover-20261015T084302Z-values.yaml': '53f77283f65b00387ec3d3f7fe30a278e5c2a324d27506fa976ab14861cd3f7f', '/opt/quiz-master/releases/quiz-2026.10.15-reader291-3482af9/quiz-2026.10.15-reader291-3482af9-cutover-20261015T084302Z-rendered.yaml': '61194251e41088773f5e2b3da7b448d074f5a69f6caeb4343cb9a049d7824b98', '/opt/quiz-master/backups/quiz-2026.10.15-reader291-3482af9-publish-20261015T093511Z.sqlite': '6794975864e19369f7e41188ad98de43244bd34153451d158115210a6e52bd21', '/opt/quiz-master/releases/quiz-2026.10.15-reader299-9c670e9.tar.gz': '01ddc3ee1cd7ef68376ec1dc84c06ad9c8ab88970995715edce3e631a5c7417d', '/opt/quiz-master/backups/quiz-2026.10.15-reader299-9c670e9-cutover-20261015T115837Z.sqlite': '6794975864e19369f7e41188ad98de43244bd34153451d158115210a6e52bd21', '/var/lib/rancher/k3s/agent/images/quiz-2026.10.15-reader299-9c670e9.tar': '96b931aa9555ee83090a609235b181c884fb4e197bb3fb8c0510aa42da24d438', '/opt/quiz-master/releases/quiz-2026.10.15-reader299-9c670e9/quiz-2026.10.15-reader299-9c670e9-cutover-20261015T122746Z-values.yaml': '52a88e38981a994bc3d04f0239b4454ac4935e88e6f04886214d050c18330f42', '/opt/quiz-master/backups/quiz-2026.10.15-reader299-9c670e9-cutover-20261015T122746Z.sqlite': '6794975864e19369f7e41188ad98de43244bd34153451d158115210a6e52bd21', '/opt/quiz-master/backups/quiz-2026.10.15-reader299-9c670e9-publish-20261015T124056Z.sqlite': '6794975864e19369f7e41188ad98de43244bd34153451d158115210a6e52bd21', '/opt/quiz-master/releases/quiz-2026.10.15-reader303-14b7da4.tar.gz': '0df5f4496ab163a0cbeefaedce2c62af8d7d8b322b19dd41c4bc16e50cc79a0b', '/var/lib/rancher/k3s/agent/images/quiz-2026.10.15-reader303-14b7da4.tar': 'c86b4632f0826f9a5a7d92b772ba1744846f23ff08d2b46403c23d1c18153bd3', '/opt/quiz-master/backups/quiz-2026.10.15-reader303-14b7da4-cutover-20261015T171054Z.sqlite': '6794975864e19369f7e41188ad98de43244bd34153451d158115210a6e52bd21', '/opt/quiz-master/releases/quiz-2026.10.15-reader303-14b7da4/quiz-2026.10.15-reader303-14b7da4-cutover-20261015T171054Z-values.yaml': '574a9278a4a202d1c8541b01e1cc23526c028bc1c883a099eb9986bc14d6053f', '/opt/quiz-master/releases/quiz-2026.10.15-reader303-14b7da4/quiz-2026.10.15-reader303-14b7da4-cutover-20261015T171054Z-rendered.yaml': 'd6b42f6c2f7536335caf1687e93298f370282f2b7da4014c3719d1d7a68dfe48', '/opt/quiz-master/releases/quiz-2026.10.15-reader303-14b7da4/quiz-2026.10.15-reader303-14b7da4-cutover-20261015T171054Z-candidate-runtime.json': '9cb1005af6f6f57c23288ef6f680a686eb6feb5b7a8e7c5d16d20b4b3b700c62', '/opt/quiz-master/releases/quiz-2026.10.15-reader303-14b7da4/quiz-2026.10.15-reader303-14b7da4-cutover-20261015T171054Z-rehearsal.json': 'e5431954162e3dea0f7050bac8f3248f704d4c76a4ab5b4fa49229c4d1d8bfc8'}
FAILED_ARCHIVE_SHA256='06d1af4fff1b7a7b65cd8e8780723c71f394b8ae4f6e86af7687086ba5c7bff2'
ENTRY_FIELDS={'path','kind','dev','ino','size','mtime_ns','mode','nlink','uid','gid','blocks'}
PLAN_FIELDS={'schema_version','trees','archives','protected_files','protected_tree','release_parent','cold_parent','total_allocated_bytes'}

def logical(text):
    path=PurePosixPath(text)
    assert isinstance(text,str) and (path.is_absolute() or Path(text).is_absolute()) and str(path)==text and '..' not in path.parts and '\\' not in text
    return path

def validate_entry(entry):
    assert entry['kind'] in ('file','dir')
    assert set(entry)==ENTRY_FIELDS|({'sha256'} if entry['kind']=='file' else set())
    logical(entry['path'])
    assert all(type(entry[k]) is int and entry[k]>=0 for k in ENTRY_FIELDS-{'path','kind'})
    assert entry['ino']>0 and entry['nlink']>0 and entry['mode']<=0o7777
    if entry['kind']=='file':
        assert entry['nlink']==1 and re.fullmatch('[0-9a-f]{64}',entry['sha256'])

def validate_tree(tree,expected_root,device):
    assert set(tree)=={'root','entries'} and tree['root']==str(expected_root)
    entries=tree['entries'];assert isinstance(entries,list) and entries
    mapping={e['path']:e for e in entries};assert len(mapping)==len(entries)
    assert mapping[str(expected_root)]['kind']=='dir'
    for entry in entries:
        validate_entry(entry);path=logical(entry['path'])
        assert path.is_relative_to(expected_root) and entry['dev']==device
        if path!=expected_root:assert mapping[str(path.parent)]['kind']=='dir'
    return mapping

def validate_plan(plan):
    assert set(plan)==PLAN_FIELDS and plan['schema_version']=='qm-reader303-stage-cold-offload/v1'
    for key,path in [('release_parent',RELEASE_ROOT),('cold_parent',COLD_ROOT)]:
        validate_entry(plan[key]);assert plan[key]['kind']=='dir' and plan[key]['path']==str(path)
    device=plan['release_parent']['dev'];assert plan['cold_parent']['dev']==device
    trees=plan['trees'];assert len(trees)==9 and {t['root'] for t in trees}=={str(RELEASE_ROOT/name) for name in COLD_NAMES}
    removal={}
    for tree in trees:
        mapping=validate_tree(tree,logical(tree['root']),device)
        assert not set(removal)&set(mapping);removal.update(mapping)
    archives=plan['archives'];assert len(archives)==10
    archive_paths={str(COLD_ROOT/(name+'.tar.gz')) for name in COLD_NAMES}|{str(RELEASE_ROOT/(FAILED_NAME+'.tar.gz'))}
    assert {e['path'] for e in archives}==archive_paths
    for entry in archives:
        validate_entry(entry);assert entry['kind']=='file' and entry['dev']==device
        assert entry['path'] not in removal;removal[entry['path']]=entry
        if entry['path']==str(RELEASE_ROOT/(FAILED_NAME+'.tar.gz')):assert entry['sha256']==FAILED_ARCHIVE_SHA256
    assert plan['protected_files']==EXPECTED_PROTECTED_FILES and len(plan['protected_files'])==30
    assert not set(removal)&set(plan['protected_files'])
    protected=validate_tree(plan['protected_tree'],RELEASE_ROOT/PREPARED_NAME,device)
    assert not set(protected)&set(removal)
    assert type(plan['total_allocated_bytes']) is int and plan['total_allocated_bytes']==sum(e['blocks'] for e in removal.values())
    return removal

def stat_signature(value):
    return (value.st_dev,value.st_ino,value.st_size,value.st_mtime_ns,value.st_mode,value.st_nlink,value.st_uid,value.st_gid,getattr(value,'st_blocks',0))

def fingerprint(path):
    path=Path(path);before=path.lstat()
    assert not path.is_symlink() and (stat.S_ISREG(before.st_mode) or stat.S_ISDIR(before.st_mode))
    entry={'path':path.as_posix(),'kind':'file' if stat.S_ISREG(before.st_mode) else 'dir','dev':before.st_dev,'ino':before.st_ino,'size':before.st_size,'mtime_ns':before.st_mtime_ns,'mode':stat.S_IMODE(before.st_mode),'nlink':before.st_nlink,'uid':before.st_uid,'gid':before.st_gid,'blocks':getattr(before,'st_blocks',0)*512}
    if entry['kind']=='file':
        assert before.st_nlink==1
        fd=os.open(path,os.O_RDONLY|getattr(os,'O_NOFOLLOW',0))
        with os.fdopen(fd,'rb') as stream:
            opened=os.fstat(stream.fileno());assert stat_signature(opened)==stat_signature(before)
            entry['sha256']=hashlib.file_digest(stream,'sha256').hexdigest()
            assert stat_signature(os.fstat(stream.fileno()))==stat_signature(opened)
        assert stat_signature(path.lstat())==stat_signature(before) and not path.is_symlink()
    return entry

def verify_entry(entry):
    path=Path(entry['path']);assert path.resolve()==path.absolute()
    assert fingerprint(path)==entry,'frozen entry changed'

def paths_in_tree(root):
    result=[];pending=[Path(root)]
    while pending:
        path=pending.pop();st=path.lstat();assert not path.is_symlink()
        assert stat.S_ISREG(st.st_mode) or stat.S_ISDIR(st.st_mode)
        result.append(path.as_posix())
        if stat.S_ISDIR(st.st_mode):
            with os.scandir(path) as children:pending.extend(Path(item.path) for item in children)
    return set(result)

def verify_tree(tree):
    assert paths_in_tree(tree['root'])=={e['path'] for e in tree['entries']},'tree membership differs'
    for entry in tree['entries']:verify_entry(entry)

def verify_protected_files(plan):
    observed={}
    for path,sha in plan['protected_files'].items():
        entry=fingerprint(path);assert entry['kind']=='file' and entry['sha256']==sha
        observed[path]=entry
    return observed

def verify_archive(tree,archive):
    root=logical(tree['root']);expected={str(PurePosixPath(root.name)/logical(e['path']).relative_to(root)):e for e in tree['entries']}
    seen=set()
    with tarfile.open(archive['path'],'r:gz') as stream:
        for member in stream:
            name=member.name.rstrip('/');pure=PurePosixPath(name)
            assert str(pure)==name and not pure.is_absolute() and '..' not in pure.parts and '\\' not in name
            assert name in expected and name not in seen and (member.isfile() or member.isdir())
            seen.add(name);entry=expected[name]
            assert member.mode==entry['mode'] and member.uid==entry['uid'] and member.gid==entry['gid']
            assert member.isdir()==(entry['kind']=='dir')
            if member.isfile():
                assert member.size==entry['size']
                file=stream.extractfile(member);assert file is not None
                with file:assert hashlib.file_digest(file,'sha256').hexdigest()==entry['sha256']
    assert seen==set(expected),'cold archive does not contain the complete tree'

def assert_idle(plan):
    roots=[t['root'] for t in plan['trees']]
    with os.scandir(PROC_ROOT) as processes:
        for process in processes:
            if not process.name.isdecimal():continue
            directory=Path(process.path);values=[]
            try:values.append((directory/'cmdline').read_bytes().decode(errors='replace'))
            except FileNotFoundError:pass
            for key in ('cwd','exe'):
                try:values.append(os.readlink(directory/key))
                except FileNotFoundError:pass
            assert not any(root in value for root in roots for value in values),'a process still references a cold tree'
    mountpoints=[]
    for line in MOUNT_INFO.read_text().splitlines():
        fields=line.split();assert len(fields)>=6
        point=re.sub(r'\\([0-7]{3})',lambda m:chr(int(m[1],8)),fields[4]);mountpoints.append(point)
    assert mountpoints
    assert not any(point==root or point.startswith(root+'/') for point in mountpoints for root in roots),'cold tree has a submount'

def stable_directory(entry):
    path=Path(entry['path']);assert path.resolve()==path.absolute() and not path.is_symlink()
    st=path.lstat();assert stat.S_ISDIR(st.st_mode)
    assert (st.st_dev,st.st_ino,stat.S_IMODE(st.st_mode),st.st_uid,st.st_gid)==tuple(entry[k] for k in ('dev','ino','mode','uid','gid')),'directory identity changed'

def remove_cold(plan,before_mutation=None):
    removal=validate_plan(plan)
    verify_entry(plan['release_parent']);verify_entry(plan['cold_parent'])
    assert_idle(plan)
    for tree in plan['trees']:verify_tree(tree)
    for archive in plan['archives']:verify_entry(archive)
    archives={e['path']:e for e in plan['archives']}
    for tree in plan['trees']:verify_archive(tree,archives[str(COLD_ROOT/(logical(tree['root']).name+'.tar.gz'))])
    verify_tree(plan['protected_tree']);protected_before=verify_protected_files(plan)
    parents={e['path']:e for e in removal.values() if e['kind']=='dir'}
    parents.update({e['path']:e for e in (plan['release_parent'],plan['cold_parent'])})
    if before_mutation is not None:before_mutation()
    assert_idle(plan)
    for parent in parents.values():stable_directory(parent)
    removed=[]
    for entry in sorted((e for e in removal.values() if e['kind']=='file'),key=lambda e:e['path']):
        parent=parents[str(logical(entry['path']).parent)]
        stable_directory(parent);verify_entry(entry);stable_directory(parent)
        os.unlink(entry['path']);removed.append(entry['path'])
        print(json.dumps({'removed_file':entry['path']}),flush=True)
    for entry in sorted((e for e in removal.values() if e['kind']=='dir'),key=lambda e:(len(logical(e['path']).parts),e['path']),reverse=True):
        stable_directory(parents[str(logical(entry['path']).parent)]);stable_directory(entry)
        with os.scandir(entry['path']) as children:assert next(children,None) is None,'directory is not empty'
        os.rmdir(entry['path']);removed.append(entry['path'])
        print(json.dumps({'removed_empty_directory':entry['path']}),flush=True)
    verify_tree(plan['protected_tree']);assert verify_protected_files(plan)==protected_before
    stable_directory(plan['release_parent']);stable_directory(plan['cold_parent'])
    assert set(removed)==set(removal) and len(removed)==len(removal)
    return removed

def run_stage_offload(plan):
    validate_plan(plan)
    initial=guard_preflight();print(json.dumps({'phase':'initial','observed':initial}),flush=True)
    assert os.stat(str(RELEASE_ROOT)).st_dev==os.stat(str(COLD_ROOT)).st_dev==os.stat('/var/lib/rancher/k3s/agent/containerd').st_dev
    guard_verify_protected(PROTECTED_HASHES)
    before=None;inventory=None
    def before_mutation():
        nonlocal before,inventory
        before=guard_preflight();guard_check_capacity(before,reclaim=plan['total_allocated_bytes'])
        inventory=guard_loaded_images()
        print(json.dumps({'phase':'before_unlink','observed':before,'loaded_images':guard_inventory_summary(inventory)}),flush=True)
    removed=remove_cold(plan,before_mutation=before_mutation)
    after_inventory=guard_loaded_images();guard_images_preserved(inventory,after_inventory)
    guard_verify_protected(PROTECTED_HASHES)
    after=guard_preflight();guard_check_capacity(before,after,plan['total_allocated_bytes'])
    print(json.dumps({'status':'EXACT_FAILED_STAGES_OFFLOADED','removed_entries':len(removed),'removed_allocated_bytes':plan['total_allocated_bytes'],'before_available':before['disk_available'],'after_available':after['disk_available'],'total':after['disk_total'],'loaded_images_after':guard_inventory_summary(after_inventory),'loaded_images_added':{k:len(after_inventory[k]-inventory[k]) for k in inventory},'preexisting_loaded_images_preserved':True,'prepared303_tree_preserved':True,'release_collection_still_required':True}),flush=True)

def render(plan,guard_source):
    validate_plan(plan)
    assert hashlib.sha256(guard_source.encode()).hexdigest()==GUARD_SHA256,'unchanged accepted guard source required'
    aliases='\nguard_preflight=preflight\nguard_verify_protected=verify_protected\nguard_loaded_images=loaded_images\nguard_images_preserved=images_preserved\nguard_inventory_summary=inventory_summary\nguard_check_capacity=check_capacity\n'
    body=guard_source+aliases+Path(__file__).read_text(encoding='utf-8')+'\nplan='+repr(plan)+'\nrun_stage_offload(plan)\n'
    compile(body,'reader303-stage-offload','exec')
    return 'set -euo pipefail\nunset PYTHONOPTIMIZE PYTHONSTARTUP\ntest "$(hostname)" = racknerd-f0269d5\nexec 8>/opt/quiz-master/DEPLOY.lock\nflock -n 8\npython3 - <<\'READER303_STAGE_OFFLOAD\'\n'+body+'\nREADER303_STAGE_OFFLOAD\n'
