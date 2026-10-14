import copy
import json
import unittest
from pathlib import Path
import proposal as p

PILOT = p.ROOT / 'docs/rewrite-agents/tasks/SCREEN_SONG_PILOT_20261014'

class ProposalTests(unittest.TestCase):
    def setUp(self):
        self.c = json.loads((PILOT/'candidate.json').read_text())
        self.e = json.loads((PILOT/'editorial.json').read_text())
        self.t = json.loads((p.ROOT/'metadata/tags.v1.json').read_text())

    def test_all_four_nonzero_keys_and_exact_text_survive_conversion(self):
        out = p.make_proposal(self.c,self.e,self.t)
        self.assertIn('raw',out)
        self.assertEqual([q['correct_answer'] for q in out['raw']['questions']],[0,1,2,3])
        for source,edit,raw,q,article in zip(self.c['items'],self.e['items'],out['raw']['questions'],out['draft']['questions'],out['reader']['articles'],strict=True):
            self.assertEqual(raw['text'],source['stem_ru'])
            self.assertEqual(raw['options'],[o['text_ru'] for o in source['options']])
            self.assertEqual(q['grading']['correct_option_id'],q['options'][raw['correct_answer']]['option_id'])
            self.assertEqual(raw['explanation'],edit['explanation_ru'])
            self.assertEqual(q['editorial_tag_ids'],edit['tags'])
            self.assertNotIn('\\n',article['body_ru'])
            self.assertEqual(article['status'],'draft')
            self.assertEqual([s['url'] for s in article['source_links']],[s['url'] for s in edit['sources']])
        for q in out['bundle_projection']['quiz']['questions']:
            self.assertNotIn('grading',q)
            self.assertNotIn('editorial_tag_ids',q)

    def test_unregistered_tag_is_rejected(self):
        self.e['items'][0]['tags'].append('topic:not-registered')
        with self.assertRaisesRegex(ValueError,'registered'):
            p.make_proposal(self.c,self.e,self.t)

    def test_missing_nonzero_key_is_rejected(self):
        self.e['items'][3]['correct_option_id']='missing'
        with self.assertRaisesRegex(ValueError,'correct option'):
            p.make_proposal(self.c,self.e,self.t)

    def test_duplicate_question_id_is_rejected(self):
        self.c['items'][3]['id']=self.c['items'][0]['id']
        with self.assertRaisesRegex(ValueError,'IDs'):
            p.make_proposal(self.c,self.e,self.t)

    def test_duplicate_option_and_wrong_count_are_rejected(self):
        self.c['items'][1]['options'][1]['text_ru']=self.c['items'][1]['options'][0]['text_ru']
        with self.assertRaisesRegex(ValueError,'distinct options'):
            p.make_proposal(self.c,self.e,self.t)
        self.c['items'][1]['options'].pop()
        with self.assertRaisesRegex(ValueError,'four'):
            p.make_proposal(self.c,self.e,self.t)

    def test_literal_paragraph_escape_is_rejected(self):
        self.e['items'][0]['article_ru']=self.e['items'][0]['article_ru'].replace('\n\n','\\n\\n',1)
        with self.assertRaisesRegex(ValueError,'literal'):
            p.make_proposal(self.c,self.e,self.t)

    def test_live_and_other_worker_output_paths_are_rejected(self):
        for path in [p.ROOT/'quizzes',p.ROOT/'.run/screen_song_integration_20261014']:
            with self.assertRaisesRegex(ValueError,'owned'):
                p.safe_output(path)

    def test_status_stub_cannot_substitute_for_real_review(self):
        with self.assertRaisesRegex(ValueError,'callback'):
            p.accepted_review({'actual_hub_state':'ACCEPTED','actual_cli_exit':0})

if __name__ == '__main__':
    unittest.main()
