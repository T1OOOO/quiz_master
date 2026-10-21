# Actual independent phone follow-up code review

Conversation: 3438abe6-e79a-4dc2-9778-a6a7d86fbd86

### Verdict Summary

- **Scoped Patch 1 — World Map Camera (`quizipedia.dart` + `country_camera_resize_test.dart`):** **ACCEPT**
- **Scoped Patch 2 — Chronology Timeline Alignment (`chronology_timeline.dart` + `chronology_alignment_test.dart`):** **ACCEPT**

---

### Scoped Patch 1: World Map Camera ([quizipedia.dart](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/quizipedia.dart), [country_camera_resize_test.dart](file:///E:/Projects/quiz_master/next/apps/quiz_app/test/country_camera_resize_test.dart)) — **ACCEPT**

#### Resolution of Prior `15fd49b5` Findings
1. **Outgoing reverse transition gated at all writer callsites:**
   - [`_ownsCamera`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/quizipedia.dart#L2681-L2682) requires both `_cameraActive` (`TickerMode`) and `ModalRoute.of(context)?.isCurrent ?? true`.
   - Every write to `widget.controller.value` and `_cameraViewports[widget.controller]` is now gated by `_ownsCamera`: the [`_camera` listener](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/quizipedia.dart#L2688-L2690), [`_moveCamera`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/quizipedia.dart#L2730-L2731), and the post-frame callback in [`_syncCameraViewport`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/quizipedia.dart#L2786-L2802).
   - When the expanded route pops, its `isCurrent` flips to `false` immediately even while its reverse transition keeps `TickerMode` enabled, preventing its in-flight zoom animation or resize `LayoutBuilder` pass from overwriting the revealed compact camera.
2. **Empty viewport safety:**
   - [`_syncCameraViewport`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/quizipedia.dart#L2789-L2796) guards against `_view.isEmpty` and `previous.isEmpty` before calling [`_reframeCamera`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/quizipedia.dart#L2760-L2784), preventing `0 / 0` (`NaN`) matrix writes when a layout pass transiently reports `Size.zero`.
3. **Meaningful test coverage:**
   - [country_camera_resize_test.dart](file:///E:/Projects/quiz_master/next/apps/quiz_app/test/country_camera_resize_test.dart) exercises pinch/pan on the compact map, route expansion (`country-expand-map`), pinch/pan on the expanded map, an in-flight zoom animation (`Zoom in` + `16ms` pump), and simultaneous route pop (`country-collapse-map`) + physical viewport resize (`393×851` → `361×738`), verifying geographic center preservation within `0.001` and no uncaught exceptions.

#### Non-Blocking Observation
- [`didChangeDependencies`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/quizipedia.dart#L2700-L2710) tracks `TickerMode.valuesOf(context).enabled` rather than `_ownsCamera`. In normal flows where the pushed `MaterialPageRoute` settles before popping, `TickerMode` on the underlying route transitions `true → false → true` and triggers `_syncCameraViewport()` on pop. Only a pop triggered mid-push before the initial push transition finishes (while `TickerMode` on the lower route never turned `false` and without a viewport resize) would skip `didChangeDependencies` on the lower route. This is non-blocking for the scoped fix.

---

### Scoped Patch 2: Chronology Timeline ([chronology_timeline.dart](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/chronology_timeline.dart), [chronology_alignment_test.dart](file:///E:/Projects/quiz_master/next/apps/quiz_app/test/chronology_alignment_test.dart)) — **ACCEPT**

#### Checklist Verification
1. **Geometry:**
   - Each card item has width `entryWidth = 164 * _scale` and horizontal date/title padding of `8px` per side (`maxWidth: entryWidth - 16`).
   - Every item's date header is constrained to a uniform [`SizedBox(height: dateHeight)`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/chronology_timeline.dart#L136-L151) with `Align(alignment: Alignment.bottomCenter)`, and the timeline connector row is constrained to a uniform [`SizedBox(height: 20)`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/chronology_timeline.dart#L153-L172).
   - This structurally locks the horizontal divider and icon center to `y = 12 (top padding) + dateHeight + 10 (gap) + 10 (half of 20px node band) = 32 + dateHeight` across all entries, eliminating both the multi-line date step and the 2px selected (`20px`) vs. unselected (`12px`) icon height step.
   - Outer container height [`contentHeight = 24 + dateHeight + 10 + 20 + 16 + titleHeight`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/chronology_timeline.dart#L72) matches the sum of vertical paddings (`24` outer + `16` title), fixed bands (`10` + `20`), and measured text heights (`dateHeight` + `titleHeight`), floored by `textScaler.scale(180)`, while keeping `Flexible` around the title padding to absorb any sub-pixel rounding delta.
2. **Localization & `textScale`:**
   - `heightOf` passes `MediaQuery.textScalerOf(context)`, `Directionality.of(context)`, `Localizations.maybeLocaleOf(context)`, and `DefaultTextStyle.of(context).style` (plus `dateStyle` for dates and `maxLines: 3, ellipsis: '…'` for titles) to `TextPainter`, matching the rendered `Text` widgets across locales and text scale factors.
3. **Empty List (`entries.isEmpty`):**
   - When `entries` is empty, the measurement loop does not execute, `dateHeight` and `titleHeight` stay `0`, `contentHeight` is `70`, the outer `SizedBox` falls back cleanly to `textScaler.scale(180)`, and `ListView.builder` builds `0` items without error.
4. **Lifecycle:**
   - `painter.dispose()` is called immediately after `painter.layout(...)` inside `heightOf`, so no native paragraph objects leak across rebuilds or scale changes.
5. **Meaningful Test:**
   - [chronology_alignment_test.dart](file:///E:/Projects/quiz_master/next/apps/quiz_app/test/chronology_alignment_test.dart) tests wrapping vs. short Russian date strings (`'около 800 до н. э.–700 до н. э.'` vs. `'около 1308–1321'`) with one selected (`Icons.radio_button_checked`) and one unselected (`Icons.circle`) node at both `1.0` and `1.6` text scale, and re-verifies alignment (`closeTo(other.dy, .1)`) after zooming the timeline scale out and back in.

---

### Runtime Browser Unknowns (Distinguished from Code/Test Verdict)

- **Live Web / CanvasKit font shaping & sub-pixel metrics:** Widget tests run with Flutter test font metrics (`Ahem` unless real fonts are loaded); actual browser glyph shaping in Chromium stays protected for axis alignment because `SizedBox(height: dateHeight)` and `SizedBox(height: 20)` hard-constrain the vertical offset of the timeline axis regardless of font family, though visual appearance under browser zoom/DPI was not inspected in this read-only review.
- **Browser pointer/touch-pad gesture synthesis:** `country_camera_resize_test.dart` verifies Flutter's `InteractiveViewer` gesture arena with synthesized touch pointers and `physicalSize` changes; real browser trackpad wheel/pinch events and mobile browser address-bar resize dynamics remain runtime browser behavior outside unit test scope.

