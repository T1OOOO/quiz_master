"""Deterministic offline build from acquired, independently reviewed sources."""
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / 'quizipedia'
OUT = ROOT / 'next/apps/quiz_app/assets/quizipedia'


def load(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))


def encoded(value):
    return (json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(',', ':'))+'\n').encode('utf-8')


def build():
    content = load(BASE / 'content.json')
    world = load(BASE / 'sources/world-source.json')
    stars = {row['id']: row for row in load(BASE / 'sources/stars-source.json')}
    spots = load(BASE / 'hotspots.json')
    images = load(BASE / 'images-manifest.json')
    image_by_id = {row['id']: row for row in images}
    registry = {row['iso2']: row for row in load(ROOT / 'docs/rewrite-agents/preparation-country-registry/countries.json')['countries']}
    taxonomy = load(ROOT / 'metadata/tags.v1.json')
    known_tags = {row['id'] for row in taxonomy['tags']}
    selected = set(content['map_target_iso2'])
    countries = []
    for feature in world['features']:
        prop = feature['properties']
        iso = prop['ISO_A2']
        iso = content['geometry_exceptions'].get(prop['ADM0_A3'], iso)
        # Background-only political features are not part of the quiz identity scope.
        country_id = iso if iso in registry else 'ne-' + prop['ADM0_A3'].lower()
        names = registry.get(iso)
        row = dict(id=country_id, name_ru=names['name_ru'] if names else prop['NAME_EN'],
                   name_en=names['name_en'] if names else prop['NAME_EN'])
        geometry = feature['geometry']
        polygons = geometry['coordinates'] if geometry['type'] == 'MultiPolygon' else [geometry['coordinates']]
        row['polygons'] = [[[[round((lon+180)/360, 9), round((90-lat)/180, 9)]
                             for lon, lat in ring] for ring in polygon] for polygon in polygons]
        if iso in selected:
            row.update(difficulty_level={'US': 1, 'CA': 2, 'FR': 2, 'IT': 2, 'JP': 2, 'AU': 2,
                                         'BR': 3, 'IN': 3, 'CN': 3, 'GB': 3, 'ES': 3,
                                         'MX': 4, 'AR': 4, 'CL': 5, 'EG': 4, 'ZA': 4,
                                         'DE': 4, 'NO': 5, 'SE': 5, 'MG': 5}[iso],
                       flag=''.join(chr(0x1F1E6+ord(c)-ord('A')) for c in iso),
                       tag_ids=sorted(['domain:geography', 'topic:cartography', 'topic:flag', 'topic:world-geography', 'skill:spatial', 'country:'+iso.lower()]),
                       explanation_ru='На карте показана страна '+row['name_ru']+'. Карта Natural Earth использует обобщённые границы; мелкие острова на этом масштабе могут отсутствовать.',
                       explanation_en='The highlighted country is '+row['name_en']+'. Natural Earth uses generalized boundaries; small islands may be absent at this scale.',
                       source_url='https://www.naturalearthdata.com/downloads/110m-cultural-vectors/110m-admin-0-countries/',
                       credit_id='natural-earth')
        countries.append(row)
    assert len({row['id'] for row in countries}) == len(countries), 'duplicate map feature identity'
    assert {row['id'] for row in countries if row['id'] in selected} == selected
    credits = [dict(id='natural-earth', attribution='Natural Earth, 1:110m Admin 0 Countries. Generalized de facto boundaries; background features do not define the quiz country list.',
                    source_url='https://www.naturalearthdata.com/', license='Public domain', license_url='https://www.naturalearthdata.com/about/terms-of-use/'),
               dict(id='hyg', attribution=f'HYG Database v4.1, David Nash / Astronexus. {len(stars)}-star subset, fixed J2000 coordinates; eight preserved Quiz Master pilot patterns. Adapted data: CC BY-SA 4.0.',
                    source_url='https://github.com/astronexus/HYG-Database', license='CC BY-SA 4.0', license_url='https://creativecommons.org/licenses/by-sa/4.0/'),
               dict(id='sky-modern', attribution='HYG Database v4.1, David Nash / Astronexus, J2000 coordinates. Stellarium team, modern sky-culture star-figure data. Adapted data and connecting lines: CC BY-SA 4.0. No constellation illustrations reused; connecting lines are not IAU boundaries.',
                    source_url='https://github.com/Stellarium/stellarium/tree/e835ad6ee5171c9deac2bdb8f1d3003085691197/skycultures/modern', license='CC BY-SA 4.0', license_url='https://creativecommons.org/licenses/by-sa/4.0/')]
    for image in images:
        credits.append(dict(id=image['id'], attribution=image['creator']+'. '+image['modification'],
                            source_url=image['source_url'], license=image['license'], license_url=image['license_url']))
    anatomy = []
    for target in content['anatomy']:
        row = dict(target)
        row['tag_ids'] = ['domain:science', 'skill:spatial', 'topic:biology', 'topic:medical-terms']
        row['hotspots'] = [dict(x=x/spots['width'], y=y/spots['height'], radius=radius/min(spots['width'],spots['height']))
                           for x,y,radius in spots['targets'][row['id']]]
        anatomy.append(row)
    landmarks = []
    for target in content['landmarks']:
        row = {key:value for key,value in target.items() if key not in ('file_title','creator','license','license_url')}
        row.update(image_asset=image_by_id[row['id']]['image_asset'], credit_id=row['id'],
                   tag_ids=sorted(['domain:geography','topic:architecture','skill:recognition','country:'+row['country_iso2'].lower()]))
        landmarks.append(row)
    constellations = []
    for target in content['constellations']:
        row = {key:value for key,value in target.items() if key not in ('star_ids','chains')}
        row.update(stars=[{key:value for key,value in stars[str(sid)].items() if key in ('id','name','ra_hours','dec_degrees','magnitude')}
                          for sid in target['star_ids']],
                   lines=[[str(a),str(b)] for chain in target['chains'] for a,b in zip(chain,chain[1:])],
                   tag_ids=['domain:science','skill:recognition','topic:astronomy'],
                   credit_id='sky-modern' if target.get('line_source')=='stellarium-modern' else 'hyg',
                   source_url=target.get('source_url','https://github.com/astronexus/HYG-Database'))
        constellations.append(row)
    for row in countries+anatomy+landmarks+constellations:
        assert set(row.get('tag_ids',[])) <= known_tags, row['id']
    catalog = dict(schema_version='qm-quizipedia/v1', credits=credits, countries=countries,
                   map_target_ids=content['map_target_iso2'], anatomy=dict(image_asset=spots['image_asset'],
                     width=spots['width'],height=spots['height'],credit_id='endocrine',targets=anatomy),
                   landmarks=landmarks,constellations=constellations,
                   taxonomy_ref={key:taxonomy[key] for key in ('taxonomy_id','taxonomy_sha256')})
    text_manifest = load(BASE / 'text-manifest.json')
    manifest = dict(schema_version='qm-quizipedia-assets/v1', images=images, text_sources=text_manifest,
                    generated_catalog_sha256=hashlib.sha256(encoded(catalog)).hexdigest(),
                    source_subset_sha256={name:hashlib.sha256((BASE/'sources'/name).read_bytes()).hexdigest()
                                          for name in ('world-source.json','stars-source.json')},
                    source_content_sha256=hashlib.sha256((BASE/'content.json').read_bytes()).hexdigest(),
                    hotspot_source_sha256=hashlib.sha256((BASE/'hotspots.json').read_bytes()).hexdigest())
    return catalog, manifest


if __name__ == '__main__':
    catalog, manifest = build()
    OUT.mkdir(parents=True,exist_ok=True)
    (OUT/'catalog.json').write_bytes(encoded(catalog))
    (OUT/'manifest.json').write_bytes(encoded(manifest))
    (BASE/'manifest.json').write_bytes(encoded(manifest))
    print('Built',len(catalog['countries']),'background features;',
          len(catalog['map_target_ids']),len(catalog['anatomy']['targets']),
          len(catalog['landmarks']),len(catalog['constellations']),'learning targets')
