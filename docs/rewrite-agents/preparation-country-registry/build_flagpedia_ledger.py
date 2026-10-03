"""Verify one permitted downloadable flag PNG per registry ISO2; no files are retained."""
from __future__ import annotations

import hashlib
import json
from datetime import date
from pathlib import Path
from urllib.request import Request, urlopen

ROOT = Path(__file__).parent
API_DOCS = "https://flagpedia.net/download/api"


def fetch(url: str) -> bytes:
    with urlopen(Request(url, headers={"User-Agent": "quiz-master-registry/1.0"}), timeout=30) as response:
        return response.read()


def main() -> None:
    today = date.today().isoformat()
    countries = json.loads((ROOT / "countries.json").read_text(encoding="utf-8"))["countries"]
    api_docs = fetch(API_DOCS)
    flags = []
    for country in countries:
        iso2 = country["iso2"].lower()
        uri = f"https://flagpedia.net/data/flags/w320/{iso2}.png"
        try:
            data = fetch(uri)
            verification = {"status": "fetched", "bytes": len(data), "sha256": hashlib.sha256(data).hexdigest()}
        except Exception as exc:
            verification = {"status": "failed", "error": str(exc)}
        flags.append({
            "iso2": country["iso2"], "download_uri": uri, "verified_on": today,
            "byte_verification": verification,
            "provider_permission": "Flagpedia API documentation permits programmatic downloading for use in projects; a backlink is appreciated, not required.",
            "attribution": "Flagpedia.net (source attribution; backlink appreciated by provider)",
            "variant_note": "representation review required; do not infer a universal current flag" if country["iso2"] in {"AF", "SY"} else "",
        })
    result = {
        "scope": "Optional verified downloadable media source. Original UNdata flag URLs remain in countries.json.",
        "provider_api_documentation": {"uri": API_DOCS, "accessed": today, "sha256": hashlib.sha256(api_docs).hexdigest()},
        "flags": flags,
    }
    raw_out = ROOT / "raw-fetch"
    raw_out.mkdir(exist_ok=True)
    (raw_out / "flagpedia-download-ledger.json").write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
