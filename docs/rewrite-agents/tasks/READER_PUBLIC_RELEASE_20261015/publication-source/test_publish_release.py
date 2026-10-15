"""Exercise the executor's actual failure path without SSH or production writes."""
import ast,json,subprocess,tempfile,unittest
from pathlib import Path
from unittest.mock import Mock

class EvidenceTests(unittest.TestCase):
 def test_success_failure_and_timeout_persist_output(self):
  source=Path(__file__).with_name('publish_release.py').read_text()
  tree=ast.parse(source)
  start=next(i for i,n in enumerate(tree.body) if isinstance(n,ast.Assign) and any(isinstance(t,ast.Name) and t.id=='script' for t in n.targets))
  code=compile(ast.Module(body=tree.body[start:],type_ignores=[]),'<actual executor tail>','exec')
  for expected in [0,1,'timeout']:
   with self.subTest(expected=expected),tempfile.TemporaryDirectory() as folder:
    d=Path(folder);(d/'publish-preview.sh').write_bytes(b'fixture')
    run=Mock()
    if expected=='timeout':run.side_effect=subprocess.TimeoutExpired('ssh',600,output=b'rollback in progress')
    else:run.return_value=subprocess.CompletedProcess('ssh',expected,b'remote output')
    fake=Mock(run=run,PIPE=subprocess.PIPE,STDOUT=subprocess.STDOUT,TimeoutExpired=subprocess.TimeoutExpired)
    env={'d':d,'subprocess':fake,'json':json}
    if expected==0:exec(code,env)
    else:
     with self.assertRaises(subprocess.TimeoutExpired if expected=='timeout' else AssertionError):exec(code,env)
    self.assertEqual(run.call_args.kwargs['timeout'],600)
    self.assertEqual(json.loads((d/'publish-exit.json').read_text())['actual_exit'],expected)
    self.assertEqual((d/'publish-log.txt').read_bytes(),b'rollback in progress' if expected=='timeout' else b'remote output')

if __name__=='__main__':unittest.main()
