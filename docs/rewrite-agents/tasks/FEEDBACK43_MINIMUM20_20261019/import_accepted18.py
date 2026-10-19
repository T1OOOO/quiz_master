"""Fail-closed import of the accepted Harry Potter, cat, and dog additions.

Without flags this command is a read-only plan and validation.  ``--apply``
performs the source mutation only after every source baseline, receipt and draft
guard passes.  After ``quizctl import/build`` has regenerated the three
canonical directories, ``--write-evidence`` verifies them and writes evidence.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import subprocess
import tempfile
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[4]
TASK_DIR = Path(__file__).resolve().parent
PINNED_REVISION = "0c409ff28ca26b9a27ad30e07050e7892864e570"
VERSION = "2026.10.19.minimum20"
PUBLISHED_AT = "2026-10-19T00:00:00Z"
ALLOWED_LEGACY_FIELDS = (
    "id", "type", "text", "options", "correct_answer", "difficulty", "explanation",
)

PACKS: dict[str, dict[str, Any]] = {
    "harry_potter": {
        "source": ROOT / "quizzes/Cinema/Thematic80/harry_potter.json",
        "canonical": ROOT / "next/content/theme-harry-potter",
        "draft": ROOT / "study/drafts/feedback43-harrypotter-extra-20261019.json",
        "acceptance": TASK_DIR / "harrypotter-acceptance.json",
        "source_id": "theme-harry-potter",
        "draft_pack_id": "theme-harry-potter",
        "base_sha256": "140af337a118fb7880fe0a0843381442c68c0cf5e49619162f8b64ed53a7c2fa",
        "draft_sha256": "b7e4e85b2ccde778f5d622686de03a88845ffe18a2361c136ef4d9fc6bbcebeb",
        "prefix_count": 10,
        "description": "20 вопросов о мире Гарри Поттера: факультетах, Хогвартсе, квиддиче и Патронусах.",
    },
    "cats": {
        "source": ROOT / "quizzes/Nature/Cats/cats_behavior_and_psychology.json",
        "canonical": ROOT / "next/content/cats-behavior-and-psychology",
        "draft": ROOT / "study/drafts/feedback43-animal-extras-20261019.json",
        "acceptance": TASK_DIR / "animal-extras-acceptance.json",
        "source_id": "cats_behavior_and_psychology",
        "draft_pack_id": "cats_behavior_and_psychology",
        "base_sha256": "bf6dfce96b6c2cfc3d97362a610a4095b2f27da6bdcc2b38e83a6d0f39802126",
        "draft_sha256": "043f712010cc4590f2f9fcb5bc501d1810859f9f86c83fdcef35946e8849ac52",
        "prefix_count": 17,
        "description": "20 вопросов о поведении и когнитивных исследованиях кошек; часть вопросов привязана к конкретным экспериментам.",
    },
    "dogs": {
        "source": ROOT / "quizzes/Nature/Dogs/dogs_science_and_experiments.json",
        "canonical": ROOT / "next/content/dogs-science-and-experiments",
        "draft": ROOT / "study/drafts/feedback43-animal-extras-20261019.json",
        "acceptance": TASK_DIR / "animal-extras-acceptance.json",
        "source_id": "dogs_science_and_experiments",
        "draft_pack_id": "dogs_science_and_experiments",
        "base_sha256": "477c0e97403b39cd153825b7ac3460ab965f76f78eea0b86e2da38a23f4de383",
        "draft_sha256": "043f712010cc4590f2f9fcb5bc501d1810859f9f86c83fdcef35946e8849ac52",
        "prefix_count": 15,
        "description": "20 вопросов о собаках в науке и экспериментах; часть вопросов привязана к конкретным исследованиям.",
    },
}


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def normalized_lf_digest(data: bytes) -> str:
    return digest(data.replace(b"\r\n", b"\n").replace(b"\r", b"\n"))


def load_json(path: Path) -> tuple[bytes, dict[str, Any]]:
    data = path.read_bytes()
    return data, json.loads(data)


def pinned_source(path: Path) -> dict[str, Any]:
    relative = path.relative_to(ROOT).as_posix()
    data = subprocess.check_output(["git", "show", f"{PINNED_REVISION}:{relative}"], cwd=ROOT)
    return json.loads(data)


def require_receipt(spec: dict[str, Any], draft_digest: str) -> dict[str, Any]:
    _, receipt = load_json(spec["acceptance"])
    assert receipt == {
        "decision": "ACCEPT EXACTDRAFT",
        "draft_sha256": draft_digest,
        "reviewer_provider": "google",
        "reviewer_model": "gemini-4-argon-high",
        "conversation_id": receipt["conversation_id"],
    }
    assert receipt["conversation_id"]
    return receipt


def append_explanation(question: dict[str, Any], *, animal: bool) -> str:
    answer = question["correct_answer_index"]
    options = question["options"]
    wrong = [index for index in range(4) if index != answer]
    rationales = question["distractor_rationales_ru"]
    assert len(options) == 4 and len(rationales) == 3 and len(wrong) == 3
    explanation = question["explanation_ru"]
    if animal:
        scope = question["scientific_scope_ru"]
        assert scope
        explanation += " Научные рамки: " + scope
    rendered = [f"{options[index]}: {reason}" for index, reason in zip(wrong, rationales, strict=True)]
    return explanation + " Другие варианты: " + "; ".join(rendered)


def additions(spec_name: str, draft: dict[str, Any]) -> list[dict[str, Any]]:
    if spec_name == "harry_potter":
        assert draft["draft_id"] == "feedback43-harrypotter-extra-20261019"
        selected = draft["questions"]
        assert len(selected) == 10
        animal = False
    else:
        assert draft["draft_id"] == "feedback43-animal-extras-20261019"
        selected = [question for question in draft["questions"] if question["pack_id"] == PACKS[spec_name]["draft_pack_id"]]
        assert len(selected) == (3 if spec_name == "cats" else 5)
        animal = True
    result: list[dict[str, Any]] = []
    for question in selected:
        difficulty = {"easy": 3, "medium": 4}[question["estimated_difficulty"]] if not animal else question["difficulty_10"]
        item = {
            "id": question["id"],
            "type": "choice",
            "text": question["stem_ru"],
            "options": question["options"],
            "correct_answer": question["correct_answer_index"],
            "difficulty": difficulty,
            "explanation": append_explanation(question, animal=animal),
        }
        assert tuple(item) == ALLOWED_LEGACY_FIELDS
        assert len(item["options"]) == len(set(item["options"])) == 4
        assert 0 <= item["correct_answer"] < 4 and isinstance(item["difficulty"], int)
        result.append(item)
    return result


def planned_pack(name: str) -> tuple[dict[str, Any], list[dict[str, Any]], dict[str, Any], dict[str, Any]]:
    spec = PACKS[name]
    source_bytes, source = load_json(spec["source"])
    draft_bytes, draft = load_json(spec["draft"])
    assert digest(draft_bytes) == spec["draft_sha256"]
    receipt = require_receipt(spec, digest(draft_bytes))
    base = pinned_source(spec["source"])
    assert source == base and source["id"] == spec["source_id"]
    old = source["questions"]
    new = additions(name, draft)
    assert len(old) == spec["prefix_count"] and len(old) + len(new) == 20
    assert len({question["id"] for question in old + new}) == 20
    result = dict(source)
    result["description"] = spec["description"]
    result["questions"] = old + new
    assert result["questions"][:len(old)] == base["questions"]
    return source, new, result, receipt


def final_pack(name: str) -> tuple[dict[str, Any], list[dict[str, Any]], dict[str, Any]]:
    spec = PACKS[name]
    _, source = load_json(spec["source"])
    draft_bytes, draft = load_json(spec["draft"])
    assert digest(draft_bytes) == spec["draft_sha256"]
    receipt = require_receipt(spec, digest(draft_bytes))
    base = pinned_source(spec["source"])
    new = additions(name, draft)
    assert source["id"] == spec["source_id"] and len(source["questions"]) == 20
    assert source["questions"][:spec["prefix_count"]] == base["questions"]
    assert source["questions"][spec["prefix_count"]:] == new
    assert source["description"] == spec["description"]
    assert {key: value for key, value in source.items() if key not in {"description", "questions"}} == {
        key: value for key, value in base.items() if key not in {"description", "questions"}
    }
    return source, new, receipt


def atomic_json(path: Path, value: Any) -> None:
    data = (json.dumps(value, ensure_ascii=False, indent=2) + "\n").encode("utf-8")
    with tempfile.NamedTemporaryFile("wb", dir=path.parent, delete=False) as temporary:
        temporary.write(data)
        temporary.flush()
        os.fsync(temporary.fileno())
        temporary_path = Path(temporary.name)
    temporary_path.replace(path)


def canonical_evidence(name: str, source: dict[str, Any], new: list[dict[str, Any]]) -> dict[str, Any]:
    spec = PACKS[name]
    _, draft = load_json(spec["canonical"] / "draft.json")
    _, manifest = load_json(spec["canonical"] / "manifest.json")
    _, bundle = load_json(spec["canonical"] / "bundle.json")
    expected_source = (json.dumps(source, ensure_ascii=False, indent=2) + "\n").encode("utf-8")
    canonical_ids = [question["question_id"] for question in draft["questions"]]
    assert len(canonical_ids) == 20 and len(set(canonical_ids)) == 20
    assert [question["canonical_id"] for question in manifest["questions"]] == canonical_ids
    public_questions = bundle["quiz"]["questions"]
    assert [question["question_id"] for question in public_questions] == canonical_ids
    assert canonical_ids[-len(new):] == [question["id"] for question in new]
    assert bundle["bundle_version"] == VERSION and bundle["published_at"] == PUBLISHED_AT
    assert manifest["source_sha256"] == normalized_lf_digest(expected_source)
    grading = bundle["private_grading"]
    assert set(grading) == set(canonical_ids)
    for question in new:
        assert grading[question["id"]]["correct_option_id"] == f"{question['id']}-opt-{question['correct_answer'] + 1}"
    assert all("grading" not in question and "correct_answer" not in question for question in public_questions)
    return {
        "source_sha256": manifest["source_sha256"],
        "bundle_sha256": bundle["bundle_sha256"],
        "draft_questions": len(draft["questions"]),
        "manifest_questions": len(manifest["questions"]),
        "bundle_questions": len(public_questions),
        "private_grading_questions": len(grading),
        "private_grading_verified_for_new_ids": [question["id"] for question in new],
        "public_bundle_has_no_grading": True,
    }


def plan() -> dict[str, Any]:
    packs: dict[str, Any] = {}
    for name, spec in PACKS.items():
        source, new, result, receipt = planned_pack(name)
        packs[name] = {
            "source": spec["source"].relative_to(ROOT).as_posix(),
            "pinned_source_sha256_lf": spec["base_sha256"],
            "source_baseline_guard": "parsed_deep_equal_to_pinned",
            "accepted_draft_sha256": spec["draft_sha256"],
            "reviewer": f"{receipt['reviewer_provider']}/{receipt['reviewer_model']}",
            "append_question_ids": [question["id"] for question in new],
            "question_count_before": len(source["questions"]),
            "question_count_after": len(result["questions"]),
            "legacy_fields_for_additions": list(ALLOWED_LEGACY_FIELDS),
        }
    return {"applied": False, "packs": packs}


def apply() -> dict[str, Any]:
    candidates = {name: planned_pack(name)[2] for name in PACKS}
    for name, candidate in candidates.items():
        atomic_json(PACKS[name]["source"], candidate)
    return {"applied": True, "packs": {name: 20 for name in PACKS}}


def write_evidence() -> dict[str, Any]:
    packs: dict[str, Any] = {}
    for name, spec in PACKS.items():
        source, new, receipt = final_pack(name)
        packs[name] = {
            "source": spec["source"].relative_to(ROOT).as_posix(),
            "accepted_draft_sha256": spec["draft_sha256"],
            "review_receipt": {
                "decision": receipt["decision"], "reviewer_provider": receipt["reviewer_provider"],
                "reviewer_model": receipt["reviewer_model"], "conversation_id": receipt["conversation_id"],
            },
            "source_question_count": len(source["questions"]),
            "original_prefix_preserved": True,
            "legacy_addition_fields": list(ALLOWED_LEGACY_FIELDS),
            "canonical": canonical_evidence(name, source, new),
        }
    evidence = {"schema": "feedback43-minimum20-import-evidence/v1", "version": VERSION, "published_at": PUBLISHED_AT, "packs": packs}
    atomic_json(TASK_DIR / "import18-evidence.json", evidence)
    return evidence


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--apply", action="store_true")
    parser.add_argument("--write-evidence", action="store_true")
    args = parser.parse_args()
    assert not (args.apply and args.write_evidence), "apply first; regenerate with quizctl; then write evidence"
    if args.apply:
        print(json.dumps(apply(), ensure_ascii=False, sort_keys=True))
    elif args.write_evidence:
        evidence = write_evidence()
        print(json.dumps({"evidence_written": True, "packs": {name: 20 for name in evidence["packs"]}}, ensure_ascii=False, sort_keys=True))
    else:
        print(json.dumps(plan(), ensure_ascii=False, sort_keys=True))


if __name__ == "__main__":
    main()
