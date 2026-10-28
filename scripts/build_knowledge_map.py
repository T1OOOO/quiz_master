"""Build the prototype's WGS84 layers from pinned, offline source snapshots."""
import hashlib
import json
import math
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'next/apps/quiz_app/assets/quizipedia/map_v2'
SOURCES = {
 'quizipedia/sources/world-source.json': ('6866c877d39cba9c357620878839b336d569f8c662d3cfab4cb1dbe2d39c977f', 'https://www.naturalearthdata.com/downloads/110m-cultural-vectors/110m-admin-0-countries/', 'Public domain'),
 'quizipedia/content.json': ('ca0f92acffc7bd76424bb28c56c895f5f062de19eec76d4d4a97498fc449d947', 'Repository country identity exceptions', 'Project data'),
 'docs/rewrite-agents/preparation-country-registry/countries.json': ('78b1bb2d9fbfdb35033022dbdc94c34a89ad472a6cce835c5dd1ec2932f14b04', 'https://unstats.un.org/unsd/methodology/m49/overview/', 'See source registry'),
 'next/apps/quiz_app/assets/quizipedia/capital_points.json': ('7edd476a15c7edab960a0e44d0fa449aa95c094bd191bec8d663b5f622380341', 'https://www.naturalearthdata.com/downloads/10m-cultural-vectors/10m-populated-places/', 'Public domain'),
 'next/apps/quiz_app/assets/quizipedia/waterways.json': ('cb884b1a74fbfdaea11176c51045d37ae19546b1cc9c2ad6763d91dbd0bd9593', 'Repository waterway identities', 'Public domain'),
 'next/apps/quiz_app/assets/quizipedia/country_facts.json': ('38283995143f52f4a82e947fc35cc5eb4b7419f92debd3697cd71d2728821063', 'Repository country facts registry', 'See source country_facts.json'),
 'quizipedia/sources/map_v2/ne_110m_lakes.geojson': ('eb02ecc86c82004fccbf979058bfabbbd6c2d07968c7844d38eb1c9152d2ffc9', 'https://raw.githubusercontent.com/nvkelso/natural-earth-vector/master/geojson/ne_110m_lakes.geojson', 'Public domain'),
 'quizipedia/sources/map_v2/ne_110m_rivers_lake_centerlines.geojson': ('55aa4497405afc07cdc931b7fbe062c4d6693ba2a550c0d24899953f5d507c8d', 'https://raw.githubusercontent.com/nvkelso/natural-earth-vector/master/geojson/ne_110m_rivers_lake_centerlines.geojson', 'Public domain'),
 'quizipedia/sources/map_v2/ne_110m_geography_marine_polys.geojson': ('b9c3f7f557d0ff5217906adc82b66ecdac14aa7438df7e518cf6675d037bceb8', 'https://raw.githubusercontent.com/nvkelso/natural-earth-vector/master/geojson/ne_110m_geography_marine_polys.geojson', 'Public domain'),
}

def checked_read(path, expected):
    data = path.read_bytes()
    if hashlib.sha256(data).hexdigest() != expected:
        raise ValueError(f'hash mismatch: {path}')
    return json.loads(data.decode('utf-8-sig'))

def validate_geometry(geometry):
    typ, coords = geometry['type'], geometry['coordinates']
    def point(p):
        if len(p)!=2 or not all(type(x) in (int,float) and math.isfinite(x) for x in p) or not (-180 <= p[0] <= 180 and -90 <= p[1] <= 90):
            raise ValueError('invalid WGS84 point')
    def line(p):
        if len(p)<2: raise ValueError('short line')
        for x in p: point(x)
    def polygon(p):
        if not p: raise ValueError('empty polygon')
        for ring in p:
            if len(ring)<4 or ring[0]!=ring[-1]: raise ValueError('invalid ring')
            line(ring)
    if typ=='Point': point(coords)
    elif typ=='LineString': line(coords)
    elif typ=='MultiLineString':
        if not coords: raise ValueError('empty multilinestring')
        for p in coords: line(p)
    elif typ=='Polygon': polygon(coords)
    elif typ=='MultiPolygon':
        if not coords: raise ValueError('empty multipolygon')
        for p in coords: polygon(p)
    else: raise ValueError(f'unsupported geometry: {typ}')

def feature(id, ru, en, kind, geometry, country_id=None):
    validate_geometry(geometry)
    props = dict(id=id, name_ru=ru, name_en=en, kind=kind)
    if country_id: props['country_id'] = country_id
    return dict(type='Feature', id=id, properties=props, geometry=geometry)

def build():
    data = {p:checked_read(ROOT/p, meta[0]) for p,meta in SOURCES.items()}
    registry={r['iso2']:r for r in data['docs/rewrite-agents/preparation-country-registry/countries.json']['countries']}
    exceptions=data['quizipedia/content.json']['geometry_exceptions']
    facts={r['id']:r for r in data['next/apps/quiz_app/assets/quizipedia/country_facts.json']['countries']}
    crosswalk={'TWN':'TW', 'KOS':'XK'}
    if any(iso not in facts for iso in crosswalk.values()):
        raise ValueError('crosswalk ID missing from country facts')
    countries=[]; country_labels=[]; omitted=[]
    for f in data['quizipedia/sources/world-source.json']['features']:
        p=f['properties']; iso=crosswalk.get(p['ADM0_A3'], exceptions.get(p['ADM0_A3'],p['ISO_A2']))
        if len(iso)!=2 or not iso.isalpha() or not iso.isupper():
            omitted.append(p['ADM0_A3']); continue
        names=registry.get(iso) or (facts[iso] if p['ADM0_A3'] in crosswalk else None); ident=iso if names else 'ne-'+p['ADM0_A3'].lower()
        country=feature(ident, names['name_ru'] if names else p['NAME_RU'], names['name_en'] if names else p['NAME_EN'], 'country', f['geometry'], iso)
        countries.append(country)
        label=feature(iso, country['properties']['name_ru'], country['properties']['name_en'], 'country', {'type':'Point','coordinates':[p['LABEL_X'], p['LABEL_Y']]}, iso)
        label['properties']['anchor_source']='natural-earth-label'
        country_labels.append(label)
    capitals=[]
    label_ids={f['id'] for f in country_labels}
    for p in data['next/apps/quiz_app/assets/quizipedia/capital_points.json']['capitals']:
        # The existing MS row is Plymouth, England, not Montserrat.
        if p['country_id'] == 'MS': continue
        reg=registry.get(p['country_id']); names=reg['capitals'] if reg else []
        match=next((n for n in names if n['name_en'].casefold()==p['name'].casefold()), None)
        capitals.append(feature('capital-'+str(p['ne_id']), match['name_ru'] if match else p['name'], p['name'], 'capital', {'type':'Point','coordinates':[p['longitude'],p['latitude']]},p['country_id']))
        iso=p['country_id']
        if iso not in label_ids:
            names=facts[iso]
            label=feature(iso,names['name_ru'],names['name_en'],'country',{'type':'Point','coordinates':[p['longitude'],p['latitude']]},iso)
            label['properties']['anchor_source']='capital-point'
            country_labels.append(label)
            label_ids.add(iso)
    water={p['id']:p for p in data['next/apps/quiz_app/assets/quizipedia/waterways.json']['features']}
    waterways=[]
    for path in list(SOURCES)[-3:]:
        for f in data[path]['features']:
            row=water.get(f['properties']['wikidataid'])
            if row: waterways.append(feature(row['id'],row['name_ru'],row['name_en'],row['kind'],f['geometry']))
    merged={}
    for f in waterways:
        if f['id'] not in merged:
            merged[f['id']]=f
            continue
        old=merged[f['id']]['geometry']; new=f['geometry']
        base=old['type'].removeprefix('Multi')
        if new['type'].removeprefix('Multi') != base: raise ValueError('incompatible waterway geometry')
        old_parts=old['coordinates'] if old['type'].startswith('Multi') else [old['coordinates']]
        new_parts=new['coordinates'] if new['type'].startswith('Multi') else [new['coordinates']]
        merged[f['id']]['geometry']={'type':'Multi'+base,'coordinates':old_parts+new_parts}
    waterways=list(merged.values())
    layers={name+'.geojson':{'type':'FeatureCollection','features':sorted(rows,key=lambda f:f['id'])} for name,rows in [('countries',countries),('country_labels',country_labels),('capitals',capitals),('waterways',waterways),('landmarks',[])]}
    for name,collection in layers.items():
        ids=[f['id'] for f in collection['features']]
        if len(ids)!=len(set(ids)): raise ValueError('duplicate id in '+name)
    manifest={'schema_version':'qm-geography/v1','sources':[{'path':p,'sha256':v[0],'url':v[1],'license':v[2]} for p,v in SOURCES.items()], 'counts':{p:len(c['features']) for p,c in layers.items()}, 'coverage_notes':['Natural Earth 1:110m uses generalized boundaries and omits small islands.', 'Country labels use Natural Earth label anchors for shapes and first capital points for 44 additional countries; country facts without either have no marker.', 'Unmapped disputed country geometries are omitted without assigning another country: '+', '.join(sorted(omitted)), 'Montserrat (MS) is omitted: its existing Plymouth capital point is Plymouth, England, not Montserrat.', 'Landmarks are empty until coordinates and sources are verified.', 'Capital names without a matching Russian registry label retain the source name.', 'Waterways carry no inferred country relationship.']}
    return layers,manifest

def encoded(value):
    return (json.dumps(value,ensure_ascii=False,sort_keys=True,separators=(',',':'))+'\n').encode('utf8')

def serialize_build(layers,manifest):
    result={p:encoded(v) for p,v in layers.items()}
    manifest=dict(manifest, outputs={p:hashlib.sha256(b).hexdigest() for p,b in result.items()})
    result['manifest.json']=encoded(manifest)
    return result

if __name__=='__main__':
    result=serialize_build(*build())
    OUT.mkdir(parents=True,exist_ok=True)
    for name,content in result.items(): (OUT/name).write_bytes(content)
