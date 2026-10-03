"""Deterministic transcription of the lead's reviewed-by-author history draft.

No factual acceptance implied. Run to render; --check verifies saved artifacts.
"""
import json
import sys
from collections import Counter
from pathlib import Path

root = Path(__file__).resolve().parent
source = json.loads((root / "authoring20.json").read_text(encoding="utf-8-sig"))
rows = source["records"]
assert len(rows) == 20 and len({q["id"] for q in rows}) == 20
assert Counter(q["correct_answer"] for q in rows) == Counter({i: 5 for i in range(4)})
positions = [q["correct_answer"] for q in rows]
assert any(positions[i] != positions[i % 4] for i in range(4, len(rows)))
assert all(len(set(positions[i:i + 4])) > 1 for i in range(len(rows) - 3))
candidate = ["# События, которые изменили мир", "", "Черновик 20, не опубликован.", ""]
key = ["# История: закрытый редакторский ключ", "", "Независимый факт-review ещё требуется.", ""]
questions = []
for q in rows:
    assert len(q["options"]) == len(set(q["options"])) == 4
    assert type(q["correct_answer"]) is int and 0 <= q["correct_answer"] < 4
    assert type(q["difficulty"]) is int and 1 <= q["difficulty"] <= 10
    assert 20 <= len(q["explanation"].split()) <= 45, q["id"]
    assert q["sources"] and all(u.startswith("https://") for u in q["sources"])
    assert q["evidence"].strip()
    candidate += [f"## {q['id']}", "", q["text"], ""]
    candidate += [f"{letter}. {text}" for letter, text in zip("АБВГ", q["options"])] + [""]
    answer = q["correct_answer"]
    key += [f"## {q['id']}", "", q["text"], ""]
    key += [f"{letter}. {text}" for letter, text in zip("АБВГ", q["options"])]
    key += ["", f"Ответ: {'АБВГ'[answer]}. {q['options'][answer]}", "", q["explanation"], "",
            f"Доступ: {source['access_date']}", "", q["evidence"], ""]
    key += [f"Источник: {u}" for u in q["sources"]] + [""]
    questions.append({"id": q["id"], "type": "choice", **{k: q[k] for k in
                     ("text", "options", "correct_answer", "difficulty", "explanation")}})
legacy = {k: source[k] for k in ("id", "title", "description", "category")}
legacy["questions"] = questions
outputs = {"candidate.md": "\n".join(candidate), "editorial-key.md": "\n".join(key),
           "legacy.json": json.dumps(legacy, ensure_ascii=False, indent=2) + "\n"}
for name, expected in outputs.items():
    path = root / name
    if "--check" in sys.argv:
        assert path.read_text(encoding="utf-8-sig") == expected, name
    else:
        path.write_text(expected, encoding="utf-8")
print("PASS: history20; positions5each; unique4options; words20–45; full candidate/key/legacy parity")
