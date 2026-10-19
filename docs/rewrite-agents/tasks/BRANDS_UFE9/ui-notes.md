# Brand atlas UI evidence

Owned files: `next/apps/quiz_app/lib/brand_atlas.dart` and
`next/apps/quiz_app/test/brand_atlas_test.dart`.

The page loads the `qm-brand-atlas/v1` source registry from `brands.json` and
rejects impossible dates, non-HTTPS source URLs, duplicate IDs, unresolved
owner links, and claim source links. It has an explicit retry state.

The mobile-safe list supports bilingual search across brand, owner, founder,
and former name; sector filters; name/founding-year order; linked brand and
owner cards; source buttons; and a local unranked four-choice practice round.
Logo history is textual and source-linked: the screen intentionally does not
invent or redistribute trademark artwork.

Focused verification:

```text
flutter test test/brand_atlas_test.dart
00:04 +6: All tests passed!
flutter analyze lib/brand_atlas.dart test/brand_atlas_test.dart
No issues found!
```
