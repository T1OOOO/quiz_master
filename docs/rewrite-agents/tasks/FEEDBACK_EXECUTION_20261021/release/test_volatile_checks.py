import sqlite3,shutil,tempfile,unittest
from pathlib import Path
import volatile_checks as v
BUILD='quiz-2026.10.21-feedback-deadbeef';STAGE='/opt/quiz-master/releases/'+BUILD
class VolatileChecksTest(unittest.TestCase):
 def test_stage(self):
  self.assertEqual(str(v.validate_stage_name(STAGE,BUILD)),STAGE)
  with self.assertRaises(v.GuardError):v.validate_stage_name('/tmp/'+BUILD,BUILD)
 def test_ram_restore(self):
  v.validate_memory(v.SIZE+v.RESERVE)
  with self.assertRaises(v.GuardError):v.validate_memory(v.SIZE+v.RESERVE-1)
  with tempfile.TemporaryDirectory() as d:
   a,b=Path(d)/'a.sqlite',Path(d)/'b.sqlite';c=sqlite3.connect(a);c.execute('create table a(x)');c.commit();c.close();shutil.copy2(a,b);self.assertEqual(v.verify_restore(a,b)['integrity'],'ok')
if __name__=='__main__':unittest.main()