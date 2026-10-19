### Independent Storage Offload Plan Review (`VISUAL_FEEDBACK_20261019`)

- **Decision**: `ACCEPT`
- **Reviewer Provider**: `google`
- **Plan SHA-256**: `395df86a4610e2b06064e049c1520f7e4a3902d91676a94b2e10af6ee792686c`
- **Reviewed At (UTC)**: `2026-10-19T19:34:30Z`

```json
{
  "decision": "ACCEPT",
  "reviewer_provider": "google",
  "plan_sha256": "395df86a4610e2b06064e049c1520f7e4a3902d91676a94b2e10af6ee792686c",
  "reviewed_at_utc": "2026-10-19T19:34:30Z"
}
```

---

### Verification Summary

1. **Scope & Byte Accounting ([storage-offload-plan.json](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/VISUAL_FEEDBACK_20261019/storage-offload-plan.json#L1-L110))**:
   - All 15 literal targets reside strictly under `/opt/quiz-master/releases/quiz-2026.10.19-minimum20-7f8344d6/` (3 API binaries, 7 staged web/private/quiz directories, 3 restore-proof SQLite files, and 2 rehearsal-data directories).
   - Individual target `expected_bytes` sum to exactly `486,658,360` bytes (~464.1 MiB / 486.7 MB), which exceeds the ~158.9 MB deficit (`20,324,556,800` free vs `20,483,434,906` required for 20% of `102,417,174,528` bytes) and restores free space above 20% (`~20.32%`) without altering any threshold guard.
   - Zero overlap with live PVC storage, Docker/K3s images, `/opt/quiz-master/backups/`, candidate 71 (`quiz-2026.10.19-visual-3b604773`) stage/restore artifacts, or release 70 receipts, charts, manifests, and evidence files.
   - No local deletions or broad workspace/image prune actions are included.

2. **Helper Guards & Diff vs Prior Helper ([storage_offload.py](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/VISUAL_FEEDBACK_20261019/storage_offload.py#L1-L256) vs [storage_offload_extra.py](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/FEEDBACK43_MINIMUM20_20261019/storage_offload_extra.py#L1-L256))**:
   - **Root & Count Enforcement**: [`read_plan`](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/VISUAL_FEEDBACK_20261019/storage_offload.py#L25-L35) pins `PLAN_SHA256`, contract `quiz-master-storage-offload-visual/v1`, exact target count `15`, and narrows the allowed path prefix to `/opt/quiz-master/releases/quiz-2026.10.19-minimum20-7f8344d6/` with no `..` traversal.
   - **Production & Backup State Guards**: [`state`](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/VISUAL_FEEDBACK_20261019/storage_offload.py#L97-L117) verifies host `racknerd-f0269d5`, historical release receipts, Kubernetes deployment revision `68`, build `quiz-2026.10.19-minimum20-7f8344d6`, container image digest `sha256:09cc9e1df1e5d430952d1b25e57de10824877d89f1eeaac7b2cd0626e292bdee`, PVC UID `7fc2428f-4146-4c78-a26d-2347d9f3b7bf`, Helm revision `70` (`deployed`) and rollback revision `69` retention, node readiness (`Ready=True`, `DiskPressure=False`), live public endpoints, and `PRAGMA integrity_check` on both `/opt/quiz-master/backups/quiz-2026.10.19-minimum20-7f8344d6.sqlite` and `/opt/quiz-master/backups/quiz-2026.10.19-visual-3b604773.sqlite`.
   - **Active Reference Guard**: [`active_refs`](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/VISUAL_FEEDBACK_20261019/storage_offload.py#L118-L142) inspects running Docker containers (`docker ps -q`), running CRI containers (`k3s crictl ps -o json`), all Kubernetes pods (`kubectl get pods -A -o json`), and live `/proc` `cmdline`, `cwd`, and `fd` entries. Scoping container inspection to running containers avoids false positives from stopped rehearsal container metadata while preserving runtime safety (with the documented requirement to restore the archive before manually restarting any old rehearsal container).
   - **Reversible Staging & Atomic Apply**: [`stage`](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/VISUAL_FEEDBACK_20261019/storage_offload.py#L217-L237) writes into ACL-restricted `.run/private/storage-offload-visual-20261019`, `fsync`s the archive and snapshot manifest, safely extracts (`filter='data'`), and runs [`local_verify`](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/VISUAL_FEEDBACK_20261019/storage_offload.py#L182-L210) (full SHA-256, byte counts, and header-detected SQLite `PRAGMA integrity_check`). [`apply`](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/VISUAL_FEEDBACK_20261019/storage_offload.py#L238-L245) re-verifies the local archive and extracted tree, acquires `/opt/quiz-master/DEPLOY.lock`, confirms remote target hashes match the staged manifest (`actual == E`), deletes only the 15 literal targets, and re-verifies `state()`.
