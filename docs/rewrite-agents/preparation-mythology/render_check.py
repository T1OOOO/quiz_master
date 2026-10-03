"""Reuse the history draft's deterministic transcription; no factual acceptance implied."""
import json
import sys
from collections import Counter
from pathlib import Path

root = Path(__file__).resolve().parent
prefix = "norse-" if "--norse" in sys.argv else ""
source = json.loads((root / f"{prefix}authoring20.json").read_text(encoding="utf-8-sig"))
rows = source["records"]
assert len(rows) == len({q["id"] for q in rows}) == 20
assert Counter(q["correct_answer"] for q in rows) == Counter({i: 5 for i in range(4)})
positions = [q["correct_answer"] for q in rows]
assert any(positions[i] != positions[i % 4] for i in range(4, len(rows)))
assert all(len(set(positions[i:i + 4])) > 1 for i in range(len(rows) - 3))
candidate = [f"# {source['title']}", "", "Черновик 20, не опубликован.", ""]
key = [f"# {source['title']}: закрытый редакторский ключ", "", "Независимый факт-review ещё требуется.", ""]
questions = []
for q in rows:
    assert len(q["options"]) == len(set(q["options"])) == 4
    assert type(q["correct_answer"]) is int and 0 <= q["correct_answer"] < 4
    assert type(q["difficulty"]) is int and 1 <= q["difficulty"] <= 10
    assert 20 <= len(q["explanation"].split()) <= 45, q["id"]
    assert q["sources"] and all(u.startswith("https://") for u in q["sources"])
    assert q["evidence"].strip()
    variants = [f"{letter}. {text}" for letter, text in zip("АБВГ", q["options"])]
    candidate += [f"## {q['id']}", "", q["text"], ""] + variants + [""]
    answer = q["correct_answer"]
    key += [f"## {q['id']}", "", q["text"], ""] + variants
    key += ["", f"Ответ: {'АБВГ'[answer]}. {q['options'][answer]}", "", q["explanation"], "",
            f"Доступ: {source['access_date']}", "", q["evidence"], ""]
    key += [f"Источник: {u}" for u in q["sources"]] + [""]
    questions.append({"id": q["id"], "type": "choice", **{k: q[k] for k in
                     ("text", "options", "correct_answer", "difficulty", "explanation")}})
legacy = {k: source[k] for k in ("id", "title", "description", "category")}
legacy["questions"] = questions
outputs = {f"{prefix}candidate.md": "\n".join(candidate), f"{prefix}editorial-key.md": "\n".join(key),
           f"{prefix}legacy.json": json.dumps(legacy, ensure_ascii=False, indent=2) + "\n"}
for name, expected in outputs.items():
    path = root / name
    if "--check" in sys.argv:
        assert path.read_text(encoding="utf-8-sig") == expected, name
    else:
        path.write_text(expected, encoding="utf-8")
print(f"PASS: {source['id']}; balanced5each; unique4options; words20–45; candidate/key/legacy parity")
