# Global feedback for Quiz Master

User authorization: add the feedback button and project capability like
language_learner. Production targets are next/apps/quiz_app and next/server,
not legacy flutter/ or internal/server. Reference investigation identified
language_learner's global overlay, comment dialog, optional app screenshot and
open/resolved admin review. No source quiz/question metadata changes belong here.

## User flow

Global circular support-agent button, accessible tooltip in RU/EN, bottom-right
above page controls with SafeArea/keyboard handling. Mount once around the router
child in MaterialApp.router.builder. It must work on Library, Quiz, Study,
Quizipedia, History, Gallery and Join without resetting navigation, answers,
attempts or locale/theme. It must not block the last question choice or primary
action on a small screen; allow sensible placement/compact behavior.

Open a constrained responsive comment dialog, with type ui/content/idea
(Application problem / Question problem / Suggestion), multiline text,
Cancel/Send, visible optional Attach screenshot checkbox, and screenshot preview
when available. Comment trimmed, required, 1..5000 Unicode characters. Empty text
disables Send. While sending, prevent duplicate sends and show progress. On
success close and show acknowledgement; on error keep text/type/attachment for
retry, show localized actionable error. Capture the app before opening the modal,
with at most 3 seconds wait; failure or oversize must allow comment-only sending.
Capture only when appropriate, cap pixel count <=4 million and PNG <=2 MiB.
Admin token entry/report administration must never enter a screenshot/report.

Record frozen dialog-open context: sanitized route path, viewport width/height,
DPR, locale, theme, platform, app version and UTC timestamp. No URL query/fragment,
invite tokens, auth/session tokens, answers, keys, routeArgs or arbitrary state.
Normalize Join to /join/[invite]. Attach quiz_id/question_id/attempt_id and public
question stem only when actually viewing that active quiz/question; no stale
journey context on unrelated pages. item_ids contain screen:<sanitized-route>
and optionally quiz:<id>/question:<id>. No screenshot without the visible attach
choice. Private screenshot/context stay in reports, never quiz/public catalogs.

Reporting uses the existing bearer guest session. If no session exists, create
one without mutating journey state. Coalesce pending bootstrap/report session
creation so feedback cannot overwrite an active/in-flight quiz participant.
Preserve already staged answers/receipts and current quiz ownership. Dialog-open
context and request payload are stable on retry; changing payload generates a
new request ID. No network submission just from opening the form.

## Submission API

POST /v1/reports, existing authenticated participant middleware.
JSON object (unknown fields rejected):

    {"request_id":"frq_<32 lowercase hex>","type":"ui|content|idea",
     "item_ids":["screen:/library"],"comment":"trimmed text",
     "context":{"route":"/library","viewport":{"width":390,"height":844,
                "dpr":2},"locale":"ru","theme":"light","platform":"web",
                "app_version":"...","timestamp":"UTC ISO time",
                "quiz_id":"optional","question_id":"optional",
                "attempt_id":"optional","question_text":"optional"},
     "screenshot":"optional base64 PNG"}

request_id must match frq_ plus32 lowercase hex. Max16 item IDs, each<=512 chars.
Context is an object <=16 KiB serialized, explicit keys above only (viewport
explicit width/height/dpr keys); optional strings bounded, question_text<=4000
chars, route<=512, IDs<=256, locale/platform/version<=64. Strings do not contain
auth/URL secret fields. width/height/dpr must be positive finite numbers within
sensible bounds; timestamp parseable ISO8601. Screenshot decoded <=2 MiB, PNG
signature/decoder-validated dimensions with <=4M pixels. Whole request <=8 MiB.
Reject malformed/empty/null/extra/trailing JSON, unknown type, invalid PNG,
oversized input with appropriate safe 400/413. No private payloads in logs/errors.

201 on first creation,200 for identical participant/request_id retry:
{"id":"rep_<32 lowercase hex>","status":"open|resolved","created_at":"UTC RFC3339"}.
Same participant/request ID + different normalized payload =>409 idempotency
conflict. Participant comes from bearer, never request JSON. Different participants
may use the same request ID independently. Durable unique constraint + payload
digest must withstand concurrent retries/restart. Response/error code shape matches
existing API conventions; neither screenshot nor comment returned publicly.

## Storage and review

PostgreSQL migration4 (do not modify checksums of1..3), matching SQLite schema.
Persist id,participant_id,request_id,payload_digest,type,item_ids,comment,context,
optional PNG bytes,status open/resolved,created_at,updated_at. Index status/time.
Production uses PostgreSQL; SQLite local mode must retain report after DB reopen.

Current rewrite has no administrator role/account layer. Use a narrowly scoped
operator credential QM_FEEDBACK_ADMIN_TOKEN, optional when moderation is disabled,
at least32 characters when set. It is server configuration only, never a Dart
define/public asset/query/localStorage/cookie/log. Admin endpoints authenticate
this secret via a single Authorization: Bearer header with constant-time
comparison; guest/session bearer is insufficient. Empty configuration denies
access (safe disabled error). No existing identity privilege changes.

GET /v1/admin/reports?status=open|resolved|all&limit=50&offset=0
=> {"reports":[{"id","participant_id","type","item_ids","comment","context",
"status","created_at","updated_at","has_screenshot"}],"total":N,"limit":N,"offset":N}.
Default open,limit50,offset0; limit1..100,offset0..100000, duplicate/unknown/malformed
query rejected. Stable newest-first created_at then id sorting. List excludes PNG.
POST /v1/admin/reports/{id}/status {"status":"open|resolved"} =>200 report item.
GET /v1/admin/reports/{id}/screenshot =>image/png bytes,404 if none/missing.
DELETE /v1/admin/reports/{id} =>204,404 if missing. All private/no-store, privileged.

Client route /feedback: operator token sign-in (password-style field), clear
login/error/loading/empty states, Open/Resolved/All filters, paginated list,
detail with comment/context/optional screenshot, resolve/reopen/delete (confirm
delete), refresh and logout. Keep credential only in page-local memory; never
attach it to guest/normal API calls, route or feedback payload. No admin screenshot
capture. Add localized Reports entry in a suitable existing navigation surface.
Ordinary feedback remains usable without an operator credential.

## Ownership and validation

Backend owner: next/server only, including migrate/config/cmd/api/httpapi/new
reports service/PostgreSQL/SQLite/tests. Sole owner of migration4. Flutter owner:
next/apps/quiz_app/lib and test, including main/parts/API/ARBs/generated l10n.
No dependency updates needed; use Flutter/dart standard capture libraries and
existing crypto/Dio/Riverpod/router. Root owns this contract, Beads, integration,
release/CI, docs, commits/push. Reviewer edits only review evidence, not code.
Workers are not alone, preserve others, no commits/deploy/children. Actual complete
GRANTED host bundles required; failed/queued requests are no read/write permission.

TDD: first demonstrate missing global-button or report-route behavior failing
against runnable existing code, not just undefined symbols/compile errors. Add
real HTTP/store tests for auth/validation/idempotent concurrency/conflict/reopen,
PostgreSQL migration/checksum/integration and private admin access/status/delete.
Widget/API tests cover empty/pending/error/retry payload, session race, context
sanitization, screenshot opt-out/failure, active quiz preserved, RU/EN mobile320x640
and desktop/text scaling, admin token never leaked/reused as guest token. Run full
Go test/vet and Flutter tests/analyze/format plus pinned CI PostgreSQL/Web/Android.
Use shared resource guards for heavy checks; preserve source questions and all
unrelated dirty work. No full metadata rollout implied by this feature.
