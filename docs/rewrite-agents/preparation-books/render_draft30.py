"""Render the bounded 30-question books draft from saved authoring checkpoints.

This uses only Python's standard library and intentionally never reaches outside
this preparation directory.
"""
import json
from pathlib import Path

ROOT = Path(__file__).parent
CLASSIC_INPUTS = ("authoring-checkpoint.json", "authoring-step-classic-08.json", "authoring-step-classic-10.json")
MODERN_INPUTS = ("authoring-step-modern-03.json", "authoring-step-modern-05.json", "authoring-step-modern-08.json", "authoring-step-modern-10.json")

CLASSIC_FACTS = {
    "prep-books-classic-06": "1605 и 1615, до 1945; Gutenberg фиксирует обе части.",
    "prep-books-classic-07": "первое quarto 1603, до 1945; Folger фиксирует раннее издание.",
    "prep-books-classic-08": "16 октября 1847, до 1945; запись Британской библиотеки.",
    "prep-books-classic-09": "полная книжная форма 1891, до 1945; метаданные Gutenberg.",
    "prep-books-classic-10": "титульный лист 1851, до 1945; издание Gutenberg.",
    "prep-books-classic-11": "издание 1847, до 1945; библиографическая запись Gutenberg.",
    "prep-books-classic-12": "первое издание 1865, до 1945; издание Gutenberg.",
    "prep-books-classic-13": "1925, до 1945; экспозиция Библиотеки Конгресса.",
    "prep-books-classic-14": "публикация 21 сентября 1937, до 1945; запись Британской библиотеки.",
    "prep-books-classic-15": "Gutenberg указывает 1869; это верхняя граница до 1945, а не переиздание.",
}
MODERN_FACTS = {
    "prep-books-modern-06": "трилогия 1954–1955, после 1945; не «Хоббит» 1937 года.",
    "prep-books-modern-07": "1953, после 1945; дата из издательской подборки Penguin.",
    "prep-books-modern-08": "оригинальное португалоязычное «O Alquimista», 1988, после 1945; не дата английского перевода.",
    "prep-books-modern-09": "первое издание J. B. Lippincott, 1960, после 1945; экспозиция Библиотеки Конгресса.",
    "prep-books-modern-10": "первая публикация 1966–1967 после смерти автора; категория определяется публикацией.",
    "prep-books-modern-11": "2003, после 1945; страница Penguin Random House.",
    "prep-books-modern-12": "1987, после 1945; страница Penguin.",
    "prep-books-modern-13": "2005, после 1945; страница Faber.",
    "prep-books-modern-14": "твёрдое издание Doubleday 18 марта 2003, после 1945.",
    "prep-books-modern-15": "шведский оригинал «Män som hatar kvinnor», 2005, после 1945; не дата перевода.",
}
PILOT_TITLES = {
    "prep-books-classic-01": "Гордость и предубеждение", "prep-books-classic-02": "Преступление и наказание",
    "prep-books-classic-03": "Франкенштейн, или Современный Прометей", "prep-books-classic-04": "Маленький принц",
    "prep-books-classic-05": "Процесс", "prep-books-modern-01": "1984",
    "prep-books-modern-02": "Сто лет одиночества", "prep-books-modern-03": "Имя розы",
    "prep-books-modern-04": "Гарри Поттер и философский камень", "prep-books-modern-05": "Голодные игры",
}
PILOT_META = {
    "prep-books-classic-01": ("1813, до 1945", "https://www.bl.uk/stories/blogs/posts/jane-austen-names-and-notability"),
    "prep-books-classic-02": ("1866, до 1945", "https://www.gutenberg.org/ebooks/2554"),
    "prep-books-classic-03": ("1818, до 1945; полное название включает «или Современный Прометей»", "https://visit.bodleian.ox.ac.uk/sites/default/files/bodwhatson/documents/media/frankenstein-timeline-resource.pdf"),
    "prep-books-classic-04": ("1943, до 1945", "https://www.nypl.org/childrens-100-books-of-2013"),
    "prep-books-classic-05": ("1925, до 1945; первое книжное издание посмертно", "https://www.franzkafka.de/werk/der-process"),
    "prep-books-modern-01": ("1949, после 1945", "https://www.orwellfoundation.com/the-orwell-foundation/orwell/books-by-orwell/nineteen-eighty-four/"),
    "prep-books-modern-02": ("1967, после 1945", "https://www.banrepcultural.org/gabo/"),
    "prep-books-modern-03": ("1980, после 1945", "https://www.bompiani.it/storia-casa-editrice"),
    "prep-books-modern-04": ("Великобритания, 1997, после 1945; не американское переименование", "https://www.bloomsbury.com/media/hyjhn0oi/newtitles_2022e1_lr.pdf"),
    "prep-books-modern-05": ("2008, после 1945", "https://www.scholastic.com/newsroom/all-news/press-release/the-hunger-games-by-suzanne-collins.html"),
}
# The accepted first ten retain their existing positions. These positions make
# the added twenty exactly 5/5/5/5 and avoid runs longer than three.
NEW_POSITIONS = {
    "prep-books-classic-06": 1, "prep-books-classic-07": 2, "prep-books-classic-08": 3,
    "prep-books-classic-09": 0, "prep-books-classic-10": 1, "prep-books-classic-11": 2,
    "prep-books-classic-12": 3, "prep-books-classic-13": 0, "prep-books-classic-14": 1,
    "prep-books-classic-15": 2, "prep-books-modern-06": 3, "prep-books-modern-07": 1,
    "prep-books-modern-08": 0, "prep-books-modern-09": 3, "prep-books-modern-10": 2,
    "prep-books-modern-11": 1, "prep-books-modern-12": 0, "prep-books-modern-13": 3,
    "prep-books-modern-14": 0, "prep-books-modern-15": 2,
}

def load_new(names):
    result = []
    for name in names:
        result.extend(json.loads((ROOT / name).read_text(encoding="utf-8"))["new_records"])
    return result

def stem(title, index):
    variants = (
        f"Кто написал произведение «{title}»?",
        f"Назовите автора книги «{title}».",
        f"Кому принадлежит «{title}»?",
        f"Какой писатель создал «{title}»?",
    )
    return variants[index % len(variants)]

def question(record, index):
    right = record["author"]
    wrong = [item for item in record["options"] if item != right]
    position = NEW_POSITIONS[record["id"]]
    options = wrong[:]
    options.insert(position, right)
    return {"id": record["id"], "type": "choice", "text": stem(record["title"], index),
            "options": options, "correct_answer": position, "difficulty": record["difficulty"],
            "explanation": record["explanation"], "source": record["source"],
            "classification": (CLASSIC_FACTS | MODERN_FACTS)[record["id"]], "work_title": record["title"]}

def letter(position):
    return "ABCD"[position]

def render_candidate(questions):
    lines = ["# Кандидатский черновик: литература — авторы", "", "30 исходных вопросов; ключ и источники намеренно не включены.", ""]
    for item in questions:
        lines += [f"### {item['id']}", item["text"]]
        lines += [f"{letter(i)}. {option}" for i, option in enumerate(item["options"])]
        lines.append("")
    return "\n".join(lines)

def render_key(questions):
    lines = ["# Редакционный ключ и источники: черновик 30", "", "Дата доступа ко всем URL: 2026-10-03. Даты служат классификации, а не ловушкам в вопросе.", "", "| ID | Ответ | Классификация первого издания | Источник |", "|---|---|---|---|"]
    for item in questions:
        answer = item["options"][item["correct_answer"]]
        classification = item.get("classification", "см. сохранённую пилотную запись")
        source = item.get("source", "см. сохранённую пилотную запись")
        lines.append(f"| {item['id']} | {letter(item['correct_answer'])} — {answer} | {classification} | {source} |")
    lines += ["", "## Объяснения и различение дистракторов", ""]
    for item in questions:
        lines += [f"**{item['id']}.** {item['explanation']}", ""]
    return "\n".join(lines)

def render_coverage(classic, modern):
    lines = ["# Покрытие черновика 30", "", "| Классика: первое издание до 1945 | Современная: публикация после 1945 |", "|---|---|"]
    for left, right in zip(classic, modern):
        left_title = left.get("work_title") or PILOT_TITLES.get(left["id"]) or left["text"].split("«", 1)[1].split("»", 1)[0]
        right_title = right.get("work_title") or PILOT_TITLES.get(right["id"]) or right["text"].split("«", 1)[1].split("»", 1)[0]
        lines.append(f"| {left_title} — {left['options'][left['correct_answer']]} | {right_title} — {right['options'][right['correct_answer']]} |")
    lines += ["", "Итого: 15 классических и 15 послевоенных/современных произведений; первые 10 пилотных записей сохранены без изменений. Названное покрытие 120/80 остаётся последующей задачей, не заявляется этим черновиком.", ""]
    return "\n".join(lines)

def main():
    old_classic = json.loads((ROOT / "legacy-classic.json").read_text(encoding="utf-8"))
    old_modern = json.loads((ROOT / "legacy-modern.json").read_text(encoding="utf-8"))
    legacy_fields = {"id", "type", "text", "options", "correct_answer", "difficulty", "explanation"}
    old_classic["questions"] = [{key: value for key, value in item.items() if key in legacy_fields} for item in old_classic["questions"]]
    old_modern["questions"] = [{key: value for key, value in item.items() if key in legacy_fields} for item in old_modern["questions"]]
    old_classic["questions"] = old_classic["questions"][:5]
    old_modern["questions"] = old_modern["questions"][:5]
    classic_new = [question(item, i) for i, item in enumerate(load_new(CLASSIC_INPUTS), start=5)]
    modern_new = [question(item, i) for i, item in enumerate(load_new(MODERN_INPUTS), start=5)]
    classic = old_classic["questions"] + [{key: value for key, value in item.items() if key not in ("source", "classification", "work_title")} for item in classic_new]
    modern = old_modern["questions"] + [{key: value for key, value in item.items() if key not in ("source", "classification", "work_title")} for item in modern_new]
    pilot_meta = [{**q, "classification": PILOT_META[q["id"]][0], "source": PILOT_META[q["id"]][1]}
                  for q in old_classic["questions"] + old_modern["questions"]]
    # Key/candidate use pack order, matching legacy ordering.
    ordered = pilot_meta[:5] + classic_new + pilot_meta[5:] + modern_new
    old_classic.update({"title": "Литература: классика — авторы", "description": "Черновик: 15 классических книг и их авторы.", "questions": classic})
    old_modern.update({"title": "Литература: послевоенная и современная — авторы", "description": "Черновик: 15 послевоенных и современных книг и их авторы.", "questions": modern})
    (ROOT / "legacy-classic.json").write_text(json.dumps(old_classic, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    (ROOT / "legacy-modern.json").write_text(json.dumps(old_modern, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    (ROOT / "candidate.md").write_text(render_candidate(ordered), encoding="utf-8")
    (ROOT / "editorial-key.md").write_text(render_key(ordered), encoding="utf-8")
    (ROOT / "coverage.md").write_text(render_coverage(classic, modern), encoding="utf-8")

if __name__ == "__main__":
    main()
