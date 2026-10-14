"""Synthetic negative fixtures only; no release input or approval is fabricated."""
import json
import tempfile
import unittest
import copy
from pathlib import Path

import prepare_lotr_release as p


class NegativeGuards(unittest.TestCase):
    ROOT = Path(__file__).resolve().parents[2] / "LOTR_WORDING_PILOT_20261014"
    SNAPSHOT = Path(__file__).resolve().parents[5] / "study" / "question_articles" / "snapshots" / "lotr-return-king-bts-100.json"

    def actual_inputs(self):
        runtime = json.loads((self.ROOT / "integration-runtime-bundle.json").read_text(encoding="utf-8"))
        public = json.loads((self.ROOT / "integration-public-baseline.json").read_text(encoding="utf-8"))
        snapshot = json.loads(self.SNAPSHOT.read_text(encoding="utf-8"))
        return runtime, public, snapshot

    def test_actual_runtime_projection_and_snapshot_pass(self):
        runtime, public, snapshot = self.actual_inputs()
        p.verify_runtime_projection(runtime, public, snapshot)

    def test_actual_target_counts_and_browser_receipts_pass(self):
        repo = Path(__file__).resolve().parents[5]
        catalog = p.as_rows(p.read_json(repo / "next/apps/quiz_app/assets/catalog.json"), "catalog")
        reader = p.as_rows(p.read_json(repo / "next/apps/quiz_app/assets/study/question-articles.json"), "Reader")
        baseline = Path("C:/ap/quiz_master/.run/lotr_browser_20261014")
        old_catalog = p.as_rows(p.read_json(baseline / "baseline-catalog.json"), "baseline catalog")
        old_reader = p.as_rows(p.read_json(baseline / "baseline-reader.json"), "baseline Reader")
        p.verify_asset_rows(catalog, reader, old_catalog, old_reader)
        proof = p.read_json(Path(__file__).resolve().parents[1] / "local-browser" / "browser-proof.json")
        p.verify_browser_receipt(proof)

    def test_all_nine_declared_source_assets_pass(self):
        pins = p.load_release_pins(Path(__file__).resolve().parents[1] / "root-validator-pins.json")
        self.assertEqual(len(pins["source_assets"]), 9)
        p.verify_assets(Path(pins["repo"]), pins)

    def test_tampered_declared_raw_asset_is_rejected(self):
        pins = p.load_release_pins(Path(__file__).resolve().parents[1] / "root-validator-pins.json")
        pins = copy.deepcopy(pins)
        pins["source_assets"][p.RAW_PATH] = "0" * 64
        with self.assertRaisesRegex(RuntimeError, "frozen source asset differs: quizzes/Cinema/LOTR/lotr_return_king_bts_100.json"):
            p.verify_assets(Path(pins["repo"]), pins)

    def test_changed_old_article_is_rejected(self):
        repo, baseline = Path(__file__).resolve().parents[5], Path("C:/ap/quiz_master/.run/lotr_browser_20261014")
        catalog = p.as_rows(p.read_json(repo / "next/apps/quiz_app/assets/catalog.json"), "catalog")
        reader = copy.deepcopy(p.as_rows(p.read_json(repo / "next/apps/quiz_app/assets/study/question-articles.json"), "Reader"))
        old_catalog = p.as_rows(p.read_json(baseline / "baseline-catalog.json"), "baseline catalog")
        old_reader = p.as_rows(p.read_json(baseline / "baseline-reader.json"), "baseline Reader")
        reader[0]["title_ru"] += " synthetic mutation"
        with self.assertRaisesRegex(RuntimeError, "prior 264"):
            p.verify_asset_rows(catalog, reader, old_catalog, old_reader)

    def test_changed_catalog_and_count_are_rejected(self):
        repo, baseline = Path(__file__).resolve().parents[5], Path("C:/ap/quiz_master/.run/lotr_browser_20261014")
        catalog = copy.deepcopy(p.as_rows(p.read_json(repo / "next/apps/quiz_app/assets/catalog.json"), "catalog"))
        reader = p.as_rows(p.read_json(repo / "next/apps/quiz_app/assets/study/question-articles.json"), "Reader")
        old_catalog = p.as_rows(p.read_json(baseline / "baseline-catalog.json"), "baseline catalog")
        old_reader = p.as_rows(p.read_json(baseline / "baseline-reader.json"), "baseline Reader")
        catalog[0]["title"] += " synthetic mutation"
        with self.assertRaisesRegex(RuntimeError, "catalog rows"):
            p.verify_asset_rows(catalog, reader, old_catalog, old_reader)
        with self.assertRaisesRegex(RuntimeError, "135/4064"):
            p.verify_asset_rows(catalog[:-1], reader, old_catalog, old_reader)

    def test_mutated_unchanged_question_is_rejected(self):
        runtime, public, snapshot = self.actual_inputs()
        runtime = copy.deepcopy(runtime)
        runtime["quiz"]["questions"][0]["stem"] += " synthetic mutation"
        with self.assertRaisesRegex(RuntimeError, "served question changed"):
            p.verify_runtime_projection(runtime, public, snapshot)

    def test_mutated_retained_key_is_rejected(self):
        runtime, public, snapshot = self.actual_inputs()
        runtime = copy.deepcopy(runtime)
        runtime["private_grading"]["lotr-rk-95"]["correct_option_id"] = "lotr-rk-95-opt-5"
        with self.assertRaisesRegex(RuntimeError, "retained correct option"):
            p.verify_runtime_projection(runtime, public, snapshot)

    def test_q95_fourth_option_must_be_retained_old_option_five(self):
        runtime, public, snapshot = self.actual_inputs()
        runtime = copy.deepcopy(runtime)
        runtime["quiz"]["questions"][94]["options"][3]["option_id"] = "lotr-rk-95-opt-4"
        with self.assertRaisesRegex(RuntimeError, "option identifiers"):
            p.verify_runtime_projection(runtime, public, snapshot)

    def test_mutated_snapshot_is_rejected(self):
        runtime, public, snapshot = self.actual_inputs()
        snapshot = copy.deepcopy(snapshot)
        snapshot["quiz"]["questions"][92]["revision"]["sha256"] = "0" * 64
        with self.assertRaisesRegex(RuntimeError, "Reader snapshot bundle"):
            p.verify_runtime_projection(runtime, public, snapshot)

    def test_missing_pins_fail_closed(self):
        with self.assertRaisesRegex(RuntimeError, "missing required input"):
            p.load_release_pins(Path("C:/definitely-not-a-release-pin.json"))

    def test_wrong_baseline_is_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "pins.json"
            path.write_text(json.dumps({"schema_version": "qm-lotr-release-pins/v1", "frozen_commit": "x"}))
            with self.assertRaisesRegex(RuntimeError, "complete Root release pins"):
                p.load_release_pins(path)

    def test_wrong_runtime_shape_is_rejected(self):
        with self.assertRaisesRegex(RuntimeError, "exactly 100"):
            p.question_map({"quiz": {"questions": []}})

    def test_cache_rejects_existing_lotr_entry(self):
        cache = {str(n): {} for n in range(11)} | {p.QUIZ_ID: {}}
        with self.assertRaisesRegex(RuntimeError, "twelve prior"):
            p.append_only_cache(cache, {})

    def test_source_constants_are_exact(self):
        self.assertEqual(p.TARGET_SOURCE, "9194f61face75d03862003942ef55fae34aeec72")
        self.assertEqual(p.BASELINE_ARCHIVE_SHA256, "64e50bf9f49bd1287b0964f234cb9545508b878315e8fd577c262dc5c5ade6df")
        self.assertEqual(p.REPAIRED["lotr-rk-93"][:8], "4c90dc9b")
        self.assertEqual(p.REPAIRED["lotr-rk-95"][:8], "36e5d42e")


if __name__ == "__main__":
    unittest.main()
