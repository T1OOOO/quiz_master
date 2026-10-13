#!/usr/bin/env python3
"""Prepare, but never integrate, the accepted four-question Film Craft pilot.

This controller writes a self-contained staging directory below
.run/film_craft_integration_20261013/worker only.  It pins the accepted source
bytes before deriving the private canonical draft, uses quizctl to construct the
bundle, and writes Reader *draft* records.  A lead must still perform the
separate review and integration gates before any runtime asset changes.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path
from urllib.parse import urlparse


ROOT = Path(__file__).resolve().parents[5]
PILOT = ROOT / "docs/rewrite-agents/tasks/FILM_CRAFT_PILOT_20261013/writer-v3"
CANDIDATE = PILOT / "candidate.json"
EDITORIAL = PILOT / "editorial.json"
TAXONOMY = ROOT / "metadata/tags.v1.json"
QUIZ_ID = "film-craft-20261013"
OUTPUT_ROOT = ROOT / ".run/film_craft_integration_20261013/worker"
EXPECTED = {
    "candidate.json": "5a94668f197da4b256ee1cce01e8f85655030e6a4d63c795a2298f415bbeeb59",
    "editorial.json": "6491db9f97614857d385abed4edba75e0d9a2b3aea8832fec63d43bc48c7e83b",
}
EXPECTED_IDS = [f"film-craft-pilot-{number:03d}" for number in range(1, 5)]
SOURCE_URI = "/app/quizzes/Preparation/film_craft_20261013.json"
BUNDLE_VERSION = "film-craft-20261013-staging-v1"
STAGING_TIMESTAMP = "2026-10-13T00:00:00Z"


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def canonical(value: object) -> bytes:
    # Input strings contain no HTML-sensitive characters.  This exactly matches
    # the compact, sorted UTF-8 contract representation used by content.Canonical.
    return json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(",", ":")).encode("utf-8")


def write_json(path: Path, value: object) -> None:
    path.write_text(json.dumps(value, ensure_ascii=False, sort_keys=True, indent=2) + "\n", encoding="utf-8")


def rehash(value: dict, field: str = "revision") -> str:
    copied = dict(value)
    copied.pop(field, None)
    return hashlib.sha256(canonical(copied)).hexdigest()


def source_hashes(expected: dict[str, str] = EXPECTED) -> dict[str, str]:
    actual = {name: sha256(PILOT / name) for name in expected}
    if actual != expected:
        raise ValueError(f"frozen source hash mismatch: expected={expected} actual={actual}")
    return actual


def safe_output_dir(raw: str) -> Path:
    destination = Path(raw).resolve()
    root = OUTPUT_ROOT.resolve()
    if destination == root or root not in destination.parents:
        raise ValueError(f"output directory must be below {root}")
    if destination.exists():
        raise ValueError(f"refusing existing output directory: {destination}")
    return destination


def load_inputs() -> tuple[dict, dict]:
    candidate = json.loads(CANDIDATE.read_text(encoding="utf-8"))
    editorial = json.loads(EDITORIAL.read_text(encoding="utf-8"))
    if candidate.get("schema_version") != "film-craft-pilot-candidate/v1":
        raise ValueError("unexpected candidate schema")
    if editorial.get("schema_version") != "film-craft-pilot-editorial/v1":
        raise ValueError("unexpected editorial schema")
    candidate_ids = [item.get("id") for item in candidate.get("items", [])]
    editorial_ids = [item.get("question_id") for item in editorial.get("items", [])]
    if candidate_ids != EXPECTED_IDS or editorial_ids != EXPECTED_IDS:
        raise ValueError("expected four ordered source IDs are not present")
    if len(set(candidate_ids)) != 4:
        raise ValueError("duplicate source question ID")
    return candidate, editorial


def legacy_source(candidate: dict, editorial: dict, taxonomy: dict) -> dict:
    """Create the exact legacy shape consumed by the current quizctl importer."""
    questions = []
    for source, private in zip(candidate["items"], editorial["items"]):
        options = source["options"]
        answer = next(index for index, option in enumerate(options) if option["id"] == private["correct_option_id"])
        questions.append({
            "id": source["id"], "type": "choice", "difficulty": private["difficulty"],
            "text": source["stem_ru"], "options": [option["text_ru"] for option in options],
            "correct_answer": answer, "explanation": private["explanation_ru"],
        })
    return {
        "id": QUIZ_ID, "title": "Кино: ремесло и приёмы", "category": "Кино/Ремесло",
        "description": "Четыре вопроса о работе со звуком, монтажом и покадровой анимацией.",
        "taxonomy_ref": {"taxonomy_id": taxonomy["taxonomy_id"], "taxonomy_sha256": taxonomy["taxonomy_sha256"]},
        "questions": questions,
    }


def enrich_imported_draft(draft: dict, editorial: dict) -> list[dict]:
    private_by_source = {item["question_id"]: item for item in editorial["items"]}
    questions = draft["questions"]
    if [question["question_id"] for question in questions] != EXPECTED_IDS:
        raise ValueError("quizctl import did not preserve the four source question IDs")
    for question in questions:
        private = private_by_source[question["question_id"]]
        if private["tags"] != ["domain:screen", "domain:arts", "topic:film-production"]:
            raise ValueError(f"{question['question_id']}: frozen tag contract changed")
        question["editorial_tag_ids"] = sorted(private["tags"])
        question.pop("context_tag_ids", None)
        question["source"] = {"uri": SOURCE_URI, "title": "Film Craft pilot (accepted editorial source)"}
        question["revision"]["sha256"] = rehash(question)
    draft["revision"]["sha256"] = rehash(draft)
    return questions


def article_title(body: str, question_id: str) -> str:
    first = body.splitlines()[0].strip()
    if not first.startswith("### "):
        raise ValueError(f"{question_id}: article does not begin with a title")
    return first.removeprefix("### ")


def reader_body(body: str, question_id: str, source_urls: list[str]) -> str:
    """Retain accepted prose while leaving title and sources to Reader controls."""
    title = f"### {article_title(body, question_id)}"
    if not body.startswith(title):
        raise ValueError(f"{question_id}: article title changed during transform")
    prose = body[len(title):].lstrip("\r\n")
    marker = "\n\nИсточники:\n"
    if marker not in prose:
        raise ValueError(f"{question_id}: source footer missing")
    prose, footer = prose.split(marker, 1)
    if not footer.strip().startswith("-"):
        raise ValueError(f"{question_id}: source footer malformed")
    footer_urls = [line.removeprefix("- ").strip() for line in footer.splitlines() if line.startswith("- ")]
    if footer_urls != source_urls:
        raise ValueError(f"{question_id}: source footer and source ledger differ")
    return prose.rstrip()


def reader_drafts(editorial: dict, questions: list[dict]) -> dict:
    articles = []
    for source, question in zip(editorial["items"], questions):
        article = source["article_ru"]
        source_links = []
        for entry in source["sources"]:
            parsed = urlparse(entry["url"])
            if parsed.scheme != "https" or not parsed.netloc:
                raise ValueError(f"{source['question_id']}: source is not an HTTPS URL")
            source_links.append({
                "title": parsed.netloc,
                "url": entry["url"],
                "accessed": entry["accessed_on"],
                "supports": entry["supported_claim"],
            })
        articles.append({
            "id": f"question:{question['question_id']}",
            "title_ru": article_title(article, source["question_id"]),
            "body_ru": reader_body(article, source["question_id"], [entry["url"] for entry in source["sources"]]),
            "target_refs": [],
            "question_refs": [{
                "quiz_id": QUIZ_ID,
                "question_id": question["question_id"],
                "revision_sha256": question["revision"]["sha256"],
            }],
            "source_links": source_links,
            "tag_ids": source["tags"],
            "status": "draft",
        })
    return {"schema_version": "qm-question-articles/v1", "articles": articles}


def manifest(candidate: dict, editorial: dict, questions: list[dict], hashes: dict[str, str]) -> dict:
    records = []
    for index, (source, private, question) in enumerate(zip(candidate["items"], editorial["items"], questions), 1):
        records.append({
            "source_question_id": source["id"],
            "canonical_question_id": question["question_id"],
            "source_option_ids": [option["id"] for option in source["options"]],
            "canonical_option_ids": [option["option_id"] for option in question["options"]],
            "correct_source_option_id": private["correct_option_id"],
            "correct_canonical_option_id": question["grading"]["correct_option_id"],
            "article_id": f"question:{question['question_id']}",
            "question_revision_sha256": question["revision"]["sha256"],
            "source_order": index,
        })
    return {
        "schema_version": "film-craft-preparation-manifest/v1",
        "status": "staged_only_not_published",
        "input_hashes": hashes,
        "quiz_id": QUIZ_ID,
        "source_uri": SOURCE_URI,
        "records": records,
        "reader_integration_gate": "Reader records are draft status and require a separate independent article review before build.py can export accepted Reader assets.",
    }


def run_quizctl(*args: str) -> str:
    command = ["go", "run", "-p=1", "./next/server/cmd/quizctl", *args]
    result = subprocess.run(command, cwd=ROOT, text=True, capture_output=True, timeout=120)
    if result.returncode:
        raise RuntimeError(f"quizctl failed ({result.returncode}): {' '.join(command)}\n{result.stderr.strip()}")
    return result.stdout.strip()


def check_output(stage: Path, draft: dict, reader: dict) -> dict:
    draft_path = stage / "draft.json"
    bundle_path = stage / "bundle.json"
    draft_result = run_quizctl("validate", "--in", str(draft_path), "--taxonomy", str(TAXONOMY))
    build_result = run_quizctl("build", "--in", str(draft_path), "--out", str(bundle_path), "--version", BUNDLE_VERSION, "--published-at", STAGING_TIMESTAMP, "--taxonomy", str(TAXONOMY))
    bundle_result = run_quizctl("validate", "--in", str(bundle_path), "--taxonomy", str(TAXONOMY))
    bundle = json.loads(bundle_path.read_text(encoding="utf-8"))
    if "private_grading" not in bundle or any("grading" in q for q in bundle["quiz"]["questions"]):
        raise ValueError("public/private grading boundary violated")
    if len(bundle["quiz"]["questions"]) != 4 or len(reader["articles"]) != 4:
        raise ValueError("expected four staged questions and four reader drafts")
    public_questions = bundle["quiz"]["questions"]
    for article, question in zip(reader["articles"], public_questions):
        ref = article["question_refs"][0]
        if ref["question_id"] != question["question_id"] or ref["revision_sha256"] != question["revision"]["sha256"]:
            raise ValueError("Reader binding is stale")
    return {
        "schema_version": "film-craft-preparation-validation/v1",
        "quizctl": {"draft_validate": draft_result, "build": build_result, "bundle_validate": bundle_result},
        "question_count": 4,
        "reader_draft_count": 4,
        "public_bundle_contains_grading": False,
        "reader_statuses": sorted({article["status"] for article in reader["articles"]}),
        "integration_status": "preparation_only",
    }


def self_test() -> dict:
    before_exists = OUTPUT_ROOT.exists()
    before_paths = sorted(path.relative_to(OUTPUT_ROOT).as_posix() for path in OUTPUT_ROOT.rglob("*") if path.is_file()) if before_exists else []
    source_hashes()
    failed = []
    wrong = dict(EXPECTED)
    wrong["candidate.json"] = "0" * 64
    try:
        source_hashes(wrong)
    except ValueError:
        failed.append("wrong_source_hash_rejected")
    try:
        safe_output_dir(str(CANDIDATE))
    except ValueError:
        failed.append("outside_scratch_rejected")
    after_exists = OUTPUT_ROOT.exists()
    after_paths = sorted(path.relative_to(OUTPUT_ROOT).as_posix() for path in OUTPUT_ROOT.rglob("*") if path.is_file()) if after_exists else []
    if before_exists != after_exists or before_paths != after_paths:
        raise AssertionError("self-test wrote a scratch artifact")
    required = {"wrong_source_hash_rejected", "outside_scratch_rejected"}
    if set(failed) != required:
        raise AssertionError(f"self-test failures: {failed}")
    return {"self_test": "PASS", "fail_closed_cases": failed, "writes": "none"}


def prepare(destination: Path) -> dict:
    hashes = source_hashes()
    candidate, editorial = load_inputs()
    taxonomy = json.loads(TAXONOMY.read_text(encoding="utf-8"))
    destination.parent.mkdir(parents=True, exist_ok=True)
    temp = Path(tempfile.mkdtemp(prefix=f".{destination.name}.tmp-", dir=destination.parent))
    try:
        write_json(temp / "legacy.json", legacy_source(candidate, editorial, taxonomy))
        canonical_dir = temp / "canonical"
        import_result = run_quizctl("import", "--in", str(temp / "legacy.json"), "--out", str(canonical_dir), "--taxonomy", str(TAXONOMY))
        draft_path = canonical_dir / "draft.json"
        draft = json.loads(draft_path.read_text(encoding="utf-8"))
        questions = enrich_imported_draft(draft, editorial)
        write_json(draft_path, draft)
        imported_manifest = json.loads((canonical_dir / "manifest.json").read_text(encoding="utf-8"))
        imported_manifest["source_path"] = "staging/legacy.json"
        write_json(canonical_dir / "manifest.json", imported_manifest)
        reader = reader_drafts(editorial, questions)
        provenance = manifest(candidate, editorial, questions, hashes)
        provenance["quizctl_import"] = import_result
        write_json(temp / "reader-draft.json", reader)
        write_json(temp / "provenance.json", provenance)
        validation = check_output(canonical_dir, draft, reader)
        write_json(temp / "validation.json", validation)
        validation["artifacts_sha256"] = {
            path.relative_to(temp).as_posix(): sha256(path)
            for path in sorted(temp.rglob("*")) if path.is_file() and path.name != "validation.json"
        }
        write_json(temp / "validation.json", validation)
        os.replace(temp, destination)
        return validation
    except Exception:
        shutil.rmtree(temp, ignore_errors=True)
        raise


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output-dir", help="new staging directory below the assigned .run worker root")
    parser.add_argument("--self-test", action="store_true", help="run fail-closed guard checks without producing staging inputs")
    args = parser.parse_args()
    if args.self_test:
        print(json.dumps(self_test(), ensure_ascii=False, sort_keys=True))
        return 0
    if not args.output_dir:
        parser.error("--output-dir is required unless --self-test is used")
    result = prepare(safe_output_dir(args.output_dir))
    print(json.dumps({"status": "PREPARED_NOT_INTEGRATED", **result}, ensure_ascii=False, sort_keys=True))
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as error:
        print(f"film-craft preparation failed: {error}", file=sys.stderr)
        raise SystemExit(2)
