"""Create the immutable, readable source snapshot required before books60 work."""
import argparse
import hashlib
import json
from pathlib import Path

root = Path(__file__).parent
target = root / "accepted30-reconstituted-snapshot.json"
parser = argparse.ArgumentParser()
parser.add_argument("--check", action="store_true")
parser.add_argument("--reconstitute", action="store_true")
args = parser.parse_args()
if args.check:
    data = json.loads(target.read_text(encoding="utf-8"))
    assert data["question_count"] == len(data["questions"]) == 30
    print("PASS: reconstituted snapshot has exactly 30 records; --check is read-only.")
elif args.reconstitute:
    if target.exists(): raise SystemExit("refusing to overwrite existing reconstituted snapshot")
    classic = json.loads((root / "legacy-classic.json").read_text(encoding="utf-8"))["questions"][:15]
    modern = json.loads((root / "legacy-modern.json").read_text(encoding="utf-8"))["questions"][:15]
    snapshot = {"schema":"preparation-books-reconstituted30/v1", "historical_byte_proof":False,
                "questions":classic + modern, "question_count":30}
    target.write_text(json.dumps(snapshot, ensure_ascii=False, indent=2)+"\n", encoding="utf-8")
    print("WROTE: reconstituted 30-record snapshot; this is not proof of historical bytes.")
else:
    raise SystemExit("use --check or --reconstitute; accepted30-snapshot.json is never overwritten")
