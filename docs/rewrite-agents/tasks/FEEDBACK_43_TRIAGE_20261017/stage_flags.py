"""Restore verified cached flags to an isolated media-only staging tree; no release mutation."""
import json
import shutil
from pathlib import Path
from check_flag_tree import check

REPO = Path(__file__).resolve().parents[4]
CATALOG = REPO / "quizzes/Preparation/prep_flags_world.json"
CACHE = REPO / ".run/flags-pilot"
TARGET = REPO / ".run/feedback_triage_20261017_0443/restored-web"


def stage():
    if TARGET.exists():
        raise FileExistsError("staging target already exists; inspect it rather than overwrite")
    # Validate the entire cache before creating any staging files.
    check(CATALOG, CACHE)
    questions = json.loads(CATALOG.read_text(encoding="utf-8"))["questions"]
    names = sorted({m["uri"].rsplit("/", 1)[1] for q in questions for m in q.get("media", [])
                    if m["uri"].startswith("https://quiz.kotopedia.org/flags/")})
    (TARGET / "flags").mkdir(parents=True, exist_ok=False)
    for name in names:
        shutil.copyfile(CACHE / name, TARGET / "flags" / name)
    return check(CATALOG, TARGET / "flags")


if __name__ == "__main__":
    print(json.dumps(stage()))
