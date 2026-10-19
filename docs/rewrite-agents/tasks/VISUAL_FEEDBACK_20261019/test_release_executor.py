import unittest
import release_executor as r

class VisualReleaseTest(unittest.TestCase):
 def test_baseline_is_exact_release70(self):
  self.assertEqual(r.BASE_REVISION, '70')
  self.assertEqual(r.BASE_DEPLOYMENT_REVISION, '68')
  self.assertEqual(r.BASE_BUILD_ID, 'quiz-2026.10.19-minimum20-7f8344d6')
  self.assertEqual(r.API_SHA256, 'e2884077520a274a753cab0eff58c663aed159fd723c24e2b8f1e234c75539e4')
 def test_quizzes_must_be_identical(self):
  base={f'quiz-{i}.json':str(i) for i in range(165)}
  r.validate_quiz_closure({'base':base, 'candidate':base, 'expected_mutated':[]},base)
  changed={**base,'quiz-0.json':'changed'}
  with self.assertRaises(r.GuardError): r.validate_quiz_closure({'base':base,'candidate':changed,'expected_mutated':[]},changed)
  with self.assertRaises(r.GuardError): r.validate_quiz_closure({'base':base,'candidate':{**base,'new.json':'x'},'expected_mutated':[]},{**base,'new.json':'x'})
 def test_image_only_copies_web(self):
  self.assertIn('COPY --chown=10001:10001 web/',r.DOCKERFILE)
  self.assertNotIn('COPY --chown=10001:10001 api',r.DOCKERFILE)
  self.assertNotIn('COPY --chown=10001:10001 quizzes/',r.DOCKERFILE)
 def test_release_gates_remain(self):
  script=r.remote_script('quiz-2026.10.19-visual-abcdef12',r.API_SHA256,'prepare')+r.remote_script('quiz-2026.10.19-visual-abcdef12',r.API_SHA256,'publish')
  for needle in ['DEPLOY.lock','f_bavail * 5 >= s.f_blocks','helm rollback quiz-master 70','--require-real-http-grading','--require-article-revision-binding','canonical-cri.json','restore-proof.sqlite','feedback-before.json','helm lint --strict','kubectl apply --dry-run=server']:
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
if __name__=='__main__':unittest.main()
