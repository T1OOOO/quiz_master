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
  testWidgets('search selects a country and close clears its context', (
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
    await tester.tap(find.byType(ListTile).first);
    await tester.pumpAndSettle();
    expect(find.textContaining('Capital: Paris'), findsOneWidget);
    expect(find.textContaining('Area: 551695'), findsOneWidget);
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Capital:'), findsNothing);
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
}
