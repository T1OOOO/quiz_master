from pathlib import Path
import copy,ctypes,os,tempfile,unittest
from unittest.mock import patch
import quarantine as q

class Guards(unittest.TestCase):
    def setUp(self):
        if os.name=='nt':
            guard=patch.object(os,'O_NOFOLLOW',0,create=True);guard.start();self.addCleanup(guard.stop)
        self.temp=tempfile.TemporaryDirectory();self.addCleanup(self.temp.cleanup)
        self.base=Path(self.temp.name).resolve()
        self.stage=self.base/'quiz-2026.10.15-reader303-14b7da4';self.stage.mkdir()
        (self.stage/'payload').write_bytes(b'failed-package')
        self.archive=Path(str(self.stage)+'.tar.gz');self.archive.write_bytes(b'archive')
        self.backup=self.base/'backup';self.backup.write_bytes(b'preserved')
        self.dest=[Path(str(self.stage)+'.failed-20261015T162707Z'),Path(str(self.stage)+'.failed-20261015T162707Z.tar.gz')]
        self.plan={'parent':q.fingerprint(self.base),'entries':[q.fingerprint(self.stage),q.fingerprint(self.stage/'payload')],'archive':q.fingerprint(self.archive),'backup':q.fingerprint(self.backup),'destinations':list(map(str,self.dest)),'own_images':{'docker':[],'containerd':[]},'own_containers':[],'own_processes':[]}
    def test_altered_file_refused_before_rename(self):
        (self.stage/'payload').write_bytes(b'changed')
        with patch('ctypes.CDLL') as call:
            with self.assertRaises(AssertionError):q.move_failed(self.plan,self.base)
            call.assert_not_called()
        self.assertTrue(self.archive.exists())
    def test_existing_destination_refused(self):
        self.dest[0].mkdir()
        with self.assertRaises(AssertionError):q.move_failed(self.plan,self.base)
        self.assertTrue(self.stage.exists())
    def test_active_owned_work_refused(self):
        self.plan['own_processes']=[1]
        with self.assertRaises(AssertionError):q.move_failed(self.plan,self.base)
    def test_pinned_destination_refused(self):
        self.plan['destinations'][0]=str(self.base/'unrelated')
        with self.assertRaises(AssertionError):q.move_failed(self.plan,self.base)
    def test_two_renames_preserve_full_payload(self):
        def rename(srcfd,src,dstfd,dst,flags):
            self.assertEqual((srcfd,dstfd,flags),(-100,-100,1))
            os.rename(src,dst);return 0
        with patch('ctypes.CDLL') as call:
            call.return_value.renameat2.side_effect=rename
            self.assertEqual(q.move_failed(self.plan,self.base),list(map(str,self.dest)))
        self.assertEqual((self.dest[0]/'payload').read_bytes(),b'failed-package')
        self.assertEqual(self.backup.read_bytes(),b'preserved')

if __name__=='__main__':unittest.main()
