set -euo pipefail
unset PYTHONOPTIMIZE PYTHONSTARTUP
python3 - <<'COUNTRY483_FIXTURE'
__name__='qm_isolated_fixture'
import types,sys,unittest,tempfile,sqlite3,json,os,hashlib,stat,contextlib
from pathlib import Path
module=types.ModuleType("deduplicate")
exec('import contextlib\n"""Finite, reviewed deduplication of cold October 12 Quiz Master SQLite copies."""\nfrom pathlib import Path\nimport hashlib,json,os,re,sqlite3,stat\n\nBACKUPS=Path(\'/opt/quiz-master/backups\')\nNAME=re.compile(r\'quiz-2026\\.10\\.(?:13|14)-[A-Za-z0-9._-]+\\.sqlite\')\n\ndef check(name,group):\n    if not isinstance(name,str) or not NAME.fullmatch(name):raise ValueError(\'cold backup name required\')\n    p=BACKUPS/name;s=p.lstat()\n    if not stat.S_ISREG(s.st_mode) or stat.S_IMODE(s.st_mode)!=0o600 or s.st_nlink!=1 or s.st_uid!=os.geteuid():raise ValueError(\'private owned regular single-link backup required\')\n    if any(Path(str(p)+suffix).exists() for suffix in [\'-wal\',\'-shm\',\'-journal\']):raise ValueError(\'backup has live journal\')\n    h=hashlib.sha256()\n    with p.open(\'rb\') as f:\n        opened=os.fstat(f.fileno())\n        if (opened.st_dev,opened.st_ino)!=(s.st_dev,s.st_ino):raise ValueError(\'backup identity changed\')\n        while chunk:=f.read(1048576):h.update(chunk)\n    after=p.lstat()\n    fields=lambda x:(x.st_dev,x.st_ino,x.st_size,x.st_mtime_ns,x.st_mode,x.st_nlink)\n    if fields(s)!=fields(after) or s.st_size!=group[\'bytes\'] or h.hexdigest()!=group[\'sha256\']:raise ValueError(\'backup bytes or identity changed\')\n    return p\n\ndef run(plan):\n    if BACKUPS.resolve()!=BACKUPS or plan[\'schema_version\']!=\'qm-cold-backup-dedup/v1\':raise ValueError(\'backup boundary/schema differs\')\n    groups=plan[\'groups\'];names=[n for g in groups for n in [g[\'keeper\'],*g[\'duplicates\']]]\n    if len(names)!=len(set(names)) or len(names)!=plan[\'expected_files\']:raise ValueError(\'duplicate/changed plan names\')\n    # Validate the entire frozen plan before the first unlink.\n    for group in groups:\n        for name in [group[\'keeper\'],*group[\'duplicates\']]:check(name,group)\n        with contextlib.closing(sqlite3.connect(check(group[\'keeper\'],group).as_uri()+\'?mode=ro&immutable=1\',uri=True)) as db:\n            if db.execute(\'pragma integrity_check\').fetchone()!=(\'ok\',):raise ValueError(\'keeper integrity failed\')\n    removed=[]\n    for group in groups:\n        for name in group[\'duplicates\']:\n            check(group[\'keeper\'],group)\n            check(name,group).unlink()\n            removed.append({\'removed\':name,\'restore_from\':group[\'keeper\'],\'sha256\':group[\'sha256\'],\'bytes\':group[\'bytes\']})\n            print(json.dumps(removed[-1]),flush=True)\n    for group in groups:check(group[\'keeper\'],group)\n    return {\'removed_aliases\':removed,\'unique_states_retained\':len(groups),\'logical_bytes_removed\':sum(x[\'bytes\'] for x in removed),\'method\':\'Only byte-identical cold copies removed; recreate any old filename by copying its retained private raw SQLite keeper.\'}\n',module.__dict__)
sys.modules["deduplicate"]=module
def require(ok,message):
    if not ok:raise ValueError(message)

def verify_entry(path,entry):
    require(os.name=='posix' and hasattr(os,'O_NOFOLLOW'),'POSIX no-follow verification required')
    path=Path(path);st=path.lstat()
    def marker(s):
        value=dict(bytes=s.st_size,dev=s.st_dev,ino=s.st_ino,mtime_ns=s.st_mtime_ns,mode=stat.S_IMODE(s.st_mode),uid=s.st_uid,gid=s.st_gid,nlink=s.st_nlink)
        if 'allocated_bytes' in entry:value['allocated_bytes']=s.st_blocks*512
        return value
    expected={k:entry[k] for k in marker(st)}
    require(stat.S_ISREG(st.st_mode) and st.st_nlink==1 and marker(st)==expected,'backup/protected fingerprint changed')
    for suffix in ('-wal','-shm','-journal'):require(not Path(str(path)+suffix).exists() and not Path(str(path)+suffix).is_symlink(),'live journal exists')
    fd=os.open(path,os.O_RDONLY|os.O_NOFOLLOW)
    with os.fdopen(fd,'rb') as stream:
        require(marker(os.fstat(stream.fileno()))==expected,'opened identity changed')
        digest=hashlib.file_digest(stream,'sha256').hexdigest()
        require(marker(os.fstat(stream.fileno()))==expected,'identity changed during read')
    require(marker(path.lstat())==expected and not path.is_symlink() and digest==entry['sha256'],'file hash/identity changed')
    return path

def no_process_use(root):
    prefix=str(root).encode()
    for proc in Path('/proc').iterdir():
        if not proc.name.isdecimal():continue
        try:
            require(not any(prefix in arg for arg in (proc/'cmdline').read_bytes().split(b'\0')),'backup path in active process command')
            for link in (proc/'fd').iterdir():
                try:target=os.readlink(link)
                except FileNotFoundError:continue
                require(not target.startswith(str(root)+'/'),'backup open by active process')
        except (FileNotFoundError,ProcessLookupError):continue

import hashlib,json,os,sqlite3,tempfile,unittest
from pathlib import Path
import deduplicate as d

class DedupTests(unittest.TestCase):
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory(prefix='quiz-dedup-fixture-');self.root=Path(self.temp.name);self.old=d.BACKUPS;d.BACKUPS=self.root
        self.keeper='quiz-2026.10.13-fixture.sqlite';self.alias='quiz-2026.10.13-fixture.restore-proof.sqlite'
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
        other='quiz-2026.10.13-other.sqlite';(self.root/other).write_bytes(b'changed');(self.root/other).chmod(0o600)
        self.plan['groups'].append({**self.group,'keeper':other,'duplicates':[]});self.plan['expected_files']=3
        with self.assertRaises(ValueError):d.run(self.plan)
        self.assertTrue((self.root/self.alias).exists())
    def test_symlink_rejected(self):
        p=self.root/self.alias;p.unlink();p.symlink_to(self.root/self.keeper)
        with self.assertRaises(ValueError):d.run(self.plan)
        self.assertTrue(p.is_symlink())
    def test_current_and_traversal_names_rejected(self):
        for name in ['quiz-2026.10.15-reader-06dfa0b.sqlite','../quiz-2026.10.13-elsewhere.sqlite']:
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

"""Pending Linux-only temporary SQLite tests. Never use production backup paths."""
class FingerprintTests(unittest.TestCase):
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory(prefix='qm-exact29-fixture-');self.root=Path(self.temp.name)
        self.path=self.root/'quiz-2026.10.13-fixture.sqlite'
        with contextlib.closing(sqlite3.connect(self.path)) as db:db.execute('create table fixture(value text)');db.commit()
        self.path.chmod(0o600);s=self.path.stat()
        self.meta=dict(bytes=s.st_size,allocated_bytes=s.st_blocks*512,dev=s.st_dev,ino=s.st_ino,mtime_ns=s.st_mtime_ns,
                       mode=0o600,uid=s.st_uid,gid=s.st_gid,nlink=1,sha256=hashlib.sha256(self.path.read_bytes()).hexdigest())
    def tearDown(self):self.temp.cleanup()
    def test_positive_fingerprint(self):verify_entry(self.path,self.meta)
    def test_hash_metadata_and_private_mode_drift(self):
        for field,value in [('sha256','0'*64),('mtime_ns',1),('ino',1),('mode',0o644),('allocated_bytes',0)]:
            bad=dict(self.meta);bad[field]=value
            with self.subTest(field=field),self.assertRaises(ValueError):verify_entry(self.path,bad)
    def test_journal_blocks(self):
        Path(str(self.path)+'-wal').write_bytes(b'fixture')
        with self.assertRaises(ValueError):verify_entry(self.path,self.meta)
    def test_hardlink_blocks(self):
        os.link(self.path,self.root/'fixture-link')
        with self.assertRaises(ValueError):verify_entry(self.path,self.meta)
    def test_symlink_blocks(self):
        other=self.root/'other';self.path.rename(other);self.path.symlink_to(other)
        with self.assertRaises(ValueError):verify_entry(self.path,self.meta)
    def test_process_open_file_blocks(self):
        no_process_use(self.root)
        with self.path.open('rb') as stream:
            with self.assertRaises(ValueError):no_process_use(self.root)


ORIGINAL_HOUSE='"""Finite, reviewed deduplication of cold October 12 Quiz Master SQLite copies."""\nfrom pathlib import Path\nimport hashlib,json,os,re,sqlite3,stat\n\nBACKUPS=Path(\'/opt/quiz-master/backups\')\nNAME=re.compile(r\'quiz-2026\\.10\\.(?:13|14)-[A-Za-z0-9._-]+\\.sqlite\')\n\ndef check(name,group):\n    if not isinstance(name,str) or not NAME.fullmatch(name):raise ValueError(\'cold backup name required\')\n    p=BACKUPS/name;s=p.lstat()\n    if not stat.S_ISREG(s.st_mode) or stat.S_IMODE(s.st_mode)!=0o600 or s.st_nlink!=1 or s.st_uid!=os.geteuid():raise ValueError(\'private owned regular single-link backup required\')\n    if any(Path(str(p)+suffix).exists() for suffix in [\'-wal\',\'-shm\',\'-journal\']):raise ValueError(\'backup has live journal\')\n    h=hashlib.sha256()\n    with p.open(\'rb\') as f:\n        opened=os.fstat(f.fileno())\n        if (opened.st_dev,opened.st_ino)!=(s.st_dev,s.st_ino):raise ValueError(\'backup identity changed\')\n        while chunk:=f.read(1048576):h.update(chunk)\n    after=p.lstat()\n    fields=lambda x:(x.st_dev,x.st_ino,x.st_size,x.st_mtime_ns,x.st_mode,x.st_nlink)\n    if fields(s)!=fields(after) or s.st_size!=group[\'bytes\'] or h.hexdigest()!=group[\'sha256\']:raise ValueError(\'backup bytes or identity changed\')\n    return p\n\ndef run(plan):\n    if BACKUPS.resolve()!=BACKUPS or plan[\'schema_version\']!=\'qm-cold-backup-dedup/v1\':raise ValueError(\'backup boundary/schema differs\')\n    groups=plan[\'groups\'];names=[n for g in groups for n in [g[\'keeper\'],*g[\'duplicates\']]]\n    if len(names)!=len(set(names)) or len(names)!=plan[\'expected_files\']:raise ValueError(\'duplicate/changed plan names\')\n    # Validate the entire frozen plan before the first unlink.\n    for group in groups:\n        for name in [group[\'keeper\'],*group[\'duplicates\']]:check(name,group)\n        with sqlite3.connect(check(group[\'keeper\'],group).as_uri()+\'?mode=ro&immutable=1\',uri=True) as db:\n            if db.execute(\'pragma integrity_check\').fetchone()!=(\'ok\',):raise ValueError(\'keeper integrity failed\')\n    removed=[]\n    for group in groups:\n        for name in group[\'duplicates\']:\n            check(group[\'keeper\'],group)\n            check(name,group).unlink()\n            removed.append({\'removed\':name,\'restore_from\':group[\'keeper\'],\'sha256\':group[\'sha256\'],\'bytes\':group[\'bytes\']})\n            print(json.dumps(removed[-1]),flush=True)\n    for group in groups:check(group[\'keeper\'],group)\n    return {\'removed_aliases\':removed,\'unique_states_retained\':len(groups),\'logical_bytes_removed\':sum(x[\'bytes\'] for x in removed),\'method\':\'Only byte-identical cold copies removed; recreate any old filename by copying its retained private raw SQLite keeper.\'}\n'
CLOSED_HOUSE='import contextlib\n"""Finite, reviewed deduplication of cold October 12 Quiz Master SQLite copies."""\nfrom pathlib import Path\nimport hashlib,json,os,re,sqlite3,stat\n\nBACKUPS=Path(\'/opt/quiz-master/backups\')\nNAME=re.compile(r\'quiz-2026\\.10\\.(?:13|14)-[A-Za-z0-9._-]+\\.sqlite\')\n\ndef check(name,group):\n    if not isinstance(name,str) or not NAME.fullmatch(name):raise ValueError(\'cold backup name required\')\n    p=BACKUPS/name;s=p.lstat()\n    if not stat.S_ISREG(s.st_mode) or stat.S_IMODE(s.st_mode)!=0o600 or s.st_nlink!=1 or s.st_uid!=os.geteuid():raise ValueError(\'private owned regular single-link backup required\')\n    if any(Path(str(p)+suffix).exists() for suffix in [\'-wal\',\'-shm\',\'-journal\']):raise ValueError(\'backup has live journal\')\n    h=hashlib.sha256()\n    with p.open(\'rb\') as f:\n        opened=os.fstat(f.fileno())\n        if (opened.st_dev,opened.st_ino)!=(s.st_dev,s.st_ino):raise ValueError(\'backup identity changed\')\n        while chunk:=f.read(1048576):h.update(chunk)\n    after=p.lstat()\n    fields=lambda x:(x.st_dev,x.st_ino,x.st_size,x.st_mtime_ns,x.st_mode,x.st_nlink)\n    if fields(s)!=fields(after) or s.st_size!=group[\'bytes\'] or h.hexdigest()!=group[\'sha256\']:raise ValueError(\'backup bytes or identity changed\')\n    return p\n\ndef run(plan):\n    if BACKUPS.resolve()!=BACKUPS or plan[\'schema_version\']!=\'qm-cold-backup-dedup/v1\':raise ValueError(\'backup boundary/schema differs\')\n    groups=plan[\'groups\'];names=[n for g in groups for n in [g[\'keeper\'],*g[\'duplicates\']]]\n    if len(names)!=len(set(names)) or len(names)!=plan[\'expected_files\']:raise ValueError(\'duplicate/changed plan names\')\n    # Validate the entire frozen plan before the first unlink.\n    for group in groups:\n        for name in [group[\'keeper\'],*group[\'duplicates\']]:check(name,group)\n        with contextlib.closing(sqlite3.connect(check(group[\'keeper\'],group).as_uri()+\'?mode=ro&immutable=1\',uri=True)) as db:\n            if db.execute(\'pragma integrity_check\').fetchone()!=(\'ok\',):raise ValueError(\'keeper integrity failed\')\n    removed=[]\n    for group in groups:\n        for name in group[\'duplicates\']:\n            check(group[\'keeper\'],group)\n            check(name,group).unlink()\n            removed.append({\'removed\':name,\'restore_from\':group[\'keeper\'],\'sha256\':group[\'sha256\'],\'bytes\':group[\'bytes\']})\n            print(json.dumps(removed[-1]),flush=True)\n    for group in groups:check(group[\'keeper\'],group)\n    return {\'removed_aliases\':removed,\'unique_states_retained\':len(groups),\'logical_bytes_removed\':sum(x[\'bytes\'] for x in removed),\'method\':\'Only byte-identical cold copies removed; recreate any old filename by copying its retained private raw SQLite keeper.\'}\n'
OLD_PREFLIGHT_CONTEXTS=["sqlite3.connect('file:/var/lib/rancher/k3s/storage/pvc-7fc2428f-4146-4c78-a26d-2347d9f3b7bf_quiz-master_quiz-data/quiz.db?mode=ro', uri=True)", "sqlite3.connect('file:' + backup + '?mode=ro', uri=True)"]
NEW_PREFLIGHT_CONTEXTS=["contextlib.closing(sqlite3.connect('file:/var/lib/rancher/k3s/storage/pvc-7fc2428f-4146-4c78-a26d-2347d9f3b7bf_quiz-master_quiz-data/quiz.db?mode=ro', uri=True))", "contextlib.closing(sqlite3.connect('file:' + backup + '?mode=ro', uri=True))"]
"""Two additional isolated cases; all SQLite paths are TemporaryDirectory fixtures."""
from types import SimpleNamespace

class LifetimeIntegrationTests(unittest.TestCase):
    def metadata(self,path):
        s=path.stat()
        return dict(bytes=s.st_size,allocated_bytes=s.st_blocks*512,dev=s.st_dev,ino=s.st_ino,mtime_ns=s.st_mtime_ns,
                    mode=0o600,uid=s.st_uid,gid=s.st_gid,nlink=1,sha256=hashlib.sha256(path.read_bytes()).hexdigest())
    def test_real_two_group_process_guard_red_green(self):
        with tempfile.TemporaryDirectory(prefix='qm-house-two-group-') as tmp:
            root=Path(tmp);groups=[];metas={}
            for i in range(2):
                keeper=f'quiz-2026.10.13-fixture-{i}.sqlite';alias=keeper.removesuffix('.sqlite')+'.restore-proof.sqlite'
                with contextlib.closing(sqlite3.connect(root/keeper)) as db:db.execute('create table fixture(value text)');db.commit()
                (root/alias).write_bytes((root/keeper).read_bytes())
                for name in (keeper,alias):(root/name).chmod(0o600);metas[name]=self.metadata(root/name)
                groups.append(dict(keeper=keeper,duplicates=[alias],bytes=metas[keeper]['bytes'],sha256=metas[keeper]['sha256']))
            keeper_before={g['keeper']:metas[g['keeper']] for g in groups}
            for source,old in ((ORIGINAL_HOUSE,True),(CLOSED_HOUSE,False)):
                namespace={'__name__':'qm_temp_two_group'};exec(compile(source,'temp-house','exec'),namespace);namespace['BACKUPS']=root
                connections=[];connect=sqlite3.connect
                def tracked(*args,**kwargs):
                    self.assertIn('mode=ro',args[0]);connection=connect(*args,**kwargs);connections.append(connection);return connection
                namespace['sqlite3']=SimpleNamespace(connect=tracked);original=namespace['check']
                def checked(name,group):
                    no_process_use(root);verify_entry(root/name,metas[name]);original(name,group);return verify_entry(root/name,metas[name])
                namespace['check']=checked
                try:
                    if old:
                        with self.assertRaisesRegex(ValueError,'backup open by active process'):
                            namespace['run'](dict(schema_version='qm-cold-backup-dedup/v1',groups=groups,expected_files=4))
                        self.assertTrue(all((root/g['duplicates'][0]).exists() for g in groups))
                    else:
                        receipt=namespace['run'](dict(schema_version='qm-cold-backup-dedup/v1',groups=groups,expected_files=4))
                        self.assertEqual(len(receipt['removed_aliases']),2)
                        self.assertTrue(all(not (root/g['duplicates'][0]).exists() for g in groups))
                    self.assertEqual({name:self.metadata(root/name) for name in keeper_before},keeper_before)
                finally:
                    for connection in connections:connection.close()
                no_process_use(root)
    def test_both_preflight_readonly_contexts_close_real_connections(self):
        with tempfile.TemporaryDirectory(prefix='qm-preflight-contexts-') as tmp:
            root=Path(tmp);db_path=root/'fixture.sqlite'
            with contextlib.closing(sqlite3.connect(db_path)) as db:db.execute('create table fixture(value text)');db.commit()
            for expressions,old in ((OLD_PREFLIGHT_CONTEXTS,True),(NEW_PREFLIGHT_CONTEXTS,False)):
                connections=[];connect=sqlite3.connect
                def readonly(database,**kwargs):
                    self.assertIn('mode=ro',database);self.assertEqual(kwargs,{'uri':True})
                    connection=connect(db_path.as_uri()+'?mode=ro&immutable=1',uri=True);connections.append(connection);return connection
                try:
                    self.assertEqual(len(expressions),2)
                    for expression in expressions:
                        context=eval(compile(expression,'exact-preflight-context','eval'),
                                     dict(sqlite3=SimpleNamespace(connect=readonly),contextlib=contextlib,backup=str(db_path)))
                        with context as db:
                            self.assertEqual(db.execute('pragma integrity_check').fetchone(),('ok',))
                            with self.assertRaises(ValueError):no_process_use(root)
                        if old:
                            with self.assertRaises(ValueError):no_process_use(root)
                        else:
                            no_process_use(root)
                            with self.assertRaises(sqlite3.ProgrammingError):db.execute('select 1')
                finally:
                    for connection in connections:connection.close()
                no_process_use(root)

suite=unittest.TestSuite([unittest.defaultTestLoader.loadTestsFromTestCase(DedupTests),unittest.defaultTestLoader.loadTestsFromTestCase(FingerprintTests),unittest.defaultTestLoader.loadTestsFromTestCase(LifetimeIntegrationTests)])
result=unittest.TextTestRunner(verbosity=2).run(suite)
raise SystemExit(0 if result.wasSuccessful() else 1)

COUNTRY483_FIXTURE
