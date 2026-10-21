"""Restore every archived entry in bounded Linux scratch trees, retaining originals."""
from __future__ import annotations

import argparse
import copy
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import shlex
import shutil
import subprocess
import tarfile
import tempfile

DESTINATION = Path('E:/Backups/quiz-master/server-20261021')
HOST = 'root@192.3.164.184'
KEY = 'C:/Users/Alexey_Matvienko/.ssh/ll_deploy_ed25519'
CHUNK_BYTES = 32 * 1024 * 1024
MAX_FILE_BYTES = 512 * 1024 * 1024

REMOTE = r'''
import base64,hashlib,json,os,pathlib,shutil,socket,stat,subprocess,sys,tempfile
assert socket.gethostname()=='racknerd-f0269d5'
request=json.loads(sys.stdin.buffer.readline())
expected=request['entries']; basename=request['basename']
assert basename and '/' not in basename and basename not in ('.','..')
assert len({e['path'] for e in expected})==len(expected)
memory={k:int(v.split()[0])*1024 for k,v in (line.split(':',1) for line in open('/proc/meminfo'))}
required=1024**3+2*request['logical_bytes']+len(expected)*4096
assert memory['MemAvailable']>required, 'insufficient memory for bounded restore'
assert os.statvfs('/dev/shm').f_bavail*os.statvfs('/dev/shm').f_frsize>request['logical_bytes']+len(expected)*4096+64*1024**2
assert subprocess.check_output(['findmnt','-n','-o','FSTYPE','-T','/dev/shm'],text=True).strip()=='tmpfs'
work=tempfile.mkdtemp(prefix='quiz-archive-verify21-',dir='/dev/shm')
def digest(path):
 h=hashlib.sha256()
 with open(path,'rb') as f:
  for b in iter(lambda:f.read(1024*1024),b''):h.update(b)
 return h.hexdigest()
try:
 command=['tar','--extract','--gzip','--file=-','--directory='+work,'--numeric-owner','--same-owner','--same-permissions','--acls','--xattrs','--xattrs-include=*','--delay-directory-restore']
 with tempfile.TemporaryFile() as errors:
  child=subprocess.Popen(command,stdin=subprocess.PIPE,stdout=subprocess.DEVNULL,stderr=errors)
  try:
   shutil.copyfileobj(sys.stdin.buffer,child.stdin,1024*1024)
   child.stdin.close();child.stdin=None
   child.wait(timeout=300)
   errors.seek(0);err=errors.read()
  except BaseException:
   child.kill();child.wait();raise
 assert child.returncode==0, 'GNU tar restore failed: '+err.decode(errors='replace')[-2000:]
 actual=[]
 for e in expected:
  relative=pathlib.PurePosixPath(e['path'])
  assert not relative.is_absolute() and '..' not in relative.parts
  p=pathlib.Path(work)/basename
  if e['path']!='.':p=p.joinpath(*relative.parts)
  s=p.lstat(); kind='file' if stat.S_ISREG(s.st_mode) else 'dir' if stat.S_ISDIR(s.st_mode) else 'symlink' if stat.S_ISLNK(s.st_mode) else 'unsupported'
  row={'path':e['path'],'type':kind,'mode':stat.S_IMODE(s.st_mode),'uid':s.st_uid,'gid':s.st_gid,'mtime_ns':s.st_mtime_ns,'xattrs':{k:base64.b64encode(os.getxattr(p,k,follow_symlinks=False)).decode() for k in sorted(os.listxattr(p,follow_symlinks=False))}}
  if kind=='file':row.update(size=s.st_size,sha256=digest(p))
  if kind=='symlink':row.update(target=os.readlink(p))
  wanted={k:e[k] for k in row}
  assert row==wanted, 'restored content or Unix metadata differs: '+e['path']
  actual.append(row)
 actual.sort(key=lambda x:x['path'])
 fingerprint=hashlib.sha256(json.dumps(actual,sort_keys=True,separators=(',',':')).encode()).hexdigest()
 print(json.dumps({'verdict':'ACCEPT','entry_count':len(actual),'restored_sha256':fingerprint,'hostname':socket.gethostname(),'scratch_fstype':'tmpfs','scratch_cleaned':True}))
finally:
 assert pathlib.Path(work).parent==pathlib.Path('/dev/shm') and pathlib.Path(work).name.startswith('quiz-archive-verify21-')
 shutil.rmtree(work)
'''


def digest(path: Path) -> str:
    h = hashlib.sha256()
    with path.open('rb') as f:
        for block in iter(lambda: f.read(1024 * 1024), b''):
            h.update(block)
    return h.hexdigest()


def member_path(member: tarfile.TarInfo, basename: str) -> str:
    p = PurePosixPath(member.name)
    if p.is_absolute() or '..' in p.parts or not p.parts or p.parts[0] != basename:
        raise ValueError('archive member escapes its approved root')
    if not (member.isfile() or member.isdir() or member.issym()):
        raise ValueError('hard links and special files require separate handling')
    if member.size > MAX_FILE_BYTES:
        raise ValueError('entry exceeds bounded Linux restoration budget')
    return PurePosixPath(*p.parts[1:]).as_posix() if len(p.parts) > 1 else '.'


def projection(e: dict) -> dict:
    fields = ['path', 'type', 'mode', 'uid', 'gid', 'mtime_ns', 'xattrs']
    if e['type'] == 'file':
        fields += ['size', 'sha256']
    if e['type'] == 'symlink':
        fields += ['target']
    return {k: e[k] for k in fields}


def send_chunk(chunk: Path, entries: list[dict], basename: str) -> dict:
    request = {'entries': entries, 'basename': basename,
               'logical_bytes': sum(e['size'] for e in entries if e['type'] == 'file')}
    command = 'python3 -c ' + shlex.quote(REMOTE)
    child = subprocess.Popen(['ssh', '-i', KEY, '-o', 'BatchMode=yes', '-o', 'ConnectTimeout=20',
                              '-o', 'ServerAliveInterval=15', '-o', 'ServerAliveCountMax=4', '-o',
                              'StrictHostKeyChecking=yes', HOST, command],
                             stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    try:
        child.stdin.write(json.dumps(request, separators=(',', ':')).encode() + b'\n')
        with chunk.open('rb') as stream:
            shutil.copyfileobj(stream, child.stdin, 1024 * 1024)
        child.stdin.close()
        child.stdin = None
        out, err = child.communicate(timeout=360)
    except BaseException:
        child.kill()
        child.wait()
        raise
    if child.returncode:
        raise RuntimeError('Linux restore refused: ' + err.decode(errors='replace')[-2500:])
    result = json.loads(out)
    wanted = sorted((projection(e) for e in entries), key=lambda x: x['path'])
    expected_sha = hashlib.sha256(json.dumps(wanted, sort_keys=True, separators=(',', ':')).encode()).hexdigest()
    if result.get('verdict') != 'ACCEPT' or result.get('entry_count') != len(entries) or result.get('restored_sha256') != expected_sha or result.get('scratch_cleaned') is not True:
        raise ValueError('Linux restoration proof does not match source entries')
    return dict(result, chunk_sha256=digest(chunk), expected_sha256=expected_sha)


def verify(archive: Path, manifest_path: Path, receipt: Path) -> dict:
    base = DESTINATION.resolve()
    for p in (archive, manifest_path, receipt):
        if not p.resolve().is_relative_to(base):
            raise ValueError('archive evidence must remain in approved persistent backup directory')
    if receipt.exists():
        raise ValueError('refusing to overwrite immutable restore receipt')
    manifest = json.loads(manifest_path.read_text(encoding='utf-8'))
    root = PurePosixPath(manifest['root'])
    if root.parent.as_posix() != '/opt/ll/releases':
        raise ValueError('unexpected source root')
    rows = {e['path']: e for e in manifest['entries']}
    if len(rows) != manifest['entry_count']:
        raise ValueError('manifest entry count or uniqueness differs')
    seen: set[str] = set()
    links = {name for name, e in rows.items() if e['type'] == 'symlink'}
    chunks = []
    archive_sha = digest(archive)
    with tempfile.TemporaryDirectory(prefix='restore-chunks-', dir=base) as scratch:
        scratch = Path(scratch)
        with tarfile.open(archive, 'r:*') as source:
            batch = []
            batch_bytes = 0

            def flush():
                nonlocal batch, batch_bytes
                if not batch:
                    return
                chunk = scratch / 'chunk.tar.gz'
                with tarfile.open(chunk, 'w:gz', compresslevel=1, format=tarfile.PAX_FORMAT) as target:
                    for info, _ in batch:
                        stream = source.extractfile(info) if info.isfile() else None
                        try:
                            target.addfile(copy.copy(info), stream)
                        finally:
                            if stream is not None:
                                stream.close()
                result = send_chunk(chunk, [e for _, e in batch], root.name)
                chunks.append(result)
                print(json.dumps({'chunk': len(chunks), 'entries': result['entry_count'],
                                  'verified_total': len(seen), 'total': len(rows)}), flush=True)
                chunk.unlink()
                batch = []
                batch_bytes = 0

            # getmembers permits sequential re-reading of the original stream
            # while constructing chunks; no source member is extracted locally.
            for info in source.getmembers():
                name = member_path(info, root.name)
                if name not in rows or name in seen:
                    raise ValueError('archive member absent from manifest or duplicated')
                if batch and (batch_bytes + info.size > CHUNK_BYTES or len(batch) >= 256):
                    flush()
                expected = rows[name]
                kind = 'file' if info.isfile() else 'dir' if info.isdir() else 'symlink'
                if kind != expected['type']:
                    raise ValueError('archive and source entry types differ')
                if any(parent.as_posix() in links for parent in PurePosixPath(name).parents):
                    raise ValueError('archive has a member below a symbolic link')
                seen.add(name)
                batch.append((info, expected))
                batch_bytes += info.size
            flush()
    if seen != set(rows) or sum(x['entry_count'] for x in chunks) != len(rows):
        raise ValueError('not every source entry was restored')
    if digest(archive) != archive_sha:
        raise ValueError('original archive changed during Linux restoration')
    result = {'verdict': 'ACCEPT', 'verifier': 'linux_chunk_restore',
              'archive_sha256': archive_sha,
              'source_manifest_sha256': manifest['manifest_sha256'],
              'source_manifest_file_sha256': digest(manifest_path),
              'entry_count': len(rows), 'chunks': chunks,
              'all_source_entries_restored': True,
              'unix_metadata': ['mode', 'uid', 'gid', 'mtime_ns', 'xattrs', 'symlink target'],
              'original_sources_deleted': False}
    with receipt.open('x', encoding='utf-8', newline='\n') as f:
        json.dump(result, f, sort_keys=True, indent=2)
        f.write('\n')
        f.flush()
        os.fsync(f.fileno())
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--archive', required=True, type=Path)
    parser.add_argument('--manifest', required=True, type=Path)
    parser.add_argument('--receipt', required=True, type=Path)
    a = parser.parse_args()
    result = verify(a.archive, a.manifest, a.receipt)
    print(json.dumps({k: v for k, v in result.items() if k != 'chunks'}))


if __name__ == '__main__':
    main()
