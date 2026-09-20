# P10AF — P10A review remediation

Status: **DONE_WITH_CONCERNS** — all available checks pass; execution against the approved disposable PostgreSQL target remains unavailable.

Migration 0003 adds nullable, lowercase-hex-checked `attempt_bundles.manifest_sha256`. It replaces the old shared bundle trigger with a table-specific guard: pre-P10A rows may transition exactly once from `NULL` to a nonnull valid digest while bundle hash, version and controlled JSON remain identical; subsequent updates and all deletes fail. New inserts require the digest immediately. The migration is registered as version 3 with checksum `103eabd08d2a956069d86b68d160885d852a6d7d28babea075f4125af0274b19`.

Attempt startup now hashes the exact manifest bytes after full validation, stores that hash with a newly inserted bundle, conditionally adopts it for a legacy null row, rereads the winning value for concurrent-start safety, and rejects any mismatch. Thus an explanation-only or formatting-only manifest drift cannot silently change reveals after reconstruction. Unit tests independently pin the accepted P08 manifest byte hash; tagged tests cover explanation-only restart rejection and the database adoption/immutability cases.

Every reveal-path response now receives `Cache-Control: no-store` before method or authentication routing. Focused cases cover missing bearer, malformed scheme, invalid bearer and method rejection. The real integration test now parses the reveal response as raw array elements and validates each raw element against `reveal.schema.json` before typed decoding, preventing unknown wire fields from being discarded first.

## Verification and limitation

Focused tests, tagged integration compilation, the full Go suite, server vet, the P04 checker and lightweight P08 verifier all exited 0. Exact commands, durations, RED/GREEN observations and source hashes are in `docs/rewrite-agents/evidence/P10AF/`. P04 and every protected P08 byte/hash remain unchanged.

The PostgreSQL tests were not executed: `QM_TEST_DATABASE_URL` is unset and the approved P09 disposable target no longer exists. No Docker replacement was started and no database claim is made. No Git/index, Beads, Flutter, Android, CI or remote action was performed; the lead must relay scoped diff-check.

Hub lifecycle exception: the P10AF take was blocked because parent P10A remains taken until the same future integration commit exists. The lead explicitly authorized remediation now and will record parent completion, child take/completion and review in valid order after the real commit. No fake done event or commit was recorded.
