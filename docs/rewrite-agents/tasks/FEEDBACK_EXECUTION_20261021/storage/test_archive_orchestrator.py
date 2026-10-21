import hashlib
import json
import importlib.util
import pathlib
import tarfile
import tempfile
import unittest
from unittest import mock

HERE=pathlib.Path(__file__).parent
spec=importlib.util.spec_from_file_location("archive",HERE/"archive_orchestrator.py")
archive=importlib.util.module_from_spec(spec); spec.loader.exec_module(archive)

class ArchiveSafetyTest(unittest.TestCase):
 def setUp(self):
  fixture=tempfile.TemporaryDirectory();self.addCleanup(fixture.cleanup)
  self.proposal=pathlib.Path(fixture.name)/'approved.json'
  self.proposal.write_text(json.dumps({'phase_a_candidates':[{'path':x} for x in archive.PINNED_PATHS]}))
  patch=mock.patch.object(archive,'PROPOSAL',self.proposal);patch.start();self.addCleanup(patch.stop)
 def manifest(self, root):
  body={"schema_version":1,"host":"racknerd-f0269d5","root":root,"source_identity":{"device":1,"inode":2},"entries":[{"path":".","type":"dir","size":0,"mode":493,"uid":0,"gid":0,"mtime_ns":0,"xattrs":{}}],"entry_count":1}
  body["manifest_sha256"]=archive.sha_json(body)
  return body
 def test_manifest_rejects_tampering_and_wrong_root(self):
  with tempfile.TemporaryDirectory() as d:
   old=archive.ARCHIVE_ROOT; archive.ARCHIVE_ROOT=pathlib.Path(d).resolve()
   try:
    p=pathlib.Path(d)/"m.json"; p.write_text(json.dumps(self.manifest(archive.PINNED_PATHS[0])))
    self.assertEqual(archive.load_manifest(p,archive.PINNED_PATHS[0])["entry_count"],1)
    bad=json.loads(p.read_text());bad['entries'][0]['mode']=0;p.write_text(json.dumps(bad))
    with self.assertRaises(SystemExit): archive.load_manifest(p,archive.PINNED_PATHS[0])
    p.write_text(json.dumps(self.manifest('/opt/ll/releases/unapproved')))
    with self.assertRaises(SystemExit): archive.load_manifest(p,archive.PINNED_PATHS[0])
    p.write_text(json.dumps(self.manifest(archive.PINNED_PATHS[0])))
    bad=json.loads(p.read_text()); bad["root"]="/tmp/no"; p.write_text(json.dumps(bad))
    with self.assertRaises(SystemExit): archive.load_manifest(p,archive.PINNED_PATHS[0])
   finally: archive.ARCHIVE_ROOT=old
 def test_rejects_path_traversal_member(self):
  with tempfile.TemporaryDirectory() as d:
   p=pathlib.Path(d)/"bad.tar.gz"
   with tarfile.open(p,"w:gz") as t:
    info=tarfile.TarInfo("tree/../escape"); info.size=0; t.addfile(info)
   with self.assertRaises(SystemExit): archive.safe_tar_members(p,"tree")
 def test_accepts_expected_prefix(self):
  with tempfile.TemporaryDirectory() as d:
   p=pathlib.Path(d)/"ok.tar.gz"
   with tarfile.open(p,"w:gz") as t:
    for name in ("tree","tree/file"):
     info=tarfile.TarInfo(name); info.size=0; t.addfile(info)
   self.assertEqual(archive.safe_tar_members(p,"tree")[0],2)
 def test_restore_receipt_must_bind_all_values(self):
  with tempfile.TemporaryDirectory() as d:
   p=pathlib.Path(d)/"receipt.json"
   p.write_text('{"verdict":"ACCEPT","verifier":"linux_chunk_restore","archive_sha256":"a","source_manifest_sha256":"m","entry_count":2}')
   review=pathlib.Path(d)/"review.json"
   review.write_text(json.dumps({"verdict":"ACCEPT","independent_reviewer":"agy","verifier":"linux_chunk_restore","archive_sha256":"a","source_manifest_sha256":"m","entry_count":2,"restore_receipt_sha256":hashlib.sha256(p.read_bytes()).hexdigest()}))
   archive.receipt_gate(p,review,"a","m",2)
   with self.assertRaises(SystemExit): archive.receipt_gate(p,review,"x","m",2)
   p.write_text(p.read_text()+' ')
   with self.assertRaises(SystemExit): archive.receipt_gate(p,review,"a","m",2)
 def test_tar_rejects_extra_missing_and_non_directory_slash(self):
  with tempfile.TemporaryDirectory() as d:
   p=pathlib.Path(d)/"bad.tar.gz"
   with tarfile.open(p,"w:gz") as t:
    info=tarfile.TarInfo("tree/not-dir/"); info.size=0; t.addfile(info)
   with self.assertRaises(SystemExit): archive.safe_tar_members(p,"tree")
 def test_fixed_nine_and_persistent_backup_scope(self):
  self.assertEqual(archive.load_allowlist(),list(archive.PINNED_PATHS))
  self.proposal.write_text(json.dumps({'phase_a_candidates':[{'path':'/opt/ll/releases/wrong'}]*9}))
  with self.assertRaises(SystemExit):archive.load_allowlist()
  with tempfile.TemporaryDirectory() as d:
   with mock.patch.object(archive,'ARCHIVE_ROOT',pathlib.Path(d)/'approved'):
    with self.assertRaises(SystemExit):archive.persistent(pathlib.Path(d)/'elsewhere')
 def test_remote_programs_compile_and_forbidden_tar_types(self):
  for code in (archive.REMOTE_INVENTORY,archive.REMOTE_GUARD,archive.REMOTE_DELETE):compile(code,'<archive-safety>','exec')
  for name,kind in [('/absolute',tarfile.REGTYPE),('tree2/file',tarfile.REGTYPE),('tree/file',tarfile.LNKTYPE),('tree/file',tarfile.CHRTYPE),('tree/file',tarfile.FIFOTYPE)]:
   with self.subTest(name=name,kind=kind),tempfile.TemporaryDirectory() as d:
    p=pathlib.Path(d)/'bad.tar'
    with tarfile.open(p,'w') as tf:
     info=tarfile.TarInfo(name);info.type=kind;tf.addfile(info)
    with self.assertRaises(SystemExit):archive.safe_tar_members(p,'tree')
 def test_verify_requires_receipts_and_exact_archive_members(self):
  root=archive.PINNED_PATHS[0];base=root.rsplit('/',1)[1]
  with tempfile.TemporaryDirectory() as d,mock.patch.object(archive,'ARCHIVE_ROOT',pathlib.Path(d).resolve()):
   manifest=pathlib.Path(d)/'manifest.json';manifest.write_text(json.dumps(self.manifest(root)))
   tar=pathlib.Path(d)/'archive.tar'
   with tarfile.open(tar,'w') as tf:
    info=tarfile.TarInfo(base);info.type=tarfile.DIRTYPE;tf.addfile(info)
   with self.assertRaises(SystemExit):archive.verify(root,manifest,tar,None,None)
   for names in ([base,'extra'],[]):
    with tarfile.open(tar,'w') as tf:
     for name in names:
      info=tarfile.TarInfo(name);info.type=tarfile.DIRTYPE;tf.addfile(info)
    with self.assertRaises(SystemExit):archive.verify(root,manifest,tar,pathlib.Path(d)/'missing-proof',pathlib.Path(d)/'missing-review')
if __name__=="__main__": unittest.main()
