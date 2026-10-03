"""Read-only source guard for accepted-ten ledger and fifty checkpoint records."""
import re
from pathlib import Path

ROOT = Path(__file__).parent
key = (ROOT / "editorial-key.md").read_text(encoding="utf-8")
ledger = (ROOT / "working-source-ledger.md").read_text(encoding="utf-8")
checkpoints = list(ROOT.glob("checkpoint-*.md"))
body = "\n".join(path.read_text(encoding="utf-8") for path in checkpoints)
assert ledger.count("| music-oct3-") == 10
assert len(re.findall(r"^## music-oct3-\d{3}", body, re.M)) == 50
sources = re.findall(r"^Источник: \[(.+?)\]\((https://[^)]+)\)", body, re.M)
assert len(sources) >= 50 and all(url in key for _, url in sources)
assert "Пётр Чайковский" in body and "Модест Мусоргский" in body
assert "Николай Римский-Корсаков" in body and "Александр Глазунов" in body
assert "Паизиелло" in body and "1816" in body
print("PASS: accepted-ten ledger retained; 50 checkpoint claims carry received source URLs into the editorial key.")
