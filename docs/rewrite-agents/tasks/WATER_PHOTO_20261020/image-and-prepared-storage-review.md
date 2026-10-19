### 1. Prepared Candidate Image & Receipt Review (`WATER_PHOTO_20261020`)

- **Decision**: `ACCEPT` (Prepared Image Artifact Gate; publication remains gated on post-offload capacity & preflight proof)
- **Reviewer Provider**: `google`
- **Reviewed At (UTC)**: `2026-10-19T22:06:00Z`

```json
{
  "build_id": "quiz-2026.10.20-water-82fb9c57",
  "image": "quiz-master:quiz-2026.10.20-water-82fb9c57@sha256:cfe81210b9d3efba88bf3e90de2ddad3239375d55b284da095702a7aeccfba21",
  "input_sha256": "7fc7c2f928366d99ad313623ca31bbbb005674502ba20f58962d25fe996b2264"
}
```

#### Findings ([prepared-image-evidence.json](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/WATER_PHOTO_20261020/prepared-image-evidence.json#L1-L45), [prepared-receipt.json](file:///E:/Projects/quiz_master/.run/waterways_20261020/prepared-receipt.json#L1), [source-review.md](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/WATER_PHOTO_20261020/source-review.md#L1-L36), [release_executor.py](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/WATER_PHOTO_20261020/release_executor.py#L480-L535))
- **OCI Descriptor & Source Binding**: Binds source commit `82fb9c5700f9caea58dab8ed1b50b96b5ad9d1b0` (`main_dart_js_sha256: dff8835258eefbb81c5dd488329eba298756bd708e674d4180ee0415fe562e75`), frozen `input_sha256` `7fc7c2f928366d99ad313623ca31bbbb005674502ba20f58962d25fe996b2264`, OCI index / Docker engine ID `sha256:cfe81210b9d3efba88bf3e90de2ddad3239375d55b284da095702a7aeccfba21`, platform manifest `sha256:0dbea4863c666bbbd803b2e3c9e826ba858ab58c5edf4a855e4eb26c4e7da8b2`, and OCI/CRI config `sha256:4e7f24baa9fa55d795ce1c49f5bd56849c7541cbeb5e0129ac2d23f79810eb4b`.
- **Closure & Rehearsal Gates**: 574-file image web closure (`all_web_bytes_match: true`), unchanged API (`e2884077520a274a753cab0eff58c663aed159fd723c24e2b8f1e234c75539e4`), 165-file quiz closure (`0` mutations), SQLite backup/restore/rehearsal `PRAGMA integrity_check` (`ok`), real HTTP grading across 105 banks / 4,520 questions, Helm image/buildId-only diff, strict lint, and server dry-run all passed with live Helm 73 / Deployment 71 untouched (`imagefs_available_percent: 20.02222%`).

---

### 2. Prepared Auxiliary Storage Offload Plan Review ([storage-offload-prepared-plan.json](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/WATER_PHOTO_20261020/storage-offload-prepared-plan.json#L1-L49), [storage_offload_prepared.py](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/WATER_PHOTO_20261020/storage_offload_prepared.py#L1-L260))

- **Decision**: `ACCEPT`
- **Reviewer Provider**: `google`
- **Plan SHA-256**: `3cc740a36b27d26c8a150872ab82aa3982d7d8bb4cae35397f18d1cd474123ca`
- **Reviewed At (UTC)**: `2026-10-19T22:06:00Z`

```json
{
  "decision": "ACCEPT",
  "reviewer_provider": "google",
  "plan_sha256": "3cc740a36b27d26c8a150872ab82aa3982d7d8bb4cae35397f18d1cd474123ca",
  "reviewed_at_utc": "2026-10-19T22:06:00Z"
}
```

#### Findings
- **Scope & Accounting**: Targets only the 4 stopped `resume-prepare` auxiliary outputs under `/opt/quiz-master/releases/quiz-2026.10.20-water-82fb9c57/` (`resume-base-quizzes`, `resume-candidate-quizzes`, `resume-restore-proof.sqlite`, `resume-rehearsal-data`), summing to `165,339,438` bytes (~157.7 MiB / 165.3 MB) to reserve headroom for the ~75 MB `publish-restore-proof.sqlite` while keeping free space >= 20%.
- **Guards**: [`state`](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/WATER_PHOTO_20261020/storage_offload_prepared.py#L99-L121) binds live 73/Deployment 71, candidate `prepared-receipt.json` matching the 3 exact fields above, and `PRAGMA integrity_check` on all 4 server backups (`minimum20-7f8344d6`, `grid-9de2ad04`, `photo-a034673a`, `water-82fb9c57`). Preserves frozen stage inputs (`api`, `web`, `private`, `quizzes`, `chart`, `support`, `prepared-receipt.json`), live PVC, and all images, using ACL-restricted local staging (`.run/private/storage-offload-water-prepared-20261020`), `fsync`, SHA-256/SQLite verification, `active_refs`, and `DEPLOY.lock`.
- **Review Limits**: Source and evidence inspection only; no commands or network operations were executed by this reviewer.
