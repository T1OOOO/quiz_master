### 1. Storage Offload Plan Review ([storage-offload-failed-plan.json](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/WATER_PHOTO_20261020/storage-offload-failed-plan.json#L1-L67), [storage_offload_failed.py](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/WATER_PHOTO_20261020/storage_offload_failed.py#L1-L265))

- **Decision**: `ACCEPT`
- **Reviewer Provider**: `google`
- **Plan SHA-256**: `bfd4261bc4ee013a108c8859eae0969bed4665cd0b0eb0f3b405cb58546f4ccc`
- **Reviewed At (UTC)**: `2026-10-19T21:58:15Z`

```json
{
  "decision": "ACCEPT",
  "reviewer_provider": "google",
  "plan_sha256": "bfd4261bc4ee013a108c8859eae0969bed4665cd0b0eb0f3b405cb58546f4ccc",
  "reviewed_at_utc": "2026-10-19T21:58:15Z"
}
```

- **Findings**: Targets only the 6 stopped auxiliary/rehearsal outputs under `/opt/quiz-master/releases/quiz-2026.10.20-water-82fb9c57/` (`base.api`, `new.api`, `base-quizzes`, `candidate-quizzes`, `restore-proof.sqlite`, `rehearsal-data`), summing to `211,318,176` bytes. [`state`](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/WATER_PHOTO_20261020/storage_offload_failed.py#L101-L126) binds live 73/Deployment 71, candidate `release-inputs.json` (`7fc7c2f928366d99ad313623ca31bbbb005674502ba20f58962d25fe996b2264`), candidate Docker config ID (`sha256:cfe81210b9d3efba88bf3e90de2ddad3239375d55b284da095702a7aeccfba21`), and `PRAGMA integrity_check` on all 4 server backups (`minimum20-7f8344d6`, `grid-9de2ad04`, `photo-a034673a`, `water-82fb9c57`). Preserves frozen stage inputs (`api`, `web`, `private`, `quizzes`, `chart`, `support`), live PVC, and images, with ACL-restricted local staging (`.run/private/storage-offload-water-failed-20261020`), `fsync`, SHA-256/SQLite verification, `active_refs`, and `DEPLOY.lock` guards unchanged.

---

### 2. Streamed API Hash & `resume-prepare` Review ([release_executor.py](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/WATER_PHOTO_20261020/release_executor.py#L376-L384))

- **Decision**: `ACCEPT`
- **Findings**: Under `set -Eeuo pipefail`, streaming `docker cp "$container:/app/api" - | tar -xOf - api | sha256sum` into `base-api-sha256.txt` and `new-api-sha256.txt` verifies exact container `/app/api` bytes against `API_SHA256` (`e2884077520a274a753cab0eff58c663aed159fd723c24e2b8f1e234c75539e4`) without writing ~46 MB of duplicate API binaries to the stage directory. `resume-prepare` binds the existing Docker config digest and `release-inputs.json` SHA-256, uses fresh `resume-*` workdirs, and retains all 20% imagefs, 574-file web closure, 165-quiz closure, SQLite backup/restore, real HTTP grading rehearsal, and Helm/rollback 73 gates.

---

### 3. Fallback Font Manifest Registration Review ([prepare_package.py](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/WATER_PHOTO_20261020/prepare_package.py#L43-L49))

- **Decision**: `ACCEPT`
- **Findings**: Lines 43–49 inspect `dest/web/assets/FontManifest.json`, append `{'family':'Roboto','fonts':[{'asset':'fonts/fallback/Roboto-Regular.ttf'}]}` only if `Roboto` is absent, and copy `baseline/web/assets/FontManifest.json` verbatim when the resulting structure equals the baseline manifest. This preserves byte-identical `FontManifest.json` closure with release 73 and ensures local `Roboto` fallback registration without external font fetches or weakening any delta/closure guard. Final prepared-image receipt approval remains separate after `resume-prepare` completes.
