#!/usr/bin/env python3
"""Fail-closed executor for the reviewed regenerable-cache manifest."""
from __future__ import annotations
import argparse,base64,hashlib,json,os,pathlib,re,shlex,subprocess
HOST='racknerd-f0269d5';SSH_HOST='root@192.3.164.184';KEY=r'C:/Users/Alexey_Matvienko/.ssh/ll_deploy_ed25519'
MANIFEST_SHA='f0a62786649b35315a831807cd30b2dd5dd034bb16a2b34dcfeda8f3c966943b';ARCHIVE_BYTES=9555880176;EVIDENCE_ROOT=pathlib.Path(r'E:/Backups/quiz-master/server-20261021')
PROTECTED=frozenset({'atlas-reader-green-20261021-uBBJXphO','atlas-reader-red-20261021-F1CYXtII','atlas-reader-backend-20261021-0OPKKBZe'})
ARCHIVE_RELEASES=frozenset({'atlas-language-tests-20261020-uq50AzWm','loading-build-20261020-jZMLHsKM','ui55-backend-FirDEO1L','feedback-20261020-pQyJdfDm','atlas-backend-v2-20261020-cqYOYnPw','loading-build-20261020-iV6WKV3h','loading-build-20261020-9B3QwE7p','loading-build-20261020-Y0EFuthk','loading-build-20261020-rsFfOQmW'})
TMP_RE=re.compile(r'^/tmp/krug-[^/]+/(?:\.dart_tool|build)$');OPT_RE=re.compile(r'^/opt/ll/releases/([^/]+)/(?:app/(?:\.dart_tool|build)|flutter/bin/cache|pub-cache)$')
def stable(v):return json.dumps(v,sort_keys=True,separators=(',',':')).encode()
def digest(v):return hashlib.sha256(stable(v)).hexdigest()
def unescape_mount(v):return re.sub(r'\\([0-7]{3})',lambda x:chr(int(x.group(1),8)),v)
def persistent(p):
 r=p.resolve(strict=False)
 if r!=EVIDENCE_ROOT and EVIDENCE_ROOT not in r.parents:raise ValueError('evidence must be under durable E backup')
 return r
def project_root(p):
 if TMP_RE.fullmatch(p):return p.rsplit('/',1)[0]
 m=OPT_RE.fullmatch(p)
 if m:return '/opt/ll/releases/'+m.group(1)
 raise ValueError('outside six approved cache classes')
def validate_manifest(d):
 if d.get('manifest_sha256')!=MANIFEST_SHA or digest({k:v for k,v in d.items() if k!='manifest_sha256'})!=MANIFEST_SHA:raise ValueError('manifest identity')
 fs=d.get('filesystem',{})
 if d.get('schema_version')!=1 or d.get('host')!=HOST or not isinstance(fs,dict) or fs.get('source')!='/dev/vda2' or fs.get('fstype')!='ext4':raise ValueError('manifest context')
 rows=d.get('cache_children')
 if not isinstance(rows,list) or len(rows)!=21:raise ValueError('exact 21 disjoint children required')
 seen=set()
 for r in rows:
  if not isinstance(r,dict) or not isinstance(r.get('path'),str) or r['path'] in seen:raise ValueError('duplicate child')
  root=project_root(r['path']);name=root.rsplit('/',1)[-1]
  if name in PROTECTED or name in ARCHIVE_RELEASES or '..' in r['path'] or '//' in r['path']:raise ValueError('protected path')
  if r.get('mount')!={'source':'/dev/vda2','fstype':'ext4'} or any(type(r.get(k))is not int or r[k]<0 for k in ('allocated_bytes','device','inode')):raise ValueError('unsafe identity')
  seen.add(r['path'])
 if sum(r['allocated_bytes'] for r in rows)!=d.get('cache_children_allocated_bytes') or d.get('archive_prerequisite',{}).get('expected_reclaimed_allocated_bytes')!=ARCHIVE_BYTES:raise ValueError('totals')
 return rows
def is_active_build(raw):
 cmd=raw.replace(b'\0',b' ').decode(errors='ignore').lower()
 return any(x in cmd for x in ('docker build','docker buildx','docker-buildx','buildctl','flutter build','dart build','dart compile'))
def ssh_python(script,payload):
 enc=base64.b64encode(script.encode()).decode();cmd='python3 -c '+shlex.quote('import base64;exec(base64.b64decode('+repr(enc)+'))')
 return json.loads(subprocess.run(['ssh','-i',KEY,'-o','StrictHostKeyChecking=yes',SSH_HOST,cmd],input=stable(payload),capture_output=True,check=True,timeout=420).stdout)
REMOTE_COMMON=r'''import json,os,re,shutil,socket,stat,subprocess,sys
q=json.load(sys.stdin);rows=q['rows'];delete=bool(q.get('delete'))
TMP=re.compile(r'^/tmp/krug-[^/]+/(?:\.dart_tool|build)$');OPT=re.compile(r'^/opt/ll/releases/([^/]+)/(?:app/(?:\.dart_tool|build)|flutter/bin/cache|pub-cache)$')
PROTECTED={'atlas-reader-green-20261021-uBBJXphO','atlas-reader-red-20261021-F1CYXtII','atlas-reader-backend-20261021-0OPKKBZe'}
ARCHIVE={'atlas-language-tests-20261020-uq50AzWm','loading-build-20261020-jZMLHsKM','ui55-backend-FirDEO1L','feedback-20261020-pQyJdfDm','atlas-backend-v2-20261020-cqYOYnPw','loading-build-20261020-iV6WKV3h','loading-build-20261020-9B3QwE7p','loading-build-20261020-Y0EFuthk','loading-build-20261020-rsFfOQmW'}
if socket.gethostname()!='racknerd-f0269d5' or len(rows)!=21:raise SystemExit('host/count')
def project(p):
 m=OPT.fullmatch(p)
 return p.rsplit('/',1)[0] if TMP.fullmatch(p) else '/opt/ll/releases/'+m.group(1) if m else None
def hit(v,r):return v==r or v.startswith(r+'/')
def unesc(v):return re.sub(r'\\([0-7]{3})',lambda x:chr(int(x.group(1),8)),v)
roots=[]
for r in rows:
 p=r.get('path');root=project(p) if isinstance(p,str) else None
 if not root or root.rsplit('/',1)[-1] in PROTECTED or root.rsplit('/',1)[-1] in ARCHIVE or r.get('mount')!={'source':'/dev/vda2','fstype':'ext4'}:raise SystemExit('allowlist')
 roots.append(root)
roots=sorted(set(roots));parents={r:(os.lstat(r).st_dev,os.lstat(r).st_ino) for r in roots};refs=[]
for r in rows:
 p=r['path']
 for line in open('/proc/self/mountinfo',errors='ignore'):
  f=line.split()
  if len(f)>4 and (hit(unesc(f[3]),p) or hit(unesc(f[4]),p)):raise SystemExit('cache mountpoint')
for pid in os.listdir('/proc'):
 if not pid.isdigit():continue
 b='/proc/'+pid
 for root in roots:
  for part in ('cwd','root','exe'):
   try:
    if hit(os.readlink(b+'/'+part),root):refs.append({'pid':pid,'kind':part,'root':root})
   except OSError:pass
  try:
   blob=open(b+'/cmdline','rb').read()+open(b+'/maps','rb').read()+open(b+'/environ','rb').read()
   if root.encode() in blob:refs.append({'pid':pid,'kind':'env','root':root})
  except OSError:pass
  try:
   for fd in os.listdir(b+'/fd'):
    try:
     if hit(os.readlink(b+'/fd/'+fd),root):refs.append({'pid':pid,'kind':'fd','root':root,'fd':fd})
    except OSError:pass
  except OSError:pass
  try:
   for line in open(b+'/mountinfo',errors='ignore'):
    f=line.split()
    if len(f)>4 and (hit(unesc(f[3]),root) or hit(unesc(f[4]),root)):refs.append({'pid':pid,'kind':'mount','root':root})
  except OSError:pass
for cmd,kind in ((['docker','ps','-aq'],'docker'),(['crictl','ps','-aq'],'cri')):
 ids=subprocess.check_output(cmd,text=True,timeout=15).split()
 for i in range(0,len(ids),64):
  chunk=ids[i:i+64]
  if not chunk:continue
  for ident in chunk:
   raw=subprocess.check_output((['docker','inspect',ident] if kind=='docker' else ['crictl','inspect',ident]),text=True,stderr=subprocess.DEVNULL,timeout=15)
   for root in roots:
    if root in raw:refs.append({'kind':kind,'root':root,'id':ident})
for config in ('/etc/kubernetes','/var/lib/rancher/k3s/agent/pod-manifests'):
 if os.path.isdir(config):
  for base,dirs,files in os.walk(config):
   for name in files:
    try:
     raw=open(os.path.join(base,name),'rb').read()
     for root in roots:
      if root.encode() in raw:refs.append({'kind':'kubernetes-config','root':root})
    except OSError:pass
pods=subprocess.check_output(['kubectl','get','pods','-A','-o','json'],text=True,timeout=15)
for root in roots:
 if root in pods:refs.append({'kind':'kubernetes-api','root':root})
if refs:raise SystemExit('references '+json.dumps(refs,sort_keys=True))
before=os.statvfs('/').f_bavail*os.statvfs('/').f_frsize;deleted=[]
if delete:
 for r in rows:
  p=r['path'];root=project(p);s=os.lstat(p);parent=os.lstat(root)
  if not stat.S_ISDIR(s.st_mode) or os.path.islink(p) or os.path.realpath(p)!=p or (s.st_dev,s.st_ino)!=(r['device'],r['inode']):raise SystemExit('fresh child')
  if not stat.S_ISDIR(parent.st_mode) or os.path.islink(root) or os.path.realpath(root)!=root or (parent.st_dev,parent.st_ino)!=parents[root]:raise SystemExit('fresh parent')
  m=json.loads(subprocess.check_output(['findmnt','--json','--target',p],text=True,timeout=15))['filesystems'][0]
  if m.get('source')!='/dev/vda2' or m.get('fstype')!='ext4':raise SystemExit('fresh mount')
  shutil.rmtree(p);deleted.append(p)
  now=os.lstat(root)
  if (now.st_dev,now.st_ino)!=parents[root]:raise SystemExit('parent changed')
after=os.statvfs('/').f_bavail*os.statvfs('/').f_frsize
print(json.dumps({'host':socket.gethostname(),'before_free_bytes':before,'after_free_bytes':after,'deleted':deleted,'references':refs},sort_keys=True))'''
REMOTE_BUILDER=r'''import json,os,socket,subprocess,sys
q=json.load(sys.stdin)
if socket.gethostname()!='racknerd-f0269d5':raise SystemExit('host')
m=json.loads(subprocess.check_output(['findmnt','--json','--target','/'],text=True,timeout=15))['filesystems'][0]
if m.get('source')!='/dev/vda2' or m.get('fstype')!='ext4':raise SystemExit('root mount')
for pid in os.listdir('/proc'):
 if pid.isdigit():
  try:
   cmd=open('/proc/'+pid+'/cmdline','rb').read().replace(b'\0',b' ').decode(errors='ignore').lower()
   if any(x in cmd for x in ('docker build','docker buildx','docker-buildx','buildctl','flutter build','dart build','dart compile')):raise SystemExit('active build')
  except OSError:pass
def snap():
 cri=json.loads(subprocess.check_output(['crictl','images','-o','json'],text=True,timeout=15));cri['images']=sorted(cri.get('images',[]),key=lambda x:json.dumps(x,sort_keys=True,separators=(',',':')))
 return {'docker_images':sorted(subprocess.check_output(['docker','image','ls','--no-trunc','--format','{{.Repository}}:{{.Tag}} {{.ID}} {{.Digest}}'],text=True,timeout=15).splitlines()),'cri_images':json.dumps(cri,sort_keys=True,separators=(',',':')),'free':os.statvfs('/').f_bavail*os.statvfs('/').f_frsize}
before=snap();prune_output=''
if q.get('prune'):prune_output=subprocess.run(['docker','builder','prune','--all','--force','--filter','until=1h'],check=True,timeout=180,capture_output=True,text=True).stdout[-4096:]
after=snap()
if before['docker_images']!=after['docker_images'] or before['cri_images']!=after['cri_images']:raise SystemExit('published images changed')
print(json.dumps({'before':before,'after':after,'pruned':bool(q.get('prune')),'prune_output':prune_output},sort_keys=True))'''
def execute_cache(rows,do):return ssh_python(REMOTE_COMMON,{'rows':rows,'delete':do})
def execute_builder(do):return ssh_python(REMOTE_BUILDER,{'prune':do})
def main(argv=None):
 p=argparse.ArgumentParser();p.add_argument('--manifest',type=pathlib.Path,required=True);p.add_argument('--mode',choices=('cache-delete','builder-prune'),required=True);p.add_argument('--execute',action='store_true');p.add_argument('--acknowledge-cache-cleanup',action='store_true');p.add_argument('--receipt',type=pathlib.Path,required=True);a=p.parse_args(argv)
 rows=validate_manifest(json.loads(a.manifest.read_text()))
 if not a.execute or not a.acknowledge_cache_cleanup:raise SystemExit('requires explicit cleanup acknowledgement')
 receipt=persistent(a.receipt)
 if receipt.exists() or not receipt.parent.is_dir() or receipt.parent.is_symlink():raise SystemExit('receipt must be absent under real persistent parent')
 result=execute_cache(rows,True) if a.mode=='cache-delete' else execute_builder(True)
 with receipt.open('xb') as out:
  out.write(stable({'manifest_sha256':MANIFEST_SHA,'mode':a.mode,'result':result})+b'\n');out.flush();os.fsync(out.fileno())
if __name__=='__main__':main()
