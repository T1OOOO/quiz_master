import copy,json,unittest
from unittest import mock
import remaining_adapter as m

class RemainingTests(unittest.TestCase):
    def setUp(self):self.plan=json.loads(m.PLAN.read_text())
    def rejects(self,mutate):
        p=copy.deepcopy(self.plan);mutate(p)
        with self.assertRaises((ValueError,KeyError,TypeError)):m.validate_plan(p)
    def test_actual_plan(self):
        entries=m.validate_plan(self.plan)
        self.assertEqual(len(entries),185)
        self.assertEqual(len(m.selected_names(self.plan)),158)
    def test_old_schema(self):self.rejects(lambda p:p.update(schema_version='qm-country483-exact-backup-dedup/v1'))
    def test_duplicate_alias(self):self.rejects(lambda p:p['groups'][0]['aliases'].append(p['groups'][0]['aliases'][0]))
    def test_keeper_alias(self):self.rejects(lambda p:p['groups'][0]['aliases'].__setitem__(0,p['groups'][0]['keeper']))
    def test_retention(self):self.rejects(lambda p:p['explicit_retention_names'].__setitem__(0,p['groups'][0]['aliases'][0]))
    def test_missing_member(self):self.rejects(lambda p:p['entries'].pop(p['groups'][0]['aliases'][0]))
    def test_hash(self):self.rejects(lambda p:p['groups'][0].update(sha256='0'*64))
    def test_fingerprint(self):self.rejects(lambda p:p['entries'][p['groups'][0]['aliases'][0]].update(nlink=2))
    def test_path(self):self.rejects(lambda p:p['entries'][p['groups'][0]['aliases'][0]].update(path='/tmp/escape.sqlite'))
    def test_preserved_changed(self):self.rejects(lambda p:p['preserved'][p['groups'][0]['keeper']].update(ino=999))
    def test_capacity_policy(self):self.rejects(lambda p:p.update(maximum_concurrent_growth_bytes=1073741825))
    def test_previous_failure(self):self.rejects(lambda p:p.update(previous_actual_exit=0))
    def test_execution_authority(self):self.rejects(lambda p:p.update(execution_authorized_by_this_plan=True))
    def test_boundary_and_growth(self):
        total=102417174528;floor=total//5+1+2*1073741824;reclaim=4795174912
        before=dict(disk_total=total,disk_available=floor-reclaim)
        m.check_capacity(before,dict(disk_total=total,disk_available=floor))
        with self.assertRaises(ValueError):m.check_capacity(before,dict(disk_total=total,disk_available=floor-1))
        before['disk_available']=floor
        m.check_capacity(before,dict(disk_total=total,disk_available=floor+reclaim-1073741824))
        with self.assertRaises(ValueError):m.check_capacity(before,dict(disk_total=total,disk_available=floor+reclaim-1073741825))
    def test_exact_allowlist(self):
        house,_,proof=m.dependencies(self.plan)
        ns={};exec(house,ns)
        self.assertEqual(proof['owned_contexts_closed'],{'house':1,'preflight':2})
        self.assertTrue(all(ns['NAME'].fullmatch(n) for n in m.selected_names(self.plan)))
        self.assertIsNone(ns['NAME'].fullmatch('quiz-2026.10.11-unlisted.sqlite'))
        self.assertIsNone(ns['NAME'].fullmatch('../'+m.selected_names(self.plan)[0]))
    def test_input_hash_refusal_before_output(self):
        with mock.patch.object(m,'sha',return_value='0'*64):
            with self.assertRaisesRegex(ValueError,'Root immutable input'):m.render(m.WORK/'never-created')
        self.assertFalse((m.WORK/'never-created').exists())
    def test_composer_hash_refusal(self):
        with mock.patch.object(m,'sha',return_value='0'*64):
            with self.assertRaisesRegex(ValueError,'immutable lifetime composer'):m.dependencies(self.plan)
    def drive_multialias(self,corrupt=False):
        house,_,_=m.dependencies(self.plan)
        groups=copy.deepcopy([g for g in self.plan['groups'] if len(g['aliases'])>=2][:2])
        for g in groups:g['aliases']=g['aliases'][:2]
        names=[n for g in groups for n in [g['keeper'],*g['aliases']]]
        entries={n:self.plan['entries'][n] for n in names};events=[]
        class CheckedPath:
            def __init__(self,name):self.name=name
            def as_uri(self):return 'file:///fixture/'+self.name
            def unlink(self):events.append(('unlink',self.name))
        class Database:
            def execute(self,sql):return self
            def fetchone(self):return ('ok',)
            def close(self):events.append(('close',None))
        def verify(path,entry):
            events.append(('verify',path.name))
            if corrupt and path.name==names[-1]:raise ValueError('last group corrupt')
            return CheckedPath(path.name)
        def snapshot():
            self.assertEqual(len([e for e in events if e[0]=='unlink']),0)
            self.assertTrue(all(('verify',n) in events for n in names))
            self.assertEqual(len([e for e in events if e[0]=='close']),2)
            events.append(('snapshot',None))
        with mock.patch.multiple(m,parent_marker=lambda root:{},verify_entry=verify,no_process_use=lambda root:None,create=True), \
             mock.patch.object(m,'BACKUPS',m.WORK.resolve()),mock.patch.object(m.os,'geteuid',return_value=0,create=True), \
             mock.patch.object(m.sqlite3,'connect',return_value=Database()):
            if corrupt:
                with self.assertRaisesRegex(ValueError,'last group corrupt'):m.execute_groups(entries,groups,{},house,snapshot)
                self.assertFalse(any(e[0]=='unlink' for e in events))
            else:
                result=m.execute_groups(entries,groups,{},house,snapshot)
                self.assertEqual(len(result['removed_aliases']),4)
                self.assertEqual(len([e for e in events if e[0]=='snapshot']),1)
    def test_multialias_closed_validation_order(self):self.drive_multialias()
    def test_last_group_failure_before_any_unlink(self):self.drive_multialias(True)

if __name__=='__main__':unittest.main()
