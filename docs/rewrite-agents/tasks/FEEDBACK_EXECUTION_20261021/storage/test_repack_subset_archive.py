import importlib.util
from pathlib import Path
import unittest
import io,tarfile,tempfile

spec=importlib.util.spec_from_file_location('repack',Path(__file__).with_name('repack_subset_archive.py'))
r=importlib.util.module_from_spec(spec);spec.loader.exec_module(r)

class RepackSubsetTest(unittest.TestCase):
    def rows(self):
        return [{'path':'.','type':'dir','size':4096,'mtime_ns':123,'mode':493},
                {'path':'file','type':'file','size':3,'sha256':'abc','mtime_ns':1,'mode':420},
                {'path':'cache','type':'file','size':4,'sha256':'def','mtime_ns':1,'mode':420}]
    def test_removed_only_and_directory_timestamp_are_allowed(self):
        old=self.rows();current=[dict(old[0],mtime_ns=456),old[1]]
        self.assertEqual(r.validate_subset(old,current),['cache'])
    def test_new_or_modified_files_refuse(self):
        old=self.rows()
        for current in (old+[dict(old[1],path='new')],[old[0],dict(old[1],sha256='changed')],
                        [dict(old[0],mode=448),old[1]], [old[0],dict(old[1],mtime_ns=99)]):
            with self.subTest(current=current),self.assertRaises(ValueError):r.validate_subset(old,current)
    def test_duplicate_paths_refuse(self):
        with self.assertRaises(ValueError):r.validate_subset(self.rows(),[self.rows()[0],self.rows()[0]])
    def test_tar_preserves_bytes_ownership_xattrs_and_exact_directory_time(self):
        with tempfile.TemporaryDirectory() as tmp:
            original=Path(tmp)/'old.tar.gz';output=Path(tmp)/'new.tar.gz'
            with tarfile.open(original,'w:gz',format=tarfile.PAX_FORMAT) as t:
                for name,kind,data in [('sample',tarfile.DIRTYPE,None),('sample/file',tarfile.REGTYPE,b'abc'),('sample/link',tarfile.SYMTYPE,None),('sample/cache',tarfile.REGTYPE,b'drop')]:
                    info=tarfile.TarInfo(name);info.type=kind;info.uid=123;info.gid=124;info.mode=0o640
                    info.pax_headers={'mtime':'1.000000001','SCHILY.xattr.user.test':'value'}
                    if kind==tarfile.SYMTYPE:info.linkname='file'
                    if data is not None:info.size=len(data)
                    t.addfile(info,io.BytesIO(data) if data else None)
            rows=[{'path':'.','type':'dir','mtime_ns':1470000000123456789},{'path':'file','type':'file'},{'path':'link','type':'symlink'}]
            r.repack_tar(original,rows,output,'sample')
            with tarfile.open(output,'r:gz') as t:
                self.assertEqual(t.getnames(),['sample','sample/file','sample/link'])
                self.assertEqual(t.getmember('sample').pax_headers['mtime'],'1470000000.123456789')
                self.assertEqual(t.extractfile('sample/file').read(),b'abc')
                self.assertEqual(t.getmember('sample/link').linkname,'file')
                for info in t.getmembers():
                    self.assertEqual((info.uid,info.gid,info.mode),(123,124,0o640))
                    self.assertEqual(info.pax_headers['SCHILY.xattr.user.test'],'value')
            with self.assertRaises(FileExistsError):r.repack_tar(original,rows,output,'sample')
    def test_nanosecond_decimal_is_exact_for_both_signs(self):
        for ns,wanted in [(0,'0.000000000'),(1234567890,'1.234567890'),(-1,'-0.000000001'),(-1234567890,'-1.234567890')]:
            self.assertEqual(r.pax_time(ns),wanted)

if __name__=='__main__':unittest.main()
