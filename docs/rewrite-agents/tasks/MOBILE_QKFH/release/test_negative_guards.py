import hashlib
import json
import tempfile
import unittest
from pathlib import Path

import release_executor as subject


def preflight(image=subject.BASE_IMAGE, revision="64"):
    return "\n".join(
        [
            json.dumps({"hostname": subject.HOST, "revision": revision, "deployment_revision": "62", "pvc_uid": subject.PVC_UID, "containers": [{"name": "api", "image": image}, {"name": "web", "image": image}], "disk": {"free": 14396968960}}),
            json.dumps({"buildId": "quiz-2026.10.15-country483-3c22818", "api_sha256": subject.API_SHA256}),
        ]
    ) + "\n"


class NegativeGuardTests(unittest.TestCase):
    def test_accepts_the_multiline_pinned_preflight_document(self):
        subject.read_preflight(Path(__file__).parent.parent / "preflight-current.txt")

    def test_rejects_deployment_counter_as_the_helm_revision(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "preflight.txt"
            path.write_text(preflight(revision="62"))
            with self.assertRaises(subject.GuardError):
                subject.read_preflight(path)

    def test_rejects_wrong_baseline_image(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "preflight.txt"
            path.write_text(preflight(image="docker.io/library/other@sha256:" + "0" * 64))
            with self.assertRaises(subject.GuardError):
                subject.read_preflight(path)

    def test_rejects_wrong_revision(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "preflight.txt"
            path.write_text(preflight(revision="61"))
            with self.assertRaises(subject.GuardError):
                subject.read_preflight(path)

    def test_rejects_nonproduction_ssh_target(self):
        with self.assertRaises(subject.GuardError):
            subject.validate_ssh_target("root@192.0.2.1")

    def test_execute_requires_explicit_existing_identity_file(self):
        with self.assertRaises(subject.GuardError):
            subject.validate_identity_file(None)

    def test_rejects_baseline_build_reuse(self):
        with self.assertRaises(subject.GuardError):
            subject.validate_build_id("quiz-2026.10.15-country483-3c22818")

    def test_plan_mode_has_no_remote_write(self):
        with tempfile.TemporaryDirectory() as directory:
            package = Path(directory)
            (package / "web").mkdir(); (package / "chart").mkdir()
            main_js = "web"
            (package / "web" / "main.dart.js").write_text(main_js)
            (package / "web" / "version.json").write_text(json.dumps({
                "buildId": "quiz-qkfh-abcdef",
                "api_sha256": subject.API_SHA256,
                "source_commit": "a" * 40,
                "main_dart_js_sha256": hashlib.sha256(main_js.encode()).hexdigest(),
            }))
            (package / "chart" / "Chart.yaml").write_text("apiVersion: v2\nname: quiz-master\n")
            result = subject.plan("quiz-qkfh-abcdef", subject.collect_inputs(package))
            self.assertEqual(result["mode"], "PLAN_ONLY")
            self.assertFalse(result["remote_write"])

    def test_manifest_is_lf_and_matches_the_in_memory_hash(self):
        with tempfile.TemporaryDirectory() as directory:
            package = Path(directory)
            (package / "web").mkdir(); (package / "chart").mkdir()
            main_js = "web"
            (package / "web" / "main.dart.js").write_text(main_js)
            (package / "web" / "version.json").write_text(json.dumps({"buildId": "quiz-qkfh-abcdef", "api_sha256": subject.API_SHA256, "source_commit": "a" * 40, "main_dart_js_sha256": hashlib.sha256(main_js.encode()).hexdigest()}))
            (package / "chart" / "Chart.yaml").write_text("apiVersion: v2\nname: quiz-master\n")
            inputs = subject.collect_inputs(package)
            manifest = subject.write_local_manifest(inputs)
            self.assertNotIn(b"\r\n", manifest.read_bytes())
            self.assertEqual(hashlib.sha256(subject.FRONTEND_DOCKERFILE.encode()).hexdigest(), inputs.manifest["dockerfile_sha256"])

    def test_remote_post_upgrade_failures_are_rollback_armed(self):
        script = subject.remote_script("quiz-qkfh-abcdef")
        self.assertIn('test "$base_docker_id" = sha256:dc230d8cec6d555c3f0e67f17a8bdab4452cb546cdf29b50c4c6395717ba8c00', script)
        self.assertIn("set -Eeuo pipefail", script)
        self.assertIn("trap post_upgrade_err ERR", script)
        self.assertNotIn("if ! verify_public", script)
        self.assertEqual(script.count("|| return 1"), 5)
        self.assertIn("USER 0:0\nRUN find /usr/share/nginx/html", subject.FRONTEND_DOCKERFILE)
        self.assertTrue(subject.FRONTEND_DOCKERFILE.endswith("USER 10001:10001\n"))


if __name__ == "__main__":
    unittest.main()
