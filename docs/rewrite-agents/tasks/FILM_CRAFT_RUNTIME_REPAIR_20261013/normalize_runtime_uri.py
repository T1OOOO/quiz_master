#!/usr/bin/env python3
"""Normalize a host import to the runtime's fixed /app source URI and rehash it."""
from __future__ import annotations
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
WORK = Path(__file__).resolve().parent
LOCAL_DRAFT = WORK / "generated-local" / "draft.json"
OUT_DRAFT = WORK / "draft-runtime.json"
REPORT = WORK / "normalization.json"
LOCAL_URI = "quizzes/Preparation/film_craft_20261013.json"
RUNTIME_URI = "/app/quizzes/Preparation/film_craft_20261013.json"
TAGS = ["domain:arts", "domain:screen", "topic:film-production"]


def canonical(value: object) -> bytes:
    return json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(",", ":")).encode("utf-8")


def hashed_without(value: dict, key: str) -> str:
    copied = json.loads(json.dumps(value))
    copied.pop(key, None)
    return hashlib.sha256(canonical(copied)).hexdigest()


def write_json(path: Path, value: object) -> None:
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def main() -> None:
    draft = json.loads(LOCAL_DRAFT.read_text(encoding="utf-8"))
    before = {q["question_id"]: q["revision"]["sha256"] for q in draft["questions"]}
    for q in draft["questions"]:
        if q.get("source") != {"uri": LOCAL_URI}:
            raise SystemExit(f"unexpected imported source for {q.get('question_id')}: {q.get('source')!r}")
        if q.get("editorial_tag_ids") != TAGS:
            raise SystemExit(f"unexpected imported tags for {q.get('question_id')}: {q.get('editorial_tag_ids')!r}")
        q["source"] = {"uri": RUNTIME_URI}
        q["revision"]["sha256"] = hashed_without(q, "revision")
    draft["revision"]["sha256"] = hashed_without(draft, "revision")
    write_json(OUT_DRAFT, draft)
    report = {
        "method": "quizctl ImportWithTaxonomy followed only by host-to-runtime source URI normalization and canonical rehash",
        "local_input_uri": LOCAL_URI,
        "runtime_input_uri": RUNTIME_URI,
        "source_title_absent": all(set(q["source"]) == {"uri"} for q in draft["questions"]),
        "editorial_tag_ids": TAGS,
        "question_revisions_before_uri_normalization": before,
        "question_revisions_after_uri_normalization": {q["question_id"]: q["revision"]["sha256"] for q in draft["questions"]},
        "draft_revision_after_uri_normalization": draft["revision"]["sha256"],
    }
    write_json(REPORT, report)


if __name__ == "__main__":
    main()