import hashlib
import importlib.util
import json
import pathlib
import tempfile
import unittest
from unittest import mock

HERE = pathlib.Path(__file__).parent
spec = importlib.util.spec_from_file_location('local_wsl', HERE / 'local_wsl_restore.py')
local_wsl = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(local_wsl)


class LocalWslRestoreTest(unittest.TestCase):
    def load_public_base(self):
        with tempfile.TemporaryDirectory() as temp:
            frozen = pathlib.Path(temp) / 'linux_restore_probe-v1.py'
            frozen.write_bytes(local_wsl.BASE_PATH.read_bytes())
            with mock.patch.object(local_wsl, 'FROZEN_BASE', frozen):
                return local_wsl.load_base()

    def accepted(self, entries=()):
        wanted = sorted((self.load_public_base().projection(e) for e in entries), key=lambda x: x['path'])
        return json.dumps({
            'verdict': 'ACCEPT', 'entry_count': len(entries),
            'restored_sha256': hashlib.sha256(json.dumps(wanted, sort_keys=True, separators=(',', ':')).encode()).hexdigest(),
            'scratch_cleaned': True, 'wsl_distro': local_wsl.DISTRO,
            'kernel_release': '6.6.87.2-microsoft-standard-WSL2',
        }).encode()

    def test_exact_replacements_and_public_frozen_copy(self):
        base = self.load_public_base()
        self.assertNotIn('racknerd-f0269d5', base.REMOTE)
        self.assertEqual(base.REMOTE.count("WSL_DISTRO_NAME')=='QuizArchiveVerify21'"), 1)
        self.assertEqual(base.REMOTE.count("'kernel_release':os.uname().release"), 1)

    def test_hash_mismatch_refuses(self):
        with mock.patch.object(local_wsl, 'digest', return_value='bad'):
            with self.assertRaisesRegex(ValueError, 'frozen base verifier differs'):
                local_wsl.load_base()

    def test_wsl_direct_args_and_validated_stdout(self):
        with mock.patch('subprocess.Popen') as popen:
            proc = mock.Mock()
            proc.stdin = mock.Mock()
            proc.communicate.return_value = (self.accepted(), b'')
            proc.returncode = 0
            popen.return_value = proc
            base = self.load_public_base()
            result = local_wsl.local_send(base, pathlib.Path(__file__), [], 'root')
        self.assertEqual(popen.call_args.args[0][:9], ['wsl.exe', '-d', 'QuizArchiveVerify21', '-u', 'root', '--', 'python3', '-c', base.REMOTE])
        self.assertEqual(result['base_verifier_sha256'], local_wsl.BASE_SHA)

    def test_bad_count_hash_and_kernel_are_refused(self):
        for changes in ({'entry_count': 1}, {'restored_sha256': 'bad'}, {'kernel_release': 'linux'}):
            with self.subTest(changes=changes), mock.patch('subprocess.Popen') as popen:
                data = json.loads(self.accepted())
                data.update(changes)
                proc = mock.Mock()
                proc.stdin = mock.Mock()
                proc.communicate.return_value = (json.dumps(data).encode(), b'')
                proc.returncode = 0
                popen.return_value = proc
                with self.assertRaisesRegex(ValueError, 'proof differs'):
                    local_wsl.local_send(self.load_public_base(), pathlib.Path(__file__), [], 'root')

    def test_nonzero_wsl_refusal_is_not_json_accepted(self):
        with mock.patch('subprocess.Popen') as popen:
            proc = mock.Mock()
            proc.stdin = mock.Mock()
            proc.communicate.return_value = (b'', b'platform assertion failed')
            proc.returncode = 1
            popen.return_value = proc
            with self.assertRaisesRegex(RuntimeError, 'platform assertion failed'):
                local_wsl.local_send(self.load_public_base(), pathlib.Path(__file__), [], 'root')


if __name__ == '__main__':
    unittest.main()
