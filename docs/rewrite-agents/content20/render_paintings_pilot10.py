"""Render the blind candidate plus private key into the legacy quiz schema."""
import argparse
import json
from pathlib import Path

ROOT = Path(__file__).parent

def render():
    candidate = json.loads((ROOT / "paintings-pilot10.candidate.json").read_text(encoding="utf-8"))
    key = {item["id"]: item for item in json.loads((ROOT / "paintings-pilot10.key.json").read_text(encoding="utf-8"))["records"]}
    candidate["questions"] = [
        {**question, "correct_answer": key[question["id"]]["correct_answer"], "explanation": key[question["id"]]["explanation"]}
        for question in candidate["questions"]
    ]
    return candidate

def check(pack):
    assert set(pack) == {"id", "title", "description", "category", "questions"}
    assert len(pack["questions"]) == 10
    assert len({q["id"] for q in pack["questions"]}) == 10
    assert all(q["type"] == "choice" and len(q["options"]) == 4 for q in pack["questions"])
    assert all(0 <= q["correct_answer"] <= 3 and q["explanation"] for q in pack["questions"])
    assert all(len(set(q["options"])) == 4 and all(option.strip() for option in q["options"]) for q in pack["questions"])
    assert all(20 <= len(q["explanation"].split()) <= 45 for q in pack["questions"])

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--write", action="store_true")
    args = parser.parse_args()
    pack = render()
    check(pack)
    if args.check:
        saved = json.loads((ROOT / "paintings-pilot10.legacy.json").read_text(encoding="utf-8"))
        assert saved == pack, "Legacy file differs from candidate/key render"
        print("OK: 10 unique choice questions, distinct options, explanation lengths, saved legacy parity")
    elif args.write:
        (ROOT / "paintings-pilot10.legacy.json").write_text(
            json.dumps(pack, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
        )
        print("WROTE: paintings-pilot10.legacy.json")
    else:
        print(json.dumps(pack, ensure_ascii=False, indent=2))
