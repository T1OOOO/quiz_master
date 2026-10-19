import hashlib, importlib.util, json, tempfile, unittest
from pathlib import Path
import release_executor as release

class BooksReleaseTest(unittest.TestCase):
 def setUp(self):
  self.tmp=tempfile.TemporaryDirectory(); self.addCleanup(self.tmp.cleanup); self.root=Path(self.tmp.name)
  (self.root/"web/flags").mkdir(parents=True); (self.root/"chart").mkdir(); (self.root/"chart/Chart.yaml").write_text("name: quiz-master\n")
  (self.root/"api").write_bytes(b"\x7fELFcandidate"); (self.root/"web/main.dart.js").write_bytes(b"compiled")
  self.build="quiz-2026.10.19-books-test"
  self.old={"id":"preparation-books-modern","questions":[{"id":f"old-{i}","text":f"Old {i}","options":["a","b","c","d"],"correct_answer":i%4,"difficulty":1 if i<22 else 4,"explanation":"reviewed"} for i in range(30)]}
  self.candidate=json.loads(json.dumps(self.old)); self.candidate["questions"] += [{"id":f"new-{i}","text":f"New {i}","options":["a","b","c","d"],"correct_answer":2,"difficulty":4,"explanation":"reviewed rationale"} for i in range(12)]
  (self.root/"book-quiz.json").write_text(json.dumps(self.candidate))
  version={"buildId":self.build,"source_commit":"a"*40,"api_sha256":release.sha256_file(self.root/"api"),"main_dart_js_sha256":release.sha256_file(self.root/"web/main.dart.js"),"packs":144,"questions":4486,"question_articles":305,"quizipedia_facts":12316}
  (self.root/"web/version.json").write_text(json.dumps(version)); self.version=version
  for i in range(195):
   data=b"\x89PNG\r\n\x1a\n"+str(i).encode(); (self.root/"web/flags"/(hashlib.sha256(data).hexdigest()+".png")).write_bytes(data)
 def test_numeric_book_input_and_old_prefix_guard(self):
  inputs=release.collect_inputs(self.root); release.validate_package_identity(inputs,self.build); release.validate_books_append(self.old,self.candidate)
  changed=json.loads(json.dumps(self.candidate)); changed["questions"][4]["correct_answer"]=3
  with self.assertRaisesRegex(release.GuardError,"old thirty"): release.validate_books_append(self.old,changed)
  changed=json.loads(json.dumps(self.candidate)); changed["questions"][30]["difficulty"]=3
  with self.assertRaisesRegex(release.GuardError,"numeric medium"): release.validate_books_append(self.old,changed)
 def test_rejects_extra_quiz_tree_and_invalid_numeric_difficulty(self):
  (self.root/"extra-quizzes").mkdir()
  with self.assertRaisesRegex(release.GuardError,"must not contain"): release.collect_inputs(self.root)
  (self.root/"extra-quizzes").rmdir()
  bad=json.loads(json.dumps(self.candidate)); bad["questions"][31]["difficulty"]="medium"; (self.root/"book-quiz.json").write_text(json.dumps(bad))
  with self.assertRaisesRegex(release.GuardError,"numeric"): release.collect_inputs(self.root)
 def test_remote_script_keeps_reviewed_publish_receipt_and_books_closure(self):
  prepare=release.remote_script(self.build,self.version["api_sha256"],"prepare"); publish=release.remote_script(self.build,self.version["api_sha256"],"publish")
  for needle in ("reviewed-receipt.json","prepared-receipt.json","verify_public","helm rollback quiz-master 67","book-quiz.json","len(base) != 148","old books questions changed","difficulty') != 4","--book-quiz"):
   self.assertIn(needle,prepare+publish)
  self.assertIn('helm upgrade quiz-master',publish); self.assertIn('--set-string image="$candidate_image"',publish); self.assertIn('--set-string buildId="$build"',publish)
  with self.assertRaises(release.GuardError): release.remote_script(self.build,"bad","prepare")
 def test_live_baseline_and_node_guards(self):
  self.assertEqual((release.BASE_REVISION,release.BASE_DEPLOYMENT_REVISION),("67","65"))
  release.validate_imagefs_blocks(20,100)
  with self.assertRaises(release.GuardError): release.validate_imagefs_blocks(19,100)
  healthy={"status":{"conditions":[{"type":"Ready","status":"True"},{"type":"DiskPressure","status":"False"}]},"spec":{"taints":[]}}
  release.validate_node_status(healthy)
  with self.assertRaises(release.GuardError): release.validate_node_status({"status":{"conditions":[{"type":"Ready","status":"False"}]},"spec":{}})
if __name__=="__main__": unittest.main()
