"""Verify the real candidate /app/api in an isolated copied SQLite database."""
from __future__ import annotations
import argparse
import copy
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import re
import shutil
import socket
import sqlite3
import subprocess
import time
import urllib.error
import urllib.parse
import urllib.request
import uuid
QUIZ_ID = 'lotr-return-king-bts-100'
RAW_PATH = 'Cinema/LOTR/lotr_return_king_bts_100.json'
REPAIRED = {'lotr-rk-93': '4c90dc9b8f716e6de64e9153694ebb9576a024983cff098f8c16f4d7adf302e4', 'lotr-rk-95': '36e5d42e3e8a3f639c9249ede4a04fcb6186fa8e3a826325f4ec4998b20db513'}
TARGET_API_SHA256 = 'f4d69555623aab2b8e1468fccb65256abefc9823d65214799b7e1475d4d9c850'
RECEIPT_SCHEMA = 'qm-candidate-runtime/v1'
NONCATALOG_READER_REFS = [
    {'quiz_id': 'study-geography-countries', 'question_id': 'study-geography-countries-001', 'revision_sha256': '4f6f8946ad7c86d3a7e3076e00243321bdffeca8c2671f8a69f6b9b8ef456bb9'},
    {'quiz_id': 'study-geography-countries', 'question_id': 'study-geography-countries-002', 'revision_sha256': '89ed172a4b2ebd6dd18857069a879e261cca05516a1a1b3deb4fe566eb2c44a6'},
]
PUBLIC_KEYS = ('quiz_id', 'question_id', 'revision', 'stem', 'options', 'difficulty', 'source', 'answer_kind')
PUBLIC_OPTIONAL_KEYS = ('difficulty_level', 'context_tag_ids', 'media')
EARLY_REVEAL_STATUS = 404


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def read_json(path):
    return json.loads(Path(path).read_text(encoding='utf-8'))


def sha_file(path):
    with Path(path).open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def canonical(value):
    return hashlib.sha256(json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(',', ':')).encode()).hexdigest()


def indexed_questions(response):
    rows = response.get('quiz', {}).get('questions')
    require(isinstance(rows, list), 'missing HTTP catalog questions')
    result = {row['question_id']: row for row in rows}
    require(len(result) == len(rows), 'duplicate HTTP question identifiers')
    return result


def public_projection(question):
    result = {key: question[key] for key in PUBLIC_KEYS}
    result.update({key: question[key] for key in PUBLIC_OPTIONAL_KEYS if key in question})
    require(set(question) == set(result), 'unmodified candidate DTO has unsupported/private fields')
    return result


def verify_public_catalog(live, runtime):
    current, expected = indexed_questions(live), indexed_questions(runtime)
    require(live['quiz']['quiz_id'] == runtime['quiz']['quiz_id'] and set(current) == set(expected), 'unmodified candidate DTO membership differs')
    for qid, row in current.items():
        require(public_projection(row) == public_projection(expected[qid]), 'unmodified candidate DTO differs')


def verify_lotr_catalog(live, runtime, baseline):
    current, expected = indexed_questions(live), indexed_questions(runtime)
    prior = indexed_questions(baseline['response'])
    require(set(current) == set(expected) == set(prior) == {f'lotr-rk-{i}' for i in range(1, 101)}, 'LOTR HTTP membership differs')
    q95 = current['lotr-rk-95']
    require([o['option_id'] for o in q95['options']] == ['lotr-rk-95-opt-1', 'lotr-rk-95-opt-2', 'lotr-rk-95-opt-3', 'lotr-rk-95-opt-5'], 'retained option identifiers differ')
    require(len(current['lotr-rk-93']['options']) == 6 and current['lotr-rk-93']['options'][5]['option_id'] == 'lotr-rk-93-opt-6', 'retained option identifiers differ')
    for qid, row in current.items():
        require(row.get('source') == expected[qid]['source'], 'unmodified candidate DTO source differs')
        if qid in REPAIRED:
            require(row.get('revision') == {'number': 2, 'sha256': REPAIRED[qid]}, 'target runtime revision differs')
        else:
            require(row == prior[qid], '98 non-target public objects/revisions differ')
        require(row == public_projection(expected[qid]), 'unmodified candidate DTO differs')
    require(live['quiz']['quiz_id'] == QUIZ_ID, 'LOTR quiz identity differs')
    return {'questions': 100, 'non_target_questions': 98, 'target_questions': 2}


def verify_catalog_collection(catalog, responses, *, expected_packs=135, expected_questions=4064):
    ids = [row['quiz_id'] for row in catalog]
    require(len(ids) == len(set(ids)) == expected_packs and set(responses) == set(ids), 'HTTP catalog membership/count differs')
    total = 0
    for row in catalog:
        response = responses[row['quiz_id']]
        require(response['quiz']['quiz_id'] == row['quiz_id'], 'HTTP quiz identity differs')
        questions = indexed_questions(response)
        require(len(questions) == row['questions_count'], 'HTTP per-pack question count differs')
        total += len(questions)
    require(total == expected_questions, 'HTTP total question count differs')
    return {'packs': len(ids), 'questions': total}


def verify_reader_bindings(reader, responses, *, expected_articles=266, expected_total_refs=147, expected_playable_refs=145):
    require(len(reader) == expected_articles and len({a['id'] for a in reader}) == expected_articles, 'Reader article membership differs')
    questions = {qid: indexed_questions(r) for qid, r in responses.items()}
    noncatalog, playable, total = [], 0, 0
    for article in reader:
        for ref in article.get('question_refs', []):
            total += 1
            if ref['quiz_id'] not in questions:
                noncatalog.append(ref)
                continue
            question = questions[ref['quiz_id']].get(ref['question_id'])
            require(question is not None and question['revision']['sha256'] == ref['revision_sha256'], 'Reader revision binding differs')
            playable += 1
    require(sorted(noncatalog, key=lambda x: x['question_id']) == NONCATALOG_READER_REFS, 'unexpected noncatalog Reader references')
    require(total == expected_total_refs and playable == expected_playable_refs, 'Reader reference counts differ')
    return {'articles': len(reader), 'total_refs': total, 'playable_refs': playable, 'noncatalog_refs': len(noncatalog)}


def verify_grading_result(attempt, finish, reveals, runtime):
    questions = indexed_questions(runtime)
    snapshots = attempt.get('question_snapshots', [])
    require(len(snapshots) == len(questions) and {s['question_id'] for s in snapshots} == set(questions), 'attempt snapshot membership differs')
    for row in snapshots:
        require(row['question_revision'] == questions[row['question_id']]['revision'], 'attempt revision differs')
    require(finish.get('status') == 'finished' and finish.get('attempt_id') == attempt['attempt_id'] and finish.get('participant_id') == attempt['participant_id'], 'finished attempt identity differs')
    require(finish.get('server_score') == len(questions), 'server grading score differs')
    history = finish.get('history', [])
    require(len(history) == len(questions) and {r['question_id'] for r in history} == set(questions), 'finish history differs')
    for row in history:
        require(row['question_revision'] == questions[row['question_id']]['revision'], 'finish revision differs')
    require(len(reveals) == len(questions) and {r['question_id'] for r in reveals} == set(questions), 'reveal membership differs')
    for row in reveals:
        qid = row['question_id']
        require(row['quiz_id'] == runtime['quiz']['quiz_id'] and row['question_revision'] == questions[qid]['revision'], 'reveal revision/identity differs')
        require(row['correct_answer']['option_id'] == runtime['private_grading'][qid]['correct_option_id'], 'reveal answer differs')
    return {'answered': len(questions), 'server_score': len(questions), 'reveals_after_finish': len(questions)}


def verify_runtime_receipt(receipt, image, *, expected_packs=135, expected_questions=4064, expected_articles=266, expected_total_refs=147, expected_playable_refs=145):
    forbidden = {'private_grading', 'correct_option_id', 'correct_answer', 'token', 'reveals'}
    def safe(value):
        if isinstance(value, dict):
            require(not (set(value) & forbidden), 'runtime receipt exposes private grading')
            for child in value.values():
                safe(child)
        elif isinstance(value, list):
            for child in value:
                safe(child)
    safe(receipt)
    require(receipt.get('schema_version') == RECEIPT_SCHEMA and receipt.get('status') == 'VERIFIED_CANDIDATE_IMAGE_NOT_PUBLISHED' and receipt.get('image') == image and receipt.get('target_api_sha256') == TARGET_API_SHA256, 'runtime gate evidence identity differs')
    require(all(receipt.get(key) is True for key in ('source_db_unchanged', 'container_cleanup', 'scratch_cleanup', 'port_released')), 'runtime gate evidence cleanup differs')
    require(receipt.get('http') == {'lotr_questions': 100, 'non_target_questions': 98, 'target_questions': 2, 'packs': expected_packs, 'questions': expected_questions}, 'runtime gate evidence HTTP differs')
    require(receipt.get('reader') == {'articles': expected_articles, 'total_refs': expected_total_refs, 'playable_refs': expected_playable_refs, 'noncatalog_refs': 2}, 'runtime gate evidence Reader differs')
    require(receipt.get('grading') == {'answered': 100, 'server_score': 100, 'reveals_after_finish': 100} and receipt.get('target_revisions') == REPAIRED, 'runtime gate evidence grading differs')
    if (expected_packs, expected_questions) == (136, 4084):
        require(receipt.get('mixed_questions') == 20 and receipt.get('mixed_grading') == {'answered': 20, 'server_score': 20, 'reveals_after_finish': 20}, 'runtime gate evidence mixed grading differs')


def build_docker_run_command(*, image, container_name, ownership_nonce, work_dir, port):
    require(re.fullmatch(r'qm-lotr-runtime-[a-z0-9]+', container_name) and re.fullmatch(r'[a-z0-9]+', ownership_nonce), 'unsafe container ownership')
    require(PurePosixPath(work_dir).is_absolute() and '..' not in PurePosixPath(work_dir).parts and 1024 <= port <= 65535, 'unsafe runtime directory/port')
    return ['docker', 'run', '--detach', '--name', container_name, '--label', 'qm.runtime.nonce=' + ownership_nonce,
            '--network', 'host', '--read-only', '--workdir', '/app', '--user', '10001:10001', '--cap-drop', 'ALL', '--security-opt', 'no-new-privileges',
            '--tmpfs', '/tmp:rw,noexec,nosuid,size=16m', '--mount', f'type=bind,src={work_dir},dst=/app/verify',
            '-e', f'QM_LISTEN_ADDR=127.0.0.1:{port}', '-e', 'QM_CONTENT_BUNDLE_PATH=/app/quizzes',
            '-e', 'QM_CONTENT_MANIFEST_PATH=/app/next/content/home-alone-1-part-1/manifest.json',
            '-e', 'QM_CONTENT_TAXONOMY_PATH=/app/metadata/tags.v1.json', '-e', 'QM_DATABASE_URL=sqlite:verify/quiz.sqlite',
            '-e', 'GOMAXPROCS=1', '--entrypoint', '', image, '/app/api']


def safe_startup_logs(raw):
    sensitive = re.compile(r'token|authorization|bearer|secret|password|private_grading|correct_answer|correct_option', re.IGNORECASE)
    return '\n'.join('[REDACTED sensitive startup line]' if sensitive.search(line) else line for line in raw[-16384:].splitlines())


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--image', required=True)
    parser.add_argument('--source-db', type=Path, required=True)
    parser.add_argument('--stage', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--port', type=int, default=18091)
    parser.add_argument('--expected-packs', type=int, required=True)
    parser.add_argument('--expected-questions', type=int, required=True)
    parser.add_argument('--expected-reader-articles', type=int, default=266)
    parser.add_argument('--expected-reader-total-refs', type=int, default=147)
    parser.add_argument('--expected-reader-playable-refs', type=int, default=145)
    args = parser.parse_args()
    require(args.expected_reader_articles > 0 and args.expected_reader_playable_refs > 0 and args.expected_reader_total_refs == args.expected_reader_playable_refs + len(NONCATALOG_READER_REFS), 'invalid expected Reader counts')
    reader_counts = {'expected_articles': args.expected_reader_articles, 'expected_total_refs': args.expected_reader_total_refs, 'expected_playable_refs': args.expected_reader_playable_refs}
    stage = args.stage.resolve()
    require(stage == Path.cwd().resolve() and stage.parent == Path('/opt/quiz-master/releases'), 'runtime stage boundary differs')
    require(args.source_db.resolve().parent == Path('/opt/quiz-master/backups') and args.source_db.is_file(), 'copied DB source boundary differs')
    require(not args.output.exists() and args.output.resolve().parent == stage, 'runtime receipt must be new inside stage')
    nonce = uuid.uuid4().hex
    work = stage / ('runtime-' + nonce)
    name = 'qm-lotr-runtime-' + nonce
    source_hash = sha_file(args.source_db)
    runtime = read_json(stage / 'next/content' / QUIZ_ID / 'bundle.json')
    baseline = read_json(stage / 'runtime-public-baseline.json')
    catalog = read_json(stage / 'web/assets/assets/catalog.json')
    reader = read_json(stage / 'web/assets/assets/study/question-articles.json')['articles']
    version = read_json(stage / 'web/version.json')
    require((args.expected_packs, args.expected_questions) == (136, 4084) and (version['packs'], version['questions']) == (136, 4084), 'candidate target counts differ')
    with socket.create_server(('127.0.0.1', args.port)) as probe:
        pass
    image_id = subprocess.check_output(['docker', 'image', 'inspect', '--format', '{{.Id}}', args.image], text=True, timeout=15).strip()
    api_hash = subprocess.check_output(['docker', 'run', '--rm', '--network=none', '--read-only', '--entrypoint', 'sha256sum', image_id, '/app/api'], text=True, timeout=30).split()[0]
    require(api_hash == TARGET_API_SHA256, 'candidate image API hash differs')
    work.mkdir(mode=0o755)
    (work / 'nonce').write_text(nonce)
    created = False
    evidence = None
    def request(path, body=None, token=None, expect=200):
        headers = {'Content-Type': 'application/json'}
        if token:
            headers['Authorization'] = 'Bearer ' + token
        data = None if body is None else json.dumps(body, ensure_ascii=False).encode()
        try:
            with urllib.request.urlopen(urllib.request.Request(f'http://127.0.0.1:{args.port}' + path, data=data, headers=headers), timeout=10) as response:
                status, raw = response.status, response.read()
        except urllib.error.HTTPError as error:
            status, raw = error.code, error.read()
        require(status == expect, f'candidate HTTP status differs: {path} {status} expected {expect}')
        return json.loads(raw) if raw else None
    try:
        uri = args.source_db.resolve().as_uri() + '?mode=ro'
        with sqlite3.connect(uri, uri=True) as src, sqlite3.connect(work / 'quiz.sqlite') as dst:
            src.backup(dst)
            require(dst.execute('pragma integrity_check').fetchone() == ('ok',), 'copied DB integrity differs')
        os.chown(work, 10001, 10001)
        os.chown(work / 'quiz.sqlite', 10001, 10001)
        result = subprocess.run(build_docker_run_command(image=image_id, container_name=name, ownership_nonce=nonce, work_dir=str(work), port=args.port), capture_output=True, text=True, timeout=30)
        created = result.returncode == 0
        require(created, 'candidate container start failed')
        deadline = time.monotonic() + 45
        while True:
            try:
                request('/health/ready')
                break
            except (urllib.error.URLError, TimeoutError, ConnectionError):
                require(time.monotonic() < deadline, 'candidate readiness timeout')
                time.sleep(0.2)
        responses = {row['quiz_id']: request('/v1/catalog?quiz_id=' + urllib.parse.quote(row['quiz_id'], safe='')) for row in catalog}
        lotr = verify_lotr_catalog(responses[QUIZ_ID], runtime, baseline)
        corpus = verify_catalog_collection(catalog, responses, expected_packs=version['packs'], expected_questions=version['questions'])
        bindings = verify_reader_bindings(reader, responses, **reader_counts)
        mixed = read_json(stage / 'next/content/pub-connections-20261014/bundle.json')
        verify_public_catalog(responses['pub-connections-20261014'], mixed)
        guest = request('/v1/guests', {'display_name': 'Candidate runtime verification'}, expect=201)
        token = guest['token']
        def grade(bundle):
            attempt = request('/v1/attempts', {'quiz_id': bundle['quiz']['quiz_id'], 'mode': 'practice'}, token, expect=201)
            path = '/v1/attempts/' + attempt['attempt_id']
            request(path + '/reveals', token=token, expect=EARLY_REVEAL_STATUS)
            for snap in attempt['question_snapshots']:
                answer = {'option_id': bundle['private_grading'][snap['question_id']]['correct_option_id']}
                core = {'attempt_id': attempt['attempt_id'], 'participant_id': attempt['participant_id'], 'question_id': snap['question_id'], 'question_revision': snap['question_revision'], 'answer': answer}
                request(path + '/answers', {'question_id': snap['question_id'], 'question_revision': snap['question_revision'], 'answer': answer, 'idempotency_key': nonce + '-' + snap['question_id'], 'payload_digest': canonical(core)}, token)
            finish = request(path + '/finish', {}, token)
            reveals = request(path + '/reveals', token=token)
            return verify_grading_result(attempt, finish, reveals, bundle)
        grading = grade(runtime)
        mixed_grading = grade(mixed)
        evidence = {'schema_version': RECEIPT_SCHEMA, 'status': 'VERIFIED_CANDIDATE_IMAGE_NOT_PUBLISHED', 'image': args.image, 'image_id': image_id,
                    'target_api_sha256': api_hash, 'target_revisions': copy.deepcopy(REPAIRED),
                    'http': {'lotr_questions': lotr['questions'], 'non_target_questions': lotr['non_target_questions'], 'target_questions': lotr['target_questions'], **corpus},
                    'reader': bindings, 'grading': grading, 'mixed_grading': mixed_grading, 'mixed_questions': len(indexed_questions(mixed))}
    except Exception as error:
        # Preserve bounded diagnostic evidence before removing the nonce-owned container.
        try:
            owner = subprocess.run(['docker', 'inspect', '--format', '{{index .Config.Labels "qm.runtime.nonce"}}', name], text=True, capture_output=True, timeout=15)
            if owner.returncode == 0 and owner.stdout.strip() == nonce:
                logs = subprocess.run(['docker', 'logs', '--tail', '40', name], text=True, capture_output=True, timeout=15)
                diagnostic = {'status': 'CANDIDATE_FAILED_NOT_VERIFIED', 'image_id': image_id, 'container_name': name, 'error_type': type(error).__name__, 'logs_actual_exit': logs.returncode, 'startup_logs': safe_startup_logs(logs.stdout + logs.stderr)}
                with args.output.with_name(args.output.name + '.failure.json').open('x', encoding='utf-8') as output:
                    json.dump(diagnostic, output, ensure_ascii=False, indent=2)
                    output.write('\n')
        except Exception:
            pass
        raise
    finally:
        inspection = subprocess.run(['docker', 'inspect', '--format', '{{index .Config.Labels "qm.runtime.nonce"}}', name], text=True, capture_output=True, timeout=15)
        if inspection.returncode == 0:
            require(inspection.stdout.strip() == nonce, 'container cleanup ownership differs')
            subprocess.run(['docker', 'rm', '--force', name], check=True, capture_output=True, timeout=30)
        else:
            require('No such object' in inspection.stderr or 'No such container' in inspection.stderr, 'container cleanup inspection failed')
        require(work.parent == stage and work.name == 'runtime-' + nonce and (work / 'nonce').read_text() == nonce, 'scratch cleanup ownership differs')
        shutil.rmtree(work)
    require(sha_file(args.source_db) == source_hash, 'source backup database changed')
    with socket.create_server(('127.0.0.1', args.port)) as probe:
        pass
    evidence.update(source_db_unchanged=True, container_cleanup=True, scratch_cleanup=True, port_released=True)
    verify_runtime_receipt(evidence, args.image, expected_packs=version['packs'], expected_questions=version['questions'], **reader_counts)
    with args.output.open('x', encoding='utf-8') as output:
        json.dump(evidence, output, ensure_ascii=False, indent=2)
        output.write('\n')
    print(json.dumps(evidence, ensure_ascii=False))


if __name__ == '__main__':
    main()
