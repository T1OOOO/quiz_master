I will begin the read-only review of `MUSIC_GRRT` by reading the task documentation (`PACKET.md` and `fact-review.md`), data assets (`music_learning.json` and `country_culture.json`), implementation files, and test files using `view_file`.
### Independent Review Verdict — `MUSIC_GRRT`

- **Requirements Verdict:** **APPROVE**
- **Code Quality Verdict:** **APPROVE**

---

### Scoped Evidence Read (Read-Only)

All 10 target files were read directly via `view_file` without directory enumeration, broad searches, edits, or command execution:

1. [PACKET.md](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/MUSIC_GRRT/PACKET.md#L1-L12)
2. [fact-review.md](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/MUSIC_GRRT/fact-review.md#L1-L174)
3. [music_learning.dart](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/music_learning.dart#L1-L663)
4. [country_learning.dart](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/country_learning.dart#L1-L1716)
5. [quizipedia.dart](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/quizipedia.dart#L1-L2531)
6. [music_flow_test.dart](file:///E:/Projects/quiz_master/next/apps/quiz_app/test/music_flow_test.dart#L1-L225)
7. [music_learning_test.dart](file:///E:/Projects/quiz_master/next/apps/quiz_app/test/music_learning_test.dart#L1-L26)
8. [country_culture_test.dart](file:///E:/Projects/quiz_master/next/apps/quiz_app/test/country_culture_test.dart#L1-L113)
9. [music_learning.json](file:///E:/Projects/quiz_master/next/apps/quiz_app/assets/quizipedia/music_learning.json#L1-L2138)
10. [country_culture.json](file:///E:/Projects/quiz_master/next/apps/quiz_app/assets/quizipedia/country_culture.json#L1-L387)

---

### Requirement-by-Requirement Verification

1. **Sourced RU/EN Music Foundation Reference & Schema Validation**
   - [music_learning.json](file:///E:/Projects/quiz_master/next/apps/quiz_app/assets/quizipedia/music_learning.json#L1-L2138) conforms to `qm-music-learning/v1` with 33 `https` sources (including the repaired `performance` Open Music Theory URL and specific UNESCO records `dombra-source`, `tango-source`, `aitysh-source`, `bagpipe-source` required by [fact-review.md](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/MUSIC_GRRT/fact-review.md#L143-L173)), 95 bilingual RU/EN entries across all 9 required categories (`notes`, `notation`, `rhythm`, `dynamics`, `tempo`, `technique`, `harmony`, `instruments`, `world`), and 28 four-option questions with balanced answer index distribution (7 each at indices 0, 1, 2, 3).
   - [`MusicCatalog.fromJson`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/music_learning.dart#L152-L185) strictly validates schema version, non-empty strings, unique IDs, `https` URLs, calendar-valid ISO `checked_on` dates ([`MusicSource`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/music_learning.dart#L72-L89)), valid category keys ([`MusicEntry`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/music_learning.dart#L91-L106)), visual bounds ([`_visual`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/music_learning.dart#L56-L70)), and complete referential integrity for `source_ids` and `option_ids`.
   - Detail sheets ([`_details`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/music_learning.dart#L379-L412)) render both language names, visual notation, description, example, and external source links with `checked_on` dates ([`_sources`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/music_learning.dart#L363-L378)).

2. **Option ID Mapping, Finite Local Practice, No Double Score, and Mistake Retry Score Retention**
   - **Option ID mapping:** [`MusicQuestion`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/music_learning.dart#L126-L144) enforces 4 unique `optionIds` containing `correctId`, and [`MusicCatalog.fromJson`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/music_learning.dart#L175-L179) verifies every option ID exists in `entries`. In [`_quiz`](file:///E:/Projects/quiz_app/next/apps/quiz_app/lib/music_learning.dart#L607-L620), each shuffled option ID binds to `Key('music-option-$id')`, sets `_choice = id`, and displays `_catalog!.entries[id]!.name(_ru)`.
   - **No double score:** Once `Check` (`Key('music-check')`) is pressed ([lines 622-636](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/music_learning.dart#L622-L636)), `_checked` becomes `true`, option buttons are disabled (`onPressed: _checked ? null : ...`, [line 612](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/music_learning.dart#L612)), and the `Check` button is replaced by `Next` (`Key('music-next')`).
   - **Score retained on mistake retry:** [`_startRound`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/music_learning.dart#L345-L361) sets `_retry = mistakes != null` and only resets `_score = 0` and `_total = _round.length` when `!_retry`. During retry, [`_quiz`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/music_learning.dart#L629-L633) does not increment `_score` (`if (!_retry) _score++`) and displays the retention notice at round completion ([lines 559-565](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/music_learning.dart#L559-L565)). Verified by widget test in [music_flow_test.dart](file:///E:/Projects/quiz_master/next/apps/quiz_app/test/music_flow_test.dart#L99-L141).

3. **Filters Retain Distractors**
   - [`_available`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/music_learning.dart#L340-L343) filters questions by whether `q.correctId` is in the filtered `_visible` entry set, while [`_startRound`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/music_learning.dart#L347-L350) preserves all 4 `q.optionIds` from the question definition regardless of category/search filter. Verified by [music_flow_test.dart](file:///E:/Projects/quiz_master/next/apps/quiz_app/test/music_flow_test.dart#L142-L162).

4. **Bravura Glyph Placement & Note Positions (C4–B4)**
   - [`_MusicPainter.glyph`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/music_learning.dart#L239-L251) lays out the SMuFL character in `fontFamily: 'Bravura'` and subtracts `text.computeDistanceToActualBaseline(TextBaseline.alphabetic)` from `origin.dy`, aligning the SMuFL `y = 0` baseline accurately to `origin.dy`.
   - In [`_MusicPainter.paint`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/music_learning.dart#L258-L273):
     - The 5-line staff is drawn at `y = 40, 52, 64, 76, 88` (staff space = `12` px; 4 spaces = `48` px = `1 em` at `fontSize: 48`).
     - Treble clef (`0xE050`) is placed at `y = 76` (second line from bottom, G4).
     - Note vertical coordinate `y = 100.0 - note * 6` places `note = 0` (C4) at `y = 100` with a ledger line from `x = 130..158`, `note = 1` (D4) at `y = 94` (below first line), `note = 2` (E4) at `y = 88` (first line), `note = 3` (F4) at `y = 82` (first space), `note = 4` (G4) at `y = 76` (second line), `note = 5` (A4) at `y = 70` (second space), and `note = 6` (B4) at `y = 64` (third/middle line), with SMuFL `noteheadBlack` (`0xE0A4`) and upward stem `(147, y) -> (147, y - 36)`.

5. **Loading/Retry, Mobile List Accessibility, and Honest Coverage**
   - **Loading & Retry:** [`_load`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/music_learning.dart#L313-L331) and [`build`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/music_learning.dart#L428-L450) handle loading spinner, error message, and retry via `FilledButton(onPressed: _load, ...)`.
   - **Mobile Accessibility:** Uses a single scrollable `ListView` with `isExpanded: true` dropdowns and `Semantics(label: label, image: true, child: ExcludeSemantics(...))` on [`MusicVisual`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/music_learning.dart#L197-L233) so practice questions announce `'Music notation to identify'` / `'Нотный пример для определения'` ([lines 599-605](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/music_learning.dart#L599-L605)) without leaking the answer. Tested at `360x800` with `TextScaler.linear(1.6)` in [music_flow_test.dart](file:///E:/Projects/quiz_master/next/apps/quiz_app/test/music_flow_test.dart#L164-L223).
   - **No False Complete Coverage:** Explicit scope disclaimers are rendered in [`MusicLearningPage._reference`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/music_learning.dart#L464-L469) and [`CountryAtlasPage.build`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/country_learning.dart#L1166-L1175).

6. **Country Instrument/Culture Layers, Search, Details, Fair Shared Traditions, Direct Music Routes, and Camera Preservation**
   - [country_learning.dart](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/country_learning.dart#L626-L629) loads `assets/quizipedia/country_culture.json`, exposes `instrument` and `culture` in the map layer selector ([lines 1140-1141](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/country_learning.dart#L1140-L1141)) and training topic picker ([lines 1001-1003](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/country_learning.dart#L1001-L1003), [1272-1273](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/country_learning.dart#L1272-L1273)), and matches association names in search ([lines 752-753](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/country_learning.dart#L752-L753)).
   - Reverse association questions in [`CountryQuestion.associations`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/country_learning.dart#L379-L404) exclude all countries sharing the same `(kind, nameEn)` from `distractors`, ensuring shared traditions (`Tango` in `AR`/`UY`, `Aitysh / Aitys` in `KZ`/`KG`) never appear as false distractors ([country_culture_test.dart](file:///E:/Projects/quiz_master/next/apps/quiz_app/test/country_culture_test.dart#L10-L56)).
   - Selecting a country from search chips or the map updates `_selected` and `_focus` without setting `focusTarget` on [`QuizipediaWorldMap`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/country_learning.dart#L1226-L1246), preserving the user's manual `TransformationController` matrix ([country_culture_test.dart](file:///E:/Projects/quiz_master/next/apps/quiz_app/test/country_culture_test.dart#L58-L111)).
   - Tapping an `instrument` or `culture` row in country details ([country_learning.dart](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/country_learning.dart#L1496-L1504)) navigates to `MusicLearningPage(bundle: widget.bundle, initialEntryId: row.id)`, which opens the entry detail modal sheet after loading ([music_learning.dart](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/music_learning.dart#L322-L327)).

---

### Non-Blocking Findings

1. **`LOW` — Direct route `initialEntryId` auto-sheet behavior has no dedicated widget test assertion**
   - **Location:** [country_learning.dart](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/country_learning.dart#L1496-L1504), [music_learning.dart](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/music_learning.dart#L322-L327), [music_flow_test.dart](file:///E:/Projects/quiz_master/next/apps/quiz_app/test/music_flow_test.dart#L80-L98)
   - **Detail:** `music_flow_test.dart` verifies that every `country_culture.json` row ID exists in `MusicCatalog.entries`, and `MusicLearningPage` opens `_details(initial)` via `addPostFrameCallback` when `initialEntryId != null && !widget.training`. Adding a small widget test assertion that pumping `MusicLearningPage(initialEntryId: 'koto')` (or tapping the country detail row) opens the detail sheet would directly lock in the deep-link UI contract.

2. **`LOW` — Unused notation and orchestra source definitions duplicated in `country_culture.json`**
   - **Location:** [country_culture.json](file:///E:/Projects/quiz_master/next/apps/quiz_app/assets/quizipedia/country_culture.json#L2-L135)
   - **Detail:** `country_culture.json` copies all 33 source definitions from `music_learning.json`, including 22 Western notation and orchestral instrument sources (`notation` through `piano-source`) not referenced by any country association row in `country_culture.json`. This is benign, but trimming `country_culture.json` `sources` to the 11 referenced world/culture source IDs would reduce duplication.

---

### Unresolved Limits

- Per task constraints, this review was strictly **read-only** over the 10 scoped files. No `flutter test`, `dart analyze`, release builds, font binary inspection (`Bravura.otf`), or live browser/Android UI checks were executed in this review session; root test/analyze/build/browser verification remains separate.
