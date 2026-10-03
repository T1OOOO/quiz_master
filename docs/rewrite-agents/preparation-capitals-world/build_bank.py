import hashlib, json, random
from pathlib import Path

ROOT = Path(__file__).parent
SOURCE = ROOT.parent / "preparation-country-registry" / "countries.json"
DATE = "2026-10-03"
SPECIAL = {
    "BJ": ("Какой город является конституционной столицей Бенина?", "Porto-Novo"),
    "BO": ("Какой город является конституционной столицей Боливии?", "Sucre"),
    "NL": ("Какой город является конституционной столицей Нидерландов?", "Amsterdam"),
    "MY": ("Какой город является столицей Малайзии, в отличие от административного центра Путраджаи?", "Kuala Lumpur"),
    "SZ": ("Какой город является административной столицей Эсватини?", "Mbabane"),
    "ZA": ("Какой город является административной столицей ЮАР?", "Pretoria"),
    "LK": ("Какой город является законодательной столицей Шри-Ланки?", "Sri Jayewardenepura Kotte"),
    "NR": ("Науру не имеет официальной столицы. В каком округе находится правительство?", "Yaren"),
    "ID": ("Какой город указан как столица Индонезии в приведённом профиле UNdata, до поэтапного переноса столичных функций в Нусантару?", "Jakarta"),
    "PS": ("Какой город Государство Палестина объявляет своей столицей (это не утверждение о международном признании её статуса)?", "East Jerusalem"),
    "PW": ("Какой город является столицей Палау, расположенной в штате Мелекеок?", "Ngerulmud"),
    "CH": ("Какой город выполняет функцию федерального города — места федеральных властей Швейцарии?", "Bern"),
    "KI": ("Какой населённый пункт Южной Таравы указан столицей Кирибати в профиле UNdata?", "Bairiki"),
    "IL": ("Какой город Израиль объявляет своей столицей?", "Jerusalem"),
    "VA": ("Какой город указан как столица Святого Престола в профиле UNdata?", "Vatican City"),
}
SPECIAL_ISOS = set(SPECIAL) | {"NR"}
SPECIAL_EXPLANATIONS = {
    "BJ": "Конституционная столица Бенина — «{target}».", "BO": "Конституционная столица Боливии — «{target}».",
    "NL": "Конституционная столица Нидерландов — «{target}».", "MY": "Столица Малайзии — «{target}»; административный центр — Путраджая.",
    "SZ": "Административная столица Эсватини — «{target}».", "ZA": "Административная столица ЮАР — «{target}».",
    "LK": "Законодательная столица Шри-Ланки — «{target}».", "ID": "Профиль UNdata указывает «{target}» до поэтапного переноса столичных функций в Нусантару.",
    "PS": "Государство Палестина объявляет «{target}» своей столицей; это не утверждение о международном признании статуса.",
    "PW": "«{target}» — столица Палау, расположенная в штате Мелекеок.", "CH": "«{target}» выполняет функцию федерального города — места федеральных властей Швейцарии.",
    "KI": "«{target}» — населённый пункт Южной Таравы, указанный столицей Кирибати в профиле UNdata.",
    "IL": "Израиль объявляет «{target}» своей столицей. Это вопрос об объявленной столице, а не об общем международном признании статуса города.",
    "VA": "В профиле UNdata используется название «Святой Престол», а город указан как «{target}». Святой Престол относится к двум государствам-наблюдателям ООН, а не к 193 государствам-членам.",
}

def main():
    countries = json.loads(SOURCE.read_text(encoding="utf-8"))["countries"]
    by_name = {cap["name_en"]: c for c in countries for cap in c["capitals"]}
    display = {cap["name_en"]: cap["name_ru"] for c in countries for cap in c["capitals"]}
    rows = []
    for c in countries:
        cap = c["capitals"][0]
        iso, city = c["iso2"], cap["name_en"]
        stem, target = SPECIAL.get(iso, (f"Какой город является столицей государства «{c['name_ru']}»?", city))
        # NR's registry city is the government district required by the packet.
        if iso == "NR": target = "Yaren"
        candidates = [x for x in countries if x["iso2"] != iso and x["iso2"] not in SPECIAL_ISOS and x["capitals"] and x["region"] == c["region"]]
        if len(candidates) < 3: candidates = [x for x in countries if x["iso2"] != iso and x["iso2"] not in SPECIAL_ISOS and x["capitals"]]
        candidates.sort(key=lambda x: hashlib.sha256((iso + x["iso2"]).encode()).hexdigest())
        distract = []
        for d in candidates:
            dc = d["capitals"][0]["name_en"]
            if dc != target and dc not in distract: distract.append(dc)
            if len(distract) == 3: break
        ids = "capw-" + hashlib.sha256((iso + "|" + target).encode()).hexdigest()[:12]
        options = [target] + distract
        rows.append((ids, c, cap, stem, target, options))
    rng = random.Random(195)
    positions = [0] * 49 + [1] * 49 + [2] * 49 + [3] * 48
    rng.shuffle(positions)
    candidate, key, legacy = [], [], []
    for (qid, c, cap, stem, target, opts), pos in zip(rows, positions):
        distract = [x for x in opts if x != target]
        random.Random(qid).shuffle(distract)
        opts = distract[:]
        opts.insert(pos, target)
        correct = pos
        target_display = display[target]
        opts_display = [display[o] for o in opts]
        pairs = [(display[o], by_name[o]["name_ru"]) for o in opts if o != target]
        explanation = f"«{target_display}» — столица государства «{c['name_ru']}». Остальные варианты относятся к другим странам: " + "; ".join(f"«{o}» — «{n}»" for o, n in pairs) + ". Запоминай именно пару страны и столицы."
        if c["iso2"] == "NR": explanation = f"Науру не имеет официальной столицы; правительство находится в округе «{target_display}». Остальные варианты относятся к другим странам: " + "; ".join(f"«{o}» — «{n}»" for o, n in pairs) + "."
        elif c["iso2"] in SPECIAL_EXPLANATIONS: explanation = SPECIAL_EXPLANATIONS[c["iso2"]].format(target=target_display) + " Остальные варианты относятся к другим странам: " + "; ".join(f"«{o}» — «{n}»" for o, n in pairs) + "."
        candidate.append({"id": qid, "text": stem, "options": opts_display})
        key.append({"id": qid, "correct_letter": "ABCD"[correct], "correct_text": target_display, "iso": c["iso2"], "source_url": cap["source_uri"], "source_date": DATE, "distractors": [{"city": o, "country": n} for o, n in pairs], "explanation": explanation})
        legacy.append({"id": qid, "type": "choice", "difficulty": 4, "text": stem, "options": opts_display, "correct_answer": correct, "explanation": explanation})
    root = {"id":"prep-capitals-world","title":"Столицы мира: 195 стран","description":"Тренировка различения столиц государств мира и столичных функций.","category":"География/Столицы","questions":legacy}
    (ROOT/"candidate.md").write_text("\n".join(f"{x['id']} | {x['text']} | " + " | ".join(x['options']) for x in candidate)+"\n", encoding="utf-8")
    (ROOT/"editorial-key.md").write_text("\n".join(f"{x['id']} | {x['correct_letter']} | {x['correct_text']} | {x['iso']} | {x['source_url']} | {x['source_date']} | " + "; ".join(f"{d['city']} — {d['country']}" for d in x['distractors']) + " | " + x['explanation'] for x in key)+"\n", encoding="utf-8")
    (ROOT/"legacy.json").write_text(json.dumps(root, ensure_ascii=False, indent=2)+"\n", encoding="utf-8")
    (ROOT/"coverage.md").write_text("# Coverage\n\n" + "\n".join(f"{c['iso2']} → {qid}" for qid, c, *_ in rows) + f"\n\nCount: {len(rows)}\n", encoding="utf-8")
    assert len(rows) == 195 and len({x[0] for x in rows}) == 195
    assert all(len(x["options"]) == 4 and len(set(x["options"])) == 4 for x in legacy)
    display_names = {cap["name_ru"] for c in countries for cap in c["capitals"]}
    assert all(o in display_names for q in legacy for o in q["options"])
    assert all(x["correct_text"] in display_names for x in key)
    assert [x["correct_answer"] for x in legacy].count(0) == 49
    assert [x["correct_answer"] for x in legacy].count(1) == 49
    assert [x["correct_answer"] for x in legacy].count(2) == 49
    assert [x["correct_answer"] for x in legacy].count(3) == 48
    assert json.loads((ROOT/"legacy.json").read_text(encoding="utf-8")) == root
    assert len(candidate) == len(key) == len(legacy) == 195
    assert [x["id"] for x in candidate] == [x["id"] for x in key] == [x["id"] for x in legacy]
    assert [x["options"] for x in candidate] == [x["options"] for x in legacy]
    assert all(not any(d["country"] == next(y["name_ru"] for y in countries if y["iso2"] == s) for d in x["distractors"]) for x in key for s in SPECIAL_ISOS)
    assert len((ROOT/"coverage.md").read_text(encoding="utf-8").splitlines()) >= 196

if __name__ == "__main__": main()
