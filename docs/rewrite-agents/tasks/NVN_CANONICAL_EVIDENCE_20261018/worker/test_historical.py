"""Behavior checks for the non-generating historical evidence verifier."""
from pathlib import Path
import json
import copy
import os
import subprocess
import sys
import tempfile
import unittest


WORKER = Path(__file__).resolve().parent


class HistoricalEvidenceTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        import verify_historical as verifier
        cls.v = verifier
        cls.n, cls.base, cls.original, cls.original_runtime = verifier.adapted()
        cls.proof = verifier.read(verifier.EVIDENCE / 'runtime-proof.json')
        cls.manifest = verifier.read(verifier.EVIDENCE / 'runtime-evidence-inputs.json')

    def test_complete_historical_closure_without_release_acceptance(self):
        result = subprocess.run(
            [sys.executable, '-B', str(WORKER / 'verify_historical.py')],
            capture_output=True, text=True, timeout=60,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        record = json.loads(result.stdout)
        self.assertEqual(record['status'], 'PASS_HISTORICAL_EVIDENCE_ONLY')
        self.assertEqual(record['direct_pins'], 17)
        self.assertEqual(record['runtime_files'], 103)
        self.assertEqual(record['compiled_files'], 148)
        self.assertFalse(record['release_ready'])
        self.assertFalse(record['archive_generated'])

    def test_old_raw_alias_refused_and_canonical_original_accepted(self):
        old, pins, _ = self.v.historical()
        relative, entry = next(iter(pins['proofs'].items()))
        with self.assertRaisesRegex(ValueError, 'path/hash/identity'):
            old.bound(entry, self.v.REPO / relative)
        canonical = dict(entry, path=str(self.v.REPO / relative))
        self.assertEqual(old.bound(canonical, self.v.REPO / relative), self.v.REPO / relative)

    def test_nested_stale_alias_refused(self):
        proof = copy.deepcopy(self.proof)
        proof['browser']['qa']['cleanup']['path'] = 'C:/ap/quiz_master/docs/rewrite-agents/tasks/NVN_RELEASE_20261016/runtime/browser/native-cleanup.json'
        with self.assertRaisesRegex(ValueError, 'canonical evidence path'):
            self.n.verify_runtime(proof, self.base)

    def test_wrong_hash_and_outside_repository_refused(self):
        path = self.v.EVIDENCE / 'runtime/browser/close.json'
        with self.assertRaisesRegex(ValueError, 'path/hash/identity'):
            self.n.bound(dict(path=str(path), sha256='0' * 64), path)
        outside = Path(sys.executable)
        with self.assertRaisesRegex(ValueError, 'path/hash/identity'):
            self.n.bound(dict(path=str(outside), sha256=self.v.sha(outside)), outside)

    def test_junction_and_hardlink_refused(self):
        scratch = self.v.REPO / '.run/heartbeat_20261018_0231/worker'
        with tempfile.TemporaryDirectory(dir=scratch, prefix='guard-') as folder:
            root = Path(folder)
            target = root / 'target'
            target.mkdir()
            file = target / 'record.json'
            file.write_bytes(b'{}')
            junction = root / 'junction'
            result = subprocess.run(['cmd', '/c', 'mklink', '/J', str(junction), str(target)], capture_output=True)
            self.assertEqual(result.returncode, 0, result.stderr.decode(errors='replace'))
            try:
                with self.assertRaisesRegex(ValueError, 'canonical evidence path'):
                    self.n.bound(dict(path=str(junction / file.name), sha256=self.v.sha(file)), file)
            finally:
                junction.rmdir()
            hardlink = root / 'hardlink.json'
            os.link(file, hardlink)
            with self.assertRaisesRegex(ValueError, 'path/hash/identity'):
                self.n.bound(dict(path=str(hardlink), sha256=self.v.sha(hardlink)), hardlink)

    def test_symlink_refused(self):
        scratch = self.v.REPO / '.run/heartbeat_20261018_0231/worker'
        with tempfile.TemporaryDirectory(dir=scratch, prefix='symlink-') as folder:
            target = Path(folder) / 'target.json'
            target.write_bytes(b'{}')
            link = Path(folder) / 'link.json'
            os.symlink(target, link)
            with self.assertRaisesRegex(ValueError, 'canonical evidence path'):
                self.n.bound(dict(path=str(link), sha256=self.v.sha(target)), target)

    def test_lifecycle_member_required_before_read(self):
        for label in ('production', 'qa'):
            folder = self.v.REPO / 'docs/rewrite-agents/tasks/NVN_FOOTER_20261016/release-browser' if label == 'production' else self.v.EVIDENCE / 'runtime/browser'
            names = ('close.json', 'identity-capture.json', 'exact-daemon-cleanup.json') if label == 'production' else ('close.json', 'identity-capture.json')
            for name in names:
                manifest = self.manifest.copy()
                path = folder / name
                manifest.pop(path.relative_to(self.v.REPO).as_posix())
                with self.subTest(label=label, name=name), self.assertRaisesRegex(ValueError, 'lifecycle file missing'):
                    self.v.member_read(self.n, path, manifest)
        path = self.v.EVIDENCE / 'runtime/fixture-cleanup.json'
        manifest = self.manifest.copy()
        manifest.pop(path.relative_to(self.v.REPO).as_posix())
        with self.assertRaisesRegex(ValueError, 'lifecycle file missing'):
            self.v.member_read(self.n, path, manifest)

    def test_extra_missing_and_same_count_replacement_closure_refused(self):
        close = (self.v.EVIDENCE / 'runtime/browser/close.json').relative_to(self.v.REPO).as_posix()
        for mutation in ('missing', 'extra', 'replacement'):
            manifest = self.manifest.copy()
            if mutation in ('missing', 'replacement'):
                manifest.pop(close)
            if mutation in ('extra', 'replacement'):
                manifest['unexpected/close.json'] = '0' * 64
            with self.subTest(mutation=mutation), self.assertRaisesRegex(ValueError, 'exact historical runtime closure'):
                self.v.validate_manifest(manifest, self.original_runtime)

    def test_false_lifecycle_outcomes_refused(self):
        for field in ('close', 'count', 'ports', 'api_exit'):
            proof = copy.deepcopy(self.proof)
            if field == 'close':
                proof['browser']['production']['official_close_actual_exit'] = 0
            elif field == 'count':
                proof['browser']['qa']['captured_identities_inactive'] -= 1
            elif field == 'ports':
                proof['ports_closed']['19093'] = False
            else:
                proof['actual_fixture_api_terminate_exit'] = 0
            with self.subTest(field=field), self.assertRaises(ValueError):
                self.n.verify_runtime(proof, self.base)

    def test_incomplete_or_misclassified_migration_refused(self):
        original = self.v.read(self.v.EVIDENCE / 'migration-map.json')
        for mutation in ('empty', 'missing', 'extra', 'kind'):
            mapping = copy.deepcopy(original)
            if mutation == 'empty':
                mapping['files'] = []
            elif mutation == 'missing':
                mapping['files'].pop()
            elif mutation == 'extra':
                mapping['files'].append(copy.deepcopy(mapping['files'][0]))
            else:
                mapping['files'][0]['kind'] = 'ignored'
            with self.subTest(mutation=mutation), self.assertRaisesRegex(ValueError, 'exact migration'):
                self.v.validate_mapping(mapping, self.original, self.original_runtime)

    def test_migration_refuses_to_overwrite_existing_evidence(self):
        path = self.v.EVIDENCE / 'release-inputs.json'
        before = path.read_bytes()
        result = subprocess.run([sys.executable, '-B', str(WORKER / 'migrate_evidence.py')],
                                capture_output=True, text=True, timeout=60)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('migration destination must not exist', result.stderr)
        self.assertEqual(path.read_bytes(), before)

    def test_cli_refuses_preparation_and_optimized_mode(self):
        for arguments in (['--prepare', 'not-an-output'], ['--verify', 'not-an-archive']):
            result = subprocess.run([sys.executable, '-B', str(WORKER / 'verify_historical.py'), *arguments],
                                    capture_output=True, text=True, timeout=60)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn('preparation is unavailable', result.stderr)
        result = subprocess.run([sys.executable, '-O', '-B', str(WORKER / 'verify_historical.py')],
                                capture_output=True, text=True, timeout=60)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('normal Python required', result.stderr)


if __name__ == '__main__':
    unittest.main()
