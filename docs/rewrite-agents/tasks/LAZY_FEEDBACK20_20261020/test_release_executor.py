import unittest
import io
from pathlib import Path
from unittest import mock
import release_executor as r

class VisualReleaseTest(unittest.TestCase):
 def test_staging_omits_the_redundant_api_but_keeps_runtime_hash_gates(self):
  archive=mock.Mock(stdout=io.BytesIO(),wait=mock.Mock(return_value=0))
  inputs=r.Inputs(Path('package'),Path('web'),Path('chart'),Path('version.json'),{'staged_web':{'version.json':'v'}})
  with mock.patch.object(r.subprocess,'Popen',return_value=archive) as popen, mock.patch.object(r.subprocess,'run'):
   r.stage_package('root@192.3.164.184',Path('key'),'quiz-2026.10.20-touch-abcdef12',inputs)
  self.assertNotIn('api',popen.call_args.args[0])
  script=r.remote_script('quiz-2026.10.20-touch-abcdef12',r.API_SHA256,'prepare')
  self.assertIn('docker cp "$new_api:/app/api" - | tar -xOf - api | sha256sum',script)
  self.assertIn(r.API_SHA256,script)
 def test_ram_proofs_end_before_prepare_receipt_and_publication(self):
  script=r.remote_script('quiz-2026.10.20-touch-abcdef12',r.API_SHA256,'prepare')
  start=script.index('record-rehearsal')
  unmount=script.index('volatile_checks.py" unmount',start)
  self.assertLess(unmount,script.index('PREPARED receipt='))
  publish=script[script.index('test -f "$stage/reviewed-receipt.json"'):]
  self.assertLess(publish.index('record-restore'),publish.index('volatile_checks.py" unmount'))
  self.assertLess(publish.index('volatile_checks.py" unmount'),publish.index('helm upgrade'))
 def test_baseline_is_exact_release77(self):
  self.assertEqual(r.BASE_REVISION, '77')
  self.assertEqual(r.BASE_DEPLOYMENT_REVISION, '75')
  self.assertEqual(r.BASE_BUILD_ID, 'quiz-2026.10.20-atlas-4fc2fd02')
  self.assertEqual(r.API_SHA256, 'e2884077520a274a753cab0eff58c663aed159fd723c24e2b8f1e234c75539e4')
 def test_quizzes_must_be_identical(self):
  base={f'quiz-{i}.json':str(i) for i in range(165)}
  r.validate_quiz_closure({'base':base, 'candidate':base, 'expected_mutated':[]},base)
  changed={**base,'quiz-0.json':'changed'}
  with self.assertRaises(r.GuardError): r.validate_quiz_closure({'base':base,'candidate':changed,'expected_mutated':[]},changed)
  with self.assertRaises(r.GuardError): r.validate_quiz_closure({'base':base,'candidate':{**base,'new.json':'x'},'expected_mutated':[]},{**base,'new.json':'x'})
 def test_image_only_copies_web(self):
  self.assertIn('COPY --chown=10001:10001 web-delta/',r.DOCKERFILE)
  self.assertNotIn('COPY --chown=10001:10001 api',r.DOCKERFILE)
  self.assertNotIn('COPY --chown=10001:10001 quizzes/',r.DOCKERFILE)
 def test_runtime_api_hashes_stream_without_redundant_disk_copies(self):
  script=r.remote_script('quiz-2026.10.20-water-abcdef12',r.API_SHA256,'prepare')
  self.assertIn('docker cp "$base_api:/app/api" - | tar -xOf - api | sha256sum',script)
  self.assertIn('docker cp "$new_api:/app/api" - | tar -xOf - api | sha256sum',script)
  self.assertIn('base-api-sha256.txt',script)
  self.assertIn('new-api-sha256.txt',script)
  self.assertNotIn('$stage/base.api',script)
  self.assertNotIn('$stage/new.api',script)
 def test_release_gates_remain(self):
  script=r.remote_script('quiz-2026.10.19-visual-abcdef12',r.API_SHA256,'prepare')+r.remote_script('quiz-2026.10.19-visual-abcdef12',r.API_SHA256,'publish')
  for needle in ['DEPLOY.lock','f_bavail * 5 >= s.f_blocks','helm rollback quiz-master 77','--require-real-http-grading','--require-article-revision-binding','canonical-cri.json','restore-proof.sqlite','feedback-before.json','helm lint --strict','kubectl apply --dry-run=server']:
   self.assertIn(needle,script)
  self.assertIn('frontend-only candidate changed a quiz source byte',script)
  self.assertIn('test \"$(sha256sum',script)
 def test_wrong_host_and_tag_rejected(self):
  with self.assertRaises(r.GuardError): r.validate_ssh_target('wrong.example')
  with self.assertRaises(r.GuardError): r.validate_build_id(r.BASE_BUILD_ID)
  with self.assertRaises(r.GuardError): r.validate_build_id('other-tag')
 def test_disk_and_node_guards(self):
  with self.assertRaises(r.GuardError): r.validate_imagefs_blocks(199,1000)
  r.validate_imagefs_blocks(200,1000)
  with self.assertRaises(r.GuardError): r.validate_node_status({'status':{'conditions':[{'type':'Ready','status':'True'},{'type':'DiskPressure','status':'True'}]}})
class DeltaTest(unittest.TestCase):
 def test_remote_staging_retains_every_json_for_article_rehearsal(self):
  web={'main.dart.js':'a','version.json':'b','assets/articles.json':'c','assets/photo.jpg':'d'}
  self.assertEqual(r.staged_web_manifest(web),{'version.json':'b','assets/articles.json':'c'})
 def test_restored_database_is_reused_after_integrity_proof(self):
  script=r.remote_script('quiz-2026.10.20-sky-abcdef12',r.API_SHA256,'prepare')
  self.assertIn('restore-proof-sha256.txt',script)
  self.assertIn('mv "$stage/volatile-checks/restore-proof.sqlite" "$stage/volatile-checks/rehearsal-data/quiz.db"',script)
  self.assertNotIn('cp "$stage/volatile-checks/restore-proof.sqlite" "$stage/volatile-checks/rehearsal-data/quiz.db"',script)
 def test_exact_changed_file_set(self):
  r.validate_web_delta({'a':'x','b':'y'},{'a':'z','b':'y'},{'a':'z'})
 def test_omitted_or_unexpected_delta_rejected(self):
  for delta in ({},{'a':'x'},{'a':'z','b':'y'}):
   with self.assertRaises(r.GuardError):r.validate_web_delta({'a':'x','b':'y'},{'a':'z','b':'y'},delta)
 def test_only_reviewed_bundle_paths_may_be_added(self):
  self.assertEqual(len(r.NEW_WEB_PATHS),66)
  for path in r.NEW_WEB_PATHS:
   r.validate_web_delta({'a':'x'},{'a':'x',path:'z'},{path:'z'})
  for path in ['assets/assets/quizipedia/unknown.jpg','assets/assets/quizipedia/country_flag_images.json']:
   with self.assertRaises(r.GuardError):r.validate_web_delta({'a':'x'},{'a':'x',path:'z'},{path:'z'})
 def test_new_or_deleted_web_path_rejected(self):
  for candidate in ({'a':'x'}, {'a':'x','b':'y','new':'z'}):
   with self.assertRaises(r.GuardError):r.validate_web_delta({'a':'x','b':'y'},candidate,candidate)
if __name__=='__main__':unittest.main()
