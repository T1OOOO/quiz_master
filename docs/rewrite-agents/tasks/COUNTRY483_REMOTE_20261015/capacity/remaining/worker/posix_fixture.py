"""Isolated Linux cases; appended to rendered physical guards, never production paths."""
import ast,contextlib,copy,tempfile,unittest

class MultiAliasTests(unittest.TestCase):
    def setUp(self):
        global BACKUPS
        self.temp=tempfile.TemporaryDirectory(prefix='qm-remaining-isolated-')
        self.addCleanup(self.temp.cleanup)
        self.previous=BACKUPS;BACKUPS=Path(self.temp.name)
        self.addCleanup(self.restore_root)
        self.entries={};self.groups=[];self.snapshots=0
        for index,names in enumerate(FIXTURE_NAMES):
            keeper=BACKUPS/names[0]
            with contextlib.closing(sqlite3.connect(keeper)) as db:
                db.execute('create table fixture(value integer)');db.execute('insert into fixture values(?)',(index,));db.commit()
            data=keeper.read_bytes()
            for name in names:
                path=BACKUPS/name;path.write_bytes(data);path.chmod(0o600)
                st=path.stat()
                self.entries[name]=dict(bytes=st.st_size,allocated_bytes=st.st_blocks*512,dev=st.st_dev,ino=st.st_ino,
                    mtime_ns=st.st_mtime_ns,mode=stat.S_IMODE(st.st_mode),uid=st.st_uid,gid=st.st_gid,nlink=st.st_nlink,
                    sha256=hashlib.sha256(data).hexdigest())
            self.groups.append(dict(keeper=names[0],aliases=names[1:],bytes=len(data),sha256=hashlib.sha256(data).hexdigest()))
        self.parent=parent_marker(BACKUPS)
    def restore_root(self):
        global BACKUPS
        BACKUPS=self.previous
    def snapshot(self):
        self.snapshots+=1
        self.assertTrue(all((BACKUPS/n).exists() for g in self.groups for n in g['aliases']))
    def run_groups(self,source=None):return execute_groups(self.entries,self.groups,self.parent,source or house_source,self.snapshot)
    def assert_aliases_present(self):
        self.assertTrue(all((BACKUPS/n).exists() for g in self.groups for n in g['aliases']))
    def last_alias(self):return BACKUPS/self.groups[-1]['aliases'][-1]
    def test_two_groups_four_aliases_closed_green(self):
        receipt=self.run_groups();self.assertEqual(self.snapshots,1)
        self.assertEqual(len(receipt['removed_aliases']),4)
        self.assertEqual({p.name for p in BACKUPS.iterdir()},{g['keeper'] for g in self.groups})
        for g in self.groups:verify_entry(BACKUPS/g['keeper'],self.entries[g['keeper']])
        no_process_use(BACKUPS)
    def test_unclosed_house_red_no_unlink(self):
        tree=ast.parse(house_source)
        calls=[item.context_expr for node in ast.walk(tree) if isinstance(node,ast.With) for item in node.items
            if isinstance(item.context_expr,ast.Call) and isinstance(item.context_expr.func,ast.Attribute)
            and isinstance(item.context_expr.func.value,ast.Name) and item.context_expr.func.value.id=='contextlib']
        self.assertEqual(len(calls),1);call=calls[0]
        old=ast.get_source_segment(house_source,call);inner=ast.get_source_segment(house_source,call.args[0])
        leaky=house_source.replace('with '+old+' as db:','with '+inner+' as db:')
        self.assertNotEqual(leaky,house_source)
        with self.assertRaisesRegex(ValueError,'backup open by active process'):self.run_groups(leaky)
        self.assert_aliases_present();self.assertEqual(self.snapshots,0)
    def test_last_group_hash_before_any_unlink(self):
        self.last_alias().write_bytes(b'corrupt')
        with self.assertRaises(ValueError):self.run_groups()
        self.assert_aliases_present();self.assertEqual(self.snapshots,0)
    def test_same_size_hash_change(self):
        path=self.last_alias();st=path.stat();data=bytearray(path.read_bytes());data[-1]^=1;path.write_bytes(data)
        os.utime(path,ns=(st.st_atime_ns,st.st_mtime_ns))
        with self.assertRaises(ValueError):self.run_groups()
        self.assert_aliases_present()
    def test_journal_before_any_unlink(self):
        Path(str(self.last_alias())+'-journal').touch()
        with self.assertRaises(ValueError):self.run_groups()
        self.assert_aliases_present()
    def test_symlink_before_any_unlink(self):
        path=self.last_alias();path.unlink();path.symlink_to(BACKUPS/self.groups[-1]['keeper'])
        with self.assertRaises(ValueError):self.run_groups()
        self.assert_aliases_present()
    def test_hardlink_before_any_unlink(self):
        path=self.last_alias();path.unlink();os.link(BACKUPS/self.groups[-1]['keeper'],path)
        with self.assertRaises(ValueError):self.run_groups()
        self.assert_aliases_present()
    def test_open_owned_connection_no_pid_skip(self):
        with contextlib.closing(sqlite3.connect(self.last_alias())):
            with self.assertRaisesRegex(ValueError,'backup open by active process'):self.run_groups()
        self.assert_aliases_present()
    def test_duplicate_alias_rejected(self):
        self.groups[-1]['aliases'].append(self.groups[0]['aliases'][0])
        with self.assertRaises(ValueError):self.run_groups()
        self.assert_aliases_present()
    def test_private_mode_rejected(self):
        self.last_alias().chmod(0o644)
        with self.assertRaises(ValueError):self.run_groups()
        self.assert_aliases_present()
    def test_parent_identity_rejected(self):
        self.parent['ino']+=1
        with self.assertRaises(ValueError):self.run_groups()
        self.assert_aliases_present()
    def test_unlisted_name_rejected(self):
        self.groups[-1]['aliases'][-1]='quiz-2026.10.11-unlisted.sqlite'
        with self.assertRaises(ValueError):self.run_groups()
        self.assertEqual(len(list(BACKUPS.iterdir())),6)

if os.name!='posix' or not hasattr(os,'O_NOFOLLOW'):
    raise RuntimeError('real POSIX fixture required, no skips')
result=unittest.TextTestRunner(verbosity=2).run(unittest.defaultTestLoader.loadTestsFromTestCase(MultiAliasTests))
raise SystemExit(0 if result.wasSuccessful() else 1)
