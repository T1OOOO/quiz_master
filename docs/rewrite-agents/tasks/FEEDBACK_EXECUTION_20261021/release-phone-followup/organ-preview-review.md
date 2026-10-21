# Actual independent bounded review

Conversation: 3746a5c9-e7a9-4166-bb0b-2742159eb548

### Independent Read-Only Change Review (Base `037efe20`)

---

### 1. Organ Practice Feedback (`organ_atlas.dart` + `organ_practice_feedback_test.dart`)
**Verdict: ACCEPT** *(subject to root's pending test + `dart analyze` rerun)*

* **What was verified**:
  * **Wrong/correct visual & semantic distinction**: Checked options now compute `correctOption` and `wrongSelection` explicitly, applying distinct icons (`Icons.check_circle_outline` vs `Icons.cancel_outlined`), localized status labels (`Correct`/`Верный ответ` vs `Your answer`/`Ваш ответ`), `Semantics` labels, and Material 3 container colors (`primaryContainer`/`onPrimaryContainer` vs `errorContainer`/`onErrorContainer`) via `disabledBackgroundColor` / `disabledForegroundColor` when buttons are disabled (`onPressed: null`).
  * **Explicit summary cards & manual progression**: `_answerSummary` renders `organ-feedback-your` and (when wrong) `organ-feedback-correct` immediately above `organ-next`, keeping manual `Next` above the fold and before the optional `ExpansionTile` (`organ-option-explanations`).
  * **Source-backed per-option explanations**: `_choiceExplanation` pulls only atlas-backed `positionEn`/`positionRu` and `functionEn`/`functionRu` fields and omits empty entries.
  * **Narrow-viewport safety**: Tested at `Size(361, 738)` (`devicePixelRatio = 1.0`) in Russian with long anatomical names (`Поднижнечелюстные железы`, `Подъязычные железы`) and `tester.takeException() == null`.
* **Residual risk / gate**:
  * Root must execute the pending `flutter test` (10 tests) and `dart analyze` run before building a candidate.

---

### 2. Small Constellation Preview Geometry (`quizipedia.dart` + `constellation_preview_size_test.dart`)
**Verdict: ACCEPT**

* **What was verified**:
  * **Root cause & fix math**: Previously, subtracting a fixed `48` px (`24` px per side) from a `Size(40, 40)` preview canvas clamped `availableW` and `availableH` to `1.0` px, collapsing all stars into a ~`1.02` px dot.
  * **Adaptive padding behavior**: `padding = math.min(24.0, math.min(size.width, size.height) * .1)` yields `4.0` px per side (`32x32` drawable area) on a `40x40` picker preview while remaining identically `24.0` px per side (`48` px total) for all canvases with `min(width, height) >= 240` (including the `340` px main sky maps).
  * **Test coverage**: `constellation_preview_size_test.dart` verifies `span > 20` and `[0, 40]` bounds on `Size(40, 40)`, and root's 19 sky/mobile tests passed.

---

### 3. Next Frontend Release Baseline-Controller Adaptation (`RELEASECONTROLLERDIFF`)
**Verdict: ACCEPT** *(subject to root running the controller test suite)*

* **What was verified**:
  * **Baseline pin alignment**: `BASE_REVISION = "79"`, `BASE_DEPLOYMENT_REVISION = "77"`, `BASE_BUILD_ID = "quiz-2026.10.21-feedback-0c536221"`, `BASE_IMAGE` (`@sha256:8c48ef8954fec882f19687eeffddf08e19a72eefca19938a063b89692a79e1c3`), `BASE_OCI_INDEX_DIGEST`, and `BASE_INPUT_SHA256` (`ca89b956a2512508487829d169bc2522fefb68932f3f0f00cb196a2de70dc384`) match `PUBLICATIONPROOF` byte-for-byte.
  * **Unchanged invariants**: `API_SHA256` (`e28840775...`), `PVC_UID` (`7fc2428f-...`), `MIN_FIXED_HEADROOM`, and `EXPECTED_GENERATED_WEB_MUTATIONS` remain intact.
  * **Build ID regex**: `BUILD_RE = re.compile(r"^quiz-2026\.10\.21-[a-z0-9]+(?:-[a-z0-9]+)*-[a-f0-9]{8}$")` generalizes the `2026.10.21` slug segment without relaxing date prefix or 8-hex commit suffix validation, and still matches `BASE_BUILD_ID`.
  * **Lineage messages**: Updated cleanly from `release-78` to `release-79`.

---

### 4. Scope of What Publication 79 Proof Supports (`PUBLICATIONPROOF`)
**Verdict: SUPPORTS ONLY THE NARROW BASELINE-79 CLAIMS (WITH TWO EXPLICIT BOUNDARIES)**

1. **Supported by `PUBLICATIONPROOF`**:
   * Release 79 (`helm_revision: 79`, `deployment_revision: 77`) was published and verified healthy (`live: 200`, `ready: 200`, `available_replicas: 1`) for frontend-only build `quiz-2026.10.21-feedback-0c536221` (commit `0c536221c84b0777ffce24f9919e9541e30a64be`, `main_dart_js_sha256: 3e03f9fc502d6aca58a83d78b66f5789e5abe7c03054074dd745ca0c7b7dc9e2`) against unchanged API `quiz-2026.10.19-minimum20-7f8344d6` (`api_sha256: e28840775...`).
   * Physical backup & restore rehearsal passed (`backup_sha256 == restored_sha256 == 3ecc6222...`, `integrity: "ok"`, `bytes: 89694208`, `input_sha256: ca89b956...`), temp mount was cleanly unmounted (`mounted: false`), free disk is `21.75%` (`> 20%` gate), `pvc_uid` is preserved, and `original_feedback_rows_preserved: true`.
2. **Not supported by `PUBLICATIONPROOF` (do not over-claim)**:
   * **Does not cover the new working-tree app changes on `037efe20`**: Items 1 (organ practice feedback) and 2 (40px constellation preview geometry) are post-`0c536221` changes that have not yet been built into a next candidate or published.
   * **Does not prove feedback backlog completion**: Only proves the narrow release-79 state and `original_feedback_rows_preserved: true`.
   * **Nested OCI digests (`BASE_OCI_MANIFEST_DIGEST` and `BASE_DOCKER_CONFIG_DIGEST`)**: `PUBLICATIONPROOF` binds the top-level image/index digest (`sha256:8c48ef89...`), whereas `c05faf62...` (manifest) and `09081896...` (docker config) come from the OCI image manifest/config inspection and must be confirmed by root's controller test/preflight execution.


After this review input was frozen, the root inherited guard suite caught the carried-over post-upgrade revision79 assertion. It was repaired to derive baseline+1 (80);14 tests pass. This follow-up repair still requires explicit independent review.
