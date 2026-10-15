set -euo pipefail
python3 - <<'SQLITE_FIXTURE_DIAGNOSIS'
import sqlite3,tempfile,pathlib,os,json
with tempfile.TemporaryDirectory(prefix='qm-sqlite-lifetime-diagnostic-') as tmp:
 root=pathlib.Path(tmp)
 def make(name,close):
  p=root/name
  with sqlite3.connect(p) as db:db.execute('create table fixture(value text)')
  if close:db.close()
  return p
 def opened(p):
  matches=[]
  for fd in pathlib.Path('/proc/self/fd').iterdir():
   try:target=os.readlink(fd)
   except FileNotFoundError:continue
   if target==str(p):matches.append(fd.name)
  return len(matches)
 old=make('context-only.sqlite',False);fixed=make('explicit-close.sqlite',True)
 print(json.dumps(dict(context_only_open_fd_count=opened(old),explicit_close_open_fd_count=opened(fixed),production_data_used=False)))
SQLITE_FIXTURE_DIAGNOSIS
