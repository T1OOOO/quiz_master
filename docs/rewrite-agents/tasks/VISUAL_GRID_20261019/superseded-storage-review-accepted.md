### Independent Storage Offload Plan Review (`VISUAL_GRID_20261019` — Superseded Candidate `grid-8681ac36`)

- **Decision**: `ACCEPT`
- **Reviewer Provider**: `google`
- **Plan SHA-256**: `3071ac4d9b44342431a7236397cdabe33d740e33305fd62ae62617ee8ead23c3`
- **Reviewed At (UTC)**: `2026-10-19T20:05:00Z`

```json
{
  "decision": "ACCEPT",
  "reviewer_provider": "google",
  "plan_sha256": "3071ac4d9b44342431a7236397cdabe33d740e33305fd62ae62617ee8ead23c3",
  "reviewed_at_utc": "2026-10-19T20:05:00Z"
}
```

---

### Verification of Plan & Helper Differences

1. **Scope & Byte Accounting ([storage-offload-superseded-plan.json](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/VISUAL_GRID_20261019/storage-offload-superseded-plan.json#L1-L86))**:
   - Retains the live production baseline (`build_id: "quiz-2026.10.19-visual-3b604773"`, `deployment_revision: "69"`, `helm_deployed_revision: 71`, `rollback_revision: 70`, image `sha256:90431ef229e5f86f2c3b8a4c368f473c1172d91150c3c02f50c1b10f4c599591`, PVC UID `7fc2428f-4146-4c78-a26d-2347d9f3b7bf`).
   - Targets exactly 11 items belonging exclusively to the superseded, never-published candidate `quiz-2026.10.19-grid-8681ac36`: 10 stage inputs/restore-proof/rehearsal targets under `/opt/quiz-master/releases/quiz-2026.10.19-grid-8681ac36/` plus its single unused pre-prepare backup `/opt/quiz-master/backups/quiz-2026.10.19-grid-8681ac36.sqlite`.
   - Individual `expected_bytes` sum to `402,649,926` bytes (~384.0 MiB / 402.65 MB), matching `planned_total_bytes`.
   - Preserves `prepared-receipt.json` and stage metadata under `/opt/quiz-master/releases/quiz-2026.10.19-grid-8681ac36/`, all published rollback backups (`quiz-2026.10.19-minimum20-7f8344d6.sqlite` and `quiz-2026.10.19-visual-3b604773.sqlite`), live PVC data, and all Docker/K3s images.

2. **Helper Diff ([storage_offload_superseded.py](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/VISUAL_GRID_20261019/storage_offload_superseded.py#L1-L259))**:
   - [`read_plan`](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/VISUAL_GRID_20261019/storage_offload_superseded.py#L25-L35) pins `PLAN_SHA256 = '3071ac4d9b44342431a7236397cdabe33d740e33305fd62ae62617ee8ead23c3'`, contract `quiz-master-storage-offload-superseded/v1`, exact target count `11`, and restricts paths strictly to `/opt/quiz-master/releases/quiz-2026.10.19-grid-8681ac36/` or the exact literal `/opt/quiz-master/backups/quiz-2026.10.19-grid-8681ac36.sqlite`.
   - [`state`](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/VISUAL_GRID_20261019/storage_offload_superseded.py#L97-L119) adds an explicit guard proving `quiz-2026.10.19-grid-8681ac36` has `prepared-receipt.json` pinned to `quiz-master:quiz-2026.10.19-grid-8681ac36@sha256:a8e87cce91a9bf9fe961b85ceda47fff6e69feb848f03ef0b4af5c5aa567e101` and that `reviewed-receipt.json` does **not** exist (confirming it was never approved/published), while verifying `PRAGMA integrity_check` on both published rollback backups (`minimum20-7f8344d6.sqlite` and `visual-3b604773.sqlite`) before and after apply.
   - Retains identical ACL-restricted local staging (`.run/private/storage-offload-superseded-20261019`), `fsync`, `safe_extract`, remote and local SHA-256 + SQLite `PRAGMA integrity_check` (including on the offloaded `grid-8681ac36.sqlite` backup), active container/pod/process guards, and `DEPLOY.lock`-protected verification prior to unlinking.
