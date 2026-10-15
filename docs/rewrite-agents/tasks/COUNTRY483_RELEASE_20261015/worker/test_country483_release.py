"""Bounded offline checks using the real immutable Reader303 controls and assets."""
import copy
import json
import subprocess
import sys
import tarfile
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch
import prepare_country483 as c


class Country483(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.helper = c.house()
        cls.helper.verify_safe_archive(c.BASE_ARCHIVE)
        with tarfile.open(c.BASE_ARCHIVE, 'r:gz') as tar:
            def payload(name): return tar.extractfile(c.BASE_BUILD + '/' + name).read()
            cls.cutover = payload('cutover.sh').decode()
            cls.rehearsal = payload('rehearse.py').decode()
            cls.atlas = json.loads(payload('web/' + c.ATLAS))
        cls.current = c.read(c.REPO / 'next/apps/quiz_app/assets/quizipedia/catalog.json')
        cls.prod_js = c.sha(c.REPO / '.run/country483_runtime_20261015/production-web/main.dart.js')

    def test_real_accepted_inputs_and_all_compiled_hashes(self):
        self.assertEqual(c.verify_inputs()['counts'], c.COUNTS)

    def test_current63_guard_preserves_every_other_preflight_byte(self):
        old = c.load_dependency('READER303_RELEASE_20261015/release-worker/reader303_guard.py').preflight_shell()
        actual = c.preflight_shell()
        self.assertEqual(actual, old.replace("helm['version']==62", "helm['version']==63").replace(c.OLD_IMAGE, c.IMAGE))
        self.assertIn('usage.f_bavail*usage.f_frsize*5>usage.f_blocks*usage.f_frsize', actual)

    def test_real_controls_remain_prepare_only_and_335_15(self):
        cutover, rehearsal = c.patch_controls(self.cutover, self.rehearsal, self.prod_js)
        self.assertNotIn(b'helm upgrade', cutover)
        self.assertNotIn(c.OLD_IMAGE.encode(), cutover)
        self.assertNotIn(c.OLD_JS.encode(), cutover)
        self.assertIn(b'[[ "$quiz_mode" = prepare ]]', cutover)
        self.assertIn(b"'prep-musicals':5", rehearsal)
        self.assertIn(c.BASE_CHECKS.encode(), rehearsal)
        self.assertIn(b'assert graded==335 and finished==15', rehearsal)
        compile(rehearsal, 'copied-rehearsal', 'exec')

    def test_guarded_replacement_refuses_anchor_drift(self):
        for cutover, rehearsal in ((self.cutover.replace(c.OLD_JS, 'f'*64, 1), self.rehearsal),
                                   (self.cutover + 'helm upgrade\n', self.rehearsal),
                                   (self.cutover, self.rehearsal.replace('assert graded==335', 'assert graded==334'))):
            with self.subTest(), self.assertRaises((RuntimeError, SystemExit)):
                c.patch_controls(cutover, rehearsal, self.prod_js)

    def test_exact_eleven_labels_only(self):
        c.verify_label_delta(self.atlas, self.current)

    def test_country_and_other_section_mutations_rejected(self):
        mutations = []
        for field, value in [('name_en', 'Changed'), ('id', 'ne-bogus'), ('name_ru', 'Changed')]:
            changed = copy.deepcopy(self.current); changed['countries'][0][field] = value; mutations.append(changed)
        changed = copy.deepcopy(self.current); changed['countries'].reverse(); mutations.append(changed)
        changed = copy.deepcopy(self.current); changed['countries'].append(changed['countries'][0]); mutations.append(changed)
        changed = copy.deepcopy(self.current); changed['unexpected'] = True; mutations.append(changed)
        for changed in mutations:
            with self.subTest(), self.assertRaises(RuntimeError): c.verify_label_delta(self.atlas, changed)

    def test_unaccepted_or_other_task_review_refused(self):
        proof = c.read(c.RUNTIME / 'independent-runtime-review.json')
        c.verify_acceptance(proof, 'task-96da0af0c5ef4d3da1b5a09e30a0cd8c', self.helper)
        with self.assertRaises(RuntimeError): c.verify_acceptance(proof, 'task-wrong', self.helper)
        proof['actual_cli_exit'] = 1
        with self.assertRaises((RuntimeError, SystemExit)): c.verify_acceptance(proof, 'task-96da0af0c5ef4d3da1b5a09e30a0cd8c', self.helper)

    def test_proof_or_dependency_hash_drift_refused(self):
        with patch.object(c, 'INPUTS_SHA', '0'*64), self.assertRaises(RuntimeError): c.verify_inputs()
        with patch.dict(c.DEPENDENCIES, {'READER303_RELEASE_20261015/release-worker/reader303_guard.py':'0'*64}), self.assertRaises(RuntimeError): c.preflight_shell()

    def test_baseline62_wrong_image_or_capacity_boundary_refused(self):
        actual = [json.loads(line) for line in (c.INPUTS.parent / 'production-baseline.jsonl').read_text().splitlines()]
        c.verify_baseline(actual)
        for field, value in [('helm_revision', 62), ('images', [c.OLD_IMAGE]*2), ('pvc_uid', 'other'), ('feedback_sha256', '0'*64)]:
            changed = copy.deepcopy(actual); changed[1][field] = value
            with self.subTest(field=field), self.assertRaises(RuntimeError): c.verify_baseline(changed)
        changed = copy.deepcopy(actual); changed[0].update(disk_available=20, disk_total=100)
        with self.assertRaises(RuntimeError): c.verify_baseline(changed)
        changed[0]['disk_available'] = 21; c.verify_baseline(changed)

    def test_wrong_prior_archive_and_traversal_refused(self):
        with tempfile.TemporaryDirectory(dir=c.WORK) as tmp:
            wrong = Path(tmp) / 'wrong.tar.gz'; wrong.write_bytes(b'bad')
            with self.assertRaises((RuntimeError, SystemExit)): self.helper.verify_safe_archive(wrong)
        member = tarfile.TarInfo(c.BASE_BUILD + '/../escape'); member.size = 1
        with self.assertRaises((RuntimeError, SystemExit)): self.helper.validate_archive_members([member], c.BASE_BUILD)

    def test_existing_or_escaping_output_refused_before_mutation(self):
        with tempfile.TemporaryDirectory(dir=c.WORK) as tmp:
            with self.assertRaises((RuntimeError, SystemExit)): c.validate_output(Path(tmp))
        with self.assertRaises(RuntimeError): c.validate_output(c.REPO / '.run/foreign-output')

    def test_unrelated_schema_binary_or_reader_change_refused(self):
        with tempfile.TemporaryDirectory(dir=c.WORK) as tmp:
            root = Path(tmp); (root/'api').write_bytes(b'original'); before = c.file_tree(root)
            (root/'api').write_bytes(b'mutated')
            with self.assertRaises(RuntimeError): c.verify_preserved(before, root)

    def test_optimized_python_refused(self):
        command = [sys.executable, '-B', '-O', str(c.OWN/'prepare_country483.py'), '--output-root', str(c.WORK/'never-optimized-output')]
        result = subprocess.run(command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn(b'optimized Python', result.stdout)
        self.assertFalse((c.WORK/'never-optimized-output').exists())


if __name__ == '__main__':
    unittest.main(verbosity=2)
