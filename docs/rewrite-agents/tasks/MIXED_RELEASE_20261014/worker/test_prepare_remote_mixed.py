"""Pure guards for the new remote prepare helper; no SSH is invoked."""
import copy
import unittest
import prepare_remote_mixed as r


class RemoteBoundaries(unittest.TestCase):
    def package(self):
        return {'build_id': 'quiz-2026.10.14-mixed-ecac092', 'archive_sha256': 'a' * 64}

    def test_prepare_shell_has_exact_baseline_and_prepare_only_guards(self):
        guard, script = r.remote_scripts(self.package())
        for expected in ('racknerd-f0269d5', r.BASELINE_IMAGE, r.PVC_UID, 'status=="deployed"', 'version==52', 'flock -n 8', 'sha256sum -c checksums.txt', 'bash cutover.sh prepare'):
            self.assertIn(expected, guard + script)
        for forbidden in ('helm upgrade', 'helm rollback', 'kubectl apply -n', 'rm -rf'):
            self.assertNotIn(forbidden, script)
        self.assertIn('flock -u 8', script)
        self.assertIn('runtime-public-baseline.json', script)

    def test_untrusted_build_or_archive_hash_cannot_reach_shell(self):
        for key, value in (('build_id', '../../escape'), ('build_id', 'quiz-2026.10.14-mixed-ecac092;echo bad'), ('archive_sha256', 'bad')):
            package = self.package()
            package[key] = value
            with self.assertRaisesRegex(RuntimeError, 'identity'):
                r.remote_scripts(package)

    def test_collector_checks_real_runtime_rehearsal_and_rejects_other_run(self):
        build = self.package()['build_id']
        body = r.collection_script(build, build + '-cutover-20261014T140000Z', 'sha256:' + 'b' * 64, 'c' * 64)
        python = body.split("python3 - <<'PY'\n", 1)[1].rsplit('\nPY\n', 1)[0]
        compile(python, 'generated-read-only-evidence-collector', 'exec')
        for expected in ('verify_runtime_receipt', '==(14,280,55,335,15)', 'practice==(15,335)', 'baseline_helm_revision', 'values_sha256'):
            self.assertIn(expected, body)
        with self.assertRaisesRegex(RuntimeError, 'execution identity'):
            r.collection_script(build, 'other-cutover-20261014T140000Z', 'sha256:' + 'b' * 64, 'c' * 64)

    def test_helper_review_requires_actual_callback_and_exact_hashes(self):
        hashes = {'prepare_remote_mixed.py': '1' * 64, 'test_prepare_remote_mixed.py': '2' * 64}
        review = {'schema_version': 'qm-mixed-remote-helper-review/v1', 'actual_cli_exit': 0, 'actual_hub_state': 'ACCEPTED', 'author_provider': 'openai', 'reviewer_provider': 'claude', 'reviewed_worker_sha256': hashes,
                  'actual_reviews': {'one': {'call': {'action': 'review', 'arguments': {'task_id': 't', 'verdict': 'accept'}}, 'actual_response': {'id': 't', 'state': 'ACCEPTED', 'reviewer': 'b', 'assignee': 'a'}}}}
        r.verify_helper_review(review, hashes)
        for field, value in (('reviewed_worker_sha256', {}), ('reviewer_provider', 'openai'), ('actual_reviews', {})):
            wrong = copy.deepcopy(review)
            wrong[field] = value
            with self.assertRaisesRegex(RuntimeError, 'helper review'):
                r.verify_helper_review(wrong, hashes)


if __name__ == '__main__':
    unittest.main()
