"""Convert pinned Natural Earth 1:110m sources without simplifying their geometry.

Usage: python tool/build_waterways.py SOURCE_DIRECTORY
Sources and their SHA256 are recorded in the shipped asset. Public domain.
"""
import hashlib, json, math, sys
from pathlib import Path

root = Path(__file__).resolve().parents[1]
source = Path(sys.argv[1])
pins = json.loads((root.parents[2]/'docs/rewrite-agents/tasks/WATER_PHOTO_20261020/water-source-manifest.json').read_text(encoding='utf-8'))
pins = {row['file']: row['sha256'] for row in pins['files']}
countries = json.loads((root/'assets/quizipedia/catalog.json').read_text(encoding='utf-8'))['countries']

def inside(p, ring):
    x, y = p; result = False
    for a, b in zip(ring, ring[1:]+ring[:1]):
        if (a[1] > y) != (b[1] > y) and x < (b[0]-a[0])*(y-a[1])/(b[1]-a[1])+a[0]:
            result = not result
    return result

def in_polygon(p, poly):
    return inside(p, poly[0]) and not any(inside(p, r) for r in poly[1:])

def bounds(poly):
    ring = poly[0]
    return min(p[0] for p in ring), min(p[1] for p in ring), max(p[0] for p in ring), max(p[1] for p in ring)

land = [(bounds(poly), poly) for country in countries for poly in country['polygons']]
def on_land(p):
    return any(x0 <= p[0] <= x1 and y0 <= p[1] <= y1 and in_polygon(p, poly)
               for (x0,y0,x1,y1),poly in land)

def distance2(p, a, b):
    dx,dy=b[0]-a[0],b[1]-a[1]; n=dx*dx+dy*dy
    t=max(0,min(1,((p[0]-a[0])*dx+(p[1]-a[1])*dy)/n)) if n else 0
    return (p[0]-a[0]-t*dx)**2+(p[1]-a[1]-t*dy)**2

def anchor(polygons, marine):
    candidates=[]
    for poly in polygons:
        x0,y0,x1,y1=bounds(poly)
        for i in range(1,40):
            for j in range(1,40):
                p=[round(x0+(x1-x0)*i/40,6),round(y0+(y1-y0)*j/40,6)]
                if in_polygon(p,poly) and not (marine and on_land(p)):
                    clearance=min(distance2(p,a,b) for ring in poly for a,b in zip(ring,ring[1:]))
                    candidates.append((clearance,p))
    assert candidates, 'No interior label anchor'
    return max(candidates)[1]

def point(p):
    return [round((p[0]+180)/360,6),round((90-p[1])/180,6)]

rows={}; provenance=[]
for filename,kind in [('ne_110m_lakes.geojson','lake'),('ne_110m_rivers_lake_centerlines.geojson','river'),('ne_110m_geography_marine_polys.geojson','marine')]:
    data=(source/filename).read_bytes()
    assert hashlib.sha256(data).hexdigest() == pins[filename], 'Source differs from reviewed snapshot: '+filename
    provenance.append(dict(url='https://raw.githubusercontent.com/nvkelso/natural-earth-vector/master/geojson/'+filename,sha256=hashlib.sha256(data).hexdigest()))
    for feature in json.loads(data)['features']:
        props=feature['properties']; geo=feature['geometry']; ident=props['wikidataid']
        row=rows.setdefault(ident,dict(id=ident,name_ru=props['name_ru'],name_en=props['name_en'],kind=kind,polygons=[],lines=[]))
        assert row['kind']==kind
        coordinates=geo['coordinates']
        if geo['type']=='LineString': row['lines'].append([point(p) for p in coordinates])
        else:
            for poly in ([coordinates] if geo['type']=='Polygon' else coordinates):
                row['polygons'].append([[point(p) for p in ring] for ring in poly])

for row in rows.values():
    if row['lines']:
        line=max(row['lines'],key=lambda l:sum(math.dist(a,b) for a,b in zip(l,l[1:])))
        row['anchor']=line[len(line)//2]
    else: row['anchor']=anchor(row['polygons'],row['kind']=='marine')
assert len(rows)==63
assert len({row['name_ru'] for row in rows.values()})==63
payload=dict(schema_version='qm-waterways/v1',source_url='https://www.naturalearthdata.com/',license='Public domain',scale='1:110m',sources=provenance,features=sorted(rows.values(),key=lambda r:r['name_ru']))
path=root/'assets/quizipedia/waterways.json'
path.write_bytes((json.dumps(payload,ensure_ascii=False,separators=(',',':'))+'\n').encode())
print('Water geometry:',len(rows),'objects,',path.stat().st_size,'bytes')
