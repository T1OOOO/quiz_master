#!/usr/bin/env python3
"""Publish a reviewed Film Craft v2 package only after explicit --publish.

Default and --preview modes are local, read-only validations. This controller
never builds Flutter, content, Docker images, or a release package. Its normal
mode consumes the immutable image and shell prefix prepared by the release lead.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import re
import subprocess
from pathlib import Path
from typing import Any

REPO = Path(r"C:\ap\quiz_master")
BUILD_ID = "quiz-2026.10.13-film-craft-c74253f"
SOURCE_COMMIT = "c74253fe16e7ddf50d81fd884a2606483808448d"
PUBLIC_JS_SHA256 = "646ec761865694df76d046d698f49609eee0237f95b3f558a757c7391515ba8f"
READER_SHA256 = "d06e01e33e8343951f48c7aa131a763128f216ad92bd2ab07717e4462f0870fc"
FAILED_V1_ARCHIVE_SHA256 = "e6a26225619149708c8fb2c3ac93a42cadf095efb68c9b6d9136549a20163083"
COUNTS = {"packs": 132, "questions": 4048, "question_articles": 248}


def fail(message: str) -> None:
    raise RuntimeError(message)


def load(path: Path) -> dict[str, Any]:
    if not path.is_file():
        fail(f"missing required release evidence: {path}")
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        fail(f"expected JSON object: {path}")
    return value


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def require_string(value: dict[str, Any], key: str) -> str:
    item = value.get(key)
    if not isinstance(item, str) or not item:
        fail(f"missing nonempty {key}")
    return item


def prepare(release_dir: Path) -> tuple[dict[str, Any], dict[str, Any], dict[str, Any], Path, str]:
    package = load(release_dir / "package-current.json")
    execution = load(release_dir / "execution-packet.json")
    acceptance = load(release_dir / "execution-acceptance.json")
    if package.get("status") != "PREPARED_NOT_EXECUTED":
        fail("package-current.json is not a prepared immutable package")
    metadata = package.get("metadata")
    if not isinstance(metadata, dict) or metadata.get("buildId") != BUILD_ID:
        fail("package build ID differs from the frozen Film Craft v2 target")
    if metadata.get("commit") != SOURCE_COMMIT or metadata.get("source_commit") != SOURCE_COMMIT:
        fail("package source commit differs from the frozen Film Craft source")
    if metadata.get("main_dart_js_sha256") != PUBLIC_JS_SHA256:
        fail("package JavaScript SHA differs from the reviewed production output")
    if {key: metadata.get(key) for key in COUNTS} != COUNTS:
        fail("package metadata counts differ from 132/4048/248")
    archive = Path(require_string(package, "archive"))
    archive_sha256 = require_string(package, "archive_sha256")
    if archive_sha256 == FAILED_V1_ARCHIVE_SHA256:
        fail("refusing failed v1 archive; corrected package-current.json must identify v2")
    if re.fullmatch(r"[a-f0-9]{64}", archive_sha256) is None or not archive.is_file() or sha256_file(archive) != archive_sha256:
        fail("immutable corrected archive is missing or hash-mismatched")
    if execution.get("build_id") != BUILD_ID or execution.get("source_commit") != SOURCE_COMMIT:
        fail("execution packet does not bind the frozen Film Craft build/source")
    if execution.get("package_sha256") != archive_sha256 or acceptance.get("package_sha256") != archive_sha256:
        fail("execution/acceptance packet archive hashes do not bind corrected v2")
    image = require_string(execution, "image")
    if not re.fullmatch(r"sha256:[a-f0-9]{64}", image) or acceptance.get("image") != image:
        fail("execution/acceptance packet image identity is missing or mismatched")
    if acceptance.get("actual_hub_state") != "ACCEPTED":
        fail("independent execution acceptance is required before publication")
    if sha256_file(Path(__file__)) != execution.get("publisher_controller_sha256"):
        fail("publisher source differs from the reviewed controller")
    subprocess.run(["git", "merge-base", "--is-ancestor", SOURCE_COMMIT, "HEAD"], cwd=REPO, check=True)
    for revisions in ((SOURCE_COMMIT, "HEAD"), (SOURCE_COMMIT,)):
        changed = subprocess.check_output(["git", "diff", "--name-only", *revisions, "--", "next", "quizzes", "metadata", "study/question_articles"], cwd=REPO, text=True)
        if changed.strip():
            fail("runtime source changed after the frozen release commit")
    qa_path = release_dir / "browser-proof.json"
    qa = load(qa_path)
    if sha256_file(qa_path) != execution.get("local_browser_evidence_sha256"):
        fail("local browser evidence differs from the reviewed packet")
    if not (qa.get("actual_clean_ui_answers") == 4 and qa.get("new_article_sheets_opened_closed") == 4 and qa.get("actual_clean_server_score") == 4 and qa.get("source_controls_each") == [2,2,2,2] and qa.get("clean_sdk2_actual_exit") == 0 and qa.get("clean_qa_wrapper_actual_exit") == 0 and qa.get("feedback_submissions") == 0 and qa.get("ports18090_18093_free")):
        fail("required clean local browser gates are absent")
    remote_log = release_dir / require_string(execution, "remote_log")
    if sha256_file(remote_log) != require_string(execution, "remote_log_sha256"):
        fail("prepared remote log hash differs from execution packet")
    for key in ("backup_sha256", "copied_db_rehearsal_sha256", "df_sha256", "helm_dryrun_sha256"):
        value = require_string(execution, key)
        if re.fullmatch(r"[a-f0-9]{64}", value) is None:
            fail(f"execution packet has invalid {key}")
    stage = Path(require_string(package, "stage"))
    cutover = stage / "cutover.sh"
    if not cutover.is_file():
        fail("prepared package cutover script is missing")
    shell = cutover.read_text(encoding="utf-8")
    for anchor in ("backup", "rehearse", "flock", "quiz_image=", "quiz_run="):
        if anchor not in shell:
            fail(f"prepared cutover prefix lacks required guard: {anchor}")
    split = 'quiz_image="quiz-master:$quiz_build"'
    if shell.count(split) != 1:
        fail("prepared cutover image anchor is absent or duplicated")
    prefix = shell.split(split)[0]
    if "docker build" in prefix or "flutter build" in prefix or "quizctl" in prefix:
        fail("prepared prefix attempts a rebuild")
    return package, execution, acceptance, stage, prefix


def publish_script(package: dict[str, Any], execution: dict[str, Any], stage: Path, prefix: str, *, verify_hash: bool = True) -> str:
    image = execution["image"]
    values = require_string(execution, "values")
    durable_archive = require_string(execution, "durable_archive")
    durable_archive_sha256 = require_string(execution, "durable_archive_sha256")
    if re.fullmatch(re.escape(BUILD_ID) + r"-cutover-\d{8}T\d{6}Z-values\.yaml", values) is None:
        fail("prepared values filename is outside this release")
    if durable_archive != "/var/lib/rancher/k3s/agent/images/" + BUILD_ID + ".tar":
        fail("durable image archive is outside this release")
    if re.fullmatch(r"[a-f0-9]{64}", durable_archive_sha256) is None:
        fail("invalid durable archive SHA")
    df_guard = 'test "$(df --output=avail -B1 /opt/quiz-master | tail -1)" -gt 4000000000\n'
    capacity_anchor = 'quiz_run="$quiz_build-cutover-$(date -u +%Y%m%dT%H%M%SZ)"'
    if prefix.count(capacity_anchor) != 1:
        fail("prepared cutover capacity anchor is absent or duplicated")
    prefix = prefix.replace(capacity_anchor, df_guard + capacity_anchor)
    append = f'''\nquiz_digest='{image}'
quiz_values='{values}'
echo '{durable_archive_sha256}  {durable_archive}' | sha256sum -c -
k3s ctr images ls | awk -v image="docker.io/library/quiz-master@$quiz_digest" '$1==image {{found=1}} END {{exit !found}}'
helm lint --strict chart -n quiz-master -f "$quiz_values"
helm template quiz-master chart -n quiz-master -f "$quiz_values" > "$quiz_run-publish-rendered.yaml"
test "$(grep -Fc "docker.io/library/quiz-master@$quiz_digest" "$quiz_run-publish-rendered.yaml")" -eq 2
kubectl apply --dry-run=server -n quiz-master -f "$quiz_run-publish-rendered.yaml"
helm upgrade quiz-master chart -n quiz-master -f "$quiz_values" --atomic --wait --timeout 180s
test "$(kubectl get deploy quiz-master -n quiz-master -o jsonpath='{{.spec.template.spec.containers[0].image}}')" = "docker.io/library/quiz-master@$quiz_digest"
curl -fsS https://quiz.kotopedia.org/version.json | python3 -c 'import json,sys; actual=json.load(sys.stdin); expected=json.load(open("web/version.json")); actual==expected or sys.exit("Public version mismatch"); print(actual)'
test "$(curl -fsS https://quiz.kotopedia.org/main.dart.js | sha256sum | cut -d ' ' -f 1)" = {PUBLIC_JS_SHA256}
test "$(curl -fsS https://quiz.kotopedia.org/assets/assets/study/question-articles.json | sha256sum | cut -d ' ' -f 1)" = {READER_SHA256}
'''
    script = prefix + append
    if any(token in script for token in ("docker build", "flutter build", "quizctl")):
        fail("publisher must consume the immutable image and must not rebuild")
    # The lead may render an inert review artifact before acceptance exists.
    # The CLI publication path always uses the default exact hash check.
    if verify_hash:
        expected = require_string(execution, "publish_script_sha256")
        if hashlib.sha256(script.encode("utf-8")).hexdigest() != expected:
            fail("publisher differs from the independently reviewed publish script")
    return script


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--release-dir", type=Path, required=True, help="corrected v2 release evidence directory")
    parser.add_argument("--preview", action="store_true", help="validate locally and print the reviewed script hash")
    parser.add_argument("--publish", action="store_true", help="explicitly permit remote atomic publication")
    args = parser.parse_args()
    if args.preview and args.publish:
        fail("choose only one mode")
    package, execution, _, stage, prefix = prepare(args.release_dir)
    script = publish_script(package, execution, stage, prefix)
    if args.preview:
        print(json.dumps({"status": "PREVIEW_ONLY", "build_id": BUILD_ID, "archive_sha256": package["archive_sha256"], "image": execution["image"], "publish_script_sha256": hashlib.sha256(script.encode()).hexdigest()}))
        return
    if not args.publish:
        print("Validated corrected v2 publication evidence; rerun with --preview or explicit --publish.")
        return
    # This path is intentionally not invoked by this task. It remains available
    # only for the release lead after a separate review of these exact v2 files.
    result = subprocess.run(
        ["ssh", "-i", "C:/Users/Alexey_Matvienko/.ssh/ll_deploy_ed25519", "root@192.3.164.184", "bash -s -- publish"],
        input=script.encode("utf-8"), stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=600,
    )
    print(result.stdout.decode("utf-8", errors="replace"), end="")
    if result.returncode != 0:
        fail(f"atomic publication failed with exit {result.returncode}")


if __name__ == "__main__":
    main()
