"""Minimal offline contract/parity check for the unpublished flags pilot."""
import json
import re
from collections import Counter
from itertools import groupby
from pathlib import Path

ROOT = Path(__file__).parent
data = json.loads((ROOT / "legacy.json").read_text(encoding="utf-8"))
questions = data["questions"]
candidate = (ROOT / "candidate.md").read_text(encoding="utf-8")
key = (ROOT / "editorial-key.md").read_text(encoding="utf-8")
coverage = (ROOT / "coverage.md").read_text(encoding="utf-8")
assert set(data) == {"id", "title", "description", "category", "questions"}
assert all(isinstance(data[key], str) and data[key].strip() for key in data if key != "questions")
assert data["id"] == "prep-flags-world"
assert len(questions) == 195
assert len({q["id"] for q in questions}) == 195
assert Counter(q["correct_answer"] for q in questions) == Counter({0: 49, 1: 49, 2: 49, 3: 48})
assert [q["correct_answer"] for q in questions][80:] != [0, 1, 2, 3] * 15
for q in questions:
    assert set(q) == {"id", "type", "difficulty", "text", "options", "correct_answer", "explanation", "media"}
    assert q["type"] == "choice" and isinstance(q["text"], str) and q["text"].strip()
    assert len(q["options"]) == 4
    assert 0 <= q["correct_answer"] < 4
    assert 1 <= q["difficulty"] <= 10
    assert len(q["media"]) == 1
    assert set(q["media"][0]) == {"uri", "kind", "alt"}
    assert re.fullmatch(r"https://quiz\.kotopedia\.org/flags/[0-9a-f]{64}\.png", q["media"][0]["uri"])
    assert q["media"][0]["kind"] == "image" and q["media"][0]["alt"] == "Флаг страны"
    words = len(q["explanation"].split())
    assert 20 <= words <= 45, (q["id"], words)
    block = candidate.split("## " + q["id"], 1)[1].split("\n## ", 1)[0]
    shown = [line[3:].rstrip() for line in re.findall(r"^[A-D]\. .+$", block, re.M)]
    assert shown == q["options"], q["id"]
    letter = "ABCD"[q["correct_answer"]]
    assert f"| {q['id']} | {letter}. {q['options'][q['correct_answer']]} |" in key
    assert re.search(rf"\| [A-Z]{{2}} \| {q['id']} \| {letter} \|", coverage)
assert candidate.count("## flag-") == 195
coverage_rows = [line.split("|") for line in coverage.splitlines() if line.startswith("| ") and "flag-" in line]
assert len(coverage_rows) == 195
assert {row[2].strip() for row in coverage_rows} == {q["id"] for q in questions}
assert all(q["id"] in key for q in questions)
tail = questions[140:]
assert Counter(q["correct_answer"] for q in tail) == Counter({0: 14, 1: 14, 2: 14, 3: 13})
assert max(len(list(run)) for _, run in groupby(q["correct_answer"] for q in tail)) <= 3
wrong_sets = {tuple(sorted(q["options"][i] for i in range(4) if i != q["correct_answer"])) for q in tail}
assert len(wrong_sets) >= 40
wrong_uses = Counter(option for q in tail for i, option in enumerate(q["options"]) if i != q["correct_answer"])
assert max(wrong_uses.values()) <= 15
for q in questions:
    option_set = set(q["options"])
    assert not {"Индонезия", "Монако"} <= option_set, q["id"]
    assert not {"Люксембург", "Нидерланды (Королевство)"} <= option_set, q["id"]
    assert not {"Румыния", "Чад"} <= option_set, q["id"]
print("OK: LegacyImport fields, 195 image questions, 4 options, 49/49/49/48, explanations 20–45 words")
