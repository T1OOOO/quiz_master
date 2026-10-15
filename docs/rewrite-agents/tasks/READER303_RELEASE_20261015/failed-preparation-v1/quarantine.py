"""Preserve the exact never-published failed stage and archive by sibling rename."""
if not __debug__:
    raise RuntimeError('quarantine refuses optimized Python')
from pathlib import Path
import hashlib,json,os,stat

def fingerprint(p):
    assert not p.is_symlink() and p.resolve()==p.absolute()
    st=p.lstat()
    value={'path':str(p),'dev':st.st_dev,'ino':st.st_ino,'size':st.st_size,'mtime_ns':st.st_mtime_ns,'mode':stat.S_IMODE(st.st_mode),'nlink':st.st_nlink}
    if stat.S_ISREG(st.st_mode):
        with os.fdopen(os.open(p,os.O_RDONLY|os.O_NOFOLLOW|getattr(os,'O_BINARY',0)),'rb') as stream:
            assert identity(os.fstat(stream.fileno()))==identity(st)
            value['sha256']=hashlib.file_digest(stream,'sha256').hexdigest()
            assert identity(os.fstat(stream.fileno()))==identity(st)
    else:assert stat.S_ISDIR(st.st_mode)
    assert identity(p.lstat())==identity(st)
    return value

def identity(st):
    return st.st_dev,st.st_ino,st.st_size,st.st_mtime_ns,st.st_mode,st.st_nlink

def move_failed(plan,base):
    stage=base/'quiz-2026.10.15-reader303-14b7da4'
    archive=stage.with_name(stage.name+'.tar.gz')
    destinations=[Path(str(stage)+'.failed-20261015T162707Z'),Path(str(stage)+'.failed-20261015T162707Z.tar.gz')]
    assert plan['destinations']==[str(p) for p in destinations]
    assert fingerprint(base)==plan['parent']
    assert all(not p.exists() and not p.is_symlink() for p in destinations)
    assert [fingerprint(stage)]+[fingerprint(p) for p in sorted(stage.rglob('*'))]==plan['entries']
    assert fingerprint(archive)==plan['archive']
    assert fingerprint(Path(plan['backup']['path']))==plan['backup']
    assert not any(plan['own_images'].values()) and not plan['own_containers'] and not plan['own_processes']
    # renameat2 NOREPLACE preserves existing destinations even if another writer races the lock.
    import ctypes
    libc=ctypes.CDLL(None,use_errno=True)
    for source,target in zip([stage,archive],destinations):
        assert not target.exists() and not target.is_symlink()
        result=libc.renameat2(-100,os.fsencode(source),-100,os.fsencode(target),1)
        if result:raise OSError(ctypes.get_errno(),str(source))
    expected=[dict(e,path=str(destinations[0])+e['path'][len(str(stage)):]) for e in plan['entries']]
    assert [fingerprint(destinations[0])]+[fingerprint(p) for p in sorted(destinations[0].rglob('*'))]==expected
    assert fingerprint(destinations[1])==dict(plan['archive'],path=str(destinations[1]))
    assert fingerprint(Path(plan['backup']['path']))==plan['backup']
    return [str(p) for p in destinations]

def render(plan,preflight_source):
    assert plan['parent']['path']=='/opt/quiz-master/releases'
    source=Path(__file__).read_text()
    body=preflight_source+'\n'+source+'\nplan='+repr(plan)+'''
import socket,subprocess
assert socket.gethostname()=='racknerd-f0269d5'
before=preflight()
assert before['disk_available']*5>before['disk_total']
verify_protected(PROTECTED_HASHES)
images=loaded_images()
assert all('reader303' not in str(row) for values in images.values() for row in values)
assert 'reader303' not in subprocess.check_output(['docker','ps','-a','--format','{{.Image}} {{.Names}}'],text=True)
for p in Path('/proc').iterdir():
    if not p.name.isdecimal():continue
    try:cmd=(p/'cmdline').read_bytes()
    except (FileNotFoundError,PermissionError,ProcessLookupError):continue
    assert b'reader303' not in cmd
result=move_failed(plan,Path('/opt/quiz-master/releases'))
verify_protected(PROTECTED_HASHES)
after=preflight()
print(json.dumps({'status':'FAILED_STAGE_PRESERVED','destinations':result,'baseline_after':after}),flush=True)
'''
    compile(body,'reader303-quarantine','exec')
    return "set -euo pipefail\nunset PYTHONOPTIMIZE PYTHONSTARTUP\nexec 8>/opt/quiz-master/DEPLOY.lock\nflock -n 8\npython3 - <<'QUIZ_QUARANTINE'\n"+body+'\nQUIZ_QUARANTINE\n'
