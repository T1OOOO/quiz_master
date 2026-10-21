#!/usr/bin/env python3
"""Fail-closed cold archive helper for the nine user-approved LL release trees.

It deliberately does no implicit deletion.  ``delete`` is an opt-in operation
for the release lead after a separate Linux restore verifier and independent
review have produced hash-bound receipts.
"""
from __future__ import annotations

import argparse
import base64
import hashlib
import json
import os
import pathlib
import shlex
import subprocess
import sys
import tarfile
from datetime import datetime, timezone

HOST = "racknerd-f0269d5"
SSH_HOST = "root@192.3.164.184"
KEY = r"C:/Users/Alexey_Matvienko/.ssh/ll_deploy_ed25519"
RELEASE_ROOT = "/opt/ll/releases"
ARCHIVE_ROOT = pathlib.Path(r"E:/Backups/quiz-master/server-20261021")
PROPOSAL = pathlib.Path(".run/feedback_execute_20261021/archive-proposal.json")
PINNED_PATHS = (
    "/opt/ll/releases/atlas-language-tests-20261020-uq50AzWm",
    "/opt/ll/releases/loading-build-20261020-jZMLHsKM",
    "/opt/ll/releases/ui55-backend-FirDEO1L",
    "/opt/ll/releases/feedback-20261020-pQyJdfDm",
    "/opt/ll/releases/atlas-backend-v2-20261020-cqYOYnPw",
    "/opt/ll/releases/loading-build-20261020-iV6WKV3h",
    "/opt/ll/releases/loading-build-20261020-9B3QwE7p",
    "/opt/ll/releases/loading-build-20261020-Y0EFuthk",
    "/opt/ll/releases/loading-build-20261020-rsFfOQmW",
)


def stable(value: object) -> bytes:
    return json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(",", ":")).encode()


def sha_file(path: pathlib.Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def sha_json(value: object) -> str:
    return hashlib.sha256(stable(value)).hexdigest()


def load_allowlist() -> list[str]:
    proposal = json.loads(PROPOSAL.read_text(encoding="utf-8"))
    paths = [entry["path"] for entry in proposal["phase_a_candidates"]]
    if tuple(paths) != PINNED_PATHS:
        raise SystemExit("proposal does not match the immutable nine-path allowlist")
    for path in paths:
        if pathlib.PurePosixPath(path).parent.as_posix() != RELEASE_ROOT:
            raise SystemExit(f"candidate outside release root: {path}")
    return paths


def persistent(path: pathlib.Path) -> pathlib.Path:
    resolved = path.resolve(strict=False)
    if resolved != ARCHIVE_ROOT and ARCHIVE_ROOT not in resolved.parents:
        raise SystemExit(f"evidence path must be under {ARCHIVE_ROOT}")
    return resolved


def load_manifest(path: pathlib.Path, expected_root: str) -> dict:
    persistent(path)
    if expected_root not in load_allowlist():
        raise SystemExit("root is not in fixed allowlist")
    doc=json.loads(path.read_text(encoding="utf-8"))
    core={k:v for k,v in doc.items() if k != "manifest_sha256"}
    if doc.get("root") != expected_root or doc.get("manifest_sha256") != sha_json(core):
        raise SystemExit("invalid canonical source manifest")
    if doc.get("entry_count") != len(doc.get("entries", [])):
        raise SystemExit("invalid source entry count")
    for entry in doc["entries"]:
        if entry.get("type") not in {"file","dir","symlink"}:
            raise SystemExit("invalid source member type")
    return doc


def ssh(args: list[str], *, input_bytes: bytes | None = None, capture: bool = True) -> subprocess.CompletedProcess:
    command = " ".join(shlex.quote(arg) for arg in args)
    return subprocess.run(["ssh", "-i", KEY, "-o", "StrictHostKeyChecking=yes", SSH_HOST, command], input=input_bytes, capture_output=capture, check=True)


def ssh_python(script: str, payload: dict) -> subprocess.CompletedProcess:
    """Run fixed remote code with target data only on stdin, never in /proc cmdline."""
    encoded = base64.b64encode(script.encode("utf-8")).decode("ascii")
    command = "python3 -c " + shlex.quote("import base64;exec(base64.b64decode(" + repr(encoded) + "))")
    return subprocess.run(["ssh", "-i", KEY, "-o", "StrictHostKeyChecking=yes", SSH_HOST, command], input=stable(payload), capture_output=True, check=True)


REMOTE_INVENTORY = r'''import base64, hashlib, json, os, stat, sys
root=json.load(sys.stdin)['path']
def hx(p):
 h=hashlib.sha256()
 with open(p,'rb',buffering=0) as f:
  for b in iter(lambda:f.read(1048576),b''): h.update(b)
 return h.hexdigest()
def xa(p, follow=False):
 out={}
 try:
  for n in os.listxattr(p, follow_symlinks=follow): out[n]=base64.b64encode(os.getxattr(p,n,follow_symlinks=follow)).decode('ascii')
 except AttributeError: raise SystemExit('xattrs unavailable')
 except OSError as e:
  if e.errno in (95,): return {} # ENOTSUP only
  raise
 return out
rootst=os.lstat(root)
if not stat.S_ISDIR(rootst.st_mode) or os.path.realpath(root)!=root: raise SystemExit('root must be a real directory')
entries=[]; seen={}
def add(full, rel):
 s=os.lstat(full); mode=stat.S_IMODE(s.st_mode)
 if s.st_dev != rootst.st_dev: raise SystemExit('nested filesystem or bind mount: '+rel)
 e={'path':rel,'size':s.st_size,'mode':mode,'uid':s.st_uid,'gid':s.st_gid,'mtime_ns':s.st_mtime_ns,'xattrs':xa(full)}
 if stat.S_ISDIR(s.st_mode): e['type']='dir'
 elif stat.S_ISLNK(s.st_mode): e.update(type='symlink',target=os.readlink(full))
 elif stat.S_ISREG(s.st_mode):
  e.update(type='file',sha256=hx(full))
  k=(s.st_dev,s.st_ino)
  if k in seen: raise SystemExit('hardlink detected: '+rel+' -> '+seen[k])
  seen[k]=rel
 else: raise SystemExit('unsupported special file: '+rel)
 entries.append(e)
 if e['type']=='dir':
  with os.scandir(full) as it:
   for child in sorted(it,key=lambda x:x.name): add(child.path, rel+'/'+child.name if rel!='.' else child.name)
add(root,'.')
doc={'schema_version':1,'host':os.uname().nodename,'root':root,'source_identity':{'device':rootst.st_dev,'inode':rootst.st_ino},'entries':entries,'entry_count':len(entries)}
doc['manifest_sha256']=hashlib.sha256(json.dumps({k:v for k,v in doc.items() if k!='manifest_sha256'},ensure_ascii=False,sort_keys=True,separators=(',',':')).encode()).hexdigest()
print(json.dumps(doc,sort_keys=True,separators=(',',':')))
'''

REMOTE_GUARD = r'''import json, os, socket, subprocess, sys
request=json.load(sys.stdin); path=request['path']; expected_dev=int(request['device']); expected_ino=int(request['inode'])
allow=("/opt/ll/releases/atlas-language-tests-20261020-uq50AzWm","/opt/ll/releases/loading-build-20261020-jZMLHsKM","/opt/ll/releases/ui55-backend-FirDEO1L","/opt/ll/releases/feedback-20261020-pQyJdfDm","/opt/ll/releases/atlas-backend-v2-20261020-cqYOYnPw","/opt/ll/releases/loading-build-20261020-iV6WKV3h","/opt/ll/releases/loading-build-20261020-9B3QwE7p","/opt/ll/releases/loading-build-20261020-Y0EFuthk","/opt/ll/releases/loading-build-20261020-rsFfOQmW")
if path not in allow or os.path.realpath('/opt/ll/releases')!='/opt/ll/releases' or os.path.realpath(os.path.dirname(path))!='/opt/ll/releases': raise SystemExit('invalid release root')
s=os.lstat(path)
if socket.gethostname()!='racknerd-f0269d5': raise SystemExit('unexpected hostname')
if not os.path.isdir(path) or os.path.islink(path) or s.st_dev!=expected_dev or s.st_ino!=expected_ino: raise SystemExit('source identity changed')
mount=json.loads(subprocess.check_output(['findmnt','--json','--target',path],text=True))['filesystems'][0]
if mount.get('source')!='/dev/vda2' or mount.get('fstype')!='ext4': raise SystemExit('unexpected filesystem')
refs=[]
prefix=path.rstrip('/')+'/'
def hit(value): return value==path or value.startswith(prefix)
def unesc(value):
 import re
 return re.sub(r'\\\\([0-7]{3})',lambda m:chr(int(m.group(1),8)),value)
for pid in os.listdir('/proc'):
 if not pid.isdigit(): continue
 base='/proc/'+pid
 for part in ('cwd','root'):
  try:
   if hit(os.readlink(base+'/'+part)): refs.append({'pid':pid,'kind':part})
  except OSError: pass
 try:
  for fd in os.listdir(base+'/fd'):
   try:
    if hit(os.readlink(base+'/fd/'+fd)): refs.append({'pid':pid,'kind':'fd','fd':fd})
   except OSError: pass
 except OSError: pass
 try:
  if path.encode() in open(base+'/cmdline','rb').read(): refs.append({'pid':pid,'kind':'cmdline'})
 except OSError: pass
 for part in ('exe','maps'):
  try:
   if part=='exe' and hit(os.readlink(base+'/exe')): refs.append({'pid':pid,'kind':'exe'})
   if part=='maps' and path.encode() in open(base+'/maps','rb').read(): refs.append({'pid':pid,'kind':'maps'})
  except OSError: pass
for command,kind in ((['docker','ps','-aq'],'docker'),(['crictl','ps','-aq'],'cri')):
 try:
  ids=subprocess.check_output(command,text=True,stderr=subprocess.DEVNULL).split()
  for ident in ids:
   raw=subprocess.check_output((['docker','inspect',ident] if kind=='docker' else ['crictl','inspect',ident]),text=True,stderr=subprocess.DEVNULL)
   if path in raw: refs.append({'kind':kind,'id':ident})
 except (OSError,subprocess.CalledProcessError) as e: raise SystemExit(kind+' inspection unavailable: '+str(e))
try:
 pods=subprocess.check_output(['kubectl','get','pods','-A','-o','json'],text=True,stderr=subprocess.DEVNULL)
 if path in pods: refs.append({'kind':'kubernetes-api-hostpath'})
except (OSError,subprocess.CalledProcessError) as e: raise SystemExit('kubernetes API inspection unavailable: '+str(e))
for pid in os.listdir('/proc'):
 if not pid.isdigit(): continue
 try:
  for line in open('/proc/'+pid+'/mountinfo',errors='ignore'):
   fields=line.split()
   if len(fields)>4 and (hit(unesc(fields[3])) or hit(unesc(fields[4]))): refs.append({'pid':pid,'kind':'mount','root':unesc(fields[3]),'mountpoint':unesc(fields[4])})
 except OSError: pass
for config_root in ('/etc/kubernetes','/var/lib/rancher/k3s/agent/pod-manifests'):
 if not os.path.isdir(config_root): continue
 for root,dirs,files in os.walk(config_root):
  for name in files:
   p=os.path.join(root,name)
   try:
    if path in open(p,'r',errors='ignore').read(): refs.append({'kind':'kubernetes-config','file':p})
   except OSError: pass
for config_root in ('/etc/systemd/system','/lib/systemd/system'):
 if not os.path.isdir(config_root): continue
 for name in os.listdir(config_root):
  p=os.path.join(config_root,name)
  try:
   if os.path.islink(p) and hit(os.path.realpath(p)): refs.append({'kind':'systemd-symlink','file':p})
   elif os.path.isfile(p) and path in open(p,'r',errors='ignore').read(): refs.append({'kind':'systemd-unit','file':p})
  except OSError: pass
for alias_root in ('/opt/ll','/opt/ll/releases'):
 try:
  for name in os.listdir(alias_root):
   p=os.path.join(alias_root,name)
   if os.path.islink(p) and hit(os.path.realpath(p)): refs.append({'kind':'ll-symlink','file':p})
 except OSError: raise SystemExit('cannot inspect LL aliases')
print(json.dumps({'host':socket.gethostname(),'mount':{'source':mount.get('source'),'fstype':mount.get('fstype'),'target':mount.get('target')},'identity':{'device':s.st_dev,'inode':s.st_ino},'references':refs},sort_keys=True))
'''

REMOTE_DELETE = REMOTE_GUARD + r'''
import shutil
if refs: raise SystemExit('references appeared before delete')
shutil.rmtree(path)
if os.path.lexists(path): raise SystemExit('path remains after delete')
print(json.dumps({'deleted':path},sort_keys=True))
'''


def inventory(path: str, out: pathlib.Path) -> dict:
    if path not in load_allowlist():
        raise SystemExit("path is not in fixed nine-path allowlist")
    result = ssh_python(REMOTE_INVENTORY, {"path":path})
    doc = json.loads(result.stdout)
    if doc["host"] != HOST or doc["root"] != path:
        raise SystemExit("unexpected host or root in inventory")
    out=persistent(out); out.parent.mkdir(parents=True, exist_ok=True)
    out.write_bytes(stable(doc) + b"\n")
    return doc


def fresh_guard(path: str, doc: dict) -> dict:
    ident=doc["source_identity"]
    result=ssh_python(REMOTE_GUARD, {"path":path,"device":ident["device"],"inode":ident["inode"]})
    guard=json.loads(result.stdout)
    if guard["references"]:
        raise SystemExit("active process/container/Kubernetes reference blocks operation")
    return guard


def safe_tar_members(archive: pathlib.Path, expected_root: str) -> tuple[int, list[str]]:
    names: list[str] = []
    with tarfile.open(archive, "r:*") as tar:
        for member in tar:
            name = member.name.replace("\\", "/")
            if name.endswith("/"):
                if not member.isdir(): raise SystemExit(f"non-directory trailing slash: {name}")
                name=name.rstrip("/")
            if name.startswith("/") or ".." in pathlib.PurePosixPath(name).parts:
                raise SystemExit(f"unsafe tar member: {name}")
            if name != expected_root and not name.startswith(expected_root + "/"):
                raise SystemExit(f"member escapes expected root: {name}")
            if not (member.isfile() or member.isdir() or member.issym()):
                raise SystemExit(f"special tar member forbidden: {name}")
            names.append(name)
    return len(names), names


def archive(path: str, manifest: pathlib.Path, destination: pathlib.Path) -> dict:
    doc = load_manifest(manifest, path)
    destination=persistent(destination)
    fresh = inventory(path, destination.with_suffix(destination.suffix+".pre-source.json"))
    if fresh["manifest_sha256"] != doc["manifest_sha256"]:
        raise SystemExit("source changed since inventory")
    fresh_guard(path, fresh)
    base = pathlib.PurePosixPath(path).name
    destination.parent.mkdir(parents=True, exist_ok=True)
    if destination.exists() or destination.with_suffix(destination.suffix+".part").exists():
        raise SystemExit("refusing to overwrite archive")
    part=destination.with_suffix(destination.suffix+".part")
    command = "set -o pipefail; cd /opt/ll/releases; tar --format=pax --numeric-owner --acls --xattrs --xattrs-include='*' -cf - -- " + base + " | gzip -1"
    with part.open("xb") as output:
        subprocess.run(["ssh", "-i", KEY, "-o", "StrictHostKeyChecking=yes", SSH_HOST, "bash -lc " + shlex.quote(command)], stdout=output, check=True)
    count, names = safe_tar_members(part, base)
    expected={base if e['path']=='.' else base+'/'+e['path'] for e in doc['entries']}
    if set(names)!=expected or len(names)!=len(expected): raise SystemExit('post-tar member paths differ; retained .part diagnostic')
    post = inventory(path, destination.with_suffix(destination.suffix+".post-source.json"))
    if post["manifest_sha256"] != doc["manifest_sha256"]: raise SystemExit('source changed during archive; retained .part diagnostic')
    os.replace(part,destination)
    receipt = {"schema_version":1,"created_at":datetime.now(timezone.utc).isoformat(),"host":HOST,"root":path,"archive":str(destination),"archive_sha256":sha_file(destination),"source_manifest":str(manifest),"source_manifest_sha256":doc["manifest_sha256"],"source_entry_count":doc["entry_count"],"tar_member_count":count}
    return receipt


def receipt_gate(receipt_path: pathlib.Path, review_path: pathlib.Path, archive_sha: str, manifest_sha: str, count: int) -> None:
    receipt = json.loads(receipt_path.read_text(encoding="utf-8"))
    required = {"verdict":"ACCEPT", "verifier":"linux_chunk_restore", "archive_sha256":archive_sha, "source_manifest_sha256":manifest_sha, "entry_count":count}
    if any(receipt.get(k) != v for k, v in required.items()):
        raise SystemExit("Linux restore receipt does not bind this archive/manifest/count")
    review = json.loads(review_path.read_text(encoding="utf-8"))
    if review.get("verdict") != "ACCEPT" or not review.get("independent_reviewer"):
        raise SystemExit("independent review receipt is invalid")
    if review.get("restore_receipt_sha256") != sha_file(receipt_path):
        raise SystemExit("independent review receipt does not bind this restore receipt")
    for key, value in required.items():
        if review.get(key) != value:
            raise SystemExit("independent review receipt does not bind restore evidence")


def verify(path: str, manifest: pathlib.Path, archive_path: pathlib.Path, linux_receipt: pathlib.Path | None, independent_review: pathlib.Path | None) -> dict:
    doc = load_manifest(manifest, path)
    archive_path=persistent(archive_path)
    base = pathlib.PurePosixPath(path).name
    member_count, names = safe_tar_members(archive_path, base)
    archive_sha = sha_file(archive_path)
    expected_paths = {base if entry["path"] == "." else base + "/" + entry["path"] for entry in doc["entries"]}
    if set(names) != expected_paths or len(names) != len(expected_paths):
        raise SystemExit("tar path set differs from source manifest")
    if not linux_receipt or not independent_review: raise SystemExit("Linux restore and independent review receipts are required")
    persistent(linux_receipt); persistent(independent_review)
    receipt_gate(linux_receipt, independent_review, archive_sha, doc["manifest_sha256"], doc["entry_count"])
    return {"archive_sha256":archive_sha,"source_manifest_sha256":doc["manifest_sha256"],"entry_count":doc["entry_count"],"tar_member_count":member_count,"linux_restore_receipt":str(linux_receipt) if linux_receipt else None}


def main() -> None:
    parser = argparse.ArgumentParser()
    sub = parser.add_subparsers(dest="mode", required=True)
    for name in ("inventory", "archive", "verify", "delete"):
        item=sub.add_parser(name); item.add_argument("--path", required=True); item.add_argument("--manifest", type=pathlib.Path, required=True)
    sub.choices["inventory"].add_argument("--out", type=pathlib.Path, required=True)
    sub.choices["archive"].add_argument("--out", type=pathlib.Path, required=True)
    for name in ("verify", "delete"):
        sub.choices[name].add_argument("--archive", type=pathlib.Path, required=True); sub.choices[name].add_argument("--linux-receipt", type=pathlib.Path, required=True); sub.choices[name].add_argument("--independent-review", type=pathlib.Path, required=True)
    sub.choices["delete"].add_argument("--user-authorized", action="store_true")
    args=parser.parse_args()
    if args.mode=="inventory":
        doc=inventory(args.path,args.out)
        result={"root":doc["root"],"manifest":str(args.out),"source_manifest_sha256":doc["manifest_sha256"],"entry_count":doc["entry_count"]}
    elif args.mode=="archive": result=archive(args.path,args.manifest,args.out)
    elif args.mode=="verify": result=verify(args.path,args.manifest,args.archive,args.linux_receipt,args.independent_review)
    else:
        if not args.user_authorized: raise SystemExit("delete requires --user-authorized")
        result=verify(args.path,args.manifest,args.archive,args.linux_receipt,args.independent_review)
        fresh_path=args.manifest.with_suffix(args.manifest.suffix+".predelete.json")
        fresh=inventory(args.path,fresh_path)
        original=json.loads(args.manifest.read_text(encoding="utf-8"))
        if fresh["manifest_sha256"] != original["manifest_sha256"]:
            raise SystemExit("source changed since archived manifest")
        result["fresh_guard"]=fresh_guard(args.path,fresh)
        ssh_python(REMOTE_DELETE, {"path":args.path,"device":fresh["source_identity"]["device"],"inode":fresh["source_identity"]["inode"]})
        result["deleted"] = args.path
    print(json.dumps(result,sort_keys=True))

if __name__ == "__main__": main()
