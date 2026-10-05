# Separate-provider static review — 2026-10-05

The read-only CLI was requested as `haiku`; the actual result reports
**claude-sonnet-5**. Record the actual model rather than the requested alias.
The first full static review returned APPROVE, cost USD 0.1897914. Its library
snapshot was `763a36ad6da44fcb393fe40f8948a342378c7c45a3db34dfdf922b6c15be8d7f`.
The renewal guard expired around that invocation. After confirmed CLI exit and
guard exit the owning session reconciled the reservation; that first result
does not establish resource-protocol or current-runtime acceptance.

A fresh changed-scope review ran under granted lease
`lease-dfc90f5ecdd34afc944fff630c0344a5`, guarded by owned PID 47372. No renewal
error was recorded. The CLI exited 0, the guard was stopped, and the reservation
was released after quiescence. Actual model: **claude-sonnet-5**, verdict
**APPROVE**, cost USD 0.0726356. Total recorded provider-review cost is
USD **0.2624270**; no capacity/fallback claim is fabricated.

The second review covers clamped 1..6 relative zoom, modern per-view semantic
announcement, transformed input/hole/ocean and correct-score tests. Reviewed
library SHA-256 is
`85ee0e40ec8bc1464a95f11444aaec89740ac4f5c21e55a1622dbc5730f8f7d5`;
test snapshot was
`a66064392a107a59817337acb5fd5c5566ed43bd64f99273c9e93803033d50c3`.
The route test's fake-async repair and runtime gates were explicitly pending.
This report is static evidence, not a Flutter or production-pass claim.
