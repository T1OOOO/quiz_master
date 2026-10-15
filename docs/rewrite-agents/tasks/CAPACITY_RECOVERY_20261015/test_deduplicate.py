import hashlib,json,os,sqlite3,tempfile,unittest
from pathlib import Path
import deduplicate as d

class DedupTests(unittest.TestCase):
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory(prefix='quiz-dedup-fixture-');self.root=Path(self.temp.name);self.old=d.BACKUPS;d.BACKUPS=self.root
        self.keeper='quiz-2026.10.12-fixture.sqlite';self.alias='quiz-2026.10.12-fixture.restore-proof.sqlite'
        with sqlite3.connect(self.root/self.keeper) as db:db.execute('create table proof(value text)');db.execute('insert into proof values (?)',('fixture, not production',))
        raw=(self.root/self.keeper).read_bytes();(self.root/self.alias).write_bytes(raw)
        for p in self.root.iterdir():p.chmod(0o600)
        self.group={'keeper':self.keeper,'duplicates':[self.alias],'bytes':len(raw),'sha256':hashlib.sha256(raw).hexdigest()}
        self.plan={'schema_version':'qm-cold-backup-dedup/v1','groups':[self.group],'expected_files':2}
    def tearDown(self):d.BACKUPS=self.old;self.temp.cleanup()
    def test_identical_copy_removed_and_alias_restorable(self):
        receipt=d.run(self.plan);self.assertFalse((self.root/self.alias).exists());self.assertEqual(receipt['unique_states_retained'],1)
        item=receipt['removed_aliases'][0];raw=(self.root/item['restore_from']).read_bytes();self.assertEqual(hashlib.sha256(raw).hexdigest(),item['sha256'])
        (self.root/self.alias).write_bytes(raw);self.assertEqual((self.root/self.keeper).read_bytes(),(self.root/self.alias).read_bytes())
    def test_changed_second_group_aborts_before_any_unlink(self):
        other='quiz-2026.10.12-other.sqlite';(self.root/other).write_bytes(b'changed');(self.root/other).chmod(0o600)
        self.plan['groups'].append({**self.group,'keeper':other,'duplicates':[]});self.plan['expected_files']=3
        with self.assertRaises(ValueError):d.run(self.plan)
        self.assertTrue((self.root/self.alias).exists())
    def test_symlink_rejected(self):
        p=self.root/self.alias;p.unlink();p.symlink_to(self.root/self.keeper)
        with self.assertRaises(ValueError):d.run(self.plan)
        self.assertTrue(p.is_symlink())
    def test_current_and_traversal_names_rejected(self):
        for name in ['quiz-2026.10.15-reader-06dfa0b.sqlite','../quiz-2026.10.12-elsewhere.sqlite']:
            with self.subTest(name=name),self.assertRaises(ValueError):d.check(name,self.group)
        self.assertTrue((self.root/self.alias).exists())
    def test_live_journal_rejected(self):
        Path(str(self.root/self.alias)+'-wal').write_bytes(b'journal')
        with self.assertRaises(ValueError):d.run(self.plan)
        self.assertTrue((self.root/self.alias).exists())
    def test_duplicate_plan_name_rejected(self):
        self.group['duplicates'].append(self.keeper);self.plan['expected_files']=3
        with self.assertRaises(ValueError):d.run(self.plan)
        self.assertTrue((self.root/self.alias).exists())
    def test_nonprivate_copy_rejected(self):
        (self.root/self.alias).chmod(0o644)
        with self.assertRaises(ValueError):d.run(self.plan)
        self.assertTrue((self.root/self.alias).exists())
    def test_hard_link_rejected(self):
        p=self.root/self.alias;p.unlink();os.link(self.root/self.keeper,p)
        with self.assertRaises(ValueError):d.run(self.plan)
        self.assertTrue(p.exists())

if __name__=='__main__':unittest.main()
