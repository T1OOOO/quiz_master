# Learning visuals feedback execution

The organ atlas uses `anatomy-orientation.png` as an anterior-orientation backdrop. It is decorative UI, not a factual source. Only the major structures with reviewed screen coordinates receive a selectable marker; other structures remain directly reachable through search and cards with their existing source links.

The numbered callout pagination and crossing connector lines were removed. Horizontal structure cards select a focused visual, while the existing accessible list, filters and search retain complete access to the curated set.

Music reference cards render their structured `visual` data through `MusicVisual` in compact form. Notes, clefs, accidentals, durations and rests therefore use their notation glyphs instead of a shared generic music icon; the detail sheet keeps the larger preview and sources.

Verification: run the focused Flutter atlas, navigation, music and feedback-visual suites from `next/apps/quiz_app`.
