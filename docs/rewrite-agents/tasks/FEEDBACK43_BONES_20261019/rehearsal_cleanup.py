#!/usr/bin/env python3
"""Guarded cleanup of disposable rehearsal outputs from two published release stages.

Run on the pinned Linux host.  Inventory is read-only.  ``--execute`` obtains
DEPLOY.lock, performs a fresh inventory, and removes only the fourteen literal
paths declared in TARGETS.  It never removes images, backups, receipts, web,
API, chart, manifests, or a release directory.
"""
from __future__ import annotations

import argparse
try:  # The executable path is Linux-only; tests also import this guard on Windows.
    import fcntl
except ModuleNotFoundError:  # pragma: no cover - exercised by Windows import only
    fcntl = None
import json
import os
from pathlib import Path
import socket
import stat
import subprocess
import urllib.request
from typing import Any, Callable

HOST = "racknerd-f0269d5"
NAMESPACE = "quiz-master"
RELEASE = "quiz-master"
RELEASE_ROOT = Path("/opt/quiz-master/releases")
BACKUP_ROOT = Path("/opt/quiz-master/backups")
LOCK_PATH = "/opt/quiz-master/DEPLOY.lock"
PVC_UID = "7fc2428f-4146-4c78-a26d-2347d9f3b7bf"
IMAGEFS = "/var/lib/rancher/k3s/agent/containerd"
CURRENT_BUILD = "quiz-2026.10.19-books-8954b166"
CURRENT_IMAGE = (
    "quiz-master:quiz-2026.10.19-books-8954b166@"
    "sha256:dd7166c8690a2009f6b6fa5ae6b8145f6328c93fd0b8e1d450cbe9de83b4ef13"
)
CURRENT_API_SHA256 = "208ac3638f5d7bd3e081b2f042b0afcf222c95a4b1af5e139286e45a3e6f22aa"

# These are the only paths that --execute can remove, exactly once each.
TARGETS: dict[str, str] = {
    "quiz-2026.10.19-feedback-5df1d538": "sha256:ea1d2e9049f87f777df9b5b226dba5391aff4050bfd66c28690259d04b668561",
    "quiz-2026.10.19-books-8954b166": "sha256:dd7166c8690a2009f6b6fa5ae6b8145f6328c93fd0b8e1d450cbe9de83b4ef13",
}
DISPOSABLE_TYPES = {
    "base.api": "file",
    "new.api": "file",
    "base-quizzes": "dir",
    "candidate-quizzes": "dir",
    "restore-proof.sqlite": "file",
    "publish-restore-proof.sqlite": "file",
    "rehearsal-data": "dir",
}
PRESERVED_NAMES = (
    "web", "api", "chart", "release-inputs.json", "prepared-receipt.json", "reviewed-receipt.json",
)


class GuardError(RuntimeError):
    pass


def run(*args: str) -> str:
    return subprocess.check_output(args, text=True)


def data(*args: str) -> Any:
    return json.loads(run(*args))


def assert_regular(path: Path, label: str) -> None:
    try:
        info = path.lstat()
    except FileNotFoundError as error:
        raise GuardError(f"required {label} is missing: {path}") from error
    if path.is_symlink() or not stat.S_ISREG(info.st_mode):
        raise GuardError(f"required {label} is not a regular non-symlink file: {path}")


def assert_owned_stage(path: Path, release_root: Path = RELEASE_ROOT) -> None:
    expected = release_root / path.name
    try:
        resolved = path.resolve(strict=True)
    except FileNotFoundError as error:
        raise GuardError(f"release stage is missing: {path}") from error
    if path != expected or resolved != expected or path.is_symlink():
        raise GuardError(f"release stage has an unexpected path or symlink: {path}")
    info = path.lstat()
    if not stat.S_ISDIR(info.st_mode) or (info.st_uid, info.st_gid, stat.S_IMODE(info.st_mode)) != (0, 0, 0o700):
        raise GuardError(f"release stage must be root:root mode 700: {path}")


def assert_no_symlink_tree(path: Path) -> None:
    for root, dirs, files in os.walk(path, followlinks=False):
        here = Path(root)
        if here.is_symlink():
            raise GuardError(f"symlink in disposable tree: {here}")
        for name in dirs + files:
            child = here / name
            if child.is_symlink():
                raise GuardError(f"symlink in disposable tree: {child}")


def assert_exact_target(path: Path, expected_type: str, release_root: Path = RELEASE_ROOT) -> None:
    if path.parent.parent != release_root or path.parent.name not in TARGETS or path.name not in DISPOSABLE_TYPES:
        raise GuardError(f"path is not an approved disposable target: {path}")
    if DISPOSABLE_TYPES[path.name] != expected_type:
        raise GuardError(f"wrong approved target type requested: {path}")
    try:
        info = path.lstat()
    except FileNotFoundError as error:
        raise GuardError(f"disposable target is missing: {path}") from error
    if path.is_symlink():
        raise GuardError(f"disposable target is a symlink: {path}")
    if expected_type == "file" and not stat.S_ISREG(info.st_mode):
        raise GuardError(f"disposable target must be a regular file: {path}")
    if expected_type == "dir":
        if not stat.S_ISDIR(info.st_mode):
            raise GuardError(f"disposable target must be a directory: {path}")
        assert_no_symlink_tree(path)


def public_health() -> None:
    with urllib.request.urlopen("https://quiz.kotopedia.org/version.json", timeout=30) as response:
        version = json.load(response)
    if version.get("buildId") != CURRENT_BUILD or version.get("api_sha256") != CURRENT_API_SHA256:
        raise GuardError("public version is not the pinned books baseline")
    with urllib.request.urlopen("https://quiz.kotopedia.org/health/ready", timeout=30) as response:
        if response.status != 200:
            raise GuardError("public ready health check failed")


def state() -> dict[str, Any]:
    if socket.gethostname() != HOST:
        raise GuardError("cleanup must run on the pinned production host")
    deploy = data("kubectl", "get", "deploy", RELEASE, "-n", NAMESPACE, "-o", "json")
    if deploy.get("metadata", {}).get("annotations", {}).get("deployment.kubernetes.io/revision") != "66":
        raise GuardError("deployment revision is not the pinned baseline")
    template = deploy.get("spec", {}).get("template", {})
    if template.get("metadata", {}).get("annotations", {}).get("quiz-master/build-id") != CURRENT_BUILD:
        raise GuardError("deployment build is not the pinned books baseline")
    containers = template.get("spec", {}).get("containers", [])
    if {item.get("name") for item in containers} != {"api", "web"} or any(item.get("image") != CURRENT_IMAGE for item in containers):
        raise GuardError("deployment images are not the pinned books baseline")
    if run("kubectl", "get", "pvc", "quiz-data", "-n", NAMESPACE, "-o", "jsonpath={.metadata.uid}") != PVC_UID:
        raise GuardError("PVC identity differs")
    history = data("helm", "history", RELEASE, "-n", NAMESPACE, "-o", "json")
    revisions = {item.get("revision") for item in history}
    if not history or history[-1].get("revision") != 68 or history[-1].get("status") != "deployed" or not {67, 68} <= revisions:
        raise GuardError("Helm history does not retain the expected baseline and rollback")
    nodes = data("kubectl", "get", "nodes", "-o", "json").get("items", [])
    if len(nodes) != 1:
        raise GuardError("expected exactly one production node")
    node = nodes[0]
    conditions = {item.get("type"): item.get("status") for item in node.get("status", {}).get("conditions", [])}
    if conditions.get("Ready") != "True" or conditions.get("DiskPressure") != "False" or node.get("spec", {}).get("unschedulable"):
        raise GuardError("node is not ready for guarded cleanup")
    if any(item.get("effect") in {"NoSchedule", "NoExecute"} for item in node.get("spec", {}).get("taints", [])):
        raise GuardError("node has a blocking scheduling taint")
    fs = os.statvfs(IMAGEFS)
    if fs.f_blocks <= 0 or fs.f_bavail * 5 < fs.f_blocks:
        raise GuardError("image filesystem is below 20 percent available")
    public_health()
    return {
        "build_id": CURRENT_BUILD,
        "helm_revision": 68,
        "deployment_revision": 66,
        "imagefs_available_percent": 100 * fs.f_bavail / fs.f_blocks,
        "available_bytes": fs.f_bavail * fs.f_frsize,
    }


def assert_receipts(stage: Path, build: str, digest: str) -> None:
    expected = {"build_id": build, "image": f"quiz-master:{build}@{digest}"}
    prepared_path, reviewed_path = stage / "prepared-receipt.json", stage / "reviewed-receipt.json"
    assert_regular(prepared_path, "prepared receipt")
    assert_regular(reviewed_path, "reviewed receipt")
    try:
        prepared = json.loads(prepared_path.read_text(encoding="utf-8"))
        reviewed = json.loads(reviewed_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as error:
        raise GuardError(f"receipt is invalid JSON in {stage}") from error
    if prepared != reviewed or any(prepared.get(key) != value for key, value in expected.items()):
        raise GuardError(f"receipt does not pin approved published image: {stage}")
    input_hash = prepared.get("input_sha256")
    if not isinstance(input_hash, str) or len(input_hash) != 64 or any(char not in "0123456789abcdef" for char in input_hash):
        raise GuardError(f"receipt lacks a SHA-256 input binding: {stage}")


def assert_backup(build: str, backup_root: Path = BACKUP_ROOT) -> None:
    backup = backup_root / f"{build}.sqlite"
    assert_regular(backup, "retained release backup")
    if run("sqlite3", str(backup), "pragma integrity_check").strip() != "ok":
        raise GuardError(f"retained release backup integrity check failed: {backup}")


def assert_no_active_stage_reference(stages: list[Path]) -> None:
    paths = [str(path) for path in stages]
    docker_ids = run("docker", "ps", "-aq").split()
    docker = data("docker", "inspect", *docker_ids) if docker_ids else []
    cri = data("k3s", "crictl", "ps", "-a", "-o", "json")
    cri_ids = [item.get("id") for item in cri.get("containers", []) if isinstance(item.get("id"), str)]
    cri_details = [data("k3s", "crictl", "inspect", "-o", "json", identifier) for identifier in cri_ids]
    # Traverse values without printing container configuration or environment.
    def strings(value: Any):
        if isinstance(value, str):
            yield value
        elif isinstance(value, dict):
            for child in value.values():
                yield from strings(child)
        elif isinstance(value, list):
            for child in value:
                yield from strings(child)
    active_values = tuple(strings({"docker": docker, "cri": cri_details}))
    if any(path in value for path in paths for value in active_values):
        raise GuardError("active Docker or CRI container references a target stage")


def inventory(release_root: Path = RELEASE_ROOT, backup_root: Path = BACKUP_ROOT) -> dict[str, Any]:
    before = state()
    stages = [release_root / build for build in TARGETS]
    assert_no_active_stage_reference(stages)
    result: dict[str, Any] = {**before, "stages": []}
    for build, digest in TARGETS.items():
        stage = release_root / build
        assert_owned_stage(stage, release_root)
        assert_receipts(stage, build, digest)
        assert_backup(build, backup_root)
        preserved: dict[str, str] = {}
        for name in PRESERVED_NAMES:
            preserved_path = stage / name
            assert_regular(preserved_path, f"preserved {name}") if name.endswith(".json") or name == "api" else None
            if not preserved_path.exists() or preserved_path.is_symlink():
                raise GuardError(f"preserved release input is missing or a symlink: {preserved_path}")
            preserved[name] = "present"
        disposable = []
        for name, kind in DISPOSABLE_TYPES.items():
            target = stage / name
            assert_exact_target(target, kind, release_root)
            disposable.append({"path": str(target), "type": kind, "bytes": target.stat().st_size if kind == "file" else sum(p.stat().st_size for p in target.rglob("*") if p.is_file())})
        result["stages"].append({"build_id": build, "path": str(stage), "receipt_digest": digest, "preserved": preserved, "disposable": disposable})
    return result


def remove_target(path: Path, kind: str, release_root: Path = RELEASE_ROOT) -> None:
    assert_exact_target(path, kind, release_root)
    if kind == "file":
        path.unlink()
    else:
        # The directory itself is a literal target.  All descendants were checked for symlinks.
        import shutil
        shutil.rmtree(path)


def execute() -> None:
    if fcntl is None:
        raise GuardError("--execute requires Linux fcntl locking")
    with open(LOCK_PATH, "a", encoding="utf-8") as lock:
        fcntl.flock(lock.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
        before = inventory()
        for stage in before["stages"]:
            for target in stage["disposable"]:
                remove_target(Path(target["path"]), target["type"])
        after = state()
        for build in TARGETS:
            stage = RELEASE_ROOT / build
            assert_owned_stage(stage)
            assert_receipts(stage, build, TARGETS[build])
            assert_backup(build)
            if any((stage / name).exists() for name in DISPOSABLE_TYPES):
                raise GuardError("a literal disposable target remains after cleanup")
        after.update({"removed_paths": 14, "available_bytes_before": before["available_bytes"], "recovered_bytes": after["available_bytes"] - before["available_bytes"]})
        print(json.dumps(after, sort_keys=True))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--execute", action="store_true")
    args = parser.parse_args()
    if args.execute:
        execute()
    else:
        print(json.dumps(inventory(), sort_keys=True))
