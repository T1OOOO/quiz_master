from pathlib import Path
import importlib.util,json,subprocess,sys,unittest,hashlib,copy,tarfile,tempfile,io
from contextlib import redirect_stdout
from unittest.mock import patch

ROOT=Path(__file__).parent

class PublicationGuards(unittest.TestCase):
    def test_renderer_import_does_not_render_without_inputs(self):
        spec=importlib.util.spec_from_file_location('reader303_publication_renderer',ROOT/'render_publication.py')
        module=importlib.util.module_from_spec(spec)
        with patch.object(Path,'write_bytes') as write,patch.object(subprocess,'run') as ssh:
            spec.loader.exec_module(module)
        self.assertTrue(callable(module.main));write.assert_not_called();ssh.assert_not_called()

    def test_optimized_python_is_refused_before_reading_receipts(self):
        for name in ['render_publication','publish_release']:
            with self.subTest(name=name):
                p=subprocess.run([sys.executable,'-O','-c',f'import {name}'],cwd=ROOT,capture_output=True,text=True)
                self.assertNotEqual(p.returncode,0)
                self.assertIn('refuses optimized Python',p.stderr)

    def test_unaccepted_execution_receipt_never_reaches_ssh(self):
        source=ROOT/'publish_release.py'
        with patch.object(Path,'read_bytes',return_value=json.dumps({'actual_hub_state':'REWORK'}).encode()),patch.object(subprocess,'run') as ssh,patch.object(subprocess,'check_output') as git:
            with self.assertRaises(AssertionError):
                exec(compile(source.read_text(),str(source),'exec'),{'__name__':'__main__','__file__':str(source)})
        ssh.assert_not_called();git.assert_not_called()

    def test_stale_or_unbound_execution_review_stops_before_git_and_ssh(self):
        source=ROOT/'publish_release.py';payload=source.read_text();digest='a'*64
        task='task-'+'b'*32
        acceptance={'actual_hub_state':'ACCEPTED','actual_cli_exit':0,'reviewer_provider':'claude',
                    'publication_executor_sha256':digest,'execution_packet_sha256':digest,
                    'publish_script_sha256':digest,'package_sha256':digest,'image':'sha256:'+'c'*64,
                    'execution_review_task_id':task,
                    'actual_reviews':{task:{'actual_response':{'state':'ACCEPTED','assignee':'native','reviewer':'independent','id':task},
                    'call':{'action':'review','arguments':{'verdict':'accept','task_id':task,'error_count':0,
                    'note':'execution-packet sha256 '+digest}}}}}
        package_path=Path('C:/ap/quiz_master/.run/reader303_release_20261015/package-v2/package-preparation.json')
        packet={'publish_script_sha256':digest,'package_sha256':digest,'image':acceptance['image'],'package_receipt_path':str(package_path.resolve()),'package_receipt_sha256':digest,'build_id':'quiz-2026.10.15-reader303-14b7da4','source_commit':'14b7da43c3e43642d60859f5053ee6d809c2379e'}
        package={'archive_sha256':digest,'archive':str(package_path.parent/'quiz-2026.10.15-reader303-14b7da4.tar.gz'),'build_id':packet['build_id'],'frozen_commit':packet['source_commit'],'status':'PREPARED_NOT_EXECUTED'}
        for mutation in ('old_task','wrong_callback','self_review','wrong_executor','wrong_package'):
            a=copy.deepcopy(acceptance)
            if mutation=='old_task':a['execution_review_task_id']='task-1f1ca79d0de24c93954406a82768c20f'
            if mutation=='wrong_callback':a['actual_reviews'][task]['actual_response']['id']='task-'+'d'*32
            if mutation=='self_review':a['actual_reviews'][task]['actual_response']['reviewer']='native'
            if mutation=='wrong_executor':a['publication_executor_sha256']='0'*64
            if mutation=='wrong_package':a['package_sha256']='0'*64
            documents={'execution-acceptance.json':a,'execution-packet.json':packet,'package-preparation.json':package,'package-receipt-pin.json':{'path':str(package_path),'sha256':digest}}
            def read(path):return json.dumps(documents.get(path.name,{})).encode()
            with self.subTest(mutation=mutation),patch.object(Path,'exists',return_value=False),patch.object(Path,'is_symlink',return_value=False),patch.object(Path,'read_bytes',read),patch.object(hashlib,'sha256') as hashed,patch.object(subprocess,'run') as ssh,patch.object(subprocess,'check_output') as git:
                hashed.return_value.hexdigest.return_value=digest
                with self.assertRaises(AssertionError):exec(compile(payload,str(source),'exec'),{'__name__':'__main__','__file__':str(source)})
            ssh.assert_not_called();git.assert_not_called()

    def test_actual_adapted_prefix_renders_publish_only_and_rejects_wrong_receipt(self):
        worker=ROOT.parent/'release-worker'
        with patch.object(sys,'path',[str(worker),*sys.path]):
            import prepare_reader303_release as reader
            import reader303_guard
        spec=importlib.util.spec_from_file_location('reader303_render_unit',ROOT/'render_publication.py')
        module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
        repo=Path('C:/ap/quiz_master');work=repo/'.run/reader303_release_20261015';docs=ROOT.parent
        with tempfile.TemporaryDirectory() as directory:
            stage=Path(directory);(stage/'api').touch();(stage/'web').mkdir();(stage/'web/main.dart.js').write_bytes(b'unit JS')
            with tarfile.open(reader.BASELINE_ARCHIVE,'r:gz') as archive:
                for name in ('cutover.sh','rehearse.py','checksums.txt'):
                    (stage/name).write_bytes(archive.extractfile(reader.BASELINE_BUILD+'/'+name).read())
            helper=reader.house();helper.BUILD_ID=reader.BUILD_ID;helper.TARGET_SOURCE=reader.FROZEN_COMMIT;helper.TARGET_API_SHA256=reader.API_SHA256
            reader.install_runtime_verifier(stage,helper,reader.digest(stage/'web/main.dart.js'))
            cutover=(stage/'cutover.sh').read_text()
        receipt_path=work/'fresh-unit-fixture/remote-preparation-verification.json'
        receipt={'build_id':reader.BUILD_ID,'source_commit':reader.FROZEN_COMMIT,'image':'sha256:'+'c'*64,
                 'values':reader.BUILD_ID+'-cutover-20261015T180000Z-values.yaml','status':'PREPARED_NOT_PUBLISHED',
                 'remote_prepare_exit':0,'package_sha256':'a'*64,'candidate_runtime':{'reader':{'articles':303,'total_refs':184,'playable_refs':182,'noncatalog_refs':2}},
                 'durable_archive_sha256':'d'*64,'durable_archive':'/var/lib/rancher/k3s/agent/images/'+reader.BUILD_ID+'.tar',
                 'values_sha256':'e'*64,'helm_dryrun_sha256':'f'*64}
        package={'archive':str(work/'package-v2'/(reader.BUILD_ID+'.tar.gz')),'build_id':reader.BUILD_ID,'frozen_commit':reader.FROZEN_COMMIT,'archive_sha256':'a'*64}
        package_path=work/'package-v2/package-preparation.json'
        data={package_path:json.dumps(package).encode(),receipt_path:json.dumps(receipt).encode()}
        data[docs/'package-receipt-pin.json']=json.dumps({'path':str(package_path),'sha256':hashlib.sha256(data[package_path]).hexdigest()}).encode()
        data[docs/'preparation-receipt-pin.json']=json.dumps({'path':str(receipt_path),'sha256':hashlib.sha256(data[receipt_path]).hexdigest()}).encode()
        writes={}
        def read(path):return data.get(path,b'unit payload')
        with patch.object(Path,'read_bytes',read),patch.object(Path,'read_text',return_value=cutover),patch.object(Path,'write_bytes',lambda path,value:writes.__setitem__(path,value)),patch.object(Path,'write_text',lambda path,value,**kw:writes.__setitem__(path,value.encode())):
            with redirect_stdout(io.StringIO()):module.main()
        packet=json.loads(writes[docs/'execution-packet.json'])
        self.assertEqual(packet['package_receipt_path'],str(package_path.resolve()))
        self.assertEqual(packet['package_receipt_sha256'],hashlib.sha256(data[package_path]).hexdigest())
        shell=writes[docs/'publish-preview.sh'].decode()
        self.assertIn('version"]==62',shell);self.assertIn(reader.BASELINE_IMAGE,shell)
        self.assertIn('f_bavail',shell);self.assertIn('[[ "$quiz_mode" = publish ]]',shell)
        self.assertEqual(shell.count('helm upgrade'),1);self.assertIn('--atomic --wait',shell)
        self.assertIn('backup_sqlite.py',shell);self.assertIn('apply --dry-run=server',shell)
        self.assertNotIn('docker build',shell);self.assertNotIn('bash cutover.sh prepare',shell)
        check=subprocess.run(['C:/Program Files/Git/bin/bash.exe','-n'],input=shell.encode(),capture_output=True)
        self.assertEqual(check.returncode,0,check.stderr.decode())
        valid_pin=data[docs/'package-receipt-pin.json']
        for bad_pin in ({'path':'C:/unrelated/package-preparation.json','sha256':'a'*64},
                        {'path':str(package_path.with_name('wrong.json')),'sha256':'a'*64},
                        {'path':str(package_path),'sha256':'0'*64}):
            data[docs/'package-receipt-pin.json']=json.dumps(bad_pin).encode()
            with self.subTest(pin=bad_pin),patch.object(Path,'read_bytes',read),patch.object(Path,'write_bytes') as write:
                with self.assertRaisesRegex(AssertionError,'package receipt pin'):module.main()
            write.assert_not_called()
        data[docs/'package-receipt-pin.json']=valid_pin
        data[receipt_path]=json.dumps(dict(receipt,source_commit='0'*40)).encode();writes.clear()
        data[docs/'preparation-receipt-pin.json']=json.dumps({'path':str(receipt_path),'sha256':hashlib.sha256(data[receipt_path]).hexdigest()}).encode()
        with patch.object(Path,'read_bytes',read),patch.object(Path,'write_bytes') as write:
            with self.assertRaises(AssertionError):module.main()
        write.assert_not_called()

    def test_pinned_fresh_package_executor_reaches_git_only_with_matching_path_and_hash(self):
        source=ROOT/'publish_release.py';payload=source.read_text();digest='a'*64
        path=Path('C:/ap/quiz_master/.run/reader303_release_20261015/package-v2/package-preparation.json').resolve()
        task='task-'+'b'*32;build='quiz-2026.10.15-reader303-14b7da4';commit='14b7da43c3e43642d60859f5053ee6d809c2379e'
        packet={'build_id':build,'source_commit':commit,'package_receipt_path':str(path),'package_receipt_sha256':digest,'publish_script_sha256':digest,'package_sha256':digest,'image':'sha256:'+'c'*64}
        package={'build_id':build,'frozen_commit':commit,'archive':str(path.parent/(build+'.tar.gz')),'archive_sha256':digest,'status':'PREPARED_NOT_EXECUTED'}
        acceptance={'actual_hub_state':'ACCEPTED','actual_cli_exit':0,'reviewer_provider':'claude','publication_executor_sha256':digest,'execution_packet_sha256':digest,'publish_script_sha256':digest,'package_sha256':digest,'image':packet['image'],'execution_review_task_id':task,
                    'actual_reviews':{task:{'actual_response':{'state':'ACCEPTED','assignee':'native','reviewer':'independent','id':task},'call':{'action':'review','arguments':{'verdict':'accept','task_id':task,'error_count':0,'note':'execution-packet sha256 '+digest}}}}}
        original={'execution-acceptance.json':acceptance,'execution-packet.json':packet,'package-preparation.json':package,'package-receipt-pin.json':{'path':str(path),'sha256':digest}}
        for mutation in ('valid','pin_path','pin_hash','packet_path','packet_hash','outside','wrong_name','wrong_build','wrong_source','archive_parent'):
            documents=copy.deepcopy(original)
            if mutation=='pin_path':documents['package-receipt-pin.json']['path']=str(path.parent.parent/'package-v1/package-preparation.json')
            if mutation=='pin_hash':documents['package-receipt-pin.json']['sha256']='0'*64
            if mutation=='packet_path':documents['execution-packet.json']['package_receipt_path']=str(path.parent.parent/'package-v1/package-preparation.json')
            if mutation=='packet_hash':documents['execution-packet.json']['package_receipt_sha256']='0'*64
            if mutation=='outside':documents['package-receipt-pin.json']['path']='C:/unrelated/package-preparation.json'
            if mutation=='wrong_name':documents['package-receipt-pin.json']['path']=str(path.with_name('wrong.json'))
            if mutation=='wrong_build':documents['package-preparation.json']['build_id']='old-build'
            if mutation=='wrong_source':documents['package-preparation.json']['frozen_commit']='0'*40
            if mutation=='archive_parent':documents['package-preparation.json']['archive']=str(path.parent.parent/'package-v1'/(build+'.tar.gz'))
            seen=[]
            def read(p):
                seen.append(p)
                return json.dumps(documents.get(p.name,{})).encode()
            with self.subTest(mutation=mutation),patch.object(Path,'exists',return_value=False),patch.object(Path,'is_symlink',return_value=False),patch.object(Path,'read_bytes',read),patch.object(hashlib,'sha256') as h,patch.object(subprocess,'run') as ssh,patch.object(subprocess,'check_output',side_effect=RuntimeError('unit Git boundary reached')) as git:
                h.return_value.hexdigest.return_value=digest
                if mutation=='valid':
                    with self.assertRaisesRegex(RuntimeError,'Git boundary reached'):exec(compile(payload,str(source),'exec'),{'__name__':'__main__','__file__':str(source)})
                    git.assert_called_once();self.assertIn(path,seen)
                else:
                    with self.assertRaises(AssertionError):exec(compile(payload,str(source),'exec'),{'__name__':'__main__','__file__':str(source)})
                    git.assert_not_called()
            ssh.assert_not_called()

    def test_existing_execution_logs_refuse_a_repeat_before_receipts_or_ssh(self):
        source=ROOT/'publish_release.py'
        payload=source.read_text()
        with patch.object(Path,'exists',return_value=True),patch.object(Path,'read_bytes') as read,patch.object(subprocess,'run') as ssh:
            with self.assertRaisesRegex(RuntimeError,'existing publication evidence'):
                exec(compile(payload,str(source),'exec'),{'__name__':'__main__','__file__':str(source)})
        read.assert_not_called();ssh.assert_not_called()

if __name__=='__main__':unittest.main()
