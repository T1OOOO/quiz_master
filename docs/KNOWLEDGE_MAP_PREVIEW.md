# Knowledge map prototype

Plan and ownership: [KNOWLEDGE_MAP_PLAN_RU.md](KNOWLEDGE_MAP_PLAN_RU.md).

## Reproduce

From the repository root:

```sh
python scripts/build_knowledge_map.py
python -m unittest discover -s scripts -p test_build_knowledge_map.py
```

From `next/apps/quiz_app`:

```sh
flutter pub get
flutter test --no-pub test/knowledge_map test/knowledge_map_route_test.dart
flutter analyze --no-pub lib/knowledge_map lib/main.dart test/knowledge_map test/knowledge_map_route_test.dart
flutter run -d chrome --dart-define=QM_API_BASE_URL=https://quiz.kotopedia.org
```

Navigate to `#/atlas/map-preview`. This is a separate route without global
bottom navigation. The existing map remains the default.

For a release build:

```sh
flutter build web --release --no-pub --no-wasm-dry-run --dart-define=QM_API_BASE_URL=https://quiz.kotopedia.org --dart-define=QM_BUILD_ID=map-detail-20261028
```

Serve `build/web` with a static HTTP server and open the same hash route.
The inline map style and GeoJSON are local. The package's Web engine currently
loads pinned JavaScript/CSS from its default CDN; this is not an offline acceptance.

## Runtime checks

Search for France, select the result, wait for camera animation to finish and
check flag/name markers and numeric area context. Open the lower Layers panel
and toggle country names, water names, capitals and landmarks. River and lake
geometry stays visible. Move across countries: their boundaries are highlighted
without a duplicate tooltip; click selection remains independent.
Moving onto sea or the search controls must clear the hover outline.
For the native event regression, search Monaco, zoom in until its marker is
visible, hover that marker, then move once to the French land nearby and stop.
The outline must move to France without a second pointer move.
Feature-leave events must not cancel the pending map-mousemove query.
Close the country card and tap another
country; tapping sea should clear selection. Check a narrow mobile viewport and
a desktop viewport, then return with Back. Check new browser errors separately
from stale errors left by a prior debug session.

The marker layer contains 243 country/territory anchors and 239 country shapes.
Native collision detection hides overlapping labels until
zooming in. Country polygons have separate selected and hovered outlines.
Montserrat's existing capital point incorrectly identifies Plymouth, England;
that capital is excluded, while its country now has a verified 1:10m polygon
and country label at Montserrat.

## Detailed map increment

This data increment uses pinned Natural Earth 1:10m country polygons and
physical river and lake layers. From zoom 4, 3,739 river features and 1,355 lake
and reservoir polygons replace the overview water geometry without doubling it.
Below zoom 4 the overview remains visible. No names or Wikidata identities are
inferred for the additional physical network. The generator adds
`water_labels.geojson` with point anchors on river lines or inside lake polygons.
If a detailed water asset cannot be loaded or decoded as a nonempty feature
collection, or its layer cannot be installed, the corresponding overview water
geometry stays visible at every zoom instead of hiding that layer.

`quizipedia/landmark_locations.geojson` records coordinates for the 46 existing
catalog landmarks. Coordinates were read from non-deprecated terrestrial
Wikidata P625 statements; each item's P17 country was checked against P297 ISO2.
Existing names, descriptions, local thumbnails and image credits are retained.
Each point carries its coordinate source and the existing official fact source.
Coordinate data is CC0; media retains its per-image license.

Country cards show the available population and its reference year, currencies
and languages from the existing registry. `country_interesting_facts.json`
contains a first reviewed set of bilingual facts for 20 countries, each with a
source link. Countries without a reviewed fact simply omit that section; further
coverage is tracked in `quiz_master-6vig`.

Check capital dot/name toggling together, zoom-dependent river/lake names,
landmark markers and their optional layer. Open a landmark by clicking its
marker and verify its localized description, photo attribution and source.
Check country outlines when moving the pointer and narrow-screen scrolling.
Capital labels begin at zoom 4, river/lake labels at zoom 3, and landmarks at
zoom 4. Capital labels anchor above their points and landmark labels below,
so nearby features such as Paris and the Eiffel Tower can be distinguished.
Landmark pins are painted directly, without relying on optional font glyphs.
Rivers and lakes always remain visible; their point labels use native collision
placement. Turning off capitals hides their dots and names together.

When checking a rebuilt static preview at the same URL, use a fresh browser
session or a hard reload: ordinary reloads can retain the previous dynamically
loaded `main.dart.js` in the browser HTTP cache.

On Web, `featureTapsTriggersMapClick` is required because interactive country
fills otherwise consume clicks before `onMapClick`. Flag PNGs are normalized to
8-bit RGBA because palette PNG decoding otherwise fails when registering sprites.

Android requires its own real-device/emulator checks. A successful Web build
or desktop browser screenshot is not Android evidence.
