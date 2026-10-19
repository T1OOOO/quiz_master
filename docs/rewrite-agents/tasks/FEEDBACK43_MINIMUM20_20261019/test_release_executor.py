import hashlib, json, tempfile, unittest, importlib.util, sys
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
  for source in (self.root/'quizzes').rglob('*'):
   if source.is_file():
    target=self.root/'private/quizzes'/source.relative_to(self.root/'quizzes'); target.parent.mkdir(parents=True,exist_ok=True); target.write_bytes(source.read_bytes())
  for name in release.PRIVATE_DRAFTS: (self.root/'private/study/drafts'/name).write_text('{"frozen":true}')
  # overwrite hashes from actual bytes, preserving closure shape.
  candidate=release.hash_tree(self.root/'quizzes'); base={k:(candidate[k] if k not in release.EXPECTED_MUTATED else hashlib.sha256(('old-'+k).encode()).hexdigest()) for k in candidate if not k.startswith('Collections/new')}
  (self.root/'quiz-closure.json').write_text(json.dumps({'base':base,'candidate':candidate,'expected_mutated':sorted(release.EXPECTED_MUTATED)}))
  for n in release.SUPPORT: (self.root/n).write_text('{}')
  v={'buildId':self.build,'source_commit':'a'*40,'api_sha256':release.sha256_file(self.root/'api'),'main_dart_js_sha256':release.sha256_file(self.root/'web/main.dart.js'),'packs':105,'questions':4520,'quizipedia_facts':13588,'question_articles':305,'question_article_references':241,'frontend_only':False}
  (self.root/'web/version.json').write_text(json.dumps(v))
  rows=[]
  for i in range(105):
   count=2440 if i==0 else 20
   rows.append({'quiz_id':f'catalog-{i}','questions_count':count,'difficulty_counts':{'easy':count,'medium':0,'hard':0,'nightmare':0,'unknown':0}})
  (self.root/'catalog.json').write_text(json.dumps(rows))
 def test_exact_quiz_closure_and_private_api_contract(self):
  inputs=release.collect_inputs(self.root); release.validate_package_identity(inputs,self.build); self.assertEqual(len(inputs.manifest['quizzes']),165); self.assertIn('COPY --chown=10001:10001 api /app/api',release.DOCKERFILE); self.assertIn('COPY --chown=10001:10001 quizzes/',release.DOCKERFILE)
 def test_rejects_private_quiz_divergence_and_freezes_private_drafts(self):
  inputs=release.collect_inputs(self.root)
  self.assertIn('study/drafts/feedback43-planets-extra-20261019.json',inputs.manifest['private'])
  frozen_private=inputs.manifest['private']
  (self.root/'private/study/drafts/feedback43-planets-extra-20261019.json').write_text('{"frozen":false}')
  self.assertNotEqual(release.hash_tree(self.root/'private'),frozen_private)
  (self.root/'private/quizzes/old-0.json').write_bytes(b'tampered')
  with self.assertRaisesRegex(release.GuardError,'private/quizzes'): release.collect_inputs(self.root)
 def test_rejects_catalog_outside_public_minimum20_contract(self):
  rows=json.loads((self.root/'catalog.json').read_text()); rows[0]['difficulty_counts'].pop('unknown'); (self.root/'catalog.json').write_text(json.dumps(rows))
  with self.assertRaisesRegex(release.GuardError,'catalog bank'): release.collect_inputs(self.root)
 def test_rejects_unapproved_existing_mutation_and_unchanged_api(self):
  closure=json.loads((self.root/'quiz-closure.json').read_text()); closure['candidate']['old-12.json']='f'*64; (self.root/'quiz-closure.json').write_text(json.dumps(closure))
  with self.assertRaisesRegex(release.GuardError,'closure'): release.collect_inputs(self.root)
  closure['candidate']['old-12.json']=release.hash_tree(self.root/'quizzes')['old-12.json']; (self.root/'quiz-closure.json').write_text(json.dumps(closure))
  original=release.API_SHA256; release.API_SHA256=release.sha256_file(self.root/'api')
  try:
   with self.assertRaisesRegex(release.GuardError,'must differ'): release.collect_inputs(self.root)
  finally: release.API_SHA256=original
 def test_remote_scripts_keep_release_gates(self):
  script=release.remote_script(self.build,'a'*64,'prepare')+release.remote_script(self.build,'a'*64,'publish')
  for needle in ('DEPLOY.lock','f_bavail * 5 >= s.f_blocks','helm rollback quiz-master 69','restore-proof.sqlite','--require-real-http-grading','--require-article-revision-binding','canonical-cri.json','feedback'):
   self.assertIn(needle,script)
  self.assertIn('COPY --chown=10001:10001 quizzes/',release.DOCKERFILE); self.assertIn('chmod 0755 /app/api',release.DOCKERFILE); self.assertIn('chmod -R u=rwX,go=rX /app/quizzes',release.DOCKERFILE); self.assertNotIn('ENTRYPOINT',release.DOCKERFILE); self.assertIn('test "$ready" = 1',script); self.assertIn("'private':private",script)
 def test_resume_prepare_requires_exact_existing_image_and_keeps_all_later_gates(self):
  digest='09cc9e1df1e5d430952d1b25e57de10824877d89f1eeaac7b2cd0626e292bdee'
  with self.assertRaisesRegex(release.GuardError,'existing image digest'): release.remote_script(self.build,'b'*64,'resume-prepare')
  with self.assertRaisesRegex(release.GuardError,'existing image digest'): release.remote_script(self.build,'b'*64,'resume-prepare','not-a-digest')
  with self.assertRaisesRegex(release.GuardError,'release input manifest hash'): release.remote_script(self.build,'b'*64,'resume-prepare',digest)
  with self.assertRaisesRegex(release.GuardError,'only valid with resume-prepare'): release.remote_script(self.build,'b'*64,'prepare',input_manifest_sha256='c'*64)
  script=release.remote_script(self.build,'b'*64,'resume-prepare',digest,'c'*64)
  self.assertNotIn('docker build',script); self.assertNotIn('test ! -e "$backup"',script)
  for needle in ('sha256:'+digest,'input_manifest_sha256='+'c'*64,'release input checksum mismatch','test ! -e "$stage/prepared-receipt.json"','base.api','new.api','candidate image/source lock differs','restore-proof.sqlite','--require-real-http-grading','canonical-cri.json','rendered-baseline.yaml','helm lint --strict','kubectl apply --dry-run=server','f_bavail * 5 >= s.f_blocks'):
   self.assertIn(needle,script)
  self.assertIn("sha256sum \"$stage/new.api\"",script); self.assertIn('b'*64,script)
  for path in ('resume-base-quizzes','resume-candidate-quizzes','resume-restore-proof.sqlite','resume-rehearsal-data','resume-quiz-source-closure.json'):
   self.assertIn('test ! -e "$stage/'+path+'"',script); self.assertIn('$stage/'+path,script)
  self.assertNotIn('$stage/base-quizzes',script); self.assertNotIn('$stage/candidate-quizzes',script); self.assertNotIn('$stage/rehearsal-data',script)
 def test_resume_prepare_executes_only_the_digest_pinned_remote_guard(self):
  inputs=release.collect_inputs(self.root); identity=self.root/'release-key'; identity.write_text('key')
  digest='09cc9e1df1e5d430952d1b25e57de10824877d89f1eeaac7b2cd0626e292bdee'
  with patch.object(release,'stage_package') as stage, patch.object(release.subprocess,'run') as run:
   release.execute(release.HOST,identity,self.build,inputs,'resume-prepare',existing_image_digest=digest)
  stage.assert_not_called(); self.assertEqual(run.call_count,1)
  command=run.call_args.args[0]; script=run.call_args.kwargs['input'].decode()
  self.assertEqual(command[-2:],['bash','-s']); self.assertNotIn('docker build',script)
  self.assertIn(inputs.manifest['target_api_sha256'],script)
  self.assertIn(hashlib.sha256(json.dumps(inputs.manifest,sort_keys=True,indent=2).encode()+b'\n').hexdigest(),script)
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
 def test_prepare_functionally_preserves_four_baseline_only_files(self):
  source=self.root/'clean'; baseline=self.root/'baseline'; destination=self.root/'package'; commit='a'*40
  for directory in (source/'quizzes',source/'study/drafts',source/'next/apps/quiz_app/build/web',source/'next/apps/quiz_app/assets',source/'deploy/helm/quiz-master',source/'docs/rewrite-agents/tasks/FEEDBACK43_MINIMUM20_20261019',baseline): directory.mkdir(parents=True,exist_ok=True)
  (source/'next/apps/quiz_app/build/web/main.dart.js').write_bytes((f'quiz-2026.10.19-minimum20-{commit[:8]} https://quiz.kotopedia.org').encode())
  (source/'deploy/helm/quiz-master/Chart.yaml').write_text('name: quiz-master\n')
  for i in range(133):
   name=f'old-{i}.json'; (baseline/name).write_text('{"base":true}'); (source/'quizzes'/name).write_text('{"base":true}')
  for name in prepare.EXPECTED_MUTATED:
   path=baseline/name; path.parent.mkdir(parents=True,exist_ok=True); path.write_text('{"base":true}'); target=source/'quizzes'/name; target.parent.mkdir(parents=True,exist_ok=True); target.write_text('{"candidate":true}')
  for i in range(17):
   path=source/'quizzes'/f'Collections/new-{i}.json'; path.parent.mkdir(parents=True,exist_ok=True); path.write_text('{"new":true}')
  for name in prepare.BASELINE_ONLY:
   path=baseline/name; path.parent.mkdir(parents=True,exist_ok=True); path.write_text('# legacy\n')
  for name in prepare.SUPPORT: (source/'docs/rewrite-agents/tasks/FEEDBACK43_MINIMUM20_20261019'/name).write_text('{}')
  for name in release.PRIVATE_DRAFTS: (source/'study/drafts'/name).write_text('{}')
  rows=[{'quiz_id':f'catalog-{i}','questions_count':2440 if i==0 else 20,'difficulty_counts':{'easy':2440 if i==0 else 20,'medium':0,'hard':0,'nightmare':0,'unknown':0}} for i in range(105)]
  (source/'next/apps/quiz_app/assets/catalog.json').write_text(json.dumps(rows))
  api=self.root/'candidate-api'; api.write_bytes(b'\x7fELFnew-api')
  deployment={'hostname':'racknerd-f0269d5','revision':'69','deployment_revision':'67','pvc_uid':'7fc2428f-4146-4c78-a26d-2347d9f3b7bf','containers':[{'image':release.BASE_IMAGE}]}
  version={'buildId':'quiz-2026.10.19-bones-36e0b68c','api_sha256':prepare.BASE_API,'quizipedia_sections':13,'study_modules':6,'study_questions':120,'taxonomy_id':'tags.v1'}
  preflight=self.root/'preflight.txt'; preflight.write_text(json.dumps(deployment)+json.dumps(version))
  args=['prepare_package.py','--source',str(source),'--destination',str(destination),'--api',str(api),'--api-source-commit',commit,'--baseline-quizzes',str(baseline),'--preflight',str(preflight),'--quizipedia-facts','13588']
  with patch.object(prepare,'git',side_effect=[commit,'']), patch.object(prepare,'require_api_provenance'), patch.object(sys,'argv',args): prepare.main()
  closure=json.loads((destination/'quiz-closure.json').read_text())
  self.assertEqual(len(closure['candidate']),165); self.assertEqual(set(closure['baseline_only']) if 'baseline_only' in closure else set(prepare.BASELINE_ONLY),set(prepare.BASELINE_ONLY))
  self.assertFalse(set(prepare.BASELINE_ONLY)&set(closure['unchanged_source_lf_normalized']))
  self.assertEqual((destination/'web/version.json').read_text() and json.loads((destination/'web/version.json').read_text())['quizipedia_sections'],13)
if __name__=='__main__': unittest.main()
