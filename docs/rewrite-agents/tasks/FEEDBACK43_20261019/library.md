# FEEDBACK43 library evidence

Packet label: `library-feedback43`
Workspace: `E:\Projects\quiz_master`
Source revision: `cc99b0212a2716826bfea51add4370ab11c3f5b5`

## Bounded result

- Replaced each tall cover-plus-three-line pack card with a compact horizontal card: 64 px category thumbnail, two-line readable title, localized question count and direct card launch.
- Removed the obsolete card description and the global header subtitle. Pack identifiers, titles, categories and direct no-round-picker navigation remain unchanged.
- `SourceScaffold` accepts an optional background asset. The library root keeps `library-bg-v1.png`; a category drill-down uses `categoryCoverAsset(folder)` for its current category.

## Test evidence

RED: `flutter test test/feedback43_library_test.dart` first measured the old card at 164 px (requirement: at most 96 px) and could not find the category-aware background. The new test was corrected once after it mistakenly searched for an image below the image itself; it then exercised the intended background behavior.

GREEN:

- `flutter test test/feedback43_library_test.dart` — 2 passed.
- `flutter test test/discovery_test.dart` — 11 passed, including all twelve category cards fitting at 568 px and 768 px desktop heights.
- `flutter analyze lib/discovery.dart lib/source_style.dart test/feedback43_library_test.dart` — no issues.
- `git diff --check -- lib/discovery.dart lib/source_style.dart` — no whitespace errors.

## Remaining risks

- The packet reserves browser and full-build checks for the lead; neither was run here.
- A category background is selected for folder drill-down. Query-only routes preserve the neutral library background because they do not have one authoritative category.
