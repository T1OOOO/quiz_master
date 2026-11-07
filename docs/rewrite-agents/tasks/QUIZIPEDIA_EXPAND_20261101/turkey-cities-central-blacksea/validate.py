"""Validate delta.json against next/apps/quiz_app/assets/quizipedia/country_links.json.
Run: python -I validate.py   (from anywhere; paths resolve from this file)."""
import json, re, sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[4]  # .../quiz_master
BASE = ROOT / "next/apps/quiz_app/assets/quizipedia/country_links.json"
KINDS = {"fact", "landmark", "wonder", "filming_location", "scientist", "food", "bridge", "desert", "sports_team", "resource"}
CYR = re.compile(r"[Ѐ-ӿ]")
ITEM_FIELDS = ("id", "kind", "name_en", "name_ru", "relation_en", "relation_ru", "source_id")

base = json.loads(BASE.read_text(encoding="utf-8"))
delta = json.loads((HERE / "delta.json").read_text(encoding="utf-8"))
errs = []
def bad(msg): errs.append(msg)

if set(delta) != {"sources", "countries"}: bad(f"top-level keys {set(delta)}")
if set(delta["countries"]) != {"TR"}: bad(f"countries keys {set(delta['countries'])}")

base_src = {s["id"] for s in base["sources"]}
base_ids = {i["id"] for rows in base["countries"].values() for i in rows}
base_names = {i["name_en"].casefold() for rows in base["countries"].values() for i in rows}
base_names_ru = {i["name_ru"].casefold() for rows in base["countries"].values() for i in rows}

src_ids = set()
for s in delta["sources"]:
    for k in ("id", "title", "url"):
        if not str(s.get(k, "")).strip(): bad(f"source {s.get('id')} empty {k}")
    if not s["id"].startswith("trc-"): bad(f"source id prefix {s['id']}")
    if s["id"] in base_src or s["id"] in src_ids: bad(f"duplicate source id {s['id']}")
    if not s["url"].startswith("https://"): bad(f"non-https url {s['id']}")
    src_ids.add(s["id"])

seen_ids, seen_names, seen_ru, used_src = set(), set(), set(), set()
for r in delta["countries"]["TR"]:
    rid = r.get("id")
    if set(r) != set(ITEM_FIELDS): bad(f"{rid}: fields {sorted(r)}")
    for k in ITEM_FIELDS:
        if not str(r.get(k, "")).strip(): bad(f"{rid}: empty {k}")
    if not re.fullmatch(r"trc-[a-z0-9]+(-[a-z0-9]+)*", rid): bad(f"{rid}: id not kebab trc-")
    if r["kind"] not in KINDS: bad(f"{rid}: kind {r['kind']}")
    if rid in base_ids or rid in seen_ids: bad(f"{rid}: duplicate id")
    n = r["name_en"].casefold()
    if n in base_names or n in seen_names: bad(f"{rid}: duplicate name_en")
    nr = r["name_ru"].casefold()
    if nr in base_names_ru or nr in seen_ru: bad(f"{rid}: duplicate name_ru")
    if r["source_id"] not in src_ids and r["source_id"] not in base_src: bad(f"{rid}: unresolved source_id")
    if r["source_id"] not in src_ids: bad(f"{rid}: source not in delta (expected a new trc- source)")
    for k in ("name_ru", "relation_ru"):
        if not CYR.search(r[k]): bad(f"{rid}: no Cyrillic in {k}")
        if re.search(r"[A-Za-z][Ѐ-ӿ]|[Ѐ-ӿ][A-Za-z]", r[k]): bad(f"{rid}: mixed-script word in {k}")
    if len(r["relation_en"]) > 200 or len(r["relation_ru"]) > 230: bad(f"{rid}: relation too long ({len(r['relation_en'])}/{len(r['relation_ru'])})")
    seen_ids.add(rid); seen_names.add(n); seen_ru.add(nr); used_src.add(r["source_id"])
if src_ids - used_src: bad(f"unused delta sources {sorted(src_ids - used_src)}")

print(f"items={len(seen_ids)} sources={len(src_ids)}")
if errs:
    print("\n".join(errs)); sys.exit(1)
print("OK")
