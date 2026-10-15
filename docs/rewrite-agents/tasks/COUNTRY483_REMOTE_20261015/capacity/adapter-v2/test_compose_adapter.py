import ast,subprocess,tempfile,unittest
from pathlib import Path
from unittest.mock import patch
import compose_adapter as c

class Composition(unittest.TestCase):
    def test_three_exact_contexts_only_and_guard_unchanged(self):
        v1,house,guard,closed_house,closed_guard,_,_=c.inputs()
        self.assertEqual(len(c.connect_expressions(house)),1);self.assertEqual(len(c.connect_expressions(guard)),2)
        self.assertEqual(c.connect_expressions(closed_house),[]);self.assertEqual(c.connect_expressions(closed_guard),[])
        production,fixture,proof=c.compose()
        self.assertEqual(production,c.V1.read_text().replace(guard,closed_guard).replace('house_source='+repr(house),'house_source='+repr(closed_house)))
        self.assertNotEqual(proof['original_house_sha256'],proof['patched_house_sha256'])
        old=ast.parse(c.body(c.V1.read_text(),'COUNTRY483_DEDUP'));new=ast.parse(c.body(production,'COUNTRY483_DEDUP'))
        for name in ('run_exact','no_process_use','verify_entry','verify_inventory','verify_protected','check_capacity','validate_plan','loaded_images','images_preserved'):
            first=next(n for n in old.body if isinstance(n,ast.FunctionDef) and n.name==name)
            second=next(n for n in new.body if isinstance(n,ast.FunctionDef) and n.name==name)
            self.assertEqual(ast.dump(first),ast.dump(second),name)
        self.assertEqual(len(proof['case_names']),16)
    def test_every_pinned_input_and_context_count_drift_refused(self):
        for path in c.PINS:
            with self.subTest(path=path),patch.dict(c.PINS,{path:'0'*64}),self.assertRaises(RuntimeError):c.compose()
        with self.assertRaises(RuntimeError):c.close_contexts('pass',1)
    def test_render_both_shell_syntax_and_fresh_output(self):
        with tempfile.TemporaryDirectory(dir=c.WORK) as tmp:
            out=Path(tmp)/'preview';receipt=c.render(out);self.assertFalse(receipt['actual_cleanup_performed'])
            for name in ('deduplicate-v2.sh','linux-integration-v2.sh'):
                p=subprocess.run(['C:/Program Files/Git/bin/bash.exe','-n',str(out/name)],stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
                self.assertEqual(p.returncode,0,p.stdout.decode())
            with self.assertRaises(RuntimeError):c.render(out)

if __name__=='__main__':unittest.main(verbosity=2)
