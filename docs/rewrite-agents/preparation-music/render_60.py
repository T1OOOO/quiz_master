"""Render the completed music-60 draft from frozen pilot JSON and checkpoints.

Default --check is read-only. --render is the sole writing operation and is
allowed only after the one-time accepted-ten snapshot has been created.
"""
import argparse
import json
import re
from pathlib import Path

ROOT = Path(__file__).parent
PILOT_FILES = ("legacy-musicals.json", "legacy-ballet.json", "legacy-opera.json")
SNAPSHOT = ROOT / "accepted10-current60-snapshot.json"
LETTERS = "АБВГ"

def load_checkpoint_questions():
    records = []
    for path in sorted(ROOT.glob("checkpoint-*.md")):
        text = path.read_text(encoding="utf-8")
        pattern = re.compile(
            r"^## (music-oct3-(\d{3})) · .+ · intended ([АБВГ])\n\n"
            r"(.+?)\n\nА\. (.+?); Б\. (.+?); В\. (.+?); Г\. (.+?)\.\n\n"
            r"\*\*Объяснение \(\d+ слов(?:о|а)?\):\*\* (.+?)\n\nИсточник: (.+)",
            re.M | re.S,
        )
        for block in re.split(r"\n(?=## )", text):
            match = pattern.search(block)
            if not match:
                continue
            ident, number, letter, question, a, b, c, d, explanation, source = match.groups()
            records.append({"id": ident, "number": int(number), "type": "choice", "text": question,
                            "options": [a, b, c, d], "correct_answer": LETTERS.index(letter),
                            "difficulty": 4, "explanation": explanation, "source": source})
    return sorted(records, key=lambda item: item["number"])

def pilot_questions():
    items = []
    for name in PILOT_FILES:
        items.extend(item for item in json.loads((ROOT / name).read_text(encoding="utf-8"))["questions"]
                     if int(item["id"].rsplit("-", 1)[1]) <= 10)
    return sorted(items, key=lambda item: int(item["id"].rsplit("-", 1)[1]))

def snapshot_if_missing(pilot, create):
    if SNAPSHOT.exists():
        return json.loads(SNAPSHOT.read_text(encoding="utf-8"))
    if not create:
        raise SystemExit("CHECK MISMATCH: accepted-ten snapshot has not been created")
    payload = {"purpose": "accepted ten frozen before music-60 render", "questions": pilot}
    with SNAPSHOT.open("x", encoding="utf-8") as handle:
        json.dump(payload, handle, ensure_ascii=False, indent=2)
        handle.write("\n")
    return payload

def all_questions(create_snapshot):
    pilot = pilot_questions()
    snapshot = snapshot_if_missing(pilot, create_snapshot)
    assert snapshot["questions"] == pilot
    added = load_checkpoint_questions()
    assert [item["number"] for item in added] == list(range(11, 61))
    return pilot + added

def category(number):
    if number <= 3 or 11 <= number <= 27:
        return "Мюзиклы"
    if number <= 6 or 28 <= number <= 44:
        return "Балет"
    return "Опера"

def pack(name, title, description, questions):
    clean = [{key: item[key] for key in ("id", "type", "text", "options", "correct_answer", "difficulty", "explanation")} for item in questions]
    return json.dumps({"id": name, "title": title, "description": description, "category": f"Музыка/{title.rsplit(' — ', 1)[-1]}", "questions": clean}, ensure_ascii=False, indent=2) + "\n"

def candidate(questions):
    lines = ["# Музыка — полный черновик из 60 карточек", "", "Ответы и источники находятся только в редакционном ключе.", ""]
    for item in questions:
        lines += [f"### {item['id']}", item["text"]]
        lines += [f"{letter}. {option}" for letter, option in zip(LETTERS, item["options"])]
        lines.append("")
    return "\n".join(lines)

def key(questions):
    lines = ["# Редакционный ключ и источники — музыка 60", "", "Дата доступа к источникам: 2026-10-03.", ""]
    for item in questions:
        answer = item["options"][item["correct_answer"]]
        lines += [f"## {item['id']} — {LETTERS[item['correct_answer']]} · {answer}", "", f"**Полное объяснение:** {item['explanation']}", ""]
        if "source" in item:
            lines += [item["source"], ""]
        else:
            lines += ["Источник: сохранённая accepted-10 редакционная запись и source ledger.", ""]
    return "\n".join(lines)

def coverage(questions):
    rows = []
    for label in ("Мюзиклы", "Балет", "Опера"):
        subset = [item for item in questions if category(int(item["id"].rsplit("-", 1)[1])) == label]
        rows.append(f"| {label} | {len(subset)} |")
    return "\n".join(["# Покрытие музыки 60", "", "| Раздел | Количество |", "|---|---:|", *rows, "", "Итого: 60 вопросов; accepted 10 сохранены в отдельном snapshot.", ""])

def expected(create_snapshot):
    questions = all_questions(create_snapshot)
    assert len(questions) == len({item["id"] for item in questions}) == 60
    packs = {"legacy-musicals.json": [item for item in questions if category(int(item["id"].rsplit("-", 1)[1])) == "Мюзиклы"],
             "legacy-ballet.json": [item for item in questions if category(int(item["id"].rsplit("-", 1)[1])) == "Балет"],
             "legacy-opera.json": [item for item in questions if category(int(item["id"].rsplit("-", 1)[1])) == "Опера"]}
    return {"candidate.md": candidate(questions), "editorial-key.md": key(questions), "coverage.md": coverage(questions),
            "legacy-musicals.json": pack("prep-musicals", "Музыка: полный пакет — Мюзиклы", "20 вопросов о композиторах мюзиклов.", packs["legacy-musicals.json"]),
            "legacy-ballet.json": pack("prep-ballet", "Музыка: полный пакет — Балет", "20 вопросов о балетных партитурах.", packs["legacy-ballet.json"]),
            "legacy-opera.json": pack("prep-opera", "Музыка: полный пакет — Опера", "20 вопросов о композиторах опер.", packs["legacy-opera.json"])}

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--render", action="store_true")
    args = parser.parse_args()
    outputs = expected(args.render)
    if args.render:
        for name, text in outputs.items():
            (ROOT / name).write_text(text, encoding="utf-8")
        print("RENDERED: music 60")
    else:
        mismatches = [name for name, text in outputs.items() if not (ROOT / name).exists() or (ROOT / name).read_text(encoding="utf-8") != text]
        if mismatches:
            raise SystemExit("CHECK MISMATCH: " + ", ".join(mismatches))
        print("PASS: renderer check is read-only and all outputs match")

if __name__ == "__main__":
    main()
