#!/usr/bin/env python3
"""Pure fail-closed checks for the resumed Screen Song controllers.

No package, build, browser, network, Git mutation, or remote command is run.
"""
from __future__ import annotations

import json
import subprocess
import sys
import tempfile
from pathlib import Path

import prepare_screen_song_release as producer
from test_pins import inert_complete_pins


ROOT = Path(__file__).resolve().parent
SCRATCH = Path("C:/ap/quiz_master/.run/screen_song_controller_resumed_20261014")


def rejects(label: str, action, phrase: str) -> None:
    try:
        action()
    except (RuntimeError, FileNotFoundError) as error:
        if phrase not in str(error):
            raise AssertionError(f"{label}: expected {phrase!r}, got {error!s}") from error
        print(f"PASS rejection: {label}")
        return
    raise AssertionError(f"guard accepted invalid input: {label}")


def main() -> None:
    for name in (
        "prepare_screen_song_release.py", "prepare_remote.py",
        "publish_prepared.py", "save_execution_acceptance.py", "test_pins.py",
    ):
        subprocess.run([sys.executable, "-m", "py_compile", str(ROOT / name)], check=True)
    print("PASS syntax: five controllers compile")

    rejects("missing release pins", lambda: producer.load_required_pins(SCRATCH / "missing.json"), "missing fresh release pins")
    with tempfile.TemporaryDirectory(dir=SCRATCH) as directory:
        path = Path(directory) / "pins.json"
        path.write_text(json.dumps(inert_complete_pins(
            frozen_commit=producer.BASELINE_SOURCE_COMMIT,
            build_id="quiz-2026.10.14-screen-song-83748f5",
        )), encoding="utf-8")
        rejects("Actor51 reused as target", lambda: producer.load_required_pins(path), "fresh final Screen Song source")
        path.write_text(json.dumps(inert_complete_pins(normalized_source_sha256="not-a-hash")), encoding="utf-8")
        rejects("malformed full SHA256 pin", lambda: producer.load_required_pins(path), "full SHA256")

    if producer.RELEASE_PINS is not None or producer.FROZEN_COMMIT is not None or producer.BUILD_ID is not None:
        raise AssertionError("module starts with target pins already loaded")
    print("PASS fail-closed: no target pins are embedded or loaded")


if __name__ == "__main__":
    main()
