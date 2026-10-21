import importlib.util,json,pathlib,tempfile,unittest
from unittest import mock
HERE=pathlib.Path(__file__).parent;spec=importlib.util.spec_from_file_location('c',HERE/'cache_cleanup.py');c=importlib.util.module_from_spec(spec);spec.loader.exec_module(c)
def row(path,n=1):return {'path':path,'allocated_bytes':n,'device':1,'inode':2,'mount':{'source':'/dev/vda2','fstype':'ext4'}}
def manifest(rows):
 d={'schema_version':1,'host':c.HOST,'filesystem':{'source':'/dev/vda2','fstype':'ext4'},'archive_prerequisite':{'expected_reclaimed_allocated_bytes':c.ARCHIVE_BYTES},'cache_children':rows,'cache_children_allocated_bytes':sum(x['allocated_bytes'] for x in rows)};d['manifest_sha256']=c.digest(d);return d
class CacheCleanupTest(unittest.TestCase):
 def test_committed_manifest_is_exact_and_disjoint(self):
  d=json.loads((HERE/'cache-cleanup-manifest-v6.json').read_text(encoding='utf-8'))
  rows=c.validate_manifest(d)
  self.assertEqual(len(rows),21)
  self.assertEqual(sum(r['allocated_bytes'] for r in rows),1780559872)
  self.assertEqual(d['disjoint_archive_cache_proof']['externally_missing_children_count'],3)
  self.assertEqual(d['disjoint_archive_cache_proof']['externally_missing_allocated_bytes'],406663168)
  self.assertEqual({r['path'] for r in rows}&set(d['disjoint_archive_cache_proof']['externally_missing_paths']),set())
  for r in rows:self.assertNotIn(c.project_root(r['path']).rsplit('/',1)[-1],c.ARCHIVE_RELEASES|c.PROTECTED)
 def valid(self):return manifest([row('/tmp/krug-%02d/build'%n,n) for n in range(21)])
 def test_embedded_scripts_compile(self):compile(c.REMOTE_COMMON,'common','exec');compile(c.REMOTE_BUILDER,'builder','exec')
 def test_builder_prune_captures_stdout_and_emits_one_json(self):
  self.assertIn('capture_output=True,text=True',c.REMOTE_BUILDER);self.assertEqual(c.REMOTE_BUILDER.count('print('),1)
 def test_nul_builds(self):
  for raw in (b'docker\0build\0.',b'docker\0buildx\0build\0.',b'/x/docker-buildx\0build\0.',b'buildctl\0build\0.',b'flutter\0build\0web',b'dart\0compile\0exe'):self.assertTrue(c.is_active_build(raw))
  self.assertFalse(c.is_active_build(b'docker\0ps\0'))
 def test_mount_unescape(self):self.assertEqual(c.unescape_mount(r'/a\040b'),'/a b')
 def test_tamper_protected_count(self):
  d=self.valid()
  with mock.patch.object(c,'MANIFEST_SHA',d['manifest_sha256']):self.assertEqual(len(c.validate_manifest(d)),21)
  d['cache_children'][0]['inode']=99
  with self.assertRaises(ValueError):c.validate_manifest(d)
  for name in (*c.PROTECTED,'ui55-backend-FirDEO1L'):
   d=self.valid();d['cache_children'][-1]=row('/opt/ll/releases/'+name+'/app/build');d['manifest_sha256']=c.digest({k:v for k,v in d.items() if k!='manifest_sha256'})
   with mock.patch.object(c,'MANIFEST_SHA',d['manifest_sha256']):
    with self.assertRaises(ValueError):c.validate_manifest(d)
 def test_filesystem_telemetry_is_allowed_under_hash_pin(self):
  d=self.valid();d['filesystem'].update({'observed_free_bytes':123,'target_percent':20,'total_bytes':456});d['manifest_sha256']=c.digest({k:v for k,v in d.items() if k!='manifest_sha256'})
  with mock.patch.object(c,'MANIFEST_SHA',d['manifest_sha256']):self.assertEqual(len(c.validate_manifest(d)),21)
 def test_nonpersistent_receipt_never_ssh(self):
  d=self.valid()
  with tempfile.TemporaryDirectory() as td:
   m=pathlib.Path(td)/'m';r=pathlib.Path(td)/'r';m.write_text(json.dumps(d))
   with mock.patch.object(c,'MANIFEST_SHA',d['manifest_sha256']),mock.patch.object(c,'ssh_python') as ssh:
    with self.assertRaises(ValueError):c.main(['--manifest',str(m),'--receipt',str(r),'--mode','cache-delete','--execute','--acknowledge-cache-cleanup'])
    ssh.assert_not_called()
if __name__=='__main__':unittest.main()
