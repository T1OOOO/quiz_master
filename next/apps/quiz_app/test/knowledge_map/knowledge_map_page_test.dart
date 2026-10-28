import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/knowledge_map/knowledge_map_page.dart';

class MapFixtureBundle extends CachingAssetBundle {
  bool fail = false;
  @override
  Future<ByteData> load(String key) async {
    if (fail) throw const FormatException('broken test asset');
    final Object data;
    if (key.endsWith('country_facts.json')) {
      data = {
        'countries': [
          {'id': 'FR', 'capital': 'Paris', 'area_km2': 551695},
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
    expect(find.text('Capitals'), findsOneWidget);
  });
  testWidgets('hover context appears and clears independently of selection', (
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
    expect(find.text('France'), findsNWidgets(2));
    expect(find.textContaining('Capital: Paris'), findsOneWidget);
    leave();
    await tester.pump();
    expect(find.text('France'), findsOneWidget);
    expect(find.textContaining('Capital: Paris'), findsOneWidget);
  });
  testWidgets('marker-only country is searchable and displays hover context', (
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
    expect(find.text('Monaco'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Monaco');
    await tester.pump();
    expect(find.byType(ListTile), findsOneWidget);
  });
  testWidgets(
    'landmark hover and selection show details and attribution on a narrow screen',
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
      expect(find.text('Eiffel Tower'), findsOneWidget);
      expect(find.text('France'), findsOneWidget);
      expect(find.text('A landmark in Paris.'), findsOneWidget);
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
}
