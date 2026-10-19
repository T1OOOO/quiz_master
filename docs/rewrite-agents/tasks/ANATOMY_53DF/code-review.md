# Independent code review — ANATOMY_53DF

**Reviewer label:** `anatomy-review-53df`
**Scope:** organ-atlas UI, parser/model, training flow, navigation and focused evidence.
**Final verdict:** **ACCEPT for the reviewed scope.**

## Requirements compliance

The prior rework findings are resolved:

- All English system filters now have display labels, including `Endocrine system`; the widget assertion was red before the patch and is present at `organ_atlas_test.dart:149`.
- The 52-item candidate was imported unchanged: the asset and reviewed candidate both hash to `A59C98CC0ADDF036268941303D6FD741C1531E65B263C469B099BB299B520AA9`.
- The map uses finite eight-item callout pages, each target remains reachable, and selecting a callout or direct heart hit opens the detail sheet without changing the user camera.
- Training initializes a real local frozen round after data loads. Mistake review preserves the original score numerator and denominator.
- The model validates schema, nonempty required text, classifications, HTTPS sources, calendar dates, source/organ relations and distinct four-option questions; parsed lists are immutable.

The factual review's final recheck accepts this same candidate hash. It is evidence for content accuracy, not a claim of publication or release.

## Code quality

The changes are focused and use existing Flutter patterns. Camera ownership is preserved during selection, filtered practice restricts questions by the correct selected organ while retaining all four options, and the retained accessible lists use at least 44px controls. No actionable code-quality finding remains in the reviewed scope.

## Evidence inspected

- `map-tests.log`: 2/2 pass — every shipped callout is reachable and the heart touch path preserves the full camera matrix.
- `focused-tests.log`: 10/10 pass — parser/UI, loading, training navigation and retry flow coverage.
- `organ_flow_test.dart`: explicit cold-training and preserved-score cases.
- `fact-review.md`: final factual acceptance for the imported SHA-256.

The root reported 23/23 navigation regressions after moving the new card and correcting the Greek test interaction. Full-suite and analyzer reruns are root-owned and were still pending at this review point.

## Follow-up recheck — right kidney hit target

**Verdict:** **ACCEPT.** The direct-tap dispatch now recognizes both kidney
silhouettes: the existing left-kidney rectangle and the added right-kidney
rectangle at `(165, 278, 32, 48)`. The condition is constrained to the
`kidneys` target and leaves the preceding stomach hit test order intact.

`organ_map_test.dart` now taps the visible lower right-kidney point `(181, 320)`
after a 1.2x zoom, verifies the `Kidneys` detail sheet, and confirms the full
camera matrix is unchanged. The test is a focused regression for the reported
defect. The root reported the pre-fix case was red and the final focused 12-test
run was in progress; this reviewer did not run tests.
