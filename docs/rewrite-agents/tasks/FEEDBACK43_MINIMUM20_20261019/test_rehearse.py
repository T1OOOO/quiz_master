import importlib.util, json, tempfile, unittest
from pathlib import Path

HERE=Path(__file__).parent
spec=importlib.util.spec_from_file_location('rehearse',HERE/'rehearse.py')
rehearse=importlib.util.module_from_spec(spec); spec.loader.exec_module(rehearse)

def row(quiz_id='q', n=20):
 return {'quiz_id':quiz_id,'questions_count':n,'difficulty_counts':{'easy':n,'medium':0,'hard':0,'nightmare':0,'unknown':0}}

class RehearseContractTest(unittest.TestCase):
 def test_visible_catalog_requires_exact_count_total_and_minimum(self):
  with tempfile.TemporaryDirectory() as td:
   p=Path(td)/'catalog.json'; rows=[row(f'q-{i}') for i in range(105)]; rows[0]['questions_count']=2440; rows[0]['difficulty_counts']['easy']=2440
   p.write_text(json.dumps(rows),encoding='utf8'); self.assertEqual(len(rehearse.load_catalog(p)),105)
   rows[0]['questions_count']=19; rows[0]['difficulty_counts']['easy']=19; p.write_text(json.dumps(rows),encoding='utf8')
   with self.assertRaisesRegex(RuntimeError,'minimum-20'): rehearse.load_catalog(p)
 def test_public_dto_never_accepts_answer_key(self):
  rehearse.require_public_dto({'quiz':{'questions':[{'option_id':'a'}]}})
  with self.assertRaisesRegex(RuntimeError,'private grading'): rehearse.require_public_dto({'quiz':{'correct_answer':0}})
 def test_private_mapping_requires_every_public_question_and_answer_index(self):
  public={'questions':[{'question_id':'q1','stem':'S?','options':[{'text':'A','option_id':'a'},{'text':'B','option_id':'b'}]}]}
  self.assertEqual(rehearse.map_private_answers([{'id':'q1','text':'S?','options':['A','B'],'correct_answer':1}],public),{'q1':'b'})
  with self.assertRaisesRegex(RuntimeError,'incomplete'):
   rehearse.map_private_answers([],public)
 def test_alias_evidence_requires_all_56(self):
  with tempfile.TemporaryDirectory() as td:
   p=Path(td)/'evidence.json'; p.write_text(json.dumps({'aliases':{'old':'new'}}),encoding='utf8')
   with self.assertRaisesRegex(RuntimeError,'56 aliases'): rehearse.load_aliases(p)
 def test_reviewed_imports_derive_all_38_exact_ids(self):
  root=HERE.parents[3]
  manifest=rehearse.new_question_manifest(root)
  self.assertEqual(sum(len(ids) for _,ids in manifest.values()),38)
  self.assertEqual({len(ids) for _,ids in manifest.values()},{3,5,10})
if __name__=='__main__': unittest.main()
