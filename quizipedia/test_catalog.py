import hashlib
import json
import math
from pathlib import Path
import unittest

from PIL import Image

from build_catalog import BASE, OUT, ROOT, build, encoded, load


class CatalogTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.catalog, cls.manifest = build()

    def test_build_is_deterministic_and_matches_bundled_bytes(self):
        second, manifest = build()
        self.assertEqual(encoded(self.catalog), encoded(second))
        self.assertEqual(encoded(self.manifest), encoded(manifest))
        self.assertEqual(encoded(self.catalog), (OUT/'catalog.json').read_bytes())
        self.assertEqual(hashlib.sha256(encoded(self.catalog)).hexdigest(), self.manifest['generated_catalog_sha256'])

    def test_complete_country_join_without_geometry_loss(self):
        source = load(BASE/'sources/world-source.json')
        self.assertEqual(len(source['features']), len(self.catalog['countries']))
        self.assertEqual(20, len(self.catalog['map_target_ids']))
        countries = {row['id']:row for row in self.catalog['countries']}
        self.assertEqual(len(countries), len(source['features']))
        registry = {row['iso2']:row for row in load(ROOT/'docs/rewrite-agents/preparation-country-registry/countries.json')['countries']}
        for country_id in self.catalog['map_target_ids']:
            row = countries[country_id]
            self.assertEqual(row['name_en'],registry[country_id]['name_en'])
            self.assertEqual([0x1F1E6+ord(c)-65 for c in country_id],[ord(c) for c in row['flag']])
        for raw,row in zip(source['features'],self.catalog['countries']):
            polygons = raw['geometry']['coordinates']
            if raw['geometry']['type']=='Polygon':
                polygons=[polygons]
            self.assertEqual([len(p) for p in polygons], [len(p) for p in row['polygons']])
            for polygon in row['polygons']:
                for ring in polygon:
                    self.assertEqual(ring[0],ring[-1])
                    self.assertGreaterEqual(len(ring),4)
                    for point in ring:
                        self.assertTrue(all(math.isfinite(v) and 0<=v<=1 for v in point))

    def test_target_metadata_credit_and_tag_references(self):
        targets = [r for r in self.catalog['countries'] if r['id'] in self.catalog['map_target_ids']]
        targets += self.catalog['anatomy']['targets']+self.catalog['landmarks']+self.catalog['constellations']
        self.assertEqual(40,len(targets))
        self.assertEqual(40,len({r['id'] for r in targets}))
        tags = {t['id'] for t in load(ROOT/'metadata/tags.v1.json')['tags']}
        credits = {c['id'] for c in self.catalog['credits']}
        for row in targets:
            self.assertIs(type(row['difficulty_level']),int)
            self.assertIn(row['difficulty_level'],range(1,11))
            self.assertTrue(set(row['tag_ids'])<=tags)
            self.assertEqual(sorted(set(row['tag_ids'])), row['tag_ids'])
            self.assertTrue(row['source_url'].startswith('https://'))
            for field in ('name_ru','name_en','explanation_ru','explanation_en'):
                self.assertTrue(row[field])
            if 'credit_id' in row:
                self.assertIn(row['credit_id'],credits)

    def test_stars_retain_source_values_and_referenced_lines(self):
        source = {row['id']:row for row in load(BASE/'sources/stars-source.json')}
        seen = set()
        for constellation in self.catalog['constellations']:
            stars={s['id']:s for s in constellation['stars']}
            seen.update(stars)
            for star in stars.values():
                for key,value in star.items():
                    self.assertEqual(value,source[star['id']][key])
                self.assertTrue(0<=star['ra_hours']<24)
                self.assertTrue(-90<=star['dec_degrees']<=90)
            for a,b in constellation['lines']:
                self.assertIn(a,stars)
                self.assertIn(b,stars)
                self.assertNotEqual(a,b)
        self.assertEqual(set(source),seen)

    def test_real_rasters_manifest_and_hotspot_image_space(self):
        for row in self.manifest['images']:
            path=ROOT/'next/apps/quiz_app'/row['image_asset']
            self.assertEqual(row['sha256'],hashlib.sha256(path.read_bytes()).hexdigest())
            with Image.open(path) as image:
                if row['id']=='endocrine':
                    self.assertEqual(image.size,(self.catalog['anatomy']['width'],self.catalog['anatomy']['height']))
                image.verify()
            self.assertTrue(row['creator'] and row['license'] and row['modification'])
        anatomy=self.catalog['anatomy']
        pixel_source=load(BASE/'hotspots.json')
        for target in anatomy['targets']:
            self.assertEqual(len(target['hotspots']),len(pixel_source['targets'][target['id']]))
            for actual,pixel in zip(target['hotspots'],pixel_source['targets'][target['id']]):
                self.assertAlmostEqual(actual['x']*anatomy['width'],pixel[0])
                self.assertAlmostEqual(actual['y']*anatomy['height'],pixel[1])
                self.assertTrue(0<actual['radius']<0.1)


if __name__=='__main__':
    unittest.main()
