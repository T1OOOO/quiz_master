I will inspect the proposed storage offload script, plan, and inventory documents using `view_file` to conduct the read-only operational review.
### Independent Operational Review — Reversible Storage Offload Proposal

- **Decision**: **ACCEPT**
- **Reviewed Plan SHA-256**: `029af3bcc56ffca635363cc347a2874f0daf8af40ff99e08ca7ea4e10d4d7dde`
- **Reviewer Provider**: `google` (Antigravity / Gemini, distinct from `author_provider: "openai"`)
- **Scope**: Proposal review only (read-only verification of [`storage_offload.py`](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/FEEDBACK43_MINIMUM20_20261019/storage_offload.py), [`storage-offload-plan.json`](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/FEEDBACK43_MINIMUM20_20261019/storage-offload-plan.json), [`storage-offload-plan.md`](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/FEEDBACK43_MINIMUM20_20261019/storage-offload-plan.md), [`storage-inventory.json`](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/FEEDBACK43_MINIMUM20_20261019/storage-inventory.json), and [`storage-inventory.md`](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/FEEDBACK43_MINIMUM20_20261019/storage-inventory.md); no commands or mutations executed).

---

### Verification Findings

1. **Plan Hash & Scope Pinning ([`read_plan`](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/FEEDBACK43_MINIMUM20_20261019/storage_offload.py#L25-L35), [`storage-offload-plan.json`](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/FEEDBACK43_MINIMUM20_20261019/storage-offload-plan.json#L1-L276))**
   - [`PLAN_SHA256`](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/FEEDBACK43_MINIMUM20_20261019/storage_offload.py#L16) (`029af3bcc56ffca635363cc347a2874f0daf8af40ff99e08ca7ea4e10d4d7dde`) is checked on every invocation (`--plan`, `--stage`, `--apply`) before parsing.
   - Enforces contract `quiz-master-storage-offload/v1`, exactly 30 unique literal paths, all rooted under `/opt/quiz-master/` with no `..` traversal segments.
   - Byte accountingacross the 30 literal targets sums to **1,408,275,024 bytes**:
     - Prior stage build inputs (`feedback-5df1d538` and `books-8954b166` `web`/`api`): `200,261,576` B
     - Current stage build inputs (`bones-36e0b68c` `web`/`api`): `100,413,352` B
     - Current stage rehearsal copies (`base.api`, `new.api`, `base-quizzes`, `candidate-quizzes`, `restore-proof.sqlite`, `publish-restore-proof.sqlite`, `rehearsal-data`): `218,801,052` B
     - Older `2026.10.19-feedback-*` SQLite backups (`0c409557`, `27d53b72`, `5df1d538`): `174,440,448` B
     - Same-project Oct 15 release tarballs (`country483-3c22818.tar.gz`, `reader303-14b7da4.tar.gz`): `121,978,692` B
     - Same-project Oct 15 cutover/publish SQLite backups & restore-proofs (12 files): `592,379,904` B
   - Removing `1,408,275,024` B on `/dev/vda2` raises `imageFS` available capacity from `20,098,121,728` B (`19.624%`) to `21,506,396,752` B (**`20.999%`**), restoring headroom above the 20% release preflight guard without modifying kubelet thresholds or running any image build/publish while below 20%.

2. **Preservation of Active & Rollback Artifacts ([`state`](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/FEEDBACK43_MINIMUM20_20261019/storage_offload.py#L86-L106), [`receipt_guard`](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/FEEDBACK43_MINIMUM20_20261019/storage_offload.py#L81-L85))**
   - Zero container images, Helm releases, PVCs, receipts, charts, manifests, or live feedback data are targeted.
   - Current Helm 69 (`quiz-2026.10.19-bones-36e0b68c.sqlite`) and rollback Helm 68 (`quiz-2026.10.19-books-8954b166.sqlite`) backups in `/opt/quiz-master/backups` remain on the remote server and are explicitly checked for regular-file status and `sqlite3 ... "pragma integrity_check" == "ok"` both before and after deletion.
   - Both `prepared-receipt.json` and `reviewed-receipt.json` in `feedback-5df1d538`, `books-8954b166`, and `bones-36e0b68c` are verified intact and matching their pinned digests before and after deletion.

3. **Inactive Reference Proof, Non-Symlink & Integrity Guards ([`active_refs`](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/FEEDBACK43_MINIMUM20_20261019/storage_offload.py#L107-L119), [`snapshot`](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/FEEDBACK43_MINIMUM20_20261019/storage_offload.py#L120-L132))**
   - `active_refs` inspects all Docker containers (`docker ps -aq` / `docker inspect`), all k3s CRI containers (`k3s crictl ps -a` / `inspect`), and all Kubernetes pods (`kubectl get pods -A -o json`), failing closed if any target path appears in any string field.
   - `snapshot` verifies `p.resolve() == p`, `not p.is_symlink()`, exact kind (`file` vs `dir`), recursive `no_symlinks` (`os.walk(..., followlinks=False)`), exact `expected_bytes`, per-file SHA-256 digests, and `pragma integrity_check` (`ok`) on all 17 `.sqlite` targets.

4. **Locking, Durable Local Staging & Fail-Closed Apply ([`stage`](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/FEEDBACK43_MINIMUM20_20261019/storage_offload.py#L178-L188), [`apply`](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/FEEDBACK43_MINIMUM20_20261019/storage_offload.py#L189-L196))**
   - Both `--stage` and `--apply` acquire an exclusive non-blocking lock (`fcntl.LOCK_EX | fcntl.LOCK_NB`) on `/opt/quiz-master/DEPLOY.lock` and verify full baseline health (hostname `racknerd-f0269d5`, Deployment rev `67`, build `quiz-2026.10.19-bones-36e0b68c`, image `@sha256:54a3455a7efac04ab6ee6f9ffb5a053d3ce2ca431ee938557d4ab2aed928d54a`, PVC UID `7fc2428f-4146-4c78-a26d-2347d9f3b7bf`, Helm 69 deployed / 68 retained, single node Ready without DiskPressure, public `/version.json` and `/health/ready`).
   - `--stage` creates `.run/private/storage-offload-20261019` (`exist_ok=False`), restricts Windows ACLs via `icacls ... /inheritance:r /grant:r <USERNAME>:(OI)(CI)F`, downloads `remote-targets.tar.gz`, safely extracts (`filter='data'`, rejecting absolute/`..` members), and runs [`local_verify`](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/FEEDBACK43_MINIMUM20_20261019/storage_offload.py#L160-L171) (checking every file's SHA-256 and local SQLite `pragma integrity_check`) before writing `snapshot.json`.
   - `--apply` re-verifies the review receipt, `snapshot.json`, local archive SHA-256, and extracted tree hashes + SQLite integrity before connecting remotely; under `DEPLOY.lock`, it recomputes `actual = snapshot()`, enforces `actual == E` (fail-closed on any remote drift since staging), unlinks only the 30 literal targets, and re-runs `state()` before releasing `DEPLOY.lock`.
   - [`receipt`](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/FEEDBACK43_MINIMUM20_20261019/storage_offload.py#L36-L42) enforces a regular JSON file with `decision == "ACCEPT"`, `reviewer_provider != "openai"`, `plan_sha256 == PLAN_SHA256`, and `reviewed_at_utc`.
