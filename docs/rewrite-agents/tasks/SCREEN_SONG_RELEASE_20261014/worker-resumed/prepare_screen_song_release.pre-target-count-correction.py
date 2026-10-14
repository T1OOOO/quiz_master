#!/usr/bin/env python3
"""Prepare (but never publish) the immutable Screen Song release package.

This controller is deliberately inert until the release lead supplies a frozen
commit and freshly built production/QA Flutter directories.  It starts from the
approved Actor51 package, preserving its runtime/cache/content guards while
appending only the Screen Song inputs supplied in a future pinned review.
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

BASELINE_BUILD = "quiz-2026.10.14-acting-craft-83748f5"
BASELINE_ARCHIVE_SHA256 = "9d9fdb8dff8ec88b51c8adcd987a093a3a10150cb7c6f7e667c89f416933c934"
BASELINE_IMAGE = "docker.io/library/quiz-master@sha256:039474ddb2feac0986908a7681c18fcf39cb716428e9c8acf199e8f9e044c961"
NGINX_CONFIG_PATH = "next/infra/production/nginx.conf"
NGINX_CONFIG_SHA256 = "e9add812a138010e443463acb455295103dc69886ca32cd17dafbccfa676d6bc"
PVC_UID = "7fc2428f-4146-4c78-a26d-2347d9f3b7bf"
API_SHA256 = "26e1657fd6259bdbbef9178cbe9343b775406d91c56cb9661d302ad530ab6f01"
FROZEN_READER_SHA256 = None
HOME_ALONE_ID = "home-alone-1-part-1"
RUNTIME_IDS = (
    "cinema-encore-20261011", "cinema-people-20261011", "home-alone-1-part-1",
    "music-encore-20261011", "music-people-20261011", "philias-lifestyle-part-1",
    "phobias-nature", "planet-paradoxes-20261010",
)

BASELINE_RUNTIME_IDS = RUNTIME_IDS + ("film-craft-20261013", "music-craft-20261013", "acting-craft-20261014",)
SCREEN_SONG_ID = "screen-song-20261014"
RUNTIME_IDS = BASELINE_RUNTIME_IDS + (SCREEN_SONG_ID,)
BASELINE_MAIN_DART_JS_SHA256 = "a091340ebda85029c7f6d33fe382800d113feb9422c1b77f7647b6901223513a"
FROZEN_CATALOG_SHA256 = None
FROZEN_SCREEN_FILES = {}
SCREEN_SONG_ARTICLE_REFS = {}
RAW_PATH = "quizzes/Cinema/screen_song_20261014.json"
NORMALIZED_SOURCE_SHA256 = None
FROZEN_COMMIT = None
BASELINE_SOURCE_COMMIT = "83748f5a467092302184bcbeee1bd1d7d4b964fa"
PRODUCTION_JS_SHA256 = None
QA_JS_SHA256 = None
BUILD_ID = None
RELEASE_PINS = None
RELEASE_PINS_SHA256 = None


def require_loaded_pins():
    if RELEASE_PINS is None:
        fail('fresh full Screen Song source/build pins are required')


def load_required_pins(path: Path):
    if not path.is_file():
        fail('missing fresh release pins: '+str(path))
    pins = read_json(path)
    required = {'schema_version','frozen_commit','build_id','frozen_files','article_refs','normalized_source_sha256','production_js_sha256','qa_js_sha256','production_web','qa_web','build_evidence','build_evidence_sha256','source_review','export_review'}
    if not isinstance(pins,dict) or not required <= set(pins) or pins.get('schema_version')!='qm-screen-song-release-pins/v1':
        fail('complete fresh source/build/review pins are required')
    commit = pins['frozen_commit']
    if not isinstance(commit,str) or re.fullmatch(r'[a-f0-9]{40}',commit) is None or commit in (BASELINE_SOURCE_COMMIT,'b80deb12844aa786e9e0351273eab3f525ddce27') or commit.startswith('25be93a'):
        fail('fresh final Screen Song source is required; Actor/current checkpoint is not a target')
    if pins['build_id']!='quiz-2026.10.14-screen-song-'+commit[:7]:
        fail('fresh build/source pins differ')
    files = pins['frozen_files']
    required_files = {RAW_PATH,*[f'next/content/{SCREEN_SONG_ID}/{name}.json' for name in ('draft','bundle','manifest')],f'study/question_articles/drafts/{SCREEN_SONG_ID}.json',f'study/question_articles/reviews/{SCREEN_SONG_ID}-review.json','next/apps/quiz_app/assets/catalog.json','next/apps/quiz_app/assets/study/question-articles.json'}
    refs = pins['article_refs']
    if not isinstance(files,dict) or set(files)!=required_files or not isinstance(refs,dict) or set(refs)!={f'screen-song-pilot-{i:03d}' for i in range(1,5)}:
        fail('full eight-file/four actual revision pins are required')
    digests = [*files.values(),*refs.values(),pins['normalized_source_sha256'],pins['production_js_sha256'],pins['qa_js_sha256'],pins['build_evidence_sha256']]
    if any(not isinstance(value,str) or re.fullmatch(r'[a-f0-9]{64}',value) is None for value in digests):
        fail('release pins require full SHA256 digests')
    if pins['production_js_sha256']==pins['qa_js_sha256']:
        fail('production/QA pins must describe separate compiled API configurations')
    # Actual accepted source/export callbacks precede packaging; controller/QA
    # acceptance remains separately mandatory before any remote preparation.
    from prepare_remote import require_actual_acceptance
    for key in ('source_review','export_review'):
        proof = pins[key]
        if not isinstance(proof,dict) or set(proof)!={'path','sha256'}:
            fail('actual source/export review pins are required')
        review_path = Path(proof['path'])
        if sha256_file(review_path)!=proof['sha256']:
            fail('actual review evidence hash differs: '+key)
        require_actual_acceptance(read_json(review_path))
    build_path = Path(pins['build_evidence'])
    if sha256_file(build_path)!=pins['build_evidence_sha256']:
        fail('actual build evidence hash differs')
    build = read_json(build_path)
    rows = build.get('checks',[])
    if build.get('frozen_source')!=commit or build.get('build_id')!=pins['build_id'] or len(rows)!=2 or {row.get('label') for row in rows}!={'production','qa'}:
        fail('two actual fresh source-bound build records required')
    for row in rows:
        label = row['label']
        web = Path(pins[label+'_web'])
        if row.get('actual_exit')!=0 or row.get('frozen_assets_byte_identical') is not True or Path(row.get('output','')).resolve()!=web.resolve() or row.get('main_dart_js_sha256')!=pins[label+'_js_sha256'] or sha256_file(web/'main.dart.js')!=pins[label+'_js_sha256']:
            fail('actual compiled output/build pins differ: '+label)
        for source,relative in (('next/apps/quiz_app/assets/catalog.json','catalog.json'),('next/apps/quiz_app/assets/study/question-articles.json','study/question-articles.json')):
            if sha256_file(web/'assets/assets'/relative)!=files[source]:
                fail('compiled fresh asset pins differ: '+relative)
    globals().update(FROZEN_COMMIT=commit,BUILD_ID=pins['build_id'],FROZEN_SCREEN_FILES=files,SCREEN_SONG_ARTICLE_REFS=refs,NORMALIZED_SOURCE_SHA256=pins['normalized_source_sha256'],PRODUCTION_JS_SHA256=pins['production_js_sha256'],QA_JS_SHA256=pins['qa_js_sha256'],FROZEN_CATALOG_SHA256=files['next/apps/quiz_app/assets/catalog.json'],FROZEN_READER_SHA256=files['next/apps/quiz_app/assets/study/question-articles.json'],RELEASE_PINS=pins,RELEASE_PINS_SHA256=sha256_file(path))
    return pins


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
    require_loaded_pins()
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
    if sum(len(rows) for rows in expected.values()) != 160:
        fail("expected exactly 160 canonical staging revisions")
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
    if len(catalog) != 135 or sum(row["questions_count"] for row in catalog) != 4064:
        fail(f"{label} must contain 135 packs / 4064 questions")
    if len(articles) != 264 or any(row.get("status") != "accepted" for row in articles):
        fail(f"{label} must contain 264 accepted Reader articles")
    return catalog, articles


def preserved_actor51(stage: Path) -> tuple[list[dict[str, Any]], list[dict[str, Any]], dict[str, Any], dict[str, str]]:
    meta = read_json(stage / "web" / "version.json")
    if meta.get("buildId") != BASELINE_BUILD or meta.get("source_commit") != BASELINE_SOURCE_COMMIT or meta.get("commit") != BASELINE_SOURCE_COMMIT:
        fail("Actor51 baseline source/build differs")
    for path, expected in ((stage / "api", API_SHA256), (stage / "nginx.conf", NGINX_CONFIG_SHA256), (stage / "web" / "main.dart.js", BASELINE_MAIN_DART_JS_SHA256)):
        if sha256_file(path) != expected:
            fail(f"Actor51 baseline binary/config differs: {path.name}")
    root = stage / "web" / "assets" / "assets"
    catalog = rows(read_json(root / "catalog.json"), "Actor51 catalog")
    articles = rows(read_json(root / "study" / "question-articles.json"), "Actor51 Reader")
    cache = read_json(stage / "runtime-bundles.json")
    if len(catalog) != 134 or sum(row["questions_count"] for row in catalog) != 4060 or len(articles) != 260:
        fail("Actor51 baseline counts differ")
    if set(cache) != set(BASELINE_RUNTIME_IDS):
        fail("Actor51 cache must contain exactly eleven runtime entries")
    home = read_json(stage / "next" / "content" / HOME_ALONE_ID / "bundle.json")
    if len(home["quiz"]["questions"]) != 25 or cache.get(HOME_ALONE_ID) != home:
        fail("Actor51 Home Alone bundle/cache guard differs")
    for quiz_id in ("cinema-people-20261011", "music-people-20261011"):
        bundle = read_json(stage / "next" / "content" / quiz_id / "bundle.json")
        if len(bundle["quiz"]["questions"]) != 28 or cache.get(quiz_id) != bundle:
            fail(f"Actor51 People guard differs: {quiz_id}")
    content = {path.relative_to(stage / "next" / "content").as_posix(): sha256_file(path) for path in (stage / "next" / "content").rglob("*.json")}
    return copy.deepcopy(catalog), copy.deepcopy(articles), copy.deepcopy(cache), content


def assert_preserved(baseline_catalog, baseline_articles, catalog, articles, label):
    old_catalog = {row['quiz_id']:row for row in baseline_catalog}
    now_catalog = {row['quiz_id']:row for row in catalog}
    if set(now_catalog)-set(old_catalog)!={SCREEN_SONG_ID} or any(now_catalog.get(key)!=row for key,row in old_catalog.items()):
        fail(f'{label} must preserve all134 Actor51 catalog rows and add only Screen Song')
    old_articles = {row['id']:row for row in baseline_articles}
    now_articles = {row['id']:row for row in articles}
    if any(now_articles.get(key)!=row for key,row in old_articles.items()):
        fail(f'{label} changed an existing Actor51 Reader article')
    added = [row for row in articles if row['id'] not in old_articles]
    refs = [ref for row in added for ref in row.get('question_refs',[]) if ref.get('quiz_id')==SCREEN_SONG_ID]
    if len(added)!=4 or len(refs)!=4 or {ref['question_id']:ref['revision_sha256'] for ref in refs}!=SCREEN_SONG_ARTICLE_REFS or any(len(row.get('source_links',[]))!=2 or r'\\n' in row['body_ru'] for row in added):
        fail(f'{label} must append four approved Screen Song refs/eight sources with real newlines')


def assert_content_preserved(stage: Path, baseline: dict[str, str]) -> None:
    root = stage / "next" / "content"
    current = {path.relative_to(root).as_posix(): sha256_file(path) for path in root.rglob("*.json")}
    new_files = {f"{SCREEN_SONG_ID}/draft.json", f"{SCREEN_SONG_ID}/bundle.json", f"{SCREEN_SONG_ID}/manifest.json"}
    if set(current) - set(baseline) != new_files or any(current[key] != digest for key, digest in baseline.items()):
        fail("Screen Song preparation changed existing Actor51 canonical content")


def copy_screen_inputs(repo: Path, commit: str, stage: Path) -> None:
    for relative, expected in FROZEN_SCREEN_FILES.items():
        payload = git_bytes(repo, commit, relative)
        if hashlib.sha256(payload).hexdigest() != expected:
            fail(f"frozen Screen Song SHA differs: {relative}")
        if not (repo / relative).is_file() or sha256_file(repo / relative) != expected:
            fail(f"working source differs from frozen Git input: {relative}")
        target = stage / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(payload)
    bundle = read_json(stage / "next" / "content" / SCREEN_SONG_ID / "bundle.json")
    if {row["question_id"]: row["revision"]["sha256"] for row in bundle["quiz"]["questions"]} != SCREEN_SONG_ARTICLE_REFS:
        fail("Screen Song bundle refs differ from frozen accepted refs")


def verify_screen_raw_parity(stage: Path) -> None:
    require_loaded_pins()
    raw = read_json(stage / RAW_PATH)
    bundle = read_json(stage / "next/content" / SCREEN_SONG_ID / "bundle.json")
    draft = read_json(stage / "next/content" / SCREEN_SONG_ID / "draft.json")
    manifest = read_json(stage / "next/content" / SCREEN_SONG_ID / "manifest.json")
    normalized = hashlib.sha256((stage / RAW_PATH).read_bytes().replace(b'\r\n', b'\n').replace(b'\r', b'\n')).hexdigest()
    if raw["id"] != SCREEN_SONG_ID or manifest["source_sha256"] != NORMALIZED_SOURCE_SHA256 or manifest['source_path'] != RAW_PATH:
        fail("raw/manifest identity mismatch")
    if not (len(raw["questions"]) == len(draft["questions"]) == len(bundle["quiz"]["questions"]) == len(manifest["questions"]) == 4):
        fail("Screen Song raw/canonical question count differs")
    for source, authored, public, mapped in zip(raw["questions"], draft["questions"], bundle["quiz"]["questions"], manifest["questions"], strict=True):
        private = private_revision_input(bundle, public)
        expected = copy.deepcopy(authored)
        revision = expected.pop("revision")
        if private != expected or canonical_hash(private) != revision["sha256"] or revision != public["revision"]:
            fail("Screen Song draft/public/private revision mismatch")
        if private["source"] != {"uri": "/app/" + RAW_PATH}:
            fail("Screen Song runtime source must be URI-only")
        if source["id"] != public["question_id"] or source["text"] != public["stem"] or source["difficulty"] != public["difficulty_level"]:
            fail("Screen Song raw/runtime identity or stem mismatch")
        if source["editorial_tag_ids"] != private.get("editorial_tag_ids") or source["explanation"] != mapped["source_explanation"]:
            fail("Screen Song raw/runtime tags or explanation mismatch")
        if [option["text"] for option in public["options"]] != source["options"]:
            fail("Screen Song raw/runtime option mismatch")
        key = source["correct_answer"]
        if type(key) is not int or not 0 <= key < len(source["options"]) or private["grading"]["correct_option_id"] != public["options"][key]["option_id"]:
            fail("Screen Song raw/runtime grading mismatch")
        if mapped["source_id"] != source["id"] or mapped["canonical_id"] != public["question_id"] or mapped["options"] != [{"canonical_id": option["option_id"], "source_index": index} for index, option in enumerate(public["options"])]:
            fail("Screen Song raw/runtime mapping mismatch")
    if [row['correct_answer'] for row in raw['questions']] != [0,1,2,3]:
        fail("Screen Song answer positions differ from the frozen balanced keys")
    if normalized != NORMALIZED_SOURCE_SHA256:
        fail('raw normalized bytes differ from the manifest source digest')


def copy_and_check_screen_web(repo: Path, commit: str, stage: Path, production_web: Path, qa_web: Path, baseline_catalog: list[dict[str, Any]], baseline_articles: list[dict[str, Any]]) -> dict[str, str]:
    catalog_bytes = git_bytes(repo, commit, "next/apps/quiz_app/assets/catalog.json")
    reader_bytes = git_bytes(repo, commit, "next/apps/quiz_app/assets/study/question-articles.json")
    if hashlib.sha256(catalog_bytes).hexdigest() != FROZEN_CATALOG_SHA256 or hashlib.sha256(reader_bytes).hexdigest() != FROZEN_READER_SHA256:
        fail("frozen Screen Song app asset SHA differs")
    catalog, articles = current_assets(catalog_bytes, reader_bytes, "frozen source")
    assert_preserved(baseline_catalog, baseline_articles, catalog, articles, "frozen source")
    for web, label in ((production_web, "production Flutter output"), (qa_web, "QA Flutter output")):
        expected_js = PRODUCTION_JS_SHA256 if web == production_web else QA_JS_SHA256
        if sha256_file(web / "main.dart.js") != expected_js:
            fail(f"{label} JavaScript differs from actual root build")
        embedded_catalog = (web / "assets" / "assets" / "catalog.json").read_bytes()
        embedded_reader = (web / "assets" / "assets" / "study" / "question-articles.json").read_bytes()
        if not (web / "main.dart.js").is_file() or embedded_catalog != catalog_bytes or embedded_reader != reader_bytes:
            fail(f"{label} lacks the frozen compiled Screen Song assets")
        actual_catalog, actual_articles = current_assets(embedded_catalog, embedded_reader, label)
        assert_preserved(baseline_catalog, baseline_articles, actual_catalog, actual_articles, label)
    shutil.rmtree(stage / "web")
    shutil.copytree(production_web, stage / "web")
    copy_frozen_file(repo, commit, "next/apps/quiz_app/assets/catalog.json", stage / "next" / "apps" / "quiz_app" / "assets" / "catalog.json")
    copy_frozen_file(repo, commit, "next/apps/quiz_app/assets/study/question-articles.json", stage / "next" / "apps" / "quiz_app" / "assets" / "study" / "question-articles.json")
    return {"catalog_json_sha256": FROZEN_CATALOG_SHA256, "question_articles_json_sha256": FROZEN_READER_SHA256}


def append_screen_cache(stage: Path, baseline_cache: dict[str, Any]) -> None:
    path = stage / "runtime-bundles.json"
    cache = read_json(path)
    if cache != baseline_cache:
        fail("Actor51 runtime cache changed before Screen Song append")
    cache[SCREEN_SONG_ID] = read_json(stage / "next" / "content" / SCREEN_SONG_ID / "bundle.json")
    if set(cache) != set(RUNTIME_IDS) or any(cache[key] != value for key, value in baseline_cache.items()):
        fail("runtime cache append changed an existing entry")
    write_json_lf(path, cache)


def replace_once(body: str, old: str, new: str, count: int = 1) -> str:
    if body.count(old) != count:
        fail(f"baseline anchor absent or duplicated: {old}")
    return body.replace(old, new)


def patch_screen_guards(stage: Path, build_id: str, commit: str, js_sha256: str, nginx_sha256: str) -> None:
    require_loaded_pins()
    cutover = stage / "cutover.sh"
    text = cutover.read_text(encoding="utf-8")
    text = replace_once(text, BASELINE_BUILD, build_id)
    text = replace_once(text, r"r'quiz-2026\.10\.14-acting-craft-[0-9a-f]{7}'", r"r'quiz-2026\.10\.14-screen-song-[0-9a-f]{7}'")
    text = replace_once(text, BASELINE_SOURCE_COMMIT, commit, 2)
    text = replace_once(text, BASELINE_MAIN_DART_JS_SHA256, js_sha256, 2)
    old_image = "docker.io/library/quiz-master@sha256:b94a399359f87024f5b00a53c47852a3e8f90f1ba6f4bb861385e9c2655f17d7"
    text = replace_once(text, old_image, BASELINE_IMAGE)
    for old, new in (("meta['packs']==134", "meta['packs']==135"), ("meta['questions']==4060", "meta['questions']==4064"), ("meta['question_articles']==260", "meta['question_articles']==264")):
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
    body = replace_once(body, "assert after[3]-before[3]==134, 'Unexpected bundle-cache growth'", "assert after[3]-before[3]==135, 'Unexpected bundle-cache growth'")
    body = replace_once(body, "assert len(req('/v1/history',token=token))==12", "assert len(req('/v1/history',token=token))==13")
    old_ids = "['cinema-encore-20261011','music-encore-20261011','planet-paradoxes-20261010','philias-lifestyle-part-1','phobias-nature','home-alone-1-part-1','cinema-people-20261011','music-people-20261011','film-craft-20261013','music-craft-20261013','acting-craft-20261014']"
    body = replace_once(body, old_ids, old_ids[:-1] + ",'screen-song-20261014']", 2)
    old = "  else:\n   assert len(matches)==(0 if qid in ['philias-lifestyle-part-1','phobias-nature'] else 28 if qid in ['cinema-people-20261011','music-people-20261011'] else 10)"
    new = "  elif qid=='screen-song-20261014':\n   expected_article_refs=" + repr(SCREEN_SONG_ARTICLE_REFS) + "\n   assert len(matches)==4 and {ref['question_id']:ref['revision_sha256'] for ref in matches}==expected_article_refs\n   assert {q['question_id']:q['revision']['sha256'] for q in live['quiz']['questions']}==expected_article_refs\n" + old
    body = replace_once(body, old, new)
    body = replace_once(body, "assert graded==211 and finished==12", "assert graded==215 and finished==13")
    body = replace_once(body, "'canonical_packs':11,'canonical_questions':156", "'canonical_packs':12,'canonical_questions':160")
    compile(body, "rehearse.py", "exec")
    rehearsal.write_text(body, encoding="utf-8", newline="\n")


def inject_version_after_compilation(stage: Path, build_id: str, frozen_commit: str) -> dict[str, Any]:
    web = stage / "web"
    metadata = {
        "buildId": build_id,
        "commit": frozen_commit,
        "source_commit": frozen_commit,
        "local_build": True,
        "packs": 135,
        "questions": 4064,
        "study_modules": 6,
        "study_questions": 120,
        "question_articles": 264,
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
    parser.add_argument("--pins", type=Path, required=True)
    parser.add_argument("--repo", type=Path, required=True)
    parser.add_argument("--frozen-commit", required=True)
    parser.add_argument("--production-web", type=Path, required=True)
    parser.add_argument("--qa-web", type=Path, required=True)
    parser.add_argument("--output-root", type=Path, required=True)
    parser.add_argument("--prior-archive", type=Path, required=True)
    args = parser.parse_args()
    load_required_pins(args.pins)
    if args.production_web.resolve()!=Path(RELEASE_PINS["production_web"]).resolve() or args.qa_web.resolve()!=Path(RELEASE_PINS["qa_web"]).resolve():
        fail("compiled directories differ from fresh release pins")
    if args.frozen_commit != FROZEN_COMMIT:
        fail("--frozen-commit must be the accepted full Screen Song integration SHA")
    verified = subprocess.run(["git", "-C", str(args.repo), "rev-parse", "--verify", f"{args.frozen_commit}^{{commit}}"], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if verified.returncode != 0 or verified.stdout.decode().strip() != args.frozen_commit:
        fail("--frozen-commit is not an object in --repo")
    build_id = BUILD_ID
    if args.output_root.exists() and any(args.output_root.iterdir()):
        fail("--output-root must be absent or empty")
    args.output_root.mkdir(parents=True, exist_ok=True)
    stage = args.output_root / build_id
    extract_immutable(args.prior_archive, stage)
    baseline_catalog, baseline_articles, baseline_cache, baseline_content = preserved_actor51(stage)
    baseline_raw = {p.relative_to(stage).as_posix(): sha256_file(p) for p in (stage / "quizzes").rglob("*.json")}
    nginx_sha = copy_and_check_nginx_config(args.repo, args.frozen_commit, stage)
    copy_screen_inputs(args.repo, args.frozen_commit, stage)
    verify_screen_raw_parity(stage)
    assets = copy_and_check_screen_web(args.repo, args.frozen_commit, stage, args.production_web, args.qa_web, baseline_catalog, baseline_articles)
    append_screen_cache(stage, baseline_cache)
    assert_content_preserved(stage, baseline_content)
    if any(sha256_file(stage / path) != digest for path, digest in baseline_raw.items()):
        fail("existing raw quiz input changed")
    metadata = inject_version_after_compilation(stage, build_id, args.frozen_commit)
    patch_screen_guards(stage, build_id, args.frozen_commit, metadata["main_dart_js_sha256"], nginx_sha)
    expected, proof = expected_staging_revisions(stage, build_id)
    write_json_lf(stage / "expected-staging-revisions.json", expected)
    file_members, manifest_sha256 = write_checksums(stage)
    archive, archive_sha256, tar_members = archive_and_verify(stage, args.output_root)
    result = {"status":"PREPARED_NOT_EXECUTED","build_id":build_id,"frozen_commit":args.frozen_commit,"release_pins_sha256":sha256_file(args.pins),"baseline_input":{"archive":str(args.prior_archive),"archive_sha256":BASELINE_ARCHIVE_SHA256,"image":BASELINE_IMAGE,"pvc_uid":PVC_UID},"counts":{"packs":134,"questions":4060,"reader_articles":260,"preserved_catalog_rows":134,"preserved_questions":4060,"preserved_article_objects":260,"baseline_cache_entries":11,"runtime_cache_entries":12,"screen_song_questions":4,"staging_canonical_questions":160,"home_alone_questions":25},"metadata":metadata,"frozen_source_assets":assets,"nginx_config_sha256":nginx_sha,"api_sha256":API_SHA256,"qa_web_checked_not_packaged":str(args.qa_web),"expected_staging_revision_proof":proof,"stage":str(stage),"archive":str(archive),"archive_sha256":archive_sha256,"file_members":file_members,"tar_members":tar_members,"manifest_sha256":manifest_sha256,"remaining_gates":["actual Root local browser/lifecycle proof","independent review","copied-DB rehearsal and rollback","image/Helm/server/browser gates","authorized publication"]}
    write_json_lf(args.output_root / "package-preparation.json", result)
    print(json.dumps({key:result[key] for key in ("status","build_id","stage","archive","archive_sha256","counts")}, ensure_ascii=False))


if __name__ == "__main__":
    main()
