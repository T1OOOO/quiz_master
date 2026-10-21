# Actual independent controller and thumbnail review

Conversation: b9b47b54-7e84-4a62-beb2-392b26b2cbf8

### Independent Read-Only Review Verdict

* **Post-Revision Repair & OCI/CRI Baseline Pins:** **ACCEPT**
* **Photo Thumbnail Policy, Generator Tool & Test Update:** **ACCEPT**

---

### 1. Post-Revision Repair & OCI/CRI Baseline Pins — **ACCEPT**

* **Post-Upgrade Revision Assertion Fix (`CONTROLLER_SHA256: 34657ac82b33bd98f79f3b0ebb3b013082e4e81e23978c1ac2626007ee0437fa`):**
  * Replacing the stale hardcoded post-upgrade check with `"{int(BASE_REVISION) + 1}"` correctly asserts revision `"80"` after `helm upgrade` from baseline `"79"`, preventing `post_upgrade_err` from triggering a false-positive rollback of a healthy release.
  * Rollback target (`helm rollback {RELEASE} {BASE_REVISION}` -> `79`) and baseline lineage/preflight rejection of stale revision `78` remain intact.
  * `Release79GuardsTest` (`14/14` passing) directly covers both `'helm rollback quiz-master 79'` and `'= "80"'` in the rendered `publish` script, unmount-before-upgrade ordering, inline Python shell quoting across `k3s ctr` / `crictl`, `findmnt -T` + `tune2fs` reserve blocks, web delta allowlists, and `BASE_INPUT_SHA256` lineage binding.
* **Live Read-Only Baseline & OCI/CRI Chain Verification:**
  * Live read-only preflight against Helm revision `79` / deployment revision `77` (`quiz-2026.10.21-feedback-0c536221`) confirms the full digest chain in `k8s.io` containerd/CRI storage:
    * **Docker ID / Descriptor / OCI Index:** `sha256:8c48ef8954fec882f19687eeffddf08e19a72eefca19938a063b89692a79e1c3`
    * **OCI AMD64 Manifest:** `sha256:c05faf625e4ebd1f4734555072bf724b3bccd73e24f2025fd623e114808999d7`
    * **Docker Config / CRI ID:** `sha256:09081896cbdc2f7f32ff8cd34b325a1085b99d679dd1ad06aadec0d16b528bf2`
  * Separate index, manifest, and config digest pins are enforced and verified.

---

### 2. Photo Thumbnail Policy, Generator Tool & Test Update — **ACCEPT**

* **Deterministic Generator Tool & Asset Integrity (`manifest_sha256: a908fa6643868506880775ea6b43c7f6b128f2b8fc65e6e7df24fd8290d869d0`):**
  * Scoped strictly to the 46 landmark pairs in `next/apps/quiz_app/assets/quizipedia/catalog.json`, enforcing directory containment, uniqueness, `ImageOps.exif_transpose`, LANCZOS downscaling bounded to `512x512` without upscaling, `WEBP` (`quality=76`, `method=6`), and atomic `.tmp` replacement.
  * All 46 source photos and `catalog.json` match Git `HEAD` byte-for-byte; only the 46 landmark `.webp` thumbnails changed (`154,092` -> `1,356,080` bytes total), while other home thumbnails and browser lazy-loading Dart code remain untouched.
  * Aspect ratios are preserved (e.g., `colosseum` `684x912` -> `384x512`, `taj-mahal` `960x640` -> `512x341`).
* **Thumbnail Policy & Test Suite (`383/383` Flutter tests + `flutter analyze` clean, including `10/10` organ tests):**
  * Replacing the legacy `15,000 B` / `192x144` check with the higher-resolution local preview policy (`< 64 KiB` per file vs actual max `61,496 B`; `< 128 KiB` first-4 initial grid vs actual `95,462 B`; `< 1.5 MiB` total vs actual `1,356,080 B`; dimensions `240..512` px) is well-bounded and matches the regenerated assets.
  * Negative parser validation and legacy `landmark_thumbnails.json` (`<= 160x160`, `< 500,000 B`) decode checks remain preserved.

---

### Scope Boundary Note

* This acceptance covers **only** the post-upgrade revision assertion repair, the verified OCI/CRI baseline pins, and the landmark photo thumbnail regeneration policy/tool/tests (plus the previously conditionally accepted organ/preview/controller items now backed by the full 383-test and analyzer run).
* No candidate release package has been built or deployed yet, and this review does **not** claim package publication or full feedback-batch closure.

