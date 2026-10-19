# QVGI independent code review — 2026-10-19

Scope: country learning atlas, constellation interaction, knowledge atlas and
their focused Flutter tests. This is a review of the shared working tree, not
publication or merge approval.

## Verdicts

- **Requirements compliance: APPROVE.** Country selection and search leave the
  map transformation under learner control; labels cover flag, capital,
  currency, population, area, water, resources and neighbours; neighbour rows
  are navigable; population and area have ascending/descending comparison.
  The constellation canvas supports pinch/pan/double-tap plus correctly-sized
  phone star hit testing. History, culture and people have chronological,
  linked, bilingual learning views and local unranked questions.
- **Code quality: APPROVE.** Parsing validates source URLs, IDs and reciprocal
  work/person relationships. Question options are distinct, and tied chronology
  rounds are rejected. The current changes introduce no user-controlled network
  input or secret-bearing data flow.

## Reviewed corrections

- `knowledge_atlas.dart:559-567` now searches period IDs and localized labels;
  `:626-634` searches a work's type and its linked creators/cast.
- `knowledge_atlas.dart:766` uses localized `_date`; work ranges and
  approximation metadata parse at `:117-165` and render at `:824`.
- `constellation_atlas.dart:371-400` computes both drawing and hit-testing
  points from the same `LayoutBuilder` width. This fixes the narrow-phone tap
  mismatch.
- `country_learning.dart:1077-1119`, `:1337-1352` and `:766-812` implement
  the requested map-layer, neighbour-navigation and rank controls without
  setting a map focus target on selection.

The fact review's prior Don Quixote duplicate sentence is no longer present.
The current JSON contains 44 events, 30 works and 39 people. Its corrected
Hammurabi, Messiah, Swan Lake, Odyssey, Divine Comedy, Hamlet and Macbeth
metadata was inspected alongside the linked fact-review evidence.

## Fresh verification

From `next/apps/quiz_app`:

```text
flutter test test/knowledge_atlas_test.dart test/constellation_atlas_test.dart test/atlas_ui_test.dart test/atlas_map_test.dart
17 tests passed
```

`git diff --check` on the reviewed implementation and test paths reported no
whitespace error; it only emitted Windows LF-to-CRLF conversion warnings for
pre-existing tracked files.

## Remaining risk

The corpus intentionally remains a curated starter set. Sources are attached
per record, rather than per individual biographical, award and role claim, as
documented by `fact-review.md`. That limits expansion work, but does not block
the reviewed interactions or current question generators.
