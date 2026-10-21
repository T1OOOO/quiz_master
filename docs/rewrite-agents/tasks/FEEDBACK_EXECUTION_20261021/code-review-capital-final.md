# Independent selected-capital correction review

Provider: Antigravity / gemini-4-argon-high. Conversation: 9fd7a725-02fe-4a44-82b9-14ea6269bfa0

ACCEPT

### Scoped Code & Test Review Findings (`quizipedia.dart`, `lazy_flag_test.dart`)

- **No P1/P2 defects found.**
- **Selected-capital overlay ordering & visibility ([quizipedia.dart](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/quizipedia.dart#L3100-L3183))**: When `widget.showFlags` is active and the selected country has both `capitalPoints` and `capitalLabels`, `map-selected-capital-dot` and `map-selected-capital-label` are appended to `labels` after the flag marker loop so they render above the country flag in `_factLabels`.
- **Fallback when flag is decluttered/off-screen ([quizipedia.dart](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/quizipedia.dart#L3134-L3146))**: `selectedFlagRect` falls back to `Rect.fromCenter(center: at, width: 10, height: 10)` when the flag marker is omitted, keeping the caption positioned beside the visible capital dot as long as `at` is within `_view`.
- **Text measurement & disposal ([quizipedia.dart](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/quizipedia.dart#L3119-L3129))**: `TextPainter` uses `Directionality.of(context)` and `MediaQuery.textScalerOf(context)` with `maxWidth: 108`, computes `width = textPainter.width + 8`, and disposes the painter immediately.
- **Painter suppression & repaint contract ([quizipedia.dart](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/quizipedia.dart#L3606-L3609), [quizipedia.dart](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/quizipedia.dart#L3795))**: `_MapPainter` suppresses only the selected capital's canvas text label when `showFlags && id == selected`, preserving all other painter capital dots/labels and including `showFlags` in `shouldRepaint`.
- **Budget & camera preservation ([quizipedia.dart](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/quizipedia.dart#L3097-L3099))**: The `flagMarkerBudget` (`8`/`16`/`40`) check remains inside the feature loop prior to appending the selected-capital overlay widgets, and `widget.controller` is not mutated.
- **Mobile regression test coverage ([lazy_flag_test.dart](file:///E:/Projects/quiz_master/next/apps/quiz_app/test/lazy_flag_test.dart#L112-L186))**: Covers `Size(361, 738)` and `Size(393, 851)`, snapshots `before = controller.value.clone()` prior to `pumpWidget`, and verifies non-overlap (`flag.overlaps(capitalLabel) == false`), viewport containment (`mapViewport.contains(...)`), transformed dot center accuracy (`< 0.01`), and unchanged controller matrix storage.
