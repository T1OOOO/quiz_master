import json
from pathlib import Path
import unittest
from shapely.geometry import Point, shape

ROOT = Path(__file__).resolve().parents[1]

class CoastalBasinsTest(unittest.TestCase):
    def test_control_points_and_exclusions(self):
        data = json.loads((ROOT / 'quizipedia/sources/map_v2/coastal_basins.geojson').read_text(encoding='utf-8'))
        basins = {f['properties']['id']: shape(f['geometry']) for f in data['features']}
        self.assertEqual(len(basins), 5)
        for ident, points in {
            'Q4918': [(19.0, 31.5), (4.2, 42.7)],
            'Q166': [(34.0, 43.0)],
            'Q23406': [(38.0, 20.0)],
            'Q34675': [(52.0, 27.0)],
            'Q5484': [(51.0, 41.0)],
        }.items():
            for point in points:
                self.assertTrue(basins[ident].covers(Point(*point)), (ident, point))
        for point in [(-10, 35), (13.2, 32.8), (2.35, 48.86), (45, 10), (58, 26)]:
            self.assertFalse(any(g.covers(Point(*point)) for g in basins.values()), point)

if __name__ == '__main__':
    unittest.main()
