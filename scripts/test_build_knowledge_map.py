import json
import tempfile
import unittest
from pathlib import Path
import build_knowledge_map as m

class MapBuildTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.layers, cls.manifest = m.build()

    def test_country_coverage_and_identity(self):
        countries=self.layers['countries.geojson']['features']
        ids={f['id'] for f in countries}
        old_ids={f['id'] for f in json.loads((m.ROOT/'next/apps/quiz_app/assets/quizipedia/catalog.json').read_text(encoding='utf8'))['countries']}
        self.assertTrue((old_ids - {'ne-sol','ne-twn','ne-cyn','ne-kos'}) <= ids)
        self.assertGreaterEqual(len(countries), 230)
        self.assertEqual(len(ids),len(countries))
        self.assertTrue(any(len(poly)>1 for f in countries for poly in (f['geometry']['coordinates'] if f['geometry']['type']=='MultiPolygon' else [f['geometry']['coordinates']])))
        for iso in ('US','TW','XK','AD','MC','MT','VA','MS'):
            self.assertIn(iso, {f['properties']['country_id'] for f in countries})
        source=m.checked_read(m.ROOT/'quizipedia/sources/map_v2/ne_10m_admin_0_countries.geojson', m.SOURCES['quizipedia/sources/map_v2/ne_10m_admin_0_countries.geojson'][0])
        tw=next(f for f in source['features'] if f['properties']['ADM0_A3']=='TWN')
        self.assertEqual(next(f for f in countries if f['id']=='TW')['geometry'],tw['geometry'])
        for layer in self.layers.values():
            for f in layer['features']:
                self.assertEqual(f['id'],f['properties']['id'])
                m.validate_geometry(f['geometry'])

    def test_existing_country_anchor_retained_and_ms_not_plymouth(self):
        labels={f['id']:f for f in self.layers['country_labels.geojson']['features']}
        self.assertGreaterEqual(len(labels),219)
        self.assertEqual(labels['US']['geometry']['coordinates'],[-97.482602,39.538479])
        lon,lat=labels['MS']['geometry']['coordinates']
        self.assertTrue(-63 < lon < -61 and 16 < lat < 17)
        self.assertFalse(any(f['properties'].get('country_id')=='MS' for f in self.layers['capitals.geojson']['features']))

    def test_water_labels_and_anchor(self):
        waters={f['id']:f for f in self.layers['waterways.geojson']['features']}
        existing=m.checked_read(m.ROOT/'next/apps/quiz_app/assets/quizipedia/waterways.json', m.SOURCES['next/apps/quiz_app/assets/quizipedia/waterways.json'][0])
        self.assertEqual(set(waters),{r['id'] for r in existing['features']})
        lakes=m.checked_read(m.ROOT/'quizipedia/sources/map_v2/ne_10m_lakes.geojson',m.SOURCES['quizipedia/sources/map_v2/ne_10m_lakes.geojson'][0])
        source_lakes={f['properties']['wikidataid']:f['geometry'] for f in lakes['features']}
        for ident,f in waters.items():
            if f['properties']['kind']=='lake': self.assertEqual(f['geometry'],source_lakes[ident])
        expected={k for k,v in waters.items() if v['properties']['kind'] in ('river','lake')}
        labels=self.layers['water_labels.geojson']['features']
        self.assertEqual({f['id'] for f in labels},expected)
        self.assertEqual(len(labels),len(expected))
        for f in labels:
            w=waters[f['id']]
            self.assertEqual(f['properties']['kind'],w['properties']['kind'])
            self.assertEqual(f['geometry']['coordinates'],m.water_anchor(w['geometry']))
        polygon={'type':'Polygon','coordinates':[[[0,0],[10,0],[10,10],[0,10],[0,0]],[[3,3],[7,3],[7,7],[3,7],[3,3]]]}
        point=m.water_anchor(polygon)
        self.assertTrue(0 < point[0] < 10 and 0 < point[1] < 10)
        self.assertFalse(3 <= point[0] <= 7 and 3 <= point[1] <= 7)
        self.assertEqual(m.water_anchor({'type':'LineString','coordinates':[[0,0],[2,2],[4,4]]}),[2,2])

    def test_landmark_catalog_provenance_and_positions(self):
        rows=self.layers['landmarks.geojson']['features']
        catalog=m.checked_read(m.ROOT/'next/apps/quiz_app/assets/quizipedia/catalog.json',m.SOURCES['next/apps/quiz_app/assets/quizipedia/catalog.json'][0])['landmarks']
        self.assertEqual({f['id'] for f in rows},{r['id'] for r in catalog})
        self.assertEqual(len(rows),46)
        lookup={f['id']:f for f in rows}
        for ident,lon,lat in [('eiffel',2.294479,48.858296),('colosseum',12.492222,41.890278),('badaling',116.00649,40.35428)]:
            self.assertEqual(lookup[ident]['geometry']['coordinates'],[lon,lat])
        for f in rows:
            for key in ('coordinate_source_url','wikidata_id','source_url','image_attribution','image_license','image_source_url','name_ru','name_en','explanation_ru','explanation_en'):
                self.assertTrue(f['properties'][key], (f['id'],key))

    def test_determinism_tamper_and_invalid_geometry(self):
        self.assertEqual(m.serialize_build(self.layers,self.manifest),m.serialize_build(*m.build()))
        with tempfile.TemporaryDirectory() as d:
            p=Path(d)/'source';p.write_bytes(b'bad')
            with self.assertRaisesRegex(ValueError,'hash mismatch'):m.checked_read(p,'0'*64)
        for g in [{'type':'Point','coordinates':[True,0]}, {'type':'Point','coordinates':[float('nan'),0]}, {'type':'Point','coordinates':[float('inf'),0]}, {'type':'Point','coordinates':[-float('inf'),0]}, {'type':'Point','coordinates':[181,0]}, {'type':'Point','coordinates':[0,91]}, {'type':'MultiLineString','coordinates':[]}, {'type':'MultiPolygon','coordinates':[]}, {'type':'Polygon','coordinates':[[[0,0],[1,0],[1,1],[0,1]]]}]:
            with self.assertRaises(ValueError):m.validate_geometry(g)

if __name__=='__main__':unittest.main()
