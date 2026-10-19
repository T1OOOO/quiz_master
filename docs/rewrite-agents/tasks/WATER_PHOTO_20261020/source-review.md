### Corrected Final Release Review

- **Requirements Compliance Verdict**: **ACCEPT**
- **Code Quality Verdict**: **ACCEPT**
- **Overall Release Review Verdict**: **ACCEPT**

---

### Scope, Counts & Verified Source Evidence

1. **Waterways Dataset & Model Validation ([`waterways_models.dart:38-156`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/waterways_models.dart#L38-L156), [`build_waterways.py:1-78`](file:///E:/Projects/quiz_master/next/apps/quiz_app/tool/build_waterways.py#L1-L78), [`waterways_test.dart:1-109`](file:///E:/Projects/quiz_master/next/apps/quiz_app/test/waterways_test.dart#L1-L109))**
   - `assets/quizipedia/waterways.json` (`qm-waterways/v1`) bundles **63** Wikidata-backed features (**24** `lake`, **12** `river`, **27** `marine`) from cached Natural Earth 1:110m GeoJSONs in `.run/waterways_20261020`.
   - Duplicate source Wikidata IDs (**`Q97`** Atlantic Ocean, **`Q98`** Pacific Ocean, **`Q5413`** Yangtze) are merged into single multi-part features; polygon holes are preserved via `PathFillType.evenOdd`; marine anchors lie outside country land polygons; river anchors lie on line vertices.
   - `kind: "marine"` is used solely as a neutral cartographic layer; Caspian Sea (`Q5484`) is not taught as a physical salt sea.
   - [`WaterAtlas.fromJson`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/waterways_models.dart#L72-L145) rejects malformed schema/counts, duplicate IDs, non-finite/out-of-range coordinates, unclosed rings, mismatched `river`/polygon kinds, and anchors outside their geometry using the strict default `tolerance = .000001` in [`WaterShape.contains`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/waterways_models.dart#L38-L65).

2. **Four Verified Map & Interaction Fixes ([`quizipedia.dart:2493-3168`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/quizipedia.dart#L2493-L3168), [`country_learning.dart:623-641`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/country_learning.dart#L623-L641), [`waterways_ui_test.dart:34-177`](file:///E:/Projects/quiz_master/next/apps/quiz_app/test/waterways_ui_test.dart#L34-L177))**
   - **Split & polar water focus ([`_focusWater`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/quizipedia.dart#L2493-L2512))**: Focuses the smallest part containing `water.anchor` (preventing antimeridian span on `Q98` and `Q164466`) and clamps full-longitude polar features (`target.width > .6`, e.g. `Q788`, `Q7354`) to a `0.4 × min(0.25, target.height)` region around `anchor`. Selection never auto-zooms the camera.
   - **River tap tolerance ([`QuizipediaWorldMap.build`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/quizipedia.dart#L2795-L2809))**: Non-marine hit-testing passes `tolerance: 6 / (scene.width * widget.controller.value.getMaxScaleOnAxis())` (6 screen pixels) while keeping default `contains` strict.
   - **Selected water paint order & labels ([`_paintWaters`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/quizipedia.dart#L3062-L3119), [`_paintWaterLabels`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/quizipedia.dart#L3121-L3168))**: Selected water draws last within each `marine` (before country land fill) and non-`marine` (after country fill, before country borders) pass. World zoom (`sceneScale < 2.5`) labels only the 5 oceans (`Q97`, `Q98`, `Q1239`, `Q788`, `Q7354`) plus `selectedWater`, using `12 / sceneScale` bold metrics and skipping clipped or overlapping unselected labels.
   - **Mutual state clearing & mobile picker ([`country_learning.dart:623-625`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/country_learning.dart#L623-L625), [`904-908`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/country_learning.dart#L904-L908), [`973-977`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/country_learning.dart#L973-L977), [`1390-1395`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/country_learning.dart#L1390-L1395), [`1481-1485`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/country_learning.dart#L1481-L1485))**: `_selectWater` and all country selection handlers (map tap, search chips, ranking sheet, country list sheet) mutually clear `_selectedWater` and `_selected`/`_focus`. On `320×568` at `1.5×` text scale with `280px` keyboard inset, [`_WaterPicker`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/waterways_page.dart#L39-L93) clamps cleanly without overflow.

3. **Local Water Practice ([`WaterPracticePage`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/waterways_page.dart#L98-L281))**
   - 6 choices, `showWaterLabels: checked` (no pre-check answer leak), manual `Check` (`✓ ` / `✗ ` prefixes), 6 comparison `ActionChip`s, and manual `Next` resetting `scroll.jumpTo(0)` while preserving manual camera state.

4. **Landmark Picker Previews & Country Names ([`photo_thumbnails.dart:1-44`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/photo_thumbnails.dart#L1-L44), [`quizipedia.dart:1583-1745`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/quizipedia.dart#L1583-L1745))**
   - `assets/quizipedia/landmark_thumbnails.json` (`qm-landmark-thumbnails/v1`, **151,158 bytes**, 36 WebP `≤160px` previews; network proof in [`.run/waterways_20261020/preview-network-proof.json`](file:///E:/Projects/quiz_master/.run/waterways_20261020/preview-network-proof.json)) is loaded on demand in [`_pickLandmark`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/quizipedia.dart#L1600-L1745) with retry support, while the 36 flat `assets/quizipedia/*.jpg` photos remain untouched.
   - [`_landmarkCountry`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/quizipedia.dart#L1583-L1593) reads `country_name_ru`/`country_name_en` on the 30 newer landmark rows (resolving `merlion` → `"Сингапур"` / `"Singapore"`) while keeping the original 6 landmarks and other catalog sections unchanged.

---

### Review Limits

- **Source inspection only**: No tests, builds, or renders were executed by this reviewer; root logs in `.run/waterways_20261020/` are not treated as independent test runs.
- **Pending gates**: Final full test suite completion and the separate exact image/public acceptance gate remain pending before release.
