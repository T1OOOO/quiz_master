#!/usr/bin/env python3
"""Validate a reviewed local package; remote preparation requires --prepare.

Preparation uploads the frozen archive and runs only cutover.sh prepare. Image,
backup and rehearsal hashes are outputs for a later execution review.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import re
import subprocess
import tarfile
from pathlib import Path, PurePosixPath
from typing import Any

import prepare_music_craft_release as producer

BUILD_ID = "quiz-2026.10.13-music-craft-f79555e"
SOURCE_COMMIT = producer.FROZEN_COMMIT
KEY = "C:/Users/Alexey_Matvienko/.ssh/ll_deploy_ed25519"
TARGET = "root@192.3.164.184"


def fail(message: str) -> None:
    raise RuntimeError(message)


def load(path: Path) -> dict[str, Any]:
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        fail(f"expected object: {path}")
    return value


def sha(path: Path) -> str:
    return producer.sha256_file(path)


def require_actual_acceptance(record: dict[str, Any]) -> None:
    """Require the saved actual independent Hub response, never a status stub."""
    if record.get("actual_hub_state") != "ACCEPTED":
        fail("actual independent Hub acceptance is required")
    callbacks = list(record.get("actual_reviews", {}).values())
    if isinstance(record.get("actual_review"), dict):
        callbacks.append(record["actual_review"])
    for callback in callbacks:
        call = callback.get("call", {})
        arguments = call.get("arguments", {})
        response = callback.get("actual_response", {})
        if (call.get("action") == "review" and arguments.get("verdict") == "accept"
                and response.get("state") == "ACCEPTED"
                and response.get("id") == arguments.get("task_id")
                and response.get("reviewer") and response.get("assignee")
                and response["reviewer"] != response["assignee"]):
            return
    fail("saved successful independent review callback is missing")


def check_source(repo: Path) -> None:
    subprocess.run(["git", "-C", str(repo), "merge-base", "--is-ancestor", SOURCE_COMMIT, "HEAD"], check=True)
    for revisions in ((SOURCE_COMMIT, "HEAD"), (SOURCE_COMMIT,)):
        changed = subprocess.check_output(["git", "-C", str(repo), "diff", "--name-only", *revisions, "--", "next", "quizzes", "metadata", "study/question_articles"], text=True)
        if changed.strip():
            fail("runtime source changed after the frozen release commit")
    for relative, expected in producer.FROZEN_MUSIC_FILES.items():
        if sha(repo / relative) != expected or hashlib.sha256(producer.git_bytes(repo, SOURCE_COMMIT, relative)).hexdigest() != expected:
            fail(f"frozen source mismatch: {relative}")


def validate_package(release_dir: Path) -> tuple[dict[str, Any], Path]:
    package = load(release_dir / "package-current.json")
    metadata = package.get("metadata", {})
    if (package.get("status") != "PREPARED_NOT_EXECUTED" or package.get("build_id") != BUILD_ID
            or package.get("frozen_commit") != SOURCE_COMMIT or metadata.get("buildId") != BUILD_ID
            or metadata.get("commit") != SOURCE_COMMIT or metadata.get("source_commit") != SOURCE_COMMIT
            or metadata.get("main_dart_js_sha256") != producer.PRODUCTION_JS_SHA256
            or {k: metadata.get(k) for k in ("packs", "questions", "question_articles")} != {"packs":133,"questions":4052,"question_articles":252}):
        fail("package source/build/count pins differ")
    baseline = package.get("baseline_input", {})
    if baseline.get("archive_sha256") != producer.BASELINE_ARCHIVE_SHA256 or baseline.get("image") != producer.BASELINE_IMAGE or baseline.get("pvc_uid") != producer.PVC_UID:
        fail("package baseline identity differs")
    stage, archive = Path(package["stage"]), Path(package["archive"])
    if stage.name != BUILD_ID or sha(archive) != package.get("archive_sha256"):
        fail("package archive identity differs")
    if sha(stage / "checksums.txt") != package.get("manifest_sha256"):
        fail("package manifest differs")
    expected: dict[str, str] = {}
    for line in (stage / "checksums.txt").read_text().splitlines():
        digest, relative = line.split("  ", 1)
        pure = PurePosixPath(relative)
        if pure.is_absolute() or ".." in pure.parts or "\\" in relative or relative in expected or not re.fullmatch(r"[a-f0-9]{64}", digest):
            fail("unsafe checksum manifest")
        expected[relative] = digest
        if sha(stage / relative) != digest:
            fail(f"staged package changed: {relative}")
    files = {p.relative_to(stage).as_posix() for p in stage.rglob("*") if p.is_file()}
    if files != set(expected) | {"checksums.txt"}:
        fail("stage file set differs from manifest")
    with tarfile.open(archive) as tar:
        archive_files = set()
        for member in tar.getmembers():
            pure = PurePosixPath(member.name)
            if not member.isfile() or pure.is_absolute() or ".." in pure.parts or "\\" in member.name or pure.parts[0] != BUILD_ID:
                fail("unsafe package archive")
            relative = PurePosixPath(*pure.parts[1:]).as_posix()
            if relative in archive_files or relative not in files:
                fail("duplicate/unexpected archive member")
            archive_files.add(relative)
            payload = tar.extractfile(member)
            if payload is None or hashlib.sha256(payload.read()).hexdigest() != sha(stage / relative):
                fail("archive/stage content mismatch")
        if archive_files != files:
            fail("archive file set differs from stage")
    for relative, expected_hash in (("api",producer.API_SHA256), ("nginx.conf",producer.NGINX_CONFIG_SHA256), ("web/main.dart.js",producer.PRODUCTION_JS_SHA256), ("web/assets/assets/catalog.json",producer.FROZEN_CATALOG_SHA256), ("web/assets/assets/study/question-articles.json",producer.FROZEN_READER_SHA256)):
        if sha(stage / relative) != expected_hash:
            fail(f"package binary/assets differ: {relative}")
    producer.verify_music_raw_parity(stage)
    check_source(Path("C:/ap/quiz_master"))
    return package, stage


def reviewed_package(release_dir: Path) -> tuple[dict[str, Any], Path]:
    package, stage = validate_package(release_dir)
    review = load(release_dir / "static-review.json")
    require_actual_acceptance(review)
    worker = Path(__file__).parent
    for key, path in (("producer_sha256",worker/"prepare_music_craft_release.py"), ("prepare_controller_sha256",Path(__file__)), ("publisher_controller_sha256",worker/"publish_prepared.py"), ("browser_evidence_sha256",release_dir/"browser-proof.json"), ("root_browser_evidence_sha256",release_dir/"root-local-browser-verification.json")):
        if review.get(key) != sha(path):
            fail(f"independent review does not bind {key}")
    if review.get("package_sha256") != package["archive_sha256"]:
        fail("independent review does not bind package")
    qa = load(release_dir / "browser-proof.json")
    if not (qa.get("frozen_source", {}).get("git_revision") == SOURCE_COMMIT
            and qa.get("actual_clean_ui_answers") == 4 and qa.get("actual_clean_server_score") == 4
            and qa.get("new_article_sheets_opened_closed") == 4 and qa.get("source_controls_each") == [2,2,2,2]
            and qa.get("clean_qa_flow_actual_exit") == 0 and qa.get("clean_sdk2_stop_acknowledged")
            and qa.get("fixture_processes_gone_verified") and qa.get("feedback_submissions") == 0
            and qa.get("ports18090_18093_free")):
        fail("clean local browser and fixture lifecycle proof is required")
    root_qa = load(release_dir / "root-local-browser-verification.json")
    if not (root_qa.get("actual_frozen_source") == SOURCE_COMMIT and root_qa.get("root_visually_inspected_all_four_questions_four_source_footers_score4") and root_qa.get("native_artifact_hashes_verified")):
        fail("actual Root browser verification is required")
    return package, stage


def remote_scripts(package: dict[str, Any]) -> tuple[str, str]:
    b, digest = BUILD_ID, package["archive_sha256"]
    guard = f'''set -euo pipefail
test "$(hostname)" = racknerd-f0269d5
test "$(readlink -f /opt/quiz-master/releases)" = /opt/quiz-master/releases
test "$(kubectl get deploy quiz-master -n quiz-master -o jsonpath='{{.spec.template.spec.containers[0].image}}')" = {producer.BASELINE_IMAGE}
test "$(kubectl get pvc quiz-data -n quiz-master -o jsonpath='{{.metadata.uid}}')" = {producer.PVC_UID}
test ! -e /opt/quiz-master/releases/{b}
test ! -e /opt/quiz-master/releases/{b}.tar.gz
test "$(df --output=avail -B1 /opt/quiz-master | tail -1)" -gt 4000000000
'''
    script = guard.replace(f'test ! -e /opt/quiz-master/releases/{b}.tar.gz\n', '')
    script += f'''exec 8>/opt/quiz-master/DEPLOY.lock
flock -n 8
test "$(kubectl get deploy quiz-master -n quiz-master -o jsonpath='{{.spec.template.spec.containers[0].image}}')" = {producer.BASELINE_IMAGE}
test "$(kubectl get pvc quiz-data -n quiz-master -o jsonpath='{{.metadata.uid}}')" = {producer.PVC_UID}
echo '{digest}  /opt/quiz-master/releases/{b}.tar.gz' | sha256sum -c -
mkdir /opt/quiz-master/releases/{b}
test "$(readlink -f /opt/quiz-master/releases/{b})" = /opt/quiz-master/releases/{b}
tar -xzf /opt/quiz-master/releases/{b}.tar.gz --no-same-owner --strip-components=1 -C /opt/quiz-master/releases/{b}
cd /opt/quiz-master/releases/{b}
sha256sum -c checksums.txt > candidate-checksums.log
bash -n cutover.sh
python3 -c 'from pathlib import Path; compile(Path("rehearse.py").read_text(), "rehearse.py", "exec")'
flock -u 8
exec 8>&-
bash cutover.sh prepare 2>&1 | tee prepare.log
'''
    if "helm upgrade" in script:
        fail("preparation must not publish")
    return guard, script


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--release-dir", required=True, type=Path)
    parser.add_argument("--prepare", action="store_true")
    args = parser.parse_args()
    package, _ = reviewed_package(args.release_dir)
    guard, script = remote_scripts(package)
    if not args.prepare:
        print(json.dumps({"status":"PREVIEW_ONLY", "build_id":BUILD_ID, "remote_script_sha256":hashlib.sha256(script.encode()).hexdigest()}))
        return
    # Only the release lead runs this after actual code/package/QA acceptance.
    result = subprocess.run(["ssh","-i",KEY,TARGET,"bash -s"], input=guard.encode(), stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=40)
    if result.returncode:
        fail(f"remote guards failed: exit {result.returncode}")
    subprocess.run(["scp","-i",KEY,package["archive"],TARGET+":/opt/quiz-master/releases/"+BUILD_ID+".tar.gz"],check=True,timeout=90)
    result = subprocess.run(["ssh","-i",KEY,TARGET,"bash -s"],input=script.encode(),stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=600)
    (args.release_dir/"remote-prepare-script.sh").write_bytes(script.encode())
    (args.release_dir/"remote-prepare-log.txt").write_bytes(result.stdout)
    producer.write_json_lf(args.release_dir/"remote-prepare-exit.json",{"actual_exit":result.returncode})
    print(result.stdout.decode("utf-8","replace"),end="")
    if result.returncode:
        fail("preparation failed; retain artifacts and logs, do not publish")


if __name__ == "__main__":
    main()
