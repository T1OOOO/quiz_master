#!/usr/bin/env python3
"""Disposable-candidate HTTP grader; it never prints bearer credentials or DB rows."""
from __future__ import annotations

import argparse
import json
import hashlib
import urllib.request
from pathlib import Path

# Existing non-catalog study references, pinned by the prior reviewed runtime
# verifier. They cannot be queried as playable quiz packs.
NONCATALOG_READER_REFS = {
    ('study-geography-countries', 'study-geography-countries-001'): '4f6f8946ad7c86d3a7e3076e00243321bdffeca8c2671f8a69f6b9b8ef456bb9',
    ('study-geography-countries', 'study-geography-countries-002'): '89ed172a4b2ebd6dd18857069a879e261cca05516a1a1b3deb4fe566eb2c44a6',
}

REGIONAL_QUIZ_IDS = (
    "prep-capitals-europe",
    "prep-capitals-africa",
    "prep-capitals-americas",
    "prep-capitals-asia-oceania",
    "prep-flags-europe",
    "prep-flags-africa",
    "prep-flags-americas",
    "prep-flags-asia-oceania",
)


def call(base: str, path: str, body: dict | None = None, token: str | None = None) -> dict:
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = "Bearer " + token
    request = urllib.request.Request(base + path, None if body is None else json.dumps(body).encode(), headers=headers)
    with urllib.request.urlopen(request, timeout=20) as response:
        if response.status not in (200, 201):
            raise RuntimeError(f"unexpected HTTP {response.status} for {path}")
        return json.load(response)


def require_article_bindings(web_root: Path, base: str | None = None) -> None:
    found = False
    catalogs = {}
    for path in web_root.rglob("*.json"):
        value = json.loads(path.read_text(encoding="utf-8"))
        rows = value.get("articles", []) if isinstance(value, dict) else value
        if not isinstance(rows, list):
            continue
        for row in rows:
            if not isinstance(row, dict) or "question_refs" not in row:
                continue
            refs = row["question_refs"]
            if not refs:
                continue
            found = True
            if not isinstance(refs, list) or any(
                not isinstance(ref, dict) or not ref.get("question_id") or not ref.get("revision_sha256") for ref in refs
            ):
                raise RuntimeError("article revision binding is incomplete")
            if base:
                for ref in refs:
                    quiz = ref['quiz_id']
                    key = (quiz, ref['question_id'])
                    if key in NONCATALOG_READER_REFS:
                        if ref['revision_sha256'] != NONCATALOG_READER_REFS[key]:
                            raise RuntimeError('non-catalog article revision differs from its exact pin')
                        continue
                    if quiz not in catalogs:
                        catalogs[quiz] = {q['question_id']: q['revision']['sha256'] for q in
                                          call(base, '/v1/catalog?quiz_id=' + quiz)['quiz']['questions']}
                    if catalogs[quiz].get(ref['question_id']) != ref['revision_sha256']:
                        raise RuntimeError('article reference differs from candidate question revision')
    if not found:
        raise RuntimeError("candidate web tree has no article revision bindings")


def require_candidate_contract(base: str, web_root: Path) -> None:
    # This is the Reader 59 contract boundary: actual guest + practice attempt,
    # stable snapshot identity, then an answer receipt owned by the server.
    catalog = call(base, "/v1/catalog?quiz_id=gastronomy-traditions-and-etiquette")
    questions = catalog["quiz"]["questions"]
    if len(questions) < 2:
        raise RuntimeError("candidate catalog lacks meaningful grading fixture")
    guest = call(base, "/v1/guests", {"display_name": "release-rehearsal"})
    token = guest["token"]
    # Fixed fixture from unchanged canonical source:
    # quizzes/Gastronomy/gastronomy_traditions_and_etiquette.json, first question.
    fixture = next(q for q in questions if q['stem'] == 'В какой стране возникло блюдо суши?')
    for text, score in [('Япония', 1), ('Китай', 0)]:
        attempt = call(base, "/v1/attempts", {"quiz_id": "gastronomy-traditions-and-etiquette", "mode": "practice"}, token)
        snapshots = attempt['question_snapshots']
        if len(snapshots) != len(questions) or not all(s.get('question_id') and s.get('question_revision') for s in snapshots):
            raise RuntimeError('attempt snapshot revision binding differs')
        first = next(s for s in snapshots if s['question_id'] == fixture['question_id'])
        if first['question_revision'] != fixture['revision']:
            raise RuntimeError('fixture snapshot revision differs from catalog')
        option = next(o['option_id'] for o in fixture['options'] if o['text'] == text)
        payload = {'attempt_id': attempt['attempt_id'], 'participant_id': attempt['participant_id'],
                   'question_id': first['question_id'], 'question_revision': first['question_revision'],
                   'answer': {'option_id': option}}
        digest = hashlib.sha256(json.dumps(payload, ensure_ascii=False, sort_keys=True, separators=(',', ':')).encode()).hexdigest()
        receipt = call(base, f"/v1/attempts/{attempt['attempt_id']}/answers", {
            'question_id': first['question_id'], 'question_revision': first['question_revision'],
            'answer': {'option_id': option}, 'idempotency_key': 'release-rehearsal-1', 'payload_digest': digest}, token)
        if receipt['question_revision'] != first['question_revision'] or receipt['participant_id'] != attempt['participant_id']:
            raise RuntimeError('answer receipt binding differs')
        finish = call(base, f"/v1/attempts/{attempt['attempt_id']}/finish", {}, token)
        if finish['server_score'] != score or len(finish['history']) != 1:
            raise RuntimeError('authoritative correct/incorrect grading differs')
    require_article_bindings(web_root)


def canonical_answer_digest(attempt_id: str, participant_id: str, question_id: str, revision: dict, option_id: str) -> str:
    payload = {
        "attempt_id": attempt_id,
        "participant_id": participant_id,
        "question_id": question_id,
        "question_revision": revision,
        "answer": {"option_id": option_id},
    }
    return hashlib.sha256(json.dumps(payload, ensure_ascii=False, sort_keys=True, separators=(",", ":")).encode()).hexdigest()


def require_regional_sources(extra_quizzes: Path) -> dict[str, dict]:
    if not extra_quizzes.is_dir():
        raise RuntimeError("regional quiz source directory is missing")
    files = sorted(extra_quizzes.glob("*.json"))
    if len(files) != len(REGIONAL_QUIZ_IDS):
        raise RuntimeError("regional quiz source directory must contain exactly eight JSON packs")
    packs: dict[str, dict] = {}
    for path in files:
        try:
            pack = json.loads(path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            raise RuntimeError("regional quiz source is unreadable") from error
        quiz_id = pack.get("id") if isinstance(pack, dict) else None
        questions = pack.get("questions") if isinstance(pack, dict) else None
        if not isinstance(quiz_id, str) or not isinstance(questions, list) or not questions or quiz_id in packs:
            raise RuntimeError("regional quiz source contract is invalid")
        packs[quiz_id] = pack
    if set(packs) != set(REGIONAL_QUIZ_IDS):
        raise RuntimeError("regional quiz source IDs differ from the reviewed eight packs")
    return packs


def regional_public_mapping(source: dict, catalog: dict) -> dict[str, dict]:
    quiz = catalog.get("quiz")
    public_questions = quiz.get("questions") if isinstance(quiz, dict) else None
    source_questions = source.get("questions")
    if not isinstance(public_questions, list) or not isinstance(source_questions, list) or len(public_questions) != len(source_questions):
        raise RuntimeError("regional public catalog question count differs")
    public_by_id: dict[str, dict] = {}
    for question in public_questions:
        question_id = question.get("question_id") if isinstance(question, dict) else None
        if not isinstance(question_id, str) or question_id in public_by_id:
            raise RuntimeError("regional public catalog question IDs are invalid")
        public_by_id[question_id] = question

    mapped: dict[str, dict] = {}
    for source_question in source_questions:
        if not isinstance(source_question, dict):
            raise RuntimeError("regional private source question is invalid")
        question_id = source_question.get("id")
        source_options = source_question.get("options")
        correct_index = source_question.get("correct_answer")
        public_question = public_by_id.get(question_id) if isinstance(question_id, str) else None
        if (not isinstance(question_id, str) or question_id in mapped or not isinstance(source_options, list)
                or any(not isinstance(option, str) for option in source_options)
                or len(source_options) != len(set(source_options))
                or type(correct_index) is not int or correct_index < 0 or correct_index >= len(source_options)
                or not isinstance(public_question, dict)):
            raise RuntimeError("regional source/public question mapping is invalid")
        if public_question.get("stem") != source_question.get("text"):
            raise RuntimeError("regional public stem differs from source")
        revision = public_question.get("revision")
        public_options = public_question.get("options")
        if not isinstance(revision, dict) or not revision.get("sha256") or not isinstance(public_options, list):
            raise RuntimeError("regional public revision or options are invalid")
        by_text: dict[str, str] = {}
        option_ids: set[str] = set()
        for option in public_options:
            text = option.get("text") if isinstance(option, dict) else None
            option_id = option.get("option_id") if isinstance(option, dict) else None
            if not isinstance(text, str) or not isinstance(option_id, str) or not option_id or text in by_text or option_id in option_ids:
                raise RuntimeError("regional public option IDs are invalid")
            by_text[text] = option_id
            option_ids.add(option_id)
        if set(by_text) != set(source_options) or len(by_text) != len(source_options):
            raise RuntimeError("regional public options differ from source")
        correct_option_id = by_text[source_options[correct_index]]
        mapped[question_id] = {
            "revision": revision,
            "correct_option_id": correct_option_id,
            "option_ids": option_ids,
        }
    if set(public_by_id) != set(mapped):
        raise RuntimeError("regional public catalog has unexpected questions")
    return mapped


def start_regional_attempt(base: str, token: str, quiz_id: str, catalog: dict, mapped: dict[str, dict]) -> tuple[dict, dict[str, dict]]:
    attempt = call(base, "/v1/attempts", {"quiz_id": quiz_id, "mode": "practice"}, token)
    if (not attempt.get("attempt_id") or not attempt.get("participant_id")
            or attempt.get("bundle_sha256") != catalog.get("bundle_sha256")
            or attempt.get("bundle_version") != catalog.get("bundle_version")):
        raise RuntimeError("regional attempt does not pin the catalog bundle")
    snapshots = attempt.get("question_snapshots")
    if not isinstance(snapshots, list) or len(snapshots) != len(mapped):
        raise RuntimeError("regional attempt snapshot count differs")
    by_question: dict[str, dict] = {}
    for snapshot in snapshots:
        question_id = snapshot.get("question_id") if isinstance(snapshot, dict) else None
        source = mapped.get(question_id) if isinstance(question_id, str) else None
        option_order = snapshot.get("option_order") if isinstance(snapshot, dict) else None
        positions = snapshot.get("position_to_option_id") if isinstance(snapshot, dict) else None
        if (not isinstance(snapshot, dict) or source is None or question_id in by_question
                or snapshot.get("question_revision") != source["revision"]
                or not isinstance(option_order, list) or set(option_order) != source["option_ids"]
                or len(option_order) != len(source["option_ids"])
                or not isinstance(positions, dict) or set(positions.values()) != source["option_ids"]
                or len(positions) != len(source["option_ids"])):
            raise RuntimeError("regional attempt snapshot differs from catalog")
        by_question[question_id] = snapshot
    if set(by_question) != set(mapped):
        raise RuntimeError("regional attempt snapshots are incomplete")
    return attempt, by_question


def submit_regional_answer(base: str, token: str, attempt: dict, snapshot: dict, option_id: str, idempotency_key: str) -> None:
    question_id = snapshot["question_id"]
    revision = snapshot["question_revision"]
    participant_id = attempt["participant_id"]
    digest = canonical_answer_digest(attempt["attempt_id"], participant_id, question_id, revision, option_id)
    receipt = call(base, f"/v1/attempts/{attempt['attempt_id']}/answers", {
        "question_id": question_id,
        "question_revision": revision,
        "answer": {"option_id": option_id},
        "idempotency_key": idempotency_key,
        "payload_digest": digest,
    }, token)
    if (not receipt.get("receipt_id") or receipt.get("attempt_id") != attempt["attempt_id"]
            or receipt.get("participant_id") != participant_id
            or receipt.get("question_id") != question_id
            or receipt.get("question_revision") != revision):
        raise RuntimeError("regional answer receipt differs from pinned attempt")


def finish_regional_attempt(base: str, token: str, attempt: dict, expected_score: int, expected_revisions: dict[str, dict]) -> None:
    finish = call(base, f"/v1/attempts/{attempt['attempt_id']}/finish", {}, token)
    history = finish.get("history")
    if (finish.get("attempt_id") != attempt["attempt_id"] or finish.get("participant_id") != attempt["participant_id"]
            or finish.get("status") != "finished" or finish.get("server_score") != expected_score
            or not isinstance(history, list) or len(history) != len(expected_revisions)):
        raise RuntimeError("regional attempt authoritative finish differs")
    history_ids = set()
    for entry in history:
        question_id = entry.get("question_id") if isinstance(entry, dict) else None
        if (not isinstance(question_id, str) or question_id in history_ids or question_id not in expected_revisions
                or entry.get("question_revision") != expected_revisions[question_id] or not entry.get("receipt_id")):
            raise RuntimeError("regional finish history differs")
        history_ids.add(question_id)
    if history_ids != set(expected_revisions):
        raise RuntimeError("regional finish history is incomplete")


def require_regional_quiz_contract(base: str, extra_quizzes: Path) -> list[dict]:
    packs = require_regional_sources(extra_quizzes)
    guest = call(base, "/v1/guests", {"display_name": "release-regional-rehearsal"})
    token = guest.get("token")
    if not isinstance(token, str) or not token:
        raise RuntimeError("regional rehearsal guest is invalid")
    results = []
    for quiz_id in REGIONAL_QUIZ_IDS:
        catalog = call(base, "/v1/catalog?quiz_id=" + quiz_id)
        quiz = catalog.get("quiz") if isinstance(catalog, dict) else None
        if not isinstance(quiz, dict) or quiz.get("quiz_id") != quiz_id or not catalog.get("bundle_sha256") or not catalog.get("bundle_version"):
            raise RuntimeError("regional catalog bundle identity is invalid")
        mapped = regional_public_mapping(packs[quiz_id], catalog)
        attempt, snapshots = start_regional_attempt(base, token, quiz_id, catalog, mapped)
        for index, question_id in enumerate(sorted(mapped)):
            submit_regional_answer(base, token, attempt, snapshots[question_id], mapped[question_id]["correct_option_id"],
                                   f"regional-correct-{quiz_id}-{index}")
        finish_regional_attempt(base, token, attempt, len(mapped), {question_id: value["revision"] for question_id, value in mapped.items()})

        wrong_attempt, wrong_snapshots = start_regional_attempt(base, token, quiz_id, catalog, mapped)
        wrong_question_id = sorted(mapped)[0]
        correct_option = mapped[wrong_question_id]["correct_option_id"]
        wrong_option = next(option for option in sorted(mapped[wrong_question_id]["option_ids"]) if option != correct_option)
        submit_regional_answer(base, token, wrong_attempt, wrong_snapshots[wrong_question_id], wrong_option,
                               f"regional-wrong-{quiz_id}")
        finish_regional_attempt(base, token, wrong_attempt, 0, {wrong_question_id: mapped[wrong_question_id]["revision"]})
        results.append({"quiz_id": quiz_id, "questions_count": len(mapped), "correct_score": len(mapped), "wrong_score": 0})
    return results


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--base-url", required=True)
    parser.add_argument("--web-root", type=Path, required=True)
    parser.add_argument("--extra-quizzes", type=Path, required=True)
    parser.add_argument("--require-real-http-grading", action="store_true")
    parser.add_argument("--require-article-revision-binding", action="store_true")
    args = parser.parse_args()
    if not (args.require_real_http_grading and args.require_article_revision_binding):
        raise SystemExit("both release rehearsal gates are required")
    require_candidate_contract(args.base_url.rstrip("/"), args.web_root)
    require_article_bindings(args.web_root, args.base_url.rstrip('/'))
    regional = require_regional_quiz_contract(args.base_url.rstrip("/"), args.extra_quizzes)
    print(json.dumps({"real_http_grading": True, "article_revision_binding": True, "regional_quizzes": regional}))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
