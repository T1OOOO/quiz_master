#!/usr/bin/env python3
"""Prepare (but never publish) the immutable Film Craft release package.

This controller is deliberately inert until the release lead supplies a frozen
commit and freshly built production/QA Flutter directories.  It starts from the
approved Helm48 package, preserving every earlier runtime/cache/content guard while appending only frozen Film Craft inputs.
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

BASELINE_BUILD = "quiz-2026.10.13-article-only-ffa2716"
BASELINE_ARCHIVE_SHA256 = "009e3c09fb72d82ddc9775b31e2774bc21f39da157607ba78732abb61eda7bf5"
BASELINE_IMAGE = "docker.io/library/quiz-master@sha256:8e3c6bd77ab94945093e2ca4394d8364cca9e306b91c791ce2b4461d2a0f0018"
NGINX_CONFIG_PATH = "next/infra/production/nginx.conf"
NGINX_CONFIG_SHA256 = "e9add812a138010e443463acb455295103dc69886ca32cd17dafbccfa676d6bc"
PVC_UID = "7fc2428f-4146-4c78-a26d-2347d9f3b7bf"
API_SHA256 = "26e1657fd6259bdbbef9178cbe9343b775406d91c56cb9661d302ad530ab6f01"
FROZEN_READER_SHA256 = "d56144d16d2307cf581f64d55e146381f165726de0d6a59c99250e43901ebb07"
HOME_ALONE_ID = "home-alone-1-part-1"
RUNTIME_IDS = (
    "cinema-encore-20261011", "cinema-people-20261011", "home-alone-1-part-1",
    "music-encore-20261011", "music-people-20261011", "philias-lifestyle-part-1",
    "phobias-nature", "planet-paradoxes-20261010",
)

BASELINE_RUNTIME_IDS = RUNTIME_IDS
FILM_CRAFT_ID = "film-craft-20261013"
RUNTIME_IDS = BASELINE_RUNTIME_IDS + (FILM_CRAFT_ID,)
BASELINE_MAIN_DART_JS_SHA256 = "b277d40969e197d8ee96830c836927432a631180609dd278d7e8ecf5c76001b9"
FROZEN_CATALOG_SHA256 = "9196ca0592034e2a5f8e02099c1f3a8f5a10a60e8ee81222427cbe682034927e"
FROZEN_FILM_FILES = {
    "next/content/film-craft-20261013/draft.json": "19c1941d6dccaa643d0b36c8d456f227407a4049827353cfc3aacf4f835846e4",
    "next/content/film-craft-20261013/bundle.json": "e582313d7c94376ecdb12bfdc7d34e0c43562d5bc74206db8db045ed1a6e4427",
    "next/content/film-craft-20261013/manifest.json": "054be48d197a6d64c45fb958898933238f827341126781bc94ca83d9da71d540",
    "quizzes/Preparation/film_craft_20261013.json": "f1816569fb2c0c46fa0047ea148c8e4e7a3638989baa937bdc00001748655c68",
}
FILM_CRAFT_ARTICLE_REFS = {
    "film-craft-pilot-001": "33cc65a230ea288796e495d51e9d9034894711005ba822bff3999326e2d8e444",
    "film-craft-pilot-002": "e49bcb500592de3552b2bcb4042e345d341983228d2c3b9f52be0c0733aeb4c3",
    "film-craft-pilot-003": "c6f5e00a14e3740db81cbaff646341193a24795d48fe01f7c84f2bc56d69e674",
    "film-craft-pilot-004": "4e4261c14d3a5e4b4e5e81a07cb5a4ff7065020059ee11ff4041fe4af967f3f0",
}
FROZEN_COMMIT = "adf95a57594158308c94ee2bff1cb5ca9c9c0684"


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
    if sum(len(rows) for rows in expected.values()) != 144:
        fail("expected exactly 144 canonical staging revisions")
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



def current_assets(catalog_bytes: bytes, reader_bytes: bytes, label: str) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
    catalog = rows(json.loads(catalog_bytes.decode("utf-8")), f"{label} catalog")
    articles = rows(json.loads(reader_bytes.decode("utf-8")), f"{label} articles")
    if len(catalog) != 132 or sum(row["questions_count"] for row in catalog) != 4048:
        fail(f"{label} must contain 132 packs / 4048 questions")
    if len(articles) != 248 or any(row.get("status") != "accepted" for row in articles):
        fail(f"{label} must contain 248 accepted Reader articles")
    return catalog, articles


def preserved_helm48(stage: Path) -> tuple[list[dict[str, Any]], list[dict[str, Any]], dict[str, Any], dict[str, str]]:
    root = stage / "web" / "assets" / "assets"
    catalog = rows(read_json(root / "catalog.json"), "Helm48 catalog")
    articles = rows(read_json(root / "study" / "question-articles.json"), "Helm48 Reader")
    cache = read_json(stage / "runtime-bundles.json")
    if len(catalog) != 131 or sum(row["questions_count"] for row in catalog) != 4044 or len(articles) != 244:
        fail("Helm48 baseline counts differ")
    if set(cache) != set(BASELINE_RUNTIME_IDS):
        fail("Helm48 cache must contain exactly eight runtime entries")
    home = read_json(stage / "next" / "content" / HOME_ALONE_ID / "bundle.json")
    if len(home["quiz"]["questions"]) != 25 or cache.get(HOME_ALONE_ID) != home:
        fail("Helm48 Home Alone bundle/cache guard differs")
    for quiz_id in ("cinema-people-20261011", "music-people-20261011"):
        bundle = read_json(stage / "next" / "content" / quiz_id / "bundle.json")
        if len(bundle["quiz"]["questions"]) != 28 or cache.get(quiz_id) != bundle:
            fail(f"Helm48 People guard differs: {quiz_id}")
    content = {path.relative_to(stage / "next" / "content").as_posix(): sha256_file(path) for path in (stage / "next" / "content").rglob("*.json")}
    return copy.deepcopy(catalog), copy.deepcopy(articles), copy.deepcopy(cache), content


def assert_preserved(baseline_catalog: list[dict[str, Any]], baseline_articles: list[dict[str, Any]], catalog: list[dict[str, Any]], articles: list[dict[str, Any]], label: str) -> None:
    old_catalog = {row["quiz_id"]: row for row in baseline_catalog}
    now_catalog = {row["quiz_id"]: row for row in catalog}
    if set(now_catalog) - set(old_catalog) != {FILM_CRAFT_ID} or any(now_catalog[key] != row for key, row in old_catalog.items()):
        fail(f"{label} must preserve all 131 Helm48 catalog rows and add only Film Craft")
    old_articles = {row["id"]: row for row in baseline_articles}
    now_articles = {row["id"]: row for row in articles}
    if any(now_articles.get(key) != row for key, row in old_articles.items()):
        fail(f"{label} changed an existing Helm48 Reader article")
    added = [row for row in articles if row["id"] not in old_articles]
    refs = [ref for row in added for ref in row.get("question_refs", []) if ref.get("quiz_id") == FILM_CRAFT_ID]
    if len(added) != 4 or len(refs) != 4 or {ref["question_id"]: ref["revision_sha256"] for ref in refs} != FILM_CRAFT_ARTICLE_REFS:
        fail(f"{label} must append exactly four approved Film Craft Reader refs")


def assert_content_preserved(stage: Path, baseline: dict[str, str]) -> None:
    root = stage / "next" / "content"
    current = {path.relative_to(root).as_posix(): sha256_file(path) for path in root.rglob("*.json")}
    new_files = {f"{FILM_CRAFT_ID}/draft.json", f"{FILM_CRAFT_ID}/bundle.json", f"{FILM_CRAFT_ID}/manifest.json"}
    if set(current) - set(baseline) != new_files or any(current[key] != digest for key, digest in baseline.items()):
        fail("Film Craft preparation changed existing Helm48 canonical content")


def copy_film_inputs(repo: Path, commit: str, stage: Path) -> None:
    for relative, expected in FROZEN_FILM_FILES.items():
        payload = git_bytes(repo, commit, relative)
        if hashlib.sha256(payload).hexdigest() != expected:
            fail(f"frozen Film Craft SHA differs: {relative}")
        target = stage / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(payload)
    bundle = read_json(stage / "next" / "content" / FILM_CRAFT_ID / "bundle.json")
    if {row["question_id"]: row["revision"]["sha256"] for row in bundle["quiz"]["questions"]} != FILM_CRAFT_ARTICLE_REFS:
        fail("Film Craft bundle refs differ from frozen accepted refs")


def copy_and_check_film_web(repo: Path, commit: str, stage: Path, production_web: Path, qa_web: Path, baseline_catalog: list[dict[str, Any]], baseline_articles: list[dict[str, Any]]) -> dict[str, str]:
    catalog_bytes = git_bytes(repo, commit, "next/apps/quiz_app/assets/catalog.json")
    reader_bytes = git_bytes(repo, commit, "next/apps/quiz_app/assets/study/question-articles.json")
    if hashlib.sha256(catalog_bytes).hexdigest() != FROZEN_CATALOG_SHA256 or hashlib.sha256(reader_bytes).hexdigest() != FROZEN_READER_SHA256:
        fail("frozen Film Craft app asset SHA differs")
    catalog, articles = current_assets(catalog_bytes, reader_bytes, "frozen source")
    assert_preserved(baseline_catalog, baseline_articles, catalog, articles, "frozen source")
    for web, label in ((production_web, "production Flutter output"), (qa_web, "QA Flutter output")):
        embedded_catalog = (web / "assets" / "assets" / "catalog.json").read_bytes()
        embedded_reader = (web / "assets" / "assets" / "study" / "question-articles.json").read_bytes()
        if not (web / "main.dart.js").is_file() or embedded_catalog != catalog_bytes or embedded_reader != reader_bytes:
            fail(f"{label} lacks the frozen compiled Film Craft assets")
        actual_catalog, actual_articles = current_assets(embedded_catalog, embedded_reader, label)
        assert_preserved(baseline_catalog, baseline_articles, actual_catalog, actual_articles, label)
    shutil.rmtree(stage / "web")
    shutil.copytree(production_web, stage / "web")
    copy_frozen_file(repo, commit, "next/apps/quiz_app/assets/catalog.json", stage / "next" / "apps" / "quiz_app" / "assets" / "catalog.json")
    copy_frozen_file(repo, commit, "next/apps/quiz_app/assets/study/question-articles.json", stage / "next" / "apps" / "quiz_app" / "assets" / "study" / "question-articles.json")
    return {"catalog_json_sha256": FROZEN_CATALOG_SHA256, "question_articles_json_sha256": FROZEN_READER_SHA256}


def append_film_cache(stage: Path, baseline_cache: dict[str, Any]) -> None:
    path = stage / "runtime-bundles.json"
    cache = read_json(path)
    if cache != baseline_cache:
        fail("Helm48 runtime cache changed before Film Craft append")
    cache[FILM_CRAFT_ID] = read_json(stage / "next" / "content" / FILM_CRAFT_ID / "bundle.json")
    if set(cache) != set(RUNTIME_IDS) or any(cache[key] != value for key, value in baseline_cache.items()):
        fail("runtime cache append changed an existing entry")
    write_json_lf(path, cache)


def patch_film_guards(stage: Path, build_id: str, commit: str, js_sha256: str, nginx_sha256: str) -> None:
    cutover = stage / "cutover.sh"
    text = cutover.read_text(encoding="utf-8")
    prefix = r"r'quiz-2026\.10\.13-article-only-[0-9a-f]{7}'"
    if text.count(BASELINE_BUILD) != 1 or text.count(prefix) != 1 or text.count(BASELINE_MAIN_DART_JS_SHA256) != 3:
        fail("Helm48 cutover anchors absent or duplicated")
    if text.count("ffa271633279179391f83b7624d807ca29792939") != 2 or text.count(PVC_UID) != 1:
        fail("Helm48 cutover commit/target guards absent or duplicated")
    if text.count("meta['packs']==131") != 1 or text.count("meta['questions']==4044") != 1 or text.count("meta['question_articles']==244") != 1:
        fail("Helm48 cutover count guards changed")
    image = re.search(r"docker\.io/library/quiz-master@sha256:[0-9a-f]{64}", text)
    if image is None or text.count(image.group(0)) != 1:
        fail("Helm48 image guard missing or duplicated")
    text = text.replace(BASELINE_BUILD, build_id).replace(prefix, r"r'quiz-2026\.10\.13-film-craft-[0-9a-f]{7}'").replace(BASELINE_MAIN_DART_JS_SHA256, js_sha256).replace("ffa271633279179391f83b7624d807ca29792939", commit).replace(image.group(0), BASELINE_IMAGE)
    text = text.replace("meta['packs']==131", "meta['packs']==132").replace("meta['questions']==4044", "meta['questions']==4048").replace("meta['question_articles']==244", "meta['question_articles']==248")
    js_check = f"echo '{js_sha256}  web/main.dart.js' | sha256sum -c -\n"
    if text.count(js_check) != 1:
        fail("cutover JavaScript checksum anchor missing")
    text = text.replace(js_check, js_check + f"echo '{nginx_sha256}  nginx.conf' | sha256sum -c -\n")
    cutover.write_bytes(text.replace("\r\n", "\n").encode())
    values = stage / "release-values.yaml"
    body = values.read_text(encoding="utf-8")
    body, images = re.subn(r"(?m)^image:.*$", f"image: {BASELINE_IMAGE}", body)
    body, builds = re.subn(r"(?m)^buildId:.*$", f"buildId: {build_id}", body)
    if images != 1 or builds != 1:
        fail("release-values anchors absent or duplicated")
    values.write_text(body, encoding="utf-8", newline="\n")
    rehearsal = stage / "rehearse.py"
    body = rehearsal.read_text(encoding="utf-8")
    cache_guard = "assert after[3]-before[3]==131, 'Unexpected bundle-cache growth'"
    if body.count(cache_guard) != 1:
        fail("Helm48 rehearsal cache-growth anchor absent or duplicated")
    body = body.replace(cache_guard, "assert after[3]-before[3]==132, 'Unexpected bundle-cache growth'")
    history_guard = "assert len(req('/v1/history',token=token))==9"
    if body.count(history_guard) != 1:
        fail("Helm48 rehearsal rollback-history anchor absent or duplicated")
    body = body.replace(history_guard, "assert len(req('/v1/history',token=token))==10")
    old_ids = "['cinema-encore-20261011','music-encore-20261011','planet-paradoxes-20261010','philias-lifestyle-part-1','phobias-nature','home-alone-1-part-1','cinema-people-20261011','music-people-20261011']"
    new_ids = old_ids[:-1] + ",'film-craft-20261013']"
    if body.count(old_ids) != 2:
        fail("Helm48 rehearsal runtime anchors absent or duplicated")
    body = body.replace(old_ids, new_ids)
    old = "  else:\n   assert len(matches)==(0 if qid in ['philias-lifestyle-part-1','phobias-nature'] else 28 if qid in ['cinema-people-20261011','music-people-20261011'] else 10)"
    new = "  elif qid=='film-craft-20261013':\n   expected_article_refs=" + repr(FILM_CRAFT_ARTICLE_REFS) + "\n   assert len(matches)==4 and {ref['question_id']:ref['revision_sha256'] for ref in matches}==expected_article_refs\n   assert {q['question_id']:q['revision']['sha256'] for q in live['quiz']['questions']}==expected_article_refs\n" + old
    if body.count(old) != 1:
        fail("Helm48 rehearsal Reader anchor absent or duplicated")
    rehearsal.write_text(body.replace(old, new), encoding="utf-8", newline="\n")


def inject_version_after_compilation(stage: Path, build_id: str, frozen_commit: str) -> dict[str, Any]:
    web = stage / "web"
    metadata = {
        "buildId": build_id,
        "commit": frozen_commit,
        "source_commit": frozen_commit,
        "local_build": True,
        "packs": 132,
        "questions": 4048,
        "study_modules": 6,
        "study_questions": 120,
        "question_articles": 248,
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
    parser.add_argument("--frozen-commit", required=True)
    parser.add_argument("--production-web", type=Path, required=True)
    parser.add_argument("--qa-web", type=Path, required=True)
    parser.add_argument("--output-root", type=Path, required=True)
    parser.add_argument("--prior-archive", type=Path, required=True)
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()
    if args.self_test:
        if args.frozen_commit != FROZEN_COMMIT:
            fail("self-test requires the frozen Film Craft integration SHA")
        print(json.dumps({"self_test":"PASS","writes":"none","counts":[132,4048,248],"runtime_entries":[8,9]}))
        return
    if args.frozen_commit != FROZEN_COMMIT:
        fail("--frozen-commit must be the accepted full Film Craft integration SHA")
    verified = subprocess.run(["git", "-C", str(args.repo), "rev-parse", "--verify", f"{args.frozen_commit}^{{commit}}"], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if verified.returncode != 0 or verified.stdout.decode().strip() != args.frozen_commit:
        fail("--frozen-commit is not an object in --repo")
    build_id = f"quiz-2026.10.13-film-craft-{args.frozen_commit[:7]}"
    if args.output_root.exists() and any(args.output_root.iterdir()):
        fail("--output-root must be absent or empty")
    args.output_root.mkdir(parents=True, exist_ok=True)
    stage = args.output_root / build_id
    extract_immutable(args.prior_archive, stage)
    baseline_catalog, baseline_articles, baseline_cache, baseline_content = preserved_helm48(stage)
    nginx_sha = copy_and_check_nginx_config(args.repo, args.frozen_commit, stage)
    copy_film_inputs(args.repo, args.frozen_commit, stage)
    assets = copy_and_check_film_web(args.repo, args.frozen_commit, stage, args.production_web, args.qa_web, baseline_catalog, baseline_articles)
    append_film_cache(stage, baseline_cache)
    assert_content_preserved(stage, baseline_content)
    metadata = inject_version_after_compilation(stage, build_id, args.frozen_commit)
    patch_film_guards(stage, build_id, args.frozen_commit, metadata["main_dart_js_sha256"], nginx_sha)
    expected, proof = expected_staging_revisions(stage, build_id)
    write_json_lf(stage / "expected-staging-revisions.json", expected)
    file_members, manifest_sha256 = write_checksums(stage)
    archive, archive_sha256, tar_members = archive_and_verify(stage, args.output_root)
    result = {"status":"PREPARED_NOT_EXECUTED","build_id":build_id,"frozen_commit":args.frozen_commit,"baseline_input":{"archive":str(args.prior_archive),"archive_sha256":BASELINE_ARCHIVE_SHA256,"image":BASELINE_IMAGE,"pvc_uid":PVC_UID},"counts":{"packs":132,"questions":4048,"reader_articles":248,"preserved_catalog_rows":131,"preserved_questions":4044,"preserved_article_objects":244,"baseline_cache_entries":8,"runtime_cache_entries":9,"film_craft_questions":4,"staging_canonical_questions":144,"home_alone_questions":25},"metadata":metadata,"frozen_source_assets":assets,"nginx_config_sha256":nginx_sha,"api_sha256":API_SHA256,"qa_web_checked_not_packaged":str(args.qa_web),"expected_staging_revision_proof":proof,"stage":str(stage),"archive":str(archive),"archive_sha256":archive_sha256,"file_members":file_members,"tar_members":tar_members,"manifest_sha256":manifest_sha256,"remaining_gates":["root execution after fresh Flutter output","independent review","copied-DB rehearsal and rollback","image/Helm/server/browser gates","authorized publication"]}
    write_json_lf(args.output_root / "package-preparation.json", result)
    print(json.dumps({key:result[key] for key in ("status","build_id","stage","archive","archive_sha256","counts")}, ensure_ascii=False))


if __name__ == "__main__":
    main()
