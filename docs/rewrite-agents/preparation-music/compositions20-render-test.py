"""Integration check: --check detects drift without mutating its four outputs."""
from __future__ import annotations
import hashlib, shutil, subprocess, sys, tempfile
from pathlib import Path

SOURCE = Path(__file__).parent
NAMES = ["compositions20-candidate.md", "compositions20-editorial-key.md",
         "compositions20-source-ledger.md", "compositions20-legacy.json"]
with tempfile.TemporaryDirectory() as temporary:
    root = Path(temporary)
    for item in SOURCE.glob("compositions20-checkpoint-*.md"):
        shutil.copy2(item, root / item.name)
    shutil.copy2(SOURCE / "compositions20-render.py", root / "compositions20-render.py")
    renderer = [sys.executable, str(root / "compositions20-render.py")]
    assert subprocess.run(renderer, cwd=root, capture_output=True, text=True).returncode == 0
    (root / NAMES[0]).write_text("intentional drift\n", encoding="utf-8")
    before = {name: hashlib.sha256((root / name).read_bytes()).hexdigest() for name in NAMES}
    result = subprocess.run([*renderer, "--check"], cwd=root, capture_output=True, text=True)
    after = {name: hashlib.sha256((root / name).read_bytes()).hexdigest() for name in NAMES}
    assert result.returncode != 0, result.stdout + result.stderr
    assert before == after, "--check mutated a generated output"
print("PASS --check detects drift without writes")
