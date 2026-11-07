"""Validate delta.json against next/apps/quiz_app/assets/quizipedia/country_links.json."""
import json, re, sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
BASE = HERE.parents[4] / "next/apps/quiz_app/assets/quizipedia/country_links.json"
delta = json.loads((HERE / "delta.json").read_text(encoding="utf-8"))
base = json.loads(BASE.read_text(encoding="utf-8"))

errs = []
base_src_ids = {s["id"] for s in base["sources"]}
base_urls = {s["url"] for s in base["sources"]}
base_ids = {i["id"] for l in base["countries"].values() for i in l}
base_names = {i["name_en"].casefold() for l in base["countries"].values() for i in l}
base_names_ru = {i["name_ru"].casefold() for l in base["countries"].values() for i in l}

new_src = {}
for s in delta["sources"]:
    if set(s) != {"id", "title", "url"} or not all(s.values()):
        errs.append(f"bad source {s}")
    if s["id"] in base_src_ids or s["id"] in new_src:
        errs.append(f"source id collision {s['id']}")
    if s["url"] in base_urls:
        errs.append(f"source url already exists (reuse id instead): {s['url']}")
    if not s["url"].startswith("https://"):
        errs.append(f"non-https {s['url']}")
    new_src[s["id"]] = s

assert list(delta["countries"]) == ["TR"], "only TR allowed"
items = delta["countries"]["TR"]
KINDS = {"fact", "scientist"}
FIELDS = {"id", "kind", "name_en", "name_ru", "relation_en", "relation_ru", "source_id"}
seen_ids, seen_names, used_src = set(), set(), set()
cyr = re.compile("[А-Яа-яЁё]")
for it in items:
    if set(it) != FIELDS:
        errs.append(f"fields {it.get('id')}")
    if not all(isinstance(v, str) and v.strip() for v in it.values()):
        errs.append(f"empty field {it.get('id')}")
        continue
    if not re.fullmatch(r"[a-z0-9]+(-[a-z0-9]+)*", it["id"]):
        errs.append(f"id not kebab {it['id']}")
    if it["id"] in base_ids or it["id"] in seen_ids:
        errs.append(f"id duplicate {it['id']}")
    if it["name_en"].casefold() in base_names or it["name_en"].casefold() in seen_names:
        errs.append(f"name_en duplicate {it['name_en']}")
    if it["name_ru"].casefold() in base_names_ru:
        errs.append(f"name_ru duplicate {it['name_ru']}")
    seen_ids.add(it["id"]); seen_names.add(it["name_en"].casefold())
    if it["kind"] not in KINDS:
        errs.append(f"kind {it['id']}")
    sid = it["source_id"]
    if sid not in new_src and sid not in base_src_ids:
        errs.append(f"source_id unresolved {it['id']} -> {sid}")
    used_src.add(sid)
    for f in ("name_ru", "relation_ru"):
        if not cyr.search(it[f]):
            errs.append(f"no Cyrillic in {f} {it['id']}")
    if len(it["relation_en"]) > 190 or len(it["relation_ru"]) > 200:
        errs.append(f"relation too long {it['id']}")
for sid in set(new_src) - used_src:
    errs.append(f"unused new source {sid}")

print(f"items={len(items)} sources={len(new_src)} errors={len(errs)}")
for e in errs:
    print("ERR", e)
sys.exit(1 if errs else 0)
