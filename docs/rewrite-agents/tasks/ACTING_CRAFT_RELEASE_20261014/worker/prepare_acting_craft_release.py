#!/usr/bin/env python3
"""Prepare (but never publish) the immutable Acting Craft release package.

This controller is deliberately inert until the release lead supplies a frozen
commit and freshly built production/QA Flutter directories.  It starts from the
approved Helm50 package, preserving earlier runtime/cache/content guards and the
four approved Music article title corrections while appending Actor inputs.
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

BASELINE_BUILD = "quiz-2026.10.13-music-craft-f79555e"
BASELINE_ARCHIVE_SHA256 = "ae4768f4a73d94976066f24bc80dcc31636d449428660706a91154c84930f9f7"
BASELINE_IMAGE = "docker.io/library/quiz-master@sha256:b94a399359f87024f5b00a53c47852a3e8f90f1ba6f4bb861385e9c2655f17d7"
NGINX_CONFIG_PATH = "next/infra/production/nginx.conf"
NGINX_CONFIG_SHA256 = "e9add812a138010e443463acb455295103dc69886ca32cd17dafbccfa676d6bc"
PVC_UID = "7fc2428f-4146-4c78-a26d-2347d9f3b7bf"
API_SHA256 = "26e1657fd6259bdbbef9178cbe9343b775406d91c56cb9661d302ad530ab6f01"
FROZEN_READER_SHA256 = "f805bb0157e35e864d26f6fa6927e3b242720aa1a5b239465a0aa12b0b1c911d"
HOME_ALONE_ID = "home-alone-1-part-1"
RUNTIME_IDS = (
    "cinema-encore-20261011", "cinema-people-20261011", "home-alone-1-part-1",
    "music-encore-20261011", "music-people-20261011", "philias-lifestyle-part-1",
    "phobias-nature", "planet-paradoxes-20261010",
)

BASELINE_RUNTIME_IDS = RUNTIME_IDS + ("film-craft-20261013", "music-craft-20261013",)
ACTING_CRAFT_ID = "acting-craft-20261014"
RUNTIME_IDS = BASELINE_RUNTIME_IDS + (ACTING_CRAFT_ID,)
BASELINE_MAIN_DART_JS_SHA256 = "fe9b2c66ed9c7b01ad5325616ff6a4fd8402c653b9fe97705b450a96ccaf8380"
FROZEN_CATALOG_SHA256 = "77c496394c4089a8895eb180b61592807e4c37ea15b81cb54eecc0be303be377"
FROZEN_ACTING_FILES = {"quizzes/Cinema/acting_craft_20261014.json":"a3fa877452956691f048d1cd129756a64a6e94de23a09d7752680c6a4ed11963","next/content/acting-craft-20261014/draft.json":"431384f39ef4251f1c152b18b3e91d10bf084e7ad39ec2a9b7a232909e96969e","next/content/acting-craft-20261014/bundle.json":"0378dfb462aee36b31d0026381e5d804c1fda410da5166a571150c13c480b3ee","next/content/acting-craft-20261014/manifest.json":"e0f79300cb149778f81678d391785c30b41f6a86e26309e34b6b2570aef77c62","study/question_articles/drafts/acting-craft-20261014.json":"dc949de1780840797e22ff3a9ac4cc2e575c611dc821775dbd445a9ac321492f","study/question_articles/reviews/acting-craft-20261014-review.json":"588ca76bf2ebdf4ee7d508606ee6bcc6281e6a71c3481e57aa39d7f2c98f262f","next/apps/quiz_app/assets/catalog.json":"77c496394c4089a8895eb180b61592807e4c37ea15b81cb54eecc0be303be377","next/apps/quiz_app/assets/study/question-articles.json":"f805bb0157e35e864d26f6fa6927e3b242720aa1a5b239465a0aa12b0b1c911d"}
ACTING_CRAFT_ARTICLE_REFS = {
    'acting-craft-pilot-001': '0b211637a8a29d0708a33567d11fafb113773ed89aef5ba8afdde46bf1c11e44',
    'acting-craft-pilot-002': '14df4c16dfc105fefdea35e733bdf1389b0f91debb950d7be65bde3252d468cd',
    'acting-craft-pilot-003': '0d0073db567749ebd64b1dcaf91ca62109346cb1c0d2483c858ab45945dabbb7',
    'acting-craft-pilot-004': '032702e68ba38fdedc73a698e880978c5c6fcd3331777485c8ab60380d72f49b',
    'acting-craft-pilot-005': '594bd4f212f5713593331b4099054fbf9439a287c44eeec4792142c1e00e038c',
    'acting-craft-pilot-006': '02adc130e3f8feab6b7e0b5dd021b33c4283af25fb6025aded5ed1a7ff627773',
    'acting-craft-pilot-007': '7003a49c4bf117f83cd508c7c48c064d5b26daa3322c27078d288d52d5954f2a',
    'acting-craft-pilot-008': 'e8561876f0dcbdc06dfe68f9ee9146913dc11b13a7fd2a98f840592984ef0fc0',
}
RAW_PATH = 'quizzes/Cinema/acting_craft_20261014.json'
NORMALIZED_SOURCE_SHA256 = '5df21fce18ef2710d5b821eeb0a3ad3ca7d854146b0cccf479cdcaca688f8013'
TITLE_PROPOSAL = Path('C:/ap/quiz_master/docs/rewrite-agents/tasks/SOURCE_TITLES_20261014/proposed-music-articles.json')
TITLE_PROPOSAL_SHA256 = '541004c607877ec33d1260cfaad7ab1aa08494872773c5677538caeeec31da47'
FROZEN_COMMIT = "b80deb12844aa786e9e0351273eab3f525ddce27"
BASELINE_SOURCE_COMMIT = "f79555e0659f0c20b86064b446ac582de323b2e9"
PRODUCTION_JS_SHA256 = "c92ec7cd0c53040d425c5fa97f904baa0b60b74ec2f0248837a5de601bcff1f0"
QA_JS_SHA256 = "716177c0496b31a95d701ebf6045fb6e4a60330c9882e25c2faf826a5b04844f"


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
    if sum(len(rows) for rows in expected.values()) != 156:
        fail("expected exactly 156 canonical staging revisions")
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
        names: set[str] = set()
        for member in members:
            pure = PurePosixPath(member.name)
            if not member.isfile() or pure.is_absolute() or ".." in pure.parts or "\\" in member.name or member.name in names or not member.name.startswith(expected_prefix):
                fail(f"unsafe or unexpected archive member: {member.name}")
            names.add(member.name)
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
    if len(catalog) != 134 or sum(row["questions_count"] for row in catalog) != 4060:
        fail(f"{label} must contain 134 packs / 4060 questions")
    if len(articles) != 260 or any(row.get("status") != "accepted" for row in articles):
        fail(f"{label} must contain 260 accepted Reader articles")
    return catalog, articles


def preserved_helm50(stage: Path) -> tuple[list[dict[str, Any]], list[dict[str, Any]], dict[str, Any], dict[str, str]]:
    meta = read_json(stage / "web" / "version.json")
    if meta.get("buildId") != BASELINE_BUILD or meta.get("source_commit") != BASELINE_SOURCE_COMMIT or meta.get("commit") != BASELINE_SOURCE_COMMIT:
        fail("Helm50 baseline source/build differs")
    for path, expected in ((stage / "api", API_SHA256), (stage / "nginx.conf", NGINX_CONFIG_SHA256), (stage / "web" / "main.dart.js", BASELINE_MAIN_DART_JS_SHA256)):
        if sha256_file(path) != expected:
            fail(f"Helm50 baseline binary/config differs: {path.name}")
    root = stage / "web" / "assets" / "assets"
    catalog = rows(read_json(root / "catalog.json"), "Helm50 catalog")
    articles = rows(read_json(root / "study" / "question-articles.json"), "Helm50 Reader")
    cache = read_json(stage / "runtime-bundles.json")
    if len(catalog) != 133 or sum(row["questions_count"] for row in catalog) != 4052 or len(articles) != 252:
        fail("Helm50 baseline counts differ")
    if set(cache) != set(BASELINE_RUNTIME_IDS):
        fail("Helm50 cache must contain exactly ten runtime entries")
    home = read_json(stage / "next" / "content" / HOME_ALONE_ID / "bundle.json")
    if len(home["quiz"]["questions"]) != 25 or cache.get(HOME_ALONE_ID) != home:
        fail("Helm50 Home Alone bundle/cache guard differs")
    for quiz_id in ("cinema-people-20261011", "music-people-20261011"):
        bundle = read_json(stage / "next" / "content" / quiz_id / "bundle.json")
        if len(bundle["quiz"]["questions"]) != 28 or cache.get(quiz_id) != bundle:
            fail(f"Helm50 People guard differs: {quiz_id}")
    content = {path.relative_to(stage / "next" / "content").as_posix(): sha256_file(path) for path in (stage / "next" / "content").rglob("*.json")}
    return copy.deepcopy(catalog), copy.deepcopy(articles), copy.deepcopy(cache), content


def assert_preserved(baseline_catalog: list[dict[str, Any]], baseline_articles: list[dict[str, Any]], catalog: list[dict[str, Any]], articles: list[dict[str, Any]], label: str) -> None:
    old_catalog = {row["quiz_id"]: row for row in baseline_catalog}
    now_catalog = {row["quiz_id"]: row for row in catalog}
    if set(now_catalog) - set(old_catalog) != {ACTING_CRAFT_ID} or any(now_catalog[key] != row for key, row in old_catalog.items()):
        fail(f"{label} must preserve all 133 Helm50 catalog rows and add only Acting Craft")
    old_articles = {row["id"]: row for row in baseline_articles}
    now_articles = {row["id"]: row for row in articles}
    if sha256_file(TITLE_PROPOSAL) != TITLE_PROPOSAL_SHA256:
        fail("accepted Music title proposal hash differs")
    proposed = {row['id']: row for row in rows(read_json(TITLE_PROPOSAL), 'title proposal')}
    if len(proposed) != 4 or not set(proposed) <= set(old_articles):
        fail("Music title proposal must match four existing articles")
    changed_titles = 0
    for key, row in old_articles.items():
        expected = copy.deepcopy(row)
        if key in proposed:
            proposal = copy.deepcopy(proposed[key])
            proposal['status'] = row['status']
            if len(proposal['source_links']) != 2 or len(row['source_links']) != 2:
                fail("Music title proposal must contain eight source links")
            for actual, desired in zip(expected['source_links'], proposal['source_links'], strict=True):
                if actual['title'] == desired['title']:
                    fail("each approved Music source title must change")
                actual['title'] = desired['title']
                changed_titles += 1
            if expected != proposal:
                fail("Music title proposal changes fields other than SourceLink.title")
        if now_articles.get(key) != expected:
            fail(f"{label} changed an existing Reader article beyond approved source titles")
    if changed_titles != 8:
        fail("exactly eight approved Music source titles must change")
    added = [row for row in articles if row["id"] not in old_articles]
    refs = [ref for row in added for ref in row.get("question_refs", []) if ref.get("quiz_id") == ACTING_CRAFT_ID]
    if len(added) != 8 or len(refs) != 8 or {ref["question_id"]: ref["revision_sha256"] for ref in refs} != ACTING_CRAFT_ARTICLE_REFS or any(len(row.get('source_links', [])) != 2 for row in added):
        fail(f"{label} must append eight approved Acting Craft Reader refs with sixteen source links")


def assert_content_preserved(stage: Path, baseline: dict[str, str]) -> None:
    root = stage / "next" / "content"
    current = {path.relative_to(root).as_posix(): sha256_file(path) for path in root.rglob("*.json")}
    new_files = {f"{ACTING_CRAFT_ID}/draft.json", f"{ACTING_CRAFT_ID}/bundle.json", f"{ACTING_CRAFT_ID}/manifest.json"}
    if set(current) - set(baseline) != new_files or any(current[key] != digest for key, digest in baseline.items()):
        fail("Acting Craft preparation changed existing Helm50 canonical content")


def copy_actor_inputs(repo: Path, commit: str, stage: Path) -> None:
    for relative, expected in FROZEN_ACTING_FILES.items():
        payload = git_bytes(repo, commit, relative)
        if hashlib.sha256(payload).hexdigest() != expected:
            fail(f"frozen Acting Craft SHA differs: {relative}")
        if not (repo / relative).is_file() or sha256_file(repo / relative) != expected:
            fail(f"working source differs from frozen Git input: {relative}")
        target = stage / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(payload)
    bundle = read_json(stage / "next" / "content" / ACTING_CRAFT_ID / "bundle.json")
    if {row["question_id"]: row["revision"]["sha256"] for row in bundle["quiz"]["questions"]} != ACTING_CRAFT_ARTICLE_REFS:
        fail("Acting Craft bundle refs differ from frozen accepted refs")


def verify_actor_raw_parity(stage: Path) -> None:
    raw = read_json(stage / RAW_PATH)
    bundle = read_json(stage / "next/content" / ACTING_CRAFT_ID / "bundle.json")
    draft = read_json(stage / "next/content" / ACTING_CRAFT_ID / "draft.json")
    manifest = read_json(stage / "next/content" / ACTING_CRAFT_ID / "manifest.json")
    normalized = hashlib.sha256((stage / RAW_PATH).read_bytes().replace(b'\r\n', b'\n')).hexdigest()
    if raw["id"] != ACTING_CRAFT_ID or manifest["source_sha256"] != NORMALIZED_SOURCE_SHA256 or manifest['source_path'] != RAW_PATH:
        fail("raw/manifest identity mismatch")
    if not (len(raw["questions"]) == len(draft["questions"]) == len(bundle["quiz"]["questions"]) == len(manifest["questions"]) == 8):
        fail("Acting Craft raw/canonical question count differs")
    for source, authored, public, mapped in zip(raw["questions"], draft["questions"], bundle["quiz"]["questions"], manifest["questions"], strict=True):
        private = private_revision_input(bundle, public)
        expected = copy.deepcopy(authored)
        revision = expected.pop("revision")
        if private != expected or canonical_hash(private) != revision["sha256"] or revision != public["revision"]:
            fail("Acting Craft draft/public/private revision mismatch")
        if private["source"] != {"uri": "/app/" + RAW_PATH}:
            fail("Acting Craft runtime source must be URI-only")
        if source["id"] != public["question_id"] or source["text"] != public["stem"] or source["difficulty"] != public["difficulty_level"]:
            fail("Acting Craft raw/runtime identity or stem mismatch")
        if source["editorial_tag_ids"] != private.get("editorial_tag_ids") or source["explanation"] != mapped["source_explanation"]:
            fail("Acting Craft raw/runtime tags or explanation mismatch")
        if [option["text"] for option in public["options"]] != source["options"]:
            fail("Acting Craft raw/runtime option mismatch")
        key = source["correct_answer"]
        if type(key) is not int or not 0 <= key < len(source["options"]) or private["grading"]["correct_option_id"] != public["options"][key]["option_id"]:
            fail("Acting Craft raw/runtime grading mismatch")
        if mapped["source_id"] != source["id"] or mapped["canonical_id"] != public["question_id"] or mapped["options"] != [{"canonical_id": option["option_id"], "source_index": index} for index, option in enumerate(public["options"])]:
            fail("Acting Craft raw/runtime mapping mismatch")
    if [row['correct_answer'] for row in raw['questions']] != [0,1,2,3,0,1,2,3]:
        fail("Acting Craft answer positions differ from the frozen balanced keys")
    if normalized != NORMALIZED_SOURCE_SHA256:
        fail('raw normalized bytes differ from the manifest source digest')


def copy_and_check_actor_web(repo: Path, commit: str, stage: Path, production_web: Path, qa_web: Path, baseline_catalog: list[dict[str, Any]], baseline_articles: list[dict[str, Any]]) -> dict[str, str]:
    catalog_bytes = git_bytes(repo, commit, "next/apps/quiz_app/assets/catalog.json")
    reader_bytes = git_bytes(repo, commit, "next/apps/quiz_app/assets/study/question-articles.json")
    if hashlib.sha256(catalog_bytes).hexdigest() != FROZEN_CATALOG_SHA256 or hashlib.sha256(reader_bytes).hexdigest() != FROZEN_READER_SHA256:
        fail("frozen Acting Craft app asset SHA differs")
    catalog, articles = current_assets(catalog_bytes, reader_bytes, "frozen source")
    assert_preserved(baseline_catalog, baseline_articles, catalog, articles, "frozen source")
    for web, label in ((production_web, "production Flutter output"), (qa_web, "QA Flutter output")):
        expected_js = PRODUCTION_JS_SHA256 if web == production_web else QA_JS_SHA256
        if sha256_file(web / "main.dart.js") != expected_js:
            fail(f"{label} JavaScript differs from actual root build")
        embedded_catalog = (web / "assets" / "assets" / "catalog.json").read_bytes()
        embedded_reader = (web / "assets" / "assets" / "study" / "question-articles.json").read_bytes()
        if not (web / "main.dart.js").is_file() or embedded_catalog != catalog_bytes or embedded_reader != reader_bytes:
            fail(f"{label} lacks the frozen compiled Acting Craft assets")
        actual_catalog, actual_articles = current_assets(embedded_catalog, embedded_reader, label)
        assert_preserved(baseline_catalog, baseline_articles, actual_catalog, actual_articles, label)
    shutil.rmtree(stage / "web")
    shutil.copytree(production_web, stage / "web")
    copy_frozen_file(repo, commit, "next/apps/quiz_app/assets/catalog.json", stage / "next" / "apps" / "quiz_app" / "assets" / "catalog.json")
    copy_frozen_file(repo, commit, "next/apps/quiz_app/assets/study/question-articles.json", stage / "next" / "apps" / "quiz_app" / "assets" / "study" / "question-articles.json")
    return {"catalog_json_sha256": FROZEN_CATALOG_SHA256, "question_articles_json_sha256": FROZEN_READER_SHA256}


def append_actor_cache(stage: Path, baseline_cache: dict[str, Any]) -> None:
    path = stage / "runtime-bundles.json"
    cache = read_json(path)
    if cache != baseline_cache:
        fail("Helm50 runtime cache changed before Acting Craft append")
    cache[ACTING_CRAFT_ID] = read_json(stage / "next" / "content" / ACTING_CRAFT_ID / "bundle.json")
    if set(cache) != set(RUNTIME_IDS) or any(cache[key] != value for key, value in baseline_cache.items()):
        fail("runtime cache append changed an existing entry")
    write_json_lf(path, cache)


def replace_once(body: str, old: str, new: str, count: int = 1) -> str:
    if body.count(old) != count:
        fail(f"baseline anchor absent or duplicated: {old}")
    return body.replace(old, new)


def patch_actor_guards(stage: Path, build_id: str, commit: str, js_sha256: str, nginx_sha256: str) -> None:
    cutover = stage / "cutover.sh"
    text = cutover.read_text(encoding="utf-8")
    text = replace_once(text, BASELINE_BUILD, build_id)
    text = replace_once(text, r"r'quiz-2026\.10\.13-music-craft-[0-9a-f]{7}'", r"r'quiz-2026\.10\.14-acting-craft-[0-9a-f]{7}'")
    text = replace_once(text, BASELINE_SOURCE_COMMIT, commit, 2)
    text = replace_once(text, BASELINE_MAIN_DART_JS_SHA256, js_sha256, 2)
    old_image = "docker.io/library/quiz-master@sha256:6d2a206a6994b792bcc08fb0c05b5f36cbcb8c6983a6b76088a63471ab75daa6"
    text = replace_once(text, old_image, BASELINE_IMAGE)
    for old, new in (("meta['packs']==133", "meta['packs']==134"), ("meta['questions']==4052", "meta['questions']==4060"), ("meta['question_articles']==252", "meta['question_articles']==260")):
        text = replace_once(text, old, new)
    if text.count(PVC_UID) != 1 or API_SHA256 not in text or nginx_sha256 not in text:
        fail("baseline infrastructure guards differ")
    # Publication is exclusively the separately reviewed immutable-image publisher.
    if text.count('[[ "$quiz_mode" = prepare ]]') != 1 or 'helm upgrade' in text:
        fail("baseline cutover is not prepare-only")
    endpoint = 'exit 0\n'
    if text.count(endpoint) != 1:
        fail("baseline preparation endpoint changed")
    text = text.split(endpoint)[0] + endpoint
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
    body = replace_once(body, "assert after[3]-before[3]==133, 'Unexpected bundle-cache growth'", "assert after[3]-before[3]==134, 'Unexpected bundle-cache growth'")
    body = replace_once(body, "assert len(req('/v1/history',token=token))==11", "assert len(req('/v1/history',token=token))==12")
    old_ids = "['cinema-encore-20261011','music-encore-20261011','planet-paradoxes-20261010','philias-lifestyle-part-1','phobias-nature','home-alone-1-part-1','cinema-people-20261011','music-people-20261011','film-craft-20261013','music-craft-20261013']"
    body = replace_once(body, old_ids, old_ids[:-1] + ",'acting-craft-20261014']", 2)
    old = "  else:\n   assert len(matches)==(0 if qid in ['philias-lifestyle-part-1','phobias-nature'] else 28 if qid in ['cinema-people-20261011','music-people-20261011'] else 10)"
    new = "  elif qid=='acting-craft-20261014':\n   expected_article_refs=" + repr(ACTING_CRAFT_ARTICLE_REFS) + "\n   assert len(matches)==8 and {ref['question_id']:ref['revision_sha256'] for ref in matches}==expected_article_refs\n   assert {q['question_id']:q['revision']['sha256'] for q in live['quiz']['questions']}==expected_article_refs\n" + old
    body = replace_once(body, old, new)
    body = replace_once(body, "assert graded==203 and finished==11", "assert graded==211 and finished==12")
    body = replace_once(body, "'canonical_packs':10,'canonical_questions':148", "'canonical_packs':11,'canonical_questions':156")
    compile(body, "rehearse.py", "exec")
    rehearsal.write_text(body, encoding="utf-8", newline="\n")


def inject_version_after_compilation(stage: Path, build_id: str, frozen_commit: str) -> dict[str, Any]:
    web = stage / "web"
    metadata = {
        "buildId": build_id,
        "commit": frozen_commit,
        "source_commit": frozen_commit,
        "local_build": True,
        "packs": 134,
        "questions": 4060,
        "study_modules": 6,
        "study_questions": 120,
        "question_articles": 260,
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
    args = parser.parse_args()
    if args.frozen_commit != FROZEN_COMMIT:
        fail("--frozen-commit must be the accepted full Acting Craft integration SHA")
    verified = subprocess.run(["git", "-C", str(args.repo), "rev-parse", "--verify", f"{args.frozen_commit}^{{commit}}"], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if verified.returncode != 0 or verified.stdout.decode().strip() != args.frozen_commit:
        fail("--frozen-commit is not an object in --repo")
    build_id = f"quiz-2026.10.14-acting-craft-{args.frozen_commit[:7]}"
    if args.output_root.exists() and any(args.output_root.iterdir()):
        fail("--output-root must be absent or empty")
    args.output_root.mkdir(parents=True, exist_ok=True)
    stage = args.output_root / build_id
    extract_immutable(args.prior_archive, stage)
    baseline_catalog, baseline_articles, baseline_cache, baseline_content = preserved_helm50(stage)
    baseline_raw = {p.relative_to(stage).as_posix(): sha256_file(p) for p in (stage / "quizzes").rglob("*.json")}
    nginx_sha = copy_and_check_nginx_config(args.repo, args.frozen_commit, stage)
    copy_actor_inputs(args.repo, args.frozen_commit, stage)
    verify_actor_raw_parity(stage)
    assets = copy_and_check_actor_web(args.repo, args.frozen_commit, stage, args.production_web, args.qa_web, baseline_catalog, baseline_articles)
    append_actor_cache(stage, baseline_cache)
    assert_content_preserved(stage, baseline_content)
    if any(sha256_file(stage / path) != digest for path, digest in baseline_raw.items()):
        fail("existing raw quiz input changed")
    metadata = inject_version_after_compilation(stage, build_id, args.frozen_commit)
    patch_actor_guards(stage, build_id, args.frozen_commit, metadata["main_dart_js_sha256"], nginx_sha)
    expected, proof = expected_staging_revisions(stage, build_id)
    write_json_lf(stage / "expected-staging-revisions.json", expected)
    file_members, manifest_sha256 = write_checksums(stage)
    archive, archive_sha256, tar_members = archive_and_verify(stage, args.output_root)
    result = {"status":"PREPARED_NOT_EXECUTED","build_id":build_id,"frozen_commit":args.frozen_commit,"baseline_input":{"archive":str(args.prior_archive),"archive_sha256":BASELINE_ARCHIVE_SHA256,"image":BASELINE_IMAGE,"pvc_uid":PVC_UID},"counts":{"packs":134,"questions":4060,"reader_articles":260,"preserved_catalog_rows":133,"preserved_questions":4052,"preserved_article_objects":248,"approved_music_title_articles":4,"approved_music_source_titles":8,"baseline_cache_entries":10,"runtime_cache_entries":11,"acting_craft_questions":8,"staging_canonical_questions":156,"home_alone_questions":25},"metadata":metadata,"frozen_source_assets":assets,"nginx_config_sha256":nginx_sha,"api_sha256":API_SHA256,"qa_web_checked_not_packaged":str(args.qa_web),"expected_staging_revision_proof":proof,"stage":str(stage),"archive":str(archive),"archive_sha256":archive_sha256,"file_members":file_members,"tar_members":tar_members,"manifest_sha256":manifest_sha256,"remaining_gates":["actual Root local browser/lifecycle proof","independent review","copied-DB rehearsal and rollback","image/Helm/server/browser gates","authorized publication"]}
    write_json_lf(args.output_root / "package-preparation.json", result)
    print(json.dumps({key:result[key] for key in ("status","build_id","stage","archive","archive_sha256","counts")}, ensure_ascii=False))


if __name__ == "__main__":
    main()
