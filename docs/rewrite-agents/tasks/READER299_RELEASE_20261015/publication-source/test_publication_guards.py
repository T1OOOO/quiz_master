from pathlib import Path
import importlib.util,json,subprocess,sys,unittest
from unittest.mock import patch

ROOT=Path(__file__).parent

class PublicationGuards(unittest.TestCase):
    def test_renderer_import_does_not_render_without_inputs(self):
        spec=importlib.util.spec_from_file_location('reader299_publication_renderer',ROOT/'render_publication.py')
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

    def test_existing_execution_logs_refuse_a_repeat_before_receipts_or_ssh(self):
        source=ROOT/'publish_release.py'
        payload=source.read_text()
        with patch.object(Path,'exists',return_value=True),patch.object(Path,'read_bytes') as read,patch.object(subprocess,'run') as ssh:
            with self.assertRaisesRegex(RuntimeError,'existing publication evidence'):
                exec(compile(payload,str(source),'exec'),{'__name__':'__main__','__file__':str(source)})
        read.assert_not_called();ssh.assert_not_called()

if __name__=='__main__':unittest.main()
