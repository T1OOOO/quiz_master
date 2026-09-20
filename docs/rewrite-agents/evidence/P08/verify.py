"""Local P08 evidence: independent P04 canonical/hash/mapping verification.

Run from the repository root: python -B docs/rewrite-agents/evidence/P08/verify.py
No network, Git, database or services. Temporary CLI outputs are scoped here.
"""
from __future__ import annotations

import hashlib
import json
import os
from pathlib import Path
import subprocess
import tempfile
import time
import unicodedata

ROOT = Path(__file__).resolve().parents[4]
EVIDENCE = Path(__file__).resolve().parent
PACK = ROOT / "next/content/home-alone-1-part-1"
SOURCE = "quizzes/Cinema/HomeAlone/home_alone_1_part_1.json"
EXPECTED_CONTRACT = "5cc3275eb90dc71d58a5dc5d42be0fece52b727ead2bdf6ad9e7727a30df5f4e"
checks = []


def canonical(value):
    return json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(",", ":")).encode("utf-8")


def digest(value):
    return hashlib.sha256(canonical(value)).hexdigest()


def file_hash(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def load(path):
    return json.loads(path.read_text(encoding="utf-8"))


def command(args, expected=0):
    start = time.monotonic()
    result = subprocess.run(args, cwd=ROOT, capture_output=True, text=True, encoding="utf-8")
    checks.append({"command": args, "cwd": str(ROOT), "duration_seconds": round(time.monotonic()-start, 3),
                   "exit": result.returncode, "expected_exit": expected,
                   "stdout": result.stdout, "stderr": result.stderr})
    if result.returncode != expected:
        raise AssertionError(f"command failed: {args}, exit {result.returncode}: {result.stdout} {result.stderr}")
    return result.stdout


def verify_pack(directory):
    source = load(ROOT / SOURCE)
    draft = load(directory / "draft.json")
    manifest = load(directory / "manifest.json")
    bundle = load(directory / "bundle.json")
    assert file_hash(ROOT / SOURCE) == manifest["source_sha256"] == "2521e37a1187064c977dcbd8f1001b38f94016e26689333b214a07e1a0950439"
    assert manifest["source_path"] == SOURCE
    assert manifest["source_quiz_id"] == source["id"]
    assert manifest["canonical_quiz_id"] == draft["quiz_id"]
    for key in ("title", "category", "description"):
        assert manifest[f"source_{key}"] == source[key]
    assert len(source["questions"]) == len(draft["questions"]) == len(manifest["questions"]) == len(bundle["private_grading"]) == 25
    assert len({q["source_id"] for q in manifest["questions"]}) == 25
    assert len({q["question_id"] for q in draft["questions"]}) == 25
    revisions = {}
    for original, question, mapping, public in zip(source["questions"], draft["questions"], manifest["questions"], bundle["quiz"]["questions"], strict=True):
        assert mapping["source_id"] == original["id"]
        assert question["question_id"] == mapping["canonical_id"] == original["id"].replace("_", "-")
        assert question["stem"] == original["text"]
        assert mapping["source_explanation"] == original["explanation"]
        assert len(mapping["options"]) == len(original["options"]) == len(question["options"])
        for i, (option, option_map) in enumerate(zip(question["options"], mapping["options"], strict=True)):
            assert option["text"] == original["options"][i]
            assert option_map == {"source_index": i, "canonical_id": option["option_id"]}
        selected_id = question["options"][original["correct_answer"]]["option_id"]
        assert question["grading"] == {"correct_option_id": selected_id}
        assert bundle["private_grading"][question["question_id"]] == question["grading"]
        assert public == {k: v for k, v in question.items() if k != "grading"} | {"quiz_id": draft["quiz_id"]}
        revisions[question["question_id"]] = digest({k: v for k, v in question.items() if k != "revision"})
        assert revisions[question["question_id"]] == question["revision"]["sha256"]
    draft_hash = digest({k: v for k, v in draft.items() if k != "revision"})
    bundle_hash = digest({k: v for k, v in bundle.items() if k != "bundle_sha256"})
    assert draft_hash == draft["revision"]["sha256"] == bundle["quiz"]["revision"]["sha256"]
    assert bundle_hash == bundle["bundle_sha256"]
    for name in ("draft.json", "manifest.json", "bundle.json"):
        assert (directory / name).read_bytes() == canonical(load(directory / name)) + b"\n"
    return {"source_questions": 25, "canonical_questions": 25, "private_grading_entries": 25,
            "question_mappings": 25, "option_mappings": sum(len(q["options"]) for q in manifest["questions"]),
            "nonzero_source_answers": sum(q["correct_answer"] != 0 for q in source["questions"]),
            "source_sha256": manifest["source_sha256"], "draft_revision_sha256": draft_hash,
            "bundle_sha256": bundle_hash, "question_revision_sha256": revisions,
            "artifact_file_sha256": {name: file_hash(directory / name) for name in ("draft.json", "manifest.json", "bundle.json")}}


def main():
    command(["go", "test", "./..."])
    command(["go", "vet", "./next/server/..."])
    focused = command(["go", "test", "-count=1", "-json", "./next/server/internal/content", "./next/server/cmd/quizctl"])
    events = [json.loads(line) for line in focused.splitlines()]
    test_count = sum(e.get("Action") == "pass" and bool(e.get("Test")) for e in events)
    contract = json.loads(command(["python", "-B", "next/contracts/quiz-contract/v1/check_contract.py"]))
    assert contract["content_hash"] == EXPECTED_CONTRACT
    vectors = load(ROOT / "next/server/internal/content/testdata/normalization.json")
    for vector in vectors:
        assert " ".join(unicodedata.normalize("NFC", vector["input"]).casefold().split()) == vector["expected"]
    pack_evidence = verify_pack(PACK)
    with tempfile.TemporaryDirectory(prefix="p08-", dir=EVIDENCE) as temporary:
        temp = Path(temporary)
        exe = temp / ("quizctl.exe" if os.name == "nt" else "quizctl")
        command(["go", "build", "-o", str(exe), "./next/server/cmd/quizctl"])
        for name in ("one", "two"):
            directory = temp / name
            command([str(exe), "import", "--in", SOURCE, "--out", str(directory)])
            command([str(exe), "validate", "--in", str(directory / "draft.json")])
            command([str(exe), "build", "--in", str(directory / "draft.json"), "--out", str(directory / "bundle.json"), "--version", "2026.09.20.p08", "--published-at", "2026-09-20T10:00:00Z"])
            command([str(exe), "validate", "--in", str(directory / "bundle.json")])
            assert verify_pack(directory) == pack_evidence
        for artifact in ("draft.json", "manifest.json", "bundle.json"):
            assert (temp / "one" / artifact).read_bytes() == (temp / "two" / artifact).read_bytes() == (PACK / artifact).read_bytes()
        identical = command([str(exe), "diff", "--before", str(temp / "one/bundle.json"), "--after", str(temp / "two/bundle.json")])
        assert identical.strip() == "no changes"
        # Mutate/re-hash independently of the Go implementation, without dumping keys.
        draft = load(temp / "two/draft.json")
        q = draft["questions"][0]
        q["stem"] += " (controlled mutation)"
        q["revision"]["number"] += 1
        q["revision"]["sha256"] = digest({k: v for k, v in q.items() if k != "revision"})
        draft["revision"]["number"] += 1
        draft["revision"]["sha256"] = digest({k: v for k, v in draft.items() if k != "revision"})
        (temp / "mutation.json").write_bytes(canonical(draft) + b"\n")
        command([str(exe), "build", "--in", str(temp / "mutation.json"), "--out", str(temp / "changed.json"), "--version", "2026.09.20.p08", "--published-at", "2026-09-20T10:00:00Z"])
        changed = command([str(exe), "diff", "--before", str(temp / "one/bundle.json"), "--after", str(temp / "changed.json")], 1)
        assert "question changed: q-ha1-p1-1" in changed
        for secret in ("correct_option_id", "private_grading", "Кевин", "controlled mutation"):
            assert secret not in changed
    scope = [ROOT / "go.mod", ROOT / "go.sum"]
    for directory in ("next/server/internal/content", "next/server/cmd/quizctl", "next/content", "docs/rewrite-agents/evidence/P08"):
        scope.extend(p for p in (ROOT / directory).rglob("*") if p.is_file() and p.name != "checks.json")
    report = ROOT / "docs/rewrite-agents/reports/P08.md"
    if report.exists(): scope.append(report)
    hashes = {p.relative_to(ROOT).as_posix(): file_hash(p) for p in sorted(scope)}
    output = {"status": "PASS", "cwd": str(ROOT), "commands": checks, "test_pass_events": test_count,
              "normalization_vectors": len(vectors), "python_unicode_version": unicodedata.unidata_version,
              "contract_content_hash": contract["content_hash"], "real_pack": pack_evidence,
              "byte_identity": ["run-one", "run-two", "checked-in"], "diff_identical": identical,
              "diff_changed": changed, "scoped_file_sha256": hashes}
    (EVIDENCE / "checks.json").write_text(json.dumps(output, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({k: v for k, v in output.items() if k not in ("commands", "scoped_file_sha256")}, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
