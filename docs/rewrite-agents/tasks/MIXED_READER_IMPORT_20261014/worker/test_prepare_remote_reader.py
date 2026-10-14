import re
import unittest
import tempfile
import json
from pathlib import Path
import prepare_remote_reader as remote


class RemoteReaderTests(unittest.TestCase):
    def package(self):
        return {'build_id': remote.reader.BUILD_ID, 'archive_sha256': 'a' * 64}

    def test_prepare_script_has_actual53_guards_and_owned_upload(self):
        guard, script = remote.remote_scripts(self.package(), '1' * 32)
        self.assertIn('version==53', guard)
        self.assertIn(remote.reader.BASELINE_IMAGE, guard)
        self.assertIn(remote.reader.PVC_UID, guard)
        self.assertIn('.upload-' + '1' * 32, guard)
        self.assertIn('flock -n 8', script)
        self.assertIn('bash cutover.sh prepare', script)
        self.assertNotIn(remote.RENDER_ALIAS, script)
        self.assertNotIn('helm upgrade', script)
        self.assertNotIn('kubectl apply -n', script)
        self.assertNotIn('\r', script)

    def test_wrong_build_and_nonce_are_rejected(self):
        package = self.package()
        package['build_id'] = remote.RENDER_ALIAS
        with self.assertRaisesRegex(RuntimeError, 'fixed Reader build'):
            remote.remote_scripts(package, '1' * 32)
        with self.assertRaises(RuntimeError):
            remote.remote_scripts(self.package(), '../wrong')

    def test_collection_keeps_rehearsal_and_enforces_all151_reader_refs(self):
        run = remote.reader.BUILD_ID + '-cutover-20261014T142000Z'
        script = remote.collection_script(run, 'sha256:' + 'b' * 64, 'c' * 64)
        self.assertIn('expected_articles=272,expected_total_refs=153,expected_playable_refs=151', script)
        self.assertIn("'baseline_helm_revision':53", script)
        self.assertIn('old_api_rollback', script)
        self.assertIn('original_rows_preserved', script)
        self.assertIn('backup_mode', script)
        self.assertNotIn(remote.RENDER_ALIAS, script)
        body = re.search(r"python3 - <<'PY'\n(.*?)\nPY", script, re.S).group(1)
        compile(body, 'reader-collector', 'exec')

    def test_changed_house_renderer_contract_fails_closed(self):
        with self.assertRaisesRegex(RuntimeError, 'contract changed'):
            remote.replace_once('x x', 'x', 'y')
        with self.assertRaisesRegex(RuntimeError, 'contract changed'):
            remote.replace_once('none', 'x', 'y')

    def test_tampered_bootstrap_fails_even_when_js_and_metadata_match(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            web = root / 'web'
            web.mkdir()
            (web / 'main.dart.js').write_bytes(b'compiled fixture')
            (web / 'index.html').write_bytes(b'bootstrap fixture')
            (web / 'version.json').write_text('{}')
            digest = remote.reader.digest(web / 'main.dart.js')
            records = {'trees': {'trees': {'production': {'file_sha256': remote.reader.file_tree(web)}}},
                       'build': {'checks': [{'label': 'production', 'main_dart_js_sha256': digest}]}}
            pins = {}
            for key, name in [('web_trees', 'trees'), ('build_receipt', 'build')]:
                path = root / (name + '.json')
                path.write_text(json.dumps(records[name]))
                pins[key] = {'path': str(path), 'sha256': remote.reader.digest(path)}
            metadata = {'main_dart_js_sha256': digest}
            remote.verify_stage_web(root, pins, metadata)
            (web / 'index.html').write_bytes(b'unreviewed bootstrap')
            with self.assertRaisesRegex(RuntimeError, 'Web payload differs'):
                remote.verify_stage_web(root, pins, metadata)


if __name__ == '__main__':
    unittest.main()
