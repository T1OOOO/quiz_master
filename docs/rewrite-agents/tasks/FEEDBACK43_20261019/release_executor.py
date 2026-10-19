#!/usr/bin/env python3
"""Guarded, web/API executor for the FEEDBACK43_20261019 production release.

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
BASE_REVISION = "66"
BASE_DEPLOYMENT_REVISION = "64"
BASE_BUILD_ID = "quiz-2026.10.19-feedback-849e6705"
BASE_IMAGE = 'quiz-master:quiz-2026.10.19-feedback-849e6705@sha256:2205f76f1a7d02f91765c7fa1ca347b6db14b1ef241a03496470154664df3d43'
BASE_DIGEST = "sha256:2205f76f1a7d02f91765c7fa1ca347b6db14b1ef241a03496470154664df3d43"
BASE_LOCAL_TAG = f"quiz-master:{BASE_BUILD_ID}"
API_SHA256 = "95bca76bdf4bc8ad3dd74be44aae0cc936444fb86e74339ef793c825b74aa0f6"
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

FRONTEND_DOCKERFILE = f"""ARG BASE_IMAGE={BASE_LOCAL_TAG}
FROM ${{BASE_IMAGE}}
USER 0:0
RUN find /usr/share/nginx/html -mindepth 1 -maxdepth 1 -exec rm -rf -- {{}} +
COPY --chown=10001:10001 web/ /usr/share/nginx/html/
COPY --chown=10001:10001 --chmod=755 api /app/api
COPY --chown=10001:10001 extra-quizzes/ /app/quizzes/Preparation/GeographyRegions/
USER 10001:10001
"""


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


def collect_inputs(package: Path) -> Inputs:
    package = package.resolve()
    web, chart = package / "web", package / "chart"
    version = web / "version.json"
    if not version.is_file() or not (chart / "Chart.yaml").is_file():
        raise GuardError("package requires web/version.json and chart/Chart.yaml")
    try:
        version_json = json.loads(version.read_text(encoding="utf-8"))
    except json.JSONDecodeError as error:
        raise GuardError("web/version.json is not valid JSON") from error
    if not isinstance(version_json.get("buildId"), str):
        raise GuardError("web/version.json has no buildId")
    flags = list((web / "flags").glob("*.png"))
    if len(flags) != 195:
        raise GuardError("package must contain all 195 flag PNGs")
    for flag in flags:
        if not flag.read_bytes().startswith(b"\x89PNG\r\n\x1a\n") or flag.name != sha256_file(flag) + ".png":
            raise GuardError("invalid content-addressed flag image")
    validate_regional_quizzes(package / 'extra-quizzes')
    manifest = {
        "baseline": {
            "deployed_image": BASE_IMAGE,
            "local_image": BASE_LOCAL_TAG,
            "api_sha256": API_SHA256,
            "revision": BASE_REVISION,
        },
        "target_api_sha256": sha256_file(package / "api"),
        "web": hash_tree(web),
        "chart": hash_tree(chart),
        "extra_quizzes": hash_tree(package / 'extra-quizzes'),
        "version_sha256": sha256_file(version),
        "dockerfile_sha256": hashlib.sha256(FRONTEND_DOCKERFILE.encode()).hexdigest(),
        "rehearsal_sha256": sha256_file(Path(__file__).with_name("rehearse.py")),
    }
    return Inputs(package, web, chart, version, manifest)


def validate_regional_quizzes(path: Path) -> None:
    expected = {f'prep-{subject}-{region}' for subject in ('capitals', 'flags')
                for region in ('europe', 'africa', 'americas', 'asia-oceania')}
    files = list(path.glob('*.json'))
    if len(files) != 8 or len(list(path.iterdir())) != 8:
        raise GuardError('exactly eight regional quiz inputs required')
    found, ids = set(), set()
    totals = {'capitals': 0, 'flags': 0}
    for file in files:
        if file.is_symlink():
            raise GuardError('regional input symlink')
        value = json.loads(file.read_text(encoding='utf-8-sig'))
        quiz_id, questions = value.get('id'), value.get('questions')
        if quiz_id not in expected or quiz_id in found or not isinstance(questions, list) or len(questions) < 20:
            raise GuardError('regional quiz identity or minimum size differs')
        found.add(quiz_id)
        subject = 'capitals' if quiz_id.startswith('prep-capitals-') else 'flags'
        totals[subject] += len(questions)
        for q in questions:
            key, options, correct = q.get('id'), q.get('options'), q.get('correct_answer')
            if not isinstance(key, str) or key in ids or not isinstance(options, list) or not 4 <= len(options) <= 6 or type(correct) is not int or not 0 <= correct < len(options):
                raise GuardError('invalid regional question identity or grading key')
            ids.add(key)
    if found != expected or totals != {'capitals': 195, 'flags': 195}:
        raise GuardError('regional partition must preserve all 195 questions per subject')


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


def remote_script(build_id: str, target_api_sha256: str, phase: str) -> str:
    """Return the only remote mutation path. Values are fixed or regex-guarded."""
    if not re.fullmatch(r"[0-9a-f]{64}", target_api_sha256):
        raise GuardError("invalid target API hash")
    if phase not in {"prepare", "publish"}:
        raise GuardError("release phase must be prepare or publish")
    tag = f"quiz-master:{build_id}"
    stage = f"{RELEASE_PARENT}/{build_id}"
    backup = f"{BACKUP_PARENT}/{build_id}.sqlite"
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
node_guard
test -d \"$stage\"
if [ \"$phase\" = prepare ]; then test ! -e \"$backup\"; fi
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
actual={{'baseline':{{'deployed_image':{BASE_IMAGE!r},'local_image':{BASE_LOCAL_TAG!r},'api_sha256':{API_SHA256!r},'revision':{BASE_REVISION!r}}}, 'target_api_sha256':hashlib.sha256((root/'api').read_bytes()).hexdigest(),'web':tree('web'),'chart':tree('chart'), 'extra_quizzes':tree('extra-quizzes'), 'version_sha256':hashlib.sha256((root/'web/version.json').read_bytes()).hexdigest(), 'dockerfile_sha256':hashlib.sha256((root/'Dockerfile').read_bytes()).hexdigest(), 'rehearsal_sha256':hashlib.sha256((root/'rehearse.py').read_bytes()).hexdigest()}}
if actual != expected: raise SystemExit('release input checksum mismatch')
json.load(open(root/'web/version.json'))
PY
if [ \"$phase\" = prepare ]; then
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
cleanup() {{ if [ -n \"$rehearsal\" ]; then docker logs \"$rehearsal\" > \"$stage/rehearsal-startup.log\" 2>&1 || true; fi; docker rm -f \"$base_api\" ${{new_api:+\"$new_api\"}} ${{rehearsal:+\"$rehearsal\"}} >/dev/null 2>&1 || true; }}
trap cleanup EXIT
docker cp \"$base_api:/app/api\" \"$stage/base.api\"
docker cp \"$base_api:/etc/nginx/nginx.conf\" \"$stage/base.nginx.conf\"
test \"$(sha256sum \"$stage/base.api\" | awk '{{print $1}}')\" = {shlex.quote(API_SHA256)}
if docker image inspect \"$tag\" >/dev/null 2>&1; then echo 'release tag already exists' >&2; exit 1; fi
node_guard
docker build --network=none --pull=false --build-arg BASE_IMAGE=\"$base_local\" -t \"$tag\" \"$stage\"
docker run --rm --network=none --read-only --tmpfs /tmp \"$tag\" nginx -t
new_docker_id=$(docker image inspect \"$tag\" --format '{{{{.Id}}}}')
[[ \"$new_docker_id\" =~ ^sha256:[0-9a-f]{{64}}$ ]]
new_api=$(docker create \"$tag\")
docker cp \"$new_api:/app/api\" \"$stage/new.api\"
docker cp \"$new_api:/etc/nginx/nginx.conf\" \"$stage/new.nginx.conf\"
test \"$(sha256sum \"$stage/new.api\" | awk '{{print $1}}')\" = {shlex.quote(target_api_sha256)}
# API changes intentionally; exact candidate digest checked above.
cmp -s \"$stage/base.nginx.conf\" \"$stage/new.nginx.conf\"
docker cp \"$base_api:/app/quizzes\" \"$stage/base-quizzes\"
docker cp \"$new_api:/app/quizzes\" \"$stage/candidate-quizzes\"
python3 - \"$stage\" <<'PY'
import hashlib,json,pathlib,sys
root=pathlib.Path(sys.argv[1])
def tree(folder):
 result=dict()
 for p in (root/folder).rglob('*'):
  if p.is_symlink(): raise SystemExit('symlink in image quiz source')
  if p.is_file(): result[p.relative_to(root/folder).as_posix()]=hashlib.sha256(p.read_bytes()).hexdigest()
 return result
base=tree('base-quizzes'); added=dict(('Preparation/GeographyRegions/'+p,h) for p,h in tree('extra-quizzes').items())
if len(added)!=8 or set(base).intersection(added): raise SystemExit('regional sources must be eight new paths')
expected=dict(base); expected.update(added)
if tree('candidate-quizzes') != expected: raise SystemExit('candidate changed original quiz bytes or has unexpected source')
json.dump(dict(original_files=len(base),added_files=len(added),all_original_bytes_preserved=True),open(root/'quiz-source-closure.json','w'))
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
install -d -m 700 {shlex.quote(BACKUP_PARENT)}
sqlite3 \"$db\" \".backup '$backup'\"
test \"$(sqlite3 \"$backup\" 'pragma integrity_check')\" = ok
cp --reflink=auto \"$backup\" \"$stage/restore-proof.sqlite\"
test \"$(sqlite3 \"$stage/restore-proof.sqlite\" 'pragma integrity_check')\" = ok
# Rehearse this exact binary against a disposable restored database copy.
install -d -m 700 \"$stage/rehearsal-data\"
cp \"$stage/restore-proof.sqlite\" \"$stage/rehearsal-data/quiz.db\"
chown -R 10001:10001 \"$stage/rehearsal-data\"
python3 -c 'import socket; s=socket.socket(); s.bind(("127.0.0.1",18088)); s.close()'
rehearsal=$(docker run -d --network=host --cap-drop ALL --security-opt no-new-privileges --read-only --tmpfs /tmp --user 10001:10001 --entrypoint /app/api -e QM_LISTEN_ADDR=127.0.0.1:18088 -e QM_DATABASE_URL=sqlite:../data/quiz.db -e QM_CONTENT_BUNDLE_PATH=/app/quizzes -e QM_CONTENT_MANIFEST_PATH=/app/next/content/home-alone-1-part-1/manifest.json --mount type=bind,src=\"$stage/rehearsal-data\",dst=/data \"$tag\")
ready=0
for attempt in $(seq 1 45); do
 if docker exec \"$rehearsal\" /bin/busybox wget -q -O /dev/null http://127.0.0.1:18088/health/ready; then ready=1; break; fi
 sleep 1
done
test \"$ready\" = 1
test -f \"$stage/rehearse.py\"
python3 \"$stage/rehearse.py\" --base-url http://127.0.0.1:18088 --web-root \"$stage/web\" --require-real-http-grading --require-article-revision-binding --extra-quizzes \"$stage/extra-quizzes\"
docker stop \"$rehearsal\" >/dev/null
test \"$(sqlite3 \"$stage/rehearsal-data/quiz.db\" 'pragma integrity_check')\" = ok
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
# Docker image IDs are config digests; containerd digests are manifest descriptors.
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
sqlite3 \"$db\" \".backup '$backup'\"
chmod 600 \"$backup\"
test \"$(sqlite3 \"$backup\" 'pragma integrity_check')\" = ok
cp --reflink=auto \"$backup\" \"$stage/publish-restore-proof.sqlite\"
test \"$(sqlite3 \"$stage/publish-restore-proof.sqlite\" 'pragma integrity_check')\" = ok
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
        ["tar", "-C", str(inputs.package), "-cf", "-", "web", "chart", "extra-quizzes", "release-inputs.json", "Dockerfile", "api",
         "-C", str(Path(__file__).parent), "rehearse.py"],
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
            reviewed_receipt: Path | None = None) -> None:
    validate_ssh_target(target)
    validate_build_id(build_id)
    validate_package_identity(inputs, build_id)
    identity_file = validate_identity_file(identity_file)
    if phase not in {"prepare", "publish"}:
        raise GuardError("release phase must be prepare or publish")
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
    parser.add_argument("--phase", choices=("prepare", "publish"), default="prepare")
    parser.add_argument("--reviewed-receipt", type=Path)
    args = parser.parse_args(argv)
    read_preflight(args.preflight)
    inputs = collect_inputs(args.package)
    if args.plan or not args.execute:
        print(json.dumps(plan(args.build_id, inputs), sort_keys=True))
        return 0
    if not args.acknowledge_production:
        raise GuardError("--execute requires --acknowledge-production")
    execute(args.ssh_target, args.identity_file, args.build_id, inputs, args.phase, args.reviewed_receipt)
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except GuardError as error:
        print(f"GUARD: {error}", file=sys.stderr)
        raise SystemExit(2)
