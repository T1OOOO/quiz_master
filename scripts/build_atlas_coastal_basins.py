"""Build coastal water basins from the pinned Natural Earth 1:10m land.

Run: uv run --with shapely python scripts/build_atlas_coastal_basins.py
All coordinates are longitude/latitude; barriers cross narrow straits only.
"""
import json
from pathlib import Path
from shapely.geometry import box, shape, mapping, Point, LineString
from shapely.ops import unary_union, nearest_points
from shapely import make_valid

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'quizipedia/sources/map_v2/ne_10m_admin_0_countries.geojson'
OUTPUT = ROOT / 'quizipedia/sources/map_v2/coastal_basins.geojson'
# Region bounds include land on both sides of each outlet. Barriers extend into land.
BASINS = [
 ('Q4918', 'Mediterranean Sea', (-10, 28, 43, 48), (18, 37), [[(-5.6,35.6),(-5.6,36.5)],[(26.0,40.0),(26.8,40.8)],[(32.0,30.7),(32.9,31.4)]]),
 ('Q166', 'Black Sea', (26, 39, 43, 48), (34, 43), [[(28.7,41.05),(29.5,41.05)],[(36.3,45.0),(37.0,45.6)]]),
 ('Q23406', 'Red Sea', (31, 11, 45, 31), (38, 20), [[(42.3,12.3),(43.7,13.2)],[(32.0,30.7),(32.9,31.4)]]),
 ('Q34675', 'Persian Gulf', (47, 23, 59, 31), (52, 27), [[(56.3,25.8),(56.3,27.6)]]),
 ('Q5484', 'Caspian Sea', (45, 35, 56, 48), (51, 41), []),

]

def main():
    features = json.loads(SOURCE.read_text(encoding='utf-8'))['features']
    land = [make_valid(shape(f['geometry'])) for f in features if f.get('geometry')]
    result = []
    for ident, name, bounds, seed, barriers in BASINS:
        extent = box(*bounds)
        local_land = unary_union([g.intersection(extent) for g in land if g.intersects(extent)])
        water = extent.difference(local_land)
        for ends in barriers:
            start, end = (Point(*p) for p in ends)
            start_land = nearest_points(start, local_land)[1]
            end_land = nearest_points(end, local_land)[1]
            water = water.difference(LineString([start_land, start, end, end_land]).buffer(0.002))
        parts = list(water.geoms) if hasattr(water, 'geoms') else [water]
        matches = [part for part in parts if part.covers(Point(*seed))]
        if len(matches) != 1:
            raise ValueError(f'{ident}: seed not in exactly one water component')
        geom = matches[0]
        if geom.intersects(extent.boundary):
            raise ValueError(f'{ident}: water reaches the local boundary; an outlet is unsealed')
        print(ident, 'area', round(geom.area, 3), flush=True)
        result.append({'type': 'Feature', 'properties': {'id': ident, 'name_en': name}, 'geometry': mapping(geom)})
    OUTPUT.write_text(json.dumps({'type':'FeatureCollection','features':result}, separators=(',', ':')), encoding='utf-8')

if __name__ == '__main__':
    main()
