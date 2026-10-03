"""Readonly structural gate for the folklore pilot."""
import json
import re
from pathlib import Path

path = Path(__file__).with_name("folklore-legacy-pilot10.json")
pack = json.loads(path.read_text(encoding="utf-8"))
assert set(pack) == {"id", "category", "title", "description", "questions"}
assert pack["id"] == "prep-folklore" and pack["category"] == "Мифология/Фольклор"
assert pack["description"].strip() and len(pack["questions"]) == 10
ids = []
for question in pack["questions"]:
    assert set(question) == {"id", "type", "text", "options", "correct_answer", "explanation"}
    assert question["type"] == "choice" and len(question["options"]) == 4
    assert isinstance(question["correct_answer"], int) and 0 <= question["correct_answer"] < 4
    words = len(re.findall(r"[\wА-Яа-яЁё-]+", question["explanation"]))
    assert 20 <= words <= 45, (question["id"], words)
    ids.append(question["id"])
assert ids == [f"prep-folklore-{i:03d}" for i in range(1, 11)]
print("PASS folklore pilot10 closed-fields/options/answers/explanations=20-45")
