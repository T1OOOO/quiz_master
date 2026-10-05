# Feedback contract clarifications

These root decisions resolve the independent full-contract review. The frozen
API names and payload fields remain as specified in CONTRACT.md.

- Admin total is the count after the status filter and before pagination.
- Repeated setting of the same status returns the current report with HTTP200.
  Concurrent updates use the last committed status. Delete returns204 once and
  404 for later requests or concurrent losers. Missing reports return404.
- Context viewport must be a nonnull object. Required strings must be nonnull;
  optional strings are omitted or strings, never null. Existing per-field limits
  apply: route512, locale/platform/app_version64, optional IDs256, question_text4000.
  Timestamp is parseable UTC, at most64 characters; theme is light or dark.
- Enforce both the raw request body8MiB limit and decoded PNG2MiB/4M-pixel limit.
- Store screenshot bytes in SQLite BLOB and PostgreSQL bytea.
- Guest bootstrap is client-side only. POST /v1/reports always requires the
  existing participant bearer authentication.
- Status update responses contain the same admin report item as list entries:
  has_screenshot boolean, without screenshot bytes.

The user prohibited GitHub Actions due to budget. All further verification must
run locally under the applicable resource grants. No remote CI dispatches.
