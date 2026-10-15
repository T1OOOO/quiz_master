import re
import unittest
import tempfile
import json
from pathlib import Path
import prepare_actor283_remote as remote


class RemoteReaderTests(unittest.TestCase):
    def package(self):
        return {'build_id': remote.reader.BUILD_ID, 'archive_sha256': 'a' * 64}

    def test_prepare_script_has_actual59_guards_and_owned_upload(self):
        guard, script = remote.remote_scripts(self.package(), '1' * 32)
        self.assertIn('version==59', guard)
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

    def test_collection_keeps_rehearsal_and_enforces_all162_reader_refs(self):
        run = remote.reader.BUILD_ID + '-cutover-20261014T142000Z'
        script = remote.collection_script(run, 'sha256:' + 'b' * 64, 'c' * 64)
        self.assertIn('expected_articles=283,expected_total_refs=164,expected_playable_refs=162', script)
        self.assertIn("'baseline_helm_revision':59", script)
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


    def test_preflight_executes_available_space_and_target_node_guards(self):
        import copy
        from types import SimpleNamespace
        from unittest.mock import patch, MagicMock
        from actor283_guard import preflight_shell
        code=preflight_shell().split("<<'QUIZ_PREFLIGHT'\n",1)[1].rsplit('\nQUIZ_PREFLIGHT',1)[0]
        image=remote.reader.BASELINE_IMAGE
        node={'spec':{},'status':{'conditions':[{'type':'Ready','status':'True'},{'type':'DiskPressure','status':'False'}]}}
        base={'helm':{'version':59,'info':{'status':'deployed'}},'deploy':{'spec':{'template':{'spec':{'containers':[{'image':image},{'image':image}]}}},'status':{'availableReplicas':1}},'pvc':{'metadata':{'uid':remote.reader.PVC_UID}},'nodes':{'items':[node]}}
        def execute(data,available=20):
            def command(args):
                key='helm' if args[0]=='helm' else args[2]
                return json.dumps(data[key]).encode()
            response=MagicMock();response.__enter__.return_value.status=200
            usage=SimpleNamespace(f_bavail=available,f_blocks=100,f_frsize=1)
            with patch('subprocess.check_output',side_effect=command),patch('os.statvfs',create=True,return_value=usage),patch('urllib.request.urlopen',return_value=response):exec(compile(code,'actual-preflight','exec'),{})
        execute(base)
        with self.assertRaises(AssertionError):execute(base,19)
        for mutate in ('not_ready','disk_pressure','taint','cordon','wrong_image','wrong_helm','two_nodes'):
            data=copy.deepcopy(base)
            if mutate=='not_ready':data['nodes']['items'][0]['status']['conditions'][0]['status']='False'
            if mutate=='disk_pressure':data['nodes']['items'][0]['status']['conditions'][1]['status']='True'
            if mutate=='taint':data['nodes']['items'][0]['spec']['taints']=[{'effect':'NoSchedule'}]
            if mutate=='cordon':data['nodes']['items'][0]['spec']['unschedulable']=True
            if mutate=='wrong_image':data['deploy']['spec']['template']['spec']['containers'][0]['image']='foreign'
            if mutate=='wrong_helm':data['helm']['version']=54
            if mutate=='two_nodes':data['nodes']['items'].append(copy.deepcopy(node))
            with self.subTest(mutate=mutate),self.assertRaises(AssertionError):execute(data)

if __name__ == '__main__':
    unittest.main()
