"""Build lazy century packs. Run with uv run --python 3.13 --with shapely python."""
import hashlib
import json
import sys
from pathlib import Path
from zipfile import ZipFile

from shapely.geometry import shape
from shapely.ops import unary_union

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "next/apps/quiz_app/assets/quizipedia/map_v2"
SHA256 = "a1c4a935886557ef5858d97294d78c7854319b8879c4a7d181c5497d7f62f524"
SOURCE = "https://doi.org/10.5281/zenodo.13363121"


def polygons(geometry):
    parts = geometry.geoms if geometry.geom_type == "MultiPolygon" else [geometry]
    result = []
    for part in parts:
        if part.geom_type != "Polygon" or part.is_empty:
            continue
        rings = []
        for ring in (part.exterior, *part.interiors):
            points = [[round(x, 3), round(y, 3)] for x, y, *_ in ring.coords]
            if len(set(map(tuple, points))) >= 3:
                rings.append(points)
        if rings:
            result.append(rings)
    return result


def save(name, obj):
    (OUT / name).write_bytes(json.dumps(obj, ensure_ascii=False, separators=(",", ":")).encode("utf8"))


def main(archive):
    if hashlib.sha256(archive.read_bytes()).hexdigest() != SHA256:
        raise ValueError("Expected Cliopatria v0.0.1 original geojson.zip")
    buckets = {century: [] for century in range(16, 21)}
    with ZipFile(archive) as input_zip, input_zip.open("cliopatria.geojson") as file:
        # This pinned file contains one complete feature per line.
        for line in file:
            if not line.startswith(b'{ "type": "Feature",'):
                continue
            feature = json.loads(line.rstrip().rstrip(b","))
            p = feature["properties"]
            start, end = p["FromYear"], p["ToYear"]
            if p["Type"] != "POLITY" or end < 1501 or start > 2000:
                continue
            rings = polygons(shape(feature["geometry"]).simplify(.18, preserve_topology=True))
            if not rings:
                continue
            row = [p["Name"], start, end, rings]
            for century, records in buckets.items():
                if start <= century * 100 and end >= (century - 1) * 100 + 1:
                    records.append(row)
    for c, records in buckets.items():
        if not records:
            raise ValueError(f"Empty century {c}")
        save(f"historical_shapes_{c}.json", {"source": SOURCE, "polities": records})
        print(c, len(records))
    base = json.loads((ROOT / "quizipedia/sources/world-source.json").read_bytes())
    coast = unary_union([shape(f["geometry"]).buffer(0) for f in base["features"]])
    save("historical_land.json", polygons(coast.simplify(.18, preserve_topology=True)))


if __name__ == "__main__":
    main(Path(sys.argv[1]))
