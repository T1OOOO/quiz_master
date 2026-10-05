# Quizipedia renderer handoff

Task `quiz_master-1x6.2`; renderer escalation 2026-10-05. Owned files:
`next/apps/quiz_app/lib/quizipedia.dart` and
`next/apps/quiz_app/test/quizipedia_test.dart`.

The standalone Quizipedia page now loads the v1 catalog strictly and offers
Explore and local unranked Challenge for all four modules. Challenge samples
up to ten unique targets per round, keeps four named or neutral numbered
options, requires Check after selection, shows the correct answer and its own
explanation, advances after feedback, blocks repeat scoring, and has a final
score and restart. Map and anatomy alternate their two directions across a
round; landmarks alternate landmark and city questions. No API repository or
attempt code is used.

The map paints all country polygons with even-odd holes and tests child-local
tap coordinates against actual rings. Background countries may be selected as
wrong answers; ocean clears selection. The endocrine diagram is decoded from
the bundled image, painted in the catalog aspect ratio, and has numbered
image-aligned spots and numbered alternatives; overlapping tap radii open a
choice sheet. Landmark photos must decode successfully before question
controls appear, with Retry and Exit on failure. Constellations draw catalog
lines and stars with a shared-scale J2000 RA/Dec projection, RA increasing
left; Explore and post-answer tap reveal star name and magnitude. Visuals have
pan, zoom and reset. The credits dialog opens both source and license links.

The test file contains geometry, projection, strict loader, no-repeat/scoring,
both map and anatomy direction, missing photo, and narrow text-scale fixtures.
After the independent code review, it also exercises the production map
through an actual `InteractiveViewer` zoom and pan against a known polygon,
hole and ocean, and directly asserts a correct answer increments score only
once.
The renderer and test source were parsed and formatted with `dart format`.
`flutter test`, `flutter analyze`, web/Android runtime checks and builds are
**NOT_RUN** by this worker because the host resource grant was not supplied
to this worker. The integration owner should run from `next/apps/quiz_app`:

```powershell
& 'C:\Users\Alexey_Matvienko\dev\flutter\bin\flutter.bat' test test/quizipedia_test.dart
& 'C:\Users\Alexey_Matvienko\dev\flutter\bin\flutter.bat' analyze
```

The root owns pubspec/route/drawer, actual catalog/assets, factual/source
review and integrated gates. This worker did not commit, push, or edit those
paths.
