# Task packet: P10AF review remediation

TASK: P10AF / `quiz_master-rq9.11.1.1`
ROLE: `qm_backend`; sole worker `exec-backend-P10AF`; no children
BASE: current shared checkout after P10A READY; reviewer verdict: REJECT

Fix only the three independent-review findings. Read P10A/P10AF packets, `qm-work-packet`, `qm-go-backend`, TDD, verification, P10A report/evidence, reviewer message relayed by lead, migration 0002/runner, and the affected tests. No Git/index/Beads/remote, Docker, Flutter, Android or GitHub Actions.

Owned additions/edits: P10A-owned files plus `next/server/internal/migrate/runner.go`, its migration tests, exactly new migration `next/server/internal/migrate/migrations/0003_reveal_manifest.sql`, and P10AF report/evidence. Migration number 0003 is exclusively leased by the lead for this fix.

Required fixes:

1. Compute SHA-256 over the exact validated manifest bytes and immutably associate it with `attempt_bundles`. Migration 0003 adds a nullable, lowercase-64-hex-checked `manifest_sha256`. Existing pre-P10A rows may adopt exactly one nonnull hash at first startup; after adoption, updates/deletes remain forbidden. Replace the bundle trigger with a table-specific guard that permits only `NULL -> valid hash` while every prior column remains identical. New bundle inserts must store the hash immediately. Startup must compare stored bundle bytes and manifest hash and reject explanation-only manifest drift. No P08 artifact/schema/hash changes.
2. Add a RED/GREEN test proving an explanation-only manifest change is rejected after the first service initialization (including restart semantics). Cover migration registration/order/checksum and the one-time adoption guard as far as unit/SQL structure tests permit without a live database. Do not claim the unavailable live PostgreSQL gate.
3. Ensure every reveal request outcome, including missing/invalid bearer authentication, has `Cache-Control: no-store`; add focused tests.
4. In the real integration test, validate each raw reveal array element against `reveal.schema.json` before typed unmarshal, so unknown wire fields cannot be discarded before validation.
5. Rerun only invalidated focused tests, tagged integration compilation, full Go once, vet once, P04/P08 lightweight preservation checks, and lead-relayed diff-check. Update P10A report/evidence or add P10AF report/evidence without falsifying the unavailable live DB execution.

Return READY with changed paths, observed RED/GREEN, commands/exits/durations and `DONE_WITH_CONCERNS` only for the same missing approved PostgreSQL target. Do not commit or push.
