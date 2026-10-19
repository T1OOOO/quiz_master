"""Guarded one-shot import of the independently accepted 206-bone atlas draft."""
from __future__ import annotations

import copy
import hashlib
import json
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
DRAFT_PATH = ROOT / "study/drafts/feedback43-bones206-20261019.json"
ATLAS_PATH = ROOT / "next/apps/quiz_app/assets/quizipedia/organ_atlas.json"
RECEIPT_PATH = Path(__file__).with_name("bones206-acceptance.json")
DRAFT_SHA256 = "4713544bfdca14db4e07ae37cd9e4910570fe40a7575dd8bbf95e65b42e27943"
BASE_ATLAS_SHA256 = "c0e6a77f9c00f7cf40c67e4d0241499433c20dcb180585eddb77bc9d9b718c07"
EXPECTED_PARENT_COUNTS = {
    "skeleton-skull": 22,
    "skeleton-auditory-hyoid": 7,
    "skeleton-vertebral-column": 26,
    "skeleton-thoracic-cage": 25,
    "skeleton-pectoral-girdle": 4,
    "skeleton-upper-limbs": 60,
    "skeleton-pelvic-girdle": 2,
    "skeleton-lower-limbs": 60,
}
FORBIDDEN_BONE_FIELDS = {"diagram_anchor", "bone_count", "name_la", "source_profile_id"}


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def source_ids_of(entity: dict) -> set[str]:
    ids = set(entity["source_ids"])
    for fact in entity["facts"]:
        ids.update(fact["source_ids"])
    return ids


def main() -> None:
    draft_bytes = DRAFT_PATH.read_bytes()
    assert sha256(draft_bytes) == DRAFT_SHA256, "draft SHA mismatch"
    receipt = json.loads(RECEIPT_PATH.read_text(encoding="utf-8"))
    assert receipt["decision"] == "ACCEPT EXACTDRAFT", "review is not an exact-draft acceptance"
    assert receipt["draft_sha256"] == DRAFT_SHA256, "receipt SHA mismatch"
    assert receipt["reviewer_provider"] == "google", "required independent Google receipt missing"

    original_bytes = ATLAS_PATH.read_bytes()
    assert sha256(original_bytes) == BASE_ATLAS_SHA256, "unexpected atlas base SHA"
    atlas = json.loads(original_bytes)
    assert atlas["schema_version"] == "qm-organ-atlas/v1"
    assert len(atlas["organs"]) == 75 and len(atlas["questions"]) == 47
    legacy_organs = copy.deepcopy(atlas["organs"])
    legacy_questions = copy.deepcopy(atlas["questions"])
    legacy_sources = copy.deepcopy(atlas["sources"])
    source_ids = {source["id"] for source in atlas["sources"]}

    draft = json.loads(draft_bytes)
    assert draft["schema_version"] == "qm-organ-atlas-bones206-draft/v1"
    assert draft["base_atlas"]["existing_structure_count"] == 75
    assert draft["expected_counts"] == {**EXPECTED_PARENT_COUNTS, "axial": 80, "appendicular": 126, "total": 206}
    bones = draft["bone_entities"]
    profiles = draft["source_profiles"]
    assert len(bones) == 206 and len({bone["id"] for bone in bones}) == 206
    assert {bone["source_profile_id"] for bone in bones} == set(profiles)
    assert not ({bone["id"] for bone in bones} & {entity["id"] for entity in legacy_organs})

    materialized: list[dict] = []
    for bone in bones:
        assert set(bone) == {
            "id", "name_ru", "name_en", "kind", "diagram_group", "system_ids", "region",
            "parent_group_id", "adult_convention", "source_profile_id",
        }
        assert bone["kind"] == "bone" and bone["diagram_group"] == "skeleton"
        assert bone["adult_convention"] == "adult_206_standard"
        profile = profiles[bone["source_profile_id"]]
        assert set(profile) == {"position_ru", "position_en", "function_ru", "function_en", "facts", "source_ids"}
        entity = {key: value for key, value in bone.items() if key != "source_profile_id"}
        entity.update(copy.deepcopy(profile))
        # OrganStructure.fromJson requires these ordinary organ-card fields even when a bone has no secretions or note.
        entity["secretions_ru"] = []
        entity["secretions_en"] = []
        entity["note_ru"] = ""
        entity["note_en"] = ""
        assert entity["secretions_ru"] == entity["secretions_en"] == []
        assert entity["note_ru"] == entity["note_en"] == ""
        assert not (FORBIDDEN_BONE_FIELDS & set(entity))
        assert source_ids_of(entity) <= source_ids, f"unknown source on {entity['id']}"
        materialized.append(entity)

    parent_counts = Counter(entity["parent_group_id"] for entity in materialized)
    assert dict(parent_counts) == EXPECTED_PARENT_COUNTS
    assert sum(parent_counts.values()) == 206
    assert sum(parent_counts[parent] for parent in ("skeleton-skull", "skeleton-auditory-hyoid", "skeleton-vertebral-column", "skeleton-thoracic-cage")) == 80
    assert sum(parent_counts[parent] for parent in ("skeleton-pectoral-girdle", "skeleton-upper-limbs", "skeleton-pelvic-girdle", "skeleton-lower-limbs")) == 126

    result = copy.deepcopy(atlas)
    result["organs"].extend(materialized)
    result["coverage_note_ru"] = (
        "281 учебная структура: крупные органы и железы, 8 групп скелета взрослого человека "
        "(206 костей, также представленных отдельными карточками) и 15 отделов мозга. Это обзор; "
        "мелкие железы, ядра и микроструктуры перечислены не исчерпывающе. Для парных групп число костей дано суммарно с обеих сторон."
    )
    result["coverage_note_en"] = (
        "281 learning structures: major organs and glands, 8 adult skeletal groups "
        "(206 bones, also represented by individual cards), and 15 brain regions. This overview is not an exhaustive "
        "list of small glands, nuclei or microscopic structures. Counts for paired groups include both sides."
    )

    assert result["organs"][:75] == legacy_organs
    assert result["questions"] == legacy_questions
    assert result["sources"] == legacy_sources
    assert len(result["organs"]) == 281 and len(result["questions"]) == 47 and len(result["sources"]) == 34
    imported = result["organs"][75:]
    assert len(imported) == 206 and all(entity["kind"] == "bone" for entity in imported)
    assert all(not (FORBIDDEN_BONE_FIELDS & set(entity)) for entity in imported)
    assert all(entity["secretions_ru"] == entity["secretions_en"] == [] for entity in imported)
    assert all(entity["note_ru"] == entity["note_en"] == "" for entity in imported)
    assert Counter(entity["parent_group_id"] for entity in imported) == EXPECTED_PARENT_COUNTS
    assert all(source_ids_of(entity) <= source_ids for entity in imported)

    ATLAS_PATH.write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8", newline="\n")
    print(json.dumps({
        "decision": "imported accepted exact draft",
        "draft_sha256": DRAFT_SHA256,
        "base_atlas_sha256": BASE_ATLAS_SHA256,
        "organs": 281,
        "imported_bones": 206,
        "questions": 47,
        "sources": 34,
        "parent_counts": dict(parent_counts),
        "coverage": {"structures": 281, "bones": 206, "skeletal_groups": 8, "brain_regions": 15},
    }, ensure_ascii=False, sort_keys=True))


if __name__ == "__main__":
    main()
