import hashlib, json, tempfile, unittest, importlib.util
from unittest.mock import patch
from subprocess import CompletedProcess
from pathlib import Path
import release_executor as release
SPEC=importlib.util.spec_from_file_location('prepare_package',Path(__file__).with_name('prepare_package.py')); prepare=importlib.util.module_from_spec(SPEC); SPEC.loader.exec_module(prepare)

class Minimum20ReleaseTest(unittest.TestCase):
 def setUp(self):
  self.tmp=tempfile.TemporaryDirectory(); self.addCleanup(self.tmp.cleanup); self.root=Path(self.tmp.name); self.build='quiz-2026.10.19-minimum20-abcdef12'
  for d in ('web/flags','chart','quizzes','private/quizzes','private/study/drafts'): (self.root/d).mkdir(parents=True,exist_ok=True)
  (self.root/'chart/Chart.yaml').write_text('name: quiz-master\n'); (self.root/'api').write_bytes(b'\x7fELFminimum20')
  (self.root/'web/main.dart.js').write_bytes(b'compiled')
  for i in range(195):
   raw=b'\x89PNG\r\n\x1a\n'+str(i).encode(); (self.root/'web/flags'/(hashlib.sha256(raw).hexdigest()+'.png')).write_bytes(raw)
  base={f'old-{i}.json':hashlib.sha256(f'old-{i}'.encode()).hexdigest() for i in range(137)}; base.update({name:hashlib.sha256(('old-'+name).encode()).hexdigest() for name in release.EXPECTED_MUTATED}); candidate=dict(base)
  for name in release.EXPECTED_MUTATED: candidate[name]=hashlib.sha256(('changed-'+name).encode()).hexdigest()
  for i in range(17): candidate[f'Collections/new-{i}.json']=hashlib.sha256(f'new-{i}'.encode()).hexdigest()
  for name,h in candidate.items():
   p=self.root/'quizzes'/name; p.parent.mkdir(parents=True,exist_ok=True); p.write_bytes((('changed-'+name) if name in release.EXPECTED_MUTATED else ('new-'+name) if name.startswith('Collections/new') else name.removesuffix('.json')).encode())
  # overwrite hashes from actual bytes, preserving closure shape.
  candidate=release.hash_tree(self.root/'quizzes'); base={k:(candidate[k] if k not in release.EXPECTED_MUTATED else hashlib.sha256(('old-'+k).encode()).hexdigest()) for k in candidate if not k.startswith('Collections/new')}
  (self.root/'quiz-closure.json').write_text(json.dumps({'base':base,'candidate':candidate,'expected_mutated':sorted(release.EXPECTED_MUTATED)}))
  for n in release.SUPPORT: (self.root/n).write_text('{}')
  v={'buildId':self.build,'source_commit':'a'*40,'api_sha256':release.sha256_file(self.root/'api'),'main_dart_js_sha256':release.sha256_file(self.root/'web/main.dart.js'),'packs':105,'questions':4520,'quizipedia_facts':13588,'question_articles':305,'question_article_references':241,'frontend_only':False}
  (self.root/'web/version.json').write_text(json.dumps(v)); (self.root/'catalog.json').write_text('[]')
 def test_exact_quiz_closure_and_private_api_contract(self):
  inputs=release.collect_inputs(self.root); release.validate_package_identity(inputs,self.build); self.assertEqual(len(inputs.manifest['quizzes']),165); self.assertIn('COPY --chown=10001:10001 api /app/api',release.DOCKERFILE); self.assertIn('COPY --chown=10001:10001 quizzes/',release.DOCKERFILE)
 def test_rejects_unapproved_existing_mutation_and_unchanged_api(self):
  closure=json.loads((self.root/'quiz-closure.json').read_text()); closure['candidate']['old-12.json']='f'*64; (self.root/'quiz-closure.json').write_text(json.dumps(closure))
  with self.assertRaisesRegex(release.GuardError,'closure'): release.collect_inputs(self.root)
  original=release.BASE_API_SHA256; release.BASE_API_SHA256=release.sha256_file(self.root/'api')
  try:
   with self.assertRaisesRegex(release.GuardError,'must differ'): release.collect_inputs(self.root)
  finally: release.BASE_API_SHA256=original
 def test_remote_scripts_keep_release_gates(self):
  script=release.remote_script(self.build,'a'*64,'prepare')+release.remote_script(self.build,'a'*64,'publish')
  for needle in ('DEPLOY.lock','f_bavail*5>=s.f_blocks','helm rollback quiz-master 69','restore-proof.sqlite','--require-real-http-grading','--require-article-revision-binding','canonical-cri.json','feedback'):
   self.assertIn(needle,script)
  self.assertIn('COPY --chown=10001:10001 quizzes/',release.DOCKERFILE); self.assertNotIn('ENTRYPOINT',release.DOCKERFILE); self.assertNotIn('{{',script); self.assertIn('test "$ready" = 1',script)
 def test_prepare_preflight_pins_live_baseline69(self):
  deployment={'hostname':'racknerd-f0269d5','revision':'69','deployment_revision':'67','pvc_uid':'7fc2428f-4146-4c78-a26d-2347d9f3b7bf','containers':[{'image':release.BASE_IMAGE},{'image':release.BASE_IMAGE}]}
  version={'buildId':'quiz-2026.10.19-bones-36e0b68c','api_sha256':release.BASE_API_SHA256}
  path=self.root/'preflight.json'; path.write_text(json.dumps(deployment)+json.dumps(version))
  prepare.require_preflight(path)
  deployment['revision']='70'; path.write_text(json.dumps(deployment)+json.dumps(version))
  with self.assertRaisesRegex(SystemExit,'baseline 69'): prepare.require_preflight(path)
 def test_prepare_api_provenance_requires_clean_linux_amd64_vcs(self):
  api=self.root/'api'; commit='b'*40
  good='path\tquiz_master/next/server/cmd/api\n\tbuild\tGOOS=linux\n\tbuild\tGOARCH=amd64\n\tbuild\tvcs.revision='+commit+'\n\tbuild\tvcs.modified=false\n'
  with patch.object(prepare.subprocess,'run',return_value=CompletedProcess([],0,good,'')): prepare.require_api_provenance(api,commit)
  with patch.object(prepare.subprocess,'run',return_value=CompletedProcess([],0,good.replace('vcs.modified=false','vcs.modified=true'),'')):
   with self.assertRaisesRegex(SystemExit,'provenance'): prepare.require_api_provenance(api,commit)
 def test_prepare_builder_is_clean_api_and_private_tree_only(self):
  text=Path(__file__).with_name('prepare_package.py').read_text()
  for needle in ('--api-source-commit','Refusing to package a dirty source checkout','--baseline-quizzes','require_preflight','require_api_provenance','assets/catalog.json',"shutil.copytree(base_root,private/'quizzes')",'question_article_references',"'frontend_only':False"):
   self.assertIn(needle,text)
if __name__=='__main__': unittest.main()