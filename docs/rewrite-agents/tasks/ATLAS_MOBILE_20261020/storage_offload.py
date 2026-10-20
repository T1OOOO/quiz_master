#!/usr/bin/env python3
"""Guarded, reversible offload of one reviewed, literal storage set.

Default --plan is read-only.  --stage copies a verified tar archive to the local
restricted cache but cannot delete remotely.  --apply requires an independent
review receipt and the exact staged manifest, then rechecks production state and
all source hashes while holding DEPLOY.lock before unlinking the literal allowlist.
"""
from __future__ import annotations
import argparse, base64, hashlib, json, os, shutil, stat, subprocess, tarfile, tempfile
from pathlib import Path, PurePosixPath

ROOT = Path(__file__).resolve().parents[4]
HERE = Path(__file__).parent
PLAN_PATH = HERE / 'storage-offload-plan.json'
PLAN_SHA256 = '2d4938a4b6dda80c045a7bd35a13ee6b80096c31bd5f531e14e823e5d62e5cc0'
HOST = '192.3.164.184'
KEY = Path(r'C:\Users\Alexey_Matvienko\.ssh\ll_deploy_ed25519')
LOCK = '/opt/quiz-master/DEPLOY.lock'
AUTHOR_PROVIDER = 'openai'

def canonical(value: object) -> bytes:
    return json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(',', ':')).encode('utf-8')
def sha(data: bytes) -> str: return hashlib.sha256(data).hexdigest()
def read_plan() -> dict:
    raw = PLAN_PATH.read_bytes()
    if sha(raw) != PLAN_SHA256:
        raise RuntimeError('storage-offload-extra plan hash differs from reviewed candidate')
    plan = json.loads(raw)
    if plan.get('contract') != 'quiz-master-storage-offload-grid/v1': raise RuntimeError('unexpected plan contract')
    paths = [x.get('path') for x in plan.get('targets', [])]
    if len(paths) != 6 or len(set(paths)) != len(paths): raise RuntimeError('literal target set is incomplete or duplicated')
    if any(not isinstance(p, str) or not p.startswith('/opt/quiz-master/releases/quiz-2026.10.20-touch-b5863403/') or '..' in PurePosixPath(p).parts for p in paths):
        raise RuntimeError('target path escapes approved root')
    return plan
def receipt(path: Path) -> None:
    if path.is_symlink() or not path.is_file(): raise RuntimeError('review receipt must be a regular file')
    item = json.loads(path.read_text(encoding='utf-8'))
    required = {'decision','reviewer_provider','plan_sha256','reviewed_at_utc'}
    if not required <= item.keys() or item['decision'] != 'ACCEPT': raise RuntimeError('review receipt is not ACCEPT')
    if item['reviewer_provider'] == AUTHOR_PROVIDER: raise RuntimeError('reviewer must be a different provider')
    if item['plan_sha256'].lower() != PLAN_SHA256: raise RuntimeError('receipt has another plan hash')
def ssh(code: str, *, stdout=None) -> bytes:
    cmd = ['ssh','-i',str(KEY),'-o','BatchMode=yes','-o','StrictHostKeyChecking=yes',f'root@{HOST}','python3 -']
    if stdout is not None:
        done = subprocess.run(cmd, input=code.encode(), stdout=stdout, stderr=subprocess.PIPE, check=False)
        if done.returncode: raise RuntimeError('remote tar stream failed: '+done.stderr.decode(errors='replace')[-400:])
        return b''
    done = subprocess.run(cmd, input=code.encode(), stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False)
    if done.returncode: raise RuntimeError('remote guard failed: '+done.stderr.decode(errors='replace')[-800:])
    return done.stdout
def remote_program(plan: dict, expected: object | None = None, delete: bool = False) -> str:
    encoded = base64.b64encode(canonical(plan['targets'])).decode()
    expected64 = base64.b64encode(canonical(expected)).decode() if expected is not None else ''
    baseline = plan['baseline']
    candidate64 = base64.b64encode(canonical(plan['candidate_receipt'])).decode()
    return f'''import base64, hashlib, json, os, pathlib, shutil, socket, stat, subprocess, fcntl, urllib.request
T=json.loads(base64.b64decode("{encoded}")); E=json.loads(base64.b64decode("{expected64}")) if "{expected64}" else None
CANDIDATE=json.loads(base64.b64decode("{candidate64}"))
ROOT=pathlib.Path('/opt/quiz-master'); RELEASES=ROOT/'releases'; BACKUPS=ROOT/'backups'; LOCK={LOCK!r}
RECEIPTS={{'quiz-2026.10.19-feedback-5df1d538':'sha256:ea1d2e9049f87f777df9b5b226dba5391aff4050bfd66c28690259d04b668561','quiz-2026.10.19-books-8954b166':'sha256:dd7166c8690a2009f6b6fa5ae6b8145f6328c93fd0b8e1d450cbe9de83b4ef13','quiz-2026.10.19-bones-36e0b68c':'sha256:54a3455a7efac04ab6ee6f9ffb5a053d3ce2ca431ee938557d4ab2aed928d54a'}}
def run(*a): return subprocess.check_output(a,text=True)
def data(*a): return json.loads(run(*a))
def digest(p):
 h=hashlib.sha256()
 with open(p,'rb') as f:
  for b in iter(lambda:f.read(1024*1024),b''): h.update(b)
 return h.hexdigest()
def regular(p):
 s=p.lstat()
 if p.is_symlink() or not stat.S_ISREG(s.st_mode): raise RuntimeError('not regular: '+str(p))
def no_symlinks(p):
 if p.is_symlink(): raise RuntimeError('symlink: '+str(p))
 for r,ds,fs in os.walk(p,followlinks=False):
  for n in ds+fs:
   if (pathlib.Path(r)/n).is_symlink(): raise RuntimeError('symlink tree: '+str(pathlib.Path(r)/n))
SQLITE_HEADER=b'SQLite format 3\\x00'
def sqlite_ok(p):
 import sqlite3
 c=sqlite3.connect('file:'+str(p)+'?mode=ro&immutable=1',uri=True)
 try:
  if c.execute('pragma integrity_check').fetchone()[0]!='ok': raise RuntimeError('sqlite integrity: '+str(p))
 finally: c.close()
def sqlite_state(p):
 with open(p,'rb') as f: header=f.read(16)
 if header==SQLITE_HEADER: sqlite_ok(p); return 'ok'
 if p.suffix.lower()=='.sqlite': raise RuntimeError('invalid sqlite header: '+str(p))
 return None
def tree(p):
 no_symlinks(p); out=[]
 for f in (x for x in p.rglob('*') if x.is_file()):
  out.append([str(f.relative_to(p)),f.stat().st_size,digest(f),sqlite_state(f)])
 return sorted(out,key=lambda row: row[0].encode('utf-8'))
def receipt_guard():
 for build,digest in RECEIPTS.items():
  stage=RELEASES/build; a=stage/'prepared-receipt.json'; b=stage/'reviewed-receipt.json'; regular(a); regular(b)
  x=json.loads(a.read_text()); y=json.loads(b.read_text())
  if x!=y or x.get('build_id')!=build or x.get('image')!=f'quiz-master:{{build}}@{{digest}}': raise RuntimeError('receipt '+build)
def state():
 if socket.gethostname()!={baseline['host']!r}: raise RuntimeError('wrong host')
 receipt_guard()
 prepared=RELEASES/CANDIDATE['build_id']/'prepared-receipt.json'; regular(prepared)
 if json.loads(prepared.read_text())!=CANDIDATE: raise RuntimeError('candidate prepared receipt changed')
 d=data('kubectl','get','deploy','quiz-master','-n','quiz-master','-o','json'); t=d['spec']['template']; cs=t['spec'].get('containers',[])
 if d.get('metadata',{{}}).get('annotations',{{}}).get('deployment.kubernetes.io/revision')!={baseline['deployment_revision']!r}: raise RuntimeError('deployment revision')
 if t.get('metadata',{{}}).get('annotations',{{}}).get('quiz-master/build-id')!={baseline['build_id']!r}: raise RuntimeError('build')
 if {{x.get('name') for x in cs}}!={{'api','web'}} or any(x.get('image')!={baseline['image']!r} for x in cs): raise RuntimeError('image')
 if run('kubectl','get','pvc','quiz-data','-n','quiz-master','-o','jsonpath={{.metadata.uid}}')!={baseline['pvc_uid']!r}: raise RuntimeError('PVC')
 hist=data('helm','history','quiz-master','-n','quiz-master','-o','json'); rev={{x.get('revision'):x.get('status') for x in hist}}
 if rev.get({baseline['helm_deployed_revision']})!='deployed' or {baseline['rollback_revision']} not in rev: raise RuntimeError('helm retention')
 nodes=data('kubectl','get','nodes','-o','json').get('items',[])
 if len(nodes)!=1: raise RuntimeError('node count')
 c={{x.get('type'):x.get('status') for x in nodes[0].get('status',{{}}).get('conditions',[])}}
 if c.get('Ready')!='True' or c.get('DiskPressure')!='False' or nodes[0].get('spec',{{}}).get('unschedulable'): raise RuntimeError('node state')
 with urllib.request.urlopen('https://quiz.kotopedia.org/version.json',timeout=30) as r:
  if json.load(r).get('buildId')!={baseline['build_id']!r}: raise RuntimeError('public build')
 with urllib.request.urlopen('https://quiz.kotopedia.org/health/ready',timeout=30) as r:
  if r.status!=200: raise RuntimeError('public health')
 for p in (BACKUPS/'quiz-2026.10.19-minimum20-7f8344d6.sqlite',BACKUPS/'quiz-2026.10.19-grid-9de2ad04.sqlite',BACKUPS/'quiz-2026.10.19-photo-a034673a.sqlite',BACKUPS/'quiz-2026.10.20-water-82fb9c57.sqlite',BACKUPS/'quiz-2026.10.20-sky-388e5c0c.sqlite',BACKUPS/'quiz-2026.10.20-touch-b5863403.sqlite'):
  regular(p); sqlite_ok(p)
 return {{'deployment_revision':72,'helm_revision':74,'rollback_revision':73,'node_ready':True,'disk_pressure':False}}
def active_refs(roots):
 ids=run('docker','ps','-q').split(); docker=data('docker','inspect',*ids) if ids else []
 cri=data('k3s','crictl','ps','-o','json'); cids=[x.get('id') for x in cri.get('containers',[]) if x.get('id')]
 details=[data('k3s','crictl','inspect','-o','json',x) for x in cids]
 pods=data('kubectl','get','pods','-A','-o','json')
 def walk(v):
  if isinstance(v,str): yield v
  elif isinstance(v,dict):
   for x in v.values(): yield from walk(x)
  elif isinstance(v,list):
   for x in v: yield from walk(x)
 values=tuple(walk([docker,details,pods]))
 if any(root in v for root in roots for v in values): raise RuntimeError('active reference to offload target')
 def process_ref(root):
  for proc in pathlib.Path('/proc').iterdir():
   if not proc.name.isdigit() or proc.name==str(os.getpid()): continue
   try:
    cmd=(proc/'cmdline').read_bytes().replace(b'\\0',b' ').decode('utf-8','replace')
    cwd=os.readlink(proc/'cwd')
    fds=[os.readlink(fd) for fd in (proc/'fd').iterdir()]
   except OSError: continue
   if root in cmd or any(root in x for x in fds): return True
   if cwd.startswith('/opt/quiz-master') and (cwd==root or cwd.startswith(root+'/') or root.startswith(cwd.rstrip('/')+'/')): return True
  return False
 if any(process_ref(root) for root in roots): raise RuntimeError('active reference to offload target')
def snapshot():
 state(); roots=sorted({{str(pathlib.Path(x['path']).parent) for x in T}}); active_refs(roots); items=[]
 for x in T:
  p=pathlib.Path(x['path'])
  if p.resolve()!=p or p.is_symlink(): raise RuntimeError('resolved/symlink guard: '+str(p))
  s=p.lstat(); kind='file' if stat.S_ISREG(s.st_mode) else 'dir' if stat.S_ISDIR(s.st_mode) else 'other'
  if kind!=x['kind']: raise RuntimeError('type guard: '+str(p))
  files=tree(p) if kind=='dir' else None; size=s.st_size if kind=='file' else sum(z[1] for z in files)
  if size!=x['expected_bytes']: raise RuntimeError('expected byte count changed: '+str(p))
  row={{'path':str(p),'kind':kind,'bytes':size,'sha256':digest(p) if kind=='file' else None,'files':files,'sqlite_integrity':sqlite_state(p) if kind=='file' else None}}
  items.append(row)
 return items
with open(LOCK,'a') as lock:
 fcntl.flock(lock.fileno(),fcntl.LOCK_EX|fcntl.LOCK_NB)
 actual=snapshot()
 if E is not None and actual!=E: raise RuntimeError('remote target manifest changed since local staging')
 if {str(delete)!r}=='True':
  for x in T:
   p=pathlib.Path(x['path'])
   if x['kind']=='file': p.unlink()
   else: shutil.rmtree(p)
  state()
 print(json.dumps({{'targets':actual,'deleted':{str(delete)!r}=='True'}},sort_keys=True))
'''
def remote_snapshot(plan: dict, expected: object | None = None, delete: bool = False) -> list[dict]:
    result = json.loads(ssh(remote_program(plan, expected, delete)))
    if result.get('deleted') != delete: raise RuntimeError('unexpected remote mode')
    return result['targets']
def safe_extract(archive: Path, root: Path) -> None:
    with tarfile.open(archive, 'r:gz') as t:
        for m in t.getmembers():
            p=PurePosixPath(m.name)
            if p.is_absolute() or '..' in p.parts: raise RuntimeError('unsafe tar member')
        t.extractall(root, filter='data')
def local_digest(path: Path) -> str:
    h=hashlib.sha256()
    with path.open('rb') as f:
        for b in iter(lambda:f.read(1024*1024),b''): h.update(b)
    return h.hexdigest()
def local_verify(root: Path, items: list[dict]) -> None:
    import sqlite3
    sqlite_header=b'SQLite format 3\x00'
    def sqlite_state(path: Path) -> str | None:
        with path.open('rb') as source: header=source.read(16)
        if header != sqlite_header:
            if path.suffix.lower()=='.sqlite': raise RuntimeError('invalid local sqlite header: '+str(path))
            return None
        connection=sqlite3.connect(path.as_uri()+'?mode=ro&immutable=1',uri=True)
        try:
            if connection.execute('pragma integrity_check').fetchone()[0] != 'ok': raise RuntimeError('local sqlite integrity')
        finally:
            connection.close()
        return 'ok'
    for item in items:
        p=root / item['path'].lstrip('/')
        if item['kind']=='file':
            if not p.is_file() or local_digest(p)!=item['sha256']: raise RuntimeError('local file mismatch: '+str(p))
            if sqlite_state(p) != item['sqlite_integrity']: raise RuntimeError('local sqlite state mismatch')
        else:
            actual=[]
            for f in (x for x in p.rglob('*') if x.is_file()):
                relative=str(f.relative_to(p)).replace('\\','/')
                sqlite=sqlite_state(f)
                actual.append([relative,f.stat().st_size,local_digest(f),sqlite])
            # WindowsPath does not guarantee POSIX byte ordering.  Compare UTF-8
            # path bytes, the same canonical order emitted by the remote guard.
            if sorted(actual, key=lambda row: row[0].encode('utf-8')) != sorted(item['files'], key=lambda row: row[0].encode('utf-8')):
                raise RuntimeError('local directory mismatch: '+str(p))
def restrict(path: Path) -> None:
    path.mkdir(parents=True, exist_ok=False)
    if os.name=='nt':
        user=os.environ.get('USERNAME')
        subprocess.run(['icacls',str(path),'/inheritance:r','/grant:r',f'{user}:(OI)(CI)F'],check=True,stdout=subprocess.DEVNULL)
    else: os.chmod(path,0o700)
def stage(plan: dict, review: Path) -> None:
    name=plan.get('local_destination')
    if not isinstance(name,str) or Path(name).name != name or name in {'','.','..'} or Path(name).is_absolute(): raise RuntimeError('local destination must be one basename')
    private_root=ROOT/'.run/private'
    for parent in (ROOT/'.run',private_root):
        if parent.exists() and parent.is_symlink(): raise RuntimeError('private destination parent is a symlink')
    receipt(review); items=remote_snapshot(plan); dest=private_root/name; restrict(dest)
    archive=dest/'remote-targets.tar.gz'; names=[str(PurePosixPath(x['path']).relative_to('/')) for x in plan['targets']]
    encoded=base64.b64encode(canonical(names)).decode()
    tar_program=f'import base64,json,subprocess; p=json.loads(base64.b64decode({encoded!r})); subprocess.run(["tar","-C","/","-czf","-",*p],check=True)'
    with archive.open('wb') as out:
        ssh(tar_program,stdout=out)
        out.flush(); os.fsync(out.fileno())
    os.chmod(archive,0o600)
    extracted=dest/'extract'; extracted.mkdir(); os.chmod(extracted,0o700); safe_extract(archive,extracted); local_verify(extracted,items)
    manifest={'plan_sha256':PLAN_SHA256,'remote_targets':items,'remote_targets_sha256':sha(canonical(items)),'archive':'remote-targets.tar.gz','archive_sha256':local_digest(archive),'extract_root':'extract'}
    snapshot_path=dest/'snapshot.json'
    with snapshot_path.open('w',encoding='utf-8',newline='\n') as out:
        out.write(json.dumps(manifest,indent=2)+'\n'); out.flush(); os.fsync(out.fileno())
    os.chmod(snapshot_path,0o600)
    print(json.dumps({'staged':str(dest),'remote_targets_sha256':manifest['remote_targets_sha256']}))
def apply(plan: dict, review: Path, snapshot: Path) -> None:
    receipt(review); manifest=json.loads(snapshot.read_text(encoding='utf-8'))
    if manifest.get('plan_sha256')!=PLAN_SHA256: raise RuntimeError('snapshot plan mismatch')
    base=snapshot.parent; archive=base/manifest.get('archive','')
    if not archive.is_file() or local_digest(archive)!=manifest.get('archive_sha256'): raise RuntimeError('local archive missing or changed')
    items=manifest.get('remote_targets'); local_verify(base/manifest.get('extract_root',''),items)
    remote_snapshot(plan,items,delete=True)
    print(json.dumps({'applied':True,'deleted_literal_targets':len(items),'local_snapshot':str(snapshot)}))
def main() -> None:
    p=argparse.ArgumentParser(); p.add_argument('--plan',action='store_true'); p.add_argument('--stage',action='store_true'); p.add_argument('--apply',action='store_true'); p.add_argument('--accepted-review',type=Path); p.add_argument('--snapshot',type=Path); a=p.parse_args(); plan=read_plan()
    if sum((a.stage,a.apply))>1: p.error('choose one action')
    if not a.stage and not a.apply:
        print(json.dumps({'mode':'plan-only','plan_sha256':PLAN_SHA256,'targets':len(plan['targets']),'planned_bytes':plan['accounting']['planned_total_bytes']})); return
    if not a.accepted_review: p.error('--accepted-review is required')
    if a.stage: stage(plan,a.accepted_review)
    else:
        if not a.snapshot: p.error('--snapshot is required for --apply')
        apply(plan,a.accepted_review,a.snapshot)
if __name__=='__main__': main()
