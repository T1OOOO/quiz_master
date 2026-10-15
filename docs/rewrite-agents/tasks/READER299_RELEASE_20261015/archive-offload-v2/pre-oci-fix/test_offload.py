from pathlib import Path
import hashlib, os, subprocess, sys, tempfile, unittest, tarfile, io
from unittest.mock import patch
from offload import remove_verified
import offload
import generate
import execute
import json


class OffloadTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name).resolve()
        fixture_total=patch.object(offload,'EXPECTED_TOTAL_BYTES',19*21)
        fixture_total.start();self.addCleanup(fixture_total.stop)

    def tearDown(self):
        self.temp.cleanup()

    def entry(self, name='quiz-2026.10.12-culture-f219916.tar'):
        path = self.root / name
        path.write_bytes(b'fixture archive bytes')
        st = path.stat()
        return {'path': '/var/lib/rancher/k3s/agent/images/' + name,
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
        b = self.entry('quiz-2026.10.13-culture-e437661.tar')
        (self.root / Path(b['path']).name).write_bytes(b'changed')
        with self.assertRaises(AssertionError):
            remove_verified([a, b], self.root)
        self.assertTrue((self.root / Path(a['path']).name).exists())

    def test_oct14_nonprotected_archive_is_allowed(self):
        a = self.entry('quiz-2026.10.14-screen-song-6866608.tar')
        self.assertEqual(remove_verified([a], self.root), [a['path']])

    def test_legacy_exact_name_allowed_and_near_misses_rejected(self):
        a=self.entry('quiz-master-abcdef0-1234.tar')
        self.assertEqual(remove_verified([a],self.root),[a['path']])
        for name in ('quiz-master-abcdef-1234.tar','quiz-master-abcdef00-1234.tar','quiz-master-abcdef0-12345.tar','quiz-master-ABCDEF0-1234.tar','other-master-abcdef0-1234.tar','quiz-master-abcdef0-1234.tar.gz'):
            with self.subTest(name=name),self.assertRaises(AssertionError):remove_verified([self.entry(name)],self.root)

    def test_all_protected_names_rejected(self):
        for name in offload.PROTECTED:
            with self.subTest(name=name),self.assertRaises(AssertionError):remove_verified([self.entry(name)],self.root)

    def test_hash_and_each_metadata_field_are_enforced(self):
        for field in ('dev','ino','mtime_ns','size','sha256'):
            entry=self.entry()
            entry[field]=('0'*64 if field=='sha256' else entry[field]+1)
            with self.subTest(field=field),self.assertRaises(AssertionError):remove_verified([entry],self.root)

    def test_inventory_additions_allowed_removals_or_retags_rejected(self):
        before={'containerd':{('ref','sha256:old')},'docker':{('ref','digest','sha256:old')}}
        after={key:value|{('new','image')} for key,value in before.items()}
        offload.images_preserved(before,after)
        for kind in before:
            bad={key:set(value) for key,value in after.items()};bad[kind].remove(next(iter(before[kind])))
            with self.subTest(kind=kind),self.assertRaises(AssertionError):offload.images_preserved(before,bad)

    def test_loaded_inventory_captures_reference_digest_and_image_id(self):
        digest='sha256:'+'a'*64;image='sha256:'+'b'*64
        outputs=['REF TYPE DIGEST SIZE PLATFORMS LABELS\nquiz:tag type '+digest+' 1 MB linux/amd64 -\n','quiz:tag '+digest+' '+image+'\n']
        with patch('subprocess.check_output',side_effect=outputs) as command:
            captured=offload.loaded_images()
        self.assertEqual(captured,{'containerd':{('quiz:tag',digest)},'docker':{('quiz:tag',digest,image)}})
        self.assertEqual(command.call_args_list[0].args[0],['k3s','ctr','images','list'])
        self.assertIn('--no-trunc',command.call_args_list[1].args[0])
        with patch('subprocess.check_output',return_value='unexpected format'):
            with self.assertRaises(AssertionError):offload.loaded_images()

    def test_snapshot_follows_batch_and_first_per_file_validation(self):
        entries=[self.entry(),self.entry('quiz-master-abcdef0-1234.tar')]
        checked=[]
        original=offload.verify
        def verify(entry,root):
            checked.append(entry['path']);return original(entry,root)
        snapshots=[]
        def snapshot():
            self.assertEqual(checked,[entries[0]['path'],entries[1]['path'],entries[0]['path']])
            self.assertTrue(all((self.root/Path(e['path']).name).is_file() for e in entries))
            snapshots.append('immediately before first unlink')
        with patch.object(offload,'verify',side_effect=verify):remove_verified(entries,self.root,before_unlink=snapshot)
        self.assertEqual(len(snapshots),1)

    def test_per_unlink_revalidation_detects_second_file_drift(self):
        entries=[self.entry(),self.entry('quiz-master-abcdef0-1234.tar')]
        def changed_after_batch():
            (self.root/Path(entries[1]['path']).name).write_bytes(b'drift after batch validation')
        with self.assertRaises(AssertionError):remove_verified(entries,self.root,before_unlink=changed_after_batch)
        self.assertTrue((self.root/Path(entries[1]['path']).name).exists())

    def exact_plan(self):
        names=sorted(offload.OLD_NAMES)+['quiz-master-'+f'{i:07x}'+'-1234.tar' for i in range(9)]
        entries=[self.entry(name) for name in names]
        return {'schema':'qm-exact-archive-offload/v2','utc':'synthetic fixture only','entries':entries,'total_bytes':sum(e['size'] for e in entries)}

    def test_plan_generator_requires_exact19_and_protected17(self):
        plan=self.exact_plan()
        self.assertEqual(len(offload.validate_plan(plan)),19)
        for key,value in [('entries',plan['entries'][:-1]),('total_bytes',0)]:
            bad={**plan,key:value}
            with self.assertRaises(AssertionError):generate.render(bad,offload.PROTECTED_HASHES)
        with self.assertRaises(AssertionError):generate.render(plan,{})
        script=generate.render(plan,offload.PROTECTED_HASHES)
        self.assertIn('flock -n 8',script)
        self.assertIn('before_unlink=snapshot_before_unlink',script)
        self.assertIn('images_preserved(before, after)',script)
        self.assertIn('inventory_summary(before)',script)
        self.assertNotIn('sorted(value)',script)
        self.assertNotIn('actual==',script)
        syntax=subprocess.run(['C:/Program Files/Git/bin/bash.exe','-n'],input=script.encode(),capture_output=True)
        self.assertEqual(syntax.returncode,0,syntax.stderr.decode())

    def executor_fixture(self):
        # All receipts in this temporary directory are synthetic unit-test fixtures.
        plan=self.exact_plan();docs=self.root/'docs';docs.mkdir()
        legacy={}
        for e in plan['entries']:
            name=Path(e['path']).name
            if not name.startswith('quiz-master-'):continue
            commit=name.split('-')[2]
            refs=['quiz-master:quiz-2026.10.11-fixture-'+commit]
            legacy[name]=refs
            payload=json.dumps([{'RepoTags':refs}]).encode()
            local=self.root/name
            with tarfile.open(local,'w') as archive:
                member=tarfile.TarInfo('manifest.json');member.size=len(payload);archive.addfile(member,io.BytesIO(payload))
            st=local.stat();e.update(size=st.st_size,dev=st.st_dev,ino=st.st_ino,mtime_ns=st.st_mtime_ns,sha256=execute.digest(local))
        plan['total_bytes']=sum(e['size'] for e in plan['entries'])
        fixture_total=patch.object(offload,'EXPECTED_TOTAL_BYTES',plan['total_bytes'])
        fixture_total.start();self.addCleanup(fixture_total.stop)
        (docs/'legacy-project-references.json').write_text(json.dumps(legacy))
        copies=[]
        for e in plan['entries']:
            copies.append({'remote':e['path'],'local':str(self.root/Path(e['path']).name),'size':e['size'],'sha256':e['sha256'],'transfer_kind':'ssh-gzip-tar','transfer_exit':0})
        (docs/'plan.json').write_text(json.dumps(plan))
        receipt={'plan_sha256':execute.digest(docs/'plan.json'),'count':19,'bytes':plan['total_bytes'],'copied':copies}
        (docs/'copy-receipt.json').write_text(json.dumps(receipt))
        (docs/'protected-hashes.json').write_text(json.dumps(offload.PROTECTED_HASHES))
        (docs/'tests.json').write_text(json.dumps({'actual_exit':0,'scope':'synthetic test fixture'}))
        (docs/'offload.sh').write_bytes(generate.render(plan,offload.PROTECTED_HASHES).encode())
        for name in ('offload.py','execute.py','generate.py','test_offload.py'):(docs/name).write_bytes((Path(__file__).parent/name).read_bytes())
        hashes={name:execute.digest(docs/name) for name in execute.INPUT_FILES}
        (docs/'approval-inputs.json').write_text(json.dumps(hashes))
        item={'call':{'action':'review','arguments':{'task_id':execute.TASK_ID,'verdict':'accept','error_count':0,'note':'approval-inputs sha256 '+execute.digest(docs/'approval-inputs.json')}},'actual_response':{'id':execute.TASK_ID,'state':'ACCEPTED','assignee':execute.ASSIGNEE,'reviewer':'synthetic-independent-reviewer'}}
        (docs/'source-review.json').write_text(json.dumps({'actual_cli_exit':0,'actual_hub_state':'ACCEPTED','actual_reviews':{execute.TASK_ID:item}}))
        return docs,plan,receipt

    def test_executor_wrong_local_copy_rejected_before_ssh(self):
        docs,plan,_=self.executor_fixture()
        with patch.object(execute,'DOCS',docs),patch.object(execute,'COPY_ROOTS',(self.root,)),patch.object(execute.subprocess,'run') as ssh:
            execute.validate_inputs()
            (self.root/Path(plan['entries'][0]['path']).name).write_bytes(b'wrong copy')
            with self.assertRaises(AssertionError):execute.main()
            ssh.assert_not_called()

    def test_executor_wrong_bound_input_and_existing_logs_rejected_before_ssh(self):
        docs,_,_=self.executor_fixture()
        with patch.object(execute,'DOCS',docs),patch.object(execute,'COPY_ROOTS',(self.root,)),patch.object(execute.subprocess,'run') as ssh:
            (docs/'execution-exit.json').write_text('{"actual_exit":1}')
            with self.assertRaises(AssertionError):execute.main()
            (docs/'offload.sh').write_text('changed script')
            with self.assertRaises(AssertionError):execute.main()
            ssh.assert_not_called()

    def test_copy_transfer_exit_and_allowed_roots(self):
        docs,plan,receipt=self.executor_fixture()
        legacy=json.loads((docs/'legacy-project-references.json').read_bytes())
        with patch.object(execute,'COPY_ROOTS',(self.root,)):
            execute.verify_copies(plan,receipt,execute.digest(docs/'plan.json'),legacy)
            receipt['copied'][0]['transfer_exit']=1
            with self.assertRaises(AssertionError):execute.verify_copies(plan,receipt,execute.digest(docs/'plan.json'),legacy)
        receipt['copied'][0]['transfer_exit']=0
        with patch.object(execute,'COPY_ROOTS',(self.root/'foreign',)):
            with self.assertRaises(AssertionError):execute.verify_copies(plan,receipt,execute.digest(docs/'plan.json'),legacy)

    def test_legacy_manifest_must_match_bound_project_refs_and_filename_commit(self):
        docs,plan,receipt=self.executor_fixture()
        legacy=json.loads((docs/'legacy-project-references.json').read_bytes())
        with patch.object(execute,'COPY_ROOTS',(self.root,)):
            execute.verify_copies(plan,receipt,execute.digest(docs/'plan.json'),legacy)
            legacy[next(iter(legacy))]=['other-project:private']
            with self.assertRaises(AssertionError):execute.verify_copies(plan,receipt,execute.digest(docs/'plan.json'),legacy)

    def test_actual_root_plan_has_exact19_and_expected_bytes(self):
        plan=json.loads((Path(__file__).parent/'plan.json').read_bytes())
        with patch.object(offload,'EXPECTED_TOTAL_BYTES',1397289472):
            self.assertEqual(len(offload.validate_plan(plan)),19)

    def test_protected17_full_hashes_checked_before_and_after(self):
        protected={}
        for i in range(17):
            path=self.root/('protected-'+str(i));path.write_bytes(b'protected fixture')
            protected[str(path)]=execute.digest(path)
        with patch.object(offload,'PROTECTED_HASHES',protected):
            offload.verify_protected(protected)
            Path(next(iter(protected))).write_bytes(b'drift')
            with self.assertRaises(AssertionError):offload.verify_protected(protected)

    def test_inventory_summary_does_not_disclose_foreign_registry_names(self):
        state={'containerd':{('private.example/foreign:tag','sha256:a')},'docker':{('private.example/foreign:tag','digest','sha256:b')}}
        summary=json.dumps(offload.inventory_summary(state))
        self.assertNotIn('private.example',summary)
        self.assertNotIn('foreign',summary)

    def test_live_preflight_guards_allow_cleanup_below20_but_reject_state_drift(self):
        import copy
        from types import SimpleNamespace
        from unittest.mock import MagicMock
        image='docker.io/library/quiz-master@sha256:0f24677d8e499df9d21e80ce1dd50b8e830b37608c4c86e1c38e76ccc30d3228'
        base={'helm':{'version':61,'info':{'status':'deployed'}},'deploy':{'spec':{'template':{'spec':{'containers':[{'image':image},{'image':image}]}}},'status':{'availableReplicas':1}},'pvc':{'metadata':{'uid':'7fc2428f-4146-4c78-a26d-2347d9f3b7bf'},'status':{'phase':'Bound'}},'nodes':{'items':[{'spec':{},'status':{'conditions':[{'type':'Ready','status':'True'},{'type':'DiskPressure','status':'False'}]}}]}}
        expected='452929a2ea8dc34600eff8039571e2b0479ec7ad1ec52fa6e271b5c71008030e'
        def run(data,rows=29,opened=29,checksum=expected,mode=0o600,integrity='ok',ready=200):
            def command(args):return json.dumps(data['helm' if args[0]=='helm' else args[2]]).encode()
            connection=MagicMock();db=connection.__enter__.return_value
            def query(sql):return SimpleNamespace(fetchall=lambda:[('synthetic',)]*rows,fetchone=lambda:(opened,) if 'status=' in sql else (integrity,))
            db.execute.side_effect=query
            digest=MagicMock();digest.hexdigest.return_value=checksum
            response=MagicMock();response.__enter__.return_value.status=ready
            with patch('subprocess.check_output',side_effect=command),patch('sqlite3.connect',return_value=connection) as connect,patch('hashlib.sha256',return_value=digest),patch('os.statvfs',create=True,return_value=SimpleNamespace(f_bavail=19,f_blocks=100,f_frsize=1)),patch('os.stat',return_value=SimpleNamespace(st_mode=mode)),patch('urllib.request.urlopen',return_value=response):
                result=offload.preflight()
                self.assertTrue(all('?mode=ro' in call.args[0] and call.kwargs=={'uri':True} for call in connect.call_args_list))
                return result
        self.assertFalse(run(base)['disk_at_least20percent'])
        for kwargs in ({'rows':28},{'opened':28},{'checksum':'0'*64},{'mode':0o644},{'integrity':'bad'},{'ready':503}):
            with self.subTest(kwargs=kwargs),self.assertRaises(AssertionError):run(base,**kwargs)
        for field in ('helm','image','replica','pvc','unbound','not_ready','pressure','taint','cordon'):
            data=copy.deepcopy(base)
            if field=='helm':data['helm']['version']=60
            if field=='image':data['deploy']['spec']['template']['spec']['containers'][0]['image']='other'
            if field=='replica':data['deploy']['status']['availableReplicas']=0
            if field=='pvc':data['pvc']['metadata']['uid']='other'
            if field=='unbound':data['pvc']['status']['phase']='Pending'
            if field=='not_ready':data['nodes']['items'][0]['status']['conditions'][0]['status']='False'
            if field=='pressure':data['nodes']['items'][0]['status']['conditions'][1]['status']='True'
            if field=='taint':data['nodes']['items'][0]['spec']['taints']=[{'effect':'NoSchedule'}]
            if field=='cordon':data['nodes']['items'][0]['spec']['unschedulable']=True
            with self.subTest(field=field),self.assertRaises(AssertionError):run(data)

    def test_rejects_traversal(self):
        a = self.entry()
        a['path'] = '/var/lib/rancher/k3s/agent/images/../' + Path(a['path']).name
        with self.assertRaises(AssertionError):
            remove_verified([a], self.root)

    def test_rejects_protected_package(self):
        a = self.entry('quiz-2026.10.14-library-09b19cc.tar')
        with self.assertRaises(AssertionError):
            remove_verified([a], self.root)

    def test_rejects_compressed_or_out_of_window_archive_names(self):
        for name in ('quiz-2026.10.12-culture-f219916.tar.gz',
                     'quiz-2026.10.15-culture-f219916.tar'):
            with self.subTest(name=name):
                with self.assertRaises(AssertionError):
                    remove_verified([self.entry(name)], self.root)

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
            'actual_reviews': {execute.TASK_ID: item}}))
        with patch.object(execute, 'DOCS', self.root), patch.object(execute.subprocess, 'run') as ssh:
            with self.assertRaises(AssertionError):
                execute.main()
            ssh.assert_not_called()

    def test_optimized_python_refuses_offload_and_executor_before_logic(self):
        for module in ('offload', 'execute', 'generate'):
            result = subprocess.run([sys.executable, '-O', '-c', f'import {module}'], cwd=Path(__file__).parent,
                                    capture_output=True, text=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn('refuses optimized Python', result.stderr)


if __name__ == '__main__':
    unittest.main()
