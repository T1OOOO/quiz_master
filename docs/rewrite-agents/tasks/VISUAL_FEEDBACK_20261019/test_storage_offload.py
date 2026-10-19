import hashlib,io,json,tarfile,tempfile,unittest
from pathlib import Path
from unittest.mock import patch
import storage_offload as s

class StorageGuardTest(unittest.TestCase):
 def test_frozen_literal_plan(self):
  p=s.read_plan();self.assertEqual(len(p['targets']),15)
  self.assertTrue(all(x['path'].startswith('/opt/quiz-master/releases/quiz-2026.10.19-minimum20-7f8344d6/') for x in p['targets']))
 def test_tampered_plan_rejected(self):
  with tempfile.TemporaryDirectory() as t:
   p=Path(t)/'plan.json';p.write_text('{}')
   with patch.object(s,'PLAN_PATH',p),self.assertRaisesRegex(RuntimeError,'plan hash'):s.read_plan()
 def test_parent_escape_tar_rejected(self):
  with tempfile.TemporaryDirectory() as t:
   root=Path(t);a=root/'unsafe.tar.gz'
   with tarfile.open(a,'w:gz') as f:
    m=tarfile.TarInfo('../outside.txt');m.size=1;f.addfile(m,io.BytesIO(b'x'))
   with self.assertRaisesRegex(RuntimeError,'unsafe tar'):s.safe_extract(a,root/'extract')
   self.assertFalse((root.parent/'outside.txt').exists())
 def test_archive_copy_must_match_before_removal(self):
  with tempfile.TemporaryDirectory() as t:
   root=Path(t);p=root/'opt/input';p.parent.mkdir(parents=True);p.write_bytes(b'original')
   item={'path':'/opt/input','kind':'file','sha256':hashlib.sha256(b'original').hexdigest(),'sqlite_integrity':None}
   s.local_verify(root,[item]);p.write_bytes(b'changed')
   with self.assertRaisesRegex(RuntimeError,'mismatch'):s.local_verify(root,[item])
if __name__=='__main__':unittest.main()
