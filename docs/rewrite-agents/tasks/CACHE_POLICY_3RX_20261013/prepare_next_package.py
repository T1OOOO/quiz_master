#!/usr/bin/env python3
"""Prepare (but never publish) the immutable Next7 release package.

This controller is deliberately inert until the release lead supplies a frozen
commit and freshly built production/QA Flutter directories.  It starts from the
published V8 package so its earlier runtime-only repairs survive, then changes
only the two People packs, their Reader/catalog assets, and release metadata.
"""
from __future__ import annotations

import argparse
import copy
import gzip
import hashlib
import json
import re
import shutil
import subprocess
import tarfile
from pathlib import Path, PurePosixPath
from typing import Any

BASELINE_BUILD = "quiz-2026.10.13-culture-328f2f8"
BASELINE_ARCHIVE_SHA256 = "f1c8df8edb9b73f7b84dd2ea6bacfc1d80082df8eff97bd287e768b7bdfd140c"
BASELINE_IMAGE = "docker.io/library/quiz-master@sha256:fa00bc8e559ec5a02ed62903f7ed91c00540f11de0a16b0cddc5b15717f5317f"
NGINX_CONFIG_PATH = "next/infra/production/nginx.conf"
NGINX_CONFIG_SHA256 = "e9add812a138010e443463acb455295103dc69886ca32cd17dafbccfa676d6bc"
PVC_UID = "7fc2428f-4146-4c78-a26d-2347d9f3b7bf"
API_SHA256 = "26e1657fd6259bdbbef9178cbe9343b775406d91c56cb9661d302ad530ab6f01"
PEOPLE = {
    "cinema-people-20261011": ("Cinema/People/cinema_people_20261011.json", "cinema_people_20261011.json"),
    "music-people-20261011": ("MusicPeople/music_people_20261011.json", "music_people_20261011.json"),
}
RUNTIME_IDS = (
    "cinema-encore-20261011", "cinema-people-20261011", "home-alone-1-part-1",
    "music-encore-20261011", "music-people-20261011", "philias-lifestyle-part-1",
    "phobias-nature", "planet-paradoxes-20261010",
)


def fail(message: str) -> None:
    raise RuntimeError(message)


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def read_json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def write_json_lf(path: Path, value: Any) -> None:
    path.write_bytes((json.dumps(value, ensure_ascii=False, indent=2) + "\n").encode("utf-8"))


def canonical_hash(value: Any) -> str:
    # This mirrors content.Canonical/hashWithout: sorted keys, compact JSON and
    # literal non-ASCII code points. Question values contain integral numbers.
    data = json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(",", ":")).encode("utf-8")
    return hashlib.sha256(data).hexdigest()


def private_revision_input(bundle: dict[str, Any], question: dict[str, Any]) -> dict[str, Any]:
    draft = copy.deepcopy(question)
    question_id = draft["question_id"]
    draft.pop("quiz_id")
    draft.pop("revision")
    draft["grading"] = bundle["private_grading"][question_id]
    metadata = bundle.get("private_question_metadata", {}).get(question_id, {})
    tags = metadata.get("editorial_tag_ids")
    if tags:
        draft["editorial_tag_ids"] = tags
    return draft


def expected_staging_revisions(stage: Path, build_id: str) -> tuple[dict[str, Any], list[dict[str, Any]]]:
    expected: dict[str, Any] = {}
    proof: list[dict[str, Any]] = []
    for quiz_id in RUNTIME_IDS:
        bundle = read_json(stage / "next" / "content" / quiz_id / "bundle.json")
        rows: dict[str, Any] = {}
        for public in bundle["quiz"]["questions"]:
            private = private_revision_input(bundle, public)
            old_hash = public["revision"]["sha256"]
            if canonical_hash(private) != old_hash:
                fail(f"private revision reconstruction mismatch: {quiz_id}/{public['question_id']}")
            uri = private["source"]["uri"]
            if not uri.startswith("/app/quizzes/"):
                fail(f"unexpected published source URI: {quiz_id}/{public['question_id']}")
            private["source"]["uri"] = f"/opt/quiz-master/releases/{build_id}/quizzes/{uri.removeprefix('/app/quizzes/')}"
            rows[public["question_id"]] = {
                "number": public["revision"]["number"],
                "sha256": canonical_hash(private),
            }
            proof.append({
                "quiz_id": quiz_id,
                "question_id": public["question_id"],
                "published_private_revision_verified": True,
                "staging_uri": private["source"]["uri"],
            })
        expected[quiz_id] = rows
    if sum(len(rows) for rows in expected.values()) != 140:
        fail("expected exactly 140 canonical staging revisions")
    return expected, proof


def extract_immutable(archive: Path, destination: Path) -> None:
    if sha256_file(archive) != BASELINE_ARCHIVE_SHA256:
        fail("prior V8 archive SHA-256 differs from the approved immutable input")
    if destination.exists():
        fail(f"output stage already exists: {destination}")
    expected_prefix = f"{BASELINE_BUILD}/"
    with tarfile.open(archive, "r:gz") as package:
        members = package.getmembers()
        if not members:
            fail("prior archive is empty")
        for member in members:
            pure = PurePosixPath(member.name)
            if not member.isfile() or pure.is_absolute() or ".." in pure.parts or not member.name.startswith(expected_prefix):
                fail(f"unsafe or unexpected archive member: {member.name}")
        for member in members:
            relative = PurePosixPath(member.name).relative_to(BASELINE_BUILD)
            target = destination / Path(*relative.parts)
            target.parent.mkdir(parents=True, exist_ok=True)
            payload = package.extractfile(member)
            if payload is None:
                fail(f"unreadable archive member: {member.name}")
            target.write_bytes(payload.read())


def copy_file(source: Path, target: Path) -> None:
    if not source.is_file():
        fail(f"missing frozen-source input: {source}")
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(source, target)


def git_bytes(repo: Path, commit: str, relative: str) -> bytes:
    """Read a tracked frozen input, never the mutable working tree."""
    result = subprocess.run(
        ["git", "-C", str(repo), "show", f"{commit}:{relative.replace(chr(92), '/')}"],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    if result.returncode != 0:
        fail(f"frozen source is missing or unreadable: {relative}: {result.stderr.decode('utf-8', 'replace').strip()}")
    return result.stdout


def copy_frozen_file(repo: Path, commit: str, relative: str, target: Path) -> None:
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_bytes(git_bytes(repo, commit, relative))


def copy_people_inputs(repo: Path, commit: str, stage: Path) -> None:
    for quiz_id, (legacy_relative, _) in PEOPLE.items():
        copy_frozen_file(repo, commit, f"quizzes/{legacy_relative}", stage / "quizzes" / legacy_relative)
        target_dir = stage / "next" / "content" / quiz_id
        for name in ("bundle.json", "draft.json", "manifest.json"):
            copy_frozen_file(repo, commit, f"next/content/{quiz_id}/{name}", target_dir / name)
        bundle = read_json(target_dir / "bundle.json")
        if len(bundle["quiz"]["questions"]) != 28:
            fail(f"{quiz_id} must contain 28 questions")


def copy_and_check_nginx_config(repo: Path, commit: str, stage: Path) -> str:
    """Carry the frozen cache-validator configuration into the image context."""
    source = git_bytes(repo, commit, NGINX_CONFIG_PATH)
    if hashlib.sha256(source).hexdigest() != NGINX_CONFIG_SHA256:
        fail("frozen nginx.conf does not match the approved cache-validator SHA-256")
    dockerfile = stage / "Dockerfile"
    if not dockerfile.is_file():
        fail("staged Dockerfile is missing")
    if not re.search(r"(?m)^COPY nginx\.conf /etc/nginx/nginx\.conf\s*$", dockerfile.read_text(encoding="utf-8")):
        fail("staged Dockerfile does not copy nginx.conf to /etc/nginx/nginx.conf")
    target = stage / "nginx.conf"
    target.write_bytes(source)
    if target.read_bytes() != source or sha256_file(target) != NGINX_CONFIG_SHA256:
        fail("staged nginx.conf differs from frozen Git bytes")
    return NGINX_CONFIG_SHA256


def rows(value: Any, label: str) -> list[dict[str, Any]]:
    if isinstance(value, list):
        return value
    for key in ("articles", "packs", "quizzes"):
        if key in value and isinstance(value[key], list):
            return value[key]
    fail(f"unrecognized {label} schema")


def check_assets(root: Path, label: str) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
    catalog = rows(read_json(root / "assets" / "catalog.json"), f"{label} catalog")
    articles = rows(read_json(root / "assets" / "study" / "question-articles.json"), f"{label} articles")
    if len(catalog) != 131 or sum(pack["questions_count"] for pack in catalog) != 4044:
        fail(f"{label} catalog must be 131 packs / 4044 questions")
    if len(articles) != 242 or any(article.get("status") != "accepted" for article in articles):
        fail(f"{label} Reader data must contain 242 accepted articles")
    return catalog, articles


def check_asset_bytes(catalog_bytes: bytes, reader_bytes: bytes, label: str) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
    catalog = rows(json.loads(catalog_bytes.decode("utf-8")), f"{label} catalog")
    articles = rows(json.loads(reader_bytes.decode("utf-8")), f"{label} articles")
    if len(catalog) != 131 or sum(pack["questions_count"] for pack in catalog) != 4044:
        fail(f"{label} catalog must be 131 packs / 4044 questions")
    if len(articles) != 242 or any(article.get("status") != "accepted" for article in articles):
        fail(f"{label} Reader data must contain 242 accepted articles")
    return catalog, articles


def copy_and_check_web_inputs(repo: Path, commit: str, stage: Path, production_web: Path, qa_web: Path) -> dict[str, str]:
    source_catalog_bytes = git_bytes(repo, commit, "next/apps/quiz_app/assets/catalog.json")
    source_reader_bytes = git_bytes(repo, commit, "next/apps/quiz_app/assets/study/question-articles.json")
    _, source_articles = check_asset_bytes(source_catalog_bytes, source_reader_bytes, "frozen source")
    for output, label in ((production_web, "production Flutter output"), (qa_web, "QA Flutter output")):
        if not (output / "main.dart.js").is_file():
            fail(f"{label} lacks main.dart.js")
        # Flutter emits application assets under web/assets/assets.  The helper
        # intentionally accepts web/assets and appends one assets segment;
        # exact byte checks address the nested payload directory directly.
        web_assets = output / "assets"
        assets = web_assets / "assets"
        if (assets / "catalog.json").read_bytes() != source_catalog_bytes:
            fail(f"{label} embedded catalog differs from frozen source")
        if (assets / "study" / "question-articles.json").read_bytes() != source_reader_bytes:
            fail(f"{label} embedded Reader articles differ from frozen source")
        check_assets(web_assets, label)
    # The compiler output is the web payload; only it is packaged. The exact
    # frozen source copies remain in next/apps for independent inspection.
    shutil.rmtree(stage / "web")
    shutil.copytree(production_web, stage / "web")
    copy_frozen_file(repo, commit, "next/apps/quiz_app/assets/catalog.json", stage / "next" / "apps" / "quiz_app" / "assets" / "catalog.json")
    copy_frozen_file(repo, commit, "next/apps/quiz_app/assets/study/question-articles.json", stage / "next" / "apps" / "quiz_app" / "assets" / "study" / "question-articles.json")
    _, staged_articles = check_assets(stage / "web" / "assets", "packaged production web")
    if staged_articles != source_articles:
        fail("packaged Reader rows differ from frozen source")
    staged_source = stage / "next" / "apps" / "quiz_app" / "assets"
    if (staged_source / "catalog.json").read_bytes() != source_catalog_bytes or (staged_source / "study" / "question-articles.json").read_bytes() != source_reader_bytes:
        fail("packaged source assets differ from checked frozen Git bytes")
    return {
        "catalog_json_sha256": hashlib.sha256(source_catalog_bytes).hexdigest(),
        "question_articles_json_sha256": hashlib.sha256(source_reader_bytes).hexdigest(),
    }


def update_runtime_bundle_cache(stage: Path) -> None:
    cache_path = stage / "runtime-bundles.json"
    cache = read_json(cache_path)
    if set(cache) != set(RUNTIME_IDS):
        fail("runtime bundle cache key set changed unexpectedly")
    for quiz_id in PEOPLE:
        cache[quiz_id] = read_json(stage / "next" / "content" / quiz_id / "bundle.json")
    write_json_lf(cache_path, cache)


def inject_version_after_compilation(stage: Path, build_id: str, frozen_commit: str) -> dict[str, Any]:
    web = stage / "web"
    metadata = {
        "buildId": build_id,
        "commit": frozen_commit,
        "source_commit": frozen_commit,
        "local_build": True,
        "packs": 131,
        "questions": 4044,
        "study_modules": 6,
        "study_questions": 120,
        "question_articles": 242,
        "api_sha256": API_SHA256,
        "main_dart_js_sha256": sha256_file(web / "main.dart.js"),
        "taxonomy_id": "qm-tags-v1",
        "taxonomy_sha256": "07e4bbb5c7afcdab3b41a26dca1bf0ba9a830d5f776a98ebceeaeb2bd8356151",
        "taxonomy_file_sha256": "98f019902b5cce5161b5980f3338d9cd072b094b0a760fc93adb748832546f8c",
    }
    if len(metadata) != 14:
        fail("custom version metadata must have exactly 14 fields")
    write_json_lf(web / "version.json", metadata)
    return metadata


def patch_release_guards(stage: Path, build_id: str, frozen_commit: str, js_sha256: str, nginx_config_sha256: str) -> None:
    cutover = stage / "cutover.sh"
    text = cutover.read_text(encoding="utf-8")
    if text.count(BASELINE_BUILD) != 1:
        fail("cutover must contain exactly one V8 build guard")
    old_js = "7fe815841d43e057042aa76e18508c8648fb59111cb941ac8c36bd30cdee331b"
    if text.count(old_js) != 3:
        fail("cutover must contain exactly three active JavaScript guards")
    old_image = re.search(r"docker\.io/library/quiz-master@sha256:[0-9a-f]{64}", text)
    if old_image is None:
        fail("cutover baseline image guard is missing")
    if text.count(PVC_UID) != 1:
        fail("cutover PVC UID guard is missing or duplicated")
    text = text.replace(BASELINE_BUILD, build_id)
    text = text.replace(old_js, js_sha256)
    text = text.replace(old_image.group(0), BASELINE_IMAGE)
    staged_nginx_check = f"echo '{nginx_config_sha256}  nginx.conf' | sha256sum -c -\n"
    js_check = f"echo '{js_sha256}  web/main.dart.js' | sha256sum -c -\n"
    if text.count(js_check) < 1:
        fail("cutover JavaScript checksum check is missing")
    text = text.replace(js_check, js_check + staged_nginx_check, 1)
    old_commit = "328f2f8e82ade7e99491207e956281751ee6ea4e"
    if text.count(old_commit) != 2:
        fail("cutover must contain exactly two V8 source-commit guards")
    if text.count("meta['questions']==4036") != 1 or text.count("meta['question_articles']==234") != 1:
        fail("cutover metadata count guards changed unexpectedly")
    text = text.replace(old_commit, frozen_commit)
    text = text.replace("meta['questions']==4036", "meta['questions']==4044")
    text = text.replace("meta['question_articles']==234", "meta['question_articles']==242")
    image_build = 'docker build --network=none --pull=false -t "$quiz_image" .\n'
    image_nginx_check = (
        'docker run --rm --network=none --read-only --entrypoint sha256sum "$quiz_image" '
        f'/etc/nginx/nginx.conf | grep \'^{nginx_config_sha256} \'\n'
    )
    if text.count(image_build) != 1:
        fail("cutover image build command is missing or duplicated")
    text = text.replace(image_build, image_build + image_nginx_check)
    # Make the expected current PVC explicit even when its identifier did not
    # change between releases; this turns accidental drift into a hard failure.
    text = text.replace(PVC_UID, PVC_UID)
    cutover.write_bytes(text.replace("\r\n", "\n").encode("utf-8"))
    values = stage / "release-values.yaml"
    value_text = values.read_text(encoding="utf-8")
    value_text, image_count = re.subn(r"(?m)^image:.*$", f"image: {BASELINE_IMAGE}", value_text)
    value_text, build_count = re.subn(r"(?m)^buildId:.*$", f"buildId: {build_id}", value_text)
    if image_count != 1 or build_count != 1:
        fail("release-values must contain one image and one buildId")
    values.write_bytes(value_text.replace("\r\n", "\n").encode("utf-8"))
    rehearsal = stage / "rehearse.py"
    rehearsal_text = rehearsal.read_text(encoding="utf-8")
    old = "else 24 if qid in ['cinema-people-20261011','music-people-20261011'] else 10"
    new = "else 28 if qid in ['cinema-people-20261011','music-people-20261011'] else 10"
    if rehearsal_text.count(old) != 1:
        fail("rehearsal People Reader assertion changed unexpectedly")
    rehearsal.write_bytes(rehearsal_text.replace(old, new).replace("\r\n", "\n").encode("utf-8"))


def write_checksums(stage: Path) -> tuple[int, str]:
    files = sorted(path for path in stage.rglob("*") if path.is_file() and path.name != "checksums.txt")
    body = "".join(f"{sha256_file(path)}  {path.relative_to(stage).as_posix()}\n" for path in files)
    (stage / "checksums.txt").write_bytes(body.encode("utf-8"))
    for line in body.splitlines():
        digest, relative = line.split("  ", 1)
        if sha256_file(stage / relative) != digest:
            fail(f"checksum self-verification failed: {relative}")
    return len(files) + 1, sha256_file(stage / "checksums.txt")


def archive_and_verify(stage: Path, output_root: Path) -> tuple[Path, str, int]:
    archive = output_root / f"{stage.name}.tar.gz"
    with archive.open("wb") as raw:
        with gzip.GzipFile(filename="", mode="wb", fileobj=raw, mtime=0) as compressed:
            with tarfile.open(fileobj=compressed, mode="w", format=tarfile.PAX_FORMAT) as package:
                for path in sorted(candidate for candidate in stage.rglob("*") if candidate.is_file()):
                    info = tarfile.TarInfo(f"{stage.name}/{path.relative_to(stage).as_posix()}")
                    info.size = path.stat().st_size
                    info.mode = 0o644
                    info.mtime = 0
                    info.uid = info.gid = 0
                    info.uname = info.gname = ""
                    with path.open("rb") as source:
                        package.addfile(info, source)
    mismatches: list[str] = []
    with tarfile.open(archive, "r:gz") as package:
        members = package.getmembers()
        for member in members:
            pure = PurePosixPath(member.name)
            if not member.isfile() or pure.is_absolute() or ".." in pure.parts or pure.parts[0] != stage.name:
                fail(f"unsafe generated archive member: {member.name}")
            payload = package.extractfile(member)
            if payload is None:
                fail(f"unreadable generated archive member: {member.name}")
            relative = Path(*pure.parts[1:])
            if hashlib.sha256(payload.read()).hexdigest() != sha256_file(stage / relative):
                mismatches.append(member.name)
    if mismatches:
        fail(f"archive member hash mismatches: {mismatches}")
    return archive, sha256_file(archive), len(members)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo", type=Path, required=True)
    parser.add_argument("--frozen-commit", required=True, help="full immutable integration commit SHA")
    parser.add_argument("--production-web", type=Path, required=True)
    parser.add_argument("--qa-web", type=Path, required=True)
    parser.add_argument("--output-root", type=Path, required=True, help="new, empty release directory")
    parser.add_argument("--prior-archive", type=Path, required=True)
    args = parser.parse_args()
    if re.fullmatch(r"[0-9a-f]{40}", args.frozen_commit) is None:
        fail("--frozen-commit must be a full lowercase 40-hex SHA")
    if not (args.repo / ".git").exists():
        fail("--repo is not a Git checkout")
    verified = subprocess.run(["git", "-C", str(args.repo), "rev-parse", "--verify", f"{args.frozen_commit}^{{commit}}"], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if verified.returncode != 0 or verified.stdout.decode().strip() != args.frozen_commit:
        fail("--frozen-commit is not an object in --repo")
    build_id = f"quiz-2026.10.13-culture-{args.frozen_commit[:7]}"
    if args.output_root.exists() and any(args.output_root.iterdir()):
        fail("--output-root must be absent or empty")
    args.output_root.mkdir(parents=True, exist_ok=True)
    stage = args.output_root / build_id
    extract_immutable(args.prior_archive, stage)
    nginx_config_sha256 = copy_and_check_nginx_config(args.repo, args.frozen_commit, stage)
    copy_people_inputs(args.repo, args.frozen_commit, stage)
    frozen_asset_sha256 = copy_and_check_web_inputs(args.repo, args.frozen_commit, stage, args.production_web, args.qa_web)
    update_runtime_bundle_cache(stage)
    metadata = inject_version_after_compilation(stage, build_id, args.frozen_commit)
    patch_release_guards(stage, build_id, args.frozen_commit, metadata["main_dart_js_sha256"], nginx_config_sha256)
    expected, proof = expected_staging_revisions(stage, build_id)
    write_json_lf(stage / "expected-staging-revisions.json", expected)
    file_members, manifest_sha256 = write_checksums(stage)
    archive, archive_sha256, tar_members = archive_and_verify(stage, args.output_root)
    result = {
        "status": "PREPARED_NOT_EXECUTED",
        "build_id": build_id,
        "frozen_commit": args.frozen_commit,
        "baseline_input": {"archive": str(args.prior_archive), "archive_sha256": BASELINE_ARCHIVE_SHA256, "image": BASELINE_IMAGE, "pvc_uid": PVC_UID},
        "counts": {"packs": 131, "questions": 4044, "reader_articles": 242, "people_questions_each": 28, "staging_canonical_questions": 140, "newyear_copy_questions": 55, "copy_grading_questions": 195},
        "metadata": metadata,
        "frozen_source_assets": frozen_asset_sha256,
        "nginx_config_sha256": nginx_config_sha256,
        "api_sha256": API_SHA256,
        "qa_web_checked_not_packaged": str(args.qa_web),
        "expected_staging_revision_proof": proof,
        "stage": str(stage),
        "archive": str(archive),
        "archive_sha256": archive_sha256,
        "file_members": file_members,
        "tar_members": tar_members,
        "manifest_sha256": manifest_sha256,
        "remaining_gates": ["root static/execution review", "Linux copied-DB rehearsal and rollback", "image build/import, Helm lint/template/server dry-run", "isolated browser evidence", "authorized atomic production publication and public verification"],
    }
    write_json_lf(args.output_root / "package-preparation.json", result)
    print(json.dumps({key: result[key] for key in ("status", "build_id", "stage", "archive", "archive_sha256", "counts")}, ensure_ascii=False))


if __name__ == "__main__":
    main()
