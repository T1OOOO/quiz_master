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
flutter build web --release --no-pub --no-wasm-dry-run --dart-define=QM_API_BASE_URL=https://quiz.kotopedia.org --dart-define=QM_BUILD_ID=map-prototype-20261028
```

Serve `build/web` with a static HTTP server and open the same hash route.
The inline map style and GeoJSON are local. The package's Web engine currently
loads pinned JavaScript/CSS from its default CDN; this is not an offline acceptance.

## Runtime checks

Search for France, select the result, wait for camera animation to finish and
check the flag markers and numeric area context. Open side Layers, toggle water
and capitals/flags off and back on. Close the country card and tap another
country; tapping sea should clear selection. Check a narrow mobile viewport and
a desktop viewport, then return with Back. Check new browser errors separately
from stale errors left by a prior debug session.

On Web, `featureTapsTriggersMapClick` is required because interactive country
fills otherwise consume clicks before `onMapClick`. Flag PNGs are normalized to
8-bit RGBA because palette PNG decoding otherwise fails when registering sprites.

Android requires its own real-device/emulator checks. A successful Web build
or desktop browser screenshot is not Android evidence.
