"""Build the tiny Mercator starter image from the same outlines used by the atlas."""
import json
import math
from pathlib import Path

from PIL import Image, ImageDraw

APP = Path(__file__).resolve().parents[1] / "next/apps/quiz_app"
SIZE = 2048
SEA, LAND, BORDER = "#b6cac0", "#f3e9cf", "#969981"


def point(coordinate):
    lon, lat = coordinate[:2]
    latitude = math.radians(max(-85.05112878, min(85.05112878, lat)))
    x = (lon + 180) / 360 * SIZE
    y = (1 - math.asinh(math.tan(latitude)) / math.pi) / 2 * SIZE
    return round(x), round(y)


def main():
    data = json.loads(
        (APP / "assets/quizipedia/map_v2/countries_overview.geojson").read_bytes()
    )
    polygons = []
    for feature in data["features"]:
        geometry = feature["geometry"]
        rings = geometry["coordinates"]
        for polygon in [rings] if geometry["type"] == "Polygon" else rings:
            polygons.append([[point(position) for position in ring] for ring in polygon])

    image = Image.new("RGB", (SIZE, SIZE), SEA)
    draw = ImageDraw.Draw(image)
    for polygon in polygons:
        if polygon and len(polygon[0]) > 2:
            draw.polygon(polygon[0], fill=LAND)
    for polygon in polygons:
        for ring in polygon:
            if len(ring) > 2:
                draw.line(ring, fill=BORDER, width=1)
    image.resize((1552, 1552), Image.Resampling.LANCZOS).save(
        APP / "web/atlas-overview.webp", quality=84, method=6
    )


if __name__ == "__main__":
    main()
