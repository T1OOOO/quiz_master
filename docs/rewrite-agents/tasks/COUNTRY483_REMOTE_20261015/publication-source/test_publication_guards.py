"""Offline unit fixtures only: sample candidate fields below are never server evidence."""
from pathlib import Path
import copy,importlib.util,io,json,subprocess,sys,tempfile,unittest
from unittest.mock import patch
from contextlib import redirect_stdout
import render_publication as r
import publish_release as p

class PublicationGuards(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.stage=r.PACKAGE.parent/r.BUILD
        cls.cutover=(cls.stage/'cutover.sh').read_text()
        cls.preflight=cls.cutover.split('quiz_preflight() {\n',1)[1].split('\n}\n',1)[0]
    def fixtures(self):
        image='sha256:'+'c'*64;values=r.BUILD+'-cutover-20990101T000000Z-values.yaml';run=values.removesuffix('-values.yaml')
        e=dict(build_id=r.BUILD,source_commit=r.SOURCE,package_sha256=r.ARCHIVE_SHA,status='PREPARED_NOT_PUBLISHED',baseline_helm_revision=63,
            image=image,values=values,backup_path='/opt/quiz-master/backups/'+run+'.sqlite',backup_mode='0600',backup_integrity='ok',
            durable_archive='/var/lib/rancher/k3s/agent/images/'+r.BUILD+'.tar',candidate_runtime={},copied_db_rehearsal=dict(migration='ok',
            original_rows_preserved=True,integrity='ok',feedback_lifecycle='ok',old_api_rollback='ok',canonical_packs=14,canonical_questions=280,
            newyear_questions=55,total_graded=335,practice_finished=15,original_counts=[1,1,1,1],post_migration_counts=[1,1,1,137]))
        for key in ('values_sha256','backup_sha256','copied_db_rehearsal_sha256','candidate_runtime_sha256','helm_dryrun_sha256','durable_archive_sha256'):e[key]='a'*64
        atlas=dict(schema_version='qm-country483-candidate-atlas/v1',status='VERIFIED_CANDIDATE_ATLAS_NOT_PUBLISHED',build_id=r.BUILD,
            source_commit=r.SOURCE,package_sha256=r.ARCHIVE_SHA,package_checksums_sha256=r.CHECKSUMS_SHA,run=run,image=image,
            candidate_runtime_sha256=e['candidate_runtime_sha256'],atlas_sha256={'/usr/share/nginx/html/assets/assets/quizipedia/'+n:v for n,v in r.ATLAS.items()},
            actual_exit=0,stateless=True,production_db_mounted=False)
        e.update(candidate_atlas=atlas,candidate_atlas_sha256=r.digest((json.dumps(atlas,sort_keys=True,indent=2)+'\n').encode()))
        prep_stdout=f'PREPARED build={r.BUILD} image={image} values={values} mode=prepare\n'.encode()
        collect_stdout=b'{"preflight":"unit sample"}\n'+json.dumps(e).encode()+b'\n'
        prep=dict(actual_exit=0,stdout_sha256=r.digest(prep_stdout),script_sha256=r.RETRY_SHA,command=r.SSH_PREFIX+['env -u PYTHONOPTIMIZE -u PYTHONSTARTUP bash -s'])
        collection=dict(prep,stdout_sha256=r.digest(collect_stdout),build_id=r.BUILD,source_commit=r.SOURCE,image=image,run=run,prepared_receipt_sha256='b'*64)
        return e,prep,prep_stdout,collection,collect_stdout
    def test_valid_transport_and_multiline_final_receipt(self):
        e,a,raw,c,stdout=self.fixtures()
        self.assertEqual(r.validate_evidence(e,a,raw,c,stdout,'b'*64),c['run'])
    def test_bad_actual_receipt_mutations(self):
        for mutation in ('prepare_exit','bool_exit','collect_exit','stdout_hash','marker','last_json','collection_identity','receipt_digest','atlas_image','atlas_path','atlas_hash','runtime_hash','source','package','baseline','rehearsal','durable_path','values_path','optimized_command','old_script'):
            e,a,raw,c,stdout=self.fixtures()
            if mutation=='prepare_exit':a['actual_exit']=1
            if mutation=='bool_exit':a['actual_exit']=False
            if mutation=='collect_exit':c['actual_exit']=1
            if mutation=='stdout_hash':a['stdout_sha256']='0'*64
            if mutation=='marker':raw=raw.replace(b'PREPARED',b'FAILED');a['stdout_sha256']=r.digest(raw)
            if mutation=='last_json':stdout+=b'{}\n';c['stdout_sha256']=r.digest(stdout)
            if mutation=='collection_identity':c['image']='sha256:'+'d'*64
            if mutation=='receipt_digest':c['prepared_receipt_sha256']='d'*64
            if mutation=='atlas_image':e['candidate_atlas']['image']='sha256:'+'d'*64
            if mutation=='atlas_path':e['candidate_atlas']['atlas_sha256']={'/app/web/wrong':'a'*64}
            if mutation=='atlas_hash':e['candidate_atlas_sha256']='d'*64
            if mutation=='runtime_hash':e['candidate_runtime_sha256']='d'*64
            if mutation=='source':e['source_commit']='d'*40
            if mutation=='package':e['package_sha256']='d'*64
            if mutation=='baseline':e['baseline_helm_revision']=62
            if mutation=='rehearsal':e['copied_db_rehearsal']['old_api_rollback']='failed'
            if mutation=='durable_path':e['durable_archive']='/tmp/x.tar'
            if mutation=='values_path':e['values']='../x-values.yaml'
            if mutation=='optimized_command':a['command'][-1]='bash -s'
            if mutation=='old_script':a['script_sha256']='d'*64
            with self.subTest(mutation=mutation),self.assertRaises((ValueError,KeyError)):r.validate_evidence(e,a,raw,c,stdout,'b'*64)
    def test_real_prefix_publish_only_public_atlas_and_full_postflight(self):
        e,*_=self.fixtures();shell=r.script({},e,self.stage,self.preflight)
        self.assertIn('[[ "$quiz_mode" = publish ]]',shell);self.assertNotIn('[[ "$quiz_mode" = prepare ]]',shell)
        self.assertEqual(shell.count('helm upgrade'),1);self.assertIn('--atomic --wait --timeout 180s',shell)
        for gate in ('backup_sqlite.py','helm lint','helm template','--dry-run=server','f_bavail',"helm['version']==64",'unset PYTHONOPTIMIZE PYTHONSTARTUP','feedback_reports','quiz_preflight'):
            self.assertIn(gate,shell)
        for name,value in r.ATLAS.items():self.assertIn('https://quiz.kotopedia.org/assets/assets/quizipedia/'+name,shell);self.assertIn(value,shell)
        self.assertLess(shell.index('quizipedia/manifest.json'),shell.index("printf 'PUBLISHED"))
        self.assertNotIn('docker build',shell);self.assertNotIn('rehearse-',shell)
        result=subprocess.run(['C:/Program Files/Git/bin/bash.exe','-n'],input=shell.encode(),capture_output=True)
        self.assertEqual(result.returncode,0,result.stderr.decode())
        blocks=__import__('re').findall(r"python3 [^\n]*<<'([A-Z_0-9]+)'\n(.*?)\n\1(?:\n|$)",shell,__import__('re').S)
        self.assertEqual(len(blocks),3)
        for marker,body in blocks:compile(body,marker,'exec')
    def test_imports_inert(self):
        for name in ('render_publication','publish_release'):
            spec=importlib.util.spec_from_file_location(name+'_inert',Path(__file__).parent/(name+'.py'));module=importlib.util.module_from_spec(spec)
            with patch.object(Path,'read_bytes') as reads,patch.object(Path,'write_bytes') as writes,patch.object(subprocess,'run') as ssh:
                spec.loader.exec_module(module)
            reads.assert_not_called();writes.assert_not_called();ssh.assert_not_called()
    def test_missing_actual_pins_refuse_before_output(self):
        with patch.object(Path,'read_bytes',side_effect=FileNotFoundError('absent actual receipt')),patch.object(Path,'exists',return_value=False),patch.object(Path,'is_symlink',return_value=False),patch.object(Path,'mkdir') as mkdir:
            with self.assertRaises(FileNotFoundError):r.main()
        mkdir.assert_not_called()
    def test_existing_render_or_execution_evidence_refuses(self):
        with patch.object(Path,'exists',return_value=True),patch.object(r,'context') as context,patch.object(subprocess,'run') as ssh:
            with self.assertRaises(ValueError):r.main()
            with self.assertRaises(ValueError):p.main()
        context.assert_not_called();ssh.assert_not_called()
    def test_pin_wrong_path_or_hash(self):
        for pin in ({'path':'C:/outside/x.json','sha256':'a'*64},{'path':str(r.PACKAGE),'sha256':'a'*64}):
            with self.subTest(pin=pin),patch.object(r,'read',return_value=pin),patch.object(r,'h',return_value='b'*64):
                with self.assertRaises(ValueError):r.pin('package-receipt-pin.json',r.PACKAGE)
    def test_complete_context_with_actual_package_and_unit_only_transports(self):
        corrected=r.load(r.CORRECT,'country483_test_corrected')
        _,_,_,package=corrected.context()
        e,a,raw,c,_=self.fixtures()
        old=r.read(r.REPO/'.run/reader303_release_20261015/remote-v3-collect/remote-preparation-verification.json')
        e['candidate_runtime']=copy.deepcopy(old['candidate_runtime']);e['candidate_runtime']['image']='quiz-master:'+r.BUILD
        stdout=b'{"preflight":"unit only"}\n'+json.dumps(e).encode()+b'\n';c['stdout_sha256']=r.digest(stdout)
        expected=corrected.collection_script(c['run'],e['image'],e['durable_archive_sha256']).encode()
        c['script_sha256']=r.digest(expected)
        def binding(path,sha='a'*64):return dict(path=str(path.resolve()),sha256=sha)
        documents=[(package,binding(r.PACKAGE)),(e,binding(r.PREPARATION,'b'*64)),(a,binding(r.PREP_EXIT)),(c,binding(r.COLLECT_EXIT))]
        original_read=Path.read_bytes;original_h=r.h;collector=r.COLLECT_EXIT.parent/'script.sh'
        overlay={r.PREP_EXIT.parent/'stdout.txt':raw,r.COLLECT_EXIT.parent/'stdout.txt':stdout,collector:expected}
        def read(path):return overlay[path] if path in overlay else original_read(path)
        def hashed(path):return r.digest(overlay[Path(path)]) if Path(path) in overlay else original_h(path)
        with patch.object(r,'pin',side_effect=documents),patch.object(Path,'read_bytes',read),patch.object(r,'h',side_effect=hashed):
            p,e2,stage,binding_result,preflight=r.context()
        self.assertEqual(p,package);self.assertEqual(e2,e);self.assertEqual(stage,self.stage)
        self.assertEqual(binding_result['collector_script_sha256'],c['script_sha256']);self.assertIn("helm['version']==63",preflight)
    def approval(self):
        e,*_=self.fixtures();e['publish_script_sha256']='a'*64;task='task-'+'b'*32
        a=dict(actual_hub_state='ACCEPTED',actual_cli_exit=0,reviewer_provider='claude',publication_executor_sha256='a'*64,
            execution_packet_sha256='a'*64,publish_script_sha256='a'*64,package_sha256=r.ARCHIVE_SHA,image=e['image'],execution_review_task_id=task,
            actual_reviews={task:dict(call=dict(action='review',arguments=dict(task_id=task,verdict='accept',error_count=0,note=r.BUILD+' execution-packet sha256 '+'a'*64)),
                actual_response=dict(state='ACCEPTED',id=task,assignee='native',reviewer='independent'))})
        return a,e,task
    def test_actual_approval_mutations(self):
        a,e,_=self.approval();p.validate_acceptance(a,e,'a'*64,'a'*64,'a'*64)
        for mutation in ('unaccepted','cli','provider','executor','packet','script','package','image','old_task','self_review','error_count','note','callback_task'):
            a,e,task=self.approval();args=a['actual_reviews'][task]['call']['arguments'];response=a['actual_reviews'][task]['actual_response']
            if mutation=='unaccepted':a['actual_hub_state']='REWORK'
            if mutation=='cli':a['actual_cli_exit']=1
            if mutation=='provider':a['reviewer_provider']='codex'
            if mutation in ('executor','packet','script','package'):
                key={'executor':'publication_executor_sha256','packet':'execution_packet_sha256','script':'publish_script_sha256','package':'package_sha256'}[mutation];a[key]='0'*64
            if mutation=='image':a['image']='sha256:'+'d'*64
            if mutation=='old_task':a['execution_review_task_id']='task-c6511c146826432dbfc37acdcef563d0'
            if mutation=='self_review':response['reviewer']='native'
            if mutation=='error_count':args['error_count']=1
            if mutation=='note':args['note']='old execution packet'
            if mutation=='callback_task':response['id']='task-'+'d'*32
            with self.subTest(mutation=mutation),self.assertRaises(ValueError):p.validate_acceptance(a,e,'a'*64,'a'*64,'a'*64)
    def test_unaccepted_main_never_reaches_context_git_ssh(self):
        with patch.object(Path,'exists',return_value=False),patch.object(Path,'is_symlink',return_value=False),patch.object(r,'read',return_value={}),patch.object(r,'h',return_value='a'*64),patch.object(r,'context') as context,patch.object(subprocess,'check_output') as git,patch.object(subprocess,'run') as ssh:
            with self.assertRaises(ValueError):p.main()
        context.assert_not_called();git.assert_not_called();ssh.assert_not_called()
    def test_timeout_retains_partial_output_and_no_retry(self):
        e,*_=self.fixtures();a,_,_=self.approval()
        with tempfile.TemporaryDirectory() as temp:
            docs=Path(temp)
            with patch.object(r,'DOCS',docs),patch.object(r,'publication_boundary'),patch.object(r,'read',side_effect=[a,e]),patch.object(p,'validate_acceptance'),patch.object(r,'context',return_value=({},e,self.stage,{},self.preflight)),patch.object(r,'script',return_value='unit script'),patch.object(r,'packet',return_value=e),patch.object(Path,'read_bytes',return_value=b'unit script'),patch.object(r,'h',return_value='a'*64),patch.object(subprocess,'check_output',return_value=b''),patch.object(subprocess,'run',side_effect=subprocess.TimeoutExpired('unit SSH',600,output=b'partial log')) as ssh:
                with self.assertRaises(subprocess.TimeoutExpired):p.main()
            self.assertEqual((docs/'publish-log.txt').read_bytes(),b'partial log')
            self.assertEqual(json.loads((docs/'publish-exit.json').read_text())['actual_exit'],'timeout')
            ssh.assert_called_once()
    def test_source_or_regenerated_packet_drift_never_reaches_ssh(self):
        for mutation in ('source','packet'):
            e,*_=self.fixtures();a,_,_=self.approval()
            generated={} if mutation=='packet' else e
            with self.subTest(mutation=mutation),patch.object(Path,'exists',return_value=False),patch.object(Path,'is_symlink',return_value=False),patch.object(r,'read',side_effect=[a,e]),patch.object(p,'validate_acceptance'),patch.object(r,'context',return_value=({},e,self.stage,{},self.preflight)),patch.object(r,'script',return_value='unit script'),patch.object(r,'packet',return_value=generated),patch.object(Path,'read_bytes',return_value=b'unit script'),patch.object(r,'h',return_value='a'*64),patch.object(subprocess,'check_output',return_value=b'quizipedia/build_catalog.py\n') as git,patch.object(subprocess,'run') as ssh:
                with self.assertRaises(ValueError):p.main()
            ssh.assert_not_called()
            if mutation=='packet':git.assert_not_called()
            else:self.assertIn('quizipedia',git.call_args.args[0]);self.assertNotIn('study/check_reader.py',git.call_args.args[0])
    def test_optimized_mode_refused(self):
        for name in ('render_publication','publish_release'):
            result=subprocess.run([sys.executable,'-O','-B','-c','import '+name+'; '+name+'.main()'],cwd=Path(__file__).parent,capture_output=True)
            self.assertNotEqual(result.returncode,0);self.assertIn(b'optimized Python forbidden',result.stderr)

if __name__=='__main__':unittest.main()
