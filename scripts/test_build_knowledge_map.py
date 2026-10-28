import json
import tempfile
import unittest
from pathlib import Path
import build_knowledge_map as m

class MapBuildTest(unittest.TestCase):
    def test_output_contract_and_joins(self):
        layers, manifest = m.build()
        countries = layers['countries.geojson']['features']
        ids = {f['id'] for f in countries}
        self.assertEqual(len(ids), len(countries))
        self.assertIn('US', ids)
        self.assertIn('TW', ids)
        self.assertIn('XK', ids)
        self.assertEqual(next(f for f in countries if f['id']=='TW')['properties']['country_id'], 'TW')
        source=m.checked_read(m.ROOT/'quizipedia/sources/world-source.json',m.SOURCES['quizipedia/sources/world-source.json'][0])
        original={f['properties']['ADM0_A3']: f['geometry'] for f in source['features']}
        for f in countries:
            matches=[g for g in original.values() if g == f['geometry']]
            self.assertTrue(matches, f['id'])
        self.assertEqual(next(f for f in countries if f['id']=='TW')['geometry'], original['TWN'])
        self.assertEqual(next(f for f in countries if f['id']=='US')['properties']['country_id'], 'US')
        for f in layers['capitals.geojson']['features']:
            self.assertRegex(f['properties']['country_id'], r'^[A-Z]{2}$')
        for layer in layers.values():
            for f in layer['features']:
                self.assertEqual(f['id'], f['properties']['id'])
                m.validate_geometry(f['geometry'])
        self.assertTrue(any(len(poly)>1 for f in countries for poly in (f['geometry']['coordinates'] if f['geometry']['type']=='MultiPolygon' else [f['geometry']['coordinates']])))
        us_capital = next(f for f in layers['capitals.geojson']['features'] if f['properties']['country_id']=='US')
        lon, lat = us_capital['geometry']['coordinates']
        self.assertTrue(-78 < lon < -76 and 38 < lat < 40)
        self.assertEqual(manifest['schema_version'], 'qm-geography/v1')
        existing=m.checked_read(m.ROOT/'next/apps/quiz_app/assets/quizipedia/waterways.json',m.SOURCES['next/apps/quiz_app/assets/quizipedia/waterways.json'][0])
        self.assertEqual({f['id'] for f in layers['waterways.geojson']['features']}, {f['id'] for f in existing['features']})
        for f in countries:
            self.assertRegex(f['properties']['country_id'], r'^[A-Z]{2}$')
            if not f['id'].startswith('ne-'): self.assertEqual(f['id'], f['properties']['country_id'])

    def test_country_label_anchors(self):
        layers, manifest = m.build()
        countries = {f['properties']['country_id']: f for f in layers['countries.geojson']['features']}
        labels = layers['country_labels.geojson']['features']
        by_id = {f['id']: f for f in labels}
        capitals = m.checked_read(m.ROOT/'next/apps/quiz_app/assets/quizipedia/capital_points.json', m.SOURCES['next/apps/quiz_app/assets/quizipedia/capital_points.json'][0])['capitals']
        first_capitals = {}
        for row in capitals:
            first_capitals.setdefault(row['country_id'], row)
        self.assertEqual(len(labels), 219)
        self.assertNotIn('MS', by_id)
        self.assertNotIn('MS', {f['properties']['country_id'] for f in layers['capitals.geojson']['features']})
        self.assertEqual(len(by_id), len(labels))
        self.assertEqual(set(by_id), (set(countries) | set(first_capitals)) - {'MS'})
        source = m.checked_read(m.ROOT/'quizipedia/sources/world-source.json', m.SOURCES['quizipedia/sources/world-source.json'][0])
        facts = {r['id']: r for r in m.checked_read(m.ROOT/'next/apps/quiz_app/assets/quizipedia/country_facts.json', m.SOURCES['next/apps/quiz_app/assets/quizipedia/country_facts.json'][0])['countries']}
        for ident, label in by_id.items():
            self.assertEqual(label['properties']['country_id'], ident)
            m.validate_geometry(label['geometry'])
            if ident in countries:
                country = countries[ident]
                match = next(f for f in source['features'] if f['geometry'] == country['geometry'])
                coordinates = [match['properties']['LABEL_X'], match['properties']['LABEL_Y']]
                self.assertEqual(label['properties']['anchor_source'], 'natural-earth-label')
                for key in ('name_ru', 'name_en'):
                    self.assertEqual(label['properties'][key], country['properties'][key])
            else:
                row = first_capitals[ident]
                coordinates = [row['longitude'], row['latitude']]
                self.assertEqual(label['properties']['anchor_source'], 'capital-point')
                for key in ('name_ru', 'name_en'):
                    self.assertEqual(label['properties'][key], facts[ident][key])
            self.assertEqual(label['geometry'], {'type':'Point', 'coordinates':coordinates})
        self.assertEqual(manifest['counts']['country_labels.geojson'], 219)
        self.assertTrue(any('Montserrat' in note for note in manifest['coverage_notes']))
        self.assertIn('country_labels.geojson', json.loads(m.serialize_build(layers, manifest)['manifest.json'])['outputs'])

    def test_determinism_and_tampering(self):
        self.assertEqual(m.serialize_build(*m.build()), m.serialize_build(*m.build()))
        with tempfile.TemporaryDirectory() as d:
            p=Path(d)/'source'; p.write_bytes(b'bad')
            with self.assertRaisesRegex(ValueError, 'hash mismatch'):
                m.checked_read(p, '0'*64)

    def test_invalid_ring_and_coordinates_rejected(self):
        for geometry in [
            {'type':'Point','coordinates':[181,0]},
            {'type':'Point','coordinates':[True,0]},
            {'type':'Point','coordinates':[float('nan'),0]},
            {'type':'Point','coordinates':[float('inf'),0]},
            {'type':'MultiLineString','coordinates':[]},
            {'type':'MultiPolygon','coordinates':[]},
            {'type':'Point','coordinates':[0,91]},
            {'type':'Polygon','coordinates':[[[0,0],[1,0],[1,1],[0,1]]]},
        ]:
            with self.assertRaises(ValueError): m.validate_geometry(geometry)

if __name__=='__main__': unittest.main()
