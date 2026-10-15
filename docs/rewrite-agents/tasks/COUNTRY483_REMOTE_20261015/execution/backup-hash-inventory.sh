set -euo pipefail
test "$(hostname)" = racknerd-f0269d5
python3 - <<'BACKUP_HASH_INVENTORY'
import pathlib,os,json,stat,hashlib,sqlite3,time
root=pathlib.Path('/opt/quiz-master/backups');rows=[];checked={};start=time.monotonic()
for p in sorted(root.glob('quiz-*.sqlite')):
 s=p.lstat()
 assert stat.S_ISREG(s.st_mode) and not p.is_symlink() and s.st_nlink==1 and p.resolve().parent==root
 assert stat.S_IMODE(s.st_mode)==0o600 and s.st_uid==0
 with p.open('rb') as stream:digest=hashlib.file_digest(stream,'sha256').hexdigest()
 if digest not in checked:
  with sqlite3.connect(p.as_uri()+'?mode=ro&immutable=1',uri=True) as db:integrity=db.execute('pragma integrity_check').fetchall()
  assert integrity==[('ok',)];checked[digest]=True
 after=p.lstat();assert (s.st_dev,s.st_ino,s.st_size,s.st_mtime_ns,s.st_mode,s.st_uid,s.st_gid,s.st_nlink)==(after.st_dev,after.st_ino,after.st_size,after.st_mtime_ns,after.st_mode,after.st_uid,after.st_gid,after.st_nlink)
 rows.append(dict(path=str(p),sha256=digest,integrity='ok',bytes=s.st_size,allocated_bytes=s.st_blocks*512,dev=s.st_dev,ino=s.st_ino,mtime_ns=s.st_mtime_ns,mode=stat.S_IMODE(s.st_mode),uid=s.st_uid,gid=s.st_gid,nlink=s.st_nlink))
print(json.dumps(dict(schema_version='qm-readonly-backup-inventory/v1',entries=rows,unique_states=len(checked),elapsed_seconds=round(time.monotonic()-start,3),mutation_performed=False)))
BACKUP_HASH_INVENTORY
