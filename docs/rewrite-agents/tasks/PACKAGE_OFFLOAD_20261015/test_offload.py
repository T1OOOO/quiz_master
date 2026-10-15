from pathlib import Path
import hashlib, os, tempfile, unittest
from unittest.mock import patch
from offload import remove_verified
import execute
import json


class OffloadTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name).resolve()

    def tearDown(self):
        self.temp.cleanup()

    def entry(self, name='quiz-2026.10.12-culture-f219916.tar.gz'):
        path = self.root / name
        path.write_bytes(b'fixture archive bytes')
        st = path.stat()
        return {'path': '/opt/quiz-master/releases/' + name,
                'size': st.st_size, 'sha256': hashlib.sha256(path.read_bytes()).hexdigest(),
                'dev': st.st_dev, 'ino': st.st_ino, 'mtime_ns': st.st_mtime_ns}

    def test_only_exact_files_removed(self):
        a = self.entry()
        keep = self.root / 'unrelated'
        keep.write_bytes(b'keep')
        result = remove_verified([a], self.root)
        self.assertEqual(result, [a['path']])
        self.assertEqual(keep.read_bytes(), b'keep')

    def test_invalid_last_file_preserves_whole_batch(self):
        a = self.entry()
        b = self.entry('quiz-2026.10.13-culture-e437661.tar.gz')
        (self.root / Path(b['path']).name).write_bytes(b'changed')
        with self.assertRaises(AssertionError):
            remove_verified([a, b], self.root)
        self.assertTrue((self.root / Path(a['path']).name).exists())

    def test_rejects_traversal(self):
        a = self.entry()
        a['path'] = '/opt/quiz-master/releases/../' + Path(a['path']).name
        with self.assertRaises(AssertionError):
            remove_verified([a], self.root)

    def test_rejects_protected_package(self):
        a = self.entry('quiz-2026.10.14-library-09b19cc.tar.gz')
        with self.assertRaises(AssertionError):
            remove_verified([a], self.root)

    def test_rejects_symlink_before_open(self):
        a = self.entry()
        with patch.object(Path, 'is_symlink', return_value=True):
            with self.assertRaises(AssertionError):
                remove_verified([a], self.root)

    def test_rejects_metadata_change(self):
        a = self.entry()
        a['ino'] += 1
        with self.assertRaises(AssertionError):
            remove_verified([a], self.root)

    def test_rejects_duplicate_path(self):
        a = self.entry()
        with self.assertRaises(AssertionError):
            remove_verified([a, a], self.root)
        self.assertTrue((self.root / Path(a['path']).name).exists())

    def test_executor_rejects_unaccepted_review_before_ssh(self):
        (self.root / 'approval-inputs.json').write_text('{}')
        (self.root / 'source-review.json').write_text(json.dumps({
            'actual_cli_exit': 0, 'actual_hub_state': 'REWORK'}))
        with patch.object(execute, 'DOCS', self.root), patch.object(execute.subprocess, 'run') as ssh:
            with self.assertRaises(AssertionError):
                execute.main()
            ssh.assert_not_called()

    def test_executor_rejects_unbound_manifest_before_ssh(self):
        (self.root / 'approval-inputs.json').write_text('{}')
        item = {'call': {'arguments': {'verdict': 'accept', 'note': 'approval for other bytes'}},
                'actual_response': {'state': 'ACCEPTED', 'reviewer': 'different', 'assignee': 'author'}}
        (self.root / 'source-review.json').write_text(json.dumps({
            'actual_cli_exit': 0, 'actual_hub_state': 'ACCEPTED',
            'actual_reviews': {'task-f23e797ad2fd45938696186c1ea09354': item}}))
        with patch.object(execute, 'DOCS', self.root), patch.object(execute.subprocess, 'run') as ssh:
            with self.assertRaises(AssertionError):
                execute.main()
            ssh.assert_not_called()


if __name__ == '__main__':
    unittest.main()
