#!/usr/bin/env python3
"""Prepare, but never execute, the immutable LOTR repair release package."""
from __future__ import annotations

import argparse
import copy
import gzip
import hashlib
import json
import re
import shutil
import subprocess
import tarfile
from pathlib import Path, PurePosixPath
from typing import Any, Iterable


BASELINE_BUILD = "quiz-2026.10.14-screen-song-6866608"
BASELINE_SOURCE = "6866608bd7c20ceff2b454970b315eaee86329a9"
BASELINE_ARCHIVE_SHA256 = "64e50bf9f49bd1287b0964f234cb9545508b878315e8fd577c262dc5c5ade6df"
BASELINE_IMAGE = "docker.io/library/quiz-master@sha256:a97cf777b2015c595fd1307017246a2806cce597e0233da75e496a433761e074"
BASELINE_CUTOVER_IMAGE = "docker.io/library/quiz-master@sha256:039474ddb2feac0986908a7681c18fcf39cb716428e9c8acf199e8f9e044c961"
BASELINE_MAIN_DART_JS_SHA256 = "aed8b728b1d019b86432075f96c6fec48414fc8351079c1f9c53519e0e4373e9"
BASELINE_API_SHA256 = "26e1657fd6259bdbbef9178cbe9343b775406d91c56cb9661d302ad530ab6f01"
TARGET_API_SHA256 = "f4d69555623aab2b8e1468fccb65256abefc9823d65214799b7e1475d4d9c850"
TARGET_API_BYTES = 22988817
API_CODE_CHECKPOINT = "9d842dfd641a2f288aef5f539c88d701b2d6c86c"
API_NONCOMPILED_CHANGED_PATHS = ['next/server/cmd/quizctl/catalog_test.go', 'next/server/internal/content/import_identity_test.go', 'next/server/internal/sqlite/collection_test.go']
NGINX_SHA256 = "e9add812a138010e443463acb455295103dc69886ca32cd17dafbccfa676d6bc"
PVC_UID = "7fc2428f-4146-4c78-a26d-2347d9f3b7bf"
TARGET_SOURCE = "23882307770ecb176edb602b06998111aae67581"
BUILD_ID = "quiz-2026.10.14-lotr-identity-2388230"
MIXED_QUIZ_ID = "pub-connections-20261014"
MIXED_RAW_PATH = "quizzes/Preparation/pub_connections_20261014.json"
QUIZ_ID = "lotr-return-king-bts-100"
RAW_PATH = "quizzes/Cinema/LOTR/lotr_return_king_bts_100.json"
TARGET_CONTENT_ROOT = f"next/content/{QUIZ_ID}"
REPAIRED = {
    "lotr-rk-93": "4c90dc9b8f716e6de64e9153694ebb9576a024983cff098f8c16f4d7adf302e4",
    "lotr-rk-95": "36e5d42e3e8a3f639c9249ede4a04fcb6186fa8e3a826325f4ec4998b20db513",
}
LOCAL_REPAIRED = {
    "lotr-rk-93": "dc3c5b2b3b119a472993d32ae4c0321eea64532904956dad26075507cd362fa7",
    "lotr-rk-95": "a359dc8245a34bbafbf4c21b8fa096f13a49597196bee92885026e973d0f948e",
}
BASELINE_RUNTIME_IDS = (
    "cinema-encore-20261011",
    "cinema-people-20261011",
    "home-alone-1-part-1",
    "music-encore-20261011",
    "music-people-20261011",
    "philias-lifestyle-part-1",
    "phobias-nature",
    "planet-paradoxes-20261010",
    "film-craft-20261013",
    "music-craft-20261013",
    "acting-craft-20261014",
    "screen-song-20261014",
)
SOURCE_ASSET_PATHS = {
    "study/question_articles/reviews/lotr-return-king-repair-20261014-review.json",
    "next/apps/quiz_app/assets/study/question-articles.json",
    "next/apps/quiz_app/test/question_articles_test.dart",
    "next/apps/quiz_app/assets/catalog.json",
    RAW_PATH,
    f"{TARGET_CONTENT_ROOT}/draft.json",
    f"{TARGET_CONTENT_ROOT}/manifest.json",
    f"{TARGET_CONTENT_ROOT}/bundle.json",
    "study/question_articles/snapshots/lotr-return-king-bts-100.json",
}
MIXED_SOURCE_ASSET_PATHS = {MIXED_RAW_PATH, *(f'next/content/{MIXED_QUIZ_ID}/{name}.json' for name in ('draft', 'manifest', 'bundle'))}
PACKAGE_SOURCE_PATHS = SOURCE_ASSET_PATHS - {
    "next/apps/quiz_app/test/question_articles_test.dart",
    f"{TARGET_CONTENT_ROOT}/bundle.json",
}
CONTROLLER_FILES = {"prepare_lotr_package.py", "test_prepare_lotr_package.py", "verify_candidate_runtime.py", "test_verify_candidate_runtime.py", "README.md"}
HASH = re.compile(r"[0-9a-f]{64}")


def verify_target_api(pins: dict[str, Any], *, expected_sha256: str = TARGET_API_SHA256, expected_bytes: int = TARGET_API_BYTES) -> Path:
    api = proof_path(pins.get("target_api"), "target API")
    build = pins.get("target_api_build")
    inspection = pins.get("target_api_inspection")
    if isinstance(build, dict) and set(build) == {"path", "sha256"}:
        build = read_json(proof_path(build, "target API build"))
    if isinstance(inspection, dict) and set(inspection) == {"path", "sha256"}:
        inspection = read_json(proof_path(inspection, "target API inspection"))
    if not isinstance(build, dict) or not isinstance(inspection, dict):
        fail("missing actual target API build/inspection receipt")
    if build.get("api_code_checkpoint") != API_CODE_CHECKPOINT:
        fail("target API code checkpoint differs")
    with api.open("rb") as stream:
        magic = stream.read(4)
    if (sha256_file(api) != expected_sha256 or api.stat().st_size != expected_bytes or magic != b"\x7fELF"):
        fail("target API SHA/bytes/ELF differs")
    command = build.get("command", [])
    if (build.get("actual_exit") != 0 or build.get("environment") != {"GOOS": "linux", "GOARCH": "amd64", "CGO_ENABLED": "0"}
            or build.get("artifact_sha256") != expected_sha256 or build.get("artifact_bytes") != expected_bytes
            or build.get("elf") is not True or build.get("buildvcs") is not False
            or Path(build.get("artifact_path", "")).resolve() != api.resolve()
            or Path(build.get("cwd", "")).resolve() != (Path(pins["repo"]) / "next/server").resolve()
            or command != ["go", "build", "-p=1", "-trimpath", "-buildvcs=false", "-o", str(api), "./cmd/api"]):
        fail("actual target API build receipt differs")
    stdout = inspection.get("stdout", "")
    required = ("path\tquiz_master/next/server/cmd/api", "-trimpath=true", "CGO_ENABLED=0", "GOARCH=amd64", "GOOS=linux")
    if (inspection.get("actual_exit") != 0 or any(pin not in stdout for pin in required)
            or inspection.get("only_server_difference_from_api_code_checkpoint") != API_NONCOMPILED_CHANGED_PATHS
            or inspection.get("untracked_go_inputs") != []):
        fail("target API inspection/provenance differs")
    return api


def copy_target_api(stage: Path, api: Path, *, expected_sha256: str = TARGET_API_SHA256) -> None:
    if sha256_file(api) != expected_sha256:
        fail("target API changed before copy")
    shutil.copyfile(api, stage / "api")
    (stage / "api").chmod(0o755)
    if sha256_file(stage / "api") != expected_sha256:
        fail("staged target API differs")


def fail(message: str) -> None:
    raise RuntimeError(message)


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def sha256_bytes(value: bytes) -> str:
    return hashlib.sha256(value).hexdigest()


def canonical(value: Any) -> str:
    payload = json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(",", ":")).encode("utf-8")
    return hashlib.sha256(payload).hexdigest()


def read_json(path: Path) -> Any:
    if not path.is_file():
        fail(f"missing required input: {path}")
    return json.loads(path.read_text(encoding="utf-8"))


def write_json_lf(path: Path, value: Any) -> None:
    path.write_bytes((json.dumps(value, ensure_ascii=False, indent=2) + "\n").encode("utf-8"))


def require_hash(value: Any, label: str) -> str:
    if not isinstance(value, str) or HASH.fullmatch(value) is None:
        fail(f"{label} must be a SHA-256")
    return value


def as_rows(value: Any, label: str) -> list[dict[str, Any]]:
    if isinstance(value, list):
        return value
    if isinstance(value, dict):
        for key in ("articles", "packs", "quizzes"):
            if isinstance(value.get(key), list):
                return value[key]
    fail(f"unrecognized {label} schema")


def replace_once(body: str, old: str, new: str, count: int = 1) -> str:
    if body.count(old) != count:
        fail(f"baseline anchor absent or duplicated: {old}")
    return body.replace(old, new)


def require_actual_acceptance(proof: dict[str, Any], label: str) -> None:
    if proof.get("actual_cli_exit") != 0 or proof.get("actual_hub_state") != "ACCEPTED" or not proof.get("actual_reviews"):
        fail(f"actual accepted {label} review outcome is required")


def verify_controller_review(review: dict[str, Any], expected_hashes: dict[str, str]) -> None:
    if review.get("schema_version") != "qm-lotr-package-controller-review/v1":
        fail("package controller review schema differs")
    require_actual_acceptance(review, "package controller")
    author = str(review.get("author_provider", "")).lower()
    reviewer = str(review.get("reviewer_provider", "")).lower()
    if not author or not reviewer or author == reviewer:
        fail("package controller review must come from a different provider")
    if review.get("reviewed_worker_sha256") != expected_hashes:
        fail("package controller reviewed source hashes differ")
    scope = str(review.get("scope", "")).lower()
    publication_denied = "no publication" in scope or "no execution or publication" in scope
    if "prepare-only" not in scope or "no execution" not in scope or not publication_denied:
        fail("package controller review scope must stay prepare-only with no execution/publication")


def proof_path(entry: Any, label: str) -> Path:
    if not isinstance(entry, dict) or set(entry) != {"path", "sha256"}:
        fail(f"actual {label} pin is required")
    path = Path(entry["path"])
    if sha256_file(path) != require_hash(entry["sha256"], label):
        fail(f"actual {label} evidence hash differs")
    return path


def load_release_pins(path: Path) -> dict[str, Any]:
    global TARGET_SOURCE, BUILD_ID
    pins = read_json(path)
    required = {
        "schema_version", "frozen_commit", "build_id", "baseline_archive_sha256", "baseline_image",
        "baseline_api_sha256", "target_api_sha256", "target_api", "target_api_build", "target_api_inspection", "mixed_runtime_bundle", "mixed_source_review",
        "nginx_sha256", "pvc_uid", "source_assets", "runtime_bundle", "public_baseline",
        "reader_snapshot", "build_evidence", "source_review", "export_review", "browser_proof",
        "production_web", "qa_web", "baseline_catalog", "baseline_reader", "repo",
        "package_controller_review", "package_controller_source_sha256",
    }
    if not isinstance(pins, dict) or not required <= set(pins) or pins.get("schema_version") != "qm-mixed-release-pins/v1":
        fail("complete package release pins are required")
    if re.fullmatch(r'[0-9a-f]{40}', str(pins['frozen_commit'])) is None or re.fullmatch(r'quiz-2026\.10\.14-mixed-' + pins['frozen_commit'][:7], str(pins['build_id'])) is None:
        fail('mixed frozen source/build identity differs')
    TARGET_SOURCE, BUILD_ID = pins['frozen_commit'], pins['build_id']
    actual_infra = (
        pins["baseline_archive_sha256"], pins["baseline_image"], pins["baseline_api_sha256"],
        pins["nginx_sha256"], pins["pvc_uid"],
    )
    if actual_infra != (BASELINE_ARCHIVE_SHA256, BASELINE_IMAGE, BASELINE_API_SHA256, NGINX_SHA256, PVC_UID):
        fail("ScreenSong52 infrastructure baseline differs")
    assets = pins["source_assets"]
    if pins['target_api_sha256'] != TARGET_API_SHA256:
        fail('target API SHA differs')
    if not isinstance(assets, dict) or set(assets) != SOURCE_ASSET_PATHS | MIXED_SOURCE_ASSET_PATHS:
        fail("exact thirteen frozen source asset pins are required")
    for relative, digest in assets.items():
        pure = PurePosixPath(relative)
        if pure.is_absolute() or ".." in pure.parts or "\\" in relative:
            fail(f"unsafe frozen source asset path: {relative}")
        require_hash(digest, f"source asset {relative}")
    for label in (
        "runtime_bundle", "mixed_runtime_bundle", "mixed_source_review", "public_baseline", "reader_snapshot", "build_evidence", "source_review",
        "export_review", "browser_proof", "baseline_catalog", "baseline_reader", "package_controller_review",
    ):
        proof_path(pins[label], label)
    expected = pins["package_controller_source_sha256"]
    if not isinstance(expected, dict) or set(expected) != CONTROLLER_FILES:
        fail("exact package controller source hashes are required")
    worker = Path(__file__).resolve().parent
    for name, digest in expected.items():
        require_hash(digest, f"package controller {name}")
        if sha256_file(worker / name) != digest:
            fail(f"package controller source changed after review: {name}")
    verify_controller_review(read_json(Path(pins["package_controller_review"]["path"])), expected)
    require_actual_acceptance(read_json(Path(pins["source_review"]["path"])), "source")
    require_actual_acceptance(read_json(Path(pins['mixed_source_review']['path'])), 'mixed source')
    require_actual_acceptance(read_json(Path(pins["export_review"]["path"])), "export")
    return pins


def git_bytes(repo: Path, commit: str, relative: str) -> bytes:
    result = subprocess.run(
        ["git", "-C", str(repo), "show", f"{commit}:{relative}"],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    if result.returncode != 0:
        fail(f"frozen source is missing or unreadable: {relative}: {result.stderr.decode('utf-8', 'replace').strip()}")
    return result.stdout


def verify_commit(repo: Path, commit: str) -> None:
    result = subprocess.run(
        ["git", "-C", str(repo), "rev-parse", "--verify", f"{commit}^{{commit}}"],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )
    if result.returncode != 0 or result.stdout.strip() != commit:
        fail("frozen commit is not an exact commit object in the repository")


def verify_api_source(repo: Path, commit: str) -> None:
    result = subprocess.run(['git', '-C', str(repo), 'diff', '--name-only', API_CODE_CHECKPOINT, commit, '--', 'next/server'], capture_output=True, text=True)
    if result.returncode != 0:
        fail('frozen API source differs from inspected API code checkpoint')
    verify_api_changed_paths(result.stdout.splitlines())


def verify_api_changed_paths(paths: list[str]) -> None:
    if paths != API_NONCOMPILED_CHANGED_PATHS:
        fail('frozen API source differs from exact three noncompiled test paths')


def frozen_source_bytes(repo: Path, pins: dict[str, Any]) -> dict[str, bytes]:
    root = repo.resolve()
    result: dict[str, bytes] = {}
    for relative, expected in pins["source_assets"].items():
        payload = git_bytes(root, TARGET_SOURCE, relative)
        if sha256_bytes(payload) != expected:
            fail(f"frozen Git source asset differs: {relative}")
        disk = (root / Path(*PurePosixPath(relative).parts)).resolve()
        if not disk.is_relative_to(root) or not disk.is_file() or sha256_file(disk) != expected:
            fail(f"working source differs from frozen Git asset: {relative}")
        result[relative] = payload
    return result


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
    keys = ("quiz_id", "question_id", "revision", "stem", "options", "difficulty", "source", "answer_kind")
    result = {key: question[key] for key in keys}
    result.update({key: question[key] for key in ('difficulty_level', 'context_tag_ids', 'media') if key in question})
    if set(question) != set(result):
        fail('unmodified candidate DTO has unsupported/private fields')
    return result


def private_revision_input(bundle: dict[str, Any], question: dict[str, Any]) -> dict[str, Any]:
    draft = copy.deepcopy(question)
    question_id = draft["question_id"]
    draft.pop("quiz_id")
    draft.pop("revision")
    draft["grading"] = bundle["private_grading"][question_id]
    tags = bundle.get("private_question_metadata", {}).get(question_id, {}).get("editorial_tag_ids")
    if tags:
        draft["editorial_tag_ids"] = tags
    return draft


def verify_mixed_runtime(runtime: dict[str, Any], frozen: dict[str, bytes]) -> None:
    rows = runtime.get('quiz', {}).get('questions', [])
    if runtime.get('quiz', {}).get('quiz_id') != MIXED_QUIZ_ID or len(rows) != 20 or len({row['question_id'] for row in rows}) != 20:
        fail('mixed runtime identity/membership differs')
    raw = json.loads(frozen[MIXED_RAW_PATH])['questions']
    local = json.loads(frozen[f'next/content/{MIXED_QUIZ_ID}/bundle.json'])
    if len(raw) != 20 or len(local.get('quiz', {}).get('questions', [])) != 20:
        fail('mixed raw/runtime membership differs')
    if runtime.get('private_grading') != local.get('private_grading') or runtime.get('private_question_metadata', {}) != local.get('private_question_metadata', {}):
        fail('mixed canonical/runtime private metadata differs')
    local_rows = {q['question_id']: q for q in local['quiz']['questions']}
    if set(local_rows) != {row['question_id'] for row in rows}:
        fail('mixed canonical/runtime IDs differ')
    for source, question in zip(raw, rows, strict=True):
        qid = question['question_id']
        if (question['quiz_id'] != MIXED_QUIZ_ID or question['source'] != {'uri': '/app/' + MIXED_RAW_PATH}
                or question['revision'] != {'number': 1, 'sha256': canonical(private_revision_input(runtime, question))}):
            fail('mixed runtime revision/source differs')
        if {k: v for k, v in question.items() if k not in ('source', 'revision')} != {k: v for k, v in local_rows[qid].items() if k not in ('source', 'revision')}:
            fail('mixed canonical/runtime public fields differ')
        options = question['options']
        key = source.get('correct_answer')
        if (source.get('text') != question['stem'] or source.get('options') != [row['text'] for row in options]
                or type(key) is not int or not 0 <= key < len(options)
                or options[key]['option_id'] != runtime['private_grading'][qid]['correct_option_id']):
            fail('mixed raw/runtime content or private key differs')


def verify_runtime_projection(runtime: dict[str, Any], public: dict[str, Any], reader_snapshot: Any) -> None:
    current, served = question_map(runtime), public_question_map(public)
    if runtime.get("quiz", {}).get("quiz_id") != QUIZ_ID:
        fail("runtime bundle quiz ID differs")
    q93, q95 = current["lotr-rk-93"], current["lotr-rk-95"]
    if q93["options"][5].get("option_id") != "lotr-rk-93-opt-6" or len(q95["options"]) != 4 or q95["options"][3].get("option_id") != "lotr-rk-95-opt-5":
        fail("retained option identifiers differ")
    grading = runtime.get("private_grading", {})
    if grading.get("lotr-rk-93", {}).get("correct_option_id") != "lotr-rk-93-opt-6" or grading.get("lotr-rk-95", {}).get("correct_option_id") != "lotr-rk-95-opt-2":
        fail("retained correct options differ")
    for question_id, question in current.items():
        if canonical(private_revision_input(runtime, question)) != question.get("revision", {}).get("sha256"):
            fail(f"runtime private revision reconstruction differs: {question_id}")
        if question.get("source") != {"uri": "/app/" + RAW_PATH}:
            fail(f"runtime source URI differs: {question_id}")
    for question_id, old in served.items():
        if question_id not in REPAIRED and canonical(public_projection(current[question_id])) != canonical(old):
            fail(f"98 non-target public questions changed: {question_id}")
    for question_id, expected_sha in REPAIRED.items():
        if current[question_id].get("revision") != {"number": 2, "sha256": expected_sha}:
            fail(f"repaired runtime revision differs: {question_id}")
    if reader_snapshot != runtime:
        fail("Reader snapshot bundle differs from exact reviewed runtime bundle")


def verify_raw_repair(old_raw: dict[str, Any], new_raw: dict[str, Any], runtime: dict[str, Any]) -> None:
    old_questions, new_questions = old_raw.get("questions"), new_raw.get("questions")
    if not isinstance(old_questions, list) or not isinstance(new_questions, list) or len(old_questions) != 100 or len(new_questions) != 100:
        fail("raw LOTR pack must retain exactly 100 questions")
    old_head = {key: value for key, value in old_raw.items() if key != "questions"}
    new_head = {key: value for key, value in new_raw.items() if key not in ("questions", "taxonomy_ref")}
    expected_taxonomy = {
        "taxonomy_id": "qm-tags-v1",
        "taxonomy_sha256": "07e4bbb5c7afcdab3b41a26dca1bf0ba9a830d5f776a98ebceeaeb2bd8356151",
    }
    if old_head != new_head or new_raw.get("taxonomy_ref") != expected_taxonomy:
        fail("raw LOTR pack metadata differs outside the approved taxonomy binding")
    changed: list[int] = []
    for index, (old, new) in enumerate(zip(old_questions, new_questions, strict=True), start=1):
        if old != new:
            changed.append(index)
        if index not in (93, 95) and old != new:
            fail(f"98 non-target raw questions/private keys changed: {index}")
    if changed != [93, 95]:
        fail("raw repair must change exactly questions 93 and 95")
    runtime_questions = question_map(runtime)
    for index, question_id in ((93, "lotr-rk-93"), (95, "lotr-rk-95")):
        source, public = new_questions[index - 1], runtime_questions[question_id]
        if source.get("id", "").replace("_", "-") != question_id or source.get("text") != public.get("stem"):
            fail(f"raw/runtime repaired stem differs: {question_id}")
        if source.get("difficulty") != public.get("difficulty_level") or source.get("options") != [row.get("text") for row in public.get("options", [])]:
            fail(f"raw/runtime repaired options or difficulty differ: {question_id}")
        correct = source.get("correct_answer")
        if type(correct) is not int or not 0 <= correct < len(public["options"]):
            fail(f"raw repaired key is invalid: {question_id}")
        if runtime["private_grading"][question_id]["correct_option_id"] != public["options"][correct]["option_id"]:
            fail(f"raw/runtime repaired key differs: {question_id}")


def verify_local_canonical_repair(old_bundle: dict[str, Any], new_bundle: dict[str, Any]) -> None:
    old = question_map(old_bundle)
    new = question_map(new_bundle)
    for question_id, old_question in old.items():
        if question_id not in REPAIRED and new[question_id] != old_question:
            fail(f"98 non-target local questions/revisions changed: {question_id}")
    old_grading = old_bundle.get("private_grading", {})
    new_grading = new_bundle.get("private_grading", {})
    if set(old_grading) != set(new_grading):
        fail("local private grading membership changed")
    for question_id, old_key in old_grading.items():
        if question_id not in REPAIRED and new_grading.get(question_id) != old_key:
            fail(f"98 non-target local private keys changed: {question_id}")
    for question_id, expected_sha in LOCAL_REPAIRED.items():
        if new[question_id].get("revision") != {"number": 2, "sha256": expected_sha}:
            fail(f"local repaired revision differs: {question_id}")
        if new_grading.get(question_id) != old_grading.get(question_id):
            fail(f"local repaired private key was renumbered: {question_id}")
    metadata = new_bundle.get("private_question_metadata", {})
    if set(metadata) != set(REPAIRED):
        fail("local repaired editorial metadata must be limited to questions 93 and 95")


def verify_asset_rows(
    catalog: list[dict[str, Any]],
    reader: list[dict[str, Any]],
    old_catalog: list[dict[str, Any]],
    old_reader: list[dict[str, Any]],
    mixed_row: dict[str, Any] | None = None,
) -> dict[str, int]:
    counts = {"packs": len(catalog), "questions": sum(row.get("questions_count", 0) for row in catalog), "reader_articles": len(reader)}
    if counts != {"packs": 136 if mixed_row else 135, "questions": 4084 if mixed_row else 4064, "reader_articles": 266}:
        fail("target asset counts differ")
    if len(old_catalog) != 135 or sum(row.get("questions_count", 0) for row in old_catalog) != 4064 or len(old_reader) != 264:
        fail("ScreenSong52 baseline asset counts differ")
    if mixed_row and (mixed_row.get('quiz_id') != MIXED_QUIZ_ID or mixed_row.get('questions_count') != 20):
        fail('mixed catalog row identity/count differs')
    old_ids = {row['quiz_id'] for row in old_catalog}
    preserved = [row for row in catalog if row.get('quiz_id') in old_ids]
    added = [row for row in catalog if row.get('quiz_id') not in old_ids]
    if preserved != old_catalog or added != ([mixed_row] if mixed_row else []):
        fail("one or more of the 135 ScreenSong52 catalog rows changed")
    old_by_id = {row["id"]: row for row in old_reader}
    new_by_id = {row["id"]: row for row in reader}
    if any(new_by_id.get(key) != value for key, value in old_by_id.items()):
        fail("one or more prior 264 Reader objects changed")
    added_ids = set(new_by_id) - set(old_by_id)
    if added_ids != {"question:lotr-rk-93", "question:lotr-rk-95"} or any(row.get("status") != "accepted" for row in reader):
        fail("target Reader must add exactly two accepted LOTR articles")
    for question_id, expected_sha in REPAIRED.items():
        article = new_by_id[f"question:{question_id}"]
        if article.get("question_refs") != [{"quiz_id": QUIZ_ID, "question_id": question_id, "revision_sha256": expected_sha}]:
            fail(f"Reader article does not bind full runtime revision: {question_id}")
        if len(article.get("source_links", [])) != 2:
            fail(f"Reader article must retain two reviewed sources: {question_id}")
    return counts


def append_only_cache(baseline_cache: dict[str, Any], runtime: dict[str, Any], mixed: dict[str, Any] | None = None) -> dict[str, Any]:
    if not isinstance(baseline_cache, dict) or len(baseline_cache) != 12 or set(baseline_cache) != set(BASELINE_RUNTIME_IDS) or QUIZ_ID in baseline_cache:
        fail("ScreenSong52 runtime cache must contain exactly twelve prior entries without LOTR RK")
    result = copy.deepcopy(baseline_cache)
    result[QUIZ_ID] = copy.deepcopy(runtime)
    if mixed is not None:
        rows = mixed.get('quiz', {}).get('questions', [])
        if mixed.get('quiz', {}).get('quiz_id') != MIXED_QUIZ_ID or len(rows) != 20 or len({row['question_id'] for row in rows}) != 20:
            fail('mixed runtime pack identity/membership differs')
        result[MIXED_QUIZ_ID] = copy.deepcopy(mixed)
    if len(result) != (14 if mixed is not None else 13) or any(result[key] != value for key, value in baseline_cache.items()) or result[QUIZ_ID] != runtime:
        fail("runtime cache append changed an old entry or the exact runtime bundle")
    return result


def expected_staging_revisions_from_bundles(
    bundles: dict[str, Any], build_id: str
) -> tuple[dict[str, Any], list[dict[str, Any]]]:
    mixed_present = MIXED_QUIZ_ID in bundles
    if len(bundles) != (14 if mixed_present else 13) or set(bundles) != set(BASELINE_RUNTIME_IDS) | {QUIZ_ID} | ({MIXED_QUIZ_ID} if mixed_present else set()):
        fail("expected-staging input must be the exact thirteen-entry runtime cache")
    expected: dict[str, Any] = {}
    proof: list[dict[str, Any]] = []
    for quiz_id, bundle in bundles.items():
        rows: dict[str, Any] = {}
        for public in bundle.get("quiz", {}).get("questions", []):
            private = private_revision_input(bundle, public)
            if canonical(private) != public.get("revision", {}).get("sha256"):
                fail(f"private revision reconstruction mismatch: {quiz_id}/{public.get('question_id')}")
            uri = private.get("source", {}).get("uri")
            if not isinstance(uri, str) or not uri.startswith("/app/quizzes/"):
                fail(f"unexpected published source URI: {quiz_id}/{public.get('question_id')}")
            private["source"]["uri"] = f"/opt/quiz-master/releases/{build_id}/quizzes/{uri.removeprefix('/app/quizzes/')}"
            question_id = public["question_id"]
            rows[question_id] = {"number": public["revision"]["number"], "sha256": canonical(private)}
            proof.append({
                "quiz_id": quiz_id,
                "question_id": question_id,
                "published_private_revision_verified": True,
                "staging_uri": private["source"]["uri"],
            })
        expected[quiz_id] = rows
    if sum(len(rows) for rows in expected.values()) != (280 if mixed_present else 260):
        fail("expected exactly 260 canonical staging revisions")
    return expected, proof


def revision_map_from_documents(documents: Iterable[Any]) -> dict[tuple[str, str], str]:
    result: dict[tuple[str, str], str] = {}
    for document in documents:
        questions = document.get("quiz", {}).get("questions", []) if isinstance(document, dict) else []
        for question in questions:
            quiz_id, question_id = question.get("quiz_id"), question.get("question_id")
            revision = question.get("revision", {}).get("sha256")
            if isinstance(quiz_id, str) and isinstance(question_id, str) and isinstance(revision, str):
                result[(quiz_id, question_id)] = revision
    return result


def count_exact_article_bindings(articles: list[dict[str, Any]], revisions: dict[tuple[str, str], str]) -> int:
    return sum(
        1
        for article in articles
        if article.get("status") == "accepted"
        for ref in article.get("question_refs", [])
        if revisions.get((ref.get("quiz_id"), ref.get("question_id"))) == ref.get("revision_sha256")
    )


def frozen_revision_map(repo: Path, commit: str) -> dict[tuple[str, str], str]:
    listing = subprocess.run(
        ["git", "-C", str(repo), "ls-tree", "-r", "--name-only", commit, "--", "next/content", "study/question_articles/snapshots"],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )
    if listing.returncode != 0:
        fail("cannot list frozen canonical/snapshot inputs")
    paths = [
        line.strip()
        for line in listing.stdout.splitlines()
        if line.endswith("/bundle.json") or (line.startswith("study/question_articles/snapshots/") and line.endswith(".json"))
    ]
    paths.sort(key=lambda value: (value.startswith("study/question_articles/snapshots/"), value))
    documents = [json.loads(git_bytes(repo, commit, relative).decode("utf-8")) for relative in paths]
    return revision_map_from_documents(documents)


def verify_build_evidence(pins: dict[str, Any], frozen: dict[str, bytes]) -> tuple[str, str]:
    build = read_json(Path(pins["build_evidence"]["path"]))
    if build.get("frozen_source") != TARGET_SOURCE or build.get("build_id") != BUILD_ID:
        fail("actual Flutter build evidence is not source-bound")
    checks = build.get("checks")
    if not isinstance(checks, list) or len(checks) != 2 or {row.get("label") for row in checks} != {"production", "qa"}:
        fail("two actual production/QA Flutter build records are required")
    hashes: dict[str, str] = {}
    for row in checks:
        label = row["label"]
        web = Path(pins[f"{label}_web"])
        expected_js = require_hash(row.get("main_dart_js_sha256"), f"{label} JavaScript")
        if row.get("actual_exit") != 0 or row.get("frozen_assets_byte_identical") is not True or Path(row.get("output", "")).resolve() != web.resolve():
            fail(f"actual {label} Flutter build receipt differs")
        if sha256_file(web / "main.dart.js") != expected_js:
            fail(f"actual {label} compiled JavaScript differs")
        embedded = {
            "next/apps/quiz_app/assets/catalog.json": web / "assets/assets/catalog.json",
            "next/apps/quiz_app/assets/study/question-articles.json": web / "assets/assets/study/question-articles.json",
        }
        for relative, target in embedded.items():
            if not target.is_file() or target.read_bytes() != frozen[relative]:
                fail(f"actual {label} build lacks frozen asset: {relative}")
        hashes[label] = expected_js
    if hashes["production"] == hashes["qa"]:
        fail("production and QA builds must use separate compiled API configurations")
    return hashes["production"], hashes["qa"]


def verify_browser_receipt(proof: dict[str, Any]) -> None:
    if proof.get("frozen_source") != TARGET_SOURCE or proof.get("build_id") != BUILD_ID:
        fail("browser proof source/build identity differs")
    if proof.get("browser_inactive") is not True or proof.get("ports_closed") != [19090, 19093] or proof.get("browser_close_actual_exit") != 0 or proof.get("qa_server_actual_exit") != 0:
        fail("actual browser lifecycle/cleanup proof differs")
    answers = {row.get("question_id"): json.loads(row.get("receipt", "{}")) for row in proof.get("answers", [])}
    if {key: answers.get(key, {}).get("question_revision", {}).get("sha256") for key in REPAIRED} != REPAIRED:
        fail("actual browser receipts do not bind repaired revisions")


def validate_archive_members(members: Iterable[tarfile.TarInfo], prefix_name: str) -> None:
    prefix = prefix_name + "/"
    names: set[str] = set()
    any_member = False
    for member in members:
        any_member = True
        pure = PurePosixPath(member.name)
        if (
            not member.isfile()
            or pure.is_absolute()
            or ".." in pure.parts
            or "\\" in member.name
            or ':' in member.name
            or member.name != pure.as_posix()
            or member.name in names
            or not member.name.startswith(prefix)
            or len(pure.parts) < 2
        ):
            fail(f"unsafe or unexpected archive member: {member.name}")
        names.add(member.name)
    if not any_member:
        fail("baseline archive is empty")


def verify_safe_archive(archive: Path) -> list[tarfile.TarInfo]:
    if sha256_file(archive) != BASELINE_ARCHIVE_SHA256:
        fail("ScreenSong52 archive SHA-256 differs")
    with tarfile.open(archive, "r:gz") as package:
        members = package.getmembers()
    validate_archive_members(members, BASELINE_BUILD)
    return members


def archive_bytes(archive: Path, relative: str) -> bytes:
    name = f"{BASELINE_BUILD}/{relative}"
    with tarfile.open(archive, "r:gz") as package:
        try:
            member = package.getmember(name)
        except KeyError:
            fail(f"baseline archive lacks required member: {relative}")
        payload = package.extractfile(member)
        if payload is None:
            fail(f"baseline archive member is unreadable: {relative}")
        return payload.read()


def archive_json(archive: Path, relative: str) -> Any:
    return json.loads(archive_bytes(archive, relative).decode("utf-8"))


def require_new_output_root(path: Path) -> None:
    if path.exists():
        fail("--output-root must not already exist; choose a new caller-owned path")


def extract_immutable(archive: Path, destination: Path) -> None:
    if destination.exists():
        fail(f"output stage already exists: {destination}")
    with tarfile.open(archive, "r:gz") as package:
        members = package.getmembers()
        validate_archive_members(members, BASELINE_BUILD)
        for member in members:
            relative = PurePosixPath(member.name).relative_to(BASELINE_BUILD)
            target = destination / Path(*relative.parts)
            if not target.resolve().is_relative_to(destination.resolve()):
                fail('archive extraction escapes stage boundary')
            target.parent.mkdir(parents=True, exist_ok=True)
            payload = package.extractfile(member)
            if payload is None:
                fail(f"unreadable archive member: {member.name}")
            target.write_bytes(payload.read())


def verify_checksum_manifest(stage: Path) -> None:
    manifest = stage / "checksums.txt"
    entries: dict[str, str] = {}
    for line in manifest.read_text(encoding="utf-8").splitlines():
        digest, relative = line.split("  ", 1)
        pure = PurePosixPath(relative)
        if require_hash(digest, f"baseline checksum {relative}") != digest or pure.is_absolute() or ".." in pure.parts or "\\" in relative or relative in entries:
            fail(f"unsafe baseline checksum entry: {relative}")
        entries[relative] = digest
    actual = {path.relative_to(stage).as_posix() for path in stage.rglob("*") if path.is_file() and path.name != "checksums.txt"}
    if set(entries) != actual:
        fail("baseline checksum manifest membership differs")
    for relative, digest in entries.items():
        if sha256_file(stage / Path(*PurePosixPath(relative).parts)) != digest:
            fail(f"baseline checksum differs: {relative}")


def file_hashes(root: Path, pattern: str = "*.json") -> dict[str, str]:
    return {path.relative_to(root).as_posix(): sha256_file(path) for path in root.rglob(pattern) if path.is_file()}


def verify_baseline_stage(stage: Path, pins: dict[str, Any]) -> dict[str, Any]:
    verify_checksum_manifest(stage)
    metadata = read_json(stage / "web/version.json")
    if metadata.get("buildId") != BASELINE_BUILD or metadata.get("commit") != BASELINE_SOURCE or metadata.get("source_commit") != BASELINE_SOURCE:
        fail("ScreenSong52 baseline metadata differs")
    for path, digest in (
        (stage / "api", BASELINE_API_SHA256),
        (stage / "nginx.conf", NGINX_SHA256),
        (stage / "web/main.dart.js", BASELINE_MAIN_DART_JS_SHA256),
    ):
        if sha256_file(path) != digest:
            fail(f"ScreenSong52 binary/config differs: {path.name}")
    catalog = as_rows(read_json(stage / "web/assets/assets/catalog.json"), "baseline catalog")
    reader = as_rows(read_json(stage / "web/assets/assets/study/question-articles.json"), "baseline Reader")
    pinned_catalog = as_rows(read_json(Path(pins["baseline_catalog"]["path"])), "pinned baseline catalog")
    pinned_reader = as_rows(read_json(Path(pins["baseline_reader"]["path"])), "pinned baseline Reader")
    if catalog != pinned_catalog or reader != pinned_reader:
        fail("extracted ScreenSong52 catalog/Reader differs from pinned baseline")
    if len(catalog) != 135 or sum(row["questions_count"] for row in catalog) != 4064 or len(reader) != 264:
        fail("ScreenSong52 extracted counts differ from 135/4064/264")
    cache = read_json(stage / "runtime-bundles.json")
    append_only_cache(cache, {})
    for quiz_id, bundle in cache.items():
        if read_json(stage / "next/content" / quiz_id / "bundle.json") != bundle:
            fail(f"ScreenSong52 cache/content bundle differs: {quiz_id}")
    return {
        "catalog": copy.deepcopy(catalog),
        "reader": copy.deepcopy(reader),
        "cache": copy.deepcopy(cache),
        "raw": file_hashes(stage / "quizzes"),
        "content": file_hashes(stage / "next/content"),
    }


def copy_target_inputs(stage: Path, frozen: dict[str, bytes], runtime: dict[str, Any], mixed: dict[str, Any]) -> None:
    for relative in PACKAGE_SOURCE_PATHS | (MIXED_SOURCE_ASSET_PATHS - {f'next/content/{MIXED_QUIZ_ID}/bundle.json'}):
        target = stage / Path(*PurePosixPath(relative).parts)
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(frozen[relative])
    write_json_lf(stage / TARGET_CONTENT_ROOT / "bundle.json", runtime)
    write_json_lf(stage / 'next/content' / MIXED_QUIZ_ID / 'bundle.json', mixed)


def copy_compiled_web(stage: Path, production_web: Path) -> None:
    shutil.rmtree(stage / "web")
    shutil.copytree(production_web, stage / "web")


def assert_preserved_stage(stage: Path, baseline: dict[str, Any], runtime: dict[str, Any], frozen: dict[str, bytes], mixed: dict[str, Any]) -> None:
    raw = file_hashes(stage / "quizzes")
    target_raw_key = PurePosixPath(RAW_PATH).relative_to("quizzes").as_posix()
    mixed_raw_key = PurePosixPath(MIXED_RAW_PATH).relative_to('quizzes').as_posix()
    if set(raw) != set(baseline["raw"]) | {mixed_raw_key} or any(raw[key] != digest for key, digest in baseline["raw"].items() if key != target_raw_key):
        fail("one or more of the 134 unrelated raw packs changed")
    if raw[target_raw_key] != sha256_bytes(frozen[RAW_PATH]):
        fail("staged repaired raw pack differs from frozen source")
    if raw[mixed_raw_key] != sha256_bytes(frozen[MIXED_RAW_PATH]):
        fail('staged mixed raw pack differs from frozen source')
    content = file_hashes(stage / "next/content")
    allowed = {f"{QUIZ_ID}/{name}.json" for name in ("draft", "manifest", "bundle")}
    added = {f'{MIXED_QUIZ_ID}/{name}.json' for name in ('draft', 'manifest', 'bundle')}
    if set(content) != set(baseline["content"]) | added or any(content[key] != digest for key, digest in baseline["content"].items() if key not in allowed):
        fail("one or more unrelated canonical files changed")
    if content[f"{QUIZ_ID}/draft.json"] != sha256_bytes(frozen[f"{TARGET_CONTENT_ROOT}/draft.json"]):
        fail("staged LOTR draft differs from frozen source")
    if content[f"{QUIZ_ID}/manifest.json"] != sha256_bytes(frozen[f"{TARGET_CONTENT_ROOT}/manifest.json"]):
        fail("staged LOTR manifest differs from frozen source")
    if read_json(stage / TARGET_CONTENT_ROOT / "bundle.json") != runtime:
        fail("staged LOTR bundle differs from exact reviewed runtime bundle")
    for name in ('draft', 'manifest'):
        relative = f'next/content/{MIXED_QUIZ_ID}/{name}.json'
        if (stage / relative).read_bytes() != frozen[relative]:
            fail('staged mixed canonical source differs')
    if read_json(stage / 'next/content' / MIXED_QUIZ_ID / 'bundle.json') != mixed:
        fail('staged mixed runtime differs')


def patch_cutover_text(body: str, production_js_sha256: str, *, mixed: bool = False) -> str:
    require_hash(production_js_sha256, "production JavaScript")
    body = replace_once(body, f"quiz_build={BASELINE_BUILD}", f"quiz_build={BUILD_ID}")
    body = replace_once(body, r"r'quiz-2026\.10\.14-screen-song-[0-9a-f]{7}'", "r" + repr(re.escape(BUILD_ID)))
    body = replace_once(body, BASELINE_SOURCE, TARGET_SOURCE, 2)
    body = replace_once(body, BASELINE_MAIN_DART_JS_SHA256, production_js_sha256, 2)
    body = replace_once(body, BASELINE_CUTOVER_IMAGE, BASELINE_IMAGE)
    body = replace_once(
        body,
        "meta['packs']==135 and meta['questions']==4064 and meta['question_articles']==264",
        "meta['packs']==135 and meta['questions']==4064 and meta['question_articles']==266",
    )
    for guard in ("[[ \"$quiz_mode\" = prepare ]]", BASELINE_API_SHA256, NGINX_SHA256, PVC_UID):
        if guard not in body:
            fail(f"baseline cutover guard differs: {guard}")
    if "helm upgrade" in body or body.count("exit 0\n") != 1:
        fail("baseline cutover is not prepare-only")
    body = body.split("exit 0\n", 1)[0] + "exit 0\n"
    body = replace_once(body, BASELINE_API_SHA256, TARGET_API_SHA256, 2)
    gate = 'python3 verify_candidate_runtime.py --image "$quiz_image" --source-db "/opt/quiz-master/backups/$quiz_run.sqlite" --output "$quiz_run-candidate-runtime.json" --stage "$PWD"\n'
    if mixed:
        body = replace_once(body, "meta['packs']==135 and meta['questions']==4064", "meta['packs']==136 and meta['questions']==4084")
        gate = gate.rstrip('\n') + ' --expected-packs 136 --expected-questions 4084\n'
    body = replace_once(body, 'quiz_archive="/var/lib/rancher/k3s/agent/images/$quiz_build.tar"', gate + 'quiz_archive="/var/lib/rancher/k3s/agent/images/$quiz_build.tar"')
    return body.replace("\r\n", "\n")


def patch_values_text(body: str) -> str:
    body, image_count = re.subn(r"(?m)^image:.*$", f"image: {BASELINE_IMAGE}", body)
    body, build_count = re.subn(r"(?m)^buildId:.*$", f"buildId: {BUILD_ID}", body)
    if image_count != 1 or build_count != 1:
        fail("release-values anchors absent or duplicated")
    return body.replace("\r\n", "\n").rstrip("\n") + "\n"


def patch_rehearsal_text(body: str, *, mixed: bool = False) -> str:
    old_ids = "['cinema-encore-20261011','music-encore-20261011','planet-paradoxes-20261010','philias-lifestyle-part-1','phobias-nature','home-alone-1-part-1','cinema-people-20261011','music-people-20261011','film-craft-20261013','music-craft-20261013','acting-craft-20261014','screen-song-20261014']"
    body = replace_once(body, old_ids, old_ids[:-1] + ",'lotr-return-king-bts-100']", 2)
    old_else = "  else:\n   assert len(matches)==(0 if qid in ['philias-lifestyle-part-1','phobias-nature'] else 28 if qid in ['cinema-people-20261011','music-people-20261011'] else 10)"
    target_branch = (
        "  elif qid=='lotr-return-king-bts-100':\n"
        f"   expected_article_refs={REPAIRED!r}\n"
        "   assert bundle['quiz']['quiz_id']=='lotr-return-king-bts-100'\n"
        "   assert len(matches)==2 and {ref['question_id']:ref['revision_sha256'] for ref in matches}==expected_article_refs\n"
        "   live_questions={q['question_id']:q for q in live['quiz']['questions']}\n"
        "   assert {key:live_questions[key]['revision']['sha256'] for key in expected_article_refs}==expected_article_refs\n"
        "   assert live_questions['lotr-rk-93']['options'][5]['option_id']=='lotr-rk-93-opt-6'\n"
        "   assert len(live_questions['lotr-rk-95']['options'])==4 and live_questions['lotr-rk-95']['options'][3]['option_id']=='lotr-rk-95-opt-5'\n"
        "   assert bundle['private_grading']['lotr-rk-93']['correct_option_id']=='lotr-rk-93-opt-6' and bundle['private_grading']['lotr-rk-95']['correct_option_id']=='lotr-rk-95-opt-2'\n"
        + old_else
    )
    body = replace_once(body, old_else, target_branch)
    body = replace_once(body, "assert graded==215 and finished==13", "assert graded==315 and finished==14")
    body = replace_once(body, "assert len(req('/v1/history',token=token))==13", "assert len(req('/v1/history',token=token))==14")
    body = replace_once(body, "'canonical_packs':12,'canonical_questions':160", "'canonical_packs':13,'canonical_questions':260")
    required = (
        "old_rows[t] <= current", "pragma integrity_check", "after[3]-before[3]==135",
        "old_api_rollback", "sqlite:rehearsal-final/quiz.sqlite", "feedback_lifecycle",
    )
    if any(guard not in body for guard in required):
        fail("baseline rehearsal DB/rollback guards differ")
    if mixed:
        body = replace_once(body, old_ids[:-1] + ",'lotr-return-king-bts-100']", old_ids[:-1] + ",'lotr-return-king-bts-100','" + MIXED_QUIZ_ID + "']", 2)
        branch = "  elif qid=='" + MIXED_QUIZ_ID + "':\n   assert bundle['quiz']['quiz_id']=='" + MIXED_QUIZ_ID + "'\n   assert len(matches)==0 and len(expected_questions)==20\n" + old_else
        body = replace_once(body, old_else, branch)
        body = replace_once(body, 'assert graded==315 and finished==14', 'assert graded==335 and finished==15')
        body = replace_once(body, "assert len(req('/v1/history',token=token))==14", "assert len(req('/v1/history',token=token))==15")
        body = replace_once(body, "'canonical_packs':13,'canonical_questions':260", "'canonical_packs':14,'canonical_questions':280")
        body = replace_once(body, 'after[3]-before[3]==135', 'after[3]-before[3]==136')
    compile(body, "rehearse.py", "exec")
    return body.replace("\r\n", "\n")


def inject_version(stage: Path, counts: dict[str, int], production_js_sha256: str) -> dict[str, Any]:
    metadata = {
        "buildId": BUILD_ID,
        "commit": TARGET_SOURCE,
        "source_commit": TARGET_SOURCE,
        "local_build": True,
        "packs": counts["packs"],
        "questions": counts["questions"],
        "study_modules": 6,
        "study_questions": 120,
        "question_articles": counts["reader_articles"],
        "api_sha256": TARGET_API_SHA256,
        "main_dart_js_sha256": production_js_sha256,
        "taxonomy_id": "qm-tags-v1",
        "taxonomy_sha256": "07e4bbb5c7afcdab3b41a26dca1bf0ba9a830d5f776a98ebceeaeb2bd8356151",
        "taxonomy_file_sha256": "98f019902b5cce5161b5980f3338d9cd072b094b0a760fc93adb748832546f8c",
    }
    if len(metadata) != 14 or sha256_file(stage / "web/main.dart.js") != production_js_sha256:
        fail("compiled Web/version metadata inputs differ")
    write_json_lf(stage / "web/version.json", metadata)
    return metadata


def write_checksums(stage: Path) -> tuple[int, str]:
    files = sorted(path for path in stage.rglob("*") if path.is_file() and path.name != "checksums.txt")
    body = "".join(f"{sha256_file(path)}  {path.relative_to(stage).as_posix()}\n" for path in files)
    (stage / "checksums.txt").write_bytes(body.encode("utf-8"))
    for line in body.splitlines():
        digest, relative = line.split("  ", 1)
        if sha256_file(stage / relative) != digest:
            fail(f"checksum self-verification failed: {relative}")
    return len(files) + 1, sha256_file(stage / "checksums.txt")


def archive_and_verify(stage: Path, output_root: Path) -> tuple[Path, str, int]:
    archive = output_root / f"{stage.name}.tar.gz"
    if archive.exists():
        fail("target archive already exists")
    with archive.open("xb") as raw:
        with gzip.GzipFile(filename="", mode="wb", fileobj=raw, mtime=0) as compressed:
            with tarfile.open(fileobj=compressed, mode="w", format=tarfile.PAX_FORMAT) as package:
                for path in sorted(candidate for candidate in stage.rglob("*") if candidate.is_file()):
                    info = tarfile.TarInfo(f"{stage.name}/{path.relative_to(stage).as_posix()}")
                    info.size = path.stat().st_size
                    info.mode = 0o755 if path.relative_to(stage).as_posix() == "api" else 0o644
                    info.mtime = 0
                    info.uid = info.gid = 0
                    info.uname = info.gname = ""
                    with path.open("rb") as source:
                        package.addfile(info, source)
    with tarfile.open(archive, "r:gz") as package:
        members = package.getmembers()
        validate_archive_members(members, stage.name)
        for member in members:
            payload = package.extractfile(member)
            if payload is None:
                fail(f"generated archive member is unreadable: {member.name}")
            relative = Path(*PurePosixPath(member.name).parts[1:])
            if sha256_bytes(payload.read()) != sha256_file(stage / relative):
                fail(f"generated archive member hash differs: {member.name}")
    return archive, sha256_file(archive), len(members)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--pins", type=Path, required=True)
    parser.add_argument("--repo", type=Path, required=True)
    parser.add_argument("--frozen-commit", required=True)
    parser.add_argument("--production-web", type=Path, required=True)
    parser.add_argument("--qa-web", type=Path, required=True)
    parser.add_argument("--output-root", type=Path, required=True)
    parser.add_argument("--prior-archive", type=Path, required=True)
    args = parser.parse_args()

    pins = load_release_pins(args.pins)
    repo = args.repo.resolve()
    if repo != Path(pins["repo"]).resolve() or args.frozen_commit != TARGET_SOURCE:
        fail("command repository/frozen source differs from package pins")
    if args.production_web.resolve() != Path(pins["production_web"]).resolve() or args.qa_web.resolve() != Path(pins["qa_web"]).resolve():
        fail("compiled directories differ from package pins")
    verify_commit(repo, args.frozen_commit)
    verify_api_source(repo, args.frozen_commit)
    frozen = frozen_source_bytes(repo, pins)
    production_js, qa_js = verify_build_evidence(pins, frozen)
    target_api = verify_target_api(pins)
    verify_browser_receipt(read_json(Path(pins["browser_proof"]["path"])))
    verify_safe_archive(args.prior_archive)

    runtime = read_json(Path(pins["runtime_bundle"]["path"]))
    mixed = read_json(Path(pins['mixed_runtime_bundle']['path']))
    verify_mixed_runtime(mixed, frozen)
    public = read_json(Path(pins["public_baseline"]["path"]))
    snapshot = read_json(Path(pins["reader_snapshot"]["path"]))
    verify_runtime_projection(runtime, public, snapshot)
    old_raw = archive_json(args.prior_archive, RAW_PATH)
    new_raw = json.loads(frozen[RAW_PATH].decode("utf-8"))
    verify_raw_repair(old_raw, new_raw, runtime)
    old_local_bundle = archive_json(args.prior_archive, f"{TARGET_CONTENT_ROOT}/bundle.json")
    new_local_bundle = json.loads(frozen[f"{TARGET_CONTENT_ROOT}/bundle.json"].decode("utf-8"))
    verify_local_canonical_repair(old_local_bundle, new_local_bundle)
    old_catalog = as_rows(archive_json(args.prior_archive, "web/assets/assets/catalog.json"), "baseline catalog")
    old_reader = as_rows(archive_json(args.prior_archive, "web/assets/assets/study/question-articles.json"), "baseline Reader")
    catalog = as_rows(json.loads(frozen["next/apps/quiz_app/assets/catalog.json"].decode("utf-8")), "target catalog")
    reader = as_rows(json.loads(frozen["next/apps/quiz_app/assets/study/question-articles.json"].decode("utf-8")), "target Reader")
    mixed_rows = [row for row in catalog if row.get('quiz_id') == MIXED_QUIZ_ID]
    if len(mixed_rows) != 1:
        fail('target mixed catalog row is missing/duplicated')
    counts = verify_asset_rows(catalog, reader, old_catalog, old_reader, mixed_rows[0])
    baseline_cache = archive_json(args.prior_archive, "runtime-bundles.json")
    target_cache = append_only_cache(baseline_cache, runtime, mixed)
    revisions = frozen_revision_map(repo, TARGET_SOURCE)
    before_bindings = count_exact_article_bindings(old_reader, revisions)
    after_bindings = count_exact_article_bindings(reader, revisions)
    if (before_bindings, after_bindings) != (143, 145):
        fail("accepted exact question/article bindings must compute as 143-to-145")
    expected, revision_proof = expected_staging_revisions_from_bundles(target_cache, BUILD_ID)

    require_new_output_root(args.output_root)
    args.output_root.mkdir(parents=True)
    stage = args.output_root / BUILD_ID
    extract_immutable(args.prior_archive, stage)
    baseline = verify_baseline_stage(stage, pins)
    copy_target_api(stage, target_api)
    copy_target_inputs(stage, frozen, runtime, mixed)
    shutil.copyfile(Path(__file__).parent / 'verify_candidate_runtime.py', stage / 'verify_candidate_runtime.py')
    shutil.copyfile(Path(pins['public_baseline']['path']), stage / 'runtime-public-baseline.json')
    copy_compiled_web(stage, args.production_web)
    write_json_lf(stage / "runtime-bundles.json", target_cache)
    assert_preserved_stage(stage, baseline, runtime, frozen, mixed)
    if read_json(stage / "runtime-bundles.json") != target_cache:
        fail("staged runtime cache differs from exact append-only result")
    metadata = inject_version(stage, counts, production_js)
    (stage / "cutover.sh").write_text(patch_cutover_text((stage / "cutover.sh").read_text(encoding="utf-8"), production_js, mixed=True), encoding="utf-8", newline="\n")
    (stage / "rehearse.py").write_text(patch_rehearsal_text((stage / "rehearse.py").read_text(encoding="utf-8"), mixed=True), encoding="utf-8", newline="\n")
    (stage / "release-values.yaml").write_text(patch_values_text((stage / "release-values.yaml").read_text(encoding="utf-8")), encoding="utf-8", newline="\n")
    write_json_lf(stage / "expected-staging-revisions.json", expected)
    file_members, manifest_sha256 = write_checksums(stage)
    archive, archive_sha256, tar_members = archive_and_verify(stage, args.output_root)
    result = {
        "status": "PREPARED_NOT_EXECUTED",
        "build_id": BUILD_ID,
        "frozen_commit": TARGET_SOURCE,
        "release_pins_sha256": sha256_file(args.pins),
        "controller_review_sha256": pins["package_controller_review"]["sha256"],
        "baseline_input": {
            "build_id": BASELINE_BUILD,
            "source_commit": BASELINE_SOURCE,
            "archive": str(args.prior_archive),
            "archive_sha256": BASELINE_ARCHIVE_SHA256,
            "image": BASELINE_IMAGE,
            "pvc_uid": PVC_UID,
        },
        "counts": {
            **counts,
            "preserved_catalog_rows": len(old_catalog),
            "preserved_questions": sum(row["questions_count"] for row in old_catalog),
            "preserved_reader_articles": len(old_reader),
            "baseline_cache_entries": len(baseline_cache),
            "runtime_cache_entries": len(target_cache),
            "staging_canonical_questions_before": 160,
            "staging_canonical_questions": sum(len(rows) for rows in expected.values()),
            "accepted_question_article_bindings_before": before_bindings,
            "accepted_question_article_bindings": after_bindings,
            "repaired_questions": len(REPAIRED),
        },
        "metadata": metadata,
        "frozen_source_assets": pins["source_assets"],
        "runtime_bundle_sha256": pins["runtime_bundle"]["sha256"],
        "production_js_sha256": production_js,
        "qa_js_sha256_checked_not_packaged": qa_js,
        "qa_web_checked_not_packaged": str(args.qa_web),
        "nginx_config_sha256": NGINX_SHA256,
        "api_sha256": TARGET_API_SHA256,
        "expected_staging_revision_proof": revision_proof,
        "stage": str(stage),
        "archive": str(archive),
        "archive_sha256": archive_sha256,
        "file_members": file_members,
        "tar_members": tar_members,
        "manifest_sha256": manifest_sha256,
        "remaining_gates": [
            "Root-owned copied-DB rehearsal and rollback evidence",
            "Root-owned immutable image/Helm/server/browser verification",
            "authorized publication and post-publication verification",
        ],
    }
    write_json_lf(args.output_root / "package-preparation.json", result)
    print(json.dumps({key: result[key] for key in ("status", "build_id", "stage", "archive", "archive_sha256", "counts")}, ensure_ascii=False))


if __name__ == "__main__":
    main()
