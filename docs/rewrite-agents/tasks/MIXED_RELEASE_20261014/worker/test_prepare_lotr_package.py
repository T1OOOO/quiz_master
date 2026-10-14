"""Pure regression guards for the immutable LOTR package producer."""
from __future__ import annotations

import copy
import json
import re
import pathlib
import tarfile
import tempfile
import unittest
from pathlib import Path

import prepare_lotr_package as p


ROOT = Path(__file__).resolve().parents[5]
BASELINE = ROOT / ".run/screen_song_package_20261014/package-v1/quiz-2026.10.14-screen-song-6866608"
PILOT = ROOT / "docs/rewrite-agents/tasks/LOTR_WORDING_PILOT_20261014"


def load(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


class FrozenContentGuards(unittest.TestCase):
    def actual_runtime_inputs(self):
        return (
            load(PILOT / "integration-runtime-bundle.json"),
            load(PILOT / "integration-public-baseline.json"),
            load(ROOT / "study/question_articles/snapshots/lotr-return-king-bts-100.json"),
        )

    def test_actual_two_question_repair_preserves_other_raw_and_public_questions(self):
        runtime, public, snapshot = self.actual_runtime_inputs()
        old_raw = load(BASELINE / p.RAW_PATH)
        new_raw = load(ROOT / p.RAW_PATH)
        p.verify_raw_repair(old_raw, new_raw, runtime)
        p.verify_runtime_projection(runtime, public, snapshot)

    def test_raw_non_target_mutation_is_rejected(self):
        runtime, _, _ = self.actual_runtime_inputs()
        old_raw = load(BASELINE / p.RAW_PATH)
        new_raw = copy.deepcopy(load(ROOT / p.RAW_PATH))
        new_raw["questions"][0]["text"] += " synthetic mutation"
        with self.assertRaisesRegex(RuntimeError, "98 non-target raw"):
            p.verify_raw_repair(old_raw, new_raw, runtime)

    def test_local_canonical_bundle_preserves_98_questions_keys_and_revisions(self):
        old_bundle = load(BASELINE / p.TARGET_CONTENT_ROOT / "bundle.json")
        new_bundle = load(ROOT / p.TARGET_CONTENT_ROOT / "bundle.json")
        p.verify_local_canonical_repair(old_bundle, new_bundle)
        mutated = copy.deepcopy(new_bundle)
        mutated["private_grading"]["lotr-rk-1"]["correct_option_id"] = "lotr-rk-1-opt-99"
        with self.assertRaisesRegex(RuntimeError, "98 non-target local private keys"):
            p.verify_local_canonical_repair(old_bundle, mutated)

    def test_retained_option_and_private_keys_are_enforced(self):
        runtime, public, snapshot = self.actual_runtime_inputs()
        wrong_option = copy.deepcopy(runtime)
        wrong_option["quiz"]["questions"][94]["options"][3]["option_id"] = "lotr-rk-95-opt-4"
        with self.assertRaisesRegex(RuntimeError, "retained option identifiers"):
            p.verify_runtime_projection(wrong_option, public, snapshot)
        wrong_key = copy.deepcopy(runtime)
        wrong_key["private_grading"]["lotr-rk-93"]["correct_option_id"] = "lotr-rk-93-opt-1"
        with self.assertRaisesRegex(RuntimeError, "retained correct options"):
            p.verify_runtime_projection(wrong_key, public, snapshot)

    def test_reader_and_catalog_preserve_baseline_and_add_exact_two_bindings(self):
        old_catalog = p.as_rows(load(BASELINE / "web/assets/assets/catalog.json"), "baseline catalog")
        old_reader = p.as_rows(load(BASELINE / "web/assets/assets/study/question-articles.json"), "baseline Reader")
        catalog = p.as_rows(load(ROOT / "next/apps/quiz_app/assets/catalog.json"), "target catalog")
        reader = p.as_rows(load(ROOT / "next/apps/quiz_app/assets/study/question-articles.json"), "target Reader")
        mixed_row = next((row for row in catalog if row['quiz_id'] == p.MIXED_QUIZ_ID), None)
        counts = p.verify_asset_rows(catalog, reader, old_catalog, old_reader, mixed_row)
        self.assertEqual(counts, {"packs": 136 if mixed_row else 135, "questions": 4084 if mixed_row else 4064, "reader_articles": 266})

    def test_changed_old_reader_object_is_rejected(self):
        old_catalog = p.as_rows(load(BASELINE / "web/assets/assets/catalog.json"), "baseline catalog")
        old_reader = p.as_rows(load(BASELINE / "web/assets/assets/study/question-articles.json"), "baseline Reader")
        catalog = p.as_rows(load(ROOT / "next/apps/quiz_app/assets/catalog.json"), "target catalog")
        reader = copy.deepcopy(p.as_rows(load(ROOT / "next/apps/quiz_app/assets/study/question-articles.json"), "target Reader"))
        reader[0]["title_ru"] += " synthetic mutation"
        with self.assertRaisesRegex(RuntimeError, "prior 264 Reader"):
            p.verify_asset_rows(catalog, reader, old_catalog, old_reader, next((row for row in catalog if row['quiz_id'] == p.MIXED_QUIZ_ID), None))


class RuntimeAndReceiptGuards(unittest.TestCase):
    def test_mixed_runtime_reconstruction_rejects_raw_key_or_revision_drift(self):
        runtime = load(PILOT / 'integration-runtime-bundle.json')
        runtime = copy.deepcopy(runtime)
        rows = runtime['quiz']['questions'][:20]
        runtime['quiz']['quiz_id'] = p.MIXED_QUIZ_ID
        runtime['quiz']['questions'] = rows
        runtime['private_grading'] = {row['question_id']: runtime['private_grading'][row['question_id']] for row in rows}
        runtime['private_question_metadata'] = {}
        raw = {'questions': []}
        for row in rows:
            row['quiz_id'] = p.MIXED_QUIZ_ID
            row['source'] = {'uri': '/app/' + p.MIXED_RAW_PATH}
            row['revision'] = {'number': 1, 'sha256': p.canonical(p.private_revision_input(runtime, row))}
            key = runtime['private_grading'][row['question_id']]['correct_option_id']
            raw['questions'].append({'text': row['stem'], 'options': [o['text'] for o in row['options']], 'correct_answer': next(i for i, o in enumerate(row['options']) if o['option_id'] == key)})
        frozen = {p.MIXED_RAW_PATH: json.dumps(raw).encode(), f'next/content/{p.MIXED_QUIZ_ID}/bundle.json': json.dumps(runtime).encode()}
        p.verify_mixed_runtime(runtime, frozen)
        wrong = copy.deepcopy(runtime)
        wrong['quiz']['questions'][0]['revision']['sha256'] = '0' * 64
        with self.assertRaisesRegex(RuntimeError, 'mixed runtime revision'):
            p.verify_mixed_runtime(wrong, frozen)
        raw['questions'][0]['correct_answer'] = 99
        frozen[p.MIXED_RAW_PATH] = json.dumps(raw).encode()
        with self.assertRaisesRegex(RuntimeError, 'mixed raw/runtime'):
            p.verify_mixed_runtime(runtime, frozen)

    def test_mixed_append_preserves_baseline_cache_and_rejects_existing_pack(self):
        cache = load(BASELINE / 'runtime-bundles.json')
        runtime = load(PILOT / 'integration-runtime-bundle.json')
        mixed = {'quiz': {'quiz_id': p.MIXED_QUIZ_ID, 'questions': [{'question_id': f'mixed-{i}'} for i in range(20)]}}
        result = p.append_only_cache(cache, runtime, mixed)
        self.assertEqual(len(result), 14)
        self.assertEqual(result[p.MIXED_QUIZ_ID], mixed)
        self.assertTrue(all(result[key] == value for key, value in cache.items()))
        bad = copy.deepcopy(mixed)
        bad['quiz']['quiz_id'] = 'other-pack'
        with self.assertRaisesRegex(RuntimeError, 'mixed'):
            p.append_only_cache(cache, runtime, bad)

    def test_mixed_catalog_preserves_all_old_rows_and_adds_exact_reviewed_row(self):
        catalog = p.as_rows(load(BASELINE / 'web/assets/assets/catalog.json'), 'old')
        old_reader = p.as_rows(load(BASELINE / 'web/assets/assets/study/question-articles.json'), 'old')
        reader = p.as_rows(load(ROOT / 'next/apps/quiz_app/assets/study/question-articles.json'), 'new')
        mixed_row = {'quiz_id': p.MIXED_QUIZ_ID, 'questions_count': 20, 'title': 'Mixed'}
        target = copy.deepcopy(catalog) + [mixed_row]
        self.assertEqual(p.verify_asset_rows(target, reader, catalog, old_reader, mixed_row), {'packs': 136, 'questions': 4084, 'reader_articles': 266})
        target[0]['title'] = 'Changed'
        with self.assertRaisesRegex(RuntimeError, '135 ScreenSong52 catalog'):
            p.verify_asset_rows(target, reader, catalog, old_reader, mixed_row)

    def test_exact_runtime_cache_append_and_staging_revision_counts(self):
        baseline_cache = load(BASELINE / "runtime-bundles.json")
        runtime = load(PILOT / "integration-runtime-bundle.json")
        target_cache = p.append_only_cache(baseline_cache, runtime)
        self.assertEqual((len(baseline_cache), len(target_cache)), (12, 13))
        expected, proof = p.expected_staging_revisions_from_bundles(target_cache, p.BUILD_ID)
        self.assertEqual(sum(len(rows) for rows in expected.values()), 260)
        self.assertEqual(len(proof), 260)

    def test_existing_target_cache_entry_is_rejected(self):
        baseline_cache = load(BASELINE / "runtime-bundles.json")
        baseline_cache[p.QUIZ_ID] = {}
        with self.assertRaisesRegex(RuntimeError, "twelve prior entries"):
            p.append_only_cache(baseline_cache, {})

    def test_frozen_question_map_computes_143_to_145_exact_bindings(self):
        documents = []
        for path in sorted((ROOT / "next/content").glob("*/bundle.json")):
            documents.append(load(path))
        for path in sorted((ROOT / "study/question_articles/snapshots").glob("*.json")):
            documents.append(load(path))
        revision_map = p.revision_map_from_documents(documents)
        old_reader = p.as_rows(load(BASELINE / "web/assets/assets/study/question-articles.json"), "baseline Reader")
        reader = p.as_rows(load(ROOT / "next/apps/quiz_app/assets/study/question-articles.json"), "target Reader")
        self.assertEqual(p.count_exact_article_bindings(old_reader, revision_map), 143)
        self.assertEqual(p.count_exact_article_bindings(reader, revision_map), 145)


class PreparedScriptGuards(unittest.TestCase):
    def test_generated_rollback_uses_verified_baseline_assets_with_expanded_copied_db(self):
        body = p.patch_rehearsal_text((BASELINE / 'rehearse.py').read_text(encoding='utf-8'), mixed=True)
        prefix = body.split('# Previous immutable API', 1)[1].split('\n', 1)[1].split('rollback=sandbox', 1)[0]
        self.assertIn('baseline_root=', prefix)
        preflight = prefix.replace("pathlib.Path('/opt/quiz-master/releases/" + p.BASELINE_BUILD + "')", 'pathlib.Path(' + repr(str(BASELINE.resolve())) + ')')
        exec(compile(preflight, 'generated-baseline-preflight', 'exec'), {'pathlib': pathlib, 'hashlib': __import__('hashlib')})
        self.assertIn("shutil.copyfile(baseline_root/'api',rollback)", body)
        self.assertIn(p.BASELINE_API_SHA256, body)
        env_line = next(line for line in body.splitlines() if line.startswith("env.update({'QM_CONTENT_BUNDLE_PATH':str(baseline_root"))
        env = {'QM_DATABASE_URL': 'sqlite:copied-expanded.sqlite', 'QM_CONTENT_BUNDLE_PATH': '/new/quizzes'}
        exec(compile(env_line, 'generated-baseline-env', 'exec'), {'env': env, 'baseline_root': BASELINE})
        self.assertEqual(env['QM_DATABASE_URL'], 'sqlite:copied-expanded.sqlite')
        self.assertEqual(env['QM_CONTENT_BUNDLE_PATH'], str(BASELINE / 'quizzes'))
        self.assertEqual(env['QM_CONTENT_MANIFEST_PATH'], str(BASELINE / 'next/content/home-alone-1-part-1/manifest.json'))
        self.assertEqual(env['QM_CONTENT_TAXONOMY_PATH'], str(BASELINE / 'metadata/tags.v1.json'))
        with tempfile.TemporaryDirectory() as directory:
            fake = Path(directory)
            (fake / 'checksums.txt').write_text('changed baseline checksum manifest')
            wrong = prefix.replace("pathlib.Path('/opt/quiz-master/releases/" + p.BASELINE_BUILD + "')", 'pathlib.Path(' + repr(str(fake)) + ')')
            with self.assertRaises(AssertionError):
                exec(compile(wrong, 'wrong-baseline-preflight', 'exec'), {'pathlib': pathlib, 'hashlib': __import__('hashlib')})

    def test_generated_cutover_python_regex_accepts_exact_plain_build(self):
        shell = p.patch_cutover_text((BASELINE / 'cutover.sh').read_text(encoding='utf-8'), '3' * 64, mixed=True)
        line = next(line for line in shell.splitlines() if line.startswith('assert re.fullmatch('))
        code = compile(line, 'generated-cutover-build-guard', 'exec')
        exec(code, {'re': re, 'build': p.BUILD_ID})
        for invalid in (p.BUILD_ID + '-extra', p.BUILD_ID.replace('.', 'X', 1)):
            with self.assertRaises(AssertionError):
                exec(code, {'re': re, 'build': invalid})

    def test_api_provenance_allows_only_three_exact_noncompiled_tests(self):
        expected = ['next/server/cmd/quizctl/catalog_test.go', 'next/server/internal/content/import_identity_test.go', 'next/server/internal/sqlite/collection_test.go']
        p.verify_api_changed_paths(expected)
        for paths in (expected + ['next/server/internal/sqlite/production.go'], expected + ['next/server/internal/sqlite/other_test.go'], expected[:1]):
            with self.assertRaisesRegex(RuntimeError, 'API source'):
                p.verify_api_changed_paths(paths)

    def test_mixed_cutover_and_rehearsal_use_target_counts_and_keep_rollback(self):
        cutover = p.patch_cutover_text((BASELINE / 'cutover.sh').read_text(encoding='utf-8'), '3' * 64, mixed=True)
        self.assertIn("meta['packs']==136 and meta['questions']==4084", cutover)
        self.assertIn('--expected-packs 136 --expected-questions 4084', cutover)
        rehearsal = p.patch_rehearsal_text((BASELINE / 'rehearse.py').read_text(encoding='utf-8'), mixed=True)
        self.assertIn('assert graded==335 and finished==15', rehearsal)
        self.assertIn('after[3]-before[3]==136', rehearsal)
        self.assertIn("'canonical_packs':14,'canonical_questions':280", rehearsal)
        self.assertIn('old_api_rollback', rehearsal)
        self.assertEqual(rehearsal.count(repr(p.MIXED_QUIZ_ID)), 4)

    def test_cutover_patch_keeps_prepare_only_infrastructure_guards(self):
        baseline = (BASELINE / "cutover.sh").read_text(encoding="utf-8")
        patched = p.patch_cutover_text(baseline, "3" * 64)
        self.assertIn(f"quiz_build={p.BUILD_ID}", patched)
        self.assertIn(p.TARGET_SOURCE, patched)
        self.assertIn(p.BASELINE_IMAGE, patched)
        self.assertIn("meta['packs']==135 and meta['questions']==4064 and meta['question_articles']==266", patched)
        self.assertIn("[[ \"$quiz_mode\" = prepare ]]", patched)
        self.assertNotIn("helm upgrade", patched)
        self.assertEqual(patched.count("exit 0\n"), 1)
        self.assertIn(p.BASELINE_IMAGE, patched)
        self.assertNotIn(p.BASELINE_API_SHA256, patched)
        for pin in (p.TARGET_API_SHA256, p.NGINX_SHA256, p.PVC_UID):
            self.assertIn(pin, patched)
        self.assertIn("verify_candidate_runtime.py", patched)
        self.assertIn("$quiz_run-candidate-runtime.json", patched)

    def test_rehearsal_patch_adds_existing_pack_without_dropping_db_or_rollback_guards(self):
        baseline = (BASELINE / "rehearse.py").read_text(encoding="utf-8")
        patched = p.patch_rehearsal_text(baseline)
        compile(patched, "rehearse.py", "exec")
        self.assertEqual(patched.count("'lotr-return-king-bts-100'"), 4)
        self.assertIn("assert graded==315 and finished==14", patched)
        self.assertIn("==14\n assert req('/v1/history/'", patched)
        self.assertIn("'canonical_packs':13,'canonical_questions':260", patched)
        for guard in ("old_rows[t] <= current", "pragma integrity_check", "old_api_rollback", "after[3]-before[3]==135"):
            self.assertIn(guard, patched)

    def test_values_patch_uses_verified_screen_song_image_and_target_build(self):
        baseline = (BASELINE / "release-values.yaml").read_text(encoding="utf-8")
        self.assertEqual(
            p.patch_values_text(baseline),
            f"image: {p.BASELINE_IMAGE}\nbuildId: {p.BUILD_ID}\n\nfeedbackAdminSecret: quiz-feedback-admin\n",
        )

    def test_target_api_receipts_and_elf_are_bound_before_copy(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            api = root / "api-linux-amd64"
            api.write_bytes(b"\x7fELF" + b"target-api")
            digest = p.sha256_file(api)
            build = {
                "command": ["go", "build", "-p=1", "-trimpath", "-buildvcs=false", "-o", str(api), "./cmd/api"],
                "cwd": str(root / "next/server"),
                "environment": {"GOOS": "linux", "GOARCH": "amd64", "CGO_ENABLED": "0"},
                "actual_exit": 0,
                "api_code_checkpoint": p.API_CODE_CHECKPOINT,
                "buildvcs": False,
                "artifact_path": str(api),
                "artifact_sha256": digest,
                "artifact_bytes": api.stat().st_size,
                "elf": True,
            }
            inspection = {
                "actual_exit": 0,
                "stdout": "path\tquiz_master/next/server/cmd/api\n\tbuild\t-trimpath=true\n\tbuild\tCGO_ENABLED=0\n\tbuild\tGOARCH=amd64\n\tbuild\tGOOS=linux\n",
                "only_server_difference_from_api_code_checkpoint": ["next/server/cmd/quizctl/catalog_test.go", "next/server/internal/content/import_identity_test.go", "next/server/internal/sqlite/collection_test.go"],
                "untracked_go_inputs": [],
            }
            pins = {
                "repo": str(root),
                "target_api": {"path": str(api), "sha256": digest},
                "target_api_build": build,
                "target_api_inspection": inspection,
            }
            p.verify_target_api(pins, expected_sha256=digest, expected_bytes=api.stat().st_size)
            stage = root / "stage"
            stage.mkdir()
            (stage / "api").write_bytes(b"baseline")
            p.copy_target_api(stage, api, expected_sha256=digest)
            self.assertEqual(p.sha256_file(stage / "api"), digest)
            broken = copy.deepcopy(build)
            broken["api_code_checkpoint"] = "0" * 40
            pins["target_api_build"] = broken
            with self.assertRaisesRegex(RuntimeError, "API code checkpoint"):
                p.verify_target_api(pins, expected_sha256=digest, expected_bytes=api.stat().st_size)

    def test_generated_archive_marks_target_api_executable(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            stage = root / p.BUILD_ID
            stage.mkdir()
            (stage / "api").write_bytes(b"\x7fELFfixture")
            (stage / "plain.txt").write_text("plain", encoding="utf-8")
            archive, _, _ = p.archive_and_verify(stage, root)
            with tarfile.open(archive, "r:gz") as package:
                self.assertEqual(package.getmember(f"{p.BUILD_ID}/api").mode, 0o755)
                self.assertEqual(package.getmember(f"{p.BUILD_ID}/plain.txt").mode, 0o644)


class BoundaryGuards(unittest.TestCase):
    def test_archive_members_reject_traversal_duplicate_and_wrong_prefix(self):
        safe = [tarfile.TarInfo(f"{p.BASELINE_BUILD}/api"), tarfile.TarInfo(f"{p.BASELINE_BUILD}/web/index.html")]
        for member in safe:
            member.type = tarfile.REGTYPE
        p.validate_archive_members(safe, p.BASELINE_BUILD)
        cases = [
            safe + [safe[0]],
            [tarfile.TarInfo(f"{p.BASELINE_BUILD}/../escape")],
            [tarfile.TarInfo("other/api")],
            [tarfile.TarInfo(f'{p.BASELINE_BUILD}/C:escape')],
            [tarfile.TarInfo(f'{p.BASELINE_BUILD}/web//index.html')],
        ]
        for members in cases:
            for member in members:
                member.type = tarfile.REGTYPE
            with self.assertRaisesRegex(RuntimeError, "unsafe or unexpected archive member"):
                p.validate_archive_members(members, p.BASELINE_BUILD)

    def test_output_root_must_be_new(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            missing = root / "new-output"
            p.require_new_output_root(missing)
            root.joinpath("existing-empty").mkdir()
            with self.assertRaisesRegex(RuntimeError, "must not already exist"):
                p.require_new_output_root(root / "existing-empty")

    def test_controller_review_requires_distinct_provider_and_exact_source_hashes(self):
        expected = {
            "prepare_lotr_package.py": "1" * 64,
            "test_prepare_lotr_package.py": "2" * 64,
            "README.md": "3" * 64,
        }
        review = {
            "schema_version": "qm-lotr-package-controller-review/v1",
            "actual_cli_exit": 0,
            "actual_hub_state": "ACCEPTED",
            "actual_reviews": {"task-review": {"verdict": "accept"}},
            "author_provider": "openai",
            "reviewer_provider": "claude",
            "reviewed_worker_sha256": expected,
            "scope": "prepare-only package producer source review; no execution or publication",
        }
        p.verify_controller_review(review, expected)
        same_provider = copy.deepcopy(review)
        same_provider["reviewer_provider"] = "openai"
        with self.assertRaisesRegex(RuntimeError, "different provider"):
            p.verify_controller_review(same_provider, expected)
        wrong_hash = copy.deepcopy(review)
        wrong_hash["reviewed_worker_sha256"]["README.md"] = "4" * 64
        with self.assertRaisesRegex(RuntimeError, "source hashes"):
            p.verify_controller_review(wrong_hash, expected)


if __name__ == "__main__":
    unittest.main()
