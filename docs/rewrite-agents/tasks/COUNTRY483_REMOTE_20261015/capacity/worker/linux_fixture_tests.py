"""Pending Linux-only temporary SQLite tests. Never use production backup paths."""
class FingerprintTests(unittest.TestCase):
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory(prefix='qm-exact29-fixture-');self.root=Path(self.temp.name)
        self.path=self.root/'quiz-2026.10.13-fixture.sqlite'
        with sqlite3.connect(self.path) as db:db.execute('create table fixture(value text)')
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
