import hashlib, importlib.util, json, tempfile, unittest
from pathlib import Path
import release_executor as release

class BonesReleaseTest(unittest.TestCase):
 def setUp(self):
  self.tmp=tempfile.TemporaryDirectory(); self.addCleanup(self.tmp.cleanup); self.root=Path(self.tmp.name)
  (self.root/"web/flags").mkdir(parents=True); (self.root/"chart").mkdir(); (self.root/"chart/Chart.yaml").write_text("name: quiz-master\n")
  (self.root/"api").write_bytes(b"\x7fELFcandidate"); (self.root/"web/main.dart.js").write_bytes(b"compiled")
  self.build="quiz-2026.10.19-bones-test"
  self.old={"id":"preparation-books-modern","questions":[{"id":f"old-{i}","text":f"Old {i}","options":["a","b","c","d"],"correct_answer":i%4,"difficulty":1 if i<22 else 4,"explanation":"reviewed"} for i in range(30)]}
  self.candidate=json.loads(json.dumps(self.old)); self.candidate["questions"] += [{"id":f"new-{i}","text":f"New {i}","options":["a","b","c","d"],"correct_answer":2,"difficulty":4,"explanation":"reviewed rationale"} for i in range(12)]
  (self.root/"book-quiz.json").write_text(json.dumps(self.candidate))
  version={"buildId":self.build,"source_commit":"a"*40,"api_sha256":release.sha256_file(self.root/"api"),"main_dart_js_sha256":release.sha256_file(self.root/"web/main.dart.js"),"packs":144,"questions":4486,"question_articles":305,"quizipedia_facts":12316}
  (self.root/"web/version.json").write_text(json.dumps(version)); self.version=version
  for i in range(195):
   data=b"\x89PNG\r\n\x1a\n"+str(i).encode(); (self.root/"web/flags"/(hashlib.sha256(data).hexdigest()+".png")).write_bytes(data)
 def test_private_books_fixture_and_frontend_quiz_byte_closure(self):
  inputs=release.collect_inputs(self.root); release.validate_package_identity(inputs,self.build)
  base={f"quiz-{index}.json": f"source-{index}".encode() for index in range(148)}
  candidate=dict(base)
  release.validate_frontend_only_quiz_closure(base,candidate)
  candidate["quiz-47.json"]=b"one-byte source mutation"
  with self.assertRaisesRegex(release.GuardError,"source byte"): release.validate_frontend_only_quiz_closure(base,candidate)
  self.assertNotIn("book-quiz.json",release.FRONTEND_DOCKERFILE)
 def test_rejects_extra_quiz_tree_and_invalid_numeric_difficulty(self):
  (self.root/"extra-quizzes").mkdir()
  with self.assertRaisesRegex(release.GuardError,"must not contain"): release.collect_inputs(self.root)
  (self.root/"extra-quizzes").rmdir()
  bad=json.loads(json.dumps(self.candidate)); bad["questions"][31]["difficulty"]="medium"; (self.root/"book-quiz.json").write_text(json.dumps(bad))
  with self.assertRaisesRegex(release.GuardError,"numeric"): release.collect_inputs(self.root)
 def test_rehearsal_requires_42_book_questions_without_append_position_assumption(self):
  spec=importlib.util.spec_from_file_location("bones_rehearse",Path(__file__).with_name("rehearse.py"))
  rehearse=importlib.util.module_from_spec(spec); spec.loader.exec_module(rehearse)
  self.assertEqual(len(rehearse.require_regional_sources(self.root/"book-quiz.json")["preparation-books-modern"]["questions"]),42)
  shuffled=json.loads(json.dumps(self.candidate)); shuffled["questions"][0]["difficulty"]=4; shuffled["questions"][30]["difficulty"]=1
  (self.root/"book-quiz.json").write_text(json.dumps(shuffled))
  rehearse.require_regional_sources(self.root/"book-quiz.json")
  bad=json.loads(json.dumps(shuffled)); bad["questions"][1]["difficulty"]=4
  (self.root/"book-quiz.json").write_text(json.dumps(bad))
  with self.assertRaisesRegex(RuntimeError,"difficulty distribution"): rehearse.require_regional_sources(self.root/"book-quiz.json")
 def test_remote_script_keeps_reviewed_publish_receipt_and_frontend_only_closure(self):
  prepare=release.remote_script(self.build,self.version["api_sha256"],"prepare"); publish=release.remote_script(self.build,self.version["api_sha256"],"publish")
  for needle in ("reviewed-receipt.json","prepared-receipt.json","verify_public","helm rollback quiz-master 68","book-quiz.json","len(base) != 148","frontend-only candidate changed a quiz source byte","base != candidate","--book-quiz"):
   self.assertIn(needle,prepare+publish)
  self.assertIn('cmp -s "$stage/base.api" "$stage/new.api"',prepare)
  self.assertIn('helm upgrade quiz-master',publish); self.assertIn('--set-string image="$candidate_image"',publish); self.assertIn('--set-string buildId="$build"',publish)
  with self.assertRaises(release.GuardError): release.remote_script(self.build,"bad","prepare")
 def test_package_builder_keeps_api_and_fact_count_explicit(self):
  builder=Path(__file__).with_name("prepare_package.py").read_text(encoding="utf-8")
  for needle in ("--preflight","--quizipedia-facts","quiz-2026.10.19-bones-","frontend_only=True","208ac3638f5d7bd3e081b2f042b0afcf222c95a4b1af5e139286e45a3e6f22aa"):
   self.assertIn(needle,builder)
 def test_live_baseline_and_node_guards(self):
  self.assertEqual((release.BASE_REVISION,release.BASE_DEPLOYMENT_REVISION),("68","66"))
  release.validate_imagefs_blocks(20,100)
  with self.assertRaises(release.GuardError): release.validate_imagefs_blocks(19,100)
  healthy={"status":{"conditions":[{"type":"Ready","status":"True"},{"type":"DiskPressure","status":"False"}]},"spec":{"taints":[]}}
  release.validate_node_status(healthy)
  with self.assertRaises(release.GuardError): release.validate_node_status({"status":{"conditions":[{"type":"Ready","status":"False"}]},"spec":{}})
if __name__=="__main__": unittest.main()

