import importlib.util
import json
import tempfile
import unittest
from pathlib import Path


def _controller():
    path = Path(__file__).with_name('release_executor.py')
    spec = importlib.util.spec_from_file_location('native_followup_controller', path)
    assert spec and spec.loader
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class NativeFollowupBaselineTest(unittest.TestCase):
    def test_only_current_published_release_is_a_valid_baseline(self):
        controller = _controller()
        self.assertEqual(
            (
                controller.BASE_REVISION,
                controller.BASE_DEPLOYMENT_REVISION,
                controller.BASE_BUILD_ID,
            ),
            ('82', '80', 'quiz-2026.10.21-feedback-02df23a7'),
        )
        self.assertEqual(
            controller.BASE_OCI_INDEX_DIGEST,
            'sha256:4b785307be90941b23a5b59c5ffdee18edfdcb62cdff18897a3ce43959c92ef4',
        )
        self.assertEqual(
            controller.BASE_OCI_MANIFEST_DIGEST,
            'sha256:ac4bf41df357fe8de546a8d0aff63b0bb976324f00f6146ef12eecc8ed6b6724',
        )
        self.assertEqual(
            controller.BASE_DOCKER_CONFIG_DIGEST,
            'sha256:574eb768f63655d0b26339ea6f7513382c256c03f21b2a23e7b71a2acaee67db',
        )
        script = controller.remote_script(
            'quiz-2026.10.21-feedback-deadbeef',
            controller.API_SHA256,
            'publish',
            reviewed_receipt_bytes=b'{"build_id":"quiz-2026.10.21-feedback-deadbeef","input_sha256":"x","image":"x@sha256:y"}',
        )
        self.assertIn('helm rollback quiz-master 82', script)
        self.assertNotIn('quiz-2026.10.20-lazy-2af0ab3f', script)
        self.assertNotIn('rollback quiz-master 81', script)
        controller.validate_build_id('quiz-2026.10.21-native-followup-deadbeef')

    def test_frontend_controller_still_rejects_api_or_short_disk_guards(self):
        controller = _controller()
        with self.assertRaises(controller.GuardError):
            controller.validate_imagefs_blocks(
                199, 1271532, 1000, 1271337, '/dev/vda2'
            )
        with self.assertRaises(controller.GuardError):
            controller.validate_build_id('quiz-2026.10.20-lazy-deadbeef')

    def test_helm_81_preflight_cannot_replay_against_helm_82_controller(self):
        controller = _controller()
        prior = [
            {
                'hostname': controller.HOST,
                'revision': '81',
                'deployment_revision': '79',
                'pvc_uid': controller.PVC_UID,
                'containers': [
                    {'name': 'api', 'image': 'old'},
                    {'name': 'web', 'image': 'old'},
                ],
                'disk': {'free': 1},
            },
            {
                'api_sha256': controller.API_SHA256,
                'buildId': 'quiz-2026.10.21-feedback-3208d5f0',
            },
            {
                'status': {
                    'conditions': [
                        {'type': 'Ready', 'status': 'True'},
                        {'type': 'DiskPressure', 'status': 'False'},
                    ],
                },
                'spec': {},
            },
            {
                'fstype': 'ext4',
                'f_bavail': 2000000,
                'f_bfree': 3275433,
                'f_blocks': 10000000,
                'reserved_block_count': 1271337,
                'block_device': '/dev/vda2',
            },
        ]
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'preflight.json'
            path.write_text('\n'.join(json.dumps(row) for row in prior))
            with self.assertRaises(controller.GuardError):
                controller.read_preflight(path)


if __name__ == '__main__':
    unittest.main()
