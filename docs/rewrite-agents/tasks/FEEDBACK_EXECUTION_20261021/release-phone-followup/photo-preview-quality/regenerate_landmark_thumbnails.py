"""Regenerate the approved landmark thumbnail set deterministically.

The script is intentionally narrow: it reads the 46 landmark pairs from the
catalog, writes only those thumbnail paths, and emits a binding manifest.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import platform
import sys
from datetime import datetime, timezone
from pathlib import Path

from PIL import Image, ImageOps, __version__ as PILLOW_VERSION

EXPECTED_COUNT = 46
MAX_EDGE = 512
QUALITY = 76
METHOD = 6


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as fh:
        for chunk in iter(lambda: fh.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def dimensions(path: Path) -> list[int]:
    with Image.open(path) as im:
        return [int(im.width), int(im.height)]


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", type=Path, default=Path("next/apps/quiz_app"))
    ap.add_argument("--manifest", type=Path, required=True)
    args = ap.parse_args()
    if args.manifest.exists():
        raise SystemExit("manifest already exists; use a fresh evidence path")
    root = args.root.resolve()
    catalog_path = root / "assets/quizipedia/catalog.json"
    catalog_bytes = catalog_path.read_bytes()
    catalog = json.loads(catalog_bytes.decode("utf-8"))
    entries = catalog.get("landmarks", [])
    if len(entries) != EXPECTED_COUNT:
        raise SystemExit(f"expected {EXPECTED_COUNT} landmarks, got {len(entries)}")

    asset_dir = (root / "assets/quizipedia").resolve()
    rows: list[dict] = []
    seen: set[Path] = set()
    for entry in entries:
        original = (root / entry["image_asset"]).resolve()
        thumb = (root / entry["thumbnail_asset"]).resolve()
        if not original.is_file() or not thumb.is_file():
            raise SystemExit(f"missing pair for {entry.get('id')}")
        if asset_dir not in original.parents or asset_dir not in thumb.parents:
            raise SystemExit("pair escapes the quizipedia asset directory")
        if thumb in seen:
            raise SystemExit(f"duplicate thumbnail path: {thumb}")
        seen.add(thumb)
        before = {"sha256": sha256(thumb), "bytes": thumb.stat().st_size, "dimensions": dimensions(thumb)}
        original_sha = sha256(original)
        original_bytes = original.stat().st_size
        original_dims = dimensions(original)

        with Image.open(original) as source:
            image = ImageOps.exif_transpose(source)
            image.load()
            if image.width > MAX_EDGE or image.height > MAX_EDGE:
                image.thumbnail((MAX_EDGE, MAX_EDGE), Image.Resampling.LANCZOS)
            # Keep alpha where present; RGB/RGBA avoids palette or CMYK output.
            if "A" in image.getbands():
                image = image.convert("RGBA")
            else:
                image = image.convert("RGB")
            tmp = thumb.with_name(thumb.name + ".tmp")
            image.save(tmp, format="WEBP", quality=QUALITY, method=METHOD)
        tmp.replace(thumb)

        after = {"sha256": sha256(thumb), "bytes": thumb.stat().st_size, "dimensions": dimensions(thumb)}
        if after["dimensions"][0] > MAX_EDGE or after["dimensions"][1] > MAX_EDGE:
            raise SystemExit(f"thumbnail exceeds bound: {thumb}")
        if after["dimensions"][0] > original_dims[0] or after["dimensions"][1] > original_dims[1]:
            raise SystemExit(f"thumbnail upscaled beyond original: {thumb}")
        rows.append({
            "id": entry["id"],
            "original": {"path": entry["image_asset"], "sha256": original_sha, "bytes": original_bytes, "dimensions": original_dims},
            "thumbnail": {"path": entry["thumbnail_asset"], "before": before, "after": after},
        })

    manifest = {
        "schema": "qm-landmark-thumbnail-regeneration/v1",
        "generated_at_utc": datetime.now(timezone.utc).isoformat(),
        "catalog": {"path": "next/apps/quiz_app/assets/quizipedia/catalog.json", "sha256": hashlib.sha256(catalog_bytes).hexdigest(), "bytes": len(catalog_bytes)},
        "policy": {"count": EXPECTED_COUNT, "max_edge": MAX_EDGE, "never_upscale": True, "webp_quality": QUALITY, "webp_method": METHOD, "orientation": "Pillow ImageOps.exif_transpose"},
        "tool": {"python": platform.python_version(), "pillow": PILLOW_VERSION},
        "items": rows,
        "totals": {"count": len(rows), "old_bytes": sum(x["thumbnail"]["before"]["bytes"] for x in rows), "new_bytes": sum(x["thumbnail"]["after"]["bytes"] for x in rows)},
    }
    args.manifest.parent.mkdir(parents=True, exist_ok=True)
    args.manifest.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(manifest["totals"], ensure_ascii=False, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
