Actual reviewer: Antigravity CLI / gemini-4-argon-high. Review findings independently checked by lead before fixes. Some non-issue descriptions in this report are inaccurate (e.g. SVG flags and source function names); those are not evidence of acceptance.

## Review Verdict: **CHANGES REQUESTED (3 Concrete Blockers)**

I reviewed the uncommitted diff in [review-ui.diff](file:///E:/Projects/quiz_master/.run/feedback_20261019/review-ui.diff) and inspected the connected source and test files across the requested Flutter UI and Go server paths (strictly read-only; no test passes inferred).

---

### Concrete Blockers

#### 1. [`organ_atlas.dart`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/organ_atlas.dart): Unhandled `StateError` crash on empty search/filter + broken organ selection & English default state in [`_BodyMapState`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/organ_atlas.dart#L609-L669)
- **Location**:
  - [`_OrganAtlasPageState._browse`](file:///E:/Projects/quiz_master/next/apps/quiz_master/next/apps/quiz_app/lib/organ_atlas.dart#L302-L351) ([organ_atlas.dart:307-350](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/organ_atlas.dart#L307-L350))
  - [`_BodyMapState._drawableIds`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/organ_atlas.dart#L610-L623), [`_BodyMapState._illustratedAnchors`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/organ_atlas.dart#L624-L631), and [`_BodyMapState.build`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/organ_atlas.dart#L634-L668)
- **Problems**:
  1. **Crash on empty search result**: [`_browse`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/organ_atlas.dart#L302-L351) unconditionally mounts `_BodyMap(organs: shown, ...)` at [line 307](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/organ_atlas.dart#L307) *before* checking `if (shown.isEmpty)` at [line 345](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/organ_atlas.dart#L345). When `shown` (`widget.organs`) is empty, [`_BodyMapState.build`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/organ_atlas.dart#L636-L644) evaluates:
     ```dart
     final focused =
         widget.selected != null && _drawableIds.contains(widget.selected!.id)
         ? widget.selected!
         : widget.organs.firstWhere(
             (item) => _drawableIds.contains(item.id),
             orElse: () => widget.organs.first,
           );
     ```
     `widget.organs.first` throws `StateError (Bad state: No element)`.
  2. **Stale `_drawableIds` (12 IDs) vs `_illustratedAnchors` (6 IDs) breaks selection for 46 of 52 organs and breaks initial English load**:
     - [`_drawableIds`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/organ_atlas.dart#L610-L623) still lists 12 IDs from the old custom painter (`brain`, `thyroid`, `parathyroids`, `thymus`, `lungs`, `heart`, `liver`, `stomach`, `pancreas`, `adrenals`, `kidneys`, `bladder`), whereas [`_illustratedAnchors`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/organ_atlas.dart#L624-L631) only defines 6 points (`brain`, `thyroid`, `lungs`, `heart`, `liver`, `stomach`).
     - **Broken initial English view**: On initial load (`_selected == null`), [`_visible`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/organ_atlas.dart#L204-L216) sorts alphabetically by `nameEn`, placing `Adrenal glands` (`id: 'adrenals'`) first. Because `'adrenals'` is in `_drawableIds` but not in `_illustratedAnchors`, `focused` resolves to `adrenals` and `anchor` is `null`—so the default English diagram shows **no pin** (`organ-map-target-*` is absent) and immediately displays the *"This structure has no point on the orientation illustration..."* banner.
     - **Broken selection for the 40 organs outside `_drawableIds`**: When the user taps a `ChoiceChip` (`Key('organ-map-card-<id>')`) or list item (`Key('organ-list-<id>')`) for any structure not in `_drawableIds` (e.g., `spinal_cord`, `bones`, `spleen`, `pituitary`), `_drawableIds.contains(widget.selected!.id)` is `false`. `focused` ignores `widget.selected!` and snaps back to `brain` (RU) or `adrenals` (EN):
       - The tapped `ChoiceChip` (`selected: item.id == focused.id` at [line 695](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/organ_atlas.dart#L695)) never highlights as selected.
       - In Russian, the illustration misleadingly keeps the `brain` pin (`organ-map-target-brain`) on screen instead of showing the `organAtlasNoDiagramPoint` notice for the selected non-illustrated organ.
- **Reproduction**:
  1. Open `/quizipedia/organs` and type `xyz` into `Key('organ-search')` → immediate `StateError` exception.
  2. Open `/quizipedia/organs` with `Locale('en')` → initial diagram has no pin and shows the no-diagram-point warning for `Adrenal glands`.
  3. Open `/quizipedia/organs` with `Locale('ru')` and tap `Key('organ-map-card-spinal_cord')` → detail dialog opens for Spinal Cord, but `focused` stays `brain` (chip `organ-map-card-brain` remains selected and `organ-map-target-brain` stays pinned on the illustration).
- **Fix Direction**:
  - Guard `if (widget.organs.isEmpty) return const SizedBox.shrink();` in [`_BodyMapState.build`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/organ_atlas.dart#L634) (or skip rendering `_BodyMap` when `shown.isEmpty`).
  - Remove the stale 12-item `_drawableIds` set (or align it with `_illustratedAnchors.keys`), and when `widget.selected != null` (and present in `widget.organs`), set `focused = widget.selected!` directly so `ChoiceChip` selection and `anchor = _illustratedAnchors[focused.id]` accurately reflect the selected structure, falling back to `_illustratedAnchors.containsKey(item.id)` only when `widget.selected == null`.

---

#### 2. [`music_learning.dart`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/music_learning.dart): Compact [`MusicVisual`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/music_learning.dart#L211-L247) in `ListTile.leading` does not scale [`_MusicPainter`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/music_learning.dart#L264-L318) or multi-line text, painting outside the leading box and over card titles
- **Location**:
  - [`MusicVisual.build`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/music_learning.dart#L218-L246)
  - [`_MusicPainter.paint`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/music_learning.dart#L270-L311)
  - [`_MusicSectionState.build`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/music_learning.dart#L573-L585) (`leading: SizedBox(width: 76, child: MusicVisual(item: item, compact: true))`)
- **Problems**:
  1. **Unscaled hardcoded canvas coordinates in [`_MusicPainter`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/music_learning.dart#L270-L311)**:
     - [`MusicVisual`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/music_learning.dart#L240-L244) passes `size: compact ? const Size(76, 68) : const Size(260, 156)` to `CustomPaint`, without a `FittedBox`, `canvas.scale`, or `ClipRect`, and `ListTile.leading` further constrains height to `56px`.
     - [`_MusicPainter.paint`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/music_learning.dart#L270-L311) uses fixed coordinates designed for `260×156`:
       - **`visual['note']`** (`note-0`..`note-6`, `ledger` in `pitch`): draws staff lines at `y = 40..88`, treble clef at `Offset(36, 76)`, ledger line at `x = 130..158`, notehead at `Offset(136, 100 - note * 6)`, and stem at `x = 147`. Because `CustomPaint` does not clip by default and the leading width is `76px`, the notehead (`x = 136..158`) paints **60–82px to the right of the leading box**, directly on top of the `ListTile` title/subtitle text, while `y = 76..100` overflows below the row.
       - **`visual['glyph']`**: draws staff lines at `y = 40..88`, articulations (`0xE4A2`, `0xE4A0`, `0xE4C0`) at `y = 115` (`fontSize: 60`), and standalone glyphs (`sharp`, `whole`, `quarter`, etc.) at `y = 106` (`fontSize: 76`), painting below the `56px`-tall leading box into the card below.
  2. **Compact text visuals overflow `76×56` leading box**:
     - For `visual['text']` ([lines 224-238](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/music_learning.dart#L224-L238)), `compact: true` uses `headlineMedium` (`fontSize: 28`, height ~36px per line) without `FittedBox`. Multi-line values in [`music_learning.json`](file:///E:/Projects/quiz_master/next/apps/quiz_app/assets/quizipedia/music_learning.json) such as `"staff"` (`"─────\n─────\n─────\n─────\n─────"`, 5 lines) and meters (`"4\n4"`, `"3\n4"`, `"6\n8"`, 2 lines), as well as long tempo strings (`"Accelerando"`, `"Ritardando"`, `"2× / ÷2"`), wrap/overflow vertically outside the `56px` `ListTile.leading` slot.
- **Reproduction**:
  - Open `/quizipedia/music` on Pitch (`pitch`), Rhythm (`rhythm`), or Tempo (`tempo`) tabs and inspect the `ListTile` rows (`Key('music-item-c4')`, `Key('music-item-staff')`, `Key('music-item-meter_4_4')`, `Key('music-item-accelerando')`).
- **Fix Direction**:
  - Render [`_MusicPainter`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/music_learning.dart#L264-L318) at its native `const Size(260, 156)` inside a `FittedBox(fit: BoxFit.contain, child: SizedBox(width: 260, height: 156, child: CustomPaint(...)))` (with `clipBehavior: Clip.hardEdge` on the outer `Container`), and wrap the `visual['text']` child in `FittedBox(fit: BoxFit.scaleDown)` when `compact` is true.

---

#### 3. [`quizipedia.dart`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/quizipedia.dart) / [`country_learning.dart`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/country_learning.dart): Country Atlas "Flags" map layer (`_layer == 'flag'`) no longer renders flags on the map
- **Location**:
  - [`CountryAtlasPage`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/country_learning.dart#L781) ([lines 781, 1263, 1352](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/country_learning.dart#L1260-L1264))
  - [`QuizipediaWorldMap.showFlags`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/quizipedia.dart#L1945) and [`_QuizipediaWorldMapState._factLabels`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/quizipedia.dart#L2137-L2185)
- **Problem**:
  - `CountryAtlasPage` includes `'flag'` in the `Key('atlas-map-layer')` segmented button ([country_learning.dart:1352](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/country_learning.dart#L1352)) and passes `showFlags: _layer == 'flag'` to [`QuizipediaWorldMap`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/country_learning.dart#L1263).
  - In [review-ui.diff](file:///E:/Projects/quiz_master/.run/feedback_20261019/review-ui.diff#L1275-L1294), the `if (widget.showFlags)` branch inside [`_QuizipediaWorldMapState._factLabels`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/quizipedia.dart#L2160-L2180) was removed and replaced with a plain `Text(label)` chip. As a result, `widget.showFlags` on [`QuizipediaWorldMap`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/quizipedia.dart#L1945) is now completely unused, and selecting the **Flags / Флаги** layer in `/geography/countries` renders plain country names identically to the Countries layer.
- **Reproduction**:
  - Open `/geography/countries`, select the `Flags` (`Флаги`) segment in `Key('atlas-map-layer')` → map pins show only text country names instead of flags.
- **Fix Direction**:
  - Either render a compact flag preview (e.g., [`CountryFlagImage`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/country_learning.dart#L472-L545) / `assets/quizipedia/flag-${feature.id.toLowerCase()}.png` or flag + code) when `widget.showFlags` is true in [`_factLabels`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/quizipedia.dart#L2160-L2180), or if removing map flag pins was intentional, remove the dead `'flag'` map-layer segment and unused `showFlags` parameter.

---

### Verified Requirements & Non-Issues

- **Privacy & Feedback Capture ([`feedback.dart`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/feedback.dart))**:
  - `_attach = true` defaults screenshot attachment to ON ([line 228](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/feedback.dart#L228)) with an explicit opt-out `CheckboxListTile` (`Key('feedback-attach-screenshot')`, [lines 320-332](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/feedback.dart#L320-L332)).
  - Operator view (`/feedback`) hides the floating action button ([line 59](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/feedback.dart#L59)) and guards `_openFeedback` with an early return ([line 155](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/feedback.dart#L155)).
  - Join routes (`/join/...`) never capture a screenshot (`_ allowsScreenshotCapture` returns `false` at [line 108](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/feedback.dart#L108), and `_openFeedback` passes `screenshotPng: null` and hides the checkbox when `screenshotPng == null`).
- **Immediate Local Fact Answer Checks ([`fact_practice.dart`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/fact_practice.dart), [`country_learning.dart`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/country_learning.dart))**:
  - Tapping an option in [`_FactPracticeSectionState._selectAnswer`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/fact_practice.dart#L194-L219) and [`_CountryPracticePanelState._selectAnswer`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/country_learning.dart#L1728-L1755) immediately grades the answer, locks option buttons (`_checked ? null : ...`), records mistakes once, and reveals the next-question button without a separate "Check answer" click.
- **Mobile Map Usability & No Click Auto-Zoom ([`quizipedia.dart`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/quizipedia.dart), [`country_learning.dart`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/country_learning.dart))**:
  - Selecting a country from the directory or tapping a polygon updates `_selectedId` without calling `_zoomToFeature`, preserving the user's current pan/zoom viewport while still providing an explicit `Key('atlas-focus-selected')` action in the detail sheet when focusing is desired.
- **195 Local SVG Flags (`next/apps/quiz_app/web/flags/*.svg`)**:
  - [`CountryFlagImage`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/country_learning.dart#L472-L545) resolves `flags/<code>.svg` cleanly to `assets/quizipedia/flag-<code>.png` in Flutter asset bundles while keeping all 195 SVG files available under `web/flags/`.
- **Compact Library Without Round Lists & Persistent Bottom Navigation ([`discovery.dart`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/discovery.dart), [`main.dart`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/main.dart))**:
  - `DiscoveryPage` enables `showNavigation: true` on `SourceScaffold` and renders compact pack cards that launch directly on tap without round button grids.
- **Server Question Shuffling & Answer Integrity ([`service.go`](file:///E:/Projects/quiz_master/next/server/internal/attempts/service.go), [`sqlite/attempts.go`](file:///E:/Projects/quiz_master/next/server/internal/sqlite/attempts.go), [`sqlite/collection.go`](file:///E:/Projects/quiz_master/next/server/internal/sqlite/collection.go))**:
  - Both in-memory [`Service.StartQuiz`](file:///E:/Projects/quiz_master/next/server/internal/attempts/service.go#L118-L133) and SQLite [`Store.StartQuiz`](file:///E:/Projects/quiz_master/next/server/internal/sqlite/attempts.go#L48-L63) partition rounds first via [`SliceQuizRound`](file:///E:/Projects/quiz_master/next/server/internal/attempts/rules.go#L169-L202) and then shuffle via [`ShuffleQuestions`](file:///E:/Projects/quiz_master/next/server/internal/attempts/rules.go#L228-L240) on a cloned slice, preserving disjoint round membership, answer keys, and deterministic replay of persisted attempt snapshots.

---

### Non-Blocking Observations / Nits

1. **Redundant `SingleChildScrollView` inside `ListView` in [`_OrganAtlasPageState._browse`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/organ_atlas.dart#L302-L355)**:
   - When `wide` is `false` ([line 356](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/organ_atlas.dart#L356)), `_browse(...)` is placed inside a parent `ListView`, so wrapping `_browse` in a vertical `SingleChildScrollView` ([line 302](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/organ_atlas.dart#L302)) is redundant on narrow viewports (the inner scroll view shrinks-wraps inside the outer `ListView`). Making only the `wide` branch wrap `_browse` in `SingleChildScrollView` avoids nested vertical scrollables.
