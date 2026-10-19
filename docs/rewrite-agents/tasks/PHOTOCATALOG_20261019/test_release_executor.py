import unittest
import release_executor as r

class VisualReleaseTest(unittest.TestCase):
 def test_baseline_is_exact_release70(self):
  self.assertEqual(r.BASE_REVISION, '72')
  self.assertEqual(r.BASE_DEPLOYMENT_REVISION, '70')
  self.assertEqual(r.BASE_BUILD_ID, 'quiz-2026.10.19-grid-9de2ad04')
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
 def test_release_gates_remain(self):
  script=r.remote_script('quiz-2026.10.19-visual-abcdef12',r.API_SHA256,'prepare')+r.remote_script('quiz-2026.10.19-visual-abcdef12',r.API_SHA256,'publish')
  for needle in ['DEPLOY.lock','f_bavail * 5 >= s.f_blocks','helm rollback quiz-master 72','--require-real-http-grading','--require-article-revision-binding','canonical-cri.json','restore-proof.sqlite','feedback-before.json','helm lint --strict','kubectl apply --dry-run=server']:
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
 def test_exact_changed_file_set(self):
  r.validate_web_delta({'a':'x','b':'y'},{'a':'z','b':'y'},{'a':'z'})
 def test_omitted_or_unexpected_delta_rejected(self):
  for delta in ({},{'a':'x'},{'a':'z','b':'y'}):
   with self.assertRaises(r.GuardError):r.validate_web_delta({'a':'x','b':'y'},{'a':'z','b':'y'},delta)
 def test_only_reviewed_photo_paths_may_be_added(self):
  self.assertEqual(len(r.NEW_WEB_PATHS),30)
  for path in r.NEW_WEB_PATHS:
   r.validate_web_delta({'a':'x'},{'a':'x',path:'z'},{path:'z'})
  for path in ['assets/assets/quizipedia/unknown.jpg','assets/assets/quizipedia/country_flag_images.json']:
   with self.assertRaises(r.GuardError):r.validate_web_delta({'a':'x'},{'a':'x',path:'z'},{path:'z'})
 def test_new_or_deleted_web_path_rejected(self):
  for candidate in ({'a':'x'}, {'a':'x','b':'y','new':'z'}):
   with self.assertRaises(r.GuardError):r.validate_web_delta({'a':'x','b':'y'},candidate,candidate)
if __name__=='__main__':unittest.main()
