# Feedback implementation checkpoint — 2026-10-06

Feature issue quiz_master-xas: production Web release verified; see RELEASE_20261006.md.
Contract frozen at bc00126; active targets next/server + next/apps/quiz_app.

Implemented global RU/EN feedback button, scrollable comment form, optional PNG
preview/attachment, three-second bounded capture, frozen sanitized screen/current
question context, stable payload/request ID across retry and shared in-flight guest
bootstrap. Guest feedback does not mutate the active quiz journey. Operator and
invite screens are excluded from capture; invitation context is normalized.

Private /feedback page uses a separate Dio and page-memory-only operator token.
It supports filtered/paginated reports, context/PNG detail, resolve/reopen,
confirmation before delete, refresh/logout, mounted/generation guards and visible
errors. Raw credentials do not enter normal API calls, assets or feedback payloads.

Backend supplies durable SQLite/PostgreSQL reports and migration 4, strict request
validation, authenticated submission, idempotent/concurrent receipt handling and
private operator lifecycle. NUL text is rejected; operator minimum is 32 Unicode
characters with separate 4096-byte maximum and whitespace exclusion.

Verification executed on current implementation with GRANTED guarded bundles:
- go test -p 1 ./next/server/...: PASS (all packages).
- go vet -p 1 ./next/server/...: PASS.
- flutter test --no-pub --concurrency=1: PASS, 101 tests.
- flutter analyze --no-pub: PASS, no issues.
- Dart format and gofmt: PASS; whitespace/staging checks required before commit.

The NUL environment fixture was changed to direct validation because operating
systems reject NUL during Setenv. The current taxonomy fixture is pinned to ID
qm-tags-v1, 425 tags and SHA256
07e4bbb5c7afcdab3b41a26dca1bf0ba9a830d5f776a98ebceeaeb2bd8356151.
Execution caught/fixed a pre-existing private dialog-name collision and missing
Overlay ancestor; installed Flutter Overlay.wrap preserves the router subtree.
Feedback widget tests exercise the screenshot timeout path using the test clock,
retry retention/idempotency, opt-out, sanitized query and operator-button hiding.

Independent source review is documented in REVIEW_20261006.md. This was another
Codex agent, not verified cross-provider acceptance. PostgreSQL integration-tag
execution and Android release/device checks are NOT_RUN. Web/Linux release builds,
production deployment, public API moderation and actual browser screenshot submission
passed on 2026-10-06. Browser verified moderator login rendering; protected operations
were exercised through the API, not by entering the operator key into the browser.
The ordinary Go suite exercises real SQLite
HTTP/store persistence and concurrency; it does not certify PostgreSQL execution.
No running Flutter target was available for hot reload/restart.

User prohibited GitHub Actions due to budget. No new runs, dispatches, downloads
or paid infrastructure were used. The workflow remains removed. Git push is
required and does not authorize paid CI. User explicitly allowed lightweight
reads/edits without Hub admission in this task; heavy operations retained real
admission, periodic renewal and release after process exit.

Earlier local RED report route returned 404 before implementation. User-authorized
recovery released exactly one stale disconnected board_game_platform QUEUED
reservation. No processes were killed and no host thresholds were changed.

Published build quiz-2026.10.06-feedback-e0f89cf, Helm revision 25. Server-only
operator secret provisioned. Backup restoration, migration with original-row
preservation and old API rollback rehearsal passed before cutover. A pre-cutover
attempt completed afterward with replay, score, history and explanations preserved.
Browser submission persisted a 448330-byte PNG; only synthetic test reports were
deleted. All owned build/browser leases released and the browser session closed.
Extended PostgreSQL and Android validation remains separate follow-up work.

Difficulty/tag task remains 2957/4078 accepted, remaining 1121. Feedback does not
apply unpublished annotations or alter question content. Those issues stay open;
metadata acceptance is not factual certification. Preserve unrelated dirty work.
