Actual Antigravity independent review 03b778bf-b519-43f1-93d3-682b5787295e

**ACCEPT**

### Review Summary
- **Capital-point anchoring (`quizipedia.dart`)**: `reference` is unconditionally anchored to the capital's projected coordinate `at` (`Rect.fromCenter(center: at, width: 10, height: 10)`), eliminating the wide-country drift where `selectedFlagRect` pulled the capital caption toward the country polygon centroid.
- **Collision avoidance (`quizipedia.dart`)**: Candidate rects (side-by-side, above/below dot, and `clearedAboveTop`/`clearedBelowTop` clearing `selectedFlagRect`) are filtered to the 4px-inset viewport bounds and checked with a 3px inflation margin against both `occupied` and `selectedFlagRect`. When a country's flag and capital share the same location, the caption steps cleanly above/below the flag while remaining horizontally centered on `at.dx`.
- **Viewport bounds & camera**: In-bounds filtering (`[4, _view.width - 4]` × `[4, _view.height - 4]`) keeps the caption inside phone viewports (`361×738`, `393×851`, `320×180`), and `TransformationController` remains untouched.
- **Tests (`atlas_map_test.dart`, `lazy_flag` regression suite)**: Covers both the wide-country separation case (`RU` capital at `.2, .5` vs centroid `.5, .5`) and the co-located flag/capital non-overlap case across phone viewports.
