import ast,subprocess,tempfile,unittest
from pathlib import Path
from unittest.mock import patch
import assemble_fixture as a

class FixtureOnly(unittest.TestCase):
    def test_exact_two_replacements_preserve_all14_and_guards(self):
        before=a.OLD_SCRIPT.read_text();after=a.assemble()
        expected=before.replace(a.BEFORE,a.AFTER).replace('import types,sys,unittest,tempfile,sqlite3,json,os,hashlib,stat',
                                                       'import types,sys,unittest,tempfile,sqlite3,json,os,hashlib,stat,contextlib')
        self.assertEqual(after,expected);self.assertEqual(len(a.test_names(after)),14)
        old=ast.parse(a.body(before));new=ast.parse(a.body(after))
        for name in ('require','verify_entry','no_process_use'):
            first=next(n for n in old.body if isinstance(n,ast.FunctionDef) and n.name==name)
            second=next(n for n in new.body if isinstance(n,ast.FunctionDef) and n.name==name)
            self.assertEqual(ast.dump(first),ast.dump(second))
    def test_each_accepted_binding_drift_refused(self):
        for path in a.PINS:
            with self.subTest(path=path),patch.dict(a.PINS,{path:'0'*64}),self.assertRaises(RuntimeError):a.assemble()
    def test_render_syntax_and_existing_output_refused(self):
        with tempfile.TemporaryDirectory(dir=a.WORK) as tmp:
            out=Path(tmp)/'preview';receipt=a.render(out)
            self.assertEqual(receipt['linux_tests'],'PENDING_ROOT_EXECUTION')
            result=subprocess.run(['C:/Program Files/Git/bin/bash.exe','-n',str(out/'linux-fixture-v2.sh')],stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
            self.assertEqual(result.returncode,0,result.stdout.decode())
            with self.assertRaises(RuntimeError):a.render(out)

if __name__=='__main__':unittest.main(verbosity=2)
