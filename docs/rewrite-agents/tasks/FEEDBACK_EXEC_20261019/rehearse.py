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


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--base-url", required=True)
    parser.add_argument("--web-root", type=Path, required=True)
    parser.add_argument("--require-real-http-grading", action="store_true")
    parser.add_argument("--require-article-revision-binding", action="store_true")
    args = parser.parse_args()
    if not (args.require_real_http_grading and args.require_article_revision_binding):
        raise SystemExit("both release rehearsal gates are required")
    require_candidate_contract(args.base_url.rstrip("/"), args.web_root)
    require_article_bindings(args.web_root, args.base_url.rstrip('/'))
    print(json.dumps({"real_http_grading": True, "article_revision_binding": True}))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
