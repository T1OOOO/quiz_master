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
            ('85', '83', 'quiz-2026.10.21-feedback-d0dff40a'),
        )
        self.assertEqual(
            controller.BASE_OCI_INDEX_DIGEST,
            'sha256:093122f18d8b1aee16f41011e3abec8c25ea1dc83a3b904054cf413a47658282',
        )
        self.assertEqual(
            controller.BASE_OCI_MANIFEST_DIGEST,
            'sha256:52c135f33c22708969d7fd64dbae08442ca62ce9fa3b23cad6bd61c584b9d668',
        )
        self.assertEqual(
            controller.BASE_DOCKER_CONFIG_DIGEST,
            'sha256:62984511b49837eeac7fb688232d1ea4d9bdbf98ec7da36e501a717bba580d3a',
        )
        script = controller.remote_script(
            'quiz-2026.10.21-feedback-deadbeef',
            controller.API_SHA256,
            'publish',
            reviewed_receipt_bytes=b'{"build_id":"quiz-2026.10.21-feedback-deadbeef","input_sha256":"x","image":"x@sha256:y"}',
        )
        self.assertIn('helm rollback quiz-master 85', script)
        self.assertNotIn('quiz-2026.10.20-lazy-2af0ab3f', script)
        self.assertNotIn('rollback quiz-master 84', script)
        controller.validate_build_id('quiz-2026.10.21-native-followup-deadbeef')

    def test_frontend_controller_still_rejects_api_or_short_disk_guards(self):
        controller = _controller()
        with self.assertRaises(controller.GuardError):
            controller.validate_imagefs_blocks(
                199, 1271532, 1000, 1271337, '/dev/vda2'
            )
        with self.assertRaises(controller.GuardError):
            controller.validate_build_id('quiz-2026.10.20-lazy-deadbeef')

    def test_helm_84_preflight_cannot_replay_against_helm_85_controller(self):
        controller = _controller()
        prior = [
            {
                'hostname': controller.HOST,
                'revision': '84',
                'deployment_revision': '82',
                'pvc_uid': controller.PVC_UID,
                'containers': [
                    {'name': 'api', 'image': 'old'},
                    {'name': 'web', 'image': 'old'},
                ],
                'disk': {'free': 1},
            },
            {
                'api_sha256': controller.API_SHA256,
                'buildId': 'quiz-2026.10.21-feedback-5d06f0f3',
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
