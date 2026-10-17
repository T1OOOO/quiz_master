"""Offline regression checks; disposable files remain under this task's ignored work area."""
import json
import shutil
import tempfile
from pathlib import Path
import stage_flags as restore
from check_flag_tree import check


def rejects(call, error):
    try:
        call()
    except error:
        return
    raise AssertionError("expected " + error.__name__)


with tempfile.TemporaryDirectory(dir=restore.REPO / ".run/feedback_triage_20261017_0443") as temporary:
    root = Path(temporary)
    restore.TARGET = root / "web"
    result = restore.stage()
    assert result["unique_images"] == 195
    before = {p.name: p.read_bytes() for p in (restore.TARGET / "flags").iterdir()}
    rejects(restore.stage, FileExistsError)
    assert before == {p.name: p.read_bytes() for p in (restore.TARGET / "flags").iterdir()}
    name = sorted(before)[0]
    png = restore.TARGET / "flags" / name
    png.write_bytes(b"<!DOCTYPE html>")
    rejects(lambda: check(restore.CATALOG, png.parent), ValueError)
    png.unlink()
    rejects(lambda: check(restore.CATALOG, png.parent), FileNotFoundError)
    bad_catalog = root / "bad.json"
    bad_catalog.write_text(json.dumps({"questions": [{"media": [{"uri": "https://quiz.kotopedia.org/flags/../secret.png"}]}]}))
    rejects(lambda: check(bad_catalog, png.parent), ValueError)
    shutil.copytree(restore.CACHE, root / "cache")
    restore.CACHE = root / "cache"
    (restore.CACHE / name).write_bytes(b"bad PNG")
    restore.TARGET = root / "rejected-web"
    rejects(restore.stage, ValueError)
    assert not restore.TARGET.exists()
print(json.dumps({"status": "pass_offline_only", "valid_images": 195,
                  "checks": ["closure", "no_overwrite", "HTML_rejected", "missing_rejected", "traversal_rejected", "invalid_cache_no_output"],
                  "http_browser_container_checks": False, "publication_attempted": False}))
