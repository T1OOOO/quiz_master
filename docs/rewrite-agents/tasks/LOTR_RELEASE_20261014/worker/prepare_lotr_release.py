#!/usr/bin/env python3
"""Fail-closed, prepare-only controller for the LOTR two-question repair.

This program has no deployment, browser, SSH, Docker, database, Helm, or Git
mutation path.  It only permits a future *local* package preparation after the
release lead provides real, hash-bound evidence for every gate below.
"""
from __future__ import annotations

import argparse
import copy
import hashlib
import json
import re
import tarfile
from pathlib import Path, PurePosixPath
from typing import Any

BASELINE_BUILD = "quiz-2026.10.14-screen-song-6866608"
BASELINE_SOURCE = "6866608bd7c20ceff2b454970b315eaee86329a9"
BASELINE_ARCHIVE_SHA256 = "64e50bf9f49bd1287b0964f234cb9545508b878315e8fd577c262dc5c5ade6df"
BASELINE_IMAGE = "docker.io/library/quiz-master@sha256:a97cf777b2015c595fd1307017246a2806cce597e0233da75e496a433761e074"
API_SHA256 = "26e1657fd6259bdbbef9178cbe9343b775406d91c56cb9661d302ad530ab6f01"
NGINX_SHA256 = "e9add812a138010e443463acb455295103dc69886ca32cd17dafbccfa676d6bc"
PVC_UID = "7fc2428f-4146-4c78-a26d-2347d9f3b7bf"
TARGET_SOURCE = "9194f61face75d03862003942ef55fae34aeec72"
BUILD_ID = "quiz-2026.10.14-lotr-rk-repair-9194f61"
QUIZ_ID = "lotr-return-king-bts-100"
RAW_PATH = "quizzes/Cinema/LOTR/lotr_return_king_bts_100.json"
RUNTIME_BUNDLE = "integration-runtime-bundle.json"
REPAIRED = {
    "lotr-rk-93": "4c90dc9b8f716e6de64e9153694ebb9576a024983cff098f8c16f4d7adf302e4",
    "lotr-rk-95": "36e5d42e3e8a3f639c9249ede4a04fcb6186fa8e3a826325f4ec4998b20db513",
}
COUNTS = {"packs": 135, "questions": 4064, "reader_articles": 266}
HASH = re.compile(r"[0-9a-f]{64}")


def fail(message: str) -> None:
    raise RuntimeError(message)


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def read_json(path: Path) -> Any:
    if not path.is_file():
        fail(f"missing required input: {path}")
    return json.loads(path.read_text(encoding="utf-8"))


def canonical(value: Any) -> str:
    return hashlib.sha256(json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(",", ":")).encode()).hexdigest()


def as_rows(value: Any, label: str) -> list[dict[str, Any]]:
    if isinstance(value, list):
        return value
    for key in ("articles", "packs", "quizzes"):
        if isinstance(value, dict) and isinstance(value.get(key), list):
            return value[key]
    fail(f"unrecognized {label} schema")


def require_hash(value: Any, label: str) -> str:
    if not isinstance(value, str) or not HASH.fullmatch(value):
        fail(f"{label} must be a SHA-256")
    return value


def load_release_pins(path: Path) -> dict[str, Any]:
    """Accept only Root's real post-review pin document; never embed approval."""
    pins = read_json(path)
    required = {
        "schema_version", "frozen_commit", "build_id", "baseline_archive_sha256",
        "baseline_image", "api_sha256", "nginx_sha256", "pvc_uid", "source_assets",
        "runtime_bundle", "public_baseline", "reader_snapshot", "build_evidence", "source_review",
        "export_review", "browser_proof", "production_web", "qa_web", "baseline_catalog", "baseline_reader", "repo",
    }
    if not isinstance(pins, dict) or not required <= pins.keys() or pins.get("schema_version") != "qm-lotr-release-pins/v1":
        fail("complete Root release pins are required")
    if pins["frozen_commit"] != TARGET_SOURCE or pins["build_id"] != BUILD_ID:
        fail("LOTR frozen source/build identity differs")
    if (pins["baseline_archive_sha256"], pins["baseline_image"], pins["api_sha256"], pins["nginx_sha256"], pins["pvc_uid"]) != (BASELINE_ARCHIVE_SHA256, BASELINE_IMAGE, API_SHA256, NGINX_SHA256, PVC_UID):
        fail("ScreenSong52 infrastructure baseline differs")
    for name in ("source_review", "export_review", "browser_proof", "build_evidence", "baseline_catalog", "baseline_reader"):
        proof = pins[name]
        if not isinstance(proof, dict) or set(proof) != {"path", "sha256"}:
            fail(f"actual {name} pin is required")
        proof_path = Path(proof["path"])
        if sha256_file(proof_path) != require_hash(proof["sha256"], name):
            fail(f"actual {name} evidence hash differs")
    for name in ("runtime_bundle", "public_baseline", "reader_snapshot"):
        entry = pins[name]
        if not isinstance(entry, dict) or set(entry) != {"path", "sha256"}:
            fail(f"{name} pin is required")
        if sha256_file(Path(entry["path"])) != require_hash(entry["sha256"], name):
            fail(f"{name} bytes differ from pin")
    assets = pins["source_assets"]
    if not isinstance(assets, dict) or not assets:
        fail("full frozen source asset pins are required")
    for relative, digest in assets.items():
        if not isinstance(relative, str) or relative.startswith("/") or ".." in PurePosixPath(relative).parts:
            fail("unsafe frozen source asset path")
        require_hash(digest, f"source asset {relative}")
    return pins


def require_review_acceptance(proof: dict[str, Any], label: str) -> None:
    if proof.get("actual_cli_exit") != 0 or proof.get("actual_hub_state") != "ACCEPTED" or not proof.get("actual_reviews"):
        fail(f"actual accepted {label} review outcome is required")


def verify_browser_receipt(proof: dict[str, Any]) -> None:
    if proof.get("frozen_source") != TARGET_SOURCE or proof.get("build_id") != BUILD_ID:
        fail("browser proof source/build identity differs")
    if proof.get("browser_inactive") is not True or proof.get("ports_closed") != [19090, 19093] or proof.get("browser_close_actual_exit") != 0 or proof.get("qa_server_actual_exit") != 0:
        fail("actual browser lifecycle/cleanup proof differs")
    answers = {row.get("question_id"): json.loads(row.get("receipt", "{}")) for row in proof.get("answers", [])}
    if {key: answers.get(key, {}).get("question_revision", {}).get("sha256") for key in REPAIRED} != REPAIRED:
        fail("actual browser receipts do not bind repaired revisions")


def verify_build_evidence(pins: dict[str, Any]) -> None:
    build = read_json(Path(pins["build_evidence"]["path"]))
    if build.get("frozen_source") != TARGET_SOURCE or build.get("build_id") != BUILD_ID:
        fail("actual Flutter build evidence is not source-bound")
    checks = build.get("checks")
    if not isinstance(checks, list) or {row.get("label") for row in checks} != {"production", "qa"}:
        fail("two actual production/QA Flutter build records are required")
    for row in checks:
        label = row["label"]
        web = Path(pins[f"{label}_web"])
        if row.get("actual_exit") != 0 or row.get("frozen_assets_byte_identical") is not True or Path(row.get("output", "")).resolve() != web.resolve():
            fail(f"actual {label} Flutter build receipt differs")
        if sha256_file(web / "main.dart.js") != require_hash(row.get("main_dart_js_sha256"), f"{label} JavaScript"):
            fail(f"actual {label} compiled JavaScript differs")


def verify_assets(repo: Path, pins: dict[str, Any]) -> None:
    catalog_path = "next/apps/quiz_app/assets/catalog.json"
    reader_path = "next/apps/quiz_app/assets/study/question-articles.json"
    repo = repo.resolve()
    declared = pins["source_assets"]
    if not {catalog_path, reader_path} <= set(declared):
        fail("catalog and Reader source asset pins are required")
    for relative, expected in declared.items():
        pure = PurePosixPath(relative)
        if pure.is_absolute() or ".." in pure.parts or "\\" in relative:
            fail(f"unsafe frozen source asset path: {relative}")
        target = (repo / Path(*pure.parts)).resolve()
        if not target.is_relative_to(repo):
            fail(f"frozen source asset escapes repository: {relative}")
        if not target.is_file() or sha256_file(target) != expected:
            fail(f"frozen source asset differs: {relative}")
    catalog, reader = as_rows(read_json(repo / catalog_path), "catalog"), as_rows(read_json(repo / reader_path), "Reader export")
    old_catalog, old_reader = as_rows(read_json(Path(pins["baseline_catalog"]["path"])), "baseline catalog"), as_rows(read_json(Path(pins["baseline_reader"]["path"])), "baseline Reader")
    verify_asset_rows(catalog, reader, old_catalog, old_reader)


def verify_asset_rows(catalog: list[dict[str, Any]], reader: list[dict[str, Any]], old_catalog: list[dict[str, Any]], old_reader: list[dict[str, Any]]) -> None:
    if len(catalog) != 135 or sum(row.get("questions_count", 0) for row in catalog) != 4064:
        fail("target catalog counts differ from 135/4064")
    if len(reader) != 266 or any(row.get("status") != "accepted" for row in reader):
        fail("target Reader export differs from 266 accepted objects")
    if len(old_catalog) != 135 or len(old_reader) != 264:
        fail("ScreenSong52 baseline counts differ")
    catalog_by_id, old_catalog_by_id = {row["quiz_id"]: row for row in catalog}, {row["quiz_id"]: row for row in old_catalog}
    reader_by_id, old_reader_by_id = {row["id"]: row for row in reader}, {row["id"]: row for row in old_reader}
    if catalog_by_id != old_catalog_by_id:
        fail("one or more ScreenSong52 catalog rows changed")
    if any(reader_by_id.get(key) != value for key, value in old_reader_by_id.items()) or len(set(reader_by_id) - set(old_reader_by_id)) != 2:
        fail("prior 264 Reader objects are not preserved exactly")


def question_map(bundle: dict[str, Any]) -> dict[str, dict[str, Any]]:
    questions = bundle.get("quiz", {}).get("questions")
    if not isinstance(questions, list) or len(questions) != 100:
        fail("runtime bundle must contain exactly 100 questions")
    mapped = {row.get("question_id"): row for row in questions}
    if len(mapped) != 100 or set(mapped) != {f"lotr-rk-{number}" for number in range(1, 101)}:
        fail("runtime bundle question IDs differ")
    return mapped


def public_question_map(baseline: dict[str, Any]) -> dict[str, dict[str, Any]]:
    questions = baseline.get("response", {}).get("quiz", {}).get("questions")
    if not isinstance(questions, list) or len(questions) != 100:
        fail("public baseline must contain exactly 100 served questions")
    mapped = {row.get("question_id"): row for row in questions}
    if len(mapped) != 100:
        fail("public baseline question IDs are not unique")
    return mapped


def public_projection(question: dict[str, Any]) -> dict[str, Any]:
    return {key: question[key] for key in ("quiz_id", "question_id", "revision", "stem", "options", "difficulty", "source", "answer_kind")}


def verify_runtime_projection(runtime: dict[str, Any], public: dict[str, Any], reader_snapshot: Any) -> None:
    current, served = question_map(runtime), public_question_map(public)
    if runtime.get("quiz", {}).get("quiz_id") != QUIZ_ID:
        fail("runtime bundle quiz ID differs")
    for question_id, old in served.items():
        if question_id in REPAIRED:
            continue
        if canonical(public_projection(current[question_id])) != canonical(old):
            fail(f"served question changed outside approved repair: {question_id}")
    for question_id, expected_sha in REPAIRED.items():
        row = current[question_id]
        if row.get("revision") != {"number": 2, "sha256": expected_sha} or row.get("source") != {"uri": "/app/" + RAW_PATH}:
            fail(f"repaired question revision/source differs: {question_id}")
    q93, q95 = current["lotr-rk-93"], current["lotr-rk-95"]
    if q93["options"][5].get("option_id") != "lotr-rk-93-opt-6" or len(q95["options"]) != 4 or q95["options"][3].get("option_id") != "lotr-rk-95-opt-5":
        fail("approved option identifiers differ")
    if any(row.get("source", {}).get("uri") != "/app/" + RAW_PATH for row in current.values()):
        fail("runtime source URI projection differs")
    grading = runtime.get("private_grading", {})
    if grading.get("lotr-rk-95", {}).get("correct_option_id") != "lotr-rk-95-opt-2":
        fail("lotr-rk-95 retained correct option differs")
    if "lotr-rk-95-opt-5" not in {item.get("option_id") for item in q95["options"]}:
        fail("lotr-rk-95 retained old option is absent")
    if not isinstance(reader_snapshot, dict) or reader_snapshot != runtime:
        fail("Reader snapshot bundle differs from reviewed runtime bundle")
    snapshot_questions = question_map(reader_snapshot)
    if {key: snapshot_questions[key]["revision"]["sha256"] for key in REPAIRED} != REPAIRED:
        fail("Reader snapshot does not bind repaired revisions")


def append_only_cache(baseline_cache: dict[str, Any], runtime: dict[str, Any]) -> dict[str, Any]:
    if len(baseline_cache) != 12 or QUIZ_ID in baseline_cache:
        fail("ScreenSong52 runtime cache must contain exactly twelve prior entries")
    result = copy.deepcopy(baseline_cache)
    result[QUIZ_ID] = runtime
    if len(result) != 13 or any(result[key] != value for key, value in baseline_cache.items()):
        fail("runtime cache changed an existing entry")
    return result


def verify_safe_archive(archive: Path) -> None:
    if sha256_file(archive) != BASELINE_ARCHIVE_SHA256:
        fail("ScreenSong52 archive SHA-256 differs")
    prefix = BASELINE_BUILD + "/"
    with tarfile.open(archive, "r:gz") as package:
        names: set[str] = set()
        for member in package.getmembers():
            pure = PurePosixPath(member.name)
            if not member.isfile() or pure.is_absolute() or ".." in pure.parts or "\\" in member.name or member.name in names or not member.name.startswith(prefix):
                fail(f"unsafe baseline archive member: {member.name}")
            names.add(member.name)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--pins", type=Path, required=True)
    parser.add_argument("--prior-archive", type=Path, required=True)
    parser.add_argument("--baseline-cache", type=Path, required=True)
    args = parser.parse_args()
    pins = load_release_pins(args.pins)
    verify_build_evidence(pins)
    require_review_acceptance(read_json(Path(pins["source_review"]["path"])), "source")
    require_review_acceptance(read_json(Path(pins["export_review"]["path"])), "export")
    verify_browser_receipt(read_json(Path(pins["browser_proof"]["path"])))
    verify_safe_archive(args.prior_archive)
    runtime = read_json(Path(pins["runtime_bundle"]["path"]))
    verify_runtime_projection(runtime, read_json(Path(pins["public_baseline"]["path"])), read_json(Path(pins["reader_snapshot"]["path"])))
    append_only_cache(read_json(args.baseline_cache), runtime)
    verify_assets(Path(pins["repo"]), pins)
    print(json.dumps({"status": "VALIDATED_NOT_PREPARED", "build_id": BUILD_ID, "counts": COUNTS}, ensure_ascii=False))


if __name__ == "__main__":
    main()
