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
                def readonly(uri,**kwargs):
                    self.assertIn('mode=ro',uri);self.assertEqual(kwargs,{'uri':True})
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
