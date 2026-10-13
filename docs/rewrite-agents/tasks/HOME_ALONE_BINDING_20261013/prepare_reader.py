"""Prepare a hash-pinned, non-destructive Home Alone Reader overlay.

This is deliberately a source-preparation tool.  It reads the current 242-row
Reader catalog, the independently accepted two-row draft, and the immutable
published Home Alone bundle, then writes a *new* 244-row catalog only when an
explicit, absent output path is supplied.  It does not edit runtime assets.
"""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
from typing import Any
from urllib.parse import urlparse


ROOT = Path(__file__).resolve().parents[4]
DEFAULT_BASELINE = ROOT / "next/apps/quiz_app/assets/study/question-articles.json"
DEFAULT_DRAFT = ROOT / "docs/rewrite-agents/tasks/HOME_ALONE_ARTICLES_20261013/writer-v3.json"
DEFAULT_REVIEW = ROOT / "docs/rewrite-agents/tasks/HOME_ALONE_ARTICLES_20261013/independent-review-v3.json"
DEFAULT_BUNDLE = ROOT / ".run/culture_next7_release_root_20261013/package-v2/quiz-2026.10.13-culture-e437661/next/content/home-alone-1-part-1/bundle.json"

BASELINE_SHA256 = "1eec259aa70e73dab9b3b357d4f05d274136c5a13ef023f5917fd63547590aa0"
DRAFT_SHA256 = "b734f5c0b06d29d1607b6d62098ee85c854953e960ce47b4b80b96268292c7ff"
PUBLISHED_BUNDLE_SHA256 = "58540f20607cf0d4294788a9e039b9797a9861ed3375e0aefcbd680461bf3746"

EXPECTED_DRAFT_REFS = {
    "question:q-ha1-p1-1": ("home-alone-1-part-1", "q-ha1-p1-1", "b0f0047c659e193d6790f6cc209cb1135650cab8f8a2f716fda3c20d0a6e787f"),
    "question:q-ha1-p1-2": ("home-alone-1-part-1", "q-ha1-p1-2", "0c4a99cddbb490c34f4918bac8f7ed1588b50acbd1ed6378fc8212ed5bf6005d"),
}


def fail(message: str) -> None:
    raise ValueError(message)


def sha256_bytes(raw: bytes) -> str:
    return hashlib.sha256(raw).hexdigest()


def read_json_with_hash(path: Path, expected_hash: str, label: str) -> Any:
    if not path.is_file():
        fail(f"{label}: missing file: {path}")
    raw = path.read_bytes()
    actual_hash = sha256_bytes(raw)
    if actual_hash != expected_hash:
        fail(f"{label}: SHA-256 mismatch; expected {expected_hash}, got {actual_hash}")
    try:
        return json.loads(raw.decode("utf-8-sig"))
    except (UnicodeDecodeError, json.JSONDecodeError) as error:
        fail(f"{label}: invalid JSON: {error}")


def require_article_shape(article: dict[str, Any], label: str) -> None:
    if not isinstance(article.get("id"), str) or not article["id"]:
        fail(f"{label}: missing article id")
    for field in ("title_ru", "body_ru"):
        if not isinstance(article.get(field), str) or not article[field].strip():
            fail(f"{label}: missing {field}")
    links = article.get("source_links")
    if not isinstance(links, list) or not 2 <= len(links) <= 5:
        fail(f"{label}: requires 2-5 source links")
    seen_urls: set[str] = set()
    for source in links:
        if not isinstance(source, dict):
            fail(f"{label}: malformed source link")
        url = source.get("url")
        parsed = urlparse(url) if isinstance(url, str) else None
        if not parsed or parsed.scheme != "https" or not parsed.netloc or parsed.username or parsed.password:
            fail(f"{label}: invalid source URL")
        if url in seen_urls:
            fail(f"{label}: duplicate source URL")
        seen_urls.add(url)
        if not all(isinstance(source.get(key), str) and source[key].strip() for key in ("title", "supports", "accessed")):
            fail(f"{label}: incomplete source metadata")
    question_refs = article.get("question_refs")
    target_refs = article.get("target_refs")
    if not isinstance(question_refs, list) or not isinstance(target_refs, list) or not (question_refs or target_refs):
        fail(f"{label}: requires question_refs or target_refs")


def question_ref_tuple(ref: Any, label: str) -> tuple[str, str, str]:
    if not isinstance(ref, dict):
        fail(f"{label}: malformed question ref")
    values = (ref.get("quiz_id"), ref.get("question_id"), ref.get("revision_sha256"))
    if not all(isinstance(value, str) and value for value in values):
        fail(f"{label}: incomplete question ref")
    revision = values[2]
    if len(revision) != 64 or any(char not in "0123456789abcdef" for char in revision):
        fail(f"{label}: question ref revision must be lowercase SHA-256")
    return values


def validate_output_schema(catalog: dict[str, Any]) -> None:
    if catalog.get("schema_version") != "qm-question-articles/v1":
        fail("output: schema_version must be qm-question-articles/v1")
    articles = catalog.get("articles")
    if not isinstance(articles, list) or len(articles) != 244:
        fail("output: expected exactly 244 articles")
    article_ids: set[str] = set()
    question_bindings: set[tuple[str, str, str]] = set()
    for index, article in enumerate(articles):
        if not isinstance(article, dict):
            fail(f"output: article {index} is not an object")
        require_article_shape(article, f"output article {index}")
        if article.get("status") != "accepted":
            fail(f"output article {article['id']}: status must be accepted")
        if article["id"] in article_ids:
            fail(f"output: duplicate article id {article['id']}")
        article_ids.add(article["id"])
        for ref in article["question_refs"]:
            binding = question_ref_tuple(ref, f"output article {article['id']}")
            if binding in question_bindings:
                fail(f"output: duplicate question ref {binding}")
            question_bindings.add(binding)


def validate_published_bundle(bundle: dict[str, Any]) -> dict[tuple[str, str], str]:
    quiz = bundle.get("quiz")
    if not isinstance(quiz, dict) or quiz.get("quiz_id") != "home-alone-1-part-1":
        fail("published bundle: unexpected quiz identity")
    questions = quiz.get("questions")
    if not isinstance(questions, list) or len(questions) != 25:
        fail("published bundle: expected all 25 released repaired questions")
    revisions: dict[tuple[str, str], str] = {}
    for question in questions:
        if not isinstance(question, dict):
            fail("published bundle: malformed question")
        question_id = question.get("question_id")
        revision = question.get("revision")
        revision_hash = revision.get("sha256") if isinstance(revision, dict) else None
        key = ("home-alone-1-part-1", question_id)
        if not isinstance(question_id, str) or not isinstance(revision_hash, str) or len(revision_hash) != 64:
            fail("published bundle: malformed question revision")
        if key in revisions:
            fail(f"published bundle: duplicate question {question_id}")
        revisions[key] = revision_hash
    if len(revisions) != 25:
        fail("published bundle: repaired question set is incomplete")
    return revisions


def accepted_draft_articles(draft: dict[str, Any], review: dict[str, Any], revisions: dict[tuple[str, str], str]) -> list[dict[str, Any]]:
    if review.get("verdict") != "ACCEPT" or review.get("actual_exit") != 0:
        fail("independent review: V3 does not record an accepted successful review")
    if review.get("input_sha256") != DRAFT_SHA256:
        fail("independent review: accepted hash does not pin writer-v3")
    delivery = review.get("hub_message_delivery")
    message_id = delivery.get("actual_tool_result", {}).get("id") if isinstance(delivery, dict) else None
    if message_id != 36692:
        fail("independent review: expected actual Claude verdict delivery message 36692")
    # The historical native task could not be resubmitted; acceptance here is
    # deliberately limited to this independently reviewed source draft.
    if review.get("formal_task_acceptance") is not False:
        fail("independent review: historical formal-task limitation changed")

    articles = draft.get("articles")
    if not isinstance(articles, list) or len(articles) != 2:
        fail("draft: expected exactly two articles")
    by_id = {article.get("id"): article for article in articles if isinstance(article, dict)}
    if set(by_id) != set(EXPECTED_DRAFT_REFS):
        fail("draft: unexpected article IDs")

    accepted: list[dict[str, Any]] = []
    for article_id, expected_ref in EXPECTED_DRAFT_REFS.items():
        article = by_id[article_id]
        require_article_shape(article, f"draft article {article_id}")
        if article.get("status") != "draft":
            fail(f"draft article {article_id}: expected draft status")
        refs = article["question_refs"]
        if len(refs) != 1 or question_ref_tuple(refs[0], f"draft article {article_id}") != expected_ref:
            fail(f"draft article {article_id}: unexpected question ref")
        if revisions.get(expected_ref[:2]) != expected_ref[2]:
            fail(f"draft article {article_id}: stale or missing immutable published question ref")
        integrated = dict(article)
        integrated["status"] = "accepted"
        if {key: value for key, value in integrated.items() if key != "status"} != {key: value for key, value in article.items() if key != "status"}:
            fail(f"draft article {article_id}: non-status content changed")
        accepted.append(integrated)
    return accepted


def prepare(baseline_path: Path, draft_path: Path, review_path: Path, bundle_path: Path) -> dict[str, Any]:
    baseline = read_json_with_hash(baseline_path, BASELINE_SHA256, "baseline Reader")
    draft = read_json_with_hash(draft_path, DRAFT_SHA256, "accepted V3 draft")
    review = read_json_with_hash(review_path, "f7c92eeec001f981cf06419bf8b8d59cd3e6afe8418032d188d95e61646be199", "independent V3 review")
    bundle = read_json_with_hash(bundle_path, PUBLISHED_BUNDLE_SHA256, "immutable published Home Alone bundle")

    if not isinstance(baseline, dict) or baseline.get("schema_version") != "qm-question-articles/v1":
        fail("baseline Reader: unexpected schema")
    baseline_articles = baseline.get("articles")
    if not isinstance(baseline_articles, list) or len(baseline_articles) != 242:
        fail("baseline Reader: expected exactly 242 articles")
    if any(not isinstance(article, dict) or article.get("status") != "accepted" for article in baseline_articles):
        fail("baseline Reader: all 242 rows must already be accepted")

    revisions = validate_published_bundle(bundle)
    additions = accepted_draft_articles(draft, review, revisions)
    result = {"schema_version": "qm-question-articles/v1", "articles": [*baseline_articles, *additions]}
    if result["articles"][:242] != baseline_articles:
        fail("output: pre-existing Reader rows changed")
    validate_output_schema(result)
    return result


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, required=True, help="Required new output path; it must not already exist.")
    parser.add_argument("--baseline", type=Path, default=DEFAULT_BASELINE)
    parser.add_argument("--draft", type=Path, default=DEFAULT_DRAFT)
    parser.add_argument("--review", type=Path, default=DEFAULT_REVIEW)
    parser.add_argument("--published-bundle", type=Path, default=DEFAULT_BUNDLE)
    parser.add_argument("--dry-run", action="store_true", help="Validate and render in memory without creating --output.")
    args = parser.parse_args()

    if args.output.exists():
        fail(f"output already exists; refusing to overwrite: {args.output}")
    if not args.output.parent.is_dir():
        fail(f"output parent does not exist: {args.output.parent}")
    data = prepare(args.baseline, args.draft, args.review, args.published_bundle)
    rendered = json.dumps(data, ensure_ascii=False, indent=2) + "\n"
    digest = sha256_bytes(rendered.encode("utf-8"))
    if args.dry_run:
        print(f"PASS (dry run): 244 accepted Reader articles; output_sha256={digest}; not written")
        return
    with args.output.open("x", encoding="utf-8", newline="\n") as output:
        output.write(rendered)
    print(f"PASS: wrote 244 accepted Reader articles to {args.output}; output_sha256={digest}")


if __name__ == "__main__":
    main()
