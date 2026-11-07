"""Validate delta.json against the existing country_links.json (read-only).

Run: python validate.py   (from any directory; paths are resolved from this file)
"""
import json
import re
import sys
from collections import Counter
from pathlib import Path

HERE = Path(__file__).resolve().parent
ASSET = HERE.parents[4] / "next/apps/quiz_app/assets/quizipedia/country_links.json"
KINDS = {"fact", "landmark", "wonder", "filming_location", "scientist", "food",
         "bridge", "desert", "sports_team", "resource"}
CYR = re.compile(r"[А-Яа-яЁё]")
KEBAB = re.compile(r"^[a-z0-9]+(-[a-z0-9]+)*$")
MIXED = re.compile(r"[А-Яа-яЁё][A-Za-z]|[A-Za-z][А-Яа-яЁё]")  # Latin glued to Cyrillic letter

old = json.loads(ASSET.read_text(encoding="utf-8"))
delta = json.loads((HERE / "delta.json").read_text(encoding="utf-8"))
errors, warns = [], []

old_src = {s["id"] for s in old["sources"]}
new_src = [s["id"] for s in delta["sources"]]
for sid, n in Counter(new_src).items():
    if n > 1:
        errors.append(f"duplicate new source id {sid}")
    if sid in old_src:
        errors.append(f"new source id collides with existing {sid}")
for s in delta["sources"]:
    if not (s.get("title") and s["url"].startswith("https://")):
        errors.append(f"bad source {s}")
all_src = old_src | set(new_src)

old_ids = {i["id"] for rows in old["countries"].values() for i in rows}
old_names = {i["name_en"].strip().lower() for rows in old["countries"].values() for i in rows}
seen = Counter()
total = Counter()
for iso, rows in delta["countries"].items():
    if iso not in old["countries"]:
        errors.append(f"unknown ISO2 {iso}")
    for it in rows:
        i = it.get("id", "?")
        seen[i] += 1
        total[(iso, it["kind"])] += 1
        if set(it) != {"id", "kind", "name_en", "name_ru", "relation_en", "relation_ru", "source_id"}:
            errors.append(f"{i}: wrong keys {sorted(it)}")
        if not KEBAB.match(i):
            errors.append(f"{i}: id is not kebab-case")
        if i in old_ids:
            errors.append(f"{i}: id already exists")
        if it["kind"] not in KINDS:
            errors.append(f"{i}: bad kind {it['kind']}")
        if it["source_id"] not in all_src:
            errors.append(f"{i}: unresolved source {it['source_id']}")
        for k in ("name_en", "name_ru", "relation_en", "relation_ru"):
            if not str(it[k]).strip():
                errors.append(f"{i}: empty {k}")
        for k in ("name_ru", "relation_ru"):
            if not CYR.search(it[k]):
                errors.append(f"{i}: no Cyrillic in {k}")
            if MIXED.search(it[k]):
                warns.append(f"{i}: Latin glued to Cyrillic in {k}: {MIXED.search(it[k]).group(0)}")
        if it["name_en"].strip().lower() in old_names:
            errors.append(f"{i}: name_en duplicates an existing name")
        if len(it["relation_en"]) > 190 or len(it["relation_ru"]) > 230:
            warns.append(f"{i}: long relation en={len(it['relation_en'])} ru={len(it['relation_ru'])}")
        if it["relation_en"].rstrip().endswith("."):
            warns.append(f"{i}: trailing period in relation_en")
for i, n in seen.items():
    if n > 1:
        errors.append(f"duplicate delta id {i}")

kinds = Counter(k for (_, k) in total.elements())
print("items:", sum(seen.values()), "countries:", len(delta["countries"]), "new sources:", len(new_src))
print("by kind:", dict(kinds))
print("per country:", {k: len(v) for k, v in delta["countries"].items()})
for w in warns:
    print("WARN", w)
for e in errors:
    print("ERROR", e)
print("OK" if not errors else f"FAILED ({len(errors)} errors)")
sys.exit(1 if errors else 0)
