"""Build and validate the local study reader using only Python's standard library."""
import argparse
import collections
import html
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent
EXPECTED = {
    "nature", "geography-countries", "history", "greek-mythology",
    "nature-evolution", "geography-maps",
}


def require(condition, message):
    if not condition:
        raise ValueError(message)


def read_json(path):
    return json.loads(path.read_text(encoding="utf-8-sig"))


def inline(text):
    # Escape author text first; raw HTML is never executed by the reader.
    value = html.escape(text, quote=True)
    def link(match):
        label, target = match.groups()
        target = html.unescape(target)
        if target.startswith(("https://", "http://", "#")):
            return f'<a href="{html.escape(target, quote=True)}" target="_blank" rel="noopener noreferrer">{label}</a>'
        return label
    value = re.sub(r"\[([^\]]+)\]\(([^\s)]+)\)", link, value)
    value = re.sub(r"\*\*(.+?)\*\*", r"<strong>\1</strong>", value)
    value = re.sub(r"`([^`]+)`", r"<code>\1</code>", value)
    return value


def markdown(text):
    lines = text.splitlines()
    parts, paragraph, in_list = [], [], False
    def flush():
        if paragraph:
            parts.append("<p>" + inline(" ".join(paragraph)) + "</p>")
            paragraph.clear()
    def close_list():
        nonlocal in_list
        if in_list:
            parts.append("</ul>")
            in_list = False
    i = 0
    while i < len(lines):
        line = lines[i].strip()
        image = re.fullmatch(r"!\[([^\]]*)\]\(([^)]+)\)", line)
        heading = re.match(r"^(#{1,6})\s+(.+)$", line)
        bullet = re.match(r"^(?:[-*]|\d+[.)])\s+(.+)$", line)
        if image:
            flush(); close_list()
            alt, path = image.groups()
            if path.startswith("../../assets/"):
                path = "../assets/" + path.removeprefix("../../assets/")
            if path.startswith(("../assets/", "https://")):
                parts.append(f'<figure><img src="{html.escape(path, quote=True)}" alt="{html.escape(alt, quote=True)}" loading="lazy"><figcaption>{html.escape(alt)}</figcaption></figure>')
        elif heading:
            flush(); close_list()
            n, title = len(heading.group(1)), heading.group(2)
            parts.append(f'<h{n}>{inline(title)}</h{n}>')
        elif line.startswith("|") and i + 1 < len(lines) and re.fullmatch(r"[| :\-]+", lines[i + 1].strip()):
            flush(); close_list()
            cells = lambda row: [inline(cell.strip()) for cell in row.strip().strip("|").split("|")]
            parts.append('<div class="table-wrap"><table><thead><tr>' + ''.join(f'<th>{c}</th>' for c in cells(line)) + '</tr></thead><tbody>')
            i += 2
            while i < len(lines) and lines[i].strip().startswith("|"):
                parts.append('<tr>' + ''.join(f'<td>{c}</td>' for c in cells(lines[i])) + '</tr>')
                i += 1
            parts.append('</tbody></table></div>')
            continue
        elif bullet:
            flush()
            if not in_list:
                parts.append("<ul>"); in_list = True
            parts.append("<li>" + inline(bullet.group(1)) + "</li>")
        elif line.startswith(">"):
            flush(); close_list(); parts.append("<blockquote>" + inline(line.lstrip("> ")) + "</blockquote>")
        elif not line:
            flush(); close_list()
        else:
            close_list(); paragraph.append(line)
        i += 1
    flush(); close_list()
    return "\n".join(parts)


def load_modules():
    modules, seen = [], set()
    quiz_ids = {read_json(path)["id"] for path in (ROOT.parent / "quizzes").rglob("*.json")}
    for name in sorted(EXPECTED):
        folder = ROOT / "modules" / name
        metadata = read_json(folder / "module.json")
        candidate = read_json(folder / "questions.candidate.json")
        key = read_json(folder / "questions.key.json")
        briefs = read_json(folder / "image-briefs.json")
        article = (folder / "article.md").read_text(encoding="utf-8")
        require(metadata["id"] == name, f"{name}: module id")
        require(candidate["id"] == key["pack_id"] == f"study-{name}", f"{name}: pack ids")
        require(metadata["status"] in {"draft", "revise", "accepted"}, f"{name}: status")
        require(metadata["article"] == "article.md", f"{name}: article path")
        require(type(metadata["reading_minutes_estimate"]) is int and metadata["reading_minutes_estimate"] > 0, f"{name}: reading time")
        require(3 <= len(metadata["objectives"]) <= 5, f"{name}: objectives")
        require(metadata["source_quiz_ids"] and set(metadata["source_quiz_ids"]) <= quiz_ids, f"{name}: invalid existing quiz references")
        sources = {s["id"]: s for s in metadata["source_catalog"]}
        require(len(sources) == len(metadata["source_catalog"]) >= 3, f"{name}: source catalog")
        for source in sources.values():
            require(source["url"].startswith("https://"), f"{name}: source URL")
            require(source["evidence_status"] in {"opened", "search_only", "open_failed"}, f"{name}: source access status")
            require(source["accessed"] == "2026-10-04", f"{name}: source access date")
        require(len(candidate["questions"]) == len(key["records"]) == len(briefs["items"]) == 20, f"{name}: record counts")
        records = {r["id"]: r for r in key["records"]}
        images = {r["question_id"]: r for r in briefs["items"]}
        ids = {q["id"] for q in candidate["questions"]}
        require(len(ids) == 20 and ids == set(records) == set(images), f"{name}: aligned unique IDs")
        positions, questions = [], []
        for q in candidate["questions"]:
            require(q["id"] not in seen, f"duplicate question ID: {q['id']}")
            seen.add(q["id"])
            require(set(q) == {"id", "type", "text", "options"}, f"{q['id']}: blind fields")
            require(q["type"] == "choice" and len(q["options"]) == len(set(q["options"])) == 4, f"{q['id']}: options")
            r = records[q["id"]]
            require(type(r["correct_answer"]) is int and 0 <= r["correct_answer"] <= 3, f"{q['id']}: answer index")
            words = len(r["explanation"].split())
            require(20 <= words <= 45, f"{q['id']}: explanation {words} words")
            require(len(r["distractors"]) == 3, f"{q['id']}: distractor explanations")
            require(r["source_refs"] and set(r["source_refs"]) <= set(sources), f"{q['id']}: source references")
            brief = images[q["id"]]
            require(brief["status"] in {"pending", "generated", "accepted"}, f"{q['id']}: image status")
            require(brief["purpose"] in {"illustration", "reference-required"}, f"{q['id']}: image purpose")
            require(brief["prompt"] and brief["alt"], f"{q['id']}: image brief")
            positions.append(r["correct_answer"])
            questions.append({**q, "correct_answer": r["correct_answer"], "explanation": r["explanation"], "source_refs": r["source_refs"]})
        require(collections.Counter(positions) == {0: 5, 1: 5, 2: 5, 3: 5}, f"{name}: key balance")
        require(all(not (positions[i] == positions[i+1] == positions[i+2]) for i in range(18)), f"{name}: key runs")
        require(len(article.split()) >= 600, f"{name}: substantive article")
        require(len(re.findall(r"^## ", article, re.M)) >= 6, f"{name}: article sections")
        require((ROOT / "assets" / f"{name}-hero.png").is_file(), f"{name}: missing hero")
        modules.append({"metadata": metadata, "html": markdown(article), "article_markdown": article, "questions": questions})
    return modules


def outputs(modules, include_flutter=False):
    template = (ROOT / "reader.html").read_text(encoding="utf-8")
    require(template.count("/*__STUDY_PAYLOAD__*/[]") == 1, "reader: payload marker must occur exactly once")
    payload = json.dumps(modules, ensure_ascii=False, separators=(",", ":")).replace("<", "\\u003c").replace("\u2028", "\\u2028").replace("\u2029", "\\u2029")
    result = {ROOT / "site" / "index.html": template.replace("/*__STUDY_PAYLOAD__*/[]", payload)}
    for module in modules:
        m = module["metadata"]
        pack = {"id": f"study-{m['id']}", "title": m["title"], "description": m["description"], "category": m["category"], "questions": module["questions"]}
        result[ROOT / "site" / "quiz-packs" / f"{m['id']}.json"] = json.dumps(pack, ensure_ascii=False, indent=2) + "\n"
    if include_flutter:
        catalog = read_json(ROOT.parent / "next/apps/quiz_app/assets/catalog.json")
        native_quiz_ids = {quiz["quiz_id"] for quiz in catalog}
        native_modules = []
        for module in modules:
            metadata = module["metadata"]
            require(metadata["status"] == "accepted", f"{metadata['id']}: Flutter export requires accepted editorial status")
            native = {k: metadata[k] for k in ("id", "title", "description", "category", "reading_minutes_estimate", "objectives", "source_quiz_ids")}
            # Legacy source IDs remain valid for the standalone reader; Flutter
            # routes use canonical IDs. Reject missing targets before export.
            native["source_quiz_ids"] = []
            for legacy_id in metadata["source_quiz_ids"]:
                quiz_id = legacy_id if legacy_id in native_quiz_ids else legacy_id.replace("_", "-")
                require(quiz_id in native_quiz_ids, f"{metadata['id']}: missing Flutter quiz reference {legacy_id}")
                native["source_quiz_ids"].append(quiz_id)
            native["article_markdown"] = module["article_markdown"].replace("../../assets/", "resource:assets/study/")
            native["questions"] = module["questions"]
            native["sources"] = [{k: s[k] for k in ("id", "title", "url")} for s in metadata["source_catalog"]]
            native_modules.append(native)
        result[ROOT.parent / "next/apps/quiz_app/assets/study/catalog.json"] = json.dumps({"modules": native_modules}, ensure_ascii=False, indent=2) + "\n"
    return result


def main():
    parser = argparse.ArgumentParser()
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--write", action="store_true")
    group.add_argument("--check", action="store_true")
    parser.add_argument("--flutter", action="store_true", help="Export accepted modules for explicitly unranked Flutter self-check")
    args = parser.parse_args()
    modules = load_modules()
    rendered = outputs(modules, include_flutter=args.flutter)
    for path, value in rendered.items():
        if args.write:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(value, encoding="utf-8", newline="\n")
        else:
            require(path.read_text(encoding="utf-8") == value, f"stale generated file: {path}")
    print(f"PASS: {len(modules)} modules / {sum(len(m['questions']) for m in modules)} questions; IDs, blind boundary, sources, explanations, key balance, media briefs and rendered parity")


if __name__ == "__main__":
    main()
