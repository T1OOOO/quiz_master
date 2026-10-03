"""Render a reconstituted 30 plus the bounded 30-question expansion."""
import argparse
import json
from pathlib import Path
import render_draft30 as draft30

ROOT = Path(__file__).parent
SNAPSHOT = json.loads((ROOT / "accepted30-reconstituted-snapshot.json").read_text(encoding="utf-8"))
CLASSIC = ("authoring-expansion-classic-05.json", "authoring-expansion-classic-10.json", "authoring-expansion-classic-15.json")
MODERN = ("authoring-expansion-modern-02.json", "authoring-expansion-modern-05.json", "authoring-expansion-modern-10.json", "authoring-expansion-modern-11.json", "authoring-expansion-modern-15.json")
# New records only: 7/7/8/8, while accepted30 remains byte-for-byte represented.
POSITIONS = [2,0,3,1,2,2,1,3,0,1,3,0,2,1,3, 0,3,2,1,0,2,3,0,1,2,3,1,2,0,3]

def records(names):
    return [r for name in names for r in json.loads((ROOT / name).read_text(encoding="utf-8"))["new_records"]]

def add(record, position, index):
    wrong = [x for x in record["options"] if x != record["author"]]
    wrong.insert(position, record["author"])
    stems = ("Кто написал произведение «{}»?", "Назовите автора книги «{}».", "Кому принадлежит «{}»?", "Какой писатель создал «{}»?")
    return {"id":record["id"],"type":"choice","text":stems[index % 4].format(record["title"]),"options":wrong,"correct_answer":position,"difficulty":record["difficulty"],"explanation":record["explanation"]}, record

def letter(n): return "ABCD"[n]

def main():
    check = argparse.ArgumentParser()
    check.add_argument("--check", action="store_true")
    read_only = check.parse_args().check
    accepted = SNAPSHOT["questions"]
    old_classic, old_modern = accepted[:15], accepted[15:]
    classic_raw, modern_raw = records(CLASSIC), records(MODERN)
    new_pairs = [add(r, p, i) for i, (r, p) in enumerate(zip(classic_raw + modern_raw, POSITIONS), 30)]
    new_classic, new_modern = new_pairs[:15], new_pairs[15:]
    classic, modern = old_classic + [q for q, _ in new_classic], old_modern + [q for q, _ in new_modern]
    if read_only:
        assert SNAPSHOT["question_count"] == len(SNAPSHOT["questions"]) == 30
        assert SNAPSHOT["historical_byte_proof"] is False
        current = [json.loads((ROOT / n).read_text(encoding="utf-8"))["questions"] for n in ("legacy-classic.json", "legacy-modern.json")]
        assert current == [classic, modern]
        candidate = (ROOT / "candidate.md").read_text(encoding="utf-8")
        assert all(q["id"] in candidate and q["text"] in candidate and all(x in candidate for x in q["options"]) for q in classic + modern)
        key = (ROOT / "editorial-key.md").read_text(encoding="utf-8")
        assert all(f"| {q['id']} | {letter(q['correct_answer'])} — {q['options'][q['correct_answer']]} |" in key and f"**{q['id']}.** {q['explanation']}" in key for q in classic + modern)
        rows = [line for line in key.splitlines() if line.startswith("| prep-books-")]
        assert len(rows) == 60 and all("https://" in line for line in rows)
        print("PASS: current 60 artifacts match generated questions; --check is read-only.")
        return
    for name, title, description, questions in (("legacy-classic.json", "Литература: классика — авторы", "Черновик: 30 классических произведений и их авторы.", classic), ("legacy-modern.json", "Литература: послевоенная и современная — авторы", "Черновик: 30 послевоенных и современных произведений и их авторы.", modern)):
        pack = {"id": "preparation-books-classic" if "classic" in name else "preparation-books-modern", "title":title,"description":description,"category":"Литература/Авторы","questions":questions}
        (ROOT / name).write_text(json.dumps(pack, ensure_ascii=False, indent=2)+"\n", encoding="utf-8")
    all_questions = classic + modern
    lines = ["# Кандидатский черновик: литература — авторы", "", "60 вопросов; ключ и источники намеренно не включены.", ""]
    for q in all_questions:
        lines += [f"### {q['id']}", q["text"], *[f"{letter(i)}. {x}" for i,x in enumerate(q["options"])], ""]
    (ROOT / "candidate.md").write_text("\n".join(lines), encoding="utf-8")
    facts = {r["id"]: r for _, r in new_pairs}
    old_records = {r["id"]: r for r in draft30.load_new(draft30.CLASSIC_INPUTS + draft30.MODERN_INPUTS)}
    accepted_facts = {ident:{"classification_note":note,"source":url} for ident,(note,url) in draft30.PILOT_META.items()}
    accepted_facts.update({ident:{"classification_note":(draft30.CLASSIC_FACTS | draft30.MODERN_FACTS)[ident],"source":record["source"]} for ident,record in old_records.items()})
    # Date corrections are recorded in the ledger; the author/plot sources remain the saved record URLs.
    for ident, note in {
        "prep-books-classic-17": ("LoC catalogues an 1888 edition: supported pre-1945 upper-bound classification; Maquet collaboration is qualified.", "https://www.loc.gov/item/06042822/"),
        "prep-books-classic-24": ("Gutenberg’s 1917 edition supplies a supported pre-1945 upper bound; no original-year claim is made here.", "https://www.gutenberg.org/files/30723/30723-h/30723-h.htm"),
        "prep-books-classic-26": ("Gutenberg supports Pushkin and Pugachev research context; classification is pre-1945 without asserting an unsupported original-year date.", "https://www.gutenberg.org/files/55024/old/55024-h/55024-h.htm"),
        "prep-books-modern-17": ("WorldCat library catalogue: McClelland & Stewart, Toronto, 1985; post-1945, not a later reprint.", "https://search.worldcat.org/title/The-handmaid%27s-tale/oclc/12825460"),
        "prep-books-modern-19": ("Markus Zusak’s bibliography records The Book Thief (2005); post-1945, not the 2007 Knopf ebook.", "https://www.markuszusak.com/books"),
        "prep-books-modern-20": ("Official Ian McEwan bibliography lists London: Jonathan Cape, 2001; post-1945, not the 2003 Vintage edition.", "https://www.ianmcewan.com/books/atonement"),
        "prep-books-modern-21": ("Grupo Planeta records La Sombra del Viento published in 2001; post-1945.", "https://planeta.es/en/history"),
        "prep-books-modern-22": ("Diogenes records Das Parfum originally published in 1985; post-1945.", "https://www.diogenes.ch/factsheet2/rights?titleID=56b9e489-d4c9-4b04-9e6d-ccef3f0ae91a"),
    }.items(): facts[ident] = {**facts[ident], "classification_note": note[0], "source": note[1]}
    key = ["# Редакционный ключ и источники: черновик 60", "", "Дата доступа ко всем URL: 2026-10-03. Даты служат классификации, а не ловушкам в вопросе.", "", "| ID | Ответ | Классификация первого издания | Источник |", "|---|---|---|---|"]
    for q in all_questions:
        r = facts.get(q["id"], accepted_facts.get(q["id"]))
        source = r["source"]
        note = r["classification_note"]
        key.append(f"| {q['id']} | {letter(q['correct_answer'])} — {q['options'][q['correct_answer']]} | {note} | {source} |")
    key += ["", "## Объяснения и различение дистракторов", ""]
    key += [x for q in all_questions for x in (f"**{q['id']}.** {q['explanation']}", "")]
    (ROOT / "editorial-key.md").write_text("\n".join(key), encoding="utf-8")
    coverage = ["# Покрытие черновика 60", "", "| Классика: первое издание до 1945 | Современная: первая публикация после 1945 |", "|---|---|"]
    for a,b in zip(classic, modern): coverage.append(f"| {a['text']} — {a['options'][a['correct_answer']]} | {b['text']} — {b['options'][b['correct_answer']]} |")
    coverage += ["", "Итого: 30 классических и 30 послевоенных произведений. Первые 30 взяты из отдельного reconstituted-snapshot; историческое байтовое совпадение прежнего snapshot не доказано. Долгосрочный реестр 120/80 остаётся отдельной задачей.", ""]
    (ROOT / "coverage.md").write_text("\n".join(coverage), encoding="utf-8")

if __name__ == "__main__": main()
