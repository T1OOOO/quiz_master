"""Bounded RAM filesystem for disposable, full SQLite restoration checks only."""
from __future__ import annotations
import argparse,datetime,hashlib,json,os,re,socket,sqlite3,stat,subprocess,time
from pathlib import Path,PurePosixPath

SIZE=256*1024*1024
RESERVE=1024*1024*1024
PARENT=PurePosixPath('/opt/quiz-master/releases')
PVC='7fc2428f-4146-4c78-a26d-2347d9f3b7bf'

class GuardError(RuntimeError):pass

def validate_stage_name(stage: str,build: str) -> PurePosixPath:
 p=PurePosixPath(stage)
 if not re.fullmatch(r'quiz-2026\.10\.20-atlas-[0-9a-f]{8}',build) or str(p)!=stage or p.parent!=PARENT or p.name!=build:
  raise GuardError('not the literal candidate release stage')
 return p

def validate_memory(available: int) -> None:
 if available<SIZE+RESERVE:raise GuardError('RAM proof requires its full budget plus 1GiB available reserve')

def validate_mount(mount: dict,stage: str,build: str) -> None:
 validate_stage_name(stage,build)
 if mount.get('target')!=stage+'/volatile-checks' or mount.get('source')!='qm-checks-'+build or mount.get('fstype')!='tmpfs':
  raise GuardError('mount is not this candidate RAM filesystem')
 if not {'nosuid','nodev','noexec'}<=set(mount.get('options','').split(',')):
  raise GuardError('RAM mount lost its safe flags')

def regular(path: Path) -> None:
 if path.is_symlink() or not path.is_file() or (os.name=='posix' and path.resolve()!=path.absolute()):raise GuardError('expected a regular non-symlink file')

def digest(path: Path) -> str:
 regular(path);h=hashlib.sha256()
 with path.open('rb') as f:
  for chunk in iter(lambda:f.read(1024*1024),b''):h.update(chunk)
 return h.hexdigest()

def integrity(path: Path,*,immutable=False) -> str:
 regular(path)
 try:
  with path.open('rb') as f:
   if f.read(16)!=b'SQLite format 3\x00':raise GuardError('invalid SQLite header')
  uri=path.resolve().as_uri()+'?mode=ro'+('&immutable=1' if immutable else '')
  conn=sqlite3.connect(uri,uri=True)
  try:result=conn.execute('pragma integrity_check').fetchone()[0]
  finally:conn.close()
 except sqlite3.Error as e:raise GuardError('SQLite integrity check failed') from e
 if result!='ok':raise GuardError('SQLite integrity is not ok')
 return result

def verify_restore(backup: Path,restored: Path) -> dict:
 regular(backup);regular(restored)
 if backup.samefile(restored):raise GuardError('restore must be an independent copy')
 a,b=digest(backup),digest(restored)
 if a!=b:raise GuardError('restored bytes differ from backup')
 integrity(backup,immutable=True);integrity(restored,immutable=True)
 return {'backup_sha256':a,'restored_sha256':b,'bytes':backup.stat().st_size,'integrity':'ok'}

def validate_http_receipt(value: dict) -> None:
 for key,expected in [('visible_banks',105),('visible_slots',4520),('article_refs',241)]:
  if value.get(key)!=expected:raise GuardError('HTTP grading/article gate differs: '+key)

def output(*args) -> str:return subprocess.check_output(args,text=True)

def guard_stage(stage: str,build: str) -> Path:
 validate_stage_name(stage,build)
 if os.name!='posix' or os.geteuid()!=0 or socket.gethostname()!='racknerd-f0269d5':raise GuardError('wrong host or user')
 p=Path(stage)
 if p.is_symlink() or not p.is_dir() or p.resolve()!=p or p.stat().st_uid!=0 or stat.S_IMODE(p.stat().st_mode)!=0o700:raise GuardError('stage ownership/resolution differs')
 return p

def descriptor(path: Path) -> dict|None:
 p=subprocess.run(['findmnt','--json','--mountpoint',str(path),'--output','TARGET,SOURCE,FSTYPE,OPTIONS'],capture_output=True,text=True)
 if p.returncode==1:return None
 if p.returncode:raise GuardError('cannot inspect candidate mount')
 rows=json.loads(p.stdout).get('filesystems',[])
 if len(rows)!=1:raise GuardError('ambiguous mount descriptor')
 return rows[0]

def owner(stage: Path,build: str,*,create=False) -> dict:
 expected={'build_id':build,'target':str(stage/'volatile-checks'),'source':'qm-checks-'+build,'size_bytes':SIZE}
 marker=stage/'volatile-owner.json'
 if create and not marker.exists():
  with marker.open('x',encoding='utf-8') as f:
   os.chmod(marker,0o600);json.dump(expected,f,sort_keys=True);f.flush();os.fsync(f.fileno())
 regular(marker)
 if marker.stat().st_uid!=0 or json.loads(marker.read_text())!=expected:raise GuardError('RAM owner marker differs')
 return expected

def owned_mount(stage: Path,build: str) -> dict:
 owner(stage,build);m=descriptor(stage/'volatile-checks')
 if m is None:raise GuardError('candidate RAM filesystem is not mounted')
 validate_mount(m,str(stage),build)
 if stat.S_IMODE((stage/'volatile-checks').stat().st_mode)!=0o700:raise GuardError('RAM mount permissions differ')
 s=os.statvfs(stage/'volatile-checks')
 if s.f_blocks*s.f_frsize!=SIZE:raise GuardError('RAM mount budget differs')
 return m

def mount(stage: Path,build: str) -> dict:
 mem={k:int(v.split()[0])*1024 for line in Path('/proc/meminfo').read_text().splitlines() if (pair:=line.split(':',1)) and len(pair)==2 for k,v in [pair] if k=='MemAvailable'}
 available=mem.get('MemAvailable',0);validate_memory(available)
 if output('kubectl','get','pvc','quiz-data','-n','quiz-master','-o','jsonpath={.metadata.uid}')!=PVC:raise GuardError('wrong PVC context')
 nodes=json.loads(output('kubectl','get','nodes','-o','json'))['items']
 if len(nodes)!=1:raise GuardError('wrong node count')
 conditions={c['type']:c['status'] for c in nodes[0]['status']['conditions']}
 if any(conditions.get(k)!=v for k,v in [('Ready','True'),('DiskPressure','False'),('MemoryPressure','False')]):raise GuardError('node pressure/readiness gate failed')
 path=stage/'volatile-checks';existing=descriptor(path)
 if existing is not None:
  owned_mount(stage,build)
  return {'mounted':True,'already_owned':True,'available_memory_bytes':available}
 if path.exists() and (path.is_symlink() or not path.is_dir() or path.stat().st_uid!=0 or any(path.iterdir())):raise GuardError('RAM target is not an empty owned directory')
 path.mkdir(mode=0o700,exist_ok=True)
 if stat.S_IMODE(path.stat().st_mode)!=0o700:raise GuardError('RAM target permissions differ')
 info=owner(stage,build,create=True)
 subprocess.run(['mount','-t','tmpfs','-o','size=268435456,mode=0700,nodev,nosuid,noexec',info['source'],str(path)],check=True)
 owned_mount(stage,build)
 return {'mounted':True,'size_bytes':SIZE,'available_memory_bytes':available,'reserve_bytes':RESERVE}

def unmount(stage: Path,build: str) -> dict:
 path=stage/'volatile-checks'
 if descriptor(path) is None:return {'mounted':False,'already_unmounted':True}
 owned_mount(stage,build)
 ids=output('docker','ps','-q').split()
 for ident in ids:
  mounts=json.loads(output('docker','inspect','--format','{{json .Mounts}}',ident))
  for m in mounts:
   source=PurePosixPath(m.get('Source','/'))
   if source==PurePosixPath(path) or PurePosixPath(path) in source.parents:raise GuardError('running container still uses the RAM proof')
 # Normal unmount fails closed on remaining host readers; never force/lazy.
 subprocess.run(['umount',str(path)],check=True)
 if descriptor(path) is not None:raise GuardError('RAM mount remains present')
 if path.is_symlink() or any(path.iterdir()):raise GuardError('underlying directory is not empty')
 path.rmdir()
 return {'mounted':False,'released_bytes':SIZE}

def record(stage: Path,build: str,phase: str,image_id: str,kind: str) -> dict:
 owned_mount(stage,build)
 if not re.fullmatch(r'sha256:[0-9a-f]{64}',image_id or ''):raise GuardError('invalid Docker image identity')
 actual=json.loads(output('docker','image','inspect','quiz-master:'+build))[0]['Id']
 if actual!=image_id:raise GuardError('candidate Docker image changed')
 backup=Path('/opt/quiz-master/backups')/(build+'.sqlite')
 regular(backup)
 if backup.resolve()!=backup or backup.stat().st_uid!=0:raise GuardError('backup ownership/resolution differs')
 common={'build_id':build,'phase':phase,'kind':kind,'image_docker_id':image_id,'input_sha256':digest(stage/'release-inputs.json'),'recorded_at_utc':datetime.datetime.now(datetime.timezone.utc).isoformat()}
 if kind=='restore':
  prefix='publish-' if phase=='publish' else 'resume-' if phase=='resume-prepare' else ''
  restored=stage/'volatile-checks'/(prefix+'restore-proof.sqlite')
  proof=verify_restore(backup,restored)
 else:
  prefix='resume-' if phase=='resume-prepare' else ''
  db=stage/'volatile-checks'/(prefix+'rehearsal-data')/'quiz.db'
  if db.resolve()!=db:raise GuardError('rehearsal path is a symlink')
  integrity(db)
  http=json.loads((stage/'rehearsal-http.json').read_text());validate_http_receipt(http)
  proof={'backup_sha256':digest(backup),'integrity':'ok','http':http}
 value={**common,**proof};target=stage/f'sql-proof-{phase}-{kind}-{time.time_ns()}.json'
 with target.open('x',encoding='utf-8') as f:
  os.chmod(target,0o600);json.dump(value,f,sort_keys=True);f.write('\n');f.flush();os.fsync(f.fileno())
 fd=os.open(stage,os.O_RDONLY|os.O_DIRECTORY)
 try:os.fsync(fd)
 finally:os.close(fd)
 return value

def main():
 p=argparse.ArgumentParser(description=__doc__);p.add_argument('action',choices=['mount','unmount','record-restore','record-rehearsal']);p.add_argument('--stage',required=True);p.add_argument('--build-id',required=True);p.add_argument('--phase',choices=['prepare','resume-prepare','publish'],default='prepare');p.add_argument('--image-id')
 a=p.parse_args();stage=guard_stage(a.stage,a.build_id)
 if a.action=='mount':value=mount(stage,a.build_id)
 elif a.action=='unmount':value=unmount(stage,a.build_id)
 else:value=record(stage,a.build_id,a.phase,a.image_id,'restore' if a.action=='record-restore' else 'rehearsal')
 print(json.dumps(value,sort_keys=True))

if __name__=='__main__':main()
