"""Pure boundary tests for the candidate-image HTTP runtime gate."""
from __future__ import annotations

import copy
import unittest
import json
from pathlib import Path
import urllib.parse
import ast
import inspect
import socket
from types import SimpleNamespace

import verify_candidate_runtime as v


def question(number: int, revision: str | None = None) -> dict:
    question_id = f"lotr-rk-{number}"
    options = [
        {"option_id": f"{question_id}-opt-{index}", "text": f"option {index}"}
        for index in range(1, 7)
    ]
    if number == 95:
        options = [options[0], options[1], options[2], options[4]]
    return {
        "quiz_id": v.QUIZ_ID,
        "question_id": question_id,
        "revision": {
            "number": 2 if number in (93, 95) else 1,
            "sha256": revision or v.REPAIRED.get(question_id, f"{number:064x}"),
        },
        "stem": f"question {number}",
        "options": options,
        "difficulty": {"level": 5},
        "source": {"uri": "/app/quizzes/" + v.RAW_PATH},
        "answer_kind": "single_choice",
    }


def lotr_fixture() -> tuple[dict, dict, dict]:
    questions = [question(number) for number in range(1, 101)]
    runtime = {
        "quiz": {"quiz_id": v.QUIZ_ID, "title": "LOTR", "questions": questions},
        "private_grading": {
            row["question_id"]: {
                "correct_option_id": (
                    "lotr-rk-93-opt-6" if row["question_id"] == "lotr-rk-93"
                    else "lotr-rk-95-opt-2" if row["question_id"] == "lotr-rk-95"
                    else row["options"][0]["option_id"]
                )
            }
            for row in questions
        },
    }
    baseline_questions = copy.deepcopy(questions)
    for number in (93, 95):
        baseline_questions[number - 1]["revision"] = {"number": 1, "sha256": "f" * 64}
    baseline = {"response": {"quiz": {"quiz_id": v.QUIZ_ID, "title": "old", "questions": baseline_questions}}}
    live = {"bundle_version": "source-v1", "bundle_sha256": "a" * 64, "quiz": copy.deepcopy(runtime["quiz"])}
    return runtime, baseline, live


class UnmodifiedLOTRGuards(unittest.TestCase):
    def test_actual_mixed_public_dto_preserves_optional_fields_and_rejects_drift_or_private_extras(self):
        runtime = json.loads((Path(__file__).resolve().parents[5] / 'next/content/pub-connections-20261014/bundle.json').read_text(encoding='utf-8'))
        self.assertTrue(any(row.get('difficulty_level') == 5 for row in runtime['quiz']['questions']))
        live = {'quiz': copy.deepcopy(runtime['quiz'])}
        before = copy.deepcopy(live)
        v.verify_public_catalog(live, runtime)
        self.assertEqual(live, before)
        for key, value in (('difficulty_level', None), ('difficulty_level', 99), ('private_grading', {'secret': 'key'})):
            wrong = copy.deepcopy(live)
            if value is None:
                wrong['quiz']['questions'][0].pop(key)
            else:
                wrong['quiz']['questions'][0][key] = value
            with self.assertRaisesRegex(RuntimeError, 'unmodified candidate DTO'):
                v.verify_public_catalog(wrong, runtime)
        extended = copy.deepcopy(runtime)
        extended['quiz']['questions'][0].update(context_tag_ids=['topic:science'], media=[])
        v.verify_public_catalog({'quiz': copy.deepcopy(extended['quiz'])}, extended)

    def test_exact_candidate_lotr_http_dto_passes_without_mutation(self):
        runtime, baseline, live = lotr_fixture()
        before = copy.deepcopy(live)
        summary = v.verify_lotr_catalog(live, runtime, baseline)
        self.assertEqual(summary, {"questions": 100, "non_target_questions": 98, "target_questions": 2})
        self.assertEqual(live, before)

    def test_wrong_runtime_revision_hash_source_or_retained_id_is_rejected(self):
        runtime, baseline, live = lotr_fixture()
        cases = []
        wrong_revision = copy.deepcopy(live)
        wrong_revision["quiz"]["questions"][92]["revision"]["sha256"] = "0" * 64
        cases.append((wrong_revision, "target runtime revision"))
        normalized_source = copy.deepcopy(live)
        normalized_source["quiz"]["questions"][0]["source"]["uri"] = "C:/stage/quizzes/lotr.json"
        cases.append((normalized_source, "unmodified candidate DTO"))
        wrong_retained = copy.deepcopy(live)
        wrong_retained["quiz"]["questions"][94]["options"][3]["option_id"] = "lotr-rk-95-opt-4"
        cases.append((wrong_retained, "retained option identifiers"))
        for candidate, message in cases:
            with self.subTest(message=message), self.assertRaisesRegex(RuntimeError, message):
                v.verify_lotr_catalog(candidate, runtime, baseline)

    def test_changed_non_target_public_object_is_rejected(self):
        runtime, baseline, live = lotr_fixture()
        live["quiz"]["questions"][0]["stem"] += " changed"
        with self.assertRaisesRegex(RuntimeError, "98 non-target public"):
            v.verify_lotr_catalog(live, runtime, baseline)


class CorpusAndReaderGuards(unittest.TestCase):
    def responses(self):
        runtime, _, lotr = lotr_fixture()
        other = {
            "quiz": {
                "quiz_id": "other-pack",
                "questions": [{"question_id": "other-1", "revision": {"number": 1, "sha256": "b" * 64}}],
            }
        }
        return runtime, {v.QUIZ_ID: lotr, "other-pack": other}

    def test_catalog_counts_and_all_reader_bindings_are_exact(self):
        _, responses = self.responses()
        catalog = [
            {"quiz_id": v.QUIZ_ID, "questions_count": 100},
            {"quiz_id": "other-pack", "questions_count": 1},
        ]
        summary = v.verify_catalog_collection(catalog, responses, expected_packs=2, expected_questions=101)
        self.assertEqual(summary, {"packs": 2, "questions": 101})
        reader = [
            {"id": "playable-lotr", "question_refs": [{"quiz_id": v.QUIZ_ID, "question_id": "lotr-rk-93", "revision_sha256": v.REPAIRED["lotr-rk-93"]}]},
            {"id": "playable-other", "question_refs": [{"quiz_id": "other-pack", "question_id": "other-1", "revision_sha256": "b" * 64}]},
            {"id": "noncatalog", "question_refs": [copy.deepcopy(row) for row in v.NONCATALOG_READER_REFS]},
        ]
        bindings = v.verify_reader_bindings(
            reader,
            responses,
            expected_articles=3,
            expected_total_refs=4,
            expected_playable_refs=2,
        )
        self.assertEqual(bindings, {"articles": 3, "total_refs": 4, "playable_refs": 2, "noncatalog_refs": 2})

    def test_missing_or_mismatched_reader_binding_is_rejected(self):
        _, responses = self.responses()
        reader = [
            {"id": "bad", "question_refs": [{"quiz_id": "other-pack", "question_id": "other-1", "revision_sha256": "c" * 64}]},
            {"id": "noncatalog", "question_refs": [copy.deepcopy(row) for row in v.NONCATALOG_READER_REFS]},
        ]
        with self.assertRaisesRegex(RuntimeError, "Reader revision binding"):
            v.verify_reader_bindings(
                reader,
                responses,
                expected_articles=2,
                expected_total_refs=3,
                expected_playable_refs=1,
            )


class GradingAndReceiptGuards(unittest.TestCase):
    def test_actual_pre_and_post_port_checks_listen_close_and_reject_live_listener(self):
        tree = ast.parse(inspect.getsource(v.main))
        probes = [node for node in ast.walk(tree) if isinstance(node, ast.With) and any(isinstance(item.context_expr, ast.Call) and isinstance(item.context_expr.func, ast.Attribute) and isinstance(item.context_expr.func.value, ast.Name) and item.context_expr.func.value.id == 'socket' for item in node.items)]
        self.assertEqual(len(probes), 2)
        for original in probes:
            code = copy.deepcopy(original)
            code.body += ast.parse("assert probe.getsockopt(socket.SOL_SOCKET,socket.SO_ACCEPTCONN)==1\nchecked_address=probe.getsockname()\n").body
            compiled = compile(ast.fix_missing_locations(ast.Module(body=[code], type_ignores=[])), 'actual-candidate-port-probe', 'exec')
            namespace = {'socket': socket, 'args': SimpleNamespace(port=0)}
            exec(compiled, namespace)
            self.assertEqual(namespace['probe'].fileno(), -1)
            with socket.create_server(namespace['checked_address']) as listener:
                namespace['args'].port = listener.getsockname()[1]
                with self.assertRaises(OSError):
                    exec(compiled, namespace)
            exec(compiled, namespace)
            self.assertEqual(namespace['probe'].fileno(), -1)

    def test_candidate_sqlite_url_uses_opaque_relative_path_and_exact_mount(self):
        command = v.build_docker_run_command(image='quiz:test', container_name='qm-lotr-runtime-abc', ownership_nonce='abc', work_dir='/opt/quiz-master/releases/build/runtime-abc', port=18091)
        value = next(arg.removeprefix('QM_DATABASE_URL=') for arg in command if arg.startswith('QM_DATABASE_URL='))
        parsed = urllib.parse.urlsplit(value)
        self.assertEqual(parsed.scheme, 'sqlite')
        self.assertFalse(parsed.netloc or parsed.query or parsed.fragment)
        self.assertFalse(parsed.path.startswith('/'), 'Go url.Parse must classify SQLite payload as Opaque, not absolute Path')
        self.assertEqual(value, 'sqlite:verify/quiz.sqlite')
        self.assertIn('type=bind,src=/opt/quiz-master/releases/build/runtime-abc,dst=/app/verify', command)
        self.assertEqual(command[command.index('--workdir') + 1], '/app')

    def test_failed_startup_diagnostic_redacts_tokens_and_keeps_actual_failure(self):
        raw = 'QM_DATABASE_URL SQLite path is invalid\nAuthorization: Bearer secret-value\nQM_FEEDBACK_ADMIN_TOKEN=private-value\ncorrect_option_id=private-key\n'
        safe = v.safe_startup_logs(raw)
        self.assertIn('QM_DATABASE_URL SQLite path is invalid', safe)
        self.assertNotIn('secret-value', safe)
        self.assertNotIn('private-value', safe)
        self.assertNotIn('private-key', safe)

    def test_mixed_receipt_requires_exact_20_graded_answers(self):
        receipt = {
            'schema_version': v.RECEIPT_SCHEMA, 'status': 'VERIFIED_CANDIDATE_IMAGE_NOT_PUBLISHED', 'image': 'quiz:test',
            'target_api_sha256': v.TARGET_API_SHA256, 'source_db_unchanged': True, 'container_cleanup': True, 'scratch_cleanup': True, 'port_released': True,
            'http': {'lotr_questions': 100, 'non_target_questions': 98, 'target_questions': 2, 'packs': 136, 'questions': 4084},
            'reader': {'articles': 266, 'total_refs': 147, 'playable_refs': 145, 'noncatalog_refs': 2},
            'grading': {'answered': 100, 'server_score': 100, 'reveals_after_finish': 100}, 'target_revisions': copy.deepcopy(v.REPAIRED),
        }
        with self.assertRaisesRegex(RuntimeError, 'mixed grading'):
            v.verify_runtime_receipt(receipt, 'quiz:test', expected_packs=136, expected_questions=4084)
        receipt['mixed_questions'] = 20
        receipt['mixed_grading'] = {'answered': 20, 'server_score': 20, 'reveals_after_finish': 20}
        v.verify_runtime_receipt(receipt, 'quiz:test', expected_packs=136, expected_questions=4084)

    def grading_payloads(self):
        runtime, _, _ = lotr_fixture()
        snapshots = [
            {"question_id": row["question_id"], "question_revision": row["revision"]}
            for row in runtime["quiz"]["questions"]
        ]
        attempt = {"attempt_id": "a-fixture", "participant_id": "p-fixture", "question_snapshots": snapshots, "status": "started"}
        finish = {"attempt_id": "a-fixture", "participant_id": "p-fixture", "status": "finished", "server_score": 100, "history": snapshots}
        reveals = [
            {
                "quiz_id": v.QUIZ_ID,
                "question_id": row["question_id"],
                "question_revision": row["revision"],
                "correct_answer": {"option_id": runtime["private_grading"][row["question_id"]]["correct_option_id"], "text": "answer"},
                "explanation": "verified after finish",
            }
            for row in runtime["quiz"]["questions"]
        ]
        return runtime, attempt, finish, reveals

    def test_finished_attempt_and_post_finish_reveals_are_exact(self):
        runtime, attempt, finish, reveals = self.grading_payloads()
        result = v.verify_grading_result(attempt, finish, reveals, runtime)
        self.assertEqual(result, {"answered": 100, "server_score": 100, "reveals_after_finish": 100})
        reveals[94]["correct_answer"]["option_id"] = "lotr-rk-95-opt-5"
        with self.assertRaisesRegex(RuntimeError, "reveal answer"):
            v.verify_grading_result(attempt, finish, reveals, runtime)

    def test_insufficient_or_secret_bearing_runtime_receipt_is_rejected(self):
        receipt = {
            "schema_version": v.RECEIPT_SCHEMA,
            "status": "VERIFIED_CANDIDATE_IMAGE_NOT_PUBLISHED",
            "image": "quiz-master:test",
            "target_api_sha256": v.TARGET_API_SHA256,
            "source_db_unchanged": True,
            "container_cleanup": True,
            "scratch_cleanup": True,
            "port_released": True,
            "http": {"lotr_questions": 100, "non_target_questions": 98, "target_questions": 2, "packs": 135, "questions": 4064},
            "reader": {"articles": 266, "total_refs": 147, "playable_refs": 145, "noncatalog_refs": 2},
            "grading": {"answered": 100, "server_score": 100, "reveals_after_finish": 100},
            "target_revisions": copy.deepcopy(v.REPAIRED),
        }
        v.verify_runtime_receipt(receipt, "quiz-master:test")
        incomplete = copy.deepcopy(receipt)
        incomplete["reader"]["playable_refs"] = 144
        with self.assertRaisesRegex(RuntimeError, "runtime gate evidence"):
            v.verify_runtime_receipt(incomplete, "quiz-master:test")
        leaked = copy.deepcopy(receipt)
        leaked["correct_option_id"] = "lotr-rk-95-opt-2"
        with self.assertRaisesRegex(RuntimeError, "private grading"):
            v.verify_runtime_receipt(leaked, "quiz-master:test")

    def test_docker_command_is_read_only_host_network_and_exact_owned_mount(self):
        command = v.build_docker_run_command(
            image="quiz-master:test",
            container_name="qm-lotr-runtime-abc",
            ownership_nonce="abc",
            work_dir="/opt/quiz-master/releases/build/runtime-abc",
            port=18091,
        )
        rendered = " ".join(command)
        self.assertIn("--network host", rendered)
        self.assertIn("--read-only", rendered)
        self.assertIn("QM_LISTEN_ADDR=127.0.0.1:18091", command)
        self.assertIn("QM_CONTENT_BUNDLE_PATH=/app/quizzes", command)
        self.assertIn("QM_DATABASE_URL=sqlite:verify/quiz.sqlite", command)
        self.assertEqual(command[-2:], ["quiz-master:test", "/app/api"])


class ReaderSuccessorReceiptTests(unittest.TestCase):
    def test_successor_counts_require_explicit_parameters_and_keep_other_guards(self):
        receipt = {
            "schema_version": v.RECEIPT_SCHEMA,
            "status": "VERIFIED_CANDIDATE_IMAGE_NOT_PUBLISHED",
            "image": "quiz-master:reader-test",
            "target_api_sha256": v.TARGET_API_SHA256,
            "source_db_unchanged": True,
            "container_cleanup": True,
            "scratch_cleanup": True,
            "port_released": True,
            "http": {"lotr_questions": 100, "non_target_questions": 98, "target_questions": 2, "packs": 136, "questions": 4084},
            "reader": {"articles": 272, "total_refs": 153, "playable_refs": 151, "noncatalog_refs": 2},
            "grading": {"answered": 100, "server_score": 100, "reveals_after_finish": 100},
            "target_revisions": copy.deepcopy(v.REPAIRED),
            "mixed_questions": 20,
            "mixed_grading": {"answered": 20, "server_score": 20, "reveals_after_finish": 20},
        }
        with self.assertRaisesRegex(RuntimeError, "Reader"):
            v.verify_runtime_receipt(receipt, receipt["image"], expected_packs=136, expected_questions=4084)
        arguments = {"expected_packs": 136, "expected_questions": 4084, "expected_articles": 272, "expected_total_refs": 153, "expected_playable_refs": 151}
        v.verify_runtime_receipt(receipt, receipt["image"], **arguments)
        for field in ("port_released", "source_db_unchanged", "container_cleanup", "scratch_cleanup"):
            altered = copy.deepcopy(receipt)
            altered[field] = False
            with self.assertRaisesRegex(RuntimeError, "cleanup"):
                v.verify_runtime_receipt(altered, receipt["image"], **arguments)
        altered = copy.deepcopy(receipt)
        altered["reader"]["total_refs"] = 152
        with self.assertRaisesRegex(RuntimeError, "Reader"):
            v.verify_runtime_receipt(altered, receipt["image"], **arguments)


if __name__ == "__main__":
    unittest.main()
