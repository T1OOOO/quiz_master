"""Synthetic, disposable controller tests; never create a real NVN package."""
from pathlib import Path
import copy
import datetime as dt
import json
import os
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch


WORKER = Path(__file__).resolve().parent
REPO = WORKER.parents[4]
SCRATCH = REPO / '.run/heartbeat_20261018_0327/worker'


class ProducerTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        import prepare_canonical as c
        cls.c = c
        cls.history = c.load_history()

    def setUp(self):
        SCRATCH.mkdir(parents=True, exist_ok=True)
        self.temp = tempfile.TemporaryDirectory(dir=SCRATCH, prefix='synthetic-')
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.root_patch = patch.object(self.c, 'ROOT', self.root)
        self.root_patch.start()
        self.addCleanup(self.root_patch.stop)
        self.h, _, _, self.contract, self.provenance = self.history
        self.n, self.base, _, _ = self.h.adapted()
        self.history_patch = patch.object(self.c, 'load_history', return_value=(self.h, self.n, self.base, self.contract, self.provenance))
        self.history_patch.start()
        self.addCleanup(self.history_patch.stop)
        self.bindings = {'sources': self.c.sources(), 'contract': self.c.CONTRACT_SHA}
        self.output = self.root / 'synthetic-output'
        self.now = dt.datetime.now(dt.timezone.utc)
        self.rows = [json.loads(line) for line in (self.h.EVIDENCE / 'production-baseline.jsonl').read_text().splitlines()]
        self.rows[0].update(disk_available=201, disk_total=1000, target_host='racknerd-f0269d5', memory_pressure=False, pid_pressure=False)
        self.rows[1].update(feedback_count=43, feedback_sha256=self.contract['feedback_sha256'])
        self.save(self.root / 'source-acceptance.json', self.proof(self.contract['source_task'], self.bindings))
        self.capture()

        def synthetic_output(path):
            path.mkdir()
            (path / 'SYNTHETIC_ONLY.txt').write_text('Not an NVN package or genuine acceptance.')
            return {'synthetic_delegation_only': True}

        self.writer_patch = patch.object(self.base, 'prepare', side_effect=synthetic_output)
        self.writer_patch.start()
        self.addCleanup(self.writer_patch.stop)

    def save(self, path, value):
        path.write_text(json.dumps(value, indent=2) + '\n', encoding='utf-8')

    def proof(self, task, bindings):
        return dict(fixture_only='SYNTHETIC_TEST_ONLY', actual_cli_exit=0, actual_hub_state='ACCEPTED',
                    reviewer_provider='claude', bound_raw_sha256=bindings, actual_reviews={task: dict(
                        call=dict(action='review', arguments=dict(task_id=task, verdict='accept', error_count=0)),
                        actual_response=dict(id=task, state='ACCEPTED', reviewer='synthetic-claude', assignee='synthetic-codex'))})

    def capture(self):
        stamp = self.now.isoformat()
        for row in self.rows:
            row['observed_at_utc'] = stamp
        stdout = self.root / 'current-baseline.jsonl'
        stdout.write_text(''.join(json.dumps(row) + '\n' for row in self.rows), encoding='utf-8')
        collector = WORKER / 'current-baseline-readonly.sh'
        receipt = self.root / 'current-baseline-exit.json'
        self.save(receipt, dict(fixture_only='SYNTHETIC_TEST_ONLY', actual_exit=0, read_only=True,
                               script_raw_sha256=self.c.sha(collector), stdout_raw_sha256=self.c.sha(stdout), observed_at_utc=stamp))
        files = {'collector': collector, 'stdout': stdout, 'receipt': receipt}
        manifest = dict(schema_version=self.contract['current_manifest_schema'], source_commit=self.n.SOURCE,
                        build_id=self.n.BUILD, historical_inputs_raw_sha256=self.h.INPUT_SHA,
                        **{key: dict(path=str(path), raw_byte_sha256=self.c.sha(path)) for key, path in files.items()})
        self.save(self.root / 'current-inputs.json', manifest)
        self.digests = {key: self.c.sha(path) for key, path in files.items()}
        certificate = dict(schema_version='qm-nvn-canonical-current-certificate/v1', release_baseline_certificate=True,
                           fixture_only='SYNTHETIC_TEST_ONLY', actual_exit=0, read_only=True, observed_at_utc=stamp,
                           manifest_raw_sha256=self.c.sha(self.root / 'current-inputs.json'), bindings_raw_sha256=self.digests)
        self.save(self.root / 'current-certificate.json', certificate)
        current = {**self.bindings, **self.digests, 'manifest': self.c.sha(self.root / 'current-inputs.json'),
                   'certificate': self.c.sha(self.root / 'current-certificate.json')}
        self.save(self.root / 'current-input-acceptance.json', self.proof(self.contract['current_input_task'], current))

    def refused(self):
        with self.assertRaises((ValueError, RuntimeError, FileNotFoundError)):
            self.c.operate('prepare', self.output)
        self.assertFalse(self.output.exists())

    def test_no_output_without_source_acceptance(self):
        SCRATCH.mkdir(parents=True, exist_ok=True)
        with tempfile.TemporaryDirectory(dir=SCRATCH, prefix='synthetic-') as folder:
            output = Path(folder) / 'must-not-exist'
            result = subprocess.run([sys.executable, '-B', str(WORKER / 'prepare_canonical.py'),
                                     '--prepare', str(output)], capture_output=True, text=True, timeout=60)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn('source acceptance', result.stderr)
            self.assertFalse(output.exists())

    def test_missing_or_wrong_source_acceptance_produces_nothing(self):
        path = self.root / 'source-acceptance.json'
        original = self.c.read(path)
        path.unlink()
        self.refused()
        for field in ('source_hash', 'provider', 'exit_bool', 'task'):
            proof = copy.deepcopy(original)
            if field == 'source_hash':
                proof['bound_raw_sha256']['sources']['prepare_canonical.py'] = '0' * 64
            elif field == 'provider':
                proof['reviewer_provider'] = 'codex'
            elif field == 'exit_bool':
                proof['actual_cli_exit'] = False
            else:
                proof['actual_reviews'] = {}
            self.save(path, proof)
            with self.subTest(field=field):
                self.refused()

    def test_missing_certificate_or_current_acceptance_produces_nothing(self):
        for name in ('current-certificate.json', 'current-input-acceptance.json'):
            path = self.root / name
            original = path.read_bytes()
            path.unlink()
            with self.subTest(name=name):
                self.refused()
            path.write_bytes(original)

    def test_bad_current_baseline_and_disk_boundaries_produce_nothing(self):
        original = copy.deepcopy(self.rows)
        for field in ('floor', 'below_floor', 'bool_bytes', 'feedback', 'restore', 'pvc', 'image', 'node'):
            self.rows = copy.deepcopy(original)
            if field == 'floor':
                self.rows[0]['disk_available'] = 200
            elif field == 'below_floor':
                self.rows[0]['disk_available'] = 199
            elif field == 'bool_bytes':
                self.rows[0]['disk_available'] = True
            elif field == 'feedback':
                self.rows[1]['feedback_count'] = 29
            elif field == 'restore':
                self.rows[1]['independent_restore_sha256'] = '0' * 64
            elif field == 'pvc':
                self.rows[1]['pvc_uid'] = 'foreign'
            elif field == 'image':
                self.rows[1]['images'][0] = 'foreign'
            else:
                self.rows[0]['node_ready'] = False
            self.capture()
            with self.subTest(field=field):
                self.refused()

    def test_stale_future_and_non_utc_captures_refused(self):
        for stamp in (self.now - dt.timedelta(seconds=1801), self.now + dt.timedelta(seconds=60),
                      self.now.replace(tzinfo=None), self.now.astimezone(dt.timezone(dt.timedelta(hours=3)))):
            self.now = stamp
            self.capture()
            with self.subTest(stamp=stamp):
                self.refused()

    def test_current_receipt_certificate_and_acceptance_binding_mismatches_refused(self):
        for filename, field, value in (
            ('current-baseline-exit.json', 'actual_exit', False),
            ('current-certificate.json', 'actual_exit', False),
            ('current-certificate.json', 'release_baseline_certificate', False),
            ('current-certificate.json', 'manifest_raw_sha256', '0' * 64),
            ('current-input-acceptance.json', 'bound_raw_sha256', self.bindings),
        ):
            self.capture()
            path = self.root / filename
            record = self.c.read(path)
            record[field] = value
            self.save(path, record)
            with self.subTest(filename=filename, field=field):
                self.refused()

    def test_bool_collector_exit_fails_semantic_guard_after_rebinding(self):
        path = self.root / 'current-baseline-exit.json'
        receipt = self.c.read(path)
        receipt['actual_exit'] = False
        self.save(path, receipt)
        manifest = self.c.read(self.root / 'current-inputs.json')
        manifest['receipt']['raw_byte_sha256'] = self.c.sha(path)
        self.save(self.root / 'current-inputs.json', manifest)
        certificate = self.c.read(self.root / 'current-certificate.json')
        certificate['manifest_raw_sha256'] = self.c.sha(self.root / 'current-inputs.json')
        certificate['bindings_raw_sha256']['receipt'] = self.c.sha(path)
        self.save(self.root / 'current-certificate.json', certificate)
        bindings = {**self.bindings, **certificate['bindings_raw_sha256'],
                    'manifest': self.c.sha(self.root / 'current-inputs.json'),
                    'certificate': self.c.sha(self.root / 'current-certificate.json')}
        self.save(self.root / 'current-input-acceptance.json', self.proof(self.contract['current_input_task'], bindings))
        with self.assertRaisesRegex(ValueError, 'actual read-only collector exit/raw receipt'):
            self.c.operate('prepare', self.output)
        self.assertFalse(self.output.exists())

    def test_capture_age_inclusive_boundary(self):
        for seconds in (0, 1800):
            with self.subTest(seconds=seconds):
                digest = self.c.current_inputs(self.h, self.n, self.base, self.contract, self.bindings,
                                               now=self.now + dt.timedelta(seconds=seconds))
                self.assertEqual(digest, self.c.sha(self.root / 'current-inputs.json'))
        with self.assertRaisesRegex(ValueError, 'stale or future'):
            self.c.current_inputs(self.h, self.n, self.base, self.contract, self.bindings,
                                  now=self.now + dt.timedelta(seconds=1800, microseconds=1))

    def test_positive_synthetic_delegation_is_not_package_verification(self):
        record = self.c.operate('prepare', self.output)
        self.assertEqual(record, {'synthetic_delegation_only': True})
        self.assertEqual(list(path.name for path in self.output.iterdir()), ['SYNTHETIC_ONLY.txt'])
        self.assertEqual(self.base.INPUTS_SHA, self.c.sha(self.root / 'current-inputs.json'))
        self.assertEqual(self.base.OWN, WORKER)
        self.assertEqual(self.base.verify_inputs()['web_roots'], self.c.read(self.h.EVIDENCE / 'release-inputs.json')['web_roots'])

    def test_current_preflight_uses_43_and_preserves_seven_delta(self):
        _, base, _ = self.c.authorize()
        shell = base.preflight_shell()
        self.assertIn('len(rows)==43', shell)
        self.assertIn(self.contract['feedback_sha256'], shell)
        stage = self.n.BASE_ARCHIVE.parent / self.n.BASE_BUILD
        cutover, rehearsal = base.patch_controls((stage / 'cutover.sh').read_text(), (stage / 'rehearse.py').read_text(), self.n.PRODUCTION_JS)
        checked = subprocess.run(['C:/Program Files/Git/bin/bash.exe', '-n'], input=cutover, capture_output=True)
        self.assertEqual(checked.returncode, 0, checked.stderr)
        compile(rehearsal, 'synthetic-retargeted-rehearsal', 'exec')
        before = base.file_tree(stage)
        after = before | {name: 'synthetic-change' for name in self.n.ALLOWED}
        self.assertEqual(set(self.n.verify_delta(before, after, True)), self.n.ALLOWED)
        after['api'] = 'not-allowed'
        with self.assertRaises(ValueError):
            self.n.verify_delta(before, after, True)

    def test_raw_output_receipt_and_archive_paths_refused_before_delegation(self):
        raw = 'C:/ap/quiz_master/' + self.output.relative_to(REPO).as_posix()
        with self.assertRaises(ValueError):
            self.c.output_boundary(raw)
        with self.assertRaises(ValueError):
            self.c.output_boundary(self.root / '..' / 'unowned')
        file = self.root / 'record.json'
        file.write_bytes(b'{}')
        link = self.root / 'linked.json'
        os.link(file, link)
        with self.assertRaises(ValueError):
            self.c.regular(link)

    def test_verify_refuses_junction_stage_root(self):
        stage = self.root / self.n.BUILD
        target = self.root / 'synthetic-stage'
        target.mkdir()
        archive = self.root / (self.n.BUILD + '.tar.gz')
        archive.write_bytes(b'SYNTHETIC_BOUNDARY_PLACEHOLDER_NOT_AN_ARCHIVE')
        receipt = self.root / 'package-preparation.json'
        self.save(receipt, {'archive': str(archive), 'fixture_only': 'SYNTHETIC_TEST_ONLY'})
        result = subprocess.run(['cmd', '/c', 'mklink', '/J', str(stage), str(target)], capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr.decode(errors='replace'))
        try:
            with patch.object(self.base, 'verify_package', return_value={'synthetic_only': True}):
                with self.assertRaisesRegex(ValueError, 'raw canonical'):
                    self.c.operate('verify', receipt)
        finally:
            stage.rmdir()

    def test_verify_branch_uses_source_and_current_gates(self):
        receipt = self.root / 'package-preparation.json'
        for missing in ('source-acceptance.json', 'current-input-acceptance.json'):
            path = self.root / missing
            before = path.read_bytes()
            path.unlink()
            try:
                with self.subTest(missing=missing), self.assertRaisesRegex(ValueError, 'acceptance missing'):
                    self.c.operate('verify', receipt)
            finally:
                path.write_bytes(before)
        self.assertFalse(receipt.exists())

    def test_structural_metadata_and_derived_history_counts(self):
        self.assertEqual(self.provenance, dict(direct_pins=17, runtime_files=103, compiled_files=148, historical_feedback_count=29))
        actual_read = self.c.read
        path = self.h.EVIDENCE / 'runtime-proof.json'
        corrupted = actual_read(path)
        corrupted['browser']['qa']['screenshots'] = []
        with patch.object(self.c, 'read', side_effect=lambda p: corrupted if Path(p) == path else actual_read(p)):
            with self.assertRaisesRegex(ValueError, 'structural drift'):
                self.c.equivalent_metadata(self.h, self.n, self.h.read(self.h.OLD / 'release-inputs.json'))


if __name__ == '__main__':
    unittest.main()
