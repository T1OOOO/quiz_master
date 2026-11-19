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
        self.assertGreaterEqual(len(records), 418)
        self.assertGreaterEqual(len({c for r in records for c in r['countries']}), 212)
        self.assertEqual(len({r['id'] for r in records}), len(records))
        self.assertEqual({(r['start'] - 1) // 100 + 1 for r in records}, {16, 17, 18, 19, 20})
        per_century = Counter((r['start'] - 1) // 100 + 1 for r in records)
        for century, minimum in [(16, 77), (17, 85), (18, 95)]:
            self.assertGreaterEqual(per_century[century], minimum, century)
        labels = json.loads((ASSET.parent / 'country_labels.geojson').read_text(encoding='utf-8'))
        country_ids = {f['properties']['country_id'] for f in labels['features']}
        self.assertEqual(len(records), len({(r['title_ru'], r['start']) for r in records}))
        self.assertTrue({'epidemic', 'war', 'science', 'treaty'} <= {r['kind'] for r in records})
        self.assertGreaterEqual(sum('location' in r for r in records), 180)
        for r in records:
            if 'location' in r:
                lon, lat = r['location']
                self.assertTrue(-180 <= lon <= 180 and -90 <= lat <= 90, r['id'])
                self.assertTrue(r['place_ru'].strip() and r['place_en'].strip(), r['id'])
            self.assertTrue(1501 <= r['start'] <= r['end'] <= 2000, r['id'])
            self.assertIn(r['kind'], {
                'war', 'event', 'epidemic', 'health', 'revolution', 'disaster',
                'treaty', 'science', 'culture', 'independence', 'exploration',
            })
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
