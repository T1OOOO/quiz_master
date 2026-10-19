"""Release boundaries: candidate bytes, flag closure and independent revisions."""
import hashlib
import json
import tempfile
import unittest
from pathlib import Path
import importlib.util

import release_executor as release

HELPER = Path(__file__).with_name("rehearse.py")
_spec = importlib.util.spec_from_file_location("feedback_rehearse", HELPER)
assert _spec and _spec.loader
rehearse = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(rehearse)


class ReleaseInputsTest(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        (self.root / "web/flags").mkdir(parents=True)
        (self.root / "chart").mkdir()
        (self.root / "extra-quizzes").mkdir()
        (self.root / "chart/Chart.yaml").write_text("name: quiz-master\n")
        (self.root / "api").write_bytes(b"candidate api")
        (self.root / "web/main.dart.js").write_bytes(b"compiled application")
        self.build = "quiz-2026.10.19-feedback-test"
        self.version = {
            "buildId": self.build,
            "source_commit": "a" * 40,
            "api_sha256": release.sha256_file(self.root / "api"),
            "main_dart_js_sha256": release.sha256_file(self.root / "web/main.dart.js"),
        }
        self.write_version()
        for subject in ('capitals', 'flags'):
            for region, count in [('europe', 44), ('africa', 54), ('americas', 35), ('asia-oceania', 62)]:
                quiz_id = f'prep-{subject}-{region}'
                (self.root / 'extra-quizzes' / f'{quiz_id}.json').write_text(json.dumps({
                    'id': quiz_id, 'title': quiz_id, 'description': 'Fixture',
                    'category': 'Geography', 'questions': [{
                        'id': f'{quiz_id}-{i}', 'type': 'choice', 'text': f'Question {i}',
                        'options': ['a', 'b', 'c', 'd'], 'correct_answer': 3,
                    } for i in range(count)],
                }))
        for index in range(195):
            data = b"\x89PNG\r\n\x1a\n" + str(index).encode()
            name = hashlib.sha256(data).hexdigest() + ".png"
            (self.root / "web/flags" / name).write_bytes(data)

    def write_version(self):
        (self.root / "web/version.json").write_text(json.dumps(self.version))

    def test_candidate_api_is_in_manifest_and_must_match_version(self):
        inputs = release.collect_inputs(self.root)
        release.validate_package_identity(inputs, self.build)
        self.assertEqual(inputs.manifest["target_api_sha256"], self.version["api_sha256"])
        self.assertEqual(inputs.manifest["rehearsal_sha256"], release.sha256_file(HELPER))
        (self.root / "api").write_bytes(b"different api")
        with self.assertRaisesRegex(release.GuardError, "candidate binary"):
            release.validate_package_identity(inputs, self.build)

    def test_missing_or_changed_flag_stops_packaging(self):
        flag = next((self.root / "web/flags").glob("*.png"))
        original = flag.read_bytes()
        flag.write_bytes(b"HTML instead of an image")
        with self.assertRaisesRegex(release.GuardError, "flag image"):
            release.collect_inputs(self.root)
        flag.write_bytes(original)
        flag.unlink()
        with self.assertRaisesRegex(release.GuardError, "195"):
            release.collect_inputs(self.root)

    def test_regional_banks_are_required_and_private_keys_must_be_valid(self):
        path = next((self.root / 'extra-quizzes').glob('*.json'))
        original = path.read_bytes()
        pack = json.loads(original)
        pack['questions'][0]['correct_answer'] = 7
        path.write_text(json.dumps(pack))
        with self.assertRaisesRegex(release.GuardError, 'regional'):
            release.collect_inputs(self.root)
        path.write_bytes(original)
        path.unlink()
        with self.assertRaisesRegex(release.GuardError, 'regional'):
            release.collect_inputs(self.root)

    def test_remote_script_pins_api_and_rolls_back_to_actual_helm_revision(self):
        script = release.remote_script(self.build, self.version["api_sha256"], "prepare")
        self.assertIn(self.version["api_sha256"], script)
        self.assertIn("helm rollback quiz-master 66", script)
        self.assertIn("post_upgrade_err", script)
        self.assertIn("restore-proof.sqlite", script)
        self.assertIn("QM_DATABASE_URL=sqlite:../data/quiz.db", script)
        self.assertIn("original feedback row changed or missing", script)
        self.assertIn('c.get("Ready")=="True"', script)
        self.assertIn('c.get("DiskPressure")=="False"', script)
        self.assertIn("s.f_bavail * 5 >= s.f_blocks", script)
        self.assertIn("NoSchedule", script)
        self.assertIn("imageGCHighThresholdPercent", script)
        self.assertIn("--require-real-http-grading", script)
        self.assertIn('candidate_image="$tag@$containerd_digest"', script)
        self.assertIn('image="$candidate_image"', script)
        self.assertIn('chmod 600 "$backup"', script)
        self.assertIn('test "$post" = "$(printf', script)
        self.assertIn('"$candidate_image" "$candidate_image"', script)
        self.assertNotIn('--set-string image="$tag" --set-string buildId="$build"', script)
        self.assertIn('if [ "$phase" = prepare ]; then', script)
        self.assertIn('prepared-receipt.json', script)
        self.assertIn('reviewed-receipt.json', script)
        self.assertIn('"rehearse.py"', Path(release.__file__).read_text(encoding="utf-8"))
        self.assertEqual(release.BASE_DEPLOYMENT_REVISION, "64")
        self.assertIn('canonical_image="docker.io/library/quiz-master@$containerd_digest"', script)
        self.assertIn('k3s crictl inspecti "$canonical_image"', script)
        with self.assertRaises(release.GuardError):
            release.remote_script(self.build, "shell; command", "prepare")
        with self.assertRaises(release.GuardError):
            release.remote_script(self.build, self.version["api_sha256"], "deploy")

    def test_rehearsal_rejects_incorrect_authoritative_grade(self):
        old = rehearse.call
        self.addCleanup(lambda: setattr(rehearse, "call", old))
        revision = {"number": 1, "sha256": "a" * 64}
        question = {"question_id": "fixture", "revision": revision,
                    "stem": "В какой стране возникло блюдо суши?",
                    "options": [{"option_id": "japan", "text": "Япония"}, {"option_id": "china", "text": "Китай"}]}
        state = {"option": None, "bad": False}
        def fake_call(_base, path, body=None, token=None):
            if path.startswith("/v1/catalog"):
                return {"quiz": {"questions": [question, {"question_id": "other"}]}}
            if path == "/v1/guests": return {"token": "private-token"}
            if path == "/v1/attempts":
                return {"attempt_id": "attempt", "participant_id": "p", "question_snapshots": [
                    {"question_id": "fixture", "question_revision": revision},
                    {"question_id": "other", "question_revision": revision}]}
            if path.endswith("/answers"):
                self.assertEqual(len(body["payload_digest"]), 64)
                state["option"] = body["answer"]["option_id"]
                return {"participant_id": "p", "question_revision": revision}
            if path.endswith("/finish"):
                return {"server_score": 1 if state["bad"] or state["option"] == "japan" else 0, "history": [{}]}
            raise AssertionError(path)
        rehearse.call = fake_call
        articles = self.root / "article-assets"
        articles.mkdir()
        path = articles / "articles.json"
        path.write_text(json.dumps({"articles": [{"question_refs": [{"question_id": "fixture", "revision_sha256": "a" * 64}]}]}))
        rehearse.require_candidate_contract("http://candidate", articles)
        state["bad"] = True
        with self.assertRaisesRegex(RuntimeError, "authoritative"):
            rehearse.require_candidate_contract("http://candidate", articles)
        path.write_text(json.dumps({"articles": [{"question_refs": [{"question_id": "fixture"}]}]}))
        with self.assertRaisesRegex(RuntimeError, "article revision"):
            rehearse.require_article_bindings(articles)

    def test_node_and_imagefs_boundaries_reject_unhealthy_or_less_than_twenty_percent(self):
        healthy = {"status": {"conditions": [{"type": "Ready", "status": "True"}, {"type": "DiskPressure", "status": "False"}]},
                   "spec": {"taints": []}}
        release.validate_node_status(healthy)
        release.validate_imagefs_blocks(20, 100)
        for bad in (
            {"status": {"conditions": [{"type": "Ready", "status": "False"}, {"type": "DiskPressure", "status": "False"}]}, "spec": {}},
            {"status": {"conditions": [{"type": "Ready", "status": "True"}, {"type": "DiskPressure", "status": "True"}]}, "spec": {}},
            {"status": {"conditions": [{"type": "Ready", "status": "True"}, {"type": "DiskPressure", "status": "False"}]}, "spec": {"unschedulable": True}},
            {"status": {"conditions": [{"type": "Ready", "status": "True"}, {"type": "DiskPressure", "status": "False"}]}, "spec": {"taints": [{"effect": "NoExecute"}]}},
        ):
            with self.assertRaises(release.GuardError):
                release.validate_node_status(bad)
        with self.assertRaises(release.GuardError):
            release.validate_imagefs_blocks(19, 100)

    def test_article_runtime_binding_handles_only_exact_pinned_study_refs(self):
        old = rehearse.call
        self.addCleanup(lambda: setattr(rehearse, 'call', old))
        calls = []
        def catalog(_base, path):
            calls.append(path)
            self.assertEqual(path, '/v1/catalog?quiz_id=playable')
            return {'quiz': {'questions': [{'question_id': 'question', 'revision': {'sha256': 'a' * 64}}]}}
        rehearse.call = catalog
        folder = self.root / 'bindings'
        folder.mkdir()
        refs = [{'quiz_id': q, 'question_id': k, 'revision_sha256': sha}
                for (q, k), sha in rehearse.NONCATALOG_READER_REFS.items()]
        refs.append({'quiz_id': 'playable', 'question_id': 'question', 'revision_sha256': 'a' * 64})
        path = folder / 'articles.json'
        path.write_text(json.dumps({'articles': [{'question_refs': refs}, {'question_refs': []}]}))
        rehearse.require_article_bindings(folder, 'http://candidate')
        self.assertEqual(len(calls), 1)
        refs[0]['revision_sha256'] = '0' * 64
        path.write_text(json.dumps({'articles': [{'question_refs': refs}]}))
        with self.assertRaisesRegex(RuntimeError, 'exact pin'):
            rehearse.require_article_bindings(folder, 'http://candidate')

    def test_rehearsal_stays_ready_until_http_grading_finishes(self):
        script = release.remote_script(self.build, self.version['api_sha256'], 'prepare')
        self.assertNotIn('docker start', script)
        grade = script.index('python3 "$stage/rehearse.py"')
        stop = script.index('docker stop "$rehearsal"')
        self.assertLess(grade, stop)
        self.assertLess(stop, script.index('sqlite3 "$stage/rehearsal-data/quiz.db"'))

    def test_regional_http_rehearsal_maps_shuffled_options_and_rejects_wrong_grade(self):
        sources = {}
        for quiz_id in rehearse.REGIONAL_QUIZ_IDS:
            question_id = quiz_id + '-one'
            source = {
                'id': quiz_id, 'title': quiz_id, 'description': 'Fixture', 'category': 'Geography',
                'questions': [{
                    'id': question_id, 'type': 'choice', 'text': 'Regional question',
                    'options': ['alpha', 'beta', 'private-correct-option', 'delta'],
                    'correct_answer': 2,
                }],
            }
            sources[quiz_id] = source
            (self.root / 'extra-quizzes' / f'{quiz_id}.json').write_text(json.dumps(source))

        old = rehearse.call
        self.addCleanup(lambda: setattr(rehearse, 'call', old))
        attempts, submitted, wrong_grade = {}, [], {'enabled': False}
        def public_catalog(quiz_id):
            source = sources[quiz_id]
            questions = []
            for raw in source['questions']:
                question_id = raw['id']
                # Deliberately reverse the public options. Correctness must be
                # derived from the source index by text, never public position.
                options = [{'option_id': f'{question_id}-opt-{text}', 'text': text}
                           for text in reversed(raw['options'])]
                questions.append({'question_id': question_id, 'stem': raw['text'],
                                  'revision': {'number': 1, 'sha256': 'a' * 64}, 'options': options})
            return {'bundle_sha256': 'bundle-' + quiz_id, 'bundle_version': 'v1',
                    'quiz': {'quiz_id': quiz_id, 'questions': questions}}
        def fake_call(_base, path, body=None, token=None):
            if path.startswith('/v1/catalog?quiz_id='):
                return public_catalog(path.partition('=')[2])
            if path == '/v1/guests':
                return {'token': 'never-log-this-token'}
            if path == '/v1/attempts':
                quiz_id = body['quiz_id']
                number = len(attempts)
                attempt_id = f'attempt-{number}'
                catalog = public_catalog(quiz_id)
                snapshots = []
                for question in catalog['quiz']['questions']:
                    option_order = [option['option_id'] for option in reversed(question['options'])]
                    snapshots.append({'question_id': question['question_id'], 'question_revision': question['revision'],
                                      'option_order': option_order,
                                      'position_to_option_id': {str(i): option for i, option in enumerate(option_order)}})
                attempt = {'attempt_id': attempt_id, 'participant_id': 'p-regional',
                           'bundle_sha256': catalog['bundle_sha256'], 'bundle_version': catalog['bundle_version'],
                           'question_snapshots': snapshots}
                attempts[attempt_id] = {'quiz_id': quiz_id, 'attempt': attempt, 'answers': []}
                return attempt
            if path.endswith('/answers'):
                attempt_id = path.split('/')[3]
                record = attempts[attempt_id]
                expected = rehearse.canonical_answer_digest(attempt_id, 'p-regional', body['question_id'],
                                                             body['question_revision'], body['answer']['option_id'])
                self.assertEqual(body['payload_digest'], expected)
                record['answers'].append(body)
                submitted.append(body['answer']['option_id'])
                return {'receipt_id': 'receipt-' + body['question_id'], 'attempt_id': attempt_id,
                        'participant_id': 'p-regional', 'question_id': body['question_id'],
                        'question_revision': body['question_revision']}
            if path.endswith('/finish'):
                attempt_id = path.split('/')[3]
                record = attempts[attempt_id]
                expected_correct = {question['id']: question['options'][question['correct_answer']]
                                    for question in sources[record['quiz_id']]['questions']}
                score = sum(answer['answer']['option_id'].endswith(expected_correct[answer['question_id']])
                            for answer in record['answers'])
                if wrong_grade['enabled'] and score == 0:
                    score = 1
                return {'attempt_id': attempt_id, 'participant_id': 'p-regional', 'status': 'finished',
                        'server_score': score,
                        'history': [{'question_id': answer['question_id'],
                                     'question_revision': answer['question_revision'],
                                     'receipt_id': 'receipt-' + answer['question_id']}
                                    for answer in record['answers']]}
            raise AssertionError(path)
        rehearse.call = fake_call

        result = rehearse.require_regional_quiz_contract('http://candidate', self.root / 'extra-quizzes')
        self.assertEqual([row['quiz_id'] for row in result], list(rehearse.REGIONAL_QUIZ_IDS))
        self.assertTrue(all(row['questions_count'] == 1 and row['correct_score'] == 1 and row['wrong_score'] == 0
                            for row in result))
        self.assertIn('prep-capitals-europe-one-opt-private-correct-option', submitted)
        self.assertNotIn('private-correct-option', json.dumps(result))

        wrong_grade['enabled'] = True
        with self.assertRaisesRegex(RuntimeError, 'authoritative finish'):
            rehearse.require_regional_quiz_contract('http://candidate', self.root / 'extra-quizzes')


if __name__ == "__main__":
    unittest.main()
