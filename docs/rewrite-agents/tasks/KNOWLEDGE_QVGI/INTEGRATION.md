# QVGI integration — 2026-10-19

The Quizipedia menu now opens country, constellation, world-history, culture,
and people learning screens. New data contains 44 history events, 30 works and
39 people, with reciprocal creator and actor-role connections. The culture
sequence includes films, books, opera, oratorio, ballet, plays and music.
History explains what happened, why it mattered and what followed. Ancient
and composition dates retain approximate/range metadata in both languages.

Country selection and search preserve the camera; only the user's zoom,
gesture, reset and explicit focus controls move it. Switchable map annotations
show flags, capitals, currencies, population, area, major waters, resources and
neighbours. Labels represent country associations, not precise water/resource
coordinates. Labels avoid overlap and more become visible when zooming.
Neighbour chips change the selected country. Population/area comparisons sort
in either direction. Reverse relation quizzes exclude every country recorded
with the same relation from distractors. Search includes associated rivers,
clubs, resources and other facts. Country population details show actual 2024
snapshot figures; practice uses bands. Official-language coverage now includes
Canada and Singapore with their government sources (21 curated entities).

Constellations have search, previous/next, pinch/pan, focal double-tap, explicit
zoom/reset, name/line toggles, star hit testing at the actual phone canvas size,
an accessible star list, source information and recognition practice.

Validation evidence: `flutter-tests.log`, `flutter-analyze.log`, `web-build.log`.
The shared checkout's full test suite passed 156 tests. Independent code review
is `code-review.md`; factual corrections and sampled source verification are
`fact-review.md`. Phone browser screenshots cover country flag layers,
rank sorting and constellations in `../SKY_QVGI/`; history, film and actor details
are in this folder. Dart hot reload succeeded and runtime errors were empty.

The existing unrelated discovery, backend, content and legacy-deletion work
was preserved. The pre-existing DiscoveryPage assertion in quizipedia_test.dart
is excluded from this change's staged version. The map fixture now explicitly
isolates four holed polygons for its geometric test; the synthetic background
entity cannot randomly become its target. The explorer test scrolls the map
into view before tapping because the new controls precede it.

Limits: this is a curated learning corpus, not an exhaustive encyclopedia.
Country association/president coverage remains partial. Historical/cultural
sources are attached per record, rather than per individual claim. No physical
Android device, signed Android build or production deployment was tested.
