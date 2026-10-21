import hashlib
import importlib.util
import tempfile
import unittest
from pathlib import Path
from unittest import mock


def _packager():
    path = Path(__file__).with_name('prepare_package.py')
    spec = importlib.util.spec_from_file_location('phone_followup_packager', path)
    assert spec and spec.loader
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class PhoneFollowupPackageGuardsTest(unittest.TestCase):
    def _source_with_canonical_drafts(self, module):
        directory = tempfile.TemporaryDirectory()
        source = Path(directory.name)
        expected = {
            relative: hashlib.sha256(relative.encode('utf-8')).hexdigest()
            for relative in module.CANONICAL_CONTENT_EXCEPTION
        }
        for relative in expected:
            path = source / relative
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(relative.encode('utf-8'))
        return directory, source, expected

    def test_only_exact_reviewed_canonical_paths_and_hashes_are_allowed(self):
        module = _packager()
        directory, source, expected = self._source_with_canonical_drafts(module)
        with directory:
            evidence = module.validate_canonical_content_exception(
                source,
                set(expected),
                expected,
            )
            self.assertTrue(evidence['nonruntime'])
            self.assertEqual(evidence['paths'], expected)

    def test_canonical_hash_mutation_and_unapproved_fourth_path_fail_closed(self):
        module = _packager()
        directory, source, expected = self._source_with_canonical_drafts(module)
        with directory:
            one = next(iter(expected))
            (source / one).write_bytes(b'mutated')
            with self.assertRaises(module.release.GuardError):
                module.validate_canonical_content_exception(
                    source, set(expected), expected
                )

            (source / one).write_bytes(one.encode('utf-8'))
            with self.assertRaises(module.release.GuardError):
                module.validate_canonical_content_exception(
                    source,
                    {*expected, 'next/content/unreviewed.json'},
                    expected,
                )

    def test_api_or_legacy_or_server_quiz_delta_cannot_be_hidden_by_exception(self):
        module = _packager()
        with self.assertRaises(module.release.GuardError):
            module.validate_runtime_deltas(
                {'next/server/main.go'}, set(module.CANONICAL_CONTENT_EXCEPTION)
            )
        with self.assertRaises(module.release.GuardError):
            module.validate_runtime_deltas(
                {'quizzes/legacy.json'}, set(module.CANONICAL_CONTENT_EXCEPTION)
            )
        with self.assertRaises(module.release.GuardError):
            module.validate_runtime_deltas(
                set(), {'next/content/prep-capitals-1/legacy.json'}
            )

    def test_source_freeze_checks_clean_status_before_accepting_exact_exception(self):
        module = _packager()
        expected = set(module.CANONICAL_CONTENT_EXCEPTION)
        with mock.patch('subprocess.check_output', return_value=''), mock.patch.object(
            module,
            'changed_paths',
            side_effect=[set(), set(expected)],
        ), mock.patch.object(
            module,
            'validate_canonical_content_exception',
            return_value={'nonruntime': True},
        ) as canonical:
            self.assertEqual(module.validate_source_freeze(Path('/frozen')), {'nonruntime': True})
            canonical.assert_called_once_with(Path('/frozen'), expected)

        with mock.patch('subprocess.check_output', return_value=' M next/server/main.go\n'):
            with self.assertRaises(module.release.GuardError):
                module.validate_source_freeze(Path('/dirty'))


if __name__ == '__main__':
    unittest.main()
