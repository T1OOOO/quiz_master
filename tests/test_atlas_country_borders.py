import json
import unittest
from pathlib import Path


DATA = Path(__file__).parents[1] / "next/apps/quiz_app/assets/quizipedia/map_v2/country_borders.json"


class AtlasCountryBordersTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.countries = json.loads(DATA.read_text(encoding="utf-8"))["countries"]

    def pair(self, country, neighbor):
        return [row for row in self.countries[country]["pairs"] if row["country_id"] == neighbor]

    def test_published_reference_pairs(self):
        self.assertEqual(self.pair("DE", "FR")[0]["length_km"], 418)
        self.assertEqual(self.pair("CA", "US")[0]["length_km"], 8891)
        self.assertEqual(self.pair("AO", "CD")[0]["length_km"], 2646)
        self.assertEqual(self.pair("AO", "CG")[0]["length_km"], 231)

    def test_disjoint_border_segments_are_retained(self):
        self.assertEqual([row["length_km"] for row in self.pair("RU", "CN")], [4133, 46])
        self.assertEqual(self.pair("RU", "LT")[0]["length_km"], 261)
        self.assertEqual(self.pair("RU", "PL")[0]["length_km"], 209)


if __name__ == "__main__":
    unittest.main()
