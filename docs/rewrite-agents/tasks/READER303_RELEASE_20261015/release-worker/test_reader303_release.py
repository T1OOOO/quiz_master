import copy, json, re, subprocess, tempfile, unittest, tarfile, textwrap
from pathlib import Path
import prepare_reader303_release as r
import verify_reader303_candidate as candidate
from unittest.mock import patch
from functools import lru_cache

REPO=Path(__file__).parents[5]
ARCHIVE=r.BASELINE_ARCHIVE

@lru_cache(maxsize=None)
def archived(relative):
    with tarfile.open(ARCHIVE,'r:gz') as package:
        return package.extractfile(f'{r.BASELINE_BUILD}/{relative}').read()

def offline_house():
    helper=r.house()
    documents=list(json.loads(archived('runtime-bundles.json')).values())
    documents.extend(json.loads(path.read_bytes()) for path in sorted((REPO/'study/question_articles/snapshots').glob('*.json')))
    helper.frozen_revision_map=lambda *args: helper.revision_map_from_documents(documents)
    return helper

def readers():
    prior=json.loads(archived(r.READER_SOURCE))
    current=json.loads((REPO/r.READER_SOURCE).read_bytes())
    browser=json.loads((r.BROWSER_DOCS/'browser-proof-v2.json').read_bytes())
    return prior,current,browser

class ReaderReleaseTests(unittest.TestCase):
    def test_actual_build_trees_and_evidence_hash_binding(self):
        directory=Path(__file__).parents[1]
        trees=r.read(directory.parents[0]/'READER303_BUILD_20261015/frozen-web-trees.json')
        self.assertEqual(trees['frozen_source'],r.FROZEN_COMMIT)
        self.assertEqual(trees['build_id'],r.BUILD_ID)
        for label in ('production','qa'):
            record=trees['trees'][label]
            r.verify_web_tree(record,label,record['root'])
        with tempfile.TemporaryDirectory() as d:
            proof=Path(d)/'proof.json';proof.write_text('{}')
            pins={'proof':{'path':str(proof),'sha256':r.digest(proof)}}
            self.assertEqual(r.bound_json(pins,'proof'),{})
            proof.write_text('{"altered":true}')
            with self.assertRaisesRegex(RuntimeError,'hash'):r.bound_json(pins,'proof')

    def test_genuine_source_callbacks_reject_self_review_and_wrong_task(self):
        sources={'source_review':'MUSICALS_FOUR_INTEGRATION_20261015/independent-integration-review.json','reader_review':'MUSICALS_FOUR_20261015/independent-fact-review.json'}
        for key,path in sources.items():
            proof=r.read(Path(__file__).parents[2]/path)
            r.verify_acceptance(proof,key,r.house(),r.SOURCE_REVIEW_TASKS[key])
            with self.assertRaisesRegex(RuntimeError,'acceptance'):r.verify_acceptance(proof,key,r.house(),'task-wrong')
            bad=copy.deepcopy(proof)
            response=next(iter(bad['actual_reviews'].values()))['actual_response'];response['reviewer']=response['assignee']
            with self.assertRaisesRegex(RuntimeError,'acceptance'):r.verify_acceptance(bad,key,r.house(),r.SOURCE_REVIEW_TASKS[key])

    def test_successful_v2_builds_reject_failed_outputs_and_hash_drift(self):
        receipt=r.BUILD_DOCS/'actual-flutter-builds-v2.json'
        pins={'build_receipt':{'path':str(receipt),'sha256':r.digest(receipt)},
              'production_web':str(r.WEB_ROOT/'production-web-v2'),'qa_web':str(r.WEB_ROOT/'qa-web-v2')}
        self.assertEqual(set(r.verify_builds(pins)),{'production','qa'})
        wrong=copy.deepcopy(pins);wrong['production_web']=str(r.WEB_ROOT/'production-web')
        with self.assertRaisesRegex(RuntimeError,'v2 output'):r.verify_builds(wrong)
        wrong=copy.deepcopy(pins);wrong['build_receipt']['path']=str(r.BUILD_DOCS/'actual-flutter-builds.json')
        with self.assertRaisesRegex(RuntimeError,'v2 build receipt'):r.verify_builds(wrong)
        for field,value in [('actual_exit',1),('compiled_reader_articles',299),('raw_log_sha256','0'*64),('files',{})]:
            document=r.read(receipt);document['checks'][0][field]=value
            with self.subTest(field=field),patch.object(r,'bound_json',return_value=document),self.assertRaises(RuntimeError):
                r.verify_builds(pins)
        proof=r.read(r.BUILD_DOCS/'independent-build-review.json')
        r.verify_acceptance(proof,'v2 builds',r.house(),r.BUILD_REVIEW_TASK)

    def test_superseding_browser_review_rejects_real_invalidated_acceptance(self):
        self.assertEqual(r.BROWSER_REVIEW_TASK,'task-3d369f3627744d41ba358a9f4ddc5fec')
        old=r.read(r.BROWSER_DOCS/'independent-original-review-INVALIDATED.json')
        with self.assertRaisesRegex(RuntimeError,'acceptance'):
            r.verify_acceptance(old,'corrected browser',r.house(),r.BROWSER_REVIEW_TASK)

    def test_old_cleanup_and_missing_precision_guards_are_rejected(self):
        current=r.read(r.BROWSER_DOCS/'browser-proof-v2.json')
        r.verify_browser_cleanup(current)
        old=r.read(r.BROWSER_DOCS/'browser-proof.json')
        with self.assertRaisesRegex(RuntimeError,'corrected|precision|quiescence'):r.verify_browser_cleanup(old)
        for field in ('original_cleanup_audit_invalidated','corrected_full_precision_identity_audit'):
            bad=copy.deepcopy(current);bad['browser_cleanup'].pop(field)
            with self.subTest(field=field),self.assertRaises(RuntimeError):r.verify_browser_cleanup(bad)
        for field in ('fresh_cim_microseconds_and_native_100ns_calibrated','exact_native_creation_ticks_rechecked_before_stop','original_millisecond_timestamp_and_full_command_validated'):
            bad=copy.deepcopy(current);bad['browser_cleanup']['exact_daemon_cleanup'][field]=False
            with self.subTest(field=field),self.assertRaises(RuntimeError):r.verify_browser_cleanup(bad)
        bad=copy.deepcopy(current);bad['browser_cleanup']['captured_identity_audit']['rows'][0]['captured_pid']=99999
        with self.assertRaises(RuntimeError):r.verify_browser_cleanup(bad)

    def test_corrected_identity_receipts_reject_missing_mismatched_or_truncated_data(self):
        proof=r.read(r.BROWSER_DOCS/'browser-proof-v2.json');real_read=r.read
        for file,field,value in [('calibrated-daemon-identity-v2.json','NativeCreationTicks','639276745263134600'),
                                 ('calibrated-daemon-identity-v2.json','CimCreationTicks','639276745263130000'),
                                 ('calibrated-daemon-identity-v2.json','command_sha256','0'*64),
                                 ('calibrated-daemon-identity-v2.json','ProcessId',99999),
                                 ('calibrated-daemon-identity-v2.json','CreationDate','2026-10-15T15:22:06.3130000Z'),
                                 ('corrected-daemon-cleanup-v2.json','captured_daemon_pid',99999),
                                 ('cleanup-v2.json','captured_identities',15)]:
            def read(path):
                data=real_read(path)
                if Path(path).name==file:data[field]=value
                return data
            with self.subTest(file=file,field=field),patch.object(r,'read',side_effect=read),self.assertRaises(RuntimeError):
                r.verify_browser_cleanup(proof)
        def missing(path):
            if Path(path).name=='calibrated-daemon-identity-v2.json':raise FileNotFoundError('unit missing calibration')
            return real_read(path)
        with patch.object(r,'read',side_effect=missing),self.assertRaises(FileNotFoundError):r.verify_browser_cleanup(proof)

    def test_paired_ticks_still_require_precision_calibration_and_original_milliseconds(self):
        real_read=r.read
        for offset_cim,offset_native in ((0,2),(0,-9),(10000,10000)):
            proof=real_read(r.BROWSER_DOCS/'browser-proof-v2.json')
            calibration=real_read(r.BROWSER_DOCS/'calibrated-daemon-identity-v2.json')
            calibration['CimCreationTicks']=str(int(calibration['CimCreationTicks'])+offset_cim)
            calibration['NativeCreationTicks']=str(int(calibration['NativeCreationTicks'])+offset_native)
            daemon=proof['browser_cleanup']['exact_daemon_cleanup']
            daemon['cim_creation_ticks']=calibration['CimCreationTicks'];daemon['native_creation_ticks']=calibration['NativeCreationTicks']
            def read(path):
                if Path(path).name=='calibrated-daemon-identity-v2.json':return calibration
                if Path(path).name=='corrected-daemon-cleanup-v2.json':return daemon
                return real_read(path)
            with self.subTest(cim=offset_cim,native=offset_native),patch.object(r,'read',side_effect=read),self.assertRaisesRegex(RuntimeError,'precision|millisecond'):
                r.verify_browser_cleanup(proof)

    def test_corrected_cleanup_receipt_pins_reject_missing_extra_or_changed_files(self):
        hashes={str((r.BROWSER_DOCS/name).resolve()):r.digest(r.BROWSER_DOCS/name) for name in r.BROWSER_CLEANUP_FILES}
        r.verify_cleanup_receipt_pins({'browser_cleanup_sha256':hashes})
        for mutation in ('missing','extra','wrong_hash'):
            bad=copy.deepcopy(hashes)
            if mutation=='missing':bad.pop(next(iter(bad)))
            if mutation=='extra':bad[str((r.BROWSER_DOCS/'cleanup.json').resolve())]='0'*64
            if mutation=='wrong_hash':bad[next(iter(bad))]='0'*64
            with self.subTest(mutation=mutation),self.assertRaisesRegex(RuntimeError,'receipt pins'):
                r.verify_cleanup_receipt_pins({'browser_cleanup_sha256':bad})
        with self.assertRaises(KeyError):r.verify_cleanup_receipt_pins({})

    def test_missing_pins_fail_before_any_output(self):
        output=REPO/'.run/reader303-missing-pins-negative-must-not-exist'
        self.assertFalse(output.exists())
        with self.assertRaises(KeyError):r.prepare({},ARCHIVE,output)
        self.assertFalse(output.exists())

    def test_archive_hash_member_and_existing_output_guards(self):
        helper=r.house();helper.BASELINE_BUILD=r.BASELINE_BUILD;helper.BASELINE_ARCHIVE_SHA256=r.BASELINE_ARCHIVE_SHA256
        helper.verify_safe_archive(ARCHIVE)
        with tempfile.TemporaryDirectory() as d:
            root=Path(d)
            with self.assertRaisesRegex(RuntimeError,'already exist'):helper.require_new_output_root(root)
            bad=root/'bad.tar.gz';bad.write_bytes(b'changed archive')
            with self.assertRaisesRegex(RuntimeError,'SHA-256'):helper.verify_safe_archive(bad)
        for name in (r.BUILD_ID+'/../escape',r.BUILD_ID+'/api'):
            member=tarfile.TarInfo(name)
            if name.endswith('/api'):member.type=tarfile.SYMTYPE
            with self.assertRaises(RuntimeError):helper.validate_archive_members([member],r.BUILD_ID)

    def test_api_and_raw_pack_cannot_change_under_preservation_allowlist(self):
        with tempfile.TemporaryDirectory() as d:
            stage=Path(d)
            for name in ('api','nginx.conf'):(stage/name).write_bytes(archived(name))
            raw=stage/'quizzes/raw.json';raw.parent.mkdir();raw.write_text('unchanged raw fixture')
            before={p.relative_to(stage).as_posix():r.digest(p) for p in stage.rglob('*') if p.is_file()}
            r.verify_preserved(before,stage)
            raw.write_text('changed')
            with self.assertRaisesRegex(RuntimeError,'nonweb'):r.verify_preserved(before,stage)
            raw.write_text('unchanged raw fixture');(stage/'api').write_bytes(b'wrong API')
            with self.assertRaisesRegex(RuntimeError,'nonweb|API'):r.verify_preserved(before,stage)

    def test_nested_browser_identity_and_ui_proof_negatives(self):
        prior,current,proof=readers()
        for field,value in [('captured_browser_identities_inactive',False),('raw_pid_absence_claimed',True),('captured_identities',0)]:
            bad=copy.deepcopy(proof);bad['browser_cleanup']['captured_identity_audit'][field]=value
            with self.assertRaisesRegex(RuntimeError,'quiescence'):r.verify_browser_cleanup(bad)
        for field,value in [('footer_image_sha256','0'*64),('dialog_and_source_controls_confirmed',False)]:
            bad=copy.deepcopy(proof);bad['articles'][0][field]=value
            with self.assertRaisesRegex(RuntimeError,'evidence|controls'):r.verify_reader_delta(prior,current,bad,offline_house())
        bad=copy.deepcopy(proof);bad['public_dto_equivalence']['questions']=20
        with self.assertRaisesRegex(RuntimeError,'four-question'):r.verify_reader_delta(prior,current,bad,offline_house())
    def test_candidate_wrapper_uses_successor_runtime_contract(self):
        with patch.object(candidate, 'load_house') as house:
            candidate.verify_reader_bindings({}, {})
            house.return_value.verify_reader_bindings.assert_called_once_with({}, {}, expected_articles=303, expected_total_refs=184, expected_playable_refs=182)
            candidate.verify_receipt({}, 'fixture-image')
            house.return_value.verify_runtime_receipt.assert_called_once_with({}, 'fixture-image', expected_packs=136, expected_questions=4084, expected_articles=303, expected_total_refs=184, expected_playable_refs=182)
        with patch.object(candidate.sys, 'argv', ['verifier', '--image', 'fixture-image']), patch.object(candidate.runpy, 'run_path'):
            candidate.main()
            self.assertEqual(candidate.sys.argv[-6:], ['--expected-reader-articles', '303', '--expected-reader-total-refs', '184', '--expected-reader-playable-refs', '182'])

    def test_browser_revision_and_source_count_cannot_be_invented(self):
        prior,current,browser=readers()
        for key,value in [('revision_sha256','0'*64),('source_links_count',999)]:
            bad=copy.deepcopy(browser);bad['articles'][0][key]=value
            with self.assertRaisesRegex(RuntimeError,'browser Reader303|fresh browser Reader303'):
                r.verify_reader_delta(prior,current,bad,offline_house())

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
        self.assertEqual(r.verify_reader_delta(prior,current,browser,offline_house())['total_refs'],184)
        changed=copy.deepcopy(current); changed['articles'][0]['title']='drift'
        with self.assertRaisesRegex(RuntimeError,'prior 299'): r.verify_reader_delta(prior,changed,browser,offline_house())
        bad=copy.deepcopy(current)
        added=next(x for x in bad['articles'] if x['id']=='question:music-oct3-001')
        added['question_refs'][0]['revision_sha256']='0'*64
        with self.assertRaisesRegex(RuntimeError,'Actor.*reference|Actor.*binding|Reader.*reference|prior 299'): r.verify_reader_delta(prior,bad,browser,offline_house())

    def test_actual_browser_proof_derives_score_from_exact_deliberate_wrongs(self):
        prior,current,browser=readers()
        self.assertEqual(browser['actual_visible_score'], '0/4')
        self.assertEqual(set(browser['intentional_wrong_question_ids']), {aid.split(':',1)[1] for aid in r.ARTICLE_IDS})
        r.verify_reader_delta(prior,current,browser,offline_house())
        bad=copy.deepcopy(browser); bad['actual_visible_score']='1/4'
        with self.assertRaisesRegex(RuntimeError,'fresh browser Reader303'):
            r.verify_reader_delta(prior,current,bad,offline_house())

    def test_complete_tree_rejects_extra_file(self):
        with tempfile.TemporaryDirectory() as d:
            root=Path(d); (root/'x').write_text('x'); record={'root':str(root),'file_sha256':r.file_tree(root),'file_count':1}
            r.verify_web_tree(record,'production',root)
            (root/'extra').write_text('x')
            with self.assertRaisesRegex(RuntimeError,'differs'): r.verify_web_tree(record,'production',root)

    def test_duplicate_wrong_quiz_and_duplicate_browser_proof_fail(self):
        prior,current,browser=readers()
        duplicate=copy.deepcopy(current); duplicate['articles'].append(copy.deepcopy(duplicate['articles'][-1]))
        with self.assertRaisesRegex(RuntimeError,'additions'): r.verify_reader_delta(prior,duplicate,browser,offline_house())
        wrong=copy.deepcopy(current)
        row=next(x for x in wrong['articles'] if x['id']=='question:music-oct3-001')
        row['question_refs'][0]['quiz_id']='other-quiz'
        with self.assertRaisesRegex(RuntimeError,'Actor.*reference|Actor.*binding|Reader.*reference|prior 299'): r.verify_reader_delta(prior,wrong,browser,offline_house())
        bad=copy.deepcopy(browser); bad['articles'].append(copy.deepcopy(bad['articles'][0]))
        with self.assertRaisesRegex(RuntimeError,'browser Reader303'): r.verify_reader_delta(prior,current,bad,offline_house())

    def test_failed_browser_close_requires_exact_owned_quiescence(self):
        _,_,proof=readers()
        self.assertIs(proof['browser_cleanup']['native_processes_inactive'], True)
        r.verify_browser_cleanup(proof)
        # Synthetic failed-close fixture; the actual runtime proof records its own close result.
        failed_close=copy.deepcopy(proof); failed_close['browser_close_actual_exit']=1
        r.verify_browser_cleanup(failed_close)
        old_field_only=copy.deepcopy(failed_close)
        old_field_only['browser_cleanup'].pop('native_processes_inactive',None)
        old_field_only['browser_cleanup']['native_processes_absent']=True
        with self.assertRaisesRegex(RuntimeError,'quiescence'):
            r.verify_browser_cleanup(old_field_only)
        for field,value in [('native_processes_inactive',False),('foreign_processes_changed',True),('session','foreign'),('captured_identities',0)]:
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
            shell='C:/Program Files/Git/bin/bash.exe'
            syntax=subprocess.run([shell,'-n'],input=cutover.encode(),capture_output=True)
            self.assertEqual(syntax.returncode,0,syntax.stderr.decode())
            # Publish/unknown modes fail before hostname, locks, DB or network calls.
            for mode in ('publish','unexpected'):
                refused=subprocess.run([shell,'-s','--',mode],input=cutover.encode(),capture_output=True)
                self.assertEqual(refused.returncode,1,refused.stderr.decode())
                self.assertEqual(refused.stdout,b'')
            gate=re.search(r"python3 - \"\$quiz_build\" <<'PY'\n(.*?)\nPY",cutover,re.S).group(1)
            command=['python','-c',gate,r.BUILD_ID]
            good=subprocess.run(command,cwd=stage,capture_output=True,text=True)
            self.assertEqual(good.returncode,0,good.stderr)
            meta=json.loads((stage/'web/version.json').read_text()); self.assertEqual(meta['question_articles'],303)
            meta['question_articles']=299; (stage/'web/version.json').write_text(json.dumps(meta))
            self.assertNotEqual(subprocess.run(command,cwd=stage,capture_output=True).returncode,0)
            self.assertIn(r.BASELINE_IMAGE,cutover); self.assertNotIn(r.BASELINE_CUTOVER_IMAGE,cutover)
            self.assertIn('/opt/quiz-master/releases/'+r.BASELINE_BUILD,body); self.assertIn(old_checks,body); self.assertNotIn('26e1657fd6259',body)
            self.assertIn('--expected-reader-articles 303 --expected-reader-total-refs 184 --expected-reader-playable-refs 182',cutover)
            self.assertEqual(cutover.count('quiz_preflight() {'),1)
            self.assertEqual(cutover.count('\nquiz_preflight\n'),3)
            self.assertNotIn("meta['question_articles'])==(136,4084,299)",cutover)
            clause=textwrap.dedent(body.split("elif qid=='pub-connections-20261014':",1)[1].split('  else:',1)[0])
            bundle=json.loads(archived('runtime-bundles.json'))['pub-connections-20261014']
            articles=json.loads((REPO/r.READER_SOURCE).read_bytes())['articles']
            matches=[ref for article in articles for ref in article['question_refs'] if ref['quiz_id']=='pub-connections-20261014']
            context={'bundle':bundle,'matches':matches,'expected_questions':bundle['quiz']['questions'],'live':{'quiz':bundle['quiz']}}
            exec(clause,context)
            bad=copy.deepcopy(context); bad['matches'][0]['revision_sha256']='0'*64
            with self.assertRaises(AssertionError):exec(clause,bad)

    def test_actual_rehearsal_static_musical_count_and_revision_binding(self):
        prior=json.loads(archived(r.READER_SOURCE))['articles']
        current=json.loads((REPO/r.READER_SOURCE).read_bytes())['articles']
        snapshot=json.loads((REPO/'study/question_articles/snapshots/prep-musicals.json').read_bytes())
        questions={q['question_id']:q['revision']['sha256'] for q in snapshot['quiz']['questions']}
        def bindings(body):
            lines=body.splitlines();start=next(i for i,line in enumerate(lines) if line.lstrip().startswith('assert len(refs)=='))
            return textwrap.dedent('\n'.join(lines[start:start+2]))
        old=archived('rehearse.py').decode();old_gate=bindings(old)
        def refs(articles):return [ref for a in articles for ref in a['question_refs'] if ref['quiz_id']=='prep-musicals']
        self.assertEqual(len(refs(prior)),1);self.assertEqual(len(refs(current)),5)
        exec(old_gate,{'qid':'prep-musicals','refs':refs(prior),'questions':questions})
        with self.assertRaises(AssertionError):exec(old_gate,{'qid':'prep-musicals','refs':refs(current),'questions':questions})
        with tempfile.TemporaryDirectory() as directory:
            stage=Path(directory);(stage/'api').touch();(stage/'web').mkdir();(stage/'web/main.dart.js').write_bytes(b'fixture JS')
            for name in ('cutover.sh','rehearse.py','checksums.txt'):(stage/name).write_bytes(archived(name))
            helper=r.house();helper.BUILD_ID=r.BUILD_ID;helper.TARGET_SOURCE=r.FROZEN_COMMIT;helper.TARGET_API_SHA256=r.API_SHA256
            r.install_runtime_verifier(stage,helper,r.digest(stage/'web/main.dart.js'))
            body=(stage/'rehearse.py').read_text();gate=bindings(body)
            self.assertNotIn("'prep-musicals':1",body);self.assertEqual(body.count("'prep-musicals':5"),1)
            self.assertIn("'lotr':3,'prep-ballet':1,'prep-musicals':5,'theme-harry-potter':10,'theme-terminator':10",body)
            self.assertIn('assert graded==335 and finished==15',body)
            expected=old.replace('/opt/quiz-master/releases/quiz-2026.10.15-reader291-3482af9','/opt/quiz-master/releases/'+r.BASELINE_BUILD).replace('b347996fd9486a860f518efc1d6ebdc8a657dd24f5dee00b53218b65a58f3fc9',r.digest(stage/'checksums.txt')).replace("'prep-musicals':1","'prep-musicals':5")
            self.assertEqual(body,expected,'rehearsal changed beyond rollback pins and exact musical count')
            exec(gate,{'qid':'prep-musicals','refs':refs(current),'questions':questions})
            bad=copy.deepcopy(refs(current));bad[0]['revision_sha256']='0'*64
            with self.assertRaises(AssertionError):exec(gate,{'qid':'prep-musicals','refs':bad,'questions':questions})
            with self.assertRaises(AssertionError):exec(gate,{'qid':'prep-musicals','refs':refs(current)[:-1],'questions':questions})

    def test_rehearsal_count_anchor_missing_or_duplicated_is_refused(self):
        original=archived('rehearse.py').decode()
        anchor="{'lotr':3,'prep-ballet':1,'prep-musicals':1,'theme-harry-potter':10,'theme-terminator':10}"
        for body in (original.replace(anchor,anchor.replace("'prep-musicals':1","'prep-musicals':2")),original+'\n# '+anchor):
            with tempfile.TemporaryDirectory() as directory:
                stage=Path(directory);(stage/'api').touch();(stage/'web').mkdir();(stage/'web/main.dart.js').write_bytes(b'fixture JS')
                for name in ('cutover.sh','checksums.txt'):(stage/name).write_bytes(archived(name))
                (stage/'rehearse.py').write_bytes(body.encode())
                helper=r.house();helper.BUILD_ID=r.BUILD_ID;helper.TARGET_SOURCE=r.FROZEN_COMMIT;helper.TARGET_API_SHA256=r.API_SHA256
                with self.assertRaisesRegex(RuntimeError,'static article-count contract'):
                    r.install_runtime_verifier(stage,helper,r.digest(stage/'web/main.dart.js'))

    def test_prior_reader_is_bound_to_extracted_bytes(self):
        with tempfile.TemporaryDirectory() as d:
            stage=Path(d)/'stage'; target=stage/r.READER_SOURCE; target.parent.mkdir(parents=True); target.write_bytes(archived(r.READER_SOURCE))
            prior=Path(d)/'prior.json'; prior.write_bytes(target.read_bytes()); r.verify_prior_reader(stage,prior)
            prior.write_text('{}')
            with self.assertRaisesRegex(RuntimeError,'extracted Reader299'): r.verify_prior_reader(stage,prior)

if __name__=='__main__': unittest.main()
