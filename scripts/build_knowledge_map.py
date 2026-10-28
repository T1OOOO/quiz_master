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
 'quizipedia/landmark_locations.geojson': ('77a95d4d205041552d9de88f49256f3984563991b72762e83ef1763e6f532c7b', 'https://www.wikidata.org/', 'CC0 coordinates; see individual image metadata'),
 'next/apps/quiz_app/assets/quizipedia/catalog.json': ('0ef534bac377c150e3bf3109d7dea96fb56e1e68f8bbc04c81adc5804d2d984b', 'Repository landmark catalog', 'See individual image metadata'),
 'quizipedia/sources/map_v2/ne_10m_admin_0_countries.geojson': ('239eec57ac17f100a11e2536cffc56752c318b50ae765b0918ff7aab4ce8f255', 'https://raw.githubusercontent.com/nvkelso/natural-earth-vector/v5.1.2/geojson/ne_10m_admin_0_countries.geojson', 'Public domain'),
 'quizipedia/sources/map_v2/ne_10m_rivers_lake_centerlines_scale_rank.geojson': ('65dca1bd1729a347dda0837f41b5d152252e33abd2d7ff3370a0539c33bdf89b', 'https://raw.githubusercontent.com/nvkelso/natural-earth-vector/v5.1.2/geojson/ne_10m_rivers_lake_centerlines_scale_rank.geojson', 'Public domain'),
 'quizipedia/sources/map_v2/ne_10m_lakes.geojson': ('2d036f53dedec578001c5c30c2959ee7d4eebc1306900fa4367c49929ec8f2d9', 'https://raw.githubusercontent.com/nvkelso/natural-earth-vector/v5.1.2/geojson/ne_10m_lakes.geojson', 'Public domain'),
 'quizipedia/sources/map_v2/ne_110m_lakes.geojson': ('eb02ecc86c82004fccbf979058bfabbbd6c2d07968c7844d38eb1c9152d2ffc9', 'https://raw.githubusercontent.com/nvkelso/natural-earth-vector/master/geojson/ne_110m_lakes.geojson', 'Public domain'),
 'quizipedia/sources/map_v2/ne_110m_rivers_lake_centerlines.geojson': ('55aa4497405afc07cdc931b7fbe062c4d6693ba2a550c0d24899953f5d507c8d', 'https://raw.githubusercontent.com/nvkelso/natural-earth-vector/master/geojson/ne_110m_rivers_lake_centerlines.geojson', 'Public domain'),
 'quizipedia/sources/map_v2/ne_110m_geography_marine_polys.geojson': ('b9c3f7f557d0ff5217906adc82b66ecdac14aa7438df7e518cf6675d037bceb8', 'https://raw.githubusercontent.com/nvkelso/natural-earth-vector/master/geojson/ne_110m_geography_marine_polys.geojson', 'Public domain'),
}

# IDs retained only after bidirectional geographic coverage checks.
DETAILED_RIVER_IDS = {'Q1653', 'Q46841'}

def line_points(geometry):
    return [geometry['coordinates']] if geometry['type']=='LineString' else geometry['coordinates']

def river_near_reference(geometry, references):
    # Reject accidental name collisions; 110m geometry is coarser than 10m.
    reference=[p for g in references for line in line_points(g) for p in line]
    points=[p for line in line_points(geometry) for p in line]
    sample=points[::max(1,len(points)//40)]
    if not reference or not sample: return False
    near=sum(any((p[0]-q[0])**2+(p[1]-q[1])**2 <= 0.75**2 for q in reference) for p in sample)
    return near/len(sample) >= 0.75

def river_reference_covered(references, detailed):
    old=[p for g in references for line in line_points(g) for p in line]
    new=[p for g in detailed for line in line_points(g) for p in line]
    if not old or not new: return False
    near=sum(any((p[0]-q[0])**2+(p[1]-q[1])**2 <= 0.5**2 for q in new) for p in old)
    return near/len(old) >= 0.95

def river_segments_connected(geometries):
    lines=[line for g in geometries for line in line_points(g)]
    if not lines: return False
    seen={0}
    while True:
        added={j for i in seen for j in range(len(lines)) if j not in seen and
               min((a[0]-b[0])**2+(a[1]-b[1])**2 for a in (lines[i][0],lines[i][-1]) for b in (lines[j][0],lines[j][-1])) <= 0.05**2}
        if not added: return len(seen)==len(lines)
        seen.update(added)

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

def water_anchor(geometry):
    typ=geometry['type']; coords=geometry['coordinates']
    if typ in ('LineString','MultiLineString'):
        lines=[coords] if typ=='LineString' else coords
        longest=max(lines,key=len)
        return longest[len(longest)//2]
    polygons=[coords] if typ=='Polygon' else coords
    best=None
    for polygon in polygons:
        ring=polygon[0]
        low=min(p[1] for p in ring); high=max(p[1] for p in ring)
        for fraction in (0.5,0.25,0.75):
            y=low+(high-low)*fraction
            crossings=[]
            for r in polygon:
                for a,b in zip(r,r[1:]):
                    if (a[1]>y)!=(b[1]>y):
                        crossings.append(a[0]+(y-a[1])*(b[0]-a[0])/(b[1]-a[1]))
            crossings.sort()
            for left,right in zip(crossings[::2],crossings[1::2]):
                if best is None or right-left>best[0]: best=(right-left,[(left+right)/2,y])
    if best is None or best[0]<=0: raise ValueError('no interior water label point')
    return best[1]

def build():
    data = {p:checked_read(ROOT/p, meta[0]) for p,meta in SOURCES.items()}
    registry={r['iso2']:r for r in data['docs/rewrite-agents/preparation-country-registry/countries.json']['countries']}
    exceptions=data['quizipedia/content.json']['geometry_exceptions']
    facts={r['id']:r for r in data['next/apps/quiz_app/assets/quizipedia/country_facts.json']['countries']}
    crosswalk={'TWN':'TW', 'KOS':'XK'}
    if any(iso not in facts for iso in crosswalk.values()):
        raise ValueError('crosswalk ID missing from country facts')
    countries=[]; country_labels=[]; omitted=[]; legacy={}
    for f in data['quizipedia/sources/world-source.json']['features']:
        p=f['properties']; iso=crosswalk.get(p['ADM0_A3'], exceptions.get(p['ADM0_A3'],p['ISO_A2']))
        if len(iso)!=2 or not iso.isalpha() or not iso.isupper():
            omitted.append(p['ADM0_A3']); continue
        names=registry.get(iso) or (facts[iso] if p['ADM0_A3'] in crosswalk else None); ident=iso if names else 'ne-'+p['ADM0_A3'].lower()
        country=feature(ident, names['name_ru'] if names else p['NAME_RU'], names['name_en'] if names else p['NAME_EN'], 'country', f['geometry'], iso)
        legacy[iso]=country
        label=feature(iso, country['properties']['name_ru'], country['properties']['name_en'], 'country', {'type':'Point','coordinates':[p['LABEL_X'], p['LABEL_Y']]}, iso)
        label['properties']['anchor_source']='natural-earth-label'
        country_labels.append(label)
    for f in data['quizipedia/sources/map_v2/ne_10m_admin_0_countries.geojson']['features']:
        p=f['properties']; iso=crosswalk.get(p['ADM0_A3'], exceptions.get(p['ADM0_A3'],p['ISO_A2']))
        if iso not in facts: continue
        old=legacy.get(iso); names=facts[iso]
        countries.append(feature(old['id'] if old else iso, old['properties']['name_ru'] if old else names['name_ru'], old['properties']['name_en'] if old else names['name_en'], 'country', f['geometry'], iso))
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
    for f in data['quizipedia/sources/map_v2/ne_10m_admin_0_countries.geojson']['features']:
        p=f['properties']; iso=crosswalk.get(p['ADM0_A3'],exceptions.get(p['ADM0_A3'],p['ISO_A2']))
        if iso in facts and iso not in label_ids:
            names=facts[iso]
            label=feature(iso,names['name_ru'],names['name_en'],'country',{'type':'Point','coordinates':[p['LABEL_X'],p['LABEL_Y']]},iso)
            label['properties']['anchor_source']='natural-earth-10m-label'
            country_labels.append(label); label_ids.add(iso)
    water={p['id']:p for p in data['next/apps/quiz_app/assets/quizipedia/waterways.json']['features']}
    waterways=[]
    for path in ('quizipedia/sources/map_v2/ne_10m_lakes.geojson','quizipedia/sources/map_v2/ne_110m_rivers_lake_centerlines.geojson','quizipedia/sources/map_v2/ne_110m_geography_marine_polys.geojson'):
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
    old_rivers={ident:[f['geometry'] for f in waterways if f['id']==ident] for ident in DETAILED_RIVER_IDS}
    detailed={ident:[] for ident in DETAILED_RIVER_IDS}
    for f in data['quizipedia/sources/map_v2/ne_10m_rivers_lake_centerlines_scale_rank.geojson']['features']:
        ident=f['properties']['wikidataid']
        if ident in detailed:
            if not river_near_reference(f['geometry'],old_rivers[ident]): raise ValueError('river location mismatch: '+ident)
            detailed[ident].append(f['geometry'])
    for ident in DETAILED_RIVER_IDS:
        if not river_reference_covered(old_rivers[ident],detailed[ident]): raise ValueError('river coverage incomplete: '+ident)
        if not river_segments_connected(detailed[ident]): raise ValueError('disconnected river: '+ident)
        merged[ident]['geometry']={'type':'MultiLineString','coordinates':[line for geometry in detailed[ident] for line in line_points(geometry)]}
    waterways=list(merged.values())
    river_detail=[]
    source=data['quizipedia/sources/map_v2/ne_10m_rivers_lake_centerlines_scale_rank.geojson']['features']
    for index, f in enumerate(source):
        props=f['properties']; cls=props['featurecla']
        if cls not in ('River','River (Intermittent)'): continue
        geometry=f['geometry']
        if geometry['type'] not in ('LineString','MultiLineString'): raise ValueError('invalid detailed river type')
        validate_geometry(geometry)
        zoom=props['min_zoom']
        if type(zoom) not in (int,float) or not math.isfinite(zoom): raise ValueError('invalid detailed river min_zoom')
        ident='ne10-river-'+str(index)
        properties={'id':ident,'kind':'river','min_zoom':zoom,'intermittent':cls=='River (Intermittent)'}
        water_id=props.get('wikidataid')
        if water_id in DETAILED_RIVER_IDS and water.get(water_id,{}).get('kind')=='river' and river_near_reference(geometry,old_rivers[water_id]):
            properties['water_id']=water_id
        river_detail.append({'type':'Feature','id':ident,'properties':properties,'geometry':geometry})
    lake_detail=[]
    source=data['quizipedia/sources/map_v2/ne_10m_lakes.geojson']['features']
    for index, f in enumerate(source):
        props=f['properties']; geometry=f['geometry']
        if props['featurecla'] not in ('Lake','Reservoir','Alkaline Lake') or geometry['type'] not in ('Polygon','MultiPolygon'):
            raise ValueError('invalid detailed lake feature')
        validate_geometry(geometry)
        zoom=props['min_zoom']
        if type(zoom) not in (int,float) or not math.isfinite(zoom): raise ValueError('invalid detailed lake min_zoom')
        ident='ne10-lake-'+str(index)
        properties={'id':ident,'kind':'lake','min_zoom':zoom}
        water_id=props.get('wikidataid')
        if water.get(water_id,{}).get('kind')=='lake' and water_id in merged and merged[water_id]['geometry']==geometry:
            properties['water_id']=water_id
        lake_detail.append({'type':'Feature','id':ident,'properties':properties,'geometry':geometry})
    landmarks=data['quizipedia/landmark_locations.geojson']['features']
    catalog=data['next/apps/quiz_app/assets/quizipedia/catalog.json']['landmarks']
    if {f['id'] for f in landmarks}!={r['id'] for r in catalog}: raise ValueError('landmark catalog mismatch')
    for f in landmarks:
        if f['type']!='Feature' or f['geometry']['type']!='Point' or f['id']!=f['properties']['id']: raise ValueError('invalid landmark')
        validate_geometry(f['geometry'])
        if any(not f['properties'].get(k) for k in ('country_id','name_ru','name_en','explanation_ru','explanation_en','source_url','coordinate_source_url','wikidata_id','image_attribution','image_license','image_source_url')): raise ValueError('missing landmark provenance')
    water_labels=[feature(f['id'],f['properties']['name_ru'],f['properties']['name_en'],f['properties']['kind'],{'type':'Point','coordinates':water_anchor(f['geometry'])}) for f in waterways if f['properties']['kind'] in ('river','lake')]
    layers={name+'.geojson':{'type':'FeatureCollection','features':sorted(rows,key=lambda f:f['id'])} for name,rows in [('countries',countries),('country_labels',country_labels),('capitals',capitals),('waterways',waterways),('rivers_detail',river_detail),('lakes_detail',lake_detail),('water_labels',water_labels),('landmarks',landmarks)]}
    for name,collection in layers.items():
        ids=[f['id'] for f in collection['features']]
        if len(ids)!=len(set(ids)): raise ValueError('duplicate id in '+name)
    manifest={'schema_version':'qm-geography/v1','sources':[{'path':p,'sha256':v[0],'url':v[1],'license':v[2]} for p,v in SOURCES.items()], 'counts':{p:len(c['features']) for p,c in layers.items()}, 'coverage_notes':['Country and lake geometry uses Natural Earth 1:10m. The Danube and Lena use 1:10m river geometry matched by Wikidata ID and checked against 110m coverage; other rivers and marine features remain 1:110m.', 'Country labels preserve existing 110m anchors and capital fallbacks; additional 10m shapes use 10m label anchors. Facts without a shape or verified capital have no marker.', 'Legacy 110m disputed geometries were not assigned another country: '+', '.join(sorted(omitted)), 'Montserrat uses its 1:10m country label; its existing Plymouth capital point is omitted because it is Plymouth, England.', 'Capital names without a matching Russian registry label retain the source name.', 'Detailed physical rivers contain Natural Earth 1:10m River and River (Intermittent) classes without inferred identities; lake centerlines and canals are excluded.', 'Detailed physical lakes contain all Natural Earth 1:10m Lake, Reservoir and Alkaline Lake polygons without inferred identities.', 'Waterways carry no inferred country relationship.']}
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
