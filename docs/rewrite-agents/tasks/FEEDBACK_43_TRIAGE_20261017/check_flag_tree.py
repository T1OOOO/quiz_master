"""Check the full published flag-media closure in a supplied static web root."""
import hashlib
import json
import re
import sys
from pathlib import Path


def check(catalog, flag_directory):
    questions = json.loads(Path(catalog).read_text(encoding="utf-8"))["questions"]
    names = set()
    for question in questions:
        for media in question.get("media", []):
            uri = media["uri"]
            if not uri.startswith("https://quiz.kotopedia.org/flags/"):
                continue
            name = uri.rsplit("/", 1)[1]
            if not re.fullmatch(r"[0-9a-f]{64}\.png", name):
                raise ValueError("invalid content-addressed flag filename")
            data = (Path(flag_directory) / name).read_bytes()
            if not data.startswith(b"\x89PNG\r\n\x1a\n") or hashlib.sha256(data).hexdigest() + ".png" != name:
                raise ValueError("flag PNG signature or digest mismatch: " + name)
            names.add(name)
    if len(names) != 195:
        raise ValueError("expected all 195 unique flag images")
    return {"status": "pass_static_media_closure_only", "unique_images": len(names)}


if __name__ == "__main__":
    print(json.dumps(check(sys.argv[1], Path(sys.argv[2]) / "flags")))
