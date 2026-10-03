"""Minimal offline contract/parity check for the unpublished flags pilot."""
import json
import re
from collections import Counter
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
assert len(questions) == 20
assert len({q["id"] for q in questions}) == 20
assert Counter(q["correct_answer"] for q in questions) == Counter({0: 5, 1: 5, 2: 5, 3: 5})
assert [q["correct_answer"] for q in questions] != [0, 1, 2, 3] * 5
for q in questions:
    assert set(q) == {"id", "type", "difficulty", "text", "options", "correct_answer", "explanation", "media"}
    assert q["type"] == "choice" and isinstance(q["text"], str) and q["text"].strip()
    assert len(q["options"]) == 4
    assert 0 <= q["correct_answer"] < 4
    assert 1 <= q["difficulty"] <= 10
    assert len(q["media"]) == 1
    assert set(q["media"][0]) == {"uri", "kind", "alt"}
    assert q["media"][0]["uri"].startswith("https://quiz.kotopedia.org/flags/")
    assert q["media"][0]["kind"] == "image" and q["media"][0]["alt"] == "Флаг страны"
    words = len(q["explanation"].split())
    assert 20 <= words <= 45, (q["id"], words)
    block = candidate.split("## " + q["id"], 1)[1].split("\n## ", 1)[0]
    shown = [line[3:].rstrip() for line in re.findall(r"^[A-D]\. .+$", block, re.M)]
    assert shown == q["options"], q["id"]
    letter = "ABCD"[q["correct_answer"]]
    assert f"| {q['id']} | {letter}. {q['options'][q['correct_answer']]} |" in key
    assert re.search(rf"\| [A-Z]{{2}} \| {q['id']} \| {letter} \|", coverage)
print("OK: LegacyImport fields, 20 image questions, 4 options, 5/5/5/5, explanations 20–45 words")
