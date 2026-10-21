# Actual prepared image gate

Antigravity /gemini-4-argon-high; conversation c47e298a-e680-4e4e-beda-098a5dc4f38e

**ACCEPT**

### Prepared Image Gate Verification Summary (`quiz-2026.10.21-feedback-dcdbd247` → Release 81)

1. **Source, Input & Receipt Lineage Binding**:
   - `source_commit` (`dcdbd247fd3d40d135589a65bfadce480d3cf2ec`), `build_id` (`quiz-2026.10.21-feedback-dcdbd247`), and `input_sha256` (`12a97864a413f615b40c2071afa45be2fdce84034c0ea7aa26606bd21a4a2871`) match across `candidate-summary-dcdbd247.json`, `source-dcdbd247-build-receipt.json`, `prepared-image-proof.json`, and the decoded `prepared_receipt_raw_base64`.
   - Frozen source verification passed with exit code `0` across `analyze` (`c7ecc697...`), `tests` (`393` visible Flutter tests, `8cba2e8c...`), and release `build` (`f7a7f887...`), producing `main.dart.js` (`9075ef7f...`).

2. **Immutable Inputs & Closure Guards**:
   - **Web closure**: All `804` web files match between the candidate package and container image (`all_web_bytes_match: true`, manifest SHA-256 `6c3b18b2...`), with exactly `3` generated web delta files and `0` static asset changes (`approved_assets: 0`).
   - **Backend & content immutability**: `api_sha256` (`e2884077...`) is unchanged; all `165` quiz source files are untouched (`all_165_quiz_sources_unchanged: true`, `approved_existing_mutations: 0`).
   - **Feedback conservation**: All `130` original feedback rows remain conserved (`all_original_feedback_rows_unchanged: true`) with no premature closures.

3. **Image Digest, Backup/Restore & Copied-DB Rehearsal**:
   - **OCI / CRI identity**: `oci_index` / `docker_id` (`sha256:841b08ef...`), `amd64_manifest` (`sha256:c0caa89b...`), and `config_digest` / `cri_id` (`sha256:d3aad08e...`) are verified (`oci_content_hashes_verified: true`).
   - **Backup & restore**: Prepare backup (`3ecc6222...`, `89,694,208` bytes, mode `0o600`, `integrity: "ok"`) restored cleanly with matching SHA-256 (`restored_sha256: "3ecc6222..."`).
   - **Real HTTP rehearsal against copied DB**: Passed (`integrity: "ok"`, `visible_banks: 105`, `visible_slots: 4520`, `private_pooled_banks: 23`, `aliases: 56`, `archival_fallback_quizzes: 11`, `article_refs: 241`, `eligible_started: 57`, `new_questions_graded: 38`, `short_bands_rejected: 363`).

4. **Cluster Baseline & Pre-Publish Condition**:
   - Live cluster remains untouched at `helm_revision: 80` / `deployment_revision: 78` (`new_release_published: false`, `chart_rendered_baseline_matches_live: true`), `pvc_uid` (`7fc2428f...`) and `reserved_block_count` (`1271337`) are intact, `tmpfs` is unmounted (`268,435,456` bytes released), and node disk space (`21.25%` free) and conditions (`Ready: True`, no pressures) are healthy.
   - **Condition before `publish`**: Root must finish the remaining local mobile phone viewport QA for `music`, `food`, `belief`, and `knowledge` prior to executing the Helm 80 → 81 publish step; `physical_android_tested: false` remains explicitly recorded.
