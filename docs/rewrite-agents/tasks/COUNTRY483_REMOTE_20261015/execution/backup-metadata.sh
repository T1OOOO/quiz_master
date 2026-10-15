set -euo pipefail
test "$(hostname)" = racknerd-f0269d5
python3 - <<'BACKUP_METADATA'
import pathlib,os,json,stat
root=pathlib.Path('/opt/quiz-master/backups');rows=[]
for p in sorted(root.iterdir()):
 s=p.lstat()
 rows.append(dict(name=p.name,regular=stat.S_ISREG(s.st_mode),symlink=stat.S_ISLNK(s.st_mode),bytes=s.st_size,allocated_bytes=s.st_blocks*512,mode=oct(stat.S_IMODE(s.st_mode)),mtime_ns=s.st_mtime_ns))
print(json.dumps(dict(root=str(root),entries=rows)))
BACKUP_METADATA
