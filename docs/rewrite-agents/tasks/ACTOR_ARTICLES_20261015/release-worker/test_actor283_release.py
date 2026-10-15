import copy, json, re, subprocess, tempfile, unittest, tarfile, textwrap
from pathlib import Path
import prepare_actor283_release as r
import verify_actor283_candidate as candidate
from unittest.mock import patch

REPO=Path(__file__).parents[5]
ARCHIVE=REPO/'.run/reader_public_release_20261015/package-v1/quiz-2026.10.15-reader-06dfa0b.tar.gz'

def archived(relative):
    with tarfile.open(ARCHIVE,'r:gz') as package:
        return package.extractfile(f'{r.BASELINE_BUILD}/{relative}').read()

def readers():
    prior=json.loads(archived(r.READER_SOURCE))
    current=json.loads((REPO/r.READER_SOURCE).read_bytes())
    browser=json.loads((REPO/'docs/rewrite-agents/tasks/ACTOR_ARTICLES_20261015/local-browser/browser-proof.json').read_bytes())
    return prior,current,browser

class ReaderReleaseTests(unittest.TestCase):
    def test_candidate_wrapper_uses_successor_runtime_contract(self):
        with patch.object(candidate, 'load_house') as house:
            candidate.verify_reader_bindings({}, {})
            house.return_value.verify_reader_bindings.assert_called_once_with({}, {}, expected_articles=283, expected_total_refs=164, expected_playable_refs=162)
            candidate.verify_receipt({}, 'fixture-image')
            house.return_value.verify_runtime_receipt.assert_called_once_with({}, 'fixture-image', expected_packs=136, expected_questions=4084, expected_articles=283, expected_total_refs=164, expected_playable_refs=162)
        with patch.object(candidate.sys, 'argv', ['verifier', '--image', 'fixture-image']), patch.object(candidate.runpy, 'run_path'):
            candidate.main()
            self.assertEqual(candidate.sys.argv[-6:], ['--expected-reader-articles', '283', '--expected-reader-total-refs', '164', '--expected-reader-playable-refs', '162'])

    def test_browser_revision_and_source_count_cannot_be_invented(self):
        prior,current,browser=readers()
        for key,value in [('revision_sha256','0'*64),('source_links_count',999)]:
            bad=copy.deepcopy(browser);bad['articles'][0][key]=value
            with self.assertRaisesRegex(RuntimeError,'browser Actor'):
                r.verify_reader_delta(prior,current,bad,r.house())

    def test_staging_revisions_bind_current_root_and_reject_prior_map(self):
        with tempfile.TemporaryDirectory() as d:
            stage=Path(d)
            for name in ['runtime-bundles.json','expected-staging-revisions.json']:
                (stage/name).write_bytes(archived(name))
            helper=r.house()
            with self.assertRaisesRegex(RuntimeError,'staging revisions'):
                r.verify_staging_revisions(stage,helper)
            r.install_staging_revisions(stage,helper)
            r.verify_staging_revisions(stage,helper)
            actual=r.read(stage/'expected-staging-revisions.json')
            self.assertNotEqual(actual,json.loads(archived('expected-staging-revisions.json')))
            bundle=r.read(stage/'runtime-bundles.json')['pub-connections-20261014']
            public=bundle['quiz']['questions'][0]
            private=helper.private_revision_input(bundle,public)
            private['source']['uri']=private['source']['uri'].replace('/app/quizzes/',f'/opt/quiz-master/releases/{r.BUILD_ID}/quizzes/',1)
            self.assertEqual(actual[bundle['quiz']['quiz_id']][public['question_id']]['sha256'],helper.canonical(private))

    def test_real_reader_delta_uses_real_house_revision_and_noncatalog_contract(self):
        prior,current,browser=readers()
        self.assertEqual(r.verify_reader_delta(prior,current,browser,r.house())['total_refs'],164)
        changed=copy.deepcopy(current); changed['articles'][0]['title']='drift'
        with self.assertRaisesRegex(RuntimeError,'prior 279'): r.verify_reader_delta(prior,changed,browser,r.house())
        bad=copy.deepcopy(current)
        added=next(x for x in bad['articles'] if x['id']=='question:cinema-oct3-001')
        added['question_refs'][0]['revision_sha256']='0'*64
        with self.assertRaisesRegex(RuntimeError,'Actor.*reference|Actor.*binding|Reader.*reference'): r.verify_reader_delta(prior,bad,browser,r.house())

    def test_complete_tree_rejects_extra_file(self):
        with tempfile.TemporaryDirectory() as d:
            root=Path(d); (root/'x').write_text('x'); record={'root':str(root),'file_sha256':r.file_tree(root),'file_count':1}
            r.verify_web_tree(record,'production',root)
            (root/'extra').write_text('x')
            with self.assertRaisesRegex(RuntimeError,'differs'): r.verify_web_tree(record,'production',root)

    def test_duplicate_wrong_quiz_and_duplicate_browser_proof_fail(self):
        prior,current,browser=readers()
        duplicate=copy.deepcopy(current); duplicate['articles'].append(copy.deepcopy(duplicate['articles'][-1]))
        with self.assertRaisesRegex(RuntimeError,'additions'): r.verify_reader_delta(prior,duplicate,browser,r.house())
        wrong=copy.deepcopy(current)
        row=next(x for x in wrong['articles'] if x['id']=='question:cinema-oct3-001')
        row['question_refs'][0]['quiz_id']='other-quiz'
        with self.assertRaisesRegex(RuntimeError,'Actor.*reference|Actor.*binding|Reader.*reference'): r.verify_reader_delta(prior,wrong,browser,r.house())
        bad=copy.deepcopy(browser); bad['articles'].append(copy.deepcopy(bad['articles'][0]))
        with self.assertRaisesRegex(RuntimeError,'browser Actor'): r.verify_reader_delta(prior,current,bad,r.house())

    def test_failed_browser_close_requires_exact_owned_quiescence(self):
        proof=json.loads((REPO/'docs/rewrite-agents/tasks/ACTOR_ARTICLES_20261015/local-browser/browser-proof.json').read_bytes())
        r.verify_browser_cleanup(proof)
        # Synthetic failed-close fixture; the actual runtime proof records its own close result.
        failed_close=copy.deepcopy(proof); failed_close['browser_close_actual_exit']=1
        r.verify_browser_cleanup(failed_close)
        for field,value in [('native_processes_absent',False),('foreign_processes_changed',True),('session','foreign'),('checked_owned_pids',[])]:
            bad=copy.deepcopy(failed_close); bad['browser_cleanup'][field]=value
            with self.assertRaisesRegex(RuntimeError,'quiescence'): r.verify_browser_cleanup(bad)

    def test_review_dependency_paths_are_real_and_cover_executable_modules(self):
        paths=r.controller_sources()
        self.assertEqual(len(paths),10)
        self.assertTrue(all(path.is_file() for path in paths))
        self.assertIn(Path(r.__file__).resolve(),{p.resolve() for p in paths})

    def test_actual_archived_cutover_gate_executes_with_real_successor_metadata(self):
        with tempfile.TemporaryDirectory() as d:
            stage=Path(d); (stage/'api').write_text('fixture'); (stage/'web').mkdir(); (stage/'web/main.dart.js').write_text('fixture-js')
            for rel in ['cutover.sh','rehearse.py','checksums.txt']:(stage/rel).write_bytes(archived(rel))
            old_checks=r.digest(stage/'checksums.txt'); h=r.house(); h.BUILD_ID=r.BUILD_ID; h.TARGET_SOURCE=r.FROZEN_COMMIT; h.TARGET_API_SHA256=r.API_SHA256
            r.install_runtime_verifier(stage,h,r.digest(stage/'web/main.dart.js'))
            self.assertNotIn(b'\r\n',(stage/'cutover.sh').read_bytes(),'Linux shell script must use LF')
            cutover=(stage/'cutover.sh').read_text(); body=(stage/'rehearse.py').read_text()
            gate=re.search(r"python3 - \"\$quiz_build\" <<'PY'\n(.*?)\nPY",cutover,re.S).group(1)
            command=['python','-c',gate,r.BUILD_ID]
            good=subprocess.run(command,cwd=stage,capture_output=True,text=True)
            self.assertEqual(good.returncode,0,good.stderr)
            meta=json.loads((stage/'web/version.json').read_text()); self.assertEqual(meta['question_articles'],283)
            meta['question_articles']=279; (stage/'web/version.json').write_text(json.dumps(meta))
            self.assertNotEqual(subprocess.run(command,cwd=stage,capture_output=True).returncode,0)
            self.assertIn(r.BASELINE_IMAGE,cutover); self.assertNotIn(r.BASELINE_CUTOVER_IMAGE,cutover)
            self.assertIn('/opt/quiz-master/releases/'+r.BASELINE_BUILD,body); self.assertIn(old_checks,body); self.assertNotIn('26e1657fd6259',body)
            self.assertIn('--expected-reader-articles 283 --expected-reader-total-refs 164 --expected-reader-playable-refs 162',cutover)
            self.assertEqual(cutover.count('quiz_preflight() {'),1)
            self.assertEqual(cutover.count('\nquiz_preflight\n'),3)
            self.assertNotIn("meta['question_articles'])==(136,4084,279)",cutover)
            clause=textwrap.dedent(body.split("elif qid=='pub-connections-20261014':",1)[1].split('  else:',1)[0])
            bundle=json.loads(archived('runtime-bundles.json'))['pub-connections-20261014']
            articles=json.loads((REPO/r.READER_SOURCE).read_bytes())['articles']
            matches=[ref for article in articles for ref in article['question_refs'] if ref['quiz_id']=='pub-connections-20261014']
            context={'bundle':bundle,'matches':matches,'expected_questions':bundle['quiz']['questions'],'live':{'quiz':bundle['quiz']}}
            exec(clause,context)
            bad=copy.deepcopy(context); bad['matches'][0]['revision_sha256']='0'*64
            with self.assertRaises(AssertionError):exec(clause,bad)

    def test_prior_reader_is_bound_to_extracted_bytes(self):
        with tempfile.TemporaryDirectory() as d:
            stage=Path(d)/'stage'; target=stage/r.READER_SOURCE; target.parent.mkdir(parents=True); target.write_bytes(archived(r.READER_SOURCE))
            prior=Path(d)/'prior.json'; prior.write_bytes(target.read_bytes()); r.verify_prior_reader(stage,prior)
            prior.write_text('{}')
            with self.assertRaisesRegex(RuntimeError,'extracted actual59'): r.verify_prior_reader(stage,prior)

if __name__=='__main__': unittest.main()
