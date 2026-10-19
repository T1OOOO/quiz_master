"""Fail-closed import of two independently accepted Feedback 43 additions.

The default invocation validates the exact baseline and accepted drafts without
writing.  ``--apply`` is deliberately required to append the ten reviewed
questions to each legacy pack.  ``--write-evidence`` is a separate final
read/verification pass after quizctl has regenerated the controlled artifacts.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import tempfile
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[4]
TASK_DIR = Path(__file__).resolve().parent
ALLOWED_LEGACY_FIELDS = (
    "id",
    "type",
    "text",
    "options",
    "correct_answer",
    "difficulty",
    "explanation",
)
VERSION = "2026.10.19.minimum20"
PUBLISHED_AT = "2026-10-19T00:00:00Z"

PACKS: dict[str, dict[str, Any]] = {
    "planets": {
        "source": ROOT / "quizzes/Science/planet_paradoxes_20261010.json",
        "draft": ROOT / "study/drafts/feedback43-planets-extra-20261019.json",
        "acceptance": TASK_DIR / "planets-acceptance.json",
        "canonical": ROOT / "next/content/planet-paradoxes-20261010",
        "source_id": "planet-paradoxes-20261010",
        "draft_sha256": "34d70d4c755a7598c4ca7428e3c51a5d39b3e048a74d683b879ead8024468b54",
        "base_sha256": "611486b239a15310f6242295bd794983048c90dc16d9ab262440b58c5aedfe59",
        "prefix_count": 10,
        "description": "20 вопросов о времени, погоде, составе и необычных явлениях планет. Учимся различать понятия, а не только запоминать названия.",
    },
    "games": {
        "source": ROOT / "quizzes/Cinema/Thematic80/game_worlds.json",
        "draft": ROOT / "study/drafts/feedback43-games-extra-20261019.json",
        "acceptance": TASK_DIR / "games-acceptance.json",
        "canonical": ROOT / "next/content/theme-game-worlds",
        "source_id": "theme-game-worlds",
        "draft_sha256": "5b1f1474f1dd8d087c1442d60858be0e3074ef30759076fafddf8e1017cc89df",
        "base_sha256": "6ecc0efc0d326f24ca19d7a41625b123d6735ea32942e6ccebba40b016990e2f",
        "prefix_count": 10,
        "description": "20 вопросов по конкретным играм Nintendo и Pokémon; механики относятся к указанным частям.",
    },
}


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def normalized_lf_sha256(data: bytes) -> str:
    return sha256(data.replace(b"\r\n", b"\n").replace(b"\r", b"\n"))


def load_json(path: Path) -> tuple[bytes, dict[str, Any]]:
    data = path.read_bytes()
    return data, json.loads(data)


def require_acceptance(spec: dict[str, Any], draft_digest: str) -> dict[str, Any]:
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


def append_rationales(explanation: str, options: list[str], answer: int, rationales: list[str]) -> str:
    assert len(options) == 4 and len(rationales) == 3 and 0 <= answer < 4
    wrong = [index for index in range(4) if index != answer]
    rendered = [f"{options[index]}: {reason}" for index, reason in zip(wrong, rationales, strict=True)]
    return explanation + " Другие варианты: " + "; ".join(rendered)


def additions_for_planets(draft: dict[str, Any]) -> list[dict[str, Any]]:
    assert draft["draft_id"] == "feedback43-planets-extra-20261019"
    additions: list[dict[str, Any]] = []
    for question in draft["questions"]:
        answer = question["correct_answer_index"]
        difficulty = {"easy": 3, "medium": 4}[question["estimated_difficulty"]]
        item = {
            "id": question["id"],
            "type": "choice",
            "text": question["stem_ru"],
            "options": question["options"],
            "correct_answer": answer,
            "difficulty": difficulty,
            "explanation": append_rationales(
                question["explanation_ru"], question["options"], answer, question["distractor_rationales_ru"]
            ),
        }
        assert tuple(item) == ALLOWED_LEGACY_FIELDS
        additions.append(item)
    return additions


def additions_for_games(draft: dict[str, Any]) -> list[dict[str, Any]]:
    assert draft["draft_id"] == "feedback43-games-extra-20261019"
    additions: list[dict[str, Any]] = []
    for question in draft["questions"]:
        answer = question["correct_answer"]
        wrong = [index for index in range(4) if index != answer]
        rationale_map = question["distractor_rationales"]
        rationales = [rationale_map["abcd"[index]] for index in wrong]
        item = {
            "id": question["id"],
            "type": "choice",
            "text": question["text"],
            "options": question["options"],
            "correct_answer": answer,
            "difficulty": {"лёгкий": 3, "средний": 4}[question["difficulty"]],
            "explanation": append_rationales(question["explanation"], question["options"], answer, rationales),
        }
        assert tuple(item) == ALLOWED_LEGACY_FIELDS
        additions.append(item)
    return additions


def planned_pack(name: str) -> tuple[dict[str, Any], list[dict[str, Any]], dict[str, Any], dict[str, Any]]:
    spec = PACKS[name]
    source_bytes, source = load_json(spec["source"])
    draft_bytes, draft = load_json(spec["draft"])
    assert normalized_lf_sha256(source_bytes) == spec["base_sha256"]
    assert sha256(draft_bytes) == spec["draft_sha256"]
    receipt = require_acceptance(spec, sha256(draft_bytes))
    additions = additions_for_planets(draft) if name == "planets" else additions_for_games(draft)
    old = source["questions"]
    assert source["id"] == spec["source_id"]
    assert len(old) == spec["prefix_count"] == 10 and len(additions) == 10
    assert len({question["id"] for question in old + additions}) == 20
    for question in additions:
        assert tuple(question) == ALLOWED_LEGACY_FIELDS
        assert question["type"] == "choice" and len(question["options"]) == 4
        assert len(set(question["options"])) == 4
        assert 0 <= question["correct_answer"] < 4
        assert question["difficulty"] in {3, 4}
    if name == "games":
        assert all("difficulty" not in question for question in old)
    result = dict(source)
    result["description"] = spec["description"]
    result["questions"] = old + additions
    assert result["questions"][:10] == old
    assert len(result["questions"]) == 20
    return source, additions, result, receipt


def final_pack(name: str) -> tuple[dict[str, Any], list[dict[str, Any]], dict[str, Any]]:
    spec = PACKS[name]
    _, source = load_json(spec["source"])
    draft_bytes, draft = load_json(spec["draft"])
    assert sha256(draft_bytes) == spec["draft_sha256"]
    receipt = require_acceptance(spec, sha256(draft_bytes))
    additions = additions_for_planets(draft) if name == "planets" else additions_for_games(draft)
    assert source["id"] == spec["source_id"]
    assert len(source["questions"]) == 20
    assert source["questions"][10:] == additions
    assert source["description"] == spec["description"]
    if name == "games":
        assert all("difficulty" not in question for question in source["questions"][:10])
    return source, additions, receipt


def atomic_json(path: Path, value: Any) -> None:
    encoded = (json.dumps(value, ensure_ascii=False, indent=2) + "\n").encode("utf-8")
    with tempfile.NamedTemporaryFile("wb", dir=path.parent, delete=False) as temporary:
        temporary.write(encoded)
        temporary.flush()
        os.fsync(temporary.fileno())
        temp_path = Path(temporary.name)
    temp_path.replace(path)


def canonical_evidence(name: str, source: dict[str, Any], additions: list[dict[str, Any]]) -> dict[str, Any]:
    spec = PACKS[name]
    draft_bytes = json.dumps(source, ensure_ascii=False, indent=2).encode("utf-8") + b"\n"
    artifact_dir = spec["canonical"]
    _, draft = load_json(artifact_dir / "draft.json")
    _, manifest = load_json(artifact_dir / "manifest.json")
    _, bundle = load_json(artifact_dir / "bundle.json")
    expected_ids = [question["id"] for question in source["questions"]]
    assert [question["question_id"] for question in draft["questions"]] == expected_ids
    assert [question["canonical_id"] for question in manifest["questions"]] == expected_ids
    assert [question["question_id"] for question in bundle["quiz"]["questions"]] == expected_ids
    assert manifest["source_sha256"] == normalized_lf_sha256(draft_bytes)
    assert bundle["bundle_version"] == VERSION and bundle["published_at"] == PUBLISHED_AT
    grading = bundle["private_grading"]
    assert set(grading) == set(expected_ids)
    for question in additions:
        expected = f"{question['id']}-opt-{question['correct_answer'] + 1}"
        assert grading[question["id"]]["correct_option_id"] == expected
    public_questions = bundle["quiz"]["questions"]
    assert all("grading" not in question and "correct_answer" not in question for question in public_questions)
    return {
        "source_sha256": manifest["source_sha256"],
        "bundle_sha256": bundle["bundle_sha256"],
        "draft_questions": len(draft["questions"]),
        "manifest_questions": len(manifest["questions"]),
        "bundle_questions": len(public_questions),
        "private_grading_questions": len(grading),
        "private_grading_verified_for_new_ids": [question["id"] for question in additions],
        "public_bundle_has_no_grading": True,
    }


def plan() -> dict[str, Any]:
    packs: dict[str, Any] = {}
    for name in PACKS:
        source, additions, result, receipt = planned_pack(name)
        packs[name] = {
            "source": str(PACKS[name]["source"].relative_to(ROOT)).replace("\\", "/"),
            "source_base_sha256_lf": PACKS[name]["base_sha256"],
            "accepted_draft_sha256": PACKS[name]["draft_sha256"],
            "reviewer": f"{receipt['reviewer_provider']}/{receipt['reviewer_model']}",
            "append_question_ids": [question["id"] for question in additions],
            "question_count_before": len(source["questions"]),
            "question_count_after": len(result["questions"]),
            "legacy_fields_for_additions": list(ALLOWED_LEGACY_FIELDS),
        }
    return {"applied": False, "packs": packs}


def apply() -> dict[str, Any]:
    candidates: dict[str, dict[str, Any]] = {}
    for name in PACKS:
        _, _, candidates[name], _ = planned_pack(name)
    for name, result in candidates.items():
        atomic_json(PACKS[name]["source"], result)
    return {"applied": True, "packs": {name: 20 for name in PACKS}}


def write_evidence() -> dict[str, Any]:
    packs: dict[str, Any] = {}
    for name in PACKS:
        source, additions, receipt = final_pack(name)
        packs[name] = {
            "source": str(PACKS[name]["source"].relative_to(ROOT)).replace("\\", "/"),
            "accepted_draft_sha256": PACKS[name]["draft_sha256"],
            "review_receipt": {
                "decision": receipt["decision"],
                "reviewer_provider": receipt["reviewer_provider"],
                "reviewer_model": receipt["reviewer_model"],
                "conversation_id": receipt["conversation_id"],
            },
            "source_question_count": len(source["questions"]),
            "original_prefix_preserved": True,
            "legacy_addition_fields": list(ALLOWED_LEGACY_FIELDS),
            "canonical": canonical_evidence(name, source, additions),
        }
    evidence = {
        "schema": "feedback43-minimum20-import-evidence/v1",
        "version": VERSION,
        "published_at": PUBLISHED_AT,
        "packs": packs,
    }
    atomic_json(TASK_DIR / "import20-evidence.json", evidence)
    return evidence


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--apply", action="store_true", help="append accepted additions after all guards pass")
    parser.add_argument("--write-evidence", action="store_true", help="verify regenerated canonical artifacts and write evidence")
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
