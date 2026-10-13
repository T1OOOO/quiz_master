#!/usr/bin/env python3
"""Install the validated Film Craft canonical outputs and prove constrained repair."""
from __future__ import annotations
import hashlib
import json
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
WORK = Path(__file__).resolve().parent
CANONICAL = ROOT / "next" / "content" / "film-craft-20261013"
READER = ROOT / "study" / "question_articles" / "drafts" / "film-craft-20261013.json"
RUNTIME_DRAFT = WORK / "draft-runtime.json"
RUNTIME_BUNDLE = WORK / "bundle-runtime.json"
IMPORTED_MANIFEST = WORK / "generated-local" / "manifest.json"
EVIDENCE = WORK / "repair-evidence.json"


def compact(value: object) -> bytes:
    return json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(",", ":")).encode("utf-8")


def digest(value: object) -> str:
    return hashlib.sha256(compact(value)).hexdigest()


def file_digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def without_binding(article: dict) -> dict:
    value = json.loads(json.dumps(article))
    value.pop("question_refs", None)
    return value


def main() -> None:
    old_draft = json.loads((CANONICAL / "draft.json").read_text(encoding="utf-8"))
    old_manifest = json.loads((CANONICAL / "manifest.json").read_text(encoding="utf-8"))
    old_reader = json.loads(READER.read_text(encoding="utf-8"))
    draft = json.loads(RUNTIME_DRAFT.read_text(encoding="utf-8"))
    bundle = json.loads(RUNTIME_BUNDLE.read_text(encoding="utf-8"))
    manifest = json.loads(IMPORTED_MANIFEST.read_text(encoding="utf-8"))

    old_by_id = {q["question_id"]: q for q in old_draft["questions"]}
    new_by_id = {q["question_id"]: q for q in draft["questions"]}
    preserved_question_fields = ["answer_kind", "difficulty", "difficulty_level", "grading", "options", "stem"]
    for question_id, old_question in old_by_id.items():
        new_question = new_by_id.get(question_id)
        if new_question is None:
            raise SystemExit(f"question missing after import: {question_id}")
        for field in preserved_question_fields:
            if old_question.get(field) != new_question.get(field):
                raise SystemExit(f"changed preserved question field {question_id}.{field}")
        if old_question.get("editorial_tag_ids") != new_question.get("editorial_tag_ids"):
            raise SystemExit(f"editorial tags changed unexpectedly: {question_id}")
        if new_question.get("source") != {"uri": "/app/quizzes/Preparation/film_craft_20261013.json"}:
            raise SystemExit(f"unexpected runtime source: {question_id}")

    old_explanations = {q["canonical_id"]: q.get("source_explanation") for q in old_manifest["questions"]}
    new_explanations = {q["canonical_id"]: q.get("source_explanation") for q in manifest["questions"]}
    if old_explanations != new_explanations:
        raise SystemExit("source explanations changed")

    revisions = {q["question_id"]: q["revision"]["sha256"] for q in draft["questions"]}
    bundle_revisions = {q["question_id"]: q["revision"]["sha256"] for q in bundle["quiz"]["questions"]}
    if revisions != bundle_revisions:
        raise SystemExit("draft and public bundle revisions differ")
    if set(bundle["private_grading"]) != set(revisions) or set(bundle["private_question_metadata"]) != set(revisions):
        raise SystemExit("private bundle coverage differs")

    before_article = {
        article["id"]: {
            "body_sha256": hashlib.sha256(article["body_ru"].encode("utf-8")).hexdigest(),
            "source_links_sha256": digest(article["source_links"]),
            "nonbinding_sha256": digest(without_binding(article)),
            "full_sha256": digest(article),
        }
        for article in old_reader["articles"]
    }
    reader = json.loads(json.dumps(old_reader))
    for article in reader["articles"]:
        if len(article.get("question_refs", [])) != 1:
            raise SystemExit(f"unexpected Reader bindings for {article.get('id')}")
        binding = article["question_refs"][0]
        question_id = binding.get("question_id")
        if binding.get("quiz_id") != "film-craft-20261013" or question_id not in revisions:
            raise SystemExit(f"unexpected Reader binding: {article.get('id')}")
        binding["revision_sha256"] = revisions[question_id]

    after_article = {
        article["id"]: {
            "body_sha256": hashlib.sha256(article["body_ru"].encode("utf-8")).hexdigest(),
            "source_links_sha256": digest(article["source_links"]),
            "nonbinding_sha256": digest(without_binding(article)),
            "full_sha256": digest(article),
            "revision_sha256": article["question_refs"][0]["revision_sha256"],
        }
        for article in reader["articles"]
    }
    for article_id, before in before_article.items():
        after = after_article[article_id]
        for key in ("body_sha256", "source_links_sha256", "nonbinding_sha256"):
            if before[key] != after[key]:
                raise SystemExit(f"Reader content changed outside binding: {article_id}.{key}")

    shutil.copyfile(RUNTIME_DRAFT, CANONICAL / "draft.json")
    shutil.copyfile(RUNTIME_BUNDLE, CANONICAL / "bundle.json")
    shutil.copyfile(IMPORTED_MANIFEST, CANONICAL / "manifest.json")
    READER.write_text(json.dumps(reader, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    evidence = {
        "scope": "raw tags plus runtime-equivalent canonical and Reader revision binding repair",
        "preserved_question_fields": preserved_question_fields,
        "source_explanations_preserved": True,
        "runtime_source_uri": "/app/quizzes/Preparation/film_craft_20261013.json",
        "source_title_absent": True,
        "draft_revision": draft["revision"]["sha256"],
        "bundle_sha256": bundle["bundle_sha256"],
        "question_revisions": revisions,
        "public_private_revision_identity": revisions == bundle_revisions,
        "private_grading_question_ids": sorted(bundle["private_grading"]),
        "private_metadata_question_ids": sorted(bundle["private_question_metadata"]),
        "reader_before": before_article,
        "reader_after": after_article,
        "final_file_sha256": {
            "raw": file_digest(ROOT / "quizzes" / "Preparation" / "film_craft_20261013.json"),
            "draft": file_digest(CANONICAL / "draft.json"),
            "bundle": file_digest(CANONICAL / "bundle.json"),
            "manifest": file_digest(CANONICAL / "manifest.json"),
            "reader_draft": file_digest(READER),
        },
    }
    EVIDENCE.write_text(json.dumps(evidence, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()