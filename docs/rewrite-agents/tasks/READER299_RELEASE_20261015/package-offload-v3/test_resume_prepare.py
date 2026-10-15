"""Offline continuation checks; no Git, SSH, builds or real DB calls."""
import copy,json,re,subprocess,sys,tempfile,unittest,shutil
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch,MagicMock
import resume_prepare as resume


class ResumeTests(unittest.TestCase):
    def bindings(self):return resume.read(resume.DOCS/'failed-stage-bindings.json')

    def test_actual_failure_and_external_source_hashes_bind_without_git(self):
        source=resume.verify_external_sources()
        runtime=resume.verify_failure(self.bindings(),source)
        self.assertEqual(runtime['image_id'],resume.CANDIDATE)
        self.assertEqual(runtime['reader']['articles'],299)

    def test_wrong_failed_run_image_or_evidence_rejected(self):
        source=resume.load_source_a();bindings=self.bindings()
        for key,value in [('failed_run','wrong'),('candidate_image_id','sha256:'+'0'*64),('build_id','wrong')]:
            bad=copy.deepcopy(bindings);bad[key]=value
            with self.subTest(key=key),self.assertRaises(AssertionError):resume.verify_failure(bad,source)
        bad=copy.deepcopy(bindings);bad['failed_local_evidence_sha256']['remote-prepare-log.txt']='0'*64
        with self.assertRaises(AssertionError):resume.verify_failure(bad,source)
        with tempfile.TemporaryDirectory() as d:
            root=Path(d)
            for name in bindings['failed_local_evidence_sha256']:shutil.copyfile(resume.FAILED/name,root/name)
            (root/'remote-prepare-exit.json').write_text('{"actual_exit":0}')
            bad=copy.deepcopy(bindings);bad['failed_local_evidence_sha256']['remote-prepare-exit.json']=resume.execute.digest(root/'remote-prepare-exit.json')
            with patch.object(resume,'FAILED',root),self.assertRaises(AssertionError):resume.verify_failure(bad,source)

    def test_guard_and_script_keep_strict_gate_package_candidate_and_old_logs(self):
        source=resume.load_source_a();bindings=self.bindings()
        strict=source.preflight_shell()
        guard,script=resume.render_script(bindings,strict,'a'*32)
        self.assertIn('*5>usage.f_blocks',strict)
        self.assertIn(resume.CANDIDATE,guard);self.assertIn(resume.PACKAGE_SHA,guard)
        self.assertIn('sha256sum -c checksums.txt',guard)
        self.assertIn('test ! -e /var/lib/rancher/k3s/agent/images/',guard)
        self.assertIn('bash cutover.sh prepare',script)
        self.assertIn('set -o noclobber',script)
        self.assertIn('tee resume-'+('a'*32)+'.log',script)
        self.assertNotIn('tee prepare.log',script)
        self.assertNotIn('scp ',script);self.assertNotIn('tar -x',script);self.assertNotIn('helm upgrade',script)
        self.assertIn('QUIZ_PRESERVE_FAILED',script)
        for sha in bindings['files'].values():self.assertIn(sha,guard);self.assertIn(sha,script)
        for body in (guard,script):
            result=subprocess.run(['C:/Program Files/Git/bin/bash.exe','-n'],input=body.encode(),capture_output=True)
            self.assertEqual(result.returncode,0,result.stderr.decode())
        for body in re.findall(r"<<'[^']+'\n(.*?)\n[A-Z_]+(?:\n|$)",script,re.S):compile(body,'rendered-resume-guard','exec')
        with self.assertRaises(AssertionError):resume.render_script(bindings,strict,'../wrong')

    def test_changed_external_source_set_fails_before_operations(self):
        real=resume.read
        def read(path):return {} if Path(path).name=='source-input-sha256.json' else real(path)
        with patch.object(resume,'read',side_effect=read),self.assertRaises(AssertionError):resume.verify_external_sources()

    def test_unaccepted_resume_and_existing_evidence_fail_before_ssh(self):
        bindings=self.bindings();source=MagicMock();source.preflight_shell.return_value='true'
        with tempfile.TemporaryDirectory() as d:
            output=Path(d)/'fresh'
            args=['resume','--resume','--evidence-dir',str(output)]
            with patch.object(resume.sys,'argv',args),patch.object(resume,'validate',return_value=(source,{},bindings)),patch.object(resume.execute,'validate_inputs',side_effect=AssertionError('not accepted')),patch.object(resume.subprocess,'run') as ssh:
                with self.assertRaises(AssertionError):resume.main()
                ssh.assert_not_called();self.assertFalse(output.exists())
            with patch.object(resume.sys,'argv',['resume','--resume','--evidence-dir',str(resume.REPO/'.run')]),patch.object(resume,'validate',return_value=(source,{},bindings)),patch.object(resume.execute,'validate_inputs'),patch.object(resume.subprocess,'run') as ssh:
                with self.assertRaises(AssertionError):resume.main()
                ssh.assert_not_called()

    def test_resume_timeout_keeps_partial_output_and_timeout_exit_without_collector(self):
        bindings=self.bindings();source=MagicMock();source.preflight_shell.return_value='true'
        source.legacy_remote.return_value=SimpleNamespace(SSH_KEY='fixture-key',SSH_TARGET='fixture-target')
        with tempfile.TemporaryDirectory() as d:
            # Map the allowed evidence boundary into this disposable fixture.
            repo=Path(d).resolve();(repo/'.run').mkdir();output=repo/'.run/fresh-resume'
            timeout=subprocess.TimeoutExpired(['fixture ssh'],600,output=b'actual partial combined stdout')
            with patch.object(resume,'REPO',repo),patch.object(resume.sys,'argv',['resume','--resume','--evidence-dir',str(output)]),patch.object(resume,'validate',return_value=(source,{},bindings)),patch.object(resume.execute,'validate_inputs'),patch.object(resume.subprocess,'run',side_effect=[SimpleNamespace(returncode=0,stdout=b'guard passed'),timeout]) as ssh:
                with self.assertRaises(subprocess.TimeoutExpired):resume.main()
            self.assertEqual(ssh.call_count,2)
            self.assertEqual((output/'remote-resume-log.txt').read_bytes(),b'actual partial combined stdout')
            self.assertEqual(resume.read(output/'remote-resume-exit.json'),{'actual_exit':'timeout'})
            self.assertTrue((output/'remote-resume-script.sh').is_file())
            self.assertFalse((output/'remote-preparation-verification.json').exists())
            source.collection_script.assert_not_called()


if __name__=='__main__':unittest.main()
