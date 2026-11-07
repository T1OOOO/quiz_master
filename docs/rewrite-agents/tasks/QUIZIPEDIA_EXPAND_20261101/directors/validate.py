"""Merge delta.json with the live atlas in memory and check the Dart-side invariants."""
import json, re, sys
from pathlib import Path

HERE = Path(__file__).parent
ATLAS = HERE.parents[3].parent / "next/apps/quiz_app/assets/quizipedia/knowledge_atlas.json"
base = json.loads(ATLAS.read_text(encoding="utf-8"))
delta = json.loads((HERE / "delta.json").read_text(encoding="utf-8"))
works = base["works"] + delta["works"]
people = base["people"] + delta["people"]
cyr = re.compile("[А-Яа-яЁё]")
err = []

W_FIELDS = ["id", "type", "year", "title_ru", "title_en", "creator_ids", "cast", "summary_ru",
            "summary_en", "fact_ru", "fact_en", "source_url"]
P_FIELDS = ["id", "name_ru", "name_en", "roles", "born", "bio_ru", "bio_en", "source_url", "credit_work_ids"]

for label, rows in (("work", works), ("person", people)):
    ids = [r["id"] for r in rows]
    if len(set(ids)) != len(ids):
        err.append(f"duplicate {label} ids: {[i for i in set(ids) if ids.count(i) > 1]}")

for kind, rows, fields in (("work", delta["works"], W_FIELDS), ("person", delta["people"], P_FIELDS)):
    for r in rows:
        for f in fields:
            if f not in r or r[f] in ("", None) and f != "cast":
                err.append(f"{kind} {r.get('id')}: missing/empty {f}")
        for f, v in r.items():
            if f.endswith("_ru") and isinstance(v, str) and not cyr.search(v):
                err.append(f"{kind} {r['id']}: no Cyrillic in {f}")
            if f.endswith("_en") and isinstance(v, str) and cyr.search(v):
                err.append(f"{kind} {r['id']}: Cyrillic in {f}")
        if not r["source_url"].startswith("https://"):
            err.append(f"{kind} {r['id']}: source not https")

pid = {p["id"]: p for p in people}
wid = {w["id"]: w for w in works}
for w in works:
    for c in w["creator_ids"] + [c[0] for c in w["cast"]]:
        if c not in pid:
            err.append(f"work {w['id']}: unknown person {c}")
        elif w["id"] not in pid[c]["credit_work_ids"]:
            err.append(f"work {w['id']}: {c} lacks reciprocal credit")
for p in people:
    for c in p["credit_work_ids"]:
        if c not in wid:
            err.append(f"person {p['id']}: unknown work {c}")
        elif p["id"] not in wid[c]["creator_ids"] and not any(x[0] == p["id"] for x in wid[c]["cast"]):
            err.append(f"person {p['id']}: orphan credit {c}")
yrs = [w["year"] for w in delta["works"]]
if yrs != sorted(yrs):
    err.append("delta works not sorted by year")
if not all(w["title_ru"].startswith("«") and w["title_ru"].endswith("»") for w in delta["works"]):
    err.append("title_ru not in guillemets")
for p in delta["people"]:
    if not p["credit_work_ids"]:
        err.append(f"{p['id']} has no credits")

print(f"new works={len(delta['works'])} new people={len(delta['people'])} "
      f"merged works={len(works)} people={len(people)}")
print("\n".join(err) if err else "OK")
sys.exit(1 if err else 0)
