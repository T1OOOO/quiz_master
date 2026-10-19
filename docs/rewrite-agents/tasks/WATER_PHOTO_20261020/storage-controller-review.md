### 1. Independent Storage Offload Plan Review (`WATER_PHOTO_20261020`)

- **Decision**: `ACCEPT`
- **Reviewer Provider**: `google`
- **Plan SHA-256**: `74c1ffc4e530c8d01ac59f6ac9c973738417adb943cdcade55d6a5f27b2d080f`
- **Reviewed At (UTC)**: `2026-10-19T21:42:45Z`

```json
{
  "decision": "ACCEPT",
  "reviewer_provider": "google",
  "plan_sha256": "74c1ffc4e530c8d01ac59f6ac9c973738417adb943cdcade55d6a5f27b2d080f",
  "reviewed_at_utc": "2026-10-19T21:42:45Z"
}
```

#### Storage Plan & Helper Findings
- **Scope & Byte Accounting ([storage-offload-plan.json](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/WATER_PHOTO_20261020/storage-offload-plan.json#L1-L67))**:
  - Pins live production baseline `73` (`build_id: "quiz-2026.10.19-photo-a034673a"`, `deployment_revision: "71"`, `helm_deployed_revision: 73`, `rollback_revision: 72`, image `sha256:710eaf4fdd68dead9dfc2bc4d38b72bd329c0dadd9e69640e56ab922100fdbfa`, PVC UID `7fc2428f-4146-4c78-a26d-2347d9f3b7bf`) and `candidate_receipt` (`input_sha256: "1053f1700d1c6bea8fbe2a37fe42cc3ad1dd004835f8075f58c9eb1e9358c71f"`).
  - Targets only 7 redundant stage/restore-proof items strictly inside `/opt/quiz-master/releases/quiz-2026.10.19-photo-a034673a/` (`api`, `web`, `private`, `quizzes`, `restore-proof.sqlite`, `publish-restore-proof.sqlite`, `web-delta`).
  - Individual `expected_bytes` sum to `287,253,881` bytes (~273.95 MiB / 287.25 MB), matching `planned_total_bytes`.
  - Preserves all runtime Docker/K3s images, live PVC data, all server backups under `/opt/quiz-master/backups/`, stage `chart`/`support`/receipts/metadata, and the hash-verified local package `.run/photo_catalog_20261019/package-a034673a`.
- **Helper Verification ([storage_offload.py](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/WATER_PHOTO_20261020/storage_offload.py#L1-L260))**:
  - [`read_plan`](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/WATER_PHOTO_20261020/storage_offload.py#L25-L35) enforces `PLAN_SHA256`, exact target count `7`, and path confinement to `/opt/quiz-master/releases/quiz-2026.10.19-photo-a034673a/`.
  - [`state`](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/WATER_PHOTO_20261020/storage_offload.py#L99-L121) verifies `prepared-receipt.json` against `CANDIDATE`, live Helm 73 / Deployment 71 / rollback 72, node readiness (`Ready=True`, `DiskPressure=False`), public endpoints, and SQLite `PRAGMA integrity_check` on all three server backups (`minimum20-7f8344d6.sqlite`, `grid-9de2ad04.sqlite`, `photo-a034673a.sqlite`).
  - Stages into ACL-restricted `.run/private/storage-offload-water-baseline-20261020` with `fsync`, `safe_extract`, full remote/local SHA-256 and SQLite `PRAGMA integrity_check`, active container/pod/process guards, and `DEPLOY.lock`-protected manifest re-verification prior to deletion.

---

### 2. Independent Release Controller & Package Preparation Review (`WATER_PHOTO_20261020`)

- **Decision**: `ACCEPT` (Planning / Controller Gate)
- **Reviewed Files**: [release_executor.py](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/WATER_PHOTO_20261020/release_executor.py#L1-L646), [prepare_package.py](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/WATER_PHOTO_20261020/prepare_package.py#L1-L53), [test_release_executor.py](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/WATER_PHOTO_20261020/test_release_executor.py#L1-L50), [release-tests.log](file:///E:/Projects/quiz_master/.run/waterways_20261020/release-tests.log#L1-L6)

#### Controller & Package Findings
1. **Baseline & Build Contract ([release_executor.py](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/WATER_PHOTO_20261020/release_executor.py#L20-L55), [prepare_package.py](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/WATER_PHOTO_20261020/prepare_package.py#L6-L51))**:
   - Correctly updates baseline pins to `BASE_REVISION = "73"`, `BASE_DEPLOYMENT_REVISION = "71"`, `BASE_BUILD_ID = "quiz-2026.10.19-photo-a034673a"`, `BASE_IMAGE = "quiz-master:quiz-2026.10.19-photo-a034673a@sha256:710eaf4fdd68dead9dfc2bc4d38b72bd329c0dadd9e69640e56ab922100fdbfa"`, and unchanged `API_SHA256 = "e2884077520a274a753cab0eff58c663aed159fd723c24e2b8f1e234c75539e4"`.
   - [`prepare_package.py`](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/WATER_PHOTO_20261020/prepare_package.py#L16-L34) enforces a clean git worktree, zero diff against `API_SOURCE` (`7f8344d638e2079d3b47b74972754a3425419791`) across `quizzes`, `next/server`, and `next/content`, baseline package verification against `baseline-inputs`, and build prefix `quiz-2026.10.20-water-<commit8>` embedded in compiled `main.dart.js`.
2. **Bounded Web Delta & Content Invariants ([release_executor.py](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/WATER_PHOTO_20261020/release_executor.py#L163-L230))**:
   - [`validate_web_delta`](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/WATER_PHOTO_20261020/release_executor.py#L172-L181) restricts added web paths strictly to `NEW_WEB_PATHS = {'assets/assets/quizipedia/landmark_thumbnails.json', 'assets/assets/quizipedia/waterways.json'}`, forbids path deletions, and requires `web-delta` to match the exact set of changed/added files.
   - [`collect_inputs`](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/WATER_PHOTO_20261020/release_executor.py#L206-L229) enforces `packs=105`, `questions=4520`, `quizipedia_facts=13678`, `question_articles=305`, `question_article_references=241`, `frontend_only=True`, 195 content-addressed flag PNGs, 165 unchanged quiz files (`expected_mutated=[]`), and the 4 reviewed private drafts.
3. **Remote Prepare & Publish Gates ([release_executor.py](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/WATER_PHOTO_20261020/release_executor.py#L275-L534))**:
   - Preserves all mandatory gates: `/opt/quiz-master/DEPLOY.lock`, `f_bavail * 5 >= s.f_blocks` (>=20% containerd imagefs), full resulting image web closure check (`image-web-sha256.txt`), API and 165-quiz byte closure, SQLite backup + `restore-proof.sqlite` + `publish-restore-proof.sqlite` `PRAGMA integrity_check`, disposable container HTTP grading rehearsal (`--require-real-http-grading --require-article-revision-binding`), Helm image/buildId-only manifest diff, `helm lint --strict`, `kubectl apply --dry-run=server`, independent `reviewed-receipt.json` gate, automatic `helm rollback quiz-master 73` on failure, and `feedback_reports` row hash preservation.
   - Unit test suite ([test_release_executor.py](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/WATER_PHOTO_20261020/test_release_executor.py#L1-L50)) covers all adapted invariants and passes (`10/10 OK` in [release-tests.log](file:///E:/Projects/quiz_master/.run/waterways_20261020/release-tests.log#L1-L6)).
