# Actual independent prepared image review

Conversation: 318d5713-7172-4c4a-b1eb-c83a58c8a793

**Verdict: ACCEPT**

### Bound Gate Identifiers
* **Build ID**: `quiz-2026.10.21-feedback-0c536221` (source commit `0c536221c84b0777ffce24f9919e9541e30a64be`, prior package review `d735eaba-018f-4a42-81ec-e18ed460cbc1`)
* **Prepared Image Index (`oci_index` / `docker_id` / `docker_descriptor_digest`)**: `sha256:8c48ef8954fec882f19687eeffddf08e19a72eefca19938a063b89692a79e1c3`
  * **Full Prepared Image Reference**: `quiz-master:quiz-2026.10.21-feedback-0c536221@sha256:8c48ef8954fec882f19687eeffddf08e19a72eefca19938a063b89692a79e1c3`
  * **AMD64 Manifest Digest**: `sha256:c05faf625e4ebd1f4734555072bf724b3bccd73e24f2025fd623e114808999d7`
  * **Config Digest / CRI ID**: `sha256:09081896cbdc2f7f32ff8cd34b325a1085b99d679dd1ad06aadec0d16b528bf2`
  * **Prepared Receipt Raw SHA-256**: `15be24de751052c6edaa04064beb111f8ae3b9b06406e52e233906ba485a7711`
* **Input Manifest SHA-256 (`input_sha256`)**: `ca89b956a2512508487829d169bc2522fefb68932f3f0f00cb196a2de70dc384`
  * **Image Web Manifest File SHA-256**: `72879ef822fe8cca4cef341dff1280aeb8c23d78b1e204d1920263da6e673c1d` (all 804 web files byte-verified; `main.dart.js` `3e03f9fc502d6aca58a83d78b66f5789e5abe7c03054074dd745ca0c7b7dc9e2`)
  * **API Binary SHA-256**: `e2884077520a274a753cab0eff58c663aed159fd723c24e2b8f1e234c75539e4` (unchanged; all 165 quiz source files unchanged, 0 existing mutations)
* **Proof SHA-256 (`prepared-image-proof.json`)**: `3b4158baaa9359d202e4c8a46aaf4487ac82a6a13888e9af3b1a0ad7879e0414`
  * **Prepare Executor / Script / Log SHA-256**: executor `f0ca5d1e4ae32c9aa48e4fc3c1783bc2c02a769a4ed4f578e16601cfe3ffeb49`, script `9ab96bb6ba6cd6e3a1e4f3bc647d348c9fc8ec511d7d9a231afa36a0ff788a29`, log `d9d32e4915a9128345c4a30cfff26e7575978d9223cdbf1a065e3278e7f41bfa` (`exit_code: 0`)
* **Backup SHA-256 (`backup_sha256` / `restored_sha256`)**: `3ecc6222772bdba309e68c00480a227a5114a7979297fed1711d5bdd5ce04e69`
  * **Backup File**: `/opt/quiz-master/backups/quiz-2026.10.21-feedback-0c536221-prepare.sqlite` (`89694208` bytes, mode `0o600`, `PRAGMA integrity_check = ok`, full restore hash matched)

---

### Verification Summary
1. **OCI & Containerd Chain Integrity**: Docker image ID/descriptor (`sha256:8c48ef89...`), `k3s ctr` OCI index, amd64 manifest (`sha256:c05faf62...`), and image config / `crictl` CRI ID (`sha256:09081896...`) all content-hash verified on `racknerd-f0269d5`.
2. **Content & Chart Closure**: All 804 `/usr/share/nginx/html/` files match `release-inputs.json`; API binary (`e2884077...`) and all 165 quiz source files are unchanged; normalized Helm baseline, live, and target manifests match except for the expected image digest and `build-id` annotation.
3. **Backup, Restore & RAM-DB HTTP Rehearsal**: Physical SQLite backup (`3ecc6222...`, 89,694,208 B, `0o600`) passed integrity and restore SHA verification. Rehearsal against the copied RAM DB verified 105 visible banks (4,520 slots), 23 private pooled banks, 11 archival fallback quizzes, 56 aliases, 241 article refs, 57 eligible attempts started, 363 short bands rejected, and 38 real question gradings. Volatile `tmpfs` (`268435456` B) was cleanly unmounted (`mounted: false`, release directory confirmed on `/dev/vda2` `ext4`).
4. **Live Production & Host Invariance**: `new_release_published: false`; Helm revision remains `78`, Deployment revision remains `76` (`quiz-master:quiz-2026.10.20-lazy-2af0ab3f@sha256:088725db...`, `availableReplicas: 1`), PVC UID remains `7fc2428f-4146-4c78-a26d-2347d9f3b7bf`, and all 130 `feedback_reports` row hashes are unchanged. Node `Ready=True`, `DiskPressure=False`, free disk space is `22.38%` (`22,920,462,336` B > 20% floor), and ext4 reserved block count remains `1271337`.

---

### Bound Scope & Conditions
* **Authorized Scope**: **Conditional publish only** of `quiz-master:quiz-2026.10.21-feedback-0c536221@sha256:8c48ef8954fec882f19687eeffddf08e19a72eefca19938a063b89692a79e1c3` using the exact prepared receipt (`15be24de751052c6edaa04064beb111f8ae3b9b06406e52e233906ba485a7711`) and fresh pre-publish guards (host lock, free space > 20%, reserved blocks `1271337`, baseline Helm `78` / Deployment `76` / PVC `7fc2428f-4146-4c78-a26d-2347d9f3b7bf`, fresh pre-publish backup, and rollout verification).
* **Explicit Exclusions**: **No feedback closure yet** and no new capital20/Africa54 quiz drafts in this image. Post-publish scoped public verification (including production phone UI checks) and independent post-publish review remain mandatory before closing any feedback items.

