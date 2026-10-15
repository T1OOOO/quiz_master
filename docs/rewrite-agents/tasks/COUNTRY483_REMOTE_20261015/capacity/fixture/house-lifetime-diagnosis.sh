set -euo pipefail
python3 - <<'HOUSE_CONNECTION_DIAGNOSIS'
import tempfile,sqlite3,hashlib,json,gc,os
from pathlib import Path
from contextlib import closing
def require(ok,message):
    if not ok:raise ValueError(message)
def no_process_use(root):
    prefix=str(root).encode()
    for proc in Path('/proc').iterdir():
        if not proc.name.isdecimal():continue
        try:
            require(not any(prefix in arg for arg in (proc/'cmdline').read_bytes().split(b'\0')),'backup path in active process command')
            for link in (proc/'fd').iterdir():
                try:target=os.readlink(link)
                except FileNotFoundError:continue
                require(not target.startswith(str(root)+'/'),'backup open by active process')
        except (FileNotFoundError,ProcessLookupError):continue

original_source='"""Finite, reviewed deduplication of cold October 12 Quiz Master SQLite copies."""\nfrom pathlib import Path\nimport hashlib,json,os,re,sqlite3,stat\n\nBACKUPS=Path(\'/opt/quiz-master/backups\')\nNAME=re.compile(r\'quiz-2026\\.10\\.(?:13|14)-[A-Za-z0-9._-]+\\.sqlite\')\n\ndef check(name,group):\n    if not isinstance(name,str) or not NAME.fullmatch(name):raise ValueError(\'cold backup name required\')\n    p=BACKUPS/name;s=p.lstat()\n    if not stat.S_ISREG(s.st_mode) or stat.S_IMODE(s.st_mode)!=0o600 or s.st_nlink!=1 or s.st_uid!=os.geteuid():raise ValueError(\'private owned regular single-link backup required\')\n    if any(Path(str(p)+suffix).exists() for suffix in [\'-wal\',\'-shm\',\'-journal\']):raise ValueError(\'backup has live journal\')\n    h=hashlib.sha256()\n    with p.open(\'rb\') as f:\n        opened=os.fstat(f.fileno())\n        if (opened.st_dev,opened.st_ino)!=(s.st_dev,s.st_ino):raise ValueError(\'backup identity changed\')\n        while chunk:=f.read(1048576):h.update(chunk)\n    after=p.lstat()\n    fields=lambda x:(x.st_dev,x.st_ino,x.st_size,x.st_mtime_ns,x.st_mode,x.st_nlink)\n    if fields(s)!=fields(after) or s.st_size!=group[\'bytes\'] or h.hexdigest()!=group[\'sha256\']:raise ValueError(\'backup bytes or identity changed\')\n    return p\n\ndef run(plan):\n    if BACKUPS.resolve()!=BACKUPS or plan[\'schema_version\']!=\'qm-cold-backup-dedup/v1\':raise ValueError(\'backup boundary/schema differs\')\n    groups=plan[\'groups\'];names=[n for g in groups for n in [g[\'keeper\'],*g[\'duplicates\']]]\n    if len(names)!=len(set(names)) or len(names)!=plan[\'expected_files\']:raise ValueError(\'duplicate/changed plan names\')\n    # Validate the entire frozen plan before the first unlink.\n    for group in groups:\n        for name in [group[\'keeper\'],*group[\'duplicates\']]:check(name,group)\n        with sqlite3.connect(check(group[\'keeper\'],group).as_uri()+\'?mode=ro&immutable=1\',uri=True) as db:\n            if db.execute(\'pragma integrity_check\').fetchone()!=(\'ok\',):raise ValueError(\'keeper integrity failed\')\n    removed=[]\n    for group in groups:\n        for name in group[\'duplicates\']:\n            check(group[\'keeper\'],group)\n            check(name,group).unlink()\n            removed.append({\'removed\':name,\'restore_from\':group[\'keeper\'],\'sha256\':group[\'sha256\'],\'bytes\':group[\'bytes\']})\n            print(json.dumps(removed[-1]),flush=True)\n    for group in groups:check(group[\'keeper\'],group)\n    return {\'removed_aliases\':removed,\'unique_states_retained\':len(groups),\'logical_bytes_removed\':sum(x[\'bytes\'] for x in removed),\'method\':\'Only byte-identical cold copies removed; recreate any old filename by copying its retained private raw SQLite keeper.\'}\n'
closed_source='from contextlib import closing\n"""Finite, reviewed deduplication of cold October 12 Quiz Master SQLite copies."""\nfrom pathlib import Path\nimport hashlib,json,os,re,sqlite3,stat\n\nBACKUPS=Path(\'/opt/quiz-master/backups\')\nNAME=re.compile(r\'quiz-2026\\.10\\.(?:13|14)-[A-Za-z0-9._-]+\\.sqlite\')\n\ndef check(name,group):\n    if not isinstance(name,str) or not NAME.fullmatch(name):raise ValueError(\'cold backup name required\')\n    p=BACKUPS/name;s=p.lstat()\n    if not stat.S_ISREG(s.st_mode) or stat.S_IMODE(s.st_mode)!=0o600 or s.st_nlink!=1 or s.st_uid!=os.geteuid():raise ValueError(\'private owned regular single-link backup required\')\n    if any(Path(str(p)+suffix).exists() for suffix in [\'-wal\',\'-shm\',\'-journal\']):raise ValueError(\'backup has live journal\')\n    h=hashlib.sha256()\n    with p.open(\'rb\') as f:\n        opened=os.fstat(f.fileno())\n        if (opened.st_dev,opened.st_ino)!=(s.st_dev,s.st_ino):raise ValueError(\'backup identity changed\')\n        while chunk:=f.read(1048576):h.update(chunk)\n    after=p.lstat()\n    fields=lambda x:(x.st_dev,x.st_ino,x.st_size,x.st_mtime_ns,x.st_mode,x.st_nlink)\n    if fields(s)!=fields(after) or s.st_size!=group[\'bytes\'] or h.hexdigest()!=group[\'sha256\']:raise ValueError(\'backup bytes or identity changed\')\n    return p\n\ndef run(plan):\n    if BACKUPS.resolve()!=BACKUPS or plan[\'schema_version\']!=\'qm-cold-backup-dedup/v1\':raise ValueError(\'backup boundary/schema differs\')\n    groups=plan[\'groups\'];names=[n for g in groups for n in [g[\'keeper\'],*g[\'duplicates\']]]\n    if len(names)!=len(set(names)) or len(names)!=plan[\'expected_files\']:raise ValueError(\'duplicate/changed plan names\')\n    # Validate the entire frozen plan before the first unlink.\n    for group in groups:\n        for name in [group[\'keeper\'],*group[\'duplicates\']]:check(name,group)\n        with closing(sqlite3.connect(check(group[\'keeper\'],group).as_uri()+\'?mode=ro&immutable=1\',uri=True)) as db:\n            if db.execute(\'pragma integrity_check\').fetchone()!=(\'ok\',):raise ValueError(\'keeper integrity failed\')\n    removed=[]\n    for group in groups:\n        for name in group[\'duplicates\']:\n            check(group[\'keeper\'],group)\n            check(name,group).unlink()\n            removed.append({\'removed\':name,\'restore_from\':group[\'keeper\'],\'sha256\':group[\'sha256\'],\'bytes\':group[\'bytes\']})\n            print(json.dumps(removed[-1]),flush=True)\n    for group in groups:check(group[\'keeper\'],group)\n    return {\'removed_aliases\':removed,\'unique_states_retained\':len(groups),\'logical_bytes_removed\':sum(x[\'bytes\'] for x in removed),\'method\':\'Only byte-identical cold copies removed; recreate any old filename by copying its retained private raw SQLite keeper.\'}\n'

def trial(source):
 with tempfile.TemporaryDirectory(prefix='qm-house-lifetime-diagnostic-') as tmp:
  root=Path(tmp);env={'__name__':'qm_diagnostic_house'};exec(compile(source,'pinned-house-diagnostic','exec'),env);env['BACKUPS']=root
  groups=[]
  for i in range(2):
   keeper=f'quiz-2026.10.13-fixture-{i}.sqlite';alias=f'quiz-2026.10.13-fixture-{i}.restore-proof.sqlite'
   with closing(sqlite3.connect(root/keeper)) as db:db.execute('create table fixture(value text)')
   raw=(root/keeper).read_bytes();(root/alias).write_bytes(raw)
   (root/keeper).chmod(0o600);(root/alias).chmod(0o600)
   groups.append(dict(keeper=keeper,duplicates=[alias],bytes=len(raw),sha256=hashlib.sha256(raw).hexdigest()))
  original_check=env['check']
  def guarded(name,group):no_process_use(root);return original_check(name,group)
  env['check']=guarded
  try:
   receipt=env['run'](dict(schema_version='qm-cold-backup-dedup/v1',groups=groups,expected_files=4))
   result=dict(guard_failure=False,removed=len(receipt['removed_aliases']),keepers_remaining=sum((root/g['keeper']).exists() for g in groups))
  except ValueError as error:
   result=dict(guard_failure=True,error=str(error),aliases_remaining=sum((root/g['duplicates'][0]).exists() for g in groups))
  gc.collect();return result
old=trial(original_source);new=trial(closed_source)
assert old['guard_failure'] and old['aliases_remaining']==2 and old['error']=='backup open by active process'
assert not new['guard_failure'] and new['removed']==2 and new['keepers_remaining']==2
print(json.dumps(dict(original_house=old,closing_context_house=new,production_database_used=False,production_cleanup_performed=False)))

HOUSE_CONNECTION_DIAGNOSIS
