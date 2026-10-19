"""Release boundaries: candidate bytes, flag closure and independent revisions."""
import hashlib
import json
import tempfile
import unittest
from pathlib import Path

import release_executor as release


class ReleaseInputsTest(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        (self.root / "web/flags").mkdir(parents=True)
        (self.root / "chart").mkdir()
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

    def test_remote_script_pins_api_and_rolls_back_to_actual_helm_revision(self):
        script = release.remote_script(self.build, self.version["api_sha256"])
        self.assertIn(self.version["api_sha256"], script)
        self.assertIn("helm rollback quiz-master 65", script)
        self.assertIn("post_upgrade_err", script)
        self.assertIn("restore-proof.sqlite", script)
        self.assertIn("original feedback row changed or missing", script)
        self.assertEqual(release.BASE_DEPLOYMENT_REVISION, "63")
        with self.assertRaises(release.GuardError):
            release.remote_script(self.build, "shell; command")


if __name__ == "__main__":
    unittest.main()
