"""Focused source-only checks. No archive producer is invoked."""
from pathlib import Path
import copy,importlib.util,json,subprocess,sys,unittest
from unittest.mock import patch,Mock
import prepare_nvn as n

class NVNSourceTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.base=n.implementation();cls.stage=n.BASE_ARCHIVE.parent/n.BASE_BUILD
        cls.before=cls.base.file_tree(cls.stage)
    def test_actual_baseline_count_and_pins(self):
        self.assertEqual(len(self.before),332);self.assertEqual(self.before['checksums.txt'],n.BASE_CHECKS)
        self.assertEqual(n.sha(n.BASE_ARCHIVE),n.BASE_ARCHIVE_SHA)
    def test_actual_control_and_rollback_retarget(self):
        cutover,rehearsal=self.base.patch_controls((self.stage/'cutover.sh').read_text(),(self.stage/'rehearse.py').read_text(),n.PRODUCTION_JS)
        cutover=cutover.decode();rehearsal=rehearsal.decode()
        self.assertIn("helm['version']==64",cutover);self.assertNotIn("helm['version']==63",cutover)
        self.assertIn(n.IMAGE,cutover);self.assertNotIn(n.OLD_IMAGE,cutover)
        self.assertEqual(cutover.count(n.PRODUCTION_JS),3);self.assertIn(n.SOURCE,cutover)
        self.assertIn('/opt/quiz-master/releases/'+n.BASE_BUILD,rehearsal);self.assertIn(n.BASE_CHECKS,rehearsal)
        for marker in ("'prep-musicals':5",'assert graded==335 and finished==15',"assert len(req('/v1/history',token=token))==15"):
            self.assertIn(marker,rehearsal)
        self.assertNotIn('helm upgrade',cutover);self.assertIn('[[ "$quiz_mode" = prepare ]]',cutover)
        self.assertIn('unset PYTHONOPTIMIZE PYTHONSTARTUP',cutover)
        result=subprocess.run(['C:/Program Files/Git/bin/bash.exe','-n'],input=cutover.encode(),capture_output=True)
        self.assertEqual(result.returncode,0,result.stderr.decode());compile(rehearsal,'retargeted-rehearsal','exec')
    def test_inherited_eleven_label_guard_red_then_unchanged_green(self):
        spec=importlib.util.spec_from_file_location('immutable_country483_red',n.LEGACY);old=importlib.util.module_from_spec(spec);spec.loader.exec_module(old)
        atlas=json.loads((self.stage/'web/assets/assets/quizipedia/catalog.json').read_bytes())
        with self.assertRaisesRegex(RuntimeError,'old background fallback differs'):old.verify_label_delta(atlas,atlas)
        self.base.verify_label_delta(atlas,atlas)
        changed=copy.deepcopy(atlas);changed['countries'][0]['name_ru']='unexpected'
        with self.assertRaises(ValueError):self.base.verify_label_delta(atlas,changed)
    def test_exact_seven_delta_and_unchanged_all_other_bytes(self):
        after=self.before.copy();after.update({name:'unit-only-change' for name in n.ALLOWED})
        self.assertEqual(set(n.verify_delta(self.before,after,True)),n.ALLOWED)
        for mutation in ('api','web/assets/assets/quizipedia/catalog.json','web/assets/assets/quizipedia/manifest.json'):
            changed=after.copy();changed[mutation]='wrong'
            with self.subTest(mutation=mutation),self.assertRaises(ValueError):n.verify_delta(self.before,changed,True)
        after['web/version.json']=self.before['web/version.json']
        with self.assertRaises(ValueError):n.verify_delta(self.before,after,True)
    def test_member_removal_refused(self):
        after=self.before.copy();after.pop('api')
        with self.assertRaises(ValueError):n.verify_delta(self.before,after)
    def test_control_anchor_drift_refused(self):
        cutover=(self.stage/'cutover.sh').read_text();rehearsal=(self.stage/'rehearse.py').read_text()
        for text in (cutover.replace(n.OLD_JS,'0'*64),cutover+'\nquiz_preflight() {\n}\n'):
            with self.assertRaises(ValueError):self.base.patch_controls(text,rehearsal,n.PRODUCTION_JS)
        with self.assertRaises(ValueError):self.base.patch_controls(cutover,rehearsal.replace('06d3ff4fca6a5b9265164459c25e4abcdc8e4c2cf753c5d1768595d457de1304','0'*64),n.PRODUCTION_JS)
    def test_no_prepare_without_source_acceptance(self):
        base=Mock()
        with patch.object(sys,'argv',['prepare_nvn.py','--prepare',str(n.WORK/'must-not-exist')]),patch.object(n,'implementation',return_value=base),patch.object(n,'verify_source_acceptance',side_effect=ValueError('no actual source acceptance')):
            with self.assertRaisesRegex(ValueError,'source acceptance'):n.main()
        base.prepare.assert_not_called();base.verify_package.assert_not_called()
    def test_source_map_mismatch_rejected(self):
        base=Mock()
        with patch.object(n,'read',return_value={'controller_source_sha256':{},'release_inputs_sha256':n.INPUTS_SHA}):
            with self.assertRaises(ValueError):n.verify_source_acceptance(base)
        base.verify_acceptance.assert_not_called()
    def test_root_input_digest_drift_rejected(self):
        with patch.object(n,'sha',return_value='0'*64):
            with self.assertRaises(ValueError):n.verify_inputs(self.base)
    def test_actual_frozen_inputs_and_runtime_pass_without_archiving(self):
        with patch.object(self.base,'prepare') as prepare:
            pins=n.verify_inputs(self.base)
        self.assertEqual(pins['build_id'],n.BUILD);self.assertEqual(len(pins['proofs']),17);prepare.assert_not_called()
    def test_baseline_drift_strict_floor_and_restore_refused(self):
        original=[json.loads(line) for line in (n.ROOT/'production-baseline.jsonl').read_text().splitlines() if line.strip()]
        n.verify_baseline(original)
        for field in ('revision','one_image','feedback','restore','node','strict_boundary','pvc','taint'):
            rows=copy.deepcopy(original);node,live=rows
            if field=='revision':live['helm_revision']=63
            if field=='one_image':live['images'][1]=n.OLD_IMAGE
            if field=='feedback':live['feedback_sha256']='0'*64
            if field=='restore':live['independent_restore_sha256']='0'*64
            if field=='node':node['node_ready']=False
            if field=='strict_boundary':node['disk_available']=node['disk_total']//5
            if field=='pvc':live['pvc_uid']='foreign'
            if field=='taint':node['blocking_taints']=True
            with self.subTest(field=field),self.assertRaises(ValueError):n.verify_baseline(rows)
    def test_real_lifecycle_rejects_false_close_count_or_fixture_claim(self):
        original=n.read(n.ROOT/'runtime-proof.json')
        for field in ('production_close','qa_count','qa_close','ports','api_exit'):
            proof=copy.deepcopy(original)
            if field=='production_close':proof['browser']['production']['official_close_actual_exit']=0
            if field=='qa_count':proof['browser']['qa']['captured_identities_inactive']-=1
            if field=='qa_close':proof['browser']['qa']['official_close_actual_exit']=1
            if field=='ports':proof['ports_closed']['19093']=False
            if field=='api_exit':proof['actual_fixture_api_terminate_exit']=0
            with self.subTest(field=field),self.assertRaises(ValueError):n.verify_runtime(proof,self.base)
    def test_missing_proof_source_or_schema_refused(self):
        original=n.read(n.INPUTS)
        for field in ('source','proof','baseline','schema'):
            pins=copy.deepcopy(original)
            if field=='source':pins['source_commit']='0'*40
            if field=='proof':pins['proofs'].pop(next(iter(pins['proofs'])))
            if field=='baseline':pins['baseline']['helm_revision']=63
            if field=='schema':pins['schema_version']='old'
            with self.subTest(field=field),self.assertRaises(ValueError):n.validate_inputs(pins,self.base)
    def test_output_outside_owned_scratch_refused(self):
        with self.assertRaises(RuntimeError):self.base.validate_output(n.REPO/'unowned-output')
    def test_import_has_no_file_or_archive_side_effect(self):
        spec=importlib.util.spec_from_file_location('nvn_import_inert',Path(n.__file__));module=importlib.util.module_from_spec(spec)
        with patch.object(Path,'write_bytes') as write,patch.object(subprocess,'run') as run,patch.object(Path,'read_bytes') as read:
            spec.loader.exec_module(module)
        write.assert_not_called();run.assert_not_called();read.assert_not_called()
    def test_optimized_refusal_before_archive_calls(self):
        result=subprocess.run([sys.executable,'-O','-B',str(Path(n.__file__)),'--verify-inputs'],capture_output=True)
        self.assertNotEqual(result.returncode,0);self.assertIn(b'normal Python',result.stderr)

if __name__=='__main__':unittest.main()
