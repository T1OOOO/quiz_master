"""Validate delta.json against next/apps/quiz_app/assets/quizipedia/country_links.json.

Run: python validate.py   (from any directory)
"""
import json
import re
import sys
from collections import Counter
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[4]
BASE = ROOT / "next/apps/quiz_app/assets/quizipedia/country_links.json"
KINDS = {"fact", "landmark", "wonder", "filming_location", "scientist", "food", "bridge", "desert", "sports_team", "resource"}
FIELDS = ["id", "kind", "name_en", "name_ru", "relation_en", "relation_ru", "source_id"]
CYR = re.compile(r"[А-Яа-яЁё]")
KEBAB = re.compile(r"^[a-z0-9]+(-[a-z0-9]+)*$")

base = json.loads(BASE.read_text(encoding="utf-8"))
delta = json.loads((HERE / "delta.json").read_text(encoding="utf-8"))
errs = []

assert set(delta) == {"sources", "countries"}, "top-level keys"
assert set(delta["countries"]) == {"TR"}, "only TR allowed"

base_src = {s["id"] for s in base["sources"]}
base_ids = {x["id"] for items in base["countries"].values() for x in items}
base_names = {x["name_en"].lower() for items in base["countries"].values() for x in items}
base_names_ru = {x["name_ru"].lower() for items in base["countries"].values() for x in items}

new_src = {}
for s in delta["sources"]:
    if set(s) != {"id", "title", "url"}:
        errs.append(f"source keys {s.get('id')}")
    if not s["id"].startswith("trm-"):
        errs.append(f"source prefix {s['id']}")
    if s["id"] in base_src or s["id"] in new_src:
        errs.append(f"dup source {s['id']}")
    if not s["url"].startswith("https://") or not s["title"].strip():
        errs.append(f"bad source {s['id']}")
    new_src[s["id"]] = s
all_src = base_src | set(new_src)

items = delta["countries"]["TR"]
used = set()
seen_ids, seen_names = set(), set()
for it in items:
    i = it.get("id", "?")
    if list(it) != FIELDS:
        errs.append(f"{i}: field order/keys {list(it)}")
    for f in FIELDS:
        if not str(it.get(f, "")).strip():
            errs.append(f"{i}: empty {f}")
    if not KEBAB.match(i) or not i.startswith("trm-"):
        errs.append(f"{i}: id format")
    if i in base_ids or i in seen_ids:
        errs.append(f"{i}: duplicate id")
    seen_ids.add(i)
    n = it["name_en"].lower()
    if n in base_names or n in seen_names:
        errs.append(f"{i}: duplicate name_en")
    seen_names.add(n)
    if it["name_ru"].lower() in base_names_ru:
        errs.append(f"{i}: duplicate name_ru")
    if it["kind"] not in KINDS:
        errs.append(f"{i}: kind {it['kind']}")
    if it["source_id"] not in all_src:
        errs.append(f"{i}: unresolved source {it['source_id']}")
    used.add(it["source_id"])
    for f in ("name_ru", "relation_ru"):
        if not CYR.search(it[f]):
            errs.append(f"{i}: no Cyrillic in {f}")
    if CYR.search(it["name_en"] + it["relation_en"]):
        errs.append(f"{i}: Cyrillic in English field")
    if len(it["relation_en"]) > 215:
        errs.append(f"{i}: relation_en {len(it['relation_en'])} chars")
    if len(it["relation_ru"]) > 235:
        errs.append(f"{i}: relation_ru {len(it['relation_ru'])} chars")
    if not it["relation_en"].rstrip().endswith("."):
        errs.append(f"{i}: relation_en without final period")

for s in new_src:
    if s not in used:
        errs.append(f"unused source {s}")

if errs:
    print("FAIL")
    print("\n".join(errs))
    sys.exit(1)
print("OK", len(items), "items,", len(new_src), "sources")
print(dict(Counter(x["kind"] for x in items)))
print("max relation_en", max(len(x["relation_en"]) for x in items), "max relation_ru", max(len(x["relation_ru"]) for x in items))
