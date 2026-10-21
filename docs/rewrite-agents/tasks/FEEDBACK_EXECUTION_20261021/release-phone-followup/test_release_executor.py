import importlib.util
import json
import tempfile
import unittest
from pathlib import Path


def _controller():
    path = Path(__file__).with_name('release_executor.py')
    spec = importlib.util.spec_from_file_location('phone_followup_controller', path)
    assert spec and spec.loader
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class PhoneFollowupBaselineTest(unittest.TestCase):
    def test_only_current_published_release_is_a_valid_baseline(self):
        controller = _controller()
        self.assertEqual(
            (
                controller.BASE_REVISION,
                controller.BASE_DEPLOYMENT_REVISION,
                controller.BASE_BUILD_ID,
            ),
            ('79', '77', 'quiz-2026.10.21-feedback-0c536221'),
        )
        self.assertEqual(
            controller.BASE_OCI_INDEX_DIGEST,
            'sha256:8c48ef8954fec882f19687eeffddf08e19a72eefca19938a063b89692a79e1c3',
        )
        self.assertEqual(
            controller.BASE_OCI_MANIFEST_DIGEST,
            'sha256:c05faf625e4ebd1f4734555072bf724b3bccd73e24f2025fd623e114808999d7',
        )
        self.assertEqual(
            controller.BASE_DOCKER_CONFIG_DIGEST,
            'sha256:09081896cbdc2f7f32ff8cd34b325a1085b99d679dd1ad06aadec0d16b528bf2',
        )
        script = controller.remote_script(
            'quiz-2026.10.21-feedback-deadbeef',
            controller.API_SHA256,
            'publish',
            reviewed_receipt_bytes=b'{"build_id":"quiz-2026.10.21-feedback-deadbeef","input_sha256":"x","image":"x@sha256:y"}',
        )
        self.assertIn('helm rollback quiz-master 79', script)
        self.assertNotIn('quiz-2026.10.20-lazy-2af0ab3f', script)
        self.assertNotIn('rollback quiz-master 78', script)
        controller.validate_build_id('quiz-2026.10.21-phone-followup-deadbeef')

    def test_frontend_controller_still_rejects_api_or_short_disk_guards(self):
        controller = _controller()
        with self.assertRaises(controller.GuardError):
            controller.validate_imagefs_blocks(
                199, 1271532, 1000, 1271337, '/dev/vda2'
            )
        with self.assertRaises(controller.GuardError):
            controller.validate_build_id('quiz-2026.10.20-lazy-deadbeef')

    def test_helm_78_preflight_cannot_replay_against_helm_79_controller(self):
        controller = _controller()
        prior = [
            {
                'hostname': controller.HOST,
                'revision': '78',
                'deployment_revision': '76',
                'pvc_uid': controller.PVC_UID,
                'containers': [
                    {'name': 'api', 'image': 'old'},
                    {'name': 'web', 'image': 'old'},
                ],
                'disk': {'free': 1},
            },
            {
                'api_sha256': controller.API_SHA256,
                'buildId': 'quiz-2026.10.20-lazy-2af0ab3f',
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
