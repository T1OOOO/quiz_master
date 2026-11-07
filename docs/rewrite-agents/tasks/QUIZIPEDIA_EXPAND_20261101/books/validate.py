"""Validate books/delta.json merged in memory with the live knowledge_atlas.json.

Run: python validate.py   (read-only; writes nothing)
"""
import json
import re
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
ATLAS = Path("E:/Projects/quiz_master/next/apps/quiz_app/assets/quizipedia/knowledge_atlas.json")
CYR = re.compile(r"[\u0400-\u04FF]")
errors = []


def err(msg):
    errors.append(msg)


base = json.loads(ATLAS.read_text(encoding="utf-8"))
delta = json.loads((HERE / "delta.json").read_text(encoding="utf-8"))
works = base["works"] + delta["works"]
people = base["people"] + delta["people"]

for label, rows in (("work", works), ("person", people)):
    ids = [r["id"] for r in rows]
    dup = {i for i in ids if ids.count(i) > 1}
    if dup:
        err(f"duplicate {label} ids: {sorted(dup)}")

wmap = {w["id"]: w for w in works}
pmap = {p["id"]: p for p in people}

W_REQ = ["id", "type", "year", "title_ru", "title_en", "creator_ids", "summary_ru", "summary_en",
         "fact_ru", "fact_en", "source_url"]
P_REQ = ["id", "name_ru", "name_en", "roles", "born", "bio_ru", "bio_en", "source_url", "credit_work_ids"]
W_ALLOWED = set(W_REQ) | {"cast", "approximate", "end_year"}
P_ALLOWED = set(P_REQ)

for w in delta["works"]:
    for k in W_REQ:
        if k not in w or w[k] in ("", None, []):
            err(f"work {w.get('id')}: empty {k}")
    if set(w) - W_ALLOWED:
        err(f"work {w['id']}: unknown keys {set(w) - W_ALLOWED}")
    if w.get("type") != "book" or w.get("cast") != []:
        err(f"work {w['id']}: type must be book with empty cast")
    if not isinstance(w["year"], int):
        err(f"work {w['id']}: year not int")
    if "end_year" in w and w["end_year"] < w["year"]:
        err(f"work {w['id']}: end_year < year")
    if not w["source_url"].startswith("https://"):
        err(f"work {w['id']}: source not https")
    for k in ("title_ru", "summary_ru", "fact_ru"):
        if not CYR.search(w[k]):
            err(f"work {w['id']}: {k} has no Cyrillic")
    for k in ("title_en", "summary_en", "fact_en"):
        if CYR.search(w[k]):
            err(f"work {w['id']}: {k} contains Cyrillic")
    if not (w["title_ru"].startswith("«") and w["title_ru"].endswith("»")):
        err(f"work {w['id']}: title_ru not in guillemets")
    for c in w["creator_ids"]:
        if c not in pmap:
            err(f"work {w['id']}: unknown creator {c}")
        elif w["id"] not in pmap[c]["credit_work_ids"]:
            err(f"work {w['id']}: creator {c} lacks reciprocal credit")

for p in delta["people"]:
    for k in P_REQ:
        if k not in p or p[k] in ("", None, []):
            err(f"person {p.get('id')}: empty {k}")
    if set(p) - P_ALLOWED:
        err(f"person {p['id']}: unknown keys {set(p) - P_ALLOWED}")
    if p["roles"] != ["author"]:
        err(f"person {p['id']}: roles must be ['author']")
    if not p["source_url"].startswith("https://"):
        err(f"person {p['id']}: source not https")
    for k in ("name_ru", "bio_ru", "born"):
        if not (CYR.search(p[k]) or (k == "born" and re.fullmatch(r"\d{4}", p[k]))):
            err(f"person {p['id']}: {k} has no Cyrillic / not a year")
    if CYR.search(p["name_en"]) or CYR.search(p["bio_en"]):
        err(f"person {p['id']}: *_en contains Cyrillic")
    for wid in p["credit_work_ids"]:
        if wid not in wmap:
            err(f"person {p['id']}: unknown work {wid}")
        elif p["id"] not in wmap[wid]["creator_ids"]:
            err(f"person {p['id']}: not a creator of {wid}")

# whole-atlas reciprocity (also proves old rows untouched/consistent)
for w in works:
    for c in w["creator_ids"] + [x[0] for x in w.get("cast", [])]:
        if c not in pmap or w["id"] not in pmap[c]["credit_work_ids"]:
            err(f"atlas: {w['id']} <-> {c} not reciprocal")

# sorted by year inside the delta
years = [w["year"] for w in delta["works"]]
if years != sorted(years):
    err("delta works not sorted by year")

books = [w for w in works if w["type"] == "book"]
authors = [p for p in people if "author" in p["roles"]]
print(f"delta: {len(delta['works'])} works, {len(delta['people'])} people")
print(f"merged: {len(works)} works ({len(books)} books), {len(people)} people ({len(authors)} authors)")
if len(books) < 7 or len(authors) < 7:
    err("not enough books/authors for six-option distractors")

if errors:
    print("FAIL")
    print("\n".join(errors))
    sys.exit(1)
print("OK")
