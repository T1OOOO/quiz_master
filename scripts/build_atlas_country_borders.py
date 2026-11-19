#!/usr/bin/env python3
"""Build country land-border facts from the archived CIA World Factbook JSON.

The source snapshot is intentionally pinned.  The output keeps the source's
country-pair wording and numeric precision, while distinguishing absent data
from an explicit zero-length border.
"""
from __future__ import annotations

import argparse
import subprocess
import json
import re
from pathlib import Path

SOURCE_URL = "https://github.com/factbook/factbook.json"
SOURCE_COMMIT = "144d6977b2b01ac1cbd220de754c0a005616760b"
BOUNDARY_RE = re.compile(r"(?P<name>[^;]+?)\s+(?P<km>[\d,]+(?:\.\d+)?)\s*km")


def number(value: str) -> float:
    return float(value.replace(",", ""))


ALIASES = {
    "congo, democratic republic of the": "dr congo",
    "democratic republic of the congo": "dr congo",
    "congo, republic of the": "congo",
    "republic of the congo": "congo",
    "korea, south": "south korea",
    "korea, north": "north korea",
    "holy see": "vatican city",
    "uk": "united kingdom",
    "us": "united states",
    "united states of america": "united states",
}

# A few FIPS filenames are not represented in the existing water-source
# crosswalk. These are stable country-code exceptions from the Factbook tree.
FIPS_OVERRIDES = {"CT": "CF"}


def canonical_name(value: str) -> str:
    value = re.sub(r"\s*\([^)]*\)", "", value)
    value = re.sub(r"^and\s+", "", value.strip(), flags=re.IGNORECASE)
    value = re.sub(r"\s+and\s*$", "", value)
    value = " ".join(value.lower().split()).strip(" ,")
    return ALIASES.get(value, value)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path, help="factbook.json checkout")
    parser.add_argument("country_facts", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--water-crosswalk", type=Path, help="country_waters.json containing factbook-ISO-FIPS source ids")
    args = parser.parse_args()

    revision = subprocess.check_output(
        ["git", "-C", str(args.source), "rev-parse", "HEAD"], text=True
    ).strip()
    if revision != SOURCE_COMMIT:
        parser.error(f"expected Factbook commit {SOURCE_COMMIT}, found {revision}")
    facts = json.loads(args.country_facts.read_text(encoding="utf-8"))
    by_name = {
        canonical_name(row["name_en"]): row["id"]
        for row in facts["countries"]
        if row.get("id") and row.get("name_en")
    }
    fips_to_iso = {}
    if args.water_crosswalk:
        water = json.loads(args.water_crosswalk.read_text(encoding="utf-8"))
        for item in water.get("sources", []):
            match = re.match(r"factbook-([a-z]{2})-([a-z]{2})$", item.get("id", ""))
            if match:
                fips_to_iso[match.group(2).upper()] = match.group(1).upper()
    rows: dict[str, dict] = {}
    for path in sorted(args.source.rglob("*.json")):
        raw = json.loads(path.read_text(encoding="utf-8"))
        boundary = raw.get("Geography", {}).get("Land boundaries", {})
        short_name = (
            ((raw
              .get("Government", {}).get("Country name", {})
              .get("conventional short form", {}) or {}).get("text") or ""
        )
        )
        iso = (
            by_name.get(canonical_name(short_name))
            or fips_to_iso.get(path.stem.upper())
            or FIPS_OVERRIDES.get(path.stem.upper())
        )
        if not iso:
            continue
        total_text = (boundary.get("total") or {}).get("text")
        pairs_text = (boundary.get("border countries") or {}).get("text")
        if not total_text and not pairs_text:
            continue
        pairs = []
        for match in BOUNDARY_RE.finditer(pairs_text or ""):
            name = " ".join(match.group("name").split())
            if canonical_name(name) in {"of which", "total"}:
                continue
            neighbor_id = by_name.get(canonical_name(name))
            if neighbor_id is None:
                continue
            pairs.append({"country_id": neighbor_id, "length_km": number(match.group("km"))})
        rows[iso] = {
            "total_km": number(re.search(r"[\d,.]+", total_text).group()) if total_text else None,
            "total_known": bool(total_text),
            "pairs": pairs,
            "source_file": path.relative_to(args.source).as_posix(),
        }

        for key, value in boundary.items():
            if key.endswith(" - total") and isinstance(value.get("text"), str):
                distance = re.match(r"([\d,.]+)\s*km", value["text"])
                if distance:
                    rows[iso].setdefault("components_km", {})[key[:-8]] = number(distance[1])

    result = {
        "schema": "qm-country-borders/v1",
        "source": {"url": SOURCE_URL, "commit": SOURCE_COMMIT, "field": "Geography/Land boundaries"},
        "countries": rows,
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_bytes((json.dumps(result, ensure_ascii=False, indent=2) + "\n").encode("utf-8"))
    print(f"wrote {len(rows)} countries to {args.output}")


if __name__ == "__main__":
    main()
