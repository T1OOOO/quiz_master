# Independent prepared-image review

Actual AGY conversation: f5030491-3bd1-470f-9496-596b4f0ef4b4

**ACCEPT**

### Independent Final Prepared-Image Release 85 Gate Audit (`d0dff40a`)

1. **Immutable Source & Build Closure (`source-d0dff40a-build-receipt.json`)**
   - **Source & Tree:** Commit `d0dff40a35232c78e19fdd659fdc03a95521685e`, frozen app tree `4f96cd4218a83051163f7194be8256d9b611b3a1`, build ID `quiz-2026.10.21-feedback-d0dff40a`, `published: false`. Unrelated root 86/87 work is excluded from the immutable package.
   - **Verification Gates:** 406/406 Flutter tests pass at concurrency 2 (`faff5e13...`, with the single default-pool flake reproduced as passing in isolation and full concurrency-2 rerun without weakening tests), `flutter analyze` passes (`5e543083...`), web build exits `0` (`afa6d65a...`), and 23 Python guards pass.
   - **Frontend Artifact Pin:** Compiled `main.dart.js` SHA-256 `3636c3c56a167e5ef8065440db2665c7c7f3452f3bc334d8084607acd82ff7e8`.

2. **Image, Content & API Closure (`prepared-image-proof-d0dff40a.json`)**
   - **Image Identity:** OCI index / Docker digest `sha256:093122f18d8b1aee16f41011e3abec8c25ea1dc83a3b904054cf413a47658282`, amd64 manifest `sha256:52c135f3...`, config/CRI ID `sha256:62984511...`, `oci_content_hashes_verified: true`, `input_sha256: 44ae28a10eac1c2be311461d8b2f32d8e59bf2bc9f6dc9a8e338848d12b42608` (matches `prepared_receipt` and `prepared_receipt_raw_base64`).
   - **Web, API & Content Conservation:** All 826 web files match (`image_web_all_bytes_match: true`, manifest SHA-256 `23af933e...`), API binary SHA-256 `e2884077...`, all 165 quiz source files unchanged (`approved_existing_mutations: 0`).

3. **Backup, Restore, Rehearsal & Cluster Health**
   - **Backup & Restore:** `/opt/quiz-master/backups/quiz-2026.10.21-feedback-d0dff40a-prepare.sqlite` (`91,348,992` bytes, mode `0o600`, `integrity: "ok"`, SHA-256 `90ef3a931e8c9ed3cb5239ab89a97bbfe3b3913a08323a9d2ce9d3c0c1f0e52b`) matches `restored_sha256` exactly.
   - **Copied-DB Rehearsal HTTP:** `integrity: "ok"`, `visible_banks: 105`, `visible_slots: 4520`, `private_pooled_banks: 23`, `archival_fallback_quizzes: 11`, `aliases: 56`, `article_refs: 241`, `eligible_started: 57`, `new_questions_graded: 38`, `short_bands_rejected: 363`.
   - **Feedback Conservation:** `all_original_feedback_rows_unchanged: true`, `feedback_original_rows: 130` (96 resolved / 34 open snapshot preserved).
   - **Infrastructure & Live Baseline:** Live remains on Helm revision `84` / Deployment revision `82` (`new_release_published: false`, `chart_rendered_baseline_matches_live: true`), PVC UID `7fc2428f-4146-4c78-a26d-2347d9f3b7bf`, reserved block count `1271337`, free disk `20.50%` (`20,996,382,720` bytes ≥ 20% gate), tmpfs unmounted (`268,435,456` bytes released), node `Ready: True` with no pressure conditions.

4. **Pre-Publication Phone Viewport QA (`393x851`, DPR `2.75`, touch `5`)**
   - Pinned candidate `main.dart.js` (`3636c3c5...`) was served once via bounded local CDP Fetch override in an isolated QA browser against live guest API with all other 826 assets unchanged and no production mutation.
   - Verified raw touch tap on **Close** (question `19/76`) dismisses the feedback dialog while remaining on `19/76` with the saved answer and explanation visible, and raw touch tap on **Continue** (question `20/76`) advances to `firstPending` (`1/76`).
   - Pre-publication QA is properly distinguished from post-promotion verification; mandatory live phone check on published release 85 remains required immediately after promotion.
