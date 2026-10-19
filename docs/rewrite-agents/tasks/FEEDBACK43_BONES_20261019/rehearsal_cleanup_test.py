import importlib.util
import json
import os
from pathlib import Path
import tempfile
import unittest

SPEC = importlib.util.spec_from_file_location("rehearsal_cleanup", Path(__file__).with_name("rehearsal_cleanup.py"))
cleanup = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(cleanup)


class RehearsalCleanupTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name) / "releases"
        self.root.mkdir()
        self.build = "quiz-2026.10.19-feedback-5df1d538"
        self.stage = self.root / self.build
        self.stage.mkdir()
        self.original_targets = cleanup.TARGETS
        cleanup.TARGETS = {self.build: cleanup.TARGETS[self.build]}
        self.addCleanup(setattr, cleanup, "TARGETS", self.original_targets)

    def target(self, name, kind):
        path = self.stage / name
        if kind == "file":
            path.write_bytes(b"proof")
        else:
            path.mkdir()
            (path / "nested").write_bytes(b"proof")
        return path

    def test_only_literal_targets_have_their_exact_types_and_can_be_removed(self):
        for name, kind in cleanup.DISPOSABLE_TYPES.items():
            path = self.target(name, kind)
            cleanup.assert_exact_target(path, kind, self.root)
            cleanup.remove_target(path, kind, self.root)
            self.assertFalse(path.exists())
        protected = self.stage / "web"
        protected.mkdir()
        with self.assertRaisesRegex(cleanup.GuardError, "approved disposable"):
            cleanup.remove_target(protected, "dir", self.root)

    def test_symlink_in_disposable_tree_blocks_removal(self):
        target = self.target("base-quizzes", "dir")
        link = target / "escape"
        try:
            link.symlink_to(self.stage / "web", target_is_directory=True)
        except OSError as error:
            self.skipTest(f"symlinks unavailable: {error}")
        with self.assertRaisesRegex(cleanup.GuardError, "symlink"):
            cleanup.assert_exact_target(target, "dir", self.root)

    def test_receipts_require_both_equal_pinned_values(self):
        digest = cleanup.TARGETS[self.build]
        receipt = {"build_id": self.build, "image": f"quiz-master:{self.build}@{digest}", "input_sha256": "a" * 64}
        for name in ("prepared-receipt.json", "reviewed-receipt.json"):
            (self.stage / name).write_text(json.dumps(receipt), encoding="utf-8")
        cleanup.assert_receipts(self.stage, self.build, digest)
        receipt["image"] = "quiz-master:wrong@" + digest
        (self.stage / "reviewed-receipt.json").write_text(json.dumps(receipt), encoding="utf-8")
        with self.assertRaisesRegex(cleanup.GuardError, "does not pin"):
            cleanup.assert_receipts(self.stage, self.build, digest)

    def test_active_reference_guard_does_not_report_container_environment(self):
        old_run, old_data = cleanup.run, cleanup.data
        cleanup.run = lambda *args: "docker-a\n" if args[:3] == ("docker", "ps", "-aq") else ""
        cleanup.data = lambda *args: ([{"Config": {"Env": ["SECRET=hidden"]}, "Mounts": [{"Source": str(self.stage)}]}]
                                     if args[:3] == ("docker", "inspect", "docker-a") else {"containers": []})
        self.addCleanup(setattr, cleanup, "run", old_run)
        self.addCleanup(setattr, cleanup, "data", old_data)
        with self.assertRaisesRegex(cleanup.GuardError, "active Docker or CRI"):
            cleanup.assert_no_active_stage_reference([self.stage])


if __name__ == "__main__":
    unittest.main()
