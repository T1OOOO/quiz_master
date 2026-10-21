import hashlib,json,tempfile,unittest,shlex
from unittest import mock
from pathlib import Path
import release_executor as r
class Release79GuardsTest(unittest.TestCase):
 def test_oci_identity_inline_python_survives_shell_quoting(self):
  script=r.remote_script('quiz-2026.10.21-feedback-deadbeef',r.API_SHA256,'prepare')
  commands=[line for line in script.splitlines() if line.startswith(('k3s ctr -n k8s.io content get ','k3s crictl inspecti ')) and 'python3 -c' in line]
  self.assertEqual(len(commands),3)
  for command in commands:
   tokens=shlex.split(command)
   compile(tokens[tokens.index('-c')+1],'<generated OCI identity guard>','exec')
 def test_imagefs_guards_resolve_a_directory_inside_the_mount(self):
  build='quiz-2026.10.21-feedback-deadbeef'
  stage=r.remote_stage_script(build)
  staging_python=stage.split("python3 - <<'PY'\n",1)[1].split('\nPY\n',1)[0]
  prepare=r.remote_script(build,r.API_SHA256,'prepare')
  guard_line=next(line for line in prepare.splitlines() if line.startswith(" python3 -c 'import os,subprocess,re;"))
  inline_python=shlex.split(guard_line)[2]
  for code in (staging_python,inline_python):
   for fstype,source,reserve,should_pass in [('ext4','/dev/vda2',1271337,True),('xfs','/dev/vda2',1271337,False),('ext4','/dev/other',1271337,False),('ext4','/dev/vda2',1,False)]:
    def probe(args,**kwargs):
     if args[0]=='findmnt':
      if '-T' not in args:raise RuntimeError('a directory within a filesystem is not a mountpoint')
      return (fstype if 'FSTYPE' in args else source)+'\n'
     self.assertEqual(args,['tune2fs','-l','/dev/vda2'])
     return 'Reserved block count: '+str(reserve)+'\n'
    with self.subTest(code=code[:30],fstype=fstype,source=source,reserve=reserve),mock.patch('os.statvfs',create=True,return_value=mock.Mock(f_bfree=50,f_bavail=30,f_blocks=100)),mock.patch('subprocess.check_output',side_effect=probe):
     if should_pass:exec(code,{})
     else:
      with self.assertRaises(AssertionError):exec(code,{})
 def test_flutter_build_fingerprint_is_an_exact_generated_path(self):
  with tempfile.TemporaryDirectory() as d:
   root=Path(d); (root/'.last_build_id').write_text('a'*32)
   r.validate_web_delta({'.last_build_id':'old'},{'.last_build_id':'new'},{'.last_build_id':'new'},root,{})
   with self.assertRaises(r.GuardError): r.validate_web_delta({'.last_build_id':'old'},{'.last_build_id':'new','unapproved.txt':'bad'},{'.last_build_id':'new','unapproved.txt':'bad'},root,{})
   (root/'.last_build_id').write_text('not-a-Flutter-fingerprint')
   with self.assertRaises(r.GuardError): r.validate_web_delta({'.last_build_id':'old'},{'.last_build_id':'new'},{'.last_build_id':'new'},root,{})
 def test_generated_manifests_do_not_require_content_allowlist(self):
  with tempfile.TemporaryDirectory() as d:
   root=Path(d); asset=root/'assets'/'data.json'; asset.parent.mkdir(); asset.write_bytes(b'new'); digest=hashlib.sha256(b'new').hexdigest()
   allow={'assets/data.json':{'path':'assets/data.json','sha256':digest,'bytes':3}}
   base={'main.dart.js':'old','assets/data.json':'old','assets/AssetManifest.bin':'old','assets/FontManifest.json':'old'}
   candidate={'main.dart.js':'new','assets/data.json':digest,'assets/AssetManifest.bin':'new','assets/FontManifest.json':'new'}
   r.validate_web_delta(base,candidate,candidate,root,allow)
   with self.assertRaises(r.GuardError): r.validate_web_delta(base,{**candidate,'assets/unapproved.json':'new'},{**candidate,'assets/unapproved.json':'new'},root,allow)
 def test_baseline_and_tag(self):
  self.assertEqual((r.BASE_REVISION,r.BASE_DEPLOYMENT_REVISION,r.BASE_BUILD_ID),('79','77','quiz-2026.10.21-feedback-0c536221'))
  r.validate_build_id('quiz-2026.10.21-feedback-deadbeef')
  with self.assertRaises(r.GuardError):r.validate_build_id('quiz-2026.10.20-lazy-deadbeef')
 def test_server_guards(self):
  # Real statvfs can differ from the superblock reservation by allocator metadata.
  r.validate_imagefs_blocks(2000000,3275433,10000000,1271337,'/dev/vda2')
  with self.assertRaises(r.GuardError):r.validate_imagefs_blocks(2000000,3275433,10000000,1019547,'/dev/vda2')
  with self.assertRaises(r.GuardError):r.validate_imagefs_blocks(199,1271532,1000,1271337,'/dev/vda2')
  with self.assertRaises(r.GuardError):r.validate_imagefs_blocks(2000000,3275433,10000000,None,None)
  receipt=b'{"build_id":"quiz-2026.10.21-feedback-deadbeef","input_sha256":"x","image":"x@sha256:y"}'
  script=r.remote_script('quiz-2026.10.21-feedback-deadbeef',r.API_SHA256,'publish',reviewed_receipt_bytes=receipt)
  for x in ('tune2fs','Reserved block count','/dev/vda2','helm rollback quiz-master 79','= "80"','restore-proof.sqlite','review receipt hash mismatch','deadbeef-publish.sqlite'):self.assertIn(x,script)
  self.assertLess(script.index('volatile_checks.py" unmount'),script.index('helm upgrade'))
  prepare=r.remote_script('quiz-2026.10.21-feedback-deadbeef',r.API_SHA256,'prepare')
  self.assertIn('k3s ctr -n k8s.io content get sha256:c05f',prepare); self.assertIn('baseline image web closure',prepare)
 def test_exact_approved_asset_bytes(self):
  with tempfile.TemporaryDirectory() as d:
   root=Path(d); f=root/'assets'/'a.png';f.parent.mkdir();f.write_bytes(b'abc');digest=hashlib.sha256(b'abc').hexdigest();p=root/r.ASSET_ALLOWLIST_NAME;p.write_text(json.dumps([{'path':'assets/a.png','sha256':digest,'bytes':3}]));allow=r.load_asset_allowlist(p)
   r.validate_web_delta({'main.dart.js':'x'},{'main.dart.js':'y','assets/a.png':digest},{'main.dart.js':'y','assets/a.png':digest},root,allow)
   f.write_bytes(b'bad')
   with self.assertRaises(r.GuardError):r.validate_web_delta({'main.dart.js':'x'},{'main.dart.js':'y','assets/a.png':digest},{'main.dart.js':'y','assets/a.png':digest},root,allow)
 def test_unapproved_or_deleted_asset_fails(self):
  with tempfile.TemporaryDirectory() as d:
   root=Path(d);(root/'assets').mkdir();(root/'assets'/'a.png').write_bytes(b'a');digest=hashlib.sha256(b'a').hexdigest();allow={'assets/a.png':{'path':'assets/a.png','sha256':digest,'bytes':1}}
   with self.assertRaises(r.GuardError):r.validate_web_delta({'main':'x'},{'main':'x','assets/a.png':digest,'assets/b.png':'a'},{'assets/a.png':digest,'assets/b.png':'a'},root,allow)
   with self.assertRaises(r.GuardError):r.validate_web_delta({'main':'x'},{},{},root,{})

 def test_modified_asset_and_unapproved_non_generated_path_fail(self):
  with tempfile.TemporaryDirectory() as d:
   root=Path(d); asset=root/'assets'/'old.png'; asset.parent.mkdir(); asset.write_bytes(b'new'); digest=hashlib.sha256(b'new').hexdigest(); allow={'assets/old.png':{'path':'assets/old.png','sha256':digest,'bytes':3}}
   r.validate_web_delta({'assets/old.png':'old','main.dart.js':'old'},{'assets/old.png':digest,'main.dart.js':'new'},{'assets/old.png':digest,'main.dart.js':'new'},root,allow)
   with self.assertRaises(r.GuardError):r.validate_web_delta({'index.html':'old'},{'index.html':'new'},{'index.html':'new'},root,{})
 def test_publish_requires_receipt_and_separate_pins(self):
  with self.assertRaises(r.GuardError):r.remote_script('quiz-2026.10.21-feedback-deadbeef',r.API_SHA256,'publish')
  self.assertNotEqual(r.BASE_OCI_INDEX_DIGEST,r.BASE_OCI_MANIFEST_DIGEST); self.assertNotEqual(r.BASE_OCI_MANIFEST_DIGEST,r.BASE_DOCKER_CONFIG_DIGEST)


 def test_release79_lineage_binds_historical_context(self):
  manifest={'baseline':{'revision':'78'},'web':{'main.dart.js':'a'*64},'support':{'rehearse.py':'b'*64}}
  synthetic_sha=r.canonical_json_sha256(manifest)
  receipt={'build_id':r.BASE_BUILD_ID,'image':r.BASE_IMAGE,'input_sha256':synthetic_sha}
  with mock.patch.object(r,'BASE_INPUT_SHA256',synthetic_sha):
   r.validate_baseline_lineage(manifest,receipt)
   altered=json.loads(json.dumps(manifest)); altered['web']['main.dart.js']='0'*64
   with self.assertRaises(r.GuardError): r.validate_baseline_lineage(altered,receipt)
   altered_receipt=dict(receipt); altered_receipt['input_sha256']='0'*64
   with self.assertRaises(r.GuardError): r.validate_baseline_lineage(manifest,altered_receipt)
  self.assertEqual(r.BASE_INPUT_SHA256,'ca89b956a2512508487829d169bc2522fefb68932f3f0f00cb196a2de70dc384')

if __name__=='__main__':unittest.main()
