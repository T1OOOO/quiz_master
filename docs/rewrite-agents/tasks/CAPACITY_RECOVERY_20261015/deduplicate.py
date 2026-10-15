"""Finite, reviewed deduplication of cold October 12 Quiz Master SQLite copies."""
from pathlib import Path
import hashlib,json,os,re,sqlite3,stat

BACKUPS=Path('/opt/quiz-master/backups')
NAME=re.compile(r'quiz-2026\.10\.12-[A-Za-z0-9._-]+\.sqlite')

def check(name,group):
    if not isinstance(name,str) or not NAME.fullmatch(name):raise ValueError('cold backup name required')
    p=BACKUPS/name;s=p.lstat()
    if not stat.S_ISREG(s.st_mode) or stat.S_IMODE(s.st_mode)!=0o600 or s.st_nlink!=1 or s.st_uid!=os.geteuid():raise ValueError('private owned regular single-link backup required')
    if any(Path(str(p)+suffix).exists() for suffix in ['-wal','-shm','-journal']):raise ValueError('backup has live journal')
    h=hashlib.sha256()
    with p.open('rb') as f:
        opened=os.fstat(f.fileno())
        if (opened.st_dev,opened.st_ino)!=(s.st_dev,s.st_ino):raise ValueError('backup identity changed')
        while chunk:=f.read(1048576):h.update(chunk)
    after=p.lstat()
    fields=lambda x:(x.st_dev,x.st_ino,x.st_size,x.st_mtime_ns,x.st_mode,x.st_nlink)
    if fields(s)!=fields(after) or s.st_size!=group['bytes'] or h.hexdigest()!=group['sha256']:raise ValueError('backup bytes or identity changed')
    return p

def run(plan):
    if BACKUPS.resolve()!=BACKUPS or plan['schema_version']!='qm-cold-backup-dedup/v1':raise ValueError('backup boundary/schema differs')
    groups=plan['groups'];names=[n for g in groups for n in [g['keeper'],*g['duplicates']]]
    if len(names)!=len(set(names)) or len(names)!=plan['expected_files']:raise ValueError('duplicate/changed plan names')
    # Validate the entire frozen plan before the first unlink.
    for group in groups:
        for name in [group['keeper'],*group['duplicates']]:check(name,group)
        with sqlite3.connect(check(group['keeper'],group).as_uri()+'?mode=ro&immutable=1',uri=True) as db:
            if db.execute('pragma integrity_check').fetchone()!=('ok',):raise ValueError('keeper integrity failed')
    removed=[]
    for group in groups:
        for name in group['duplicates']:
            check(group['keeper'],group)
            check(name,group).unlink()
            removed.append({'removed':name,'restore_from':group['keeper'],'sha256':group['sha256'],'bytes':group['bytes']})
            print(json.dumps(removed[-1]),flush=True)
    for group in groups:check(group['keeper'],group)
    return {'removed_aliases':removed,'unique_states_retained':len(groups),'logical_bytes_removed':sum(x['bytes'] for x in removed),'method':'Only byte-identical cold copies removed; recreate any old filename by copying its retained private raw SQLite keeper.'}
