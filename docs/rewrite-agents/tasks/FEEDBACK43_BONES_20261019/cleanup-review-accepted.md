Independent reviewer: Google Antigravity, gemini-4-argon-high

Conversation: 0331016f-b413-4df9-8b11-b392f76bc60b

Script SHA-256: 508bffbc40c79028ee6f1fc21aef4c48222ba0cb279cf4eaa0f4adce442478ec

**ACCEPT EXACTSCRIPT** ([rehearsal_cleanup.py](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/FEEDBACK43_BONES_20261019/rehearsal_cleanup.py), 13,442 bytes / 284 lines; [rehearsal_cleanup_test.py](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/FEEDBACK43_BONES_20261019/rehearsal_cleanup_test.py), 3,673 bytes / 81 lines; file SHA-256 not computed due to read-only file-tool constraint, script pins `CURRENT_API_SHA256 = 208ac3638f5d7bd3e081b2f042b0afcf222c95a4b1af5e139286e45a3e6f22aa`, `5df1d538` image `sha256:ea1d2e9049f87f777df9b5b226dba5391aff4050bfd66c28690259d04b668561`, and `8954b166` image `sha256:dd7166c8690a2009f6b6fa5ae6b8145f6328c93fd0b8e1d450cbe9de83b4ef13`).

### Verification of Guards

1. **Bounded Target Scope & Preserved Assets**
   - [`TARGETS`](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/FEEDBACK43_BONES_20261019/rehearsal_cleanup.py#L41-L44) and [`DISPOSABLE_TYPES`](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/FEEDBACK43_BONES_20261019/rehearsal_cleanup.py#L45-L53) restrict removal to the 7 literal rehearsal paths (`base.api`, `new.api`, `base-quizzes`, `candidate-quizzes`, `restore-proof.sqlite`, `publish-restore-proof.sqlite`, `rehearsal-data`) inside `/opt/quiz-master/releases/quiz-2026.10.19-feedback-5df1d538` and `/opt/quiz-master/releases/quiz-2026.10.19-books-8954b166` (14 paths total).
   - [`inventory`](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/FEEDBACK43_BONES_20261019/rehearsal_cleanup.py#L219-L242) verifies all [`PRESERVED_NAMES`](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/FEEDBACK43_BONES_20261019/rehearsal_cleanup.py#L54-L56) (`web`, `api`, `chart`, `release-inputs.json`, `prepared-receipt.json`, `reviewed-receipt.json`) exist and are non-symlinks, and checks [`assert_receipts`](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/FEEDBACK43_BONES_20261019/rehearsal_cleanup.py#L173-L188) before and after cleanup. Published images, release directories, manifests, and PVC data are untouched.

2. **Symlink & Path Escape Prevention**
   - [`assert_owned_stage`](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/FEEDBACK43_BONES_20261019/rehearsal_cleanup.py#L80-L90) enforces `path.resolve(strict=True) == release_root / path.name`, non-symlink status, and `root:root` (`0:0`) mode `0700`.
   - [`assert_exact_target`](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/FEEDBACK43_BONES_20261019/rehearsal_cleanup.py#L104-L120) and [`assert_no_symlink_tree`](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/FEEDBACK43_BONES_20261019/rehearsal_cleanup.py#L93-L101) verify parent lineage, exact file/directory mode via `lstat()`, and walk directory trees with `followlinks=False` to reject any nested symlink before both [`inventory`](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/FEEDBACK43_BONES_20261019/rehearsal_cleanup.py#L239) and [`remove_target`](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/FEEDBACK43_BONES_20261019/rehearsal_cleanup.py#L245-L252).

3. **Active Container Reference Check (`crictl` Fix)**
   - [`assert_no_active_stage_reference`](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/FEEDBACK43_BONES_20261019/rehearsal_cleanup.py#L197-L216) inspects all Docker and CRI containers without printing secrets and places `-o json` before the container ID (`data("k3s", "crictl", "inspect", "-o", "json", identifier)` at [line 203](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/FEEDBACK43_BONES_20261019/rehearsal_cleanup.py#L203)).

4. **Baseline, Backup, Node, and Lock Invariants**
   - [`state`](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/FEEDBACK43_BONES_20261019/rehearsal_cleanup.py#L133-L170) enforces host `racknerd-f0269d5`, Deployment rev `66`, Helm rev `68` deployed with `{67, 68}` retained, immutable image `dd7166...`, PVC UID `7fc2428f-4146-4c78-a26d-2347d9f3b7bf`, single ready untainted node, containerd imagefs >= 20% available, and live `/version.json` + `/health/ready`.
   - [`assert_backup`](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/FEEDBACK43_BONES_20261019/rehearsal_cleanup.py#L190-L195) runs `sqlite3 <backup> "pragma integrity_check" == "ok"` pre- and post-cleanup.
   - [`execute`](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/FEEDBACK43_BONES_20261019/rehearsal_cleanup.py#L255-L273) holds non-blocking `LOCK_EX` on `/opt/quiz-master/DEPLOY.lock`, runs a fresh inventory before deletion, and re-verifies state, receipts, and backups afterward.
