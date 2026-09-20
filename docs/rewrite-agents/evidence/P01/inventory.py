#!/usr/bin/env python3
"""Deterministically inventory every checked-in quiz JSON file."""

import collections
import hashlib
import json
import sys
from pathlib import Path


def count_key(counter, value):
    counter["<missing>" if value is None or value == "" else str(value)] += 1


def main():
    if len(sys.argv) != 2:
        raise SystemExit("usage: inventory.py QUIZZES_DIRECTORY")
    root = Path(sys.argv[1])
    files = sorted(path for path in root.rglob("*.json") if path.is_file())
    categories = collections.Counter()
    question_types = collections.Counter()
    option_counts = collections.Counter()
    correct_answer_fields = collections.Counter()
    correct_multi_fields = collections.Counter()
    question_ids = collections.defaultdict(list)
    quiz_ids = collections.defaultdict(list)
    malformed = []
    file_summary = []
    question_total = 0
    missing_difficulty = 0

    for path in files:
        rel = path.relative_to(root.parent).as_posix()
        try:
            raw = path.read_bytes()
        except OSError as error:
            malformed.append({"path": rel, "reason": f"unreadable: {error}"})
            continue
        try:
            quiz = json.loads(raw.decode("utf-8"))
        except (UnicodeDecodeError, json.JSONDecodeError) as error:
            malformed.append({"path": rel, "reason": f"malformed JSON: {error}"})
            continue
        if not isinstance(quiz, dict):
            malformed.append({"path": rel, "reason": "top-level JSON value is not an object"})
            continue
        questions = quiz.get("questions")
        if not isinstance(questions, list):
            malformed.append({"path": rel, "reason": "questions is missing or not an array"})
            continue

        quiz_id = quiz.get("id")
        category = quiz.get("category")
        quiz_ids[str(quiz_id) if quiz_id is not None else "<missing>"].append(rel)
        count_key(categories, category)
        file_summary.append({
            "path": rel,
            "quiz_id": quiz_id,
            "category": category,
            "question_count": len(questions),
            "sha256": hashlib.sha256(raw).hexdigest(),
        })
        for offset, question in enumerate(questions):
            question_total += 1
            if not isinstance(question, dict):
                malformed.append({"path": rel, "reason": f"question[{offset}] is not an object"})
                count_key(question_types, None)
                option_counts["<not-an-object>"] += 1
                missing_difficulty += 1
                continue
            question_id = question.get("id")
            question_ids[str(question_id) if question_id is not None else "<missing>"].append(
                f"{rel}#questions[{offset}]"
            )
            count_key(question_types, question.get("type"))
            options = question.get("options")
            option_counts[str(len(options)) if isinstance(options, list) else "<missing-or-not-array>"] += 1
            if question.get("difficulty") is None:
                missing_difficulty += 1
            if "correct_answer" in question:
                correct_answer_fields["correct_answer"] += 1
            if "correct_answer_index" in question:
                correct_answer_fields["correct_answer_index"] += 1
            if "correct_multi" not in question:
                correct_multi_fields["absent"] += 1
            elif question["correct_multi"] is None:
                correct_multi_fields["null"] += 1
            elif isinstance(question["correct_multi"], list) and not question["correct_multi"]:
                correct_multi_fields["empty-array"] += 1
            else:
                correct_multi_fields["nonempty"] += 1

    duplicate_questions = {
        key: locations for key, locations in sorted(question_ids.items()) if len(locations) > 1
    }
    duplicate_quizzes = {
        key: locations for key, locations in sorted(quiz_ids.items()) if len(locations) > 1
    }
    output = {
        "corpus_root": root.as_posix(),
        "files_total": len(files),
        "files_parsed": len(file_summary),
        "files_with_malformed_or_unreadable_content": len(
            {item["path"] for item in malformed}
        ),
        "questions_total": question_total,
        "category_distribution": dict(sorted(categories.items())),
        "question_type_distribution": dict(sorted(question_types.items())),
        "option_count_distribution": dict(sorted(option_counts.items(), key=lambda item: item[0])),
        "questions_missing_difficulty": missing_difficulty,
        "correct_answer_field_distribution": dict(sorted(correct_answer_fields.items())),
        "correct_multi_field_distribution": dict(sorted(correct_multi_fields.items())),
        "duplicate_question_ids": duplicate_questions,
        "duplicate_question_id_count": len(duplicate_questions),
        "duplicate_quiz_ids": duplicate_quizzes,
        "duplicate_quiz_id_count": len(duplicate_quizzes),
        "malformed_or_unreadable_inputs": malformed,
        "files": file_summary,
    }
    json.dump(output, sys.stdout, ensure_ascii=False, indent=2, sort_keys=True)
    sys.stdout.write("\n")


if __name__ == "__main__":
    main()
