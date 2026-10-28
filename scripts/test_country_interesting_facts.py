"""Validate the source-backed country facts asset without network access."""

import json
import re
import unittest
from pathlib import Path
from urllib.parse import urlsplit


ASSETS = Path(__file__).resolve().parents[1] / "next/apps/quiz_app/assets/quizipedia"


def load_json(path):
    def unique_keys(pairs):
        result = {}
        for key, value in pairs:
            if key in result:
                raise ValueError(f"Duplicate JSON key: {key}")
            result[key] = value
        return result

    return json.loads(path.read_text(encoding="utf-8"), object_pairs_hook=unique_keys)


class CountryInterestingFactsTest(unittest.TestCase):
    def test_asset(self):
        asset = load_json(ASSETS / "country_interesting_facts.json")
        registry = load_json(ASSETS / "country_facts.json")
        country_ids = {country["id"] for country in registry["countries"]}
        self.assertEqual(set(asset), {"countries"})
        self.assertIsInstance(asset["countries"], dict)
        self.assertTrue(asset["countries"])
        seen_ru, seen_en = set(), set()
        for country_id, facts in asset["countries"].items():
            with self.subTest(country=country_id):
                self.assertRegex(country_id, r"^[A-Z]{2}$")
                self.assertIn(country_id, country_ids)
                self.assertIsInstance(facts, list)
                self.assertTrue(facts)
                for fact in facts:
                    self.assertIsInstance(fact, dict)
                    self.assertEqual(set(fact), {"text_ru", "text_en", "source_url"})
                    for field, seen in (("text_ru", seen_ru), ("text_en", seen_en)):
                        value = fact[field]
                        self.assertIsInstance(value, str)
                        self.assertTrue(value.strip())
                        normalized = re.sub(r"\s+", " ", value.strip()).casefold()
                        self.assertNotIn(normalized, seen)
                        seen.add(normalized)
                    self.assertIsInstance(fact["source_url"], str)
                    url = urlsplit(fact["source_url"])
                    self.assertEqual(url.scheme, "https")
                    self.assertTrue(url.hostname)
                    self.assertFalse(url.username or url.password)


if __name__ == "__main__":
    unittest.main()
