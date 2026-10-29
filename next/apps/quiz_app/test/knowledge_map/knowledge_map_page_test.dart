import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:quiz_app/knowledge_map/knowledge_map_page.dart';
import 'package:quiz_app/knowledge_map/map_state.dart';

class MapFixtureBundle extends CachingAssetBundle {
  bool fail = false;
  bool missingRiverDetail = false;
  bool missingLakeDetail = false;
  String? invalidLakeDetail;
  final requested = <String>[];
  bool missingInterestingFacts = false;
  bool withFlags = false;
  Completer<void>? factsGate;
  @override
  Future<ByteData> load(String key) async {
    requested.add(key);
    if (key.endsWith('lakes_detail.geojson') && invalidLakeDetail != null) {
      final content = invalidLakeDetail == 'json'
          ? '{'
          : invalidLakeDetail == 'geometry'
          ? jsonEncode({
              'type': 'FeatureCollection',
              'features': [
                {
                  'type': 'Feature',
                  'geometry': {
                    'type': 'Point',
                    'coordinates': [0, 0],
                  },
                },
              ],
            })
          : jsonEncode({'type': 'Feature', 'features': []});
      return ByteData.sublistView(Uint8List.fromList(utf8.encode(content)));
    }
    if (key.endsWith('country_interesting_facts.json') && factsGate != null) {
      await factsGate!.future;
    }
    if (fail ||
        (missingRiverDetail && key.endsWith('rivers_detail.geojson')) ||
        (missingLakeDetail && key.endsWith('lakes_detail.geojson')) ||
        (missingInterestingFacts &&
            key.endsWith('country_interesting_facts.json'))) {
      throw const FormatException('broken test asset');
    }
    final Object data;
    if (key.endsWith('country_waters.json')) {
      data = {
        'countries': {
          'FR': [
            {
              'name_en': 'Test sea',
              'name_ru': 'Тестовое море',
              'source_id': 'water',
            },
          ],
        },
        'sources': [
          {'id': 'water', 'url': 'https://example.org/water'},
        ],
      };
    } else if (key.endsWith('food_atlas.json')) {
      data = {
        'dishes': [
          {
            'name_en': 'Test dish',
            'name_ru': 'Тестовое блюдо',
            'country_en': 'France',
            'source_ids': ['food'],
          },
        ],
        'sources': [
          {'id': 'food', 'url': 'https://example.org/food'},
        ],
      };
    } else if (key.endsWith('map_feature_facts.json')) {
      data = {
        'capitals': {
          'capital-paris': [
            {
              'text_ru': 'Факт о Париже',
              'text_en': 'Paris fact',
              'source_url': 'https://example.org/paris',
            },
          ],
        },
        'waterways': {
          'Q1062': [
            {
              'text_ru': 'Факт об Онтарио',
              'text_en': 'Ontario fact',
              'source_url': 'https://example.org/ontario',
            },
          ],
        },
      };
    } else if (key.endsWith('country_interesting_facts.json')) {
      data = {
        'countries': {
          'FR': [
            {
              'text_en': 'First France fact',
              'text_ru': 'Первый факт о Франции',
              'source_url': 'https://example.org/one',
            },
            {
              'text_en': 'Second France fact',
              'text_ru': 'Второй факт о Франции',
              'source_url': 'https://example.org/two',
            },
            {
              'text_en': 'Third France fact',
              'text_ru': 'Третий факт о Франции',
              'source_url': 'https://example.org/three',
            },
          ],
        },
      };
    } else if (key.endsWith('country_facts.json')) {
      data = {
        'countries': [
          {
            'id': 'FR',
            'capital': 'Paris',
            'region': 'Europe',
            'subregion': 'Central Europe',
            'area_km2': 551695,
            'population': 68000000,
            'population_year': 2024,
            'currencies': ['EUR'],
            'languages': ['French', 'Unknown language'],
          },
        ],
      };
    } else if (key.endsWith('country_flag_images.json')) {
      data = {
        'flags': withFlags
            ? {
                'FR': 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jRZkAAAAASUVORK5CYII=',
              }
            : <String, String>{},
      };
    } else if (key.endsWith('landmarks.geojson')) {
      data = {
        'type': 'FeatureCollection',
        'features': [
          {
            'type': 'Feature',
            'id': 'eiffel',
            'geometry': {
              'type': 'Point',
              'coordinates': [2.3, 48.8],
            },
            'properties': {
              'id': 'eiffel',
              'country_id': 'FR',
              'name_en': 'Eiffel Tower',
              'name_ru': 'Эйфелева башня',
              'explanation_en': 'A landmark in Paris.',
              'explanation_ru': 'Памятник Парижа.',
              'source_url': 'https://example.org/source',
              'coordinate_source_url': 'https://example.org/location',
              'thumbnail_asset': 'assets/example.png',
              'image_attribution': 'Photographer',
              'image_license': 'CC BY',
              'image_source_url': 'https://example.org/image',
              'image_license_url': 'https://example.org/licence',
            },
          },
        ],
      };
    } else if (key.endsWith('waterways.geojson')) {
      data = {
        'type': 'FeatureCollection',
        'features': [
          {
            'type': 'Feature',
            'properties': {
              'id': 'Q1062',
              'kind': 'lake',
              'name_en': 'Ontario',
              'name_ru': 'Онтарио',
            },
            'geometry': {'type': 'Polygon', 'coordinates': []},
          },
        ],
      };
    } else if (key.endsWith('country_labels.geojson')) {
      data = {
        'type': 'FeatureCollection',
        'features': [
          {
            'type': 'Feature',
            'id': 'FR',
            'properties': {
              'country_id': 'FR',
              'name_ru': 'Франция',
              'name_en': 'France',
            },
            'geometry': {
              'type': 'Point',
              'coordinates': [2.0, 48.0],
            },
          },
          {
            'type': 'Feature',
            'id': 'MC',
            'properties': {
              'country_id': 'MC',
              'name_ru': 'Монако',
              'name_en': 'Monaco',
            },
            'geometry': {
              'type': 'Point',
              'coordinates': [7.4, 43.7],
            },
          },
        ],
      };
    } else {
      data = {
        'type': 'FeatureCollection',
        'features': key.endsWith('countries.geojson')
            ? [
                {
                  'type': 'Feature',
                  'id': 'FR',
                  'properties': {
                    'country_id': 'FR',
                    'name_ru': 'Франция',
                    'name_en': 'France',
                  },
                  'geometry': {'type': 'Polygon', 'coordinates': []},
                },
              ]
            : [],
      };
    }
    return ByteData.sublistView(
      Uint8List.fromList(utf8.encode(jsonEncode(data))),
    );
  }
}

void main() {
  test(
    'failed country source update does not commit the thematic mode',
    () async {
      var applied = 'none';
      await expectLater(
        commitCountryLabelsUpdate(
          update: () async => throw StateError('source unavailable'),
          commit: () => applied = 'population',
        ),
        throwsStateError,
      );
      expect(applied, 'none');
      await commitCountryLabelsUpdate(
        update: () async {},
        commit: () => applied = 'population',
      );
      expect(applied, 'population');
    },
  );

  test('symbol fade is disabled only when requested for a map', () {
    expect(MapLibreMap().disableSymbolPlacementFade, isFalse);
    expect(
      MapLibreMap(disableSymbolPlacementFade: true).disableSymbolPlacementFade,
      isTrue,
    );
  });

  test('thematic population and area use rounded labels', () {
    expect(
      thematicNumberLabel(68551653, russian: true, area: false),
      '≈ 69 млн',
    );
    expect(
      thematicNumberLabel(551695, russian: true, area: true),
      '≈ 550 тыс. км²',
    );
    expect(thematicNumberLabel(null, russian: true, area: true), 'Нет данных');
  });
  test(
    'capital thematic value uses capital and locale, tolerating missing data',
    () {
      const france = MapCountry(
        id: 'FR',
        nameRu: 'Франция',
        nameEn: 'France',
        capital: 'Paris',
      );
      expect(capitalThematicLabel(france, russian: false), 'Paris');
      expect(capitalThematicLabel(france, russian: true), 'Париж');
      expect(capitalThematicLabel(null, russian: true), isNull);
    },
  );
  for (final size in [const Size(320, 480), const Size(390, 844)]) {
    testWidgets('countries control is accessible at $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: KnowledgeMapPage.test(
            bundle: MapFixtureBundle(),
            visibleCountryIds: const ['FR'],
            mapBuilder: (context, select) => const SizedBox.expand(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final countries = tester.getRect(find.text('Countries'));
      expect(
        countries.overlaps(tester.getRect(find.byTooltip('Zoom out'))),
        isFalse,
      );
      expect(
        countries.overlaps(tester.getRect(find.text('Visible countries'))),
        isFalse,
      );
      await tester.tap(find.text('Countries'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Close'), findsOneWidget);
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Close'), findsNothing);
    });
  }
  testWidgets('country panel resizes the same map and closing restores it', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    late void Function(String?) select;
    var builds = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: KnowledgeMapPage.test(
          bundle: MapFixtureBundle(),
          mapBuilder: (context, callback) {
            select = callback;
            builds++;
            return const SizedBox(
              key: ValueKey('map-area'),
              width: double.infinity,
              height: double.infinity,
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    final mapElement = tester.element(find.byKey(const ValueKey('map-area')));
    final before = tester.getSize(find.byKey(const ValueKey('map-area')));
    select('FR');
    await tester.pumpAndSettle();
    final after = tester.getSize(find.byKey(const ValueKey('map-area')));
    expect(
      tester.element(find.byKey(const ValueKey('map-area'))),
      same(mapElement),
    );
    expect(after.height, lessThan(before.height));
    expect(
      tester.getRect(find.byKey(const ValueKey('map-area'))).bottom,
      tester.getRect(find.byKey(const ValueKey('country-bottom-panel'))).top,
    );
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byKey(const ValueKey('map-area'))), before);
    expect(
      tester.element(find.byKey(const ValueKey('map-area'))),
      same(mapElement),
    );
    expect(builds, greaterThan(0));
  });

  testWidgets('country panel can be resized and docked beside the map', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    late void Function(String?) select;
    await tester.pumpWidget(
      MaterialApp(
        home: KnowledgeMapPage.test(
          bundle: MapFixtureBundle(),
          mapBuilder: (context, callback) {
            select = callback;
            return const SizedBox.expand(key: ValueKey('map-area'));
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    select('FR');
    await tester.pumpAndSettle();
    final map = find.byKey(const ValueKey('map-area'));
    final height = tester.getSize(map).height;
    await tester.drag(
      find.byKey(const ValueKey('country-panel-resize')),
      const Offset(0, -90),
    );
    await tester.pumpAndSettle();
    expect(tester.getSize(map).height, lessThan(height));
    await tester.tap(find.byTooltip('Move panel to side'));
    await tester.pumpAndSettle();
    expect(tester.getSize(map).height, 600);
    expect(tester.getSize(map).width, lessThan(800));
    expect(
      tester.getRect(find.byTooltip('Zoom in')).right,
      lessThanOrEqualTo(tester.getRect(map).right),
    );
    expect(
      tester.getRect(find.byType(TextField)).right,
      lessThanOrEqualTo(tester.getRect(map).right),
    );
    expect(
      tester.getRect(map).right,
      tester.getRect(find.byKey(const ValueKey('country-bottom-panel'))).left,
    );
    await tester.tap(find.byTooltip('Move panel to bottom'));
    await tester.pumpAndSettle();
    expect(tester.getSize(map).width, 800);
    expect(tester.getSize(map).height, lessThan(height));
  });

  testWidgets('practice checks a map selection and can be exited', (
    tester,
  ) async {
    late void Function(String?) select;
    await tester.pumpWidget(
      MaterialApp(
        home: KnowledgeMapPage.test(
          bundle: MapFixtureBundle(),
          mapBuilder: (context, callback) {
            select = callback;
            return const SizedBox.expand();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Practice'));
    await tester.pumpAndSettle();
    expect(find.text('Find the country on the map'), findsOneWidget);
    select('MC');
    await tester.pumpAndSettle();
    expect(find.text('Try again'), findsOneWidget);
    select('FR');
    await tester.pumpAndSettle();
    expect(find.text('Correct!'), findsOneWidget);
    await tester.tap(find.byType(DropdownButton<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Map → name').last);
    await tester.pumpAndSettle();
    expect(find.text('Which country is outlined?'), findsOneWidget);
    await tester.tap(find.widgetWithText(OutlinedButton, 'France'));
    await tester.pumpAndSettle();
    expect(find.text('Correct!'), findsOneWidget);
    await tester.tap(find.byTooltip('Exit practice'));
    await tester.pumpAndSettle();
    expect(find.text('Find the country on the map'), findsNothing);
  });

  testWidgets('flag practice works in both directions', (tester) async {
    late void Function(String?) select;
    await tester.pumpWidget(
      MaterialApp(
        home: KnowledgeMapPage.test(
          bundle: MapFixtureBundle()..withFlags = true,
          mapBuilder: (context, callback) {
            select = callback;
            return const SizedBox.expand();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Practice'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButton<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Flag → map').last);
    await tester.pumpAndSettle();
    select('FR');
    await tester.pumpAndSettle();
    expect(find.text('Correct!'), findsOneWidget);
    await tester.tap(find.byType(DropdownButton<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Map → flag').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(OutlinedButton).last);
    await tester.pumpAndSettle();
    expect(find.text('Correct!'), findsOneWidget);
  });

  testWidgets('late map selection after page disposal is ignored', (
    tester,
  ) async {
    late void Function(String?) select;
    await tester.pumpWidget(
      MaterialApp(
        home: KnowledgeMapPage.test(
          bundle: MapFixtureBundle(),
          mapBuilder: (context, callback) {
            select = callback;
            return const SizedBox.expand();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
    final errors = <Object>[];
    await tester.runAsync(() async {
      await runZonedGuarded(() async {
        select('FR');
        await Future<void>.delayed(Duration.zero);
      }, (error, stack) => errors.add(error));
    });
    expect(errors, isEmpty);
  });
  testWidgets('search selection dismisses keyboard and accepts another query', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: KnowledgeMapPage.test(
          bundle: MapFixtureBundle(),
          mapBuilder: (context, select) => const SizedBox.expand(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'France');
    await tester.pump();
    expect(tester.testTextInput.isVisible, isTrue);
    await tester.tap(find.byType(ListTile).first);
    await tester.pumpAndSettle();
    expect(tester.testTextInput.isVisible, isFalse);
    expect(find.textContaining('Capital: Paris'), findsOneWidget);
    expect(find.textContaining('Area: ≈ 550 thousand'), findsOneWidget);
    expect(
      find.textContaining('Population (2024): ≈ 68 million'),
      findsOneWidget,
    );
    expect(find.text('Currency: EUR'), findsOneWidget);
    expect(find.text('Languages: French, Unknown language'), findsOneWidget);
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Capital:'), findsNothing);
    await tester.enterText(find.byType(TextField), 'Monaco');
    await tester.pump();
    await tester.tap(find.byType(ListTile).first);
    await tester.pumpAndSettle();
    expect(find.text('Monaco'), findsOneWidget);
    expect(tester.testTextInput.isVisible, isFalse);
  });
  testWidgets('thematic panel offers data without hiding base map features', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: KnowledgeMapPage.test(
          bundle: MapFixtureBundle(),
          mapBuilder: (context, select) => const SizedBox.expand(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Layers'));
    await tester.pumpAndSettle();
    expect(find.text('Population'), findsOneWidget);
    expect(find.text('Area'), findsOneWidget);
    await tester.tap(find.text('Capital'));
    await tester.pump();
    expect(
      tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Capital'))
          .selected,
      isTrue,
    );
    await tester.tap(find.text('Dishes'));
    await tester.pump();
    expect(
      tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Dishes'))
          .selected,
      isTrue,
    );
    await tester.tap(find.text('Population'));
    await tester.pump();
    await tester.tap(find.text('Dishes'));
    await tester.pump();
    expect(
      tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Dishes'))
          .selected,
      isTrue,
    );
    expect(find.text('Country labels'), findsNothing);
    expect(find.text('Capitals'), findsNothing);
  });
  testWidgets('hover never duplicates selected country context', (
    tester,
  ) async {
    late void Function(String?, Offset) hover;
    late VoidCallback leave;
    late void Function(String?) select;
    await tester.pumpWidget(
      MaterialApp(
        home: KnowledgeMapPage.test(
          bundle: MapFixtureBundle(),
          mapBuilder: (context, select) => const SizedBox.expand(),
          hoverMapBuilder: (context, selectCountry, onHover, onExit) {
            hover = onHover;
            leave = onExit;
            select = selectCountry;
            return const SizedBox.expand();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    select('FR');
    hover('FR', const Offset(790, 590));
    await tester.pump();
    expect(find.text('France'), findsOneWidget);
    expect(find.textContaining('Capital: Paris'), findsOneWidget);
    leave();
    await tester.pump();
    expect(find.text('France'), findsOneWidget);
    expect(find.textContaining('Capital: Paris'), findsOneWidget);
  });
  testWidgets('marker-only country is searchable without a hover tooltip', (
    tester,
  ) async {
    late void Function(String?, Offset) hover;
    await tester.pumpWidget(
      MaterialApp(
        home: KnowledgeMapPage.test(
          bundle: MapFixtureBundle(),
          mapBuilder: (context, select) => const SizedBox.expand(),
          hoverMapBuilder: (context, select, onHover, onExit) {
            hover = onHover;
            return const SizedBox.expand();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    hover('MC', const Offset(100, 100));
    await tester.pump();
    expect(find.text('Monaco'), findsNothing);
    await tester.enterText(find.byType(TextField), 'Monaco');
    await tester.pump();
    expect(find.byType(ListTile), findsOneWidget);
  });
  testWidgets(
    'landmark selection shows details and attribution on a narrow screen',
    (tester) async {
      tester.view.physicalSize = const Size(320, 500);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      late void Function(String?) select;
      late void Function(String?, Offset) hover;
      await tester.pumpWidget(
        MaterialApp(
          home: KnowledgeMapPage.test(
            bundle: MapFixtureBundle(),
            mapBuilder: (context, select) => const SizedBox.expand(),
            landmarkMapBuilder: (context, onSelect, onHover) {
              select = onSelect;
              hover = onHover;
              return const SizedBox.expand();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      hover('eiffel', const Offset(300, 480));
      await tester.pump();
      expect(find.text('Eiffel Tower'), findsNothing);
      select('eiffel');
      hover(null, Offset.zero);
      await tester.pumpAndSettle();
      expect(find.text('Eiffel Tower'), findsOneWidget);
      expect(find.textContaining('Photographer'), findsOneWidget);
      expect(find.text('Source'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      expect(find.text('Eiffel Tower'), findsNothing);
    },
  );
  testWidgets('bottom layers control and country card fit a narrow viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    late void Function(String?) select;
    await tester.pumpWidget(
      MaterialApp(
        home: KnowledgeMapPage.test(
          bundle: MapFixtureBundle(),
          mapBuilder: (context, callback) {
            select = callback;
            return const SizedBox.expand();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.getBottomLeft(find.byTooltip('Layers')).dy, greaterThan(400));
    select('FR');
    await tester.pump();
    expect(find.byKey(const ValueKey('country-bottom-panel')), findsOneWidget);
    expect(
      tester.getRect(find.byKey(const ValueKey('country-bottom-panel'))).bottom,
      480,
    );
    final close = tester.getRect(find.byTooltip('Close'));
    expect(close.top, greaterThanOrEqualTo(0));
    expect(close.bottom, lessThanOrEqualTo(480));
    await tester.tap(find.byTooltip('Layers'));
    await tester.pumpAndSettle();
    expect(find.text('Population'), findsOneWidget);
    expect(find.text('Rivers and lakes'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'visible countries and layers stay usable with a mobile detail card',
    (tester) async {
      WidgetController.hitTestWarningShouldBeFatal = true;
      addTearDown(() => WidgetController.hitTestWarningShouldBeFatal = false);
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      late void Function(String?) select;
      await tester.pumpWidget(
        MaterialApp(
          home: KnowledgeMapPage.test(
            bundle: MapFixtureBundle(),
            visibleCountryIds: const ['FR'],
            mapBuilder: (context, callback) {
              select = callback;
              return const SizedBox.expand();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      select('FR');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Visible countries'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(ListTile, 'France'), findsOneWidget);
      await tester.tap(find.byTooltip('Layers'));
      await tester.pumpAndSettle();
      expect(find.text('Population'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'search selection shows its card while visible countries list is open',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: KnowledgeMapPage.test(
            bundle: MapFixtureBundle(),
            visibleCountryIds: const ['FR'],
            mapBuilder: (context, select) => const SizedBox.expand(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Visible countries'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'France');
      await tester.pumpAndSettle();
      await tester.tap(
        find.ancestor(of: find.text('FR'), matching: find.byType(ListTile)),
      );
      await tester.pumpAndSettle();
      expect(find.byTooltip('Close'), findsOneWidget);
      expect(find.widgetWithText(ListTile, 'France'), findsNothing);
    },
  );
  testWidgets(
    'visible countries and detail controls remain tappable at 320 by 480',
    (tester) async {
      WidgetController.hitTestWarningShouldBeFatal = true;
      addTearDown(() => WidgetController.hitTestWarningShouldBeFatal = false);
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      late void Function(String?) select;
      await tester.pumpWidget(
        MaterialApp(
          home: KnowledgeMapPage.test(
            bundle: MapFixtureBundle(),
            visibleCountryIds: const ['FR'],
            mapBuilder: (context, callback) {
              select = callback;
              return const SizedBox.expand();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      select('FR');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Visible countries'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, 'France'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Source 1'));
      expect(find.text('Source 1').hitTestable(), findsOneWidget);
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Layers'));
      await tester.pumpAndSettle();
      expect(find.text('Population'), findsOneWidget);
    },
  );
  testWidgets(
    'landmark card remains usable on 390 by 844 at larger text size',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      late void Function(String?) select;
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.5)),
            child: child!,
          ),
          home: KnowledgeMapPage.test(
            bundle: MapFixtureBundle(),
            mapBuilder: (context, select) => const SizedBox.expand(),
            landmarkMapBuilder: (context, onSelect, onHover) {
              select = onSelect;
              return const SizedBox.expand();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      select('eiffel');
      await tester.pumpAndSettle();
      expect(find.text('Eiffel Tower'), findsOneWidget);
      expect(find.textContaining('Photographer'), findsOneWidget);
      final close = tester.getRect(find.byTooltip('Close'));
      expect(close.top, greaterThanOrEqualTo(0));
      expect(close.bottom, lessThanOrEqualTo(844));
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      expect(find.text('Eiffel Tower'), findsNothing);
    },
  );
  testWidgets('missing detailed lakes keeps the map usable', (tester) async {
    final bundle = MapFixtureBundle()..missingLakeDetail = true;
    await tester.pumpWidget(
      MaterialApp(
        home: KnowledgeMapPage.test(
          bundle: bundle,
          mapBuilder: (context, select) => const SizedBox.expand(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      bundle.requested,
      contains('assets/quizipedia/map_v2/lakes_detail.geojson'),
    );
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Map unavailable'), findsNothing);
  });

  for (final invalid in ['json', 'type', 'geometry']) {
    testWidgets('invalid detailed lakes $invalid keeps the map usable', (
      tester,
    ) async {
      final bundle = MapFixtureBundle()..invalidLakeDetail = invalid;
      await tester.pumpWidget(
        MaterialApp(
          home: KnowledgeMapPage.test(
            bundle: bundle,
            mapBuilder: (context, select) => const SizedBox.expand(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Map unavailable'), findsNothing);
    });
  }

  testWidgets('missing detailed rivers keeps the map usable', (tester) async {
    final bundle = MapFixtureBundle()..missingRiverDetail = true;
    await tester.pumpWidget(
      MaterialApp(
        home: KnowledgeMapPage.test(
          bundle: bundle,
          mapBuilder: (context, select) => const SizedBox.expand(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      bundle.requested,
      contains('assets/quizipedia/map_v2/rivers_detail.geojson'),
    );
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Map unavailable'), findsNothing);
  });

  testWidgets(
    'country card shows sourced facts, scrolls, and omits section when absent',
    (tester) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      late void Function(String?) select;
      await tester.pumpWidget(
        MaterialApp(
          home: KnowledgeMapPage.test(
            bundle: MapFixtureBundle(),
            mapBuilder: (context, callback) {
              select = callback;
              return const SizedBox.expand();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      select('FR');
      await tester.pumpAndSettle();
      expect(find.text('Eiffel Tower'), findsOneWidget);
      expect(find.text('Landmarks'), findsOneWidget);
      expect(find.text('Test sea'), findsOneWidget);
      expect(find.text('Test dish'), findsOneWidget);
      expect(find.text('Water source: Test sea'), findsOneWidget);
      expect(find.text('Dish source: Test dish'), findsOneWidget);
      final material = tester.widget<Material>(
        find
            .descendant(
              of: find.byKey(const ValueKey('country-bottom-panel')),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(material.color!.computeLuminance(), greaterThan(0.8));
      expect(find.text('Interesting facts'), findsOneWidget);
      expect(find.text('First France fact'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('First France fact')).dy,
        lessThan(tester.getTopLeft(find.textContaining('Area:')).dy),
      );
      expect(find.byKey(const ValueKey('fact-source-0')), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Third France fact'),
        120,
        scrollable: find.descendant(
          of: find.byKey(const ValueKey('country-bottom-panel')),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.getBottomLeft(find.text('Third France fact')).dy,
        lessThan(480),
      );
      select('MC');
      await tester.pumpAndSettle();
      expect(find.text('Interesting facts'), findsNothing);
      expect(find.text('First France fact'), findsNothing);
    },
  );

  testWidgets('country facts follow Russian locale', (tester) async {
    late void Function(String?) select;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        supportedLocales: const [Locale('en'), Locale('ru')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: KnowledgeMapPage.test(
          bundle: MapFixtureBundle(),
          mapBuilder: (context, callback) {
            select = callback;
            return const SizedBox.expand();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    select('FR');
    await tester.pumpAndSettle();
    expect(find.text('Столица: Париж'), findsOneWidget);
    expect(find.text('Языки: французский, Unknown language'), findsOneWidget);
    expect(find.text('Валюта: EUR'), findsOneWidget);
    expect(find.text('Интересные факты'), findsOneWidget);
    expect(find.text('Первый факт о Франции'), findsOneWidget);
    expect(find.text('Источник 1'), findsOneWidget);
    expect(find.text('Регион: Европа · Центральная Европа'), findsOneWidget);
    expect(find.text('First France fact'), findsNothing);
  });

  testWidgets('late facts load after disposal does not update the page', (
    tester,
  ) async {
    final gate = Completer<void>();
    final bundle = MapFixtureBundle()..factsGate = gate;
    await tester.pumpWidget(
      MaterialApp(
        home: KnowledgeMapPage.test(
          bundle: bundle,
          mapBuilder: (context, select) => const SizedBox.expand(),
        ),
      ),
    );
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    gate.complete();
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Russian layers label fits the mobile panel', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        supportedLocales: const [Locale('en'), Locale('ru')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: KnowledgeMapPage.test(
          bundle: MapFixtureBundle(),
          mapBuilder: (context, select) => const SizedBox.expand(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Слои'));
    await tester.pumpAndSettle();
    expect(find.text('Население'), findsOneWidget);
    expect(tester.getSize(find.text('Население')).height, lessThan(30));
    expect(find.text('Достопримечательности'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('missing facts asset shows retry and recovers', (tester) async {
    final bundle = MapFixtureBundle()..missingInterestingFacts = true;
    await tester.pumpWidget(
      MaterialApp(
        home: KnowledgeMapPage.test(
          bundle: bundle,
          mapBuilder: (context, select) => const SizedBox.expand(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Map unavailable'), findsOneWidget);
    bundle.missingInterestingFacts = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
  });
  testWidgets('broken assets show retry and recover when repaired', (
    tester,
  ) async {
    final bundle = MapFixtureBundle()..fail = true;
    await tester.pumpWidget(
      MaterialApp(
        home: KnowledgeMapPage.test(
          bundle: bundle,
          mapBuilder: (context, select) => const SizedBox.expand(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Map unavailable'), findsOneWidget);
    bundle.fail = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Map unavailable'), findsNothing);
  });
  testWidgets('capital and water selections show their own details', (
    tester,
  ) async {
    late void Function(String, Map<String, dynamic>) selectFeature;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: KnowledgeMapPage.test(
          bundle: MapFixtureBundle(),
          mapBuilder: (context, select) => const SizedBox.expand(),
          featureMapBuilder: (context, select) {
            selectFeature = select;
            return const SizedBox.expand();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    selectFeature('capital', {
      'id': 'capital-paris',
      'name_en': 'Paris',
      'name_ru': 'Париж',
      'country_id': 'FR',
    });
    await tester.pumpAndSettle();
    expect(find.text('Paris'), findsOneWidget);
    final card = tester.widget<Material>(
      find
          .ancestor(of: find.text('Paris'), matching: find.byType(Material))
          .first,
    );
    expect(card.color!.computeLuminance(), greaterThan(0.8));
    expect(find.text('Capital · France'), findsOneWidget);
    expect(find.text('Paris fact'), findsOneWidget);
    expect(find.text('Source'), findsOneWidget);
    selectFeature('lake', {
      'id': 'Q1062',
      'name_en': 'Ontario',
      'name_ru': 'Онтарио',
    });
    await tester.pumpAndSettle();
    expect(find.text('Ontario'), findsOneWidget);
    expect(find.text('Lake'), findsOneWidget);
    expect(find.text('Paris'), findsNothing);
    expect(find.text('Paris fact'), findsNothing);
    selectFeature('lake', {
      'id': 'ne10-lake-1',
      'water_id': 'Q1062',
      'kind': 'lake',
    });
    await tester.pumpAndSettle();
    expect(find.text('Ontario'), findsOneWidget);
    expect(find.text('Ontario fact'), findsOneWidget);
    selectFeature('river', {'id': 'ne10-river-1', 'kind': 'river'});
    await tester.pumpAndSettle();
    expect(find.text('Unnamed feature'), findsOneWidget);
    expect(find.text('River'), findsOneWidget);
    expect(find.text('Source'), findsNothing);
  });
}
