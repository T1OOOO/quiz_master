# Google independent review

Conversation e074bc61-2352-48a1-838d-0c26a856528b; official AGY CLI exit0 with final result. Source388e5c0c.

### Independent Review Decision Summary

- **A (Corrected location feedback & deterministic null-description test): ACCEPT**
- **B (Release 74 evidence closure for Beads `bg43` and `a7xp` only): ACCEPT**
- **C (Capacity-preserving Release 75 controller/packaging & Release 74 storage offload): ACCEPT**

---

### A. Corrected Location Feedback — **ACCEPT**

1. **Null-Cast Crash Fixed & Generic Fallback Absent**:
   - In [`_QuizGameState._targets`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/quizipedia.dart#L1016-L1031), `_Module.map` now copies each entry from `widget.catalog.countryRows` with `'explanation_en': row['explanation_en'] ?? ''` and `'explanation_ru': row['explanation_ru'] ?? ''`.
   - Because [`QuizipediaCatalog.fromJson`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/quizipedia.dart#L214-L221) only enforces [`_target(row)`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/quizipedia.dart#L137-L159) on `map_target_ids`, non-target rows in `countryRows` can omit `explanation_en`/`explanation_ru`. Defaulting missing keys to `''` prevents [`_localized`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/quizipedia.dart#L491-L495) from throwing a `TypeError` (`Null` cast to `String`) when [`_feedback()`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/quizipedia.dart#L1931-L1932) checks `_localized(context, correct, 'explanation').isNotEmpty`.
   - When the explanation is `''`, nothing is rendered for the description line, and the previous generic fallback string (`"Find this country on the world map."`) is absent from [`quizipedia.dart`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/quizipedia.dart).

2. **Facts Only After Grading, Empty Fields Omitted, Coherent Callers & Russian Labels**:
   - [`_countryFeedback()`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/quizipedia.dart#L1848-L1881) is invoked solely inside [`_feedback()`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/quizipedia.dart#L1933), which is gated by `if (_submitted) _feedback()` ([lines 1305, 1369](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/quizipedia.dart#L1305)). No capital or neighbour facts leak before grading (`_submit`).
   - Empty `fact.capital` and empty resolved `neighbors` are omitted (`if (fact.capital.isNotEmpty)` and `if (neighbors.isNotEmpty)`).
   - Russian localization uses `Столица: ${russianCountryLabel(fact.capital)}` and `Соседи по суше: ${neighbors.join(', ')}` (with `f.nameRu` sorted), matching [`country_learning.dart`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/country_learning.dart#L745-L756).
   - [`quizipediaLocationTraining`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/quizipedia.dart#L986-L996) accepts `List<CountryFact> countryFacts = const []` and is wired coherently from [`_QuizipediaPageState.build`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/quizipedia.dart#L708-L712) and [`_CountryAtlasPageState._start`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/country_learning.dart#L1000-L1009).

3. **Deterministic Test Coverage**:
   - The first widget test in [`quizipedia_test.dart`](file:///E:/Projects/quiz_master/next/apps/quiz_app/test/quizipedia_test.dart#L13-L59) removes `'explanation_en'` and `'explanation_ru'` directly from `catalog.countryRows` (the copied map instances used by `_QuizGameState`), verifies `Capital: Paris` is absent before grading, submits `Spot 1` via `Check`, and verifies `Capital: Paris` is shown while `'Explanation '` and `'Find this country on the world map.'` are absent.
   - *Note*: Complete the pending fresh 311-test suite run as standard gate hygiene.

---

### B. Release 74 Evidence Closure (`bg43` and `a7xp` Only) — **ACCEPT**

1. **Deployment & Runtime State Verified**:
   - Per [`PUBLISHED.md`](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/WATER_PHOTO_20261020/PUBLISHED.md#L1-L16) and [`postpublish-state.json`](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/WATER_PHOTO_20261020/postpublish-state.json#L1-L53): build `quiz-2026.10.20-water-82fb9c57` (commit `82fb9c5700f9caea58dab8ed1b50b96b5ad9d1b0`) is live in exact namespace `quiz-master` at Helm revision `74` and Deployment revision `72`.
   - The single pod runs **two containers** (`api` and `web`) on image `docker.io/library/quiz-master@sha256:cfe81210b9d3efba88bf3e90de2ddad3239375d55b284da095702a7aeccfba21`, both `ready: true` with `restartCount: 0`, `pvc_unchanged: true`, integrity checks `"backup": "ok"` and `"publish_restore": "ok"`, node `Ready: "True"` and `DiskPressure: "False"`, and `imagefs_available_percent: 20.082995679964558` (`capacity_meets_20_percent: true`).
   - [`public-bytes-evidence.json`](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/WATER_PHOTO_20261020/public-bytes-evidence.json#L1-L43) confirms HTTP `200` and exact byte/SHA-256 matches for `version.json` (`940` B), `main.dart.js` (`4527696` B, `dff8835258eefbb81c5dd488329eba298756bd708e674d4180ee0415fe562e75`), `catalog.json` (`546354` B), `waterways.json` (`473400` B), `landmark_thumbnails.json` (`151158` B), `FontManifest.json` (`226` B), `Roboto-Regular.ttf` (`171676` B), `health/ready`, and `health/live`.

2. **Feature & Verification Scope (`bg43` and `a7xp`)**:
   - **Water bodies (`bg43`)**: 63 Natural Earth water features (24 lakes, 12 rivers, 27 seas/oceanic areas), preserving contours/parts/holes, camera preservation on selection, separate zoom trigger, search/list, and 6-choice training with check and manual step (`2/63`).
   - **Photo catalog (`a7xp`)**: 36 photographs across 25 countries and 108 educational facts, corrected Russian label `Сингапур`, single-request preview bundle (`151158` B uncompressed, `114030` B transferred), 6-choice photo training, and expandable explanations for the other 5 options.
   - Verified in mobile Chrome emulation (`361×738`, DPR `3.5`), explicitly documented as mobile emulation and **not** a physical Android device.

3. **Closure Authorization**:
   - Implementation tasks **`bg43` and `a7xp` MAY CLOSE**.
   - Closing all 24 user feedback reports is **NOT authorized**; as recorded in [`PUBLISHED.md`](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/WATER_PHOTO_20261020/PUBLISHED.md#L13), all 24 feedback reports remain open pending follow-up fixes and verification.

---

### C. Capacity-Preserving Release 75 & Release 74 Storage Offload — **ACCEPT**

1. **Release 75 Controller & Packaging ([`release_executor.py`](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/SKY_MOBILE_20261020/release_executor.py), [`prepare_package.py`](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/SKY_MOBILE_20261020/prepare_package.py), [`test_release_executor.py`](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/SKY_MOBILE_20261020/test_release_executor.py))**:
   - **Baseline Pins**: Pinned to Helm revision `74`, Deployment revision `72`, build `quiz-2026.10.20-water-82fb9c57`, image digest `sha256:cfe81210b9d3efba88bf3e90de2ddad3239375d55b284da095702a7aeccfba21`, API SHA-256 `e2884077520a274a753cab0eff58c663aed159fd723c24e2b8f1e234c75539e4`, and PVC UID `7fc2428f-4146-4c78-a26d-2347d9f3b7bf` ([lines 24-35](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/SKY_MOBILE_20261020/release_executor.py#L24-L35)).
   - **Exact `*.json` Web Staging + Full Image Web Closure**:
     - [`collect_inputs`](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/SKY_MOBILE_20261020/release_executor.py#L212-L235) validates the full local package (`web`, `web-delta`, 195 flags, 105 catalog banks / 4520 questions / 241 article refs, 165 quiz closure, `private` tree) and records both full `"web": hash_tree(web)` and `"staged_web": staged_web_manifest(hash_tree(web))` (`*.json` subset, [lines 206-209](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/SKY_MOBILE_20261020/release_executor.py#L206-L209)).
     - [`stage_package`](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/SKY_MOBILE_20261020/release_executor.py#L563-L578) uploads only `*("web/" + name for name in inputs.manifest["staged_web"])` plus `web-delta` and metadata/support inputs.
     - Remote input verification ([lines 350-365](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/SKY_MOBILE_20261020/release_executor.py#L350-L365)) verifies `staged_web` against the unpacked `web/` tree and confirms `staged_web` is the exact `.json` subset of `expected['web']`.
     - After building the candidate image from `BASE_LOCAL_TAG` + `web-delta/`, the remote script hashes every file under `/usr/share/nginx/html` inside the image and asserts exact equality with the complete `expected['web']` manifest ([lines 392-400](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/SKY_MOBILE_20261020/release_executor.py#L392-L400)).
   - **Restored Disposable DB Reuse**:
     - During `prepare`/`resume-prepare` ([lines 432-441](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/SKY_MOBILE_20261020/release_executor.py#L432-L441)), `.backup` creates `$backup` (`/opt/quiz-master/backups/<build>.sqlite`), verifies `pragma integrity_check = ok`, copies `$stage/{restore_proof}`, verifies `pragma integrity_check = ok`, records `restore-proof-sha256.txt`, and moves (`mv`) `$stage/{restore_proof}` into `$stage/{rehearsal_data}/quiz.db` for HTTP rehearsal—avoiding a redundant third SQLite copy while keeping `$backup` untouched on the server and running a fresh `.backup` + `publish-restore-proof.sqlite` check during `publish` ([lines 508-512](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/SKY_MOBILE_20261020/release_executor.py#L508-L512)).
   - **Retained Guards & Unit Tests**: All release gates (`DEPLOY.lock`, 20% imagefs block guard, Ready/DiskPressure/taint checks, streamed API SHA-256 check, 165-file quiz closure, HTTP rehearsal with `--require-real-http-grading --require-article-revision-binding`, feedback row snapshot invariance, Helm normalize diff/lint/server dry-run, pinned receipt check, rollback to `74`) are intact and covered by the 13 tests in [`test_release_executor.py`](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/SKY_MOBILE_20261020/test_release_executor.py#L4-L65).

2. **Release 74 Storage Offload ([`storage-offload-plan.json`](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/SKY_MOBILE_20261020/storage-offload-plan.json), [`storage_offload.py`](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/SKY_MOBILE_20261020/storage_offload.py))**:
   - **Plan Pin & Target Accounting**: `PLAN_SHA256` in [`storage_offload.py`](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/SKY_MOBILE_20261020/storage_offload.py#L16) is pinned to `8219191c77db06d2c13b6d2323e3adb8036eae21f8b460cabdb008d9c45edfbd`. The 6 literal targets under `/opt/quiz-master/releases/quiz-2026.10.20-water-82fb9c57/` (`api`: `22997561` B, `web`: `93738049` B, `private`: `4285861` B, `quizzes`: `4212887` B, `publish-restore-proof.sqlite`: `74919936` B, `web-delta`: `5772048` B) sum to `205926342` B (`planned_total_bytes`).
   - **Safety Invariants**:
     - Retains live Release 74 runtime image (`sha256:cfe81210...`), live PVC (`7fc2428f-4146-4c78-a26d-2347d9f3b7bf`), Helm revisions `74` (deployed) and `73` (rollback), all 4 server-side SQLite backups in `/opt/quiz-master/backups/` (including `quiz-2026.10.20-water-82fb9c57.sqlite`, verified via `sqlite_ok` at [lines 119-120](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/SKY_MOBILE_20261020/storage_offload.py#L119-L120)), and Release 74's `chart`, support files, and receipts (`prepared-receipt.json` hash-checked against `candidate_receipt` at [lines 102-103](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/SKY_MOBILE_20261020/storage_offload.py#L102-L103)).
     - Enforces non-author review receipt (`reviewer_provider != 'openai'`, `decision == 'ACCEPT'`, matching `plan_sha256`), exclusive `DEPLOY.lock` flock, active-reference checks across Docker, containerd/CRI, Kubernetes pods, and `/proc` (`cmdline`, `cwd`, `fd`), restricted local staging permissions (`icacls` / `0700`), `safe_extract` (`filter='data'`), full local SHA-256 + byte size + SQLite `pragma integrity_check` verification, `fsync` on archive and snapshot manifest, and pre-delete manifest re-verification (`actual == E`) before unlinking.


Primary clarification: the review says "all 4 backups" when describing four explicit integrity checks. Nine published backups exist and are retained; no backup path is an offload target. Final fresh suite:311 PASS.
