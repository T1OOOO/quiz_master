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

    def test_detailed_rivers_preserve_ids_and_geographic_coverage(self):
        waters={f['id']:f for f in self.layers['waterways.geojson']['features']}
        self.assertEqual(m.DETAILED_RIVER_IDS,{'Q1653','Q46841'})
        path='quizipedia/sources/map_v2/ne_10m_rivers_lake_centerlines_scale_rank.geojson'
        source=m.checked_read(m.ROOT/path,m.SOURCES[path][0])
        path='quizipedia/sources/map_v2/ne_110m_rivers_lake_centerlines.geojson'
        old=m.checked_read(m.ROOT/path,m.SOURCES[path][0])
        for ident in m.DETAILED_RIVER_IDS:
            reference=[f['geometry'] for f in old['features'] if f['properties']['wikidataid']==ident]
            selected=[f['geometry'] for f in source['features'] if f['properties']['wikidataid']==ident]
            self.assertTrue(selected,ident)
            self.assertTrue(m.river_reference_covered(reference,selected),ident)
            self.assertTrue(m.river_segments_connected(selected),ident)
            for geometry in selected:
                self.assertTrue(m.river_near_reference(geometry,reference),ident)
            actual=waters[ident]['geometry']
            self.assertEqual(actual['type'],'MultiLineString')
            self.assertEqual(actual['coordinates'],[line for g in selected for line in m.line_points(g)])
            self.assertGreater(sum(len(line) for line in actual['coordinates']),250)
        reference=[{'type':'LineString','coordinates':[[100,40],[101,41]]}]
        distant={'type':'LineString','coordinates':[[0,0],[1,1]]}
        self.assertFalse(m.river_near_reference(distant,reference))
        self.assertFalse(m.river_reference_covered(reference,[distant]))
        self.assertFalse(m.river_segments_connected(reference+[distant]))

    def test_physical_river_detail_is_pinned_and_complete(self):
        path='quizipedia/sources/map_v2/ne_10m_rivers_lake_centerlines_scale_rank.geojson'
        source=m.checked_read(m.ROOT/path,m.SOURCES[path][0])['features']
        expected={f'ne10-river-{index}': f for index,f in enumerate(source) if f['properties']['featurecla'] in ('River','River (Intermittent)')}
        output=self.layers['rivers_detail.geojson']['features']
        self.assertEqual(len(output),3739)
        self.assertEqual({f['id'] for f in output},set(expected))
        for f in output:
            source_row=expected[f['id']]
            self.assertEqual(f['geometry'],source_row['geometry'])
            self.assertEqual(f['properties']['min_zoom'],source_row['properties']['min_zoom'])
            self.assertEqual(f['properties']['intermittent'],source_row['properties']['featurecla']=='River (Intermittent)')
            self.assertEqual(set(f['properties']) - {'water_id'},{'id','kind','min_zoom','intermittent'})
            self.assertEqual(f['properties']['kind'],'river')
        self.assertEqual(self.manifest['counts']['rivers_detail.geojson'],3739)
        self.assertIn('rivers_detail.geojson',json.loads(m.serialize_build(self.layers,self.manifest)['manifest.json'])['outputs'])

    def test_physical_lake_detail_matches_pinned_source(self):
        path='quizipedia/sources/map_v2/ne_10m_lakes.geojson'
        source=m.checked_read(m.ROOT/path,m.SOURCES[path][0])['features']
        expected={f'ne10-lake-{index}': f for index,f in enumerate(source)}
        output=self.layers['lakes_detail.geojson']['features']
        self.assertEqual(len(output),1355)
        self.assertEqual({f['id'] for f in output},set(expected))
        for f in output:
            src=expected[f['id']]
            self.assertIn(f['geometry']['type'],('Polygon','MultiPolygon'))
            self.assertEqual(f['geometry'],src['geometry'])
            self.assertEqual({k:v for k,v in f['properties'].items() if k!='water_id'},{'id':f['id'],'kind':'lake','min_zoom':src['properties']['min_zoom']})
        self.assertEqual(self.manifest['counts']['lakes_detail.geojson'],1355)
        self.assertIn('lakes_detail.geojson',json.loads(m.serialize_build(self.layers,self.manifest)['manifest.json'])['outputs'])

    def test_detail_water_ids_are_verified_and_unique(self):
        waters={f['id']:f for f in self.layers['waterways.geojson']['features']}
        lakes=self.layers['lakes_detail.geojson']['features']
        rivers=self.layers['rivers_detail.geojson']['features']
        linked_lakes=[f for f in lakes if 'water_id' in f['properties']]
        linked_rivers=[f for f in rivers if 'water_id' in f['properties']]
        self.assertEqual({f['properties']['water_id'] for f in linked_lakes}, {i for i,v in waters.items() if v['properties']['kind']=='lake'})
        self.assertEqual({f['properties']['water_id'] for f in linked_rivers}, {'Q1653','Q46841'})
        self.assertEqual(len(linked_lakes),24)
        self.assertEqual(len(linked_rivers),28)
        for f in linked_lakes:
            self.assertEqual(f['geometry'],waters[f['properties']['water_id']]['geometry'])
        for f in linked_rivers:
            ident=f['properties']['water_id']
            self.assertTrue(m.river_near_reference(f['geometry'],[waters[ident]['geometry']]))
        self.assertEqual(len({f['id'] for f in lakes+rivers}),len(lakes+rivers))

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
