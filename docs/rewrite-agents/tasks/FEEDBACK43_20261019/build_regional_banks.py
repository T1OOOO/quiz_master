#!/usr/bin/env python3
"""Build the eight regional geography packs from the reviewed world banks.

The script deliberately copies each source question verbatim and changes only
its identifier.  Country assignment comes from the checked-in Russian country
facts; aliases below are the reviewed labels used by the existing question
banks, not fuzzy matching rules.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
from collections import Counter
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[4]
FACTS_PATH = ROOT / "next/apps/quiz_app/assets/quizipedia/country_facts.json"
OUTPUT_DIR = ROOT / "quizzes/Preparation/GeographyRegions"
REPORT_PATH = ROOT / "docs/rewrite-agents/tasks/FEEDBACK43_20261019/regional-banks.md"

SOURCES = {
    "capitals": {
        "path": ROOT / "quizzes/Preparation/prep_capitals_world.json",
        "sha256": "7dcb15b820f18649a5d8fbc7adebac18fdff1dfda49fba70fe8d0e15fa891ccd",
        "category": "География/Столицы",
        "titles": {
            "europe": "Столицы Европы",
            "africa": "Столицы Африки",
            "americas": "Столицы Америк",
            "asia-oceania": "Столицы Азии и Океании",
        },
        "description": "Региональная тренировка столиц: вопросы сохранены из полного мирового набора.",
    },
    "flags": {
        "path": ROOT / "quizzes/Preparation/prep_flags_world.json",
        "sha256": "6c6c64597a3c8f09767de3c228ce6ac54e285574ca6f07cfcaca8c61017e247c",
        "category": "География/Флаги",
        "titles": {
            "europe": "Флаги Европы",
            "africa": "Флаги Африки",
            "americas": "Флаги Америк",
            "asia-oceania": "Флаги Азии и Океании",
        },
        "description": "Региональная тренировка флагов: вопросы сохранены из полного мирового набора.",
    },
}

REGIONS = ("europe", "africa", "americas", "asia-oceania")

# Existing source labels whose spelling, grammatical form, or official long
# name differs from country_facts.json.  Values are ISO identifiers from that
# file so a typo cannot silently map to a similarly named country.
ALIASES_TO_ID = {
    "Бенина": "BJ",
    "Боливии": "BO",
    "Боливия (Многонациональное Государство)": "BO",
    "Бруней-Даруссалам": "BN",
    "Венесуэла (Боливарианская Республика)": "VE",
    "Государство Палестина": "PS",
    "Иран (Исламская Республика)": "IR",
    "Коморские Острова": "KM",
    "Конго": "CG",
    "Корейская Народно-Демократическая Республика": "KP",
    "Кот-д'Ивуар": "CI",
    "Кыргызстан": "KG",
    "Лаосская Народно-Демократическая Республика": "LA",
    "Малайзии, в отличие от административного центра Путраджаи": "MY",
    "Мальдивские Острова": "MV",
    "Микронезия (Федеративные Штаты)": "FM",
    "Наоэро": "NR",
    "Нидерланды (Королевство)": "NL",
    "Нидерландов": "NL",
    "Объединенная Республика Танзания": "TZ",
    "Объединенные Арабские Эмираты": "AE",
    "Папуа-Новая Гвинея": "PG",
    "Республика Корея": "KR",
    "Республика Молдова": "MD",
    "Российская Федерация": "RU",
    "Святой Престол": "VA",
    "Соединенное Королевство Великобритании и Северной Ирландии": "GB",
    "Соединенные Штаты Америки": "US",
    "Сирийская Арабская Республика": "SY",
    "Тимор-Лешти": "TL",
    "Туркменистан": "TM",
    "Шри-Ланки": "LK",
    "Эсватини": "SZ",
    "ЮАР": "ZA",
    "Южная Африка": "ZA",
}

# These prompts identify a country narratively rather than as the exact final
# country phrase used in the ordinary capital question template.
CAPITAL_COUNTRY_BY_QUESTION_ID = {
    "capw-2c7f4f0daa00": "ID",
    "capw-2da190108433": "VA",
    "capw-2f9fffe9436e": "KI",
    "capw-90d24ab619e2": "LK",
    "capw-9717fc313859": "IL",
    "capw-bd7de16c1e75": "CH",
    "capw-d2c57322d420": "PS",
    "capw-e0a1b4cf9b43": "NR",
    "capw-e7619898e7df": "PW",
    "capw-168034fcef88": "SZ",
    "capw-19110ba5826e": "MY",
    "capw-70a5001ca0f3": "ZA",
}


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def read_json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def canonical_json(value: Any) -> bytes:
    return (json.dumps(value, ensure_ascii=False, indent=2) + "\n").encode("utf-8")


def source_country_label(question: dict[str, Any]) -> str:
    text = question["text"]
    quoted = re.search(r"государства «([^»]+)»", text)
    if quoted:
        return quoted.group(1).strip()
    country = re.search(r"столицей ([^?]+)\?", text)
    if country:
        return country.group(1).strip()
    raise ValueError(f"capital prompt has no strict country label: {question['id']}")


def regional_key(country: dict[str, Any]) -> str:
    region = country["region"]
    if region in {"Asia", "Oceania"}:
        return "asia-oceania"
    if region in {"Europe", "Africa", "Americas"}:
        return region.lower()
    raise ValueError(f"unsupported region {region!r} for {country['id']}")


def resolve_country(label: str, by_name: dict[str, dict[str, Any]], by_id: dict[str, dict[str, Any]]) -> dict[str, Any]:
    if label in by_name:
        return by_name[label]
    alias_id = ALIASES_TO_ID.get(label)
    if alias_id and alias_id in by_id:
        return by_id[alias_id]
    raise ValueError(f"unmapped country label: {label!r}")


def country_for_question(kind: str, question: dict[str, Any], by_name: dict[str, dict[str, Any]], by_id: dict[str, dict[str, Any]]) -> dict[str, Any]:
    if kind == "flags":
        answer = question.get("correct_answer")
        options = question.get("options")
        if not isinstance(answer, int) or not isinstance(options, list) or answer < 0 or answer >= len(options):
            raise ValueError(f"invalid flag answer index in {question.get('id')}")
        return resolve_country(options[answer], by_name, by_id)
    if question["id"] in CAPITAL_COUNTRY_BY_QUESTION_ID:
        return by_id[CAPITAL_COUNTRY_BY_QUESTION_ID[question["id"]]]
    return resolve_country(source_country_label(question), by_name, by_id)


def generated_packs() -> tuple[dict[Path, bytes], dict[str, Any]]:
    facts = read_json(FACTS_PATH)["countries"]
    by_name = {country["name_ru"]: country for country in facts}
    by_id = {country["id"]: country for country in facts}
    if len(by_name) != len(facts) or len(by_id) != len(facts):
        raise ValueError("country facts do not have unique Russian names and ISO identifiers")

    outputs: dict[Path, bytes] = {}
    evidence: dict[str, Any] = {"sources": {}, "packs": {}, "aliases": {}}
    for kind, spec in SOURCES.items():
        source_bytes = spec["path"].read_bytes()
        if sha256(source_bytes) != spec["sha256"]:
            raise ValueError(f"reviewed source changed: {spec['path']}")
        source = json.loads(source_bytes)
        questions = source.get("questions")
        if not isinstance(questions, list) or len(questions) != 195:
            raise ValueError(f"{spec['path']} must contain exactly 195 questions")
        partitions = {region: [] for region in REGIONS}
        source_ids: set[str] = set()
        country_ids: set[str] = set()
        for question in questions:
            source_id = question.get("id")
            if not isinstance(source_id, str) or source_id in source_ids:
                raise ValueError(f"duplicate or missing source question id: {source_id!r}")
            source_ids.add(source_id)
            country = country_for_question(kind, question, by_name, by_id)
            country_ids.add(country["id"])
            region = regional_key(country)
            derived = dict(question)
            derived["id"] = f"{kind}-{region}-{source_id}"
            partitions[region].append(derived)

        if len(country_ids) != 195:
            raise ValueError(f"{kind} does not identify 195 distinct countries")
        evidence["sources"][kind] = {"sha256": sha256(source_bytes), "questions": len(questions)}
        for region in REGIONS:
            derived_questions = partitions[region]
            if len(derived_questions) < 20:
                raise ValueError(f"{kind}/{region} is too small: {len(derived_questions)}")
            payload = {
                "id": f"prep-{kind}-{region}",
                "title": spec["titles"][region],
                "description": spec["description"],
                "category": spec["category"],
                "questions": derived_questions,
            }
            target = OUTPUT_DIR / f"prep_{kind}_{region}.json"
            encoded = canonical_json(payload)
            outputs[target] = encoded
            evidence["packs"][f"{kind}/{region}"] = {
                "questions": len(derived_questions),
                "sha256": sha256(encoded),
            }

    for label, country_id in sorted(ALIASES_TO_ID.items()):
        country = by_id.get(country_id)
        if country is None:
            raise ValueError(f"alias {label!r} points at missing country {country_id!r}")
        evidence["aliases"][label] = {"country_id": country_id, "region": regional_key(country)}
    return outputs, evidence


def report(evidence: dict[str, Any]) -> bytes:
    lines = [
        "# Региональные банки географии",
        "",
        "Скрипт делит два проверенных мировых набора по данным `country_facts.json`. Он не меняет формулировки, варианты, правильные индексы, объяснения, сложность или медиа: у копии меняется только идентификатор вопроса.",
        "",
        "## Проверенные источники",
        "",
    ]
    for kind, source in evidence["sources"].items():
        lines.append(f"- `{kind}`: {source['questions']} вопросов, SHA-256 `{source['sha256']}`")
    lines.extend(["", "## Получившиеся наборы", ""])
    for name, pack in evidence["packs"].items():
        lines.append(f"- `{name}`: {pack['questions']} вопросов, SHA-256 `{pack['sha256']}`")
    lines.extend(["", "## Явные варианты русских названий", "", "Это точные метки из исходных вопросов; сопоставление не использует нестрогое совпадение.", ""])
    for label, mapping in evidence["aliases"].items():
        lines.append(f"- `{label}` → `{mapping['country_id']}` ({mapping['region']})")
    lines.append("")
    return "\n".join(lines).encode("utf-8")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true", help="fail if generated files differ from this script")
    args = parser.parse_args()
    outputs, evidence = generated_packs()
    expected_report = report(evidence)
    expected = {**outputs, REPORT_PATH: expected_report}
    if args.check:
        stale = [str(path.relative_to(ROOT)) for path, value in expected.items() if not path.is_file() or path.read_bytes() != value]
        if stale:
            raise SystemExit("generated files are missing or stale: " + ", ".join(stale))
        return
    for path, value in expected.items():
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(value)
    print("generated", ", ".join(str(path.relative_to(ROOT)) for path in expected))


if __name__ == "__main__":
    main()
