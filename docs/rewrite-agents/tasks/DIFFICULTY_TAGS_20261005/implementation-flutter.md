# Flutter implementation evidence

Task: `quiz_master-qr4.2` (`difficulty-flutter-20261005`).

## Scope implemented

- Strict public question decoding accepts `nightmare`, optional exact
  `difficulty_level` (1..10), checks its band mapping, and permits only valid,
  unique `context_tag_ids`. Closed parsing continues to reject editorial and
  other unknown fields.
- Discovery reads optional four-band counts and safe context search terms. It
  searches those terms, disables zero-count bands, and keeps difficulty in
  library and quiz routes.
- Selected difficulty reaches both `GET /v1/catalog` and `POST /v1/attempts`.
  Per the lead's clarification, no `round` means all matching questions;
  explicit zero-based rounds remain 20-question chips.
- Added English and Russian labels and test-first coverage for DTO boundaries,
  discovery metadata, API request preservation, and a 390×844 long-prompt/
  long-choice mobile scroll regression.

## Check status

Baseline observed: `e802ed21db936bdb9809bab2d137903eb0aa425e`.

`flutter gen-l10n`, `flutter test`, formatter, and `flutter analyze` are
**NOT RUN**. They require the packet's actual host lease. A host lease request
returned an execution error, and the lead was asked to schedule the one heavy
Flutter window. Therefore generated localization sources are not yet refreshed
and this report does not claim compilation or acceptance.

## Remaining integration points

- Root must add `difficulty_counts` and `context_search_terms` to the catalog
  asset; until then the new difficulty chips intentionally remain disabled.
- Backend must supply the confirmed optional `difficulty` contract and the
  no-match response. Safe/known tag membership remains server-side taxonomy
  validation because no public dictionary endpoint or asset is part of v1.

## Compatibility delta (difficulty-flutter-20261005)

- `PublicQuestion` keeps constructor metadata optional for the local Study
  projection, while `fromJson` still requires a non-null wire `difficulty`.
- Added focused DTO cases for missing/null wire difficulty, every approved
  context namespace, and rejected private `country`, `ingredient`, `person`,
  `place`, and `cuisine` namespaces. Flutter checks remain unrun pending the
  lead-scheduled host lease.
