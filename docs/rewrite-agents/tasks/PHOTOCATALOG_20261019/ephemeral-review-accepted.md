### Independent Storage Offload Plan Review (`PHOTOCATALOG_20261019` — Ephemeral Candidate `photo-a034673a` Aux Outputs)

- **Decision**: `ACCEPT`
- **Reviewer Provider**: `google`
- **Plan SHA-256**: `611ac826b85b5a99d7fde4f2b976d51d1bf2cf97fa96acc59ed78d034ed63eb1`
- **Reviewed At (UTC)**: `2026-10-19T21:05:15Z`

```json
{
  "decision": "ACCEPT",
  "reviewer_provider": "google",
  "plan_sha256": "611ac826b85b5a99d7fde4f2b976d51d1bf2cf97fa96acc59ed78d034ed63eb1",
  "reviewed_at_utc": "2026-10-19T21:05:15Z"
}
```

---

### Verification of Bounded Plan & Helper Changes

1. **Scope & Byte Accounting ([storage-offload-ephemeral-plan.json](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/PHOTOCATALOG_20261019/storage-offload-ephemeral-plan.json#L1-L55))**:
   - Retains the live production baseline (`build_id: "quiz-2026.10.19-grid-9de2ad04"`, `deployment_revision: "70"`, `helm_deployed_revision: 72`, `rollback_revision: 71`, image `sha256:0b46d13b5496a7d2388b3385476d4306b97709f843182407e5483b5996e643c8`, PVC UID `7fc2428f-4146-4c78-a26d-2347d9f3b7bf`) and binds `candidate_receipt` (`build_id: "quiz-2026.10.19-photo-a034673a"`, `image: "quiz-master:quiz-2026.10.19-photo-a034673a@sha256:710eaf4fdd68dead9dfc2bc4d38b72bd329c0dadd9e69640e56ab922100fdbfa"`, `input_sha256: "1053f1700d1c6bea8fbe2a37fe42cc3ad1dd004835f8075f58c9eb1e9358c71f"`).
   - Targets only the 5 stopped rehearsal/comparison auxiliary copies under `/opt/quiz-master/releases/quiz-2026.10.19-photo-a034673a/` (`base.api`, `new.api`, `base-quizzes`, `candidate-quizzes`, `rehearsal-data`).
   - Individual `expected_bytes` sum to `136,402,336` bytes (~130.1 MiB / 136.4 MB), matching `planned_total_bytes` and reserving headroom for the ~75 MB publication restore-proof copy while keeping free space comfortably above the 20% gate.
   - Untouched: frozen candidate release inputs (`api`, `web`, `quizzes`, `private`, `chart`, `support`, `prepared-receipt.json`, `restore-proof.sqlite`), candidate and published server backups under `/opt/quiz-master/backups/`, live PVC storage, and all Docker/K3s images.

2. **Helper Diff ([storage_offload_ephemeral.py](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/PHOTOCATALOG_20261019/storage_offload_ephemeral.py#L1-L260) vs [storage_offload.py](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/PHOTOCATALOG_20261019/storage_offload.py#L1-L256))**:
   - [`read_plan`](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/PHOTOCATALOG_20261019/storage_offload_ephemeral.py#L25-L35) pins `PLAN_SHA256 = '611ac826b85b5a99d7fde4f2b976d51d1bf2cf97fa96acc59ed78d034ed63eb1'`, exact target count `5`, and restricts target paths strictly to `/opt/quiz-master/releases/quiz-2026.10.19-photo-a034673a/`.
   - [`state`](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/PHOTOCATALOG_20261019/storage_offload_ephemeral.py#L99-L121) verifies that `/opt/quiz-master/releases/quiz-2026.10.19-photo-a034673a/prepared-receipt.json` is a regular file matching all 3 bound `candidate_receipt` fields (`build_id`, `image`, `input_sha256`), alongside all existing live 72/70/71 baseline checks, backup SQLite `PRAGMA integrity_check` guards, and corrected informational return labels.
   - Retains identical ACL-restricted local staging (`.run/private/storage-offload-photo-ephemeral-20261020`), `fsync`, `safe_extract`, remote and local SHA-256 + SQLite `PRAGMA integrity_check` verification, active container/pod/process reference guards, and `DEPLOY.lock`-protected manifest re-verification before unlinking.
