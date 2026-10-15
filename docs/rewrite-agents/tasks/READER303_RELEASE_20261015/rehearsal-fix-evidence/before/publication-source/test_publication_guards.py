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
        packet={'publish_script_sha256':digest,'package_sha256':digest,'image':acceptance['image']}
        package={'archive_sha256':digest,'archive':'inert-unit-fixture.tar.gz'}
        for mutation in ('old_task','wrong_callback','self_review','wrong_executor','wrong_package'):
            a=copy.deepcopy(acceptance)
            if mutation=='old_task':a['execution_review_task_id']='task-1f1ca79d0de24c93954406a82768c20f'
            if mutation=='wrong_callback':a['actual_reviews'][task]['actual_response']['id']='task-'+'d'*32
            if mutation=='self_review':a['actual_reviews'][task]['actual_response']['reviewer']='native'
            if mutation=='wrong_executor':a['publication_executor_sha256']='0'*64
            if mutation=='wrong_package':a['package_sha256']='0'*64
            documents={'execution-acceptance.json':a,'execution-packet.json':packet,'package-preparation.json':package}
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
        package={'archive':str(work/'package-v1'/(reader.BUILD_ID+'.tar.gz')),'build_id':reader.BUILD_ID,'frozen_commit':reader.FROZEN_COMMIT,'archive_sha256':'a'*64}
        data={work/'package-v1/package-preparation.json':json.dumps(package).encode(),receipt_path:json.dumps(receipt).encode()}
        data[docs/'preparation-receipt-pin.json']=json.dumps({'path':str(receipt_path),'sha256':hashlib.sha256(data[receipt_path]).hexdigest()}).encode()
        writes={}
        def read(path):return data.get(path,b'unit payload')
        with patch.object(Path,'read_bytes',read),patch.object(Path,'read_text',return_value=cutover),patch.object(Path,'write_bytes',lambda path,value:writes.__setitem__(path,value)),patch.object(Path,'write_text',lambda path,value,**kw:writes.__setitem__(path,value.encode())):
            with redirect_stdout(io.StringIO()):module.main()
        shell=writes[docs/'publish-preview.sh'].decode()
        self.assertIn('version"]==62',shell);self.assertIn(reader.BASELINE_IMAGE,shell)
        self.assertIn('f_bavail',shell);self.assertIn('[[ "$quiz_mode" = publish ]]',shell)
        self.assertEqual(shell.count('helm upgrade'),1);self.assertIn('--atomic --wait',shell)
        self.assertIn('backup_sqlite.py',shell);self.assertIn('apply --dry-run=server',shell)
        self.assertNotIn('docker build',shell);self.assertNotIn('bash cutover.sh prepare',shell)
        check=subprocess.run(['C:/Program Files/Git/bin/bash.exe','-n'],input=shell.encode(),capture_output=True)
        self.assertEqual(check.returncode,0,check.stderr.decode())
        data[receipt_path]=json.dumps(dict(receipt,source_commit='0'*40)).encode();writes.clear()
        data[docs/'preparation-receipt-pin.json']=json.dumps({'path':str(receipt_path),'sha256':hashlib.sha256(data[receipt_path]).hexdigest()}).encode()
        with patch.object(Path,'read_bytes',read),patch.object(Path,'write_bytes') as write:
            with self.assertRaises(AssertionError):module.main()
        write.assert_not_called()

    def test_existing_execution_logs_refuse_a_repeat_before_receipts_or_ssh(self):
        source=ROOT/'publish_release.py'
        payload=source.read_text()
        with patch.object(Path,'exists',return_value=True),patch.object(Path,'read_bytes') as read,patch.object(subprocess,'run') as ssh:
            with self.assertRaisesRegex(RuntimeError,'existing publication evidence'):
                exec(compile(payload,str(source),'exec'),{'__name__':'__main__','__file__':str(source)})
        read.assert_not_called();ssh.assert_not_called()

if __name__=='__main__':unittest.main()
