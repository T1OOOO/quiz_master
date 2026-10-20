#!/usr/bin/env python3
"""Guarded, web/API executor for the ATLAS_MOBILE_20261020 production release.

It is inert unless both --execute and --acknowledge-production are supplied.
Default mode is local planning; execute mode is for an authorized publication.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import re
import shlex
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any

HOST = "racknerd-f0269d5"
HOST_IP = "192.3.164.184"
NAMESPACE = "quiz-master"
RELEASE = "quiz-master"
BASE_REVISION = "76"
BASE_DEPLOYMENT_REVISION = "74"
BASE_BUILD_ID = "quiz-2026.10.20-touch-b5863403"
BASE_IMAGE = 'quiz-master:quiz-2026.10.20-touch-b5863403@sha256:343caae195b9d79085dacbd92aa2f9dec37dcf7fca91c6b5aa61efc12a4995b0'
BASE_DIGEST = "sha256:343caae195b9d79085dacbd92aa2f9dec37dcf7fca91c6b5aa61efc12a4995b0"
BASE_LOCAL_TAG = f"quiz-master:{BASE_BUILD_ID}"
API_SHA256 = "e2884077520a274a753cab0eff58c663aed159fd723c24e2b8f1e234c75539e4"
PVC_UID = "7fc2428f-4146-4c78-a26d-2347d9f3b7bf"
DB_PATH = (
    "/var/lib/rancher/k3s/storage/"
    "pvc-7fc2428f-4146-4c78-a26d-2347d9f3b7bf_quiz-master_quiz-data/quiz.db"
)
LOCK_PATH = "/opt/quiz-master/DEPLOY.lock"
RELEASE_PARENT = "/opt/quiz-master/releases"
BACKUP_PARENT = "/opt/quiz-master/backups"
MIN_FIXED_HEADROOM = 512 * 1024 * 1024
K3S_IMAGEFS = "/var/lib/rancher/k3s/agent/containerd"
BUILD_RE = re.compile(r"^quiz-[a-z0-9][a-z0-9.-]{5,100}$")
EXPECTED_MUTATED = frozenset()
SUPPORT = ("volatile_checks.py", "rehearse.py", "pool-materialization-evidence.json", "import20-evidence.json", "import18-evidence.json", "planets-acceptance.json", "games-acceptance.json", "harrypotter-acceptance.json", "animal-extras-acceptance.json")
PRIVATE_DRAFTS = ("feedback43-planets-extra-20261019.json", "feedback43-games-extra-20261019.json", "feedback43-harrypotter-extra-20261019.json", "feedback43-animal-extras-20261019.json")
CATALOG_BANDS = frozenset({"easy", "medium", "hard", "nightmare", "unknown"})

FRONTEND_DOCKERFILE = f"""ARG BASE_IMAGE={BASE_LOCAL_TAG}
FROM ${{BASE_IMAGE}}
USER 0:0
COPY --chown=10001:10001 web-delta/ /usr/share/nginx/html/
USER 10001:10001
"""
DOCKERFILE = FRONTEND_DOCKERFILE
BASE_API_SHA256 = API_SHA256


class GuardError(RuntimeError):
    pass


def validate_node_status(node: dict[str, Any]) -> None:
    conditions = {item.get("type"): item.get("status") for item in node.get("status", {}).get("conditions", [])}
    if conditions.get("Ready") != "True" or conditions.get("DiskPressure") != "False":
        raise GuardError("node must be Ready=True and DiskPressure=False")
    if node.get("spec", {}).get("unschedulable", False):
        raise GuardError("node is cordoned")
    if any(item.get("effect") in {"NoSchedule", "NoExecute"} for item in node.get("spec", {}).get("taints", [])):
        raise GuardError("node has a blocking scheduling taint")


def validate_imagefs_blocks(f_bavail: int, f_blocks: int) -> None:
    if f_blocks <= 0 or f_bavail < 0 or f_bavail * 5 < f_blocks:
        raise GuardError("k3s image filesystem has less than 20% available blocks")


@dataclass(frozen=True)
class Inputs:
    package: Path
    web: Path
    chart: Path
    version: Path
    manifest: dict[str, Any]


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for block in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def hash_tree(root: Path) -> dict[str, str]:
    if not root.is_dir():
        raise GuardError(f"required directory missing: {root}")
    result: dict[str, str] = {}
    for path in sorted(root.rglob("*")):
        if path.is_symlink():
            raise GuardError(f"symlink is forbidden in release input: {path}")
        if path.is_file():
            result[path.relative_to(root).as_posix()] = sha256_file(path)
    if not result:
        raise GuardError(f"required directory is empty: {root}")
    return result


def validate_build_id(build_id: str) -> None:
    if not BUILD_RE.fullmatch(build_id):
        raise GuardError("build ID must be a lowercase immutable quiz-* tag")
    if build_id == BASE_BUILD_ID:
        raise GuardError("the baseline build ID cannot be reused")


def validate_existing_image_digest(digest: str | None) -> str:
    if not isinstance(digest, str) or not re.fullmatch(r"[0-9a-f]{64}", digest):
        raise GuardError("resume-prepare requires a 64-character lowercase existing image digest")
    return digest


def validate_ssh_target(target: str) -> None:
    if target not in {HOST, f"root@{HOST}", HOST_IP, f"root@{HOST_IP}"}:
        raise GuardError("SSH target must be the pinned production hostname or IP")


def validate_identity_file(identity_file: Path | None) -> Path:
    if identity_file is None or not identity_file.is_file():
        raise GuardError("--execute requires an existing explicit SSH identity file")
    return identity_file.resolve()


def read_preflight(path: Path) -> None:
    text = path.read_text(encoding="utf-8")
    decoder, objects, position = json.JSONDecoder(), [], 0
    while position < len(text):
        while position < len(text) and text[position].isspace():
            position += 1
        if position == len(text):
            break
        item, position = decoder.raw_decode(text, position)
        objects.append(item)
    if len(objects) != 2:
        raise GuardError("preflight must contain exactly deployment and version JSON")
    deployment, version = objects
    if deployment.get("hostname") != HOST or str(deployment.get("revision")) != BASE_REVISION:
        raise GuardError("preflight hostname or Helm revision differs")
    containers = deployment.get("containers")
    if not isinstance(containers, list) or {item.get("name") for item in containers} != {"api", "web"}:
        raise GuardError("preflight must name exactly api and web containers")
    if any(item.get("image") != BASE_IMAGE for item in containers):
        raise GuardError("preflight image is not the pinned immutable baseline")
    if deployment.get("deployment_revision") != BASE_DEPLOYMENT_REVISION:
        raise GuardError("preflight Deployment revision differs from its separate pin")
    if deployment.get("pvc_uid") != PVC_UID:
        raise GuardError("preflight PVC identity differs")
    if deployment.get("disk", {}).get("free", 0) <= 0:
        raise GuardError("preflight requires measured free space")
    if version.get("api_sha256") != API_SHA256:
        raise GuardError("preflight API hash differs")
    if version.get("buildId") != BASE_BUILD_ID:
        raise GuardError("preflight baseline build differs")


def validate_quiz_closure(closure: dict[str, Any], candidate: dict[str, str]) -> None:
    base = closure.get("base")
    if not isinstance(base, dict) or len(base) != 165 or closure.get("candidate") != candidate or closure.get("expected_mutated") != []:
        raise GuardError("quiz closure lock is incomplete")
    if base != candidate:
        raise GuardError("frontend-only candidate changed a quiz source byte")



NEW_WEB_PATHS = frozenset(['assets/assets/quizipedia/landmark_thumbnails.json', 'assets/assets/quizipedia/waterways.json'])


def validate_web_delta(base: dict[str,str], candidate: dict[str,str], delta: dict[str,str]) -> None:
    added = set(candidate) - set(base)
    if set(base) - set(candidate) or added - NEW_WEB_PATHS:
        raise GuardError("delta release can only add the2 reviewed water and preview bundles and cannot remove paths")
    expected = {name: digest for name,digest in candidate.items() if base.get(name) != digest}
    if not expected or expected != delta:
        raise GuardError("web delta must contain exactly all changed bytes")


def validate_catalog(path: Path) -> None:
    try:
        rows = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise GuardError("catalog.json must be valid JSON") from error
    if not isinstance(rows, list) or len(rows) != 105:
        raise GuardError("catalog must contain exactly 105 banks")
    ids: set[str] = set()
    total = 0
    for row in rows:
        if not isinstance(row, dict) or not isinstance(row.get("quiz_id"), str) or not row["quiz_id"] or row["quiz_id"] in ids:
            raise GuardError("catalog quiz IDs must be unique non-empty strings")
        count, difficulties = row.get("questions_count"), row.get("difficulty_counts")
        if type(count) is not int or count < 20 or not isinstance(difficulties, dict) or set(difficulties) != CATALOG_BANDS:
            raise GuardError("catalog bank violates the minimum-20 difficulty contract")
        if any(type(value) is not int or value < 0 for value in difficulties.values()) or sum(difficulties.values()) != count:
            raise GuardError("catalog difficulty counts are invalid")
        ids.add(row["quiz_id"]); total += count
    if total != 4520:
        raise GuardError("catalog must contain exactly 4520 question slots")


def staged_web_manifest(full_web: dict[str, str]) -> dict[str, str]:
    # Article rehearsal scans every JSON. All other bytes are checked inside the
    # resulting image against the complete frozen web manifest, not re-staged.
    return {name: digest for name, digest in full_web.items() if name.endswith(".json")}


def collect_inputs(package: Path) -> Inputs:
    package = package.resolve(); web, chart, quizzes, private = package / "web", package / "chart", package / "quizzes", package / "private"; version = web / "version.json"; api = package / "api"
    required = (version, chart / "Chart.yaml", api, package / "base-web-manifest.json", package / "catalog.json", package / "quiz-closure.json", *(package / name for name in SUPPORT))
    if any(not item.is_file() or item.is_symlink() for item in required): raise GuardError("package is missing a required non-symlink input")
    if api.read_bytes()[:4] != b"\x7fELF": raise GuardError("candidate API must be Linux ELF")
    target_api = sha256_file(api)
    if target_api != API_SHA256: raise GuardError("frontend-only API must equal deployed baseline")
    data = json.loads(version.read_text(encoding="utf-8"))
    if (data.get("api_sha256") != target_api or data.get("packs") != 105 or data.get("questions") != 4520 or data.get("quizipedia_facts") != 13678 or data.get("question_articles") != 305 or data.get("question_article_references") != 241 or data.get("frontend_only") is not True): raise GuardError("candidate version contract differs")
    flags = list((web / "flags").glob("*.png"))
    if len(flags) != 195 or any(not flag.read_bytes().startswith(b"\x89PNG\r\n\x1a\n") or flag.name != sha256_file(flag) + ".png" for flag in flags): raise GuardError("195 content-addressed PNG flags required")
    validate_catalog(package / "catalog.json")
    candidate = hash_tree(quizzes); validate_quiz_closure(json.loads((package / "quiz-closure.json").read_text(encoding="utf-8")), candidate)
    if private.is_symlink() or (private / "quizzes").is_symlink():
        raise GuardError("private release input must not be a symlink")
    private_tree = hash_tree(private)
    if hash_tree(private / "quizzes") != candidate:
        raise GuardError("private/quizzes must exactly match the candidate quiz tree")
    expected_private = {f"quizzes/{path}" for path in candidate} | {f"study/drafts/{name}" for name in PRIVATE_DRAFTS}
    if set(private_tree) != expected_private:
        raise GuardError("private release input must contain only the candidate quizzes and four reviewed drafts")
    validate_web_delta(json.loads((package / "base-web-manifest.json").read_text()), hash_tree(web), hash_tree(package / "web-delta"))
    manifest = {"web_delta":hash_tree(package / "web-delta"),"base_web_manifest_sha256":sha256_file(package / "base-web-manifest.json"), "baseline":{"deployed_image":BASE_IMAGE,"local_image":BASE_LOCAL_TAG,"api_sha256":API_SHA256,"revision":BASE_REVISION}, "target_api_sha256":target_api, "web":hash_tree(web), "staged_web":staged_web_manifest(hash_tree(web)), "chart":hash_tree(chart), "quizzes":candidate, "private":private_tree, "catalog_sha256":sha256_file(package / "catalog.json"), "quiz_closure_sha256":sha256_file(package / "quiz-closure.json"), "support":{name:sha256_file(package / name) for name in SUPPORT}, "version_sha256":sha256_file(version), "dockerfile_sha256":hashlib.sha256(FRONTEND_DOCKERFILE.encode()).hexdigest()}
    return Inputs(package, web, chart, version, manifest)

def validate_package_identity(inputs: Inputs, build_id: str) -> None:
    version = json.loads(inputs.version.read_text(encoding="utf-8"))
    if version.get("buildId") != build_id:
        raise GuardError("web/version.json buildId differs from requested release tag")
    if version.get("api_sha256") != sha256_file(inputs.package / "api"):
        raise GuardError("web/version.json API hash differs from candidate binary")
    if not re.fullmatch(r"[0-9a-f]{40}", str(version.get("source_commit", ""))):
        raise GuardError("web/version.json source_commit must be a 40-character lowercase SHA")
    main_js = inputs.web / "main.dart.js"
    if not main_js.is_file() or version.get("main_dart_js_sha256") != sha256_file(main_js):
        raise GuardError("web/version.json main.dart.js hash does not match package bytes")


def write_local_manifest(inputs: Inputs) -> Path:
    path = inputs.package / "release-inputs.json"
    if path.exists():
        raise GuardError("refusing to overwrite an existing release input manifest")
    with path.open("w", encoding="utf-8", newline="\n") as destination:
        destination.write(json.dumps(inputs.manifest, sort_keys=True, indent=2) + "\n")
    return path


def remote_stage_script(build_id: str) -> str:
    """Create one fresh private remote directory and unpack a checked archive."""
    stage = f"{RELEASE_PARENT}/{build_id}"
    return f"""set -euo pipefail
umask 077
test "$(hostname)" = {shlex.quote(HOST)}
exec 9>{shlex.quote(LOCK_PATH)}
flock -n 9
node=$(kubectl get nodes -o jsonpath='{{.items[0].metadata.name}}')
kubectl get node "$node" -o json | python3 -c 'import json,sys; n=json.load(sys.stdin); c=dict((x["type"],x["status"]) for x in n["status"].get("conditions",[])); assert c.get("Ready")=="True" and c.get("DiskPressure")=="False"; assert not n["spec"].get("unschedulable",False); assert not any(t.get("effect") in ("NoSchedule","NoExecute") for t in n["spec"].get("taints",[]))'
python3 - <<'PY'
import os
s=os.statvfs({K3S_IMAGEFS!r}); assert s.f_bavail * 5 >= s.f_blocks
PY
stage={shlex.quote(stage)}
test ! -e "$stage"
mkdir -m 700 "$stage"
trap 'rm -rf -- "$stage"' ERR
tar -xf - -C "$stage" --no-same-owner --no-same-permissions
"""


def remote_script(build_id: str, target_api_sha256: str, phase: str,
                  existing_image_digest: str | None = None, input_manifest_sha256: str | None = None) -> str:
    """Return the only remote mutation path. Values are fixed or regex-guarded."""
    if not re.fullmatch(r"[0-9a-f]{64}", target_api_sha256):
        raise GuardError("invalid target API hash")
    if phase not in {"prepare", "resume-prepare", "publish"}:
        raise GuardError("release phase must be prepare, resume-prepare, or publish")
    resume_prepare = phase == "resume-prepare"
    if resume_prepare:
        existing_image_digest = validate_existing_image_digest(existing_image_digest)
    elif existing_image_digest is not None:
        raise GuardError("--existing-image-digest is only valid with resume-prepare")
    if resume_prepare:
        if not isinstance(input_manifest_sha256, str) or not re.fullmatch(r"[0-9a-f]{64}", input_manifest_sha256):
            raise GuardError("resume-prepare requires a 64-character release input manifest hash")
    elif input_manifest_sha256 is not None:
        raise GuardError("release input manifest hash is only valid with resume-prepare")
    tag = f"quiz-master:{build_id}"
    stage = f"{RELEASE_PARENT}/{build_id}"
    backup = f"{BACKUP_PARENT}/{build_id}.sqlite"
    base_quizzes = "resume-base-quizzes" if resume_prepare else "base-quizzes"
    candidate_quizzes = "resume-candidate-quizzes" if resume_prepare else "candidate-quizzes"
    restore_proof = "volatile-checks/" + ("resume-restore-proof.sqlite" if resume_prepare else "restore-proof.sqlite")
    rehearsal_data = "volatile-checks/" + ("resume-rehearsal-data" if resume_prepare else "rehearsal-data")
    closure_report = "resume-quiz-source-closure.json" if resume_prepare else "quiz-source-closure.json"
    resume_workdir_guard = "\n".join(f'test ! -e "$stage/{name}"' for name in (base_quizzes, candidate_quizzes, restore_proof, rehearsal_data, closure_report)) if resume_prepare else ""
    backup_guard = 'test ! -e "$backup"' if phase == "prepare" else ('test -f "$backup"\ntest "$(sqlite3 "$backup" \'pragma integrity_check\')" = ok' if resume_prepare else '')
    image_prepare = f'if docker image inspect "$tag" >/dev/null 2>&1; then echo \'release tag already exists\' >&2; exit 1; fi\nnode_guard\ndocker build --network=none --pull=false --build-arg BASE_IMAGE="$base_local" -t "$tag" "$stage"\ndocker run --rm --network=none --read-only --tmpfs /tmp "$tag" nginx -t\nnew_docker_id=$(docker image inspect "$tag" --format \'{{{{.Id}}}}\')\n[[ "$new_docker_id" =~ ^sha256:[0-9a-f]{{64}}$ ]]'
    if resume_prepare:
        image_prepare = f'test "$(docker image inspect "$tag" --format \'{{{{.Id}}}}\')" = {shlex.quote("sha256:" + existing_image_digest)}\nnew_docker_id=$(docker image inspect "$tag" --format \'{{{{.Id}}}}\')\n[[ "$new_docker_id" =~ ^sha256:[0-9a-f]{{64}}$ ]]\ndocker run --rm --network=none --read-only --tmpfs /tmp "$tag" nginx -t'
    return f"""#!/usr/bin/env bash
set -Eeuo pipefail
umask 077
build={shlex.quote(build_id)}
stage={shlex.quote(stage)}
backup={shlex.quote(backup)}
tag={shlex.quote(tag)}
base_deployed={shlex.quote(BASE_IMAGE)}
base_local={shlex.quote(BASE_LOCAL_TAG)}
lock={shlex.quote(LOCK_PATH)}
db={shlex.quote(DB_PATH)}
phase={shlex.quote(phase)}
input_manifest_sha256={shlex.quote(input_manifest_sha256)}
node_guard() {{
 curl -fsS --connect-timeout 10 --max-time 30 https://quiz.kotopedia.org/health/ready >/dev/null
 node=$(kubectl get nodes -o jsonpath='{{.items[0].metadata.name}}')
 kubectl get node "$node" -o json | python3 -c 'import json,sys; n=json.load(sys.stdin); c=dict((x["type"],x["status"]) for x in n["status"].get("conditions",[])); assert c.get("Ready")=="True" and c.get("DiskPressure")=="False"; assert not n["spec"].get("unschedulable",False); assert not any(t.get("effect") in ("NoSchedule","NoExecute") for t in n["spec"].get("taints",[]))'
 python3 -c 'import os; s=os.statvfs("/var/lib/rancher/k3s/agent/containerd"); assert s.f_bavail * 5 >= s.f_blocks'
 kubectl get --raw "/api/v1/nodes/$node/proxy/configz" | python3 -c 'import json,sys; c=json.load(sys.stdin).get("kubeletconfig",dict()); print(dict((x,c.get(x)) for x in ("evictionHard","evictionMinimumReclaim","imageGCHighThresholdPercent","imageGCLowThresholdPercent")))'
}}
test \"$(hostname)\" = {shlex.quote(HOST)}
exec 9>\"$lock\"
flock -n 9
test -d \"$stage\"
if [ \"$phase\" = resume-prepare ]; then
 test -f \"$stage/release-inputs.json\"
 test \"$(sha256sum \"$stage/release-inputs.json\" | awk '{{print $1}}')\" = \"$input_manifest_sha256\"
fi
node_guard
{backup_guard}
test -f \"$db\"
test \"$(helm history {RELEASE} -n {NAMESPACE} -o json | python3 -c 'import json,sys; h=json.load(sys.stdin); print(h[-1][\"revision\"])')\" = {shlex.quote(BASE_REVISION)}
test \"$(kubectl get deploy {RELEASE} -n {NAMESPACE} -o jsonpath='{{.metadata.annotations.deployment\\.kubernetes\\.io/revision}}')\" = {shlex.quote(BASE_DEPLOYMENT_REVISION)}
test \"$(kubectl get pvc quiz-data -n {NAMESPACE} -o jsonpath='{{.metadata.uid}}')\" = {shlex.quote(PVC_UID)}
images=$(kubectl get deploy {RELEASE} -n {NAMESPACE} -o jsonpath='{{range .spec.template.spec.containers[*]}}{{.image}}{{"\\n"}}{{end}}')
test \"$images\" = \"$(printf '%s\\n%s' \"$base_deployed\" \"$base_deployed\")\"
current_build=$(kubectl get deploy {RELEASE} -n {NAMESPACE} -o jsonpath='{{.spec.template.metadata.annotations.quiz-master\\/build-id}}')
test \"$current_build\" = {shlex.quote(BASE_BUILD_ID)}
test -f \"$stage/release-inputs.json\"
python3 - \"$stage\" <<'PY'
import hashlib,json,pathlib,sys
root=pathlib.Path(sys.argv[1]); expected=json.loads((root/'release-inputs.json').read_text())
def tree(name):
 out={{}}
 for p in sorted((root/name).rglob('*')):
  if p.is_symlink(): raise SystemExit('symlink in input')
  if p.is_file(): out[p.relative_to(root/name).as_posix()]=hashlib.sha256(p.read_bytes()).hexdigest()
 return out
private=tree('private')
if tree('private/quizzes') != tree('quizzes'): raise SystemExit('private/quizzes differs from candidate quiz tree')
actual={{'web_delta':tree('web-delta'),'base_web_manifest_sha256':hashlib.sha256((root/'base-web-manifest.json').read_bytes()).hexdigest(),'baseline':{{'deployed_image':{BASE_IMAGE!r},'local_image':{BASE_LOCAL_TAG!r},'api_sha256':{API_SHA256!r},'revision':{BASE_REVISION!r}}}, 'target_api_sha256':{API_SHA256!r},'web':expected['web'],'staged_web':tree('web'),'chart':tree('chart'), 'quizzes':tree('quizzes'),'private':private,'catalog_sha256':hashlib.sha256((root/'catalog.json').read_bytes()).hexdigest(),'quiz_closure_sha256':hashlib.sha256((root/'quiz-closure.json').read_bytes()).hexdigest(),'support':{{name:hashlib.sha256((root/name).read_bytes()).hexdigest() for name in {SUPPORT!r}}}, 'version_sha256':hashlib.sha256((root/'web/version.json').read_bytes()).hexdigest(), 'dockerfile_sha256':hashlib.sha256((root/'Dockerfile').read_bytes()).hexdigest()}}
if actual != expected: raise SystemExit('release input checksum mismatch')
if expected['staged_web'] != {{name:digest for name,digest in expected['web'].items() if name.endswith('.json')}}: raise SystemExit('staged web is not the exact JSON subset')
json.load(open(root/'web/version.json'))
PY
cleanup_volatile() {{ python3 \"$stage/volatile_checks.py\" unmount --stage \"$stage\" --build-id \"$build\"; }}
trap cleanup_volatile EXIT
if [ \"$phase\" = prepare ] || [ \"$phase\" = resume-prepare ]; then
{resume_workdir_guard}
web_bytes=$(du -sb \"$stage/web\" | awk '{{print $1}}')
db_bytes=$(stat -c %s \"$db\")
base_image_bytes=$(docker image inspect \"$base_local\" --format '{{{{.Size}}}}')
free_bytes=$(df -B1 --output=avail /opt | tail -1 | tr -d ' ')
# Package/archive, three image copies, backup/restore proof and fixed headroom.
required_bytes=$((web_bytes * 2 + base_image_bytes * 3 + db_bytes * 2 + {MIN_FIXED_HEADROOM}))
test \"$free_bytes\" -ge \"$required_bytes\"
base_docker_id=$(docker image inspect \"$base_local\" --format '{{{{.Id}}}}')
test \"$base_docker_id\" = {shlex.quote(BASE_DIGEST)}
[[ \"$base_docker_id\" =~ ^sha256:[0-9a-f]{{64}}$ ]]
base_api=$(docker create \"$base_local\")
new_api=''
rehearsal=''
cleanup() {{ if [ -n \"$rehearsal\" ]; then docker logs \"$rehearsal\" > \"$stage/rehearsal-startup.log\" 2>&1 || true; fi; docker rm -f \"$base_api\" ${{new_api:+\"$new_api\"}} ${{rehearsal:+\"$rehearsal\"}} >/dev/null 2>&1 || true; cleanup_volatile; }}
trap cleanup EXIT
docker cp \"$base_api:/app/api\" - | tar -xOf - api | sha256sum | awk '{{print $1}}' > \"$stage/base-api-sha256.txt\"
docker cp \"$base_api:/etc/nginx/nginx.conf\" \"$stage/base.nginx.conf\"
test \"$(cat \"$stage/base-api-sha256.txt\")\" = {shlex.quote(API_SHA256)}
{image_prepare}
new_api=$(docker create \"$tag\")
docker cp \"$new_api:/app/api\" - | tar -xOf - api | sha256sum | awk '{{print $1}}' > \"$stage/new-api-sha256.txt\"
docker cp \"$new_api:/etc/nginx/nginx.conf\" \"$stage/new.nginx.conf\"
test \"$(cat \"$stage/new-api-sha256.txt\")\" = {shlex.quote(target_api_sha256)}
test \"$(cat \"$stage/new-api-sha256.txt\")\" = {shlex.quote(API_SHA256)}
docker run --rm --network=none --read-only --entrypoint /bin/busybox \"$tag\" find /usr/share/nginx/html -type f -exec /bin/busybox sha256sum '{{}}' + > \"$stage/image-web-sha256.txt\"
python3 - \"$stage\" <<'PY'
import json,pathlib,sys
root=pathlib.Path(sys.argv[1]); expected=json.load(open(root/'release-inputs.json'))['web']; actual={{}}
for line in (root/'image-web-sha256.txt').read_text().splitlines():
 digest,path=line.split(None,1); actual[str(pathlib.PurePosixPath(path).relative_to('/usr/share/nginx/html'))]=digest
if actual != expected: raise SystemExit('resulting image web closure differs')
json.dump(dict(files=len(actual),all_web_bytes_match=True),open(root/'image-web-closure.json','w'))
PY
cmp -s \"$stage/base.nginx.conf\" \"$stage/new.nginx.conf\"
docker cp \"$base_api:/app/quizzes\" \"$stage/{base_quizzes}\"
docker cp \"$new_api:/app/quizzes\" \"$stage/{candidate_quizzes}\"
python3 - \"$stage\" <<'PY'
import hashlib,json,pathlib,sys
root=pathlib.Path(sys.argv[1])
def tree(folder):
 result=dict()
 for p in (root/folder).rglob('*'):
  if p.is_symlink(): raise SystemExit('symlink in image quiz source')
  if p.is_file(): result[p.relative_to(root/folder).as_posix()]=hashlib.sha256(p.read_bytes()).hexdigest()
 return result
base=tree({base_quizzes!r}); candidate=tree({candidate_quizzes!r}); lock=json.load(open(root/'quiz-closure.json'))
if base != lock.get('base') or candidate != lock.get('candidate'): raise SystemExit('candidate image/source lock differs')
expected=set(lock.get('expected_mutated',()))
if len(base)!=165 or base!=candidate or expected: raise SystemExit('frontend-only candidate changed a quiz source byte')
json.dump(dict(original_files=len(base),candidate_files=len(candidate),approved_existing_mutations=len(expected)),open(root/{closure_report!r},'w'))
PY
python3 - \"$db\" \"$stage/feedback-before.json\" <<'PY'
import hashlib,json,sqlite3,sys
db=sqlite3.connect('file:'+sys.argv[1]+'?mode=ro',uri=True)
table='feedback_reports'
columns=[r[1] for r in db.execute('pragma table_info('+table+')')]
if 'id' not in columns: raise SystemExit('feedback_reports/id missing')
id_index=columns.index('id'); snapshot={{}}
for row in db.execute('select * from '+table+' order by id'):
 key=hashlib.sha256(str(row[id_index]).encode()).hexdigest()
 body=hashlib.sha256(repr(tuple(row)).encode()).hexdigest()
 snapshot[key]=body
json.dump(snapshot,open(sys.argv[2],'w'),sort_keys=True)
PY
python3 \"$stage/volatile_checks.py\" mount --stage \"$stage\" --build-id \"$build\"
install -d -m 700 {shlex.quote(BACKUP_PARENT)}
sqlite3 \"$db\" \".backup '$backup'\"
test \"$(sqlite3 \"$backup\" 'pragma integrity_check')\" = ok
cp --reflink=auto \"$backup\" \"$stage/{restore_proof}\"
test \"$(sqlite3 \"$stage/{restore_proof}\" 'pragma integrity_check')\" = ok
python3 \"$stage/volatile_checks.py\" record-restore --stage \"$stage\" --build-id \"$build\" --phase \"$phase\" --image-id \"$new_docker_id\" | tee \"$stage/restore-evidence.json\"
# Rehearse this exact binary against a disposable restored database copy.
install -d -m 700 \"$stage/{rehearsal_data}\"
sha256sum \"$stage/{restore_proof}\" > \"$stage/restore-proof-sha256.txt\"
mv \"$stage/{restore_proof}\" \"$stage/{rehearsal_data}/quiz.db\"
chown -R 10001:10001 \"$stage/{rehearsal_data}\"
python3 -c 'import socket; s=socket.socket(); s.bind(("127.0.0.1",18088)); s.close()'
rehearsal=$(docker run -d --network=host --cap-drop ALL --security-opt no-new-privileges --read-only --tmpfs /tmp --user 10001:10001 --entrypoint /app/api -e QM_LISTEN_ADDR=127.0.0.1:18088 -e QM_DATABASE_URL=sqlite:../data/quiz.db -e QM_CONTENT_BUNDLE_PATH=/app/quizzes -e QM_CONTENT_MANIFEST_PATH=/app/next/content/home-alone-1-part-1/manifest.json --mount type=bind,src=\"$stage/{rehearsal_data}\",dst=/data \"$tag\")
ready=0
for attempt in $(seq 1 45); do
 if docker exec \"$rehearsal\" /bin/busybox wget -q -O /dev/null http://127.0.0.1:18088/health/ready; then ready=1; break; fi
 sleep 1
done
test \"$ready\" = 1
test -f \"$stage/rehearse.py\"
python3 \"$stage/rehearse.py\" --base-url http://127.0.0.1:18088 --catalog-json \"$stage/catalog.json\" --pool-evidence \"$stage/pool-materialization-evidence.json\" --private-quizzes-root \"$stage/private\" --web-root \"$stage/web\" --require-real-http-grading --require-article-revision-binding | tee \"$stage/rehearsal-http.json\"
docker stop \"$rehearsal\" >/dev/null
test \"$(sqlite3 \"$stage/{rehearsal_data}/quiz.db\" 'pragma integrity_check')\" = ok
python3 \"$stage/volatile_checks.py\" record-rehearsal --stage \"$stage\" --build-id \"$build\" --phase \"$phase\" --image-id \"$new_docker_id\" | tee \"$stage/rehearsal-evidence.json\"
docker logs \"$rehearsal\" > \"$stage/rehearsal-startup.log\" 2>&1
docker rm \"$rehearsal\" >/dev/null
rehearsal=''
python3 \"$stage/volatile_checks.py\" unmount --stage \"$stage\" --build-id \"$build\" | tee \"$stage/prepare-unmount.json\"
node_guard
docker save \"$tag\" | k3s ctr -n k8s.io images import -
containerd_digest=$(k3s ctr -n k8s.io images ls | awk -v tag=\"$tag\" '$1==tag || $1==\"docker.io/library/\"tag {{print $3}}')
[[ \"$containerd_digest\" =~ ^sha256:[0-9a-f]{{64}}$ ]]
canonical_image=\"docker.io/library/quiz-master@$containerd_digest\"
canonical_source=\"docker.io/library/$tag\"
if ! k3s ctr -n k8s.io images ls -q | grep -Fxq \"$canonical_image\"; then
 k3s ctr -n k8s.io images tag \"$canonical_source\" \"$canonical_image\"
fi
k3s ctr -n k8s.io images ls | awk -v ref=\"$canonical_image\" -v digest=\"$containerd_digest\" '$1==ref && $3==digest {{found=1}} END{{exit !found}}'
for n in $(seq 1 10); do if k3s crictl inspecti \"$canonical_image\" > \"$stage/canonical-cri.json\"; then break; fi; sleep 1; done
k3s crictl inspecti \"$canonical_image\" > \"$stage/canonical-cri.json\"
candidate_image=\"$tag@$containerd_digest\"
# Keep the observed Docker image ID separate from the containerd descriptor.
# Docker backends may return an index ID; OCI content and CRI prove config identity separately.
printf '%s\\n' \"$base_docker_id\" > \"$stage/base-docker-config-id.txt\"
printf '%s\\n' \"$new_docker_id\" > \"$stage/new-docker-config-id.txt\"
printf '%s\\n' \"$containerd_digest\" > \"$stage/containerd-manifest-digest.txt\"
helm get values {RELEASE} -n {NAMESPACE} -a -o yaml > \"$stage/live-values.yaml\"
helm get manifest {RELEASE} -n {NAMESPACE} > \"$stage/live-manifest.yaml\"
helm template {RELEASE} \"$stage/chart\" -n {NAMESPACE} -f \"$stage/live-values.yaml\" --set-string image=\"$base_deployed\" --set-string buildId=\"$current_build\" > \"$stage/rendered-baseline.yaml\"
helm template {RELEASE} \"$stage/chart\" -n {NAMESPACE} -f \"$stage/live-values.yaml\" --set-string image=\"$candidate_image\" --set-string buildId=\"$build\" > \"$stage/rendered-target.yaml\"
python3 - \"$stage/live-manifest.yaml\" \"$stage/rendered-baseline.yaml\" \"$stage/rendered-target.yaml\" \"$base_deployed\" \"$candidate_image\" \"$current_build\" \"$build\" <<'PY'
import sys
live,baseline,target,old_image,new_image,old_build,new_build=(open(p).read() if i < 3 else p for i,p in enumerate(sys.argv[1:]))
def normalize(text,image,build):
 if text.count('image: \"'+image+'\"') != 2: raise SystemExit('expected exactly two rendered image targets')
 if text.count('quiz-master/build-id: \"'+build+'\"') != 1: raise SystemExit('expected exactly one rendered build annotation')
 return text.replace('image: \"'+image+'\"','image: \"__IMAGE__\"').replace('quiz-master/build-id: \"'+build+'\"','quiz-master/build-id: \"__BUILD__\"').strip()
if normalize(live,old_image,old_build) != normalize(baseline,old_image,old_build): raise SystemExit('chart rendering differs from live release')
if normalize(baseline,old_image,old_build) != normalize(target,new_image,new_build): raise SystemExit('render changes more than image/build annotation')
PY
helm lint --strict \"$stage/chart\" -n {NAMESPACE} -f \"$stage/live-values.yaml\"
kubectl apply --dry-run=server -n {NAMESPACE} -f \"$stage/rendered-target.yaml\"
test ! -e \"$stage/prepared-receipt.json\"
python3 - \"$stage/prepared-receipt.json\" \"$stage/release-inputs.json\" \"$candidate_image\" <<'PY'
import hashlib,json,sys
inputs=open(sys.argv[2],'rb').read()
json.dump(dict(build_id={build_id!r},input_sha256=hashlib.sha256(inputs).hexdigest(),image=sys.argv[3]),open(sys.argv[1],'w'),sort_keys=True)
PY
chmod 600 \"$stage/prepared-receipt.json\"
echo \"PREPARED receipt=$stage/prepared-receipt.json image=$candidate_image\"
exit 0
fi
test -f \"$stage/reviewed-receipt.json\"
cmp -s \"$stage/prepared-receipt.json\" \"$stage/reviewed-receipt.json\"
candidate_image=$(python3 - \"$stage/prepared-receipt.json\" <<'PY'
import json,sys
r=json.load(open(sys.argv[1])); assert r['build_id']=={build_id!r}; assert isinstance(r['image'],str) and '@sha256:' in r['image']; print(r['image'])
PY
)
candidate_digest=$(printf '%s' \"$candidate_image\" | sed 's/^.*@//')
k3s ctr -n k8s.io images ls | awk -v digest=\"$candidate_digest\" '$3==digest {{found=1}} END{{exit !found}}'
node_guard
python3 \"$stage/volatile_checks.py\" mount --stage \"$stage\" --build-id \"$build\"
new_docker_id=$(docker image inspect \"$tag\" --format '{{{{.Id}}}}')
sqlite3 \"$db\" \".backup '$backup'\"
chmod 600 \"$backup\"
test \"$(sqlite3 \"$backup\" 'pragma integrity_check')\" = ok
cp --reflink=auto \"$backup\" \"$stage/volatile-checks/publish-restore-proof.sqlite\"
test \"$(sqlite3 \"$stage/volatile-checks/publish-restore-proof.sqlite\" 'pragma integrity_check')\" = ok
python3 \"$stage/volatile_checks.py\" record-restore --stage \"$stage\" --build-id \"$build\" --phase \"$phase\" --image-id \"$new_docker_id\" | tee \"$stage/publish-restore-evidence.json\"
python3 \"$stage/volatile_checks.py\" unmount --stage \"$stage\" --build-id \"$build\" | tee \"$stage/publish-unmount.json\"
node_guard
rollback() {{ helm rollback {RELEASE} {BASE_REVISION} -n {NAMESPACE} --wait --timeout 180s; }}
if ! helm upgrade {RELEASE} \"$stage/chart\" -n {NAMESPACE} --reuse-values --set-string image=\"$candidate_image\" --set-string buildId=\"$build\" --atomic --wait --timeout 180s; then rollback; exit 1; fi
post_upgrade_err() {{ status=$?; trap - ERR; rollback || true; exit \"$status\"; }}
trap post_upgrade_err ERR
kubectl rollout status deployment/{RELEASE} -n {NAMESPACE} --timeout=180s
test \"$(kubectl get pvc quiz-data -n {NAMESPACE} -o jsonpath='{{.metadata.uid}}')\" = {shlex.quote(PVC_UID)}
post=$(kubectl get deploy {RELEASE} -n {NAMESPACE} -o jsonpath='{{range .spec.template.spec.containers[*]}}{{.image}}{{"\\n"}}{{end}}')
test \"$post\" = \"$(printf '%s\\n%s' \"$candidate_image\" \"$candidate_image\")\"
verify_public() {{
  test \"$(curl -fsS --proto '=https' --tlsv1.2 -o \"$stage/public-version.json\" -w '%{{http_code}}' https://quiz.kotopedia.org/version.json)\" = 200 || return 1
  cmp -s \"$stage/public-version.json\" \"$stage/web/version.json\" || return 1
  expected_js=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))[\"main_dart_js_sha256\"])' \"$stage/web/version.json\")
  test \"$(curl -fsS --proto '=https' --tlsv1.2 https://quiz.kotopedia.org/main.dart.js | sha256sum | awk '{{print $1}}')\" = \"$expected_js\" || return 1
  test \"$(curl -fsS --proto '=https' --tlsv1.2 -o \"$stage/public-health-ready.body\" -w '%{{http_code}}' https://quiz.kotopedia.org/health/ready)\" = 200 || return 1
  test \"$(curl -fsS --proto '=https' --tlsv1.2 -o \"$stage/public-health-live.body\" -w '%{{http_code}}' https://quiz.kotopedia.org/health/live)\" = 200 || return 1
}}
verify_public
python3 - \"$db\" \"$stage/feedback-before.json\" \"$stage/feedback-after.json\" <<'PY'
import hashlib,json,sqlite3,sys
db=sqlite3.connect('file:'+sys.argv[1]+'?mode=ro',uri=True)
columns=[r[1] for r in db.execute('pragma table_info(feedback_reports)')]
if 'id' not in columns: raise SystemExit('feedback_reports/id missing')
id_index=columns.index('id'); snapshot={{}}
for row in db.execute('select * from feedback_reports order by id'):
 key=hashlib.sha256(str(row[id_index]).encode()).hexdigest()
 snapshot[key]=hashlib.sha256(repr(tuple(row)).encode()).hexdigest()
before=json.load(open(sys.argv[2]))
if any(snapshot.get(key) != value for key,value in before.items()): raise SystemExit('original feedback row changed or missing')
json.dump(snapshot,open(sys.argv[3],'w'),sort_keys=True)
PY
"""


def plan(build_id: str, inputs: Inputs) -> dict[str, Any]:
    validate_build_id(build_id)
    validate_package_identity(inputs, build_id)
    return {
        "mode": "PLAN_ONLY",
        "host": HOST,
        "namespace": NAMESPACE,
        "baseline_revision": BASE_REVISION,
        "deployed_base_image": BASE_IMAGE,
        "local_base_image": BASE_LOCAL_TAG,
        "new_tag": f"quiz-master:{build_id}",
        "package": str(inputs.package),
        "input_manifest": inputs.manifest,
        "remote_write": False,
    }


def stage_package(target: str, identity_file: Path, build_id: str, inputs: Inputs) -> None:
    """Transfer only manifest-checked inputs after the fresh-folder guard."""
    command = f"bash -c {shlex.quote(remote_stage_script(build_id))}"
    archive = subprocess.Popen(
        ["tar", "-C", str(inputs.package), "-cf", "-", *("web/" + name for name in inputs.manifest["staged_web"]), "web-delta", "base-web-manifest.json", "chart", "quizzes", "private", "catalog.json", "quiz-closure.json", "release-inputs.json", "Dockerfile", *SUPPORT],
        stdout=subprocess.PIPE,
    )
    try:
        if archive.stdout is None:  # pragma: no cover - defensive subprocess API guard
            raise GuardError("cannot open local package archive")
        subprocess.run(["ssh", "-i", str(identity_file), "-o", "IdentitiesOnly=yes", target, command], stdin=archive.stdout, check=True)
    finally:
        if archive.stdout is not None:
            archive.stdout.close()
        if archive.wait() != 0:
            raise GuardError("local package archiving failed")


def execute(target: str, identity_file: Path | None, build_id: str, inputs: Inputs, phase: str,
            reviewed_receipt: Path | None = None, existing_image_digest: str | None = None) -> None:
    validate_ssh_target(target)
    validate_build_id(build_id)
    validate_package_identity(inputs, build_id)
    identity_file = validate_identity_file(identity_file)
    if phase not in {"prepare", "resume-prepare", "publish"}:
        raise GuardError("release phase must be prepare, resume-prepare, or publish")
    if phase == "resume-prepare":
        digest = validate_existing_image_digest(existing_image_digest)
        manifest_sha256 = hashlib.sha256(json.dumps(inputs.manifest, sort_keys=True, indent=2).encode() + b"\n").hexdigest()
        subprocess.run(["ssh", "-i", str(identity_file), "-o", "IdentitiesOnly=yes", target, "bash", "-s"],
                       input=remote_script(build_id, inputs.manifest["target_api_sha256"], phase, digest, manifest_sha256).encode(), check=True, timeout=600)
        return
    if existing_image_digest is not None:
        raise GuardError("--existing-image-digest is only valid with resume-prepare")
    dockerfile = inputs.package / "Dockerfile"
    if phase == "publish":
        if reviewed_receipt is None or not reviewed_receipt.is_file():
            raise GuardError("publish requires a reviewed immutable prepare receipt")
        receipt = json.loads(reviewed_receipt.read_text(encoding="utf-8"))
        if receipt != {"build_id": build_id, "input_sha256": hashlib.sha256(json.dumps(inputs.manifest, sort_keys=True, indent=2).encode() + b"\n").hexdigest(),
                       "image": receipt.get("image")} or not isinstance(receipt.get("image"), str):
            raise GuardError("reviewed receipt does not bind this build and inputs")
        subprocess.run(["ssh", "-i", str(validate_identity_file(identity_file)), "-o", "IdentitiesOnly=yes", target,
                        f"umask 077; cat > {shlex.quote(RELEASE_PARENT + '/' + build_id + '/reviewed-receipt.json')}"],
                       input=reviewed_receipt.read_bytes(), check=True, timeout=600)
        subprocess.run(["ssh", "-i", str(validate_identity_file(identity_file)), "-o", "IdentitiesOnly=yes", target, "bash", "-s"],
                       input=remote_script(build_id, inputs.manifest["target_api_sha256"], phase).encode(), check=True, timeout=600)
        return
    if dockerfile.exists():
        raise GuardError("refusing to overwrite package Dockerfile")
    manifest_path = write_local_manifest(inputs)
    try:
        with dockerfile.open("w", encoding="utf-8", newline="\n") as destination:
            destination.write(FRONTEND_DOCKERFILE)
        stage_package(target, identity_file, build_id, inputs)
        subprocess.run(["ssh", "-i", str(identity_file), "-o", "IdentitiesOnly=yes", target, "bash", "-s"], input=remote_script(build_id, inputs.manifest["target_api_sha256"], phase).encode(), check=True, timeout=600)
    finally:
        dockerfile.unlink(missing_ok=True)
        manifest_path.unlink(missing_ok=True)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--preflight", type=Path, required=True)
    parser.add_argument("--package", type=Path, required=True)
    parser.add_argument("--build-id", required=True)
    parser.add_argument("--ssh-target", default=HOST)
    parser.add_argument("--identity-file", type=Path)
    parser.add_argument("--plan", action="store_true")
    parser.add_argument("--execute", action="store_true")
    parser.add_argument("--acknowledge-production", action="store_true")
    parser.add_argument("--phase", choices=("prepare", "resume-prepare", "publish"), default="prepare")
    parser.add_argument("--reviewed-receipt", type=Path)
    parser.add_argument("--existing-image-digest")
    args = parser.parse_args(argv)
    read_preflight(args.preflight)
    inputs = collect_inputs(args.package)
    if args.plan or not args.execute:
        print(json.dumps(plan(args.build_id, inputs), sort_keys=True))
        return 0
    if not args.acknowledge_production:
        raise GuardError("--execute requires --acknowledge-production")
    execute(args.ssh_target, args.identity_file, args.build_id, inputs, args.phase, args.reviewed_receipt, args.existing_image_digest)
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except GuardError as error:
        print(f"GUARD: {error}", file=sys.stderr)
        raise SystemExit(2)
