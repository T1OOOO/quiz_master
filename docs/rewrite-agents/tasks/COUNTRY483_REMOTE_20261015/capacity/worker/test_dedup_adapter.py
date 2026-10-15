"""Portable tests only; POSIX filesystem checks are in the rendered Linux fixture."""
import copy,json,subprocess,sys,tempfile,unittest
from pathlib import Path
from unittest.mock import patch
import dedup_adapter as d

class Portable(unittest.TestCase):
    @classmethod
    def setUpClass(cls):cls.plan=json.loads(d.PLAN.read_text())
    def test_exact_actual_plan214_29_185_52(self):
        self.assertEqual(len(d.validate_plan(self.plan)),214)
    def test_wrong_baseline_alias_day_keeper_or_hash_rejected(self):
        for change in ('baseline','day','keeper','hash','protected'):
            p=copy.deepcopy(self.plan)
            if change=='baseline':p['baseline_revision']=62
            if change=='day':p['pairs'][0]['alias']=p['pairs'][0]['alias'].replace('.10.13-','.10.15-')
            if change=='keeper':p['pairs'][0]['keeper']='../other.sqlite'
            if change=='hash':p['pairs'][0]['alias_metadata']['sha256']='0'*64
            if change=='protected':p['explicit_retention_names'][0]=p['pairs'][0]['alias']
            with self.subTest(change=change),self.assertRaises(ValueError):d.validate_plan(p)
    def test_changed_membership_metadata_state_or_reclaim_refused(self):
        for change in ('duplicate','preserved','mode','nlink','state','reclaim'):
            p=copy.deepcopy(self.plan)
            if change=='duplicate':p['pairs'][-1]=p['pairs'][0]
            if change=='preserved':p['preserved'].pop(next(iter(p['preserved'])))
            if change=='mode':p['pairs'][0]['alias_metadata']['mode']=0o644
            if change=='nlink':p['pairs'][0]['alias_metadata']['nlink']=2
            if change=='state':p['retained_unique_states']=51
            if change=='reclaim':p['expected_allocated_reclaim']-=4096
            with self.subTest(change=change),self.assertRaises(ValueError):d.validate_plan(p)
    def test_house_only_exact_boundary_change(self):
        house,guard=d.sources()
        old=(d.TASKS/'CAPACITY_RECOVERY_20261015/deduplicate.py').read_text()
        self.assertEqual(house,old.replace(r'quiz-2026\.10\.12-',r'quiz-2026\.10\.(?:13|14)-'))
        self.assertIn("h['version'] == 63",guard);self.assertIn(d.IMAGE,guard)
        self.assertNotIn("assert available * 5",guard)
        self.assertIn('before[kind] <= after[kind]',guard)
    def test_capacity_allows_below_floor_before_but_strict_reserve_after(self):
        before={'disk_available':20383481856,'disk_total':102417174528};d.check_capacity(before)
        target=before['disk_total']//5+1+1073741824
        with self.assertRaises(ValueError):d.check_capacity(before,{'disk_available':target-1,'disk_total':before['disk_total']})
        after={'disk_available':before['disk_available']+1408114688,'disk_total':before['disk_total']};d.check_capacity(before,after)
        after['disk_available']-=67108865
        with self.assertRaises(ValueError):d.check_capacity(before,after)
    def test_source_input_drift_and_existing_output_refused(self):
        with patch.object(d,'PLAN_SHA','0'*64),self.assertRaises(ValueError):d.render(d.WORK/'never-bad-plan')
        with patch.object(d,'PROTECTED_SHA','0'*64),self.assertRaises(ValueError):d.render(d.WORK/'never-bad-protection')
        with tempfile.TemporaryDirectory(dir=d.WORK) as tmp:
            with self.assertRaises(ValueError):d.render(Path(tmp))
        self.assertFalse((d.WORK/'never-bad-plan').exists())
    def test_render_syntax_and_no_execution_mode(self):
        with tempfile.TemporaryDirectory(dir=d.WORK) as tmp:
            p=Path(tmp)/'preview';proof=d.render(p);self.assertFalse(proof['actual_cleanup_performed'])
            body=(p/'deduplicate.sh').read_text();self.assertIn('flock -n 8',body);self.assertNotIn('helm upgrade',body)
            result=subprocess.run(['C:/Program Files/Git/bin/bash.exe','-n',str(p/'deduplicate.sh')],stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
            self.assertEqual(result.returncode,0,result.stdout.decode())
    def test_optimized_python_and_execute_refused(self):
        for args in (['-O','--output-root',str(d.WORK/'never-optimized')],['--execute']):
            cmd=[sys.executable,'-B']+(['-O'] if args[0]=='-O' else [])+[str(d.OWN/'dedup_adapter.py')]+(args[1:] if args[0]=='-O' else args)
            p=subprocess.run(cmd,stdout=subprocess.PIPE,stderr=subprocess.STDOUT);self.assertNotEqual(p.returncode,0)
        self.assertFalse((d.WORK/'never-optimized').exists())

if __name__=='__main__':unittest.main(verbosity=2)
