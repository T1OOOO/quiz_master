import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:quiz_app/knowledge_map/knowledge_map_page.dart';

class MapFixtureBundle extends CachingAssetBundle {
  bool fail = false;
  bool missingRiverDetail = false;
  bool missingLakeDetail = false;
  String? invalidLakeDetail;
  final requested = <String>[];
  bool missingInterestingFacts = false;
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
    if (key.endsWith('map_feature_facts.json')) {
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
        'waterways': {},
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
            'area_km2': 551695,
            'population': 68000000,
            'population_year': 2024,
            'currencies': ['EUR'],
            'languages': ['French', 'Unknown language'],
          },
        ],
      };
    } else if (key.endsWith('country_flag_images.json')) {
      data = {'flags': <String, String>{}};
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
    expect(find.textContaining('Area: 551695'), findsOneWidget);
    expect(find.textContaining('Population (2024): 68000000'), findsOneWidget);
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
  testWidgets('layers panel never offers a water visibility switch', (
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
    expect(find.text('Rivers and lakes'), findsNothing);
    expect(find.text('Rivers and lakes are always visible'), findsOneWidget);
    expect(find.text('Capitals'), findsOneWidget);
    expect(find.text('Country labels'), findsOneWidget);
    expect(find.text('Water labels'), findsOneWidget);
    expect(find.text('Landmarks'), findsOneWidget);
    final countrySwitch = find.widgetWithText(SwitchListTile, 'Country labels');
    final waterSwitch = find.widgetWithText(SwitchListTile, 'Water labels');
    expect(tester.widget<SwitchListTile>(countrySwitch).value, isTrue);
    await tester.tap(countrySwitch);
    await tester.pump();
    expect(tester.widget<SwitchListTile>(countrySwitch).value, isFalse);
    expect(tester.widget<SwitchListTile>(waterSwitch).value, isTrue);
    await tester.tap(waterSwitch);
    await tester.pump();
    expect(tester.widget<SwitchListTile>(waterSwitch).value, isFalse);
    await tester.tap(countrySwitch);
    await tester.tap(waterSwitch);
    await tester.pump();
    expect(tester.widget<SwitchListTile>(countrySwitch).value, isTrue);
    expect(tester.widget<SwitchListTile>(waterSwitch).value, isTrue);
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
    final close = tester.getRect(find.byTooltip('Close'));
    expect(close.top, greaterThanOrEqualTo(0));
    expect(close.bottom, lessThanOrEqualTo(480));
    await tester.tap(find.byTooltip('Layers'));
    await tester.pumpAndSettle();
    expect(find.text('Country labels'), findsOneWidget);
    expect(find.text('Rivers and lakes'), findsNothing);
    expect(tester.takeException(), isNull);
  });
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
      expect(find.text('Interesting facts'), findsOneWidget);
      expect(find.text('First France fact'), findsOneWidget);
      expect(find.byKey(const ValueKey('fact-source-0')), findsOneWidget);
      await tester.drag(
        find.byType(SingleChildScrollView).last,
        const Offset(0, -250),
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
    expect(find.text('Интересные места'), findsOneWidget);
    expect(tester.getSize(find.text('Интересные места')).height, lessThan(30));
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
    selectFeature('river', {'id': 'ne10-river-1', 'kind': 'river'});
    await tester.pumpAndSettle();
    expect(find.text('Unnamed feature'), findsOneWidget);
    expect(find.text('River'), findsOneWidget);
    expect(find.text('Source'), findsNothing);
  });
}
