"""Append delta.json (RU city items + sources) to country_links.json. Idempotent guard: refuses if any id exists.

Run: python merge.py   (from any directory)
"""
import json
from pathlib import Path

HERE = Path(__file__).resolve().parent
BASE = HERE.parents[3] / "next/apps/quiz_app/assets/quizipedia/country_links.json"

base = json.loads(BASE.read_text(encoding="utf-8"))
delta = json.loads((HERE / "delta.json").read_text(encoding="utf-8"))

sids = {s["id"] for s in base["sources"]}
iids = {i["id"] for v in base["countries"].values() for i in v}
for s in delta["sources"]:
    assert s["id"] not in sids, s["id"]
    sids.add(s["id"])
    base["sources"].append(s)
for c, items in delta["countries"].items():
    for i in items:
        assert i["id"] not in iids, i["id"]
        assert i["source_id"] in sids, i["source_id"]
        iids.add(i["id"])
    base["countries"].setdefault(c, []).extend(items)
BASE.write_text(json.dumps(base, ensure_ascii=False, indent=2) + "\n", encoding="utf-8", newline="\n")
print("merged", sum(len(v) for v in delta["countries"].values()), "items,", len(delta["sources"]), "sources")
