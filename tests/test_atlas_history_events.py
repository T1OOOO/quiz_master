import json
from collections import Counter
from pathlib import Path
import re
import unittest
from urllib.parse import urlparse

ROOT = Path(__file__).resolve().parents[1]
ASSET = ROOT / 'next/apps/quiz_app/assets/quizipedia/map_v2/history_events.json'

class HistoryEventsTest(unittest.TestCase):
    def test_records_have_dates_locations_and_sources(self):
        records = json.loads(ASSET.read_text(encoding='utf-8'))['records']
        self.assertGreaterEqual(len(records), 25)
        self.assertEqual(len({r['id'] for r in records}), len(records))
        self.assertEqual({(r['start'] - 1) // 100 + 1 for r in records}, {16, 17, 18, 19, 20})
        per_century = Counter((r['start'] - 1) // 100 + 1 for r in records)
        self.assertTrue(all(per_century[century] >= 5 for century in (16, 17, 18)))
        labels = json.loads((ASSET.parent / 'country_labels.geojson').read_text(encoding='utf-8'))
        country_ids = {f['properties']['country_id'] for f in labels['features']}
        for r in records:
            self.assertTrue(1501 <= r['start'] <= r['end'] <= 2000, r['id'])
            self.assertIn(r['kind'], {'war', 'event'})
            self.assertTrue(r['countries'])
            self.assertEqual(len(r['countries']), len(set(r['countries'])))
            self.assertTrue(all(re.fullmatch(r'[A-Z]{2}', c) for c in r['countries']))
            self.assertTrue(set(r['countries']) <= country_ids, r['id'])
            for key in ('title_ru', 'title_en', 'summary_ru', 'summary_en'):
                self.assertTrue(r[key].strip(), (r['id'], key))
            self.assertEqual(urlparse(r['source_url']).scheme, 'https')
        self.assertTrue(any(r['kind'] == 'war' and r['end'] > r['start'] for r in records))

if __name__ == '__main__':
    unittest.main()
