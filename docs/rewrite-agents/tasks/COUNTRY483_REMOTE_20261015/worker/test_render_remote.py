"""Offline renderer and receipt tests; all Docker/SSH strings remain inert."""
import copy
import json
from pathlib import Path
import re
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch
import render_remote as r


class RemotePreview(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.pins,cls.local,cls.package=r.validate_inputs()
        cls.bodies=r.render_bodies(cls.pins,cls.local,cls.package)

    def test_real_package_and_accepted_proofs_reverified(self):
        self.assertEqual(self.package['archive_sha256'],r.ARCHIVE_SHA)
        self.assertEqual(self.pins['actual_candidate_image'],None)

    def test_current63_strict_guards_and_prepare_only(self):
        for body in self.bodies.values():
            self.assertIn(self.local.IMAGE,body)
            self.assertIn(self.local.PVC,body)
            self.assertIn("helm['version']==63",body)
            self.assertIn('usage.f_bavail*usage.f_frsize*5>usage.f_blocks*usage.f_frsize',body)
            self.assertIn(self.local.FEEDBACK,body)
            self.assertNotIn(r.ALIAS,body)
            self.assertNotIn('helm upgrade',body)
            self.assertNotIn('kubectl apply -n',body)
            self.assertNotIn('\r',body)
        self.assertIn('bash cutover.sh prepare',self.bodies['prepare.sh'])
        self.assertIn('flock -n 8',self.bodies['prepare.sh'])
        collector=self.bodies['collection-INERT-EXAMPLE.sh']
        self.assertIn('(14,280,55,335,15)',collector)
        self.assertIn('old_api_rollback',collector)
        self.assertIn('original_rows_preserved',collector)
        self.assertIn('expected_articles=303,expected_total_refs=184,expected_playable_refs=182',collector)

    def test_all_shell_and_embedded_python_syntax(self):
        blocks=0
        for name,body in self.bodies.items():
            result=subprocess.run(['C:/Program Files/Git/bin/bash.exe','-n'],input=body.encode(),stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
            self.assertEqual(result.returncode,0,result.stdout.decode())
            for match in re.finditer(r"python3 - <<'([A-Z_0-9]+)'\n(.*?)\n\1(?:\n|$)",body,re.S):
                compile(match[2],name+'-'+match[1],'exec');blocks+=1
        self.assertGreaterEqual(blocks,7)

    def test_safe_stateless_immutable_image_command(self):
        command=r.candidate_command(r.EXAMPLE[1])
        for flag in ('--rm','--network=none','--read-only','--cap-drop=ALL','--security-opt=no-new-privileges','--user=10001:10001'):
            self.assertIn(flag,command)
        self.assertEqual(command[-2:],list(r.ATLAS))
        self.assertFalse(any('mount' in token or token in ('-v','--volume') for token in command))
        with self.assertRaises(RuntimeError):r.candidate_command('quiz-master:mutable')

    def atlas_receipt(self):
        return dict(schema_version='qm-country483-candidate-atlas/v1',status='VERIFIED_CANDIDATE_ATLAS_NOT_PUBLISHED',
                    build_id=r.BUILD,source_commit=r.SOURCE,package_sha256=r.ARCHIVE_SHA,package_checksums_sha256=r.CHECKSUMS_SHA,
                    run=r.EXAMPLE[0],image=r.EXAMPLE[1],candidate_runtime_sha256='a'*64,atlas_sha256=r.ATLAS.copy(),actual_exit=0,
                    stateless=True,production_db_mounted=False)

    def test_atlas_binding_rejects_all_mismatches(self):
        receipt=self.atlas_receipt();r.verify_atlas_receipt(receipt,*r.EXAMPLE[:2],'a'*64)
        for key,value in [('image','sha256:'+'b'*64),('package_sha256','0'*64),('package_checksums_sha256','0'*64),
                          ('candidate_runtime_sha256','b'*64),('run',r.EXAMPLE[0].replace('2099','2098')),
                          ('production_db_mounted',True),('actual_exit',False)]:
            changed=copy.deepcopy(receipt);changed[key]=value
            with self.subTest(key=key),self.assertRaises(RuntimeError):r.verify_atlas_receipt(changed,*r.EXAMPLE[:2],'a'*64)
        changed=copy.deepcopy(receipt);changed['atlas_sha256'][next(iter(r.ATLAS))]='0'*64
        with self.assertRaises(RuntimeError):r.verify_atlas_receipt(changed,*r.EXAMPLE[:2],'a'*64)

    def test_embedded_validator_is_same_code_and_rejects_atlas_mutation(self):
        namespace={};exec(compile(r.atlas_library(),'atlas-library','exec'),namespace)
        good=self.atlas_receipt();namespace['verify_atlas_receipt'](good,*r.EXAMPLE[:2],'a'*64)
        bad=copy.deepcopy(good);bad['atlas_sha256']={}
        with self.assertRaises(RuntimeError):namespace['verify_atlas_receipt'](bad,*r.EXAMPLE[:2],'a'*64)

    def test_candidate_check_runs_before_receipt_and_collector_binds_it(self):
        prepare=self.bodies['prepare.sh'];collector=self.bodies['collection-INERT-EXAMPLE.sh']
        self.assertLess(prepare.index('bash cutover.sh prepare'),prepare.index("path=root/(run+'-candidate-atlas.json')"))
        self.assertIn("observed==ATLAS",prepare)
        self.assertIn("with path.open('x'",prepare)
        self.assertIn('candidate_runtime_sha256=runtime_sha',prepare)
        self.assertIn("verify_atlas_receipt(atlas,run,",collector)
        self.assertIn("'candidate_atlas_sha256':h(atlas_path)",collector)
        self.assertIn("'package_sha256':ARCHIVE_SHA",collector)

    def test_bad_nonce_package_run_image_durable_refused(self):
        for nonce in ('../evil','x'*32,'0'*31,None):
            with self.subTest(nonce=nonce),self.assertRaises(RuntimeError):r.remote_scripts(self.pins,self.local,self.package,nonce)
        bad=dict(self.package,archive_sha256='0'*64)
        with self.assertRaises(RuntimeError):r.remote_scripts(self.pins,self.local,bad,self.pins['nonce'])
        bad=dict(self.package,build_id=r.ALIAS)
        with self.assertRaises(RuntimeError):r.remote_scripts(self.pins,self.local,bad,self.pins['nonce'])
        for args in ((r.BUILD+'-cutover-20261340T999999Z',r.EXAMPLE[1],r.EXAMPLE[2]),
                     ('../run',r.EXAMPLE[1],r.EXAMPLE[2]),(r.EXAMPLE[0],'sha256:bad',r.EXAMPLE[2]),
                     (r.EXAMPLE[0],r.EXAMPLE[1],'$(unsafe)')):
            with self.subTest(args=args),self.assertRaises((RuntimeError,ValueError)):r.collection_script(self.pins,self.local,*args)

    def test_stale_baseline_or_proof_source_pins_refused(self):
        stale=copy.deepcopy(self.pins);stale['baseline']['helm_revision']=62
        with self.assertRaises(RuntimeError):r.remote_scripts(stale,self.local,self.package,self.pins['nonce'])
        with patch.object(r,'INPUTS_SHA','0'*64),self.assertRaises(RuntimeError):r.validate_inputs()
        bad=copy.deepcopy(self.pins);bad['local_proofs']['worker/prepare_country483.py']['sha256']='0'*64
        with self.assertRaises(RuntimeError):r.local_producer(bad)

    def test_anchor_contract_changes_refused(self):
        for text in ('absent','x x'):
            with self.assertRaises(RuntimeError):r.replace(text,'x','y')

    def test_preview_default_is_local_and_tamper_refused(self):
        with tempfile.TemporaryDirectory(dir=r.WORK) as tmp:
            output=Path(tmp)/'preview';record=r.render(output)
            self.assertIs(record['actual_candidate_image'],None)
            self.assertTrue(record['collection_example_only'])
            self.assertFalse(record['remote_execution_performed'])
            self.assertFalse(record['execution_authorized'])
            self.assertEqual(record['upload_destination'].rsplit('.upload-',1)[1],self.pins['nonce'])
            r.verify_preview(output/'preview.json')
            original=(output/'prepare.sh').read_bytes()
            try:
                (output/'prepare.sh').write_bytes(original+b'\n#unreviewed\n')
                with self.assertRaises(RuntimeError):r.verify_preview(output/'preview.json')
            finally:(output/'prepare.sh').write_bytes(original)
            original=(output/'preview.json').read_bytes()
            try:
                changed=json.loads(original);changed['nonce']='0'*32;(output/'preview.json').write_text(json.dumps(changed))
                with self.assertRaises(RuntimeError):r.verify_preview(output/'preview.json')
            finally:(output/'preview.json').write_bytes(original)
            r.verify_preview(output/'preview.json')
            with self.assertRaises(RuntimeError):r.render(output)

    def test_cli_rejects_execute_publish_and_optimized_python(self):
        for flags in (['--execute'],['--publish'],['--prepare']):
            result=subprocess.run([sys.executable,'-B',str(r.OWN/'render_remote.py'),*flags],stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
            self.assertNotEqual(result.returncode,0)
        result=subprocess.run([sys.executable,'-B','-O',str(r.OWN/'render_remote.py'),'--output-root',str(r.WORK/'never-optimized')],stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
        self.assertNotEqual(result.returncode,0);self.assertIn(b'optimized Python',result.stdout)
        self.assertFalse((r.WORK/'never-optimized').exists())


if __name__=='__main__':unittest.main(verbosity=2)
