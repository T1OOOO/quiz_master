import sqlite3,shutil,tempfile,unittest
from pathlib import Path
import volatile_checks as v

BUILD='quiz-2026.10.20-touch-abcdef12'
STAGE='/opt/quiz-master/releases/'+BUILD

class VolatileChecksTest(unittest.TestCase):
 def test_only_the_literal_candidate_stage_is_allowed(self):
  self.assertEqual(str(v.validate_stage_name(STAGE,BUILD)),STAGE)
  for p,b in [('/tmp/'+BUILD,BUILD),(STAGE+'/child',BUILD),(STAGE+'/../other',BUILD),(STAGE,BUILD+'x'),('opt/quiz-master/releases/'+BUILD,BUILD)]:
   with self.assertRaises(v.GuardError):v.validate_stage_name(p,b)
 def test_memory_reserve_remains_after_the_whole_tmpfs_budget(self):
  v.validate_memory(v.SIZE+v.RESERVE)
  with self.assertRaises(v.GuardError):v.validate_memory(v.SIZE+v.RESERVE-1)
 def test_unmount_ownership_requires_type_source_path_and_safe_flags(self):
  expected={'target':STAGE+'/volatile-checks','source':'qm-checks-'+BUILD,'fstype':'tmpfs','options':'rw,nosuid,nodev,noexec,relatime,size=262144k,mode=700'}
  v.validate_mount(expected,STAGE,BUILD)
  for key,value in [('source','another-project'),('fstype','ext4'),('target','/var/lib/data'),('options','rw,nodev,nosuid')]:
   with self.assertRaises(v.GuardError):v.validate_mount({**expected,key:value},STAGE,BUILD)
 def test_full_sqlite_restore_is_equal_valid_and_distinct(self):
  with tempfile.TemporaryDirectory() as folder:
   source=Path(folder)/'backup.sqlite';restored=Path(folder)/'restored.sqlite'
   conn=sqlite3.connect(source);conn.execute('create table records(value blob)');conn.execute('insert into records values(?)',(b'full screenshot bytes',));conn.commit();conn.close()
   shutil.copy2(source,restored)
   proof=v.verify_restore(source,restored)
   self.assertEqual(proof['backup_sha256'],proof['restored_sha256'])
   self.assertEqual(proof['integrity'],'ok')
   with self.assertRaises(v.GuardError):v.verify_restore(source,source)
   restored.write_bytes(b'corrupt')
   with self.assertRaises(v.GuardError):v.verify_restore(source,restored)
 def test_http_receipt_keeps_real_grading_and_article_counts(self):
  v.validate_http_receipt({'visible_banks':105,'visible_slots':4520,'article_refs':241})
  for key,value in [('visible_banks',104),('visible_slots',4519),('article_refs',0)]:
   with self.assertRaises(v.GuardError):v.validate_http_receipt({**{'visible_banks':105,'visible_slots':4520,'article_refs':241},key:value})

if __name__=='__main__':unittest.main()
