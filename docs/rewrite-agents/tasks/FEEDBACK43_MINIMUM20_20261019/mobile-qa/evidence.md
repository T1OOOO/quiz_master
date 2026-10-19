# Minimum-20 mobile visual QA (local static web70)

- **Surface:** `http://127.0.0.1:8791`; Chrome emulation only, session `feedback43_nav`.
- **Build scope:** root supplied the clean web70 static output. The compiled application still targets production API69, so no quiz attempt, practice feedback, alias route, or candidate grader was invoked here.
- **Viewports:** 390×844 and 360×800 CSS pixels. No physical phone was available.

## Evidence

- `screenshots/03-library-390.png`: Russian root catalog shows `Викторин: 105 · вопросов: 4520`; category cards, difficulty chips and bottom navigation fit without visible horizontal overflow.
- `screenshots/04-search-cheese-390.png` and `05-search-cheese-360.png`: `сыр` resolves the merged canonical title **«Продукты животного происхождения: сыры, мясо и рыба»**, with 32 questions. The one-result card remains readable/actionable at both widths.
- `screenshots/06-quizipedia-390.png`: Quizipedia landing cards are legible and do not overlap the bottom navigation. It exposes the section list used by the static visual sweep.
- `screenshots/07-countries-390.png`, `08-countries-scroll-390.png`, and `10-countries-360.png`: Country Atlas labels, filter controls, map, zoom/fit controls and Russian pan/pinch/double-tap instructions remain visible. The 360px view still retains a usable map and 48px-scale controls; no automatic zoom or clipped toolbar was observed.

## Result

PASS for the bounded static web70 visual surface above. No visible overflow, overlap, or console/runtime error was observed during these screens. This is not evidence that release70 is published or that its API is live: API69 was deliberately not exercised. The all-13-section interaction sweep could not be completed through Flutter canvas semantics without triggering training/navigation actions; only landing-section visibility and the Country Atlas static/gesture UI were observed.