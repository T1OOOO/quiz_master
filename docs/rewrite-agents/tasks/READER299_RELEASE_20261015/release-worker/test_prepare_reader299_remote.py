import re
import unittest
import tempfile
import json
import subprocess
from pathlib import Path
import prepare_reader299_remote as remote


class RemoteReaderTests(unittest.TestCase):
    def package(self):
        return {'build_id': remote.reader.BUILD_ID, 'archive_sha256': 'a' * 64}

    def test_prepare_script_has_actual61_guards_and_owned_upload(self):
        guard, script = remote.remote_scripts(self.package(), '1' * 32)
        self.assertIn('version==61', guard)
        self.assertIn(remote.reader.BASELINE_IMAGE, guard)
        self.assertIn(remote.reader.PVC_UID, guard)
        self.assertIn('.upload-' + '1' * 32, guard)
        self.assertIn('flock -n 8', script)
        self.assertIn('bash cutover.sh prepare', script)
        self.assertNotIn(remote.RENDER_ALIAS, script)
        self.assertNotIn('helm upgrade', script)
        self.assertNotIn('kubectl apply -n', script)
        self.assertNotIn('\r', script)
        for body in (guard,script,remote.collection_script(remote.reader.BUILD_ID+'-cutover-20261015T120000Z','sha256:'+'b'*64,'c'*64)):
            check=subprocess.run(['C:/Program Files/Git/bin/bash.exe','-n'],input=body.encode(),capture_output=True)
            self.assertEqual(check.returncode,0,check.stderr.decode())

    def test_wrong_build_and_nonce_are_rejected(self):
        package = self.package()
        package['build_id'] = remote.RENDER_ALIAS
        with self.assertRaisesRegex(RuntimeError, 'fixed Reader build'):
            remote.remote_scripts(package, '1' * 32)
        with self.assertRaises(RuntimeError):
            remote.remote_scripts(self.package(), '../wrong')

    def test_collection_keeps_rehearsal_and_enforces_all178_reader_refs(self):
        run = remote.reader.BUILD_ID + '-cutover-20261014T142000Z'
        script = remote.collection_script(run, 'sha256:' + 'b' * 64, 'c' * 64)
        self.assertIn('expected_articles=299,expected_total_refs=180,expected_playable_refs=178', script)
        self.assertIn("'baseline_helm_revision':61", script)
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

    def test_baseline_archive_is_the_shared_real_actor_archive(self):
        self.assertEqual(remote.reader.BASELINE_ARCHIVE, remote.REPO / '.run/actor291_release_20261015/package-v1/quiz-2026.10.15-reader291-3482af9.tar.gz')
        self.assertTrue(remote.reader.BASELINE_ARCHIVE.is_file())

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
        from reader299_guard import preflight_shell
        code=preflight_shell().split("<<'QUIZ_PREFLIGHT'\n",1)[1].rsplit('\nQUIZ_PREFLIGHT',1)[0]
        image=remote.reader.BASELINE_IMAGE
        node={'spec':{},'status':{'conditions':[{'type':'Ready','status':'True'},{'type':'DiskPressure','status':'False'}]}}
        base={'helm':{'version':61,'info':{'status':'deployed'}},'deploy':{'spec':{'template':{'spec':{'containers':[{'image':image},{'image':image}]}}},'status':{'availableReplicas':1}},'pvc':{'metadata':{'uid':remote.reader.PVC_UID},'status':{'phase':'Bound'}},'nodes':{'items':[node]}}
        def execute(data,available=21,feedback_count=29,open_count=29,feedback_hash='452929a2ea8dc34600eff8039571e2b0479ec7ad1ec52fa6e271b5c71008030e'):
            def command(args):
                key='helm' if args[0]=='helm' else args[2]
                return json.dumps(data[key]).encode()
            response=MagicMock();response.__enter__.return_value.status=200
            usage=SimpleNamespace(f_bavail=available,f_blocks=100,f_frsize=1)
            # Synthetic read-only DB responses test guard branches; these are not production receipts.
            db=MagicMock();connection=db.__enter__.return_value
            connection.execute.return_value.fetchall.return_value=[('synthetic feedback',)]*feedback_count
            connection.execute.return_value.fetchone.return_value=(open_count,)
            checksum=MagicMock();checksum.hexdigest.return_value=feedback_hash
            with patch('subprocess.check_output',side_effect=command),patch('os.statvfs',create=True,return_value=usage),patch('urllib.request.urlopen',return_value=response),patch('sqlite3.connect',return_value=db) as connect,patch('hashlib.sha256',return_value=checksum):
                exec(compile(code,'actual-preflight','exec'),{})
                connect.assert_called_once()
                self.assertIn('?mode=ro',connect.call_args.args[0])
                self.assertEqual(connect.call_args.kwargs,{'uri':True})
        execute(base)
        for available in (19,20):
            with self.subTest(available=available),self.assertRaises(AssertionError):execute(base,available)
        for kwargs in ({'feedback_count':28},{'open_count':28},{'feedback_hash':'0'*64}):
            with self.subTest(kwargs=kwargs),self.assertRaises(AssertionError):execute(base,**kwargs)
        for mutate in ('not_ready','disk_pressure','taint','cordon','wrong_image','wrong_helm','two_nodes','wrong_pvc','unbound_pvc','no_replica'):
            data=copy.deepcopy(base)
            if mutate=='not_ready':data['nodes']['items'][0]['status']['conditions'][0]['status']='False'
            if mutate=='disk_pressure':data['nodes']['items'][0]['status']['conditions'][1]['status']='True'
            if mutate=='taint':data['nodes']['items'][0]['spec']['taints']=[{'effect':'NoSchedule'}]
            if mutate=='cordon':data['nodes']['items'][0]['spec']['unschedulable']=True
            if mutate=='wrong_image':data['deploy']['spec']['template']['spec']['containers'][0]['image']='foreign'
            if mutate=='wrong_helm':data['helm']['version']=54
            if mutate=='two_nodes':data['nodes']['items'].append(copy.deepcopy(node))
            if mutate=='wrong_pvc':data['pvc']['metadata']['uid']='foreign'
            if mutate=='unbound_pvc':data['pvc']['status']['phase']='Pending'
            if mutate=='no_replica':data['deploy']['status']['availableReplicas']=0
            with self.subTest(mutate=mutate),self.assertRaises(AssertionError):execute(data)

if __name__ == '__main__':
    unittest.main()
