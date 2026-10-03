"""Small stdlib validation for the in-progress compositions20 checkpoints."""
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).parent
FILES = sorted(ROOT.glob("compositions20-checkpoint-*.md"))
RECORD = re.compile(r"^## (compositions\d{3}) .+?позиция ([ABCD])$(.*?)(?=^## |\Z)", re.M | re.S)

records = []
for path in FILES:
    for ident, position, body in RECORD.findall(path.read_text(encoding="utf-8")):
        options = re.findall(r"^[ABCD]\. .+$", body, re.M)
        answer = re.search(r"^\*\*Ответ:\*\* ([ABCD])\. .+$", body, re.M)
        explanation = re.search(r"^\*\*Объяснение \((\d+) слов\w*\):\*\* (.+)$", body, re.M)
        sources = re.search(r"^\*\*Источники:\*\* .+https?://", body, re.M)
        assert len(options) == 4, (ident, "requires four closed options")
        assert answer and answer.group(1) == position, (ident, "answer/position mismatch")
        assert explanation, (ident, "missing explanation")
        words = len(re.findall(r"[\wÀ-ÿА-Яа-яЁё-]+", explanation.group(2)))
        assert 40 <= words <= 65, (ident, words)
        assert sources, (ident, "missing received source URL")
        records.append((ident, position))

assert [ident for ident, _ in records] == [f"compositions{i:03d}" for i in range(1, len(records) + 1)]
positions = [position for _, position in records]
assert all(positions[i] != positions[i + 1] for i in range(len(positions) - 1)), "cyclic adjacent positions"
assert len(set(positions)) == min(4, len(positions)), "initial distribution incomplete"
print(f"PASS compositions20 checkpoints={len(records)} positions={''.join(positions)}")
