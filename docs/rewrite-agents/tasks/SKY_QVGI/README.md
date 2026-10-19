# SKY_QVGI — constellation interaction

`ConstellationAtlasPage` is a touch-first J2000 constellation explorer. It
uses the existing 88-record `QuizipediaCatalog.constellations` data and does
not claim that its connecting lines are IAU boundaries or a live sky view.

The page provides searchable RU/EN constellation selection, previous/next
navigation, pinch/pan and focal double-tap zoom, visible zoom/reset controls,
line and label toggles, and both direct-star tapping and an accessible list of
star buttons. The selected pattern has a short catalog explanation and a link
to its credited data source. Its caller supplies the existing recognition
training route through `trainingBuilder`.

Focused verification:

```text
flutter test test/constellation_atlas_test.dart  # 3 passed
flutter analyze lib/constellation_atlas.dart test/constellation_atlas_test.dart  # No issues found
```

The integration owner imports `constellation_atlas.dart` and replaces the old
sky route with `ConstellationAtlasPage(catalog: catalog, challenge: challenge,
trainingBuilder: ...)`.
