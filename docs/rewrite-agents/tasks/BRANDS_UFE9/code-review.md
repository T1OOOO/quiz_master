# Independent review — BRANDS_UFE9

Reviewer: `brand_review` (read-only)

## Scope reviewed

- `next/apps/quiz_app/lib/brand_atlas.dart`
- `next/apps/quiz_app/assets/quizipedia/brands.json`
- `next/apps/quiz_app/test/brand_atlas_test.dart`
- `next/apps/quiz_app/test/brand_registry_test.dart`
- Quizipedia menu integration in `lib/quizipedia.dart` and
  `test/learning_navigation_test.dart`

The factual truth of ownership claims was deliberately reviewed by the
separate fact-check task and is not re-adjudicated here.

## Requirements compliance: approve

The delivered UI provides a searchable, sector-filterable local brand
reference, owner-to-brand and brand-to-owner navigation, founding/date scope,
former names, logo-history text, source-linked facts, an explicit coverage
notice, and an unranked four-option practice mode. The page is routed from
Quizipedia and forwards the asset bundle correctly.

The parser rejects duplicate registry IDs, unresolved owner/source references,
invalid HTTPS URLs, and impossible ISO dates. Claim-specific source buttons
are attached to facts, former names, and logo-history rows. The mobile test
uses a 360 px viewport and 1.5x text scale; selected owner/brand cards scroll
back into view before being shown.

The earlier practice defects were fixed before this review closed:

- questions are shuffled before a ten-question round is selected, rather than
  repeatedly taking the alphabetically first questions;
- a retry round works from a snapshot of missed questions, so wrong retry
  answers cannot keep extending the live list;
- retry answers do not inflate the first-round score;
- ambiguous historical-name rows can be marked `quiz_enabled: false`.

The registry declares itself as a starter set, not a claim that 61 entries are
every brand in the world. That limitation is accurately visible to the user.

## Code quality: approve with a non-blocking follow-up

The data boundary is explicit and validates external asset shape before UI
use. The question generator excludes duplicate options and keeps claim source
IDs with each generated question. No new network dependency, ranked scoring,
or answer/API leakage was found.

`brand_atlas.dart` is now about 1,200 lines and combines registry models,
question generation, and the widget page. It is readable today, but further
feature growth should split models/question generation from the page widget to
keep the screen maintainable. This is not a release blocker for the present
bounded feature.

## Verification evidence

I ran the focused command before the menu-test repair:

```text
flutter test test/brand_atlas_test.dart test/brand_registry_test.dart test/learning_navigation_test.dart
```

It initially found a real defect in the newly added menu test: it queried the
destination `FutureBuilder` from inside `runAsync` before the navigation route
was pumped (`learning_navigation_test.dart:23`), yielding `Bad state: No
element`. This was reported immediately and fixed by preloading both text
assets into a synchronous test bundle, then pumping the route normally.

Final static inspection confirms the repaired test exercises the actual
catalog and `brands.json` through the Quizipedia menu and asserts the page
search control loads. The UI implementer reported the six focused UI tests and
analyzer clean; the lead owns the final full-suite log after this review.

## Verdict

No remaining concrete implementation blocker found in the reviewed scope.
Requirements compliance: **approve**. Code quality: **approve**, with the
file-splitting follow-up above.

## Scoped follow-up acceptance

Reviewed the final list-row polish in `brand_atlas.dart:823-825`. Each brand
now renders its resolved `ownerFor(brand).name` directly beneath the brand
name, followed by sector, country, and year on a separate line. The owner
relation was already validated at registry load, so the displayed claim uses
the same canonical owner as the detail card and question generator. The
explicit newline keeps the secondary metadata from competing with long owner
names on narrow screens; normal `Text` wrapping remains available for an
unusually long owner name. The menu integration test asserts the shipped
`Amazon.com, Inc.` owner is visible. This changed scope is accepted.

## Filtered sibling-navigation acceptance

Reviewed the final fix at `brand_atlas.dart:681-683`. A selected detail now
resolves from `atlas.brands`, not the search-filtered `matches` list. As a
result, choosing a sibling brand from an owner card opens that sibling even
when the still-active search only matches the original brand. The narrow,
large-text widget regression now keeps the `Alpha` search while selecting
`Beta` through the shared owner and asserts that the brand detail remains
visible. This bounded change is accepted; it preserves the search filter for
the underlying list without making linked navigation appear to fail.
