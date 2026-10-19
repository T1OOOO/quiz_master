"""Cross-file integrity and representative geographic facts for offline practice."""
import json
from pathlib import Path
import unittest

ROOT=Path(__file__).resolve().parents[4]
ASSETS=ROOT/'next/apps/quiz_app/assets/quizipedia'

def load(name): return json.loads((ASSETS/name).read_text(encoding='utf8'))

class AssetTests(unittest.TestCase):
    def test_sources_and_country_references(self):
        countries=load('country_facts.json')['countries']
        ids={r['id'] for r in countries}
        self.assertEqual(len(ids),250)
        for country in countries:
            self.assertFalse(set(country['neighbors'])-ids,country['id'])
            self.assertTrue(all(isinstance(c,str) for c in country['currencies']))
        for filename in ['country_waters.json','country_links.json','country_presidents.json']:
            data=load(filename)
            sources={s['id'] for s in data['sources']}
            self.assertEqual(len(sources),len(data['sources']))
            self.assertFalse(set(data['countries'])-ids,filename)
            for code,rows in data['countries'].items():
                for row in rows if isinstance(rows,list) else [rows]:
                    self.assertIn(row['source_id'],sources,(filename,code,row))
                    self.assertTrue(row['name_ru'] and row['name_en'])

    def test_major_water_relationships(self):
        rows=load('country_waters.json')['countries']
        ru={(r['name_en'],r['relation']) for r in rows['RU']}
        self.assertIn(('Lake Baikal','internal'),ru)
        self.assertIn(('Caspian Sea','border'),ru)
        self.assertIn(('Volga','flows'),ru)
        self.assertTrue(any(r['name_en']=='Nile' and r['relation']=='flows' for r in rows['EG']))
        self.assertFalse(any(r['relation']=='coast' for r in rows['CH']))

    def test_every_requested_link_topic_has_a_quiz_pool(self):
        rows=load('country_links.json')['countries']
        for kind in ['resource','desert','wonder','landmark','bridge','scientist','food','sports_team']:
            names={r['name_en'] for values in rows.values() for r in values if r['kind']==kind}
            self.assertGreaterEqual(len(names),4,kind)
        for code in ['DZ','MR','MA','TN']:
            self.assertTrue(any(r['id']=='couscous' for r in rows[code]))

    def test_offline_flags_exist_for_every_record(self):
        for row in load('country_facts.json')['countries']:
            flag=ASSETS/f"flag-{row['id'].lower()}.png"
            self.assertTrue(flag.exists(),str(flag))
            self.assertTrue(flag.read_bytes().startswith(b'\x89PNG\r\n\x1a\n'))

    def test_presidents_are_dated_and_have_distinct_sources(self):
        rows=load('country_presidents.json')['countries']
        self.assertEqual(len(rows),12)
        self.assertTrue(all(row['checked']=='2026-10-19' for row in rows.values()))

if __name__=='__main__': unittest.main()
