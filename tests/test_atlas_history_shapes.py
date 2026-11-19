import json
from pathlib import Path


ROOT = Path(__file__).parents[1] / "next/apps/quiz_app/assets/quizipedia/map_v2"


def load_pack(century):
    return json.loads((ROOT / f"historical_shapes_{century}.json").read_text(encoding="utf-8"))


def active(rows, year):
    return [row for row in rows if row[1] <= year <= row[2]]


def test_all_five_cliopatria_century_packs_have_valid_polygons_and_intervals():
    for century in range(16, 21):
        pack = load_pack(century)
        assert pack["polities"]
        for name, start, end, geometry in pack["polities"]:
            assert isinstance(name, str) and name.strip()
            assert isinstance(start, int) and isinstance(end, int)
            assert 1 <= start <= end <= 2023
            assert geometry
            for polygon in geometry:
                assert polygon
                for ring in polygon:
                    assert len(ring) >= 4
                    assert ring[0] == ring[-1]
                    for lon, lat in ring:
                        assert -180 <= lon <= 180
                        assert -90 <= lat <= 90


def test_historical_boundaries_cover_soviet_union_in_1980_but_not_1999():
    rows = load_pack(20)["polities"]
    soviet = lambda year: any("Soviet Socialist" in row[0] for row in active(rows, year))
    assert soviet(1980)
    assert not soviet(1999)


def test_german_democratic_republic_ends_in_1990():
    rows = load_pack(20)["polities"]
    gdr = lambda year: any("German Democratic Republic" in row[0] for row in active(rows, year))
    assert gdr(1989)
    assert gdr(1990)
    assert not gdr(1991)
