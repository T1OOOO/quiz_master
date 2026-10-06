import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quiz_app/main.dart';
import 'package:quiz_app/quizipedia.dart';

void main() {
  testWidgets(
    'real Quizipedia route returns to the library and drawer reopens it',
    (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              discoveryCatalogProvider.overrideWith(
                (ref) async => [
                  const CatalogPack(
                    'example',
                    'Example',
                    'Example',
                    'General',
                    20,
                  ),
                ],
              ),
            ],
            child: const QuizApp(
              initialLocation: '/quizipedia',
              defaultLocale: Locale('en'),
            ),
          ),
        );
        final builder = tester.widget<FutureBuilder<QuizipediaCatalog>>(
          find.byWidgetPredicate(
            (widget) => widget is FutureBuilder<QuizipediaCatalog>,
          ),
        );
        await builder.future!.timeout(const Duration(seconds: 5));
      });
      await tester.pumpAndSettle();
      expect(find.text('Quizipedia'), findsOneWidget);
      await tester.tap(find.text('World map and flags'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('quizipedia-map')), findsOneWidget);
      await tester.ensureVisible(find.text('Exit'));
      await tester.tap(find.text('Exit'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Quiz library'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('catalog-search')), findsOneWidget);
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await tester.tap(find.text('Quizipedia'));
        await tester.pump();
        await tester.pump();
        final builder = tester.widget<FutureBuilder<QuizipediaCatalog>>(
          find.byWidgetPredicate(
            (widget) => widget is FutureBuilder<QuizipediaCatalog>,
          ),
        );
        await builder.future!.timeout(const Duration(seconds: 5));
      });
      await tester.pumpAndSettle();
      expect(find.text('World map and flags'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  const feature = QuizipediaFeature(
    id: 'country:test',
    nameRu: 'Тест',
    nameEn: 'Test',
    polygons: [
      [
        [
          QuizipediaPoint(0, 0),
          QuizipediaPoint(1, 0),
          QuizipediaPoint(1, 1),
          QuizipediaPoint(0, 1),
        ],
        [
          QuizipediaPoint(.3, .3),
          QuizipediaPoint(.7, .3),
          QuizipediaPoint(.7, .7),
          QuizipediaPoint(.3, .7),
        ],
      ],
      [
        [
          QuizipediaPoint(2, 2),
          QuizipediaPoint(3, 2),
          QuizipediaPoint(3, 3),
          QuizipediaPoint(2, 3),
        ],
      ],
    ],
  );

  test('polygon hit testing preserves holes and multipart features', () {
    expect(feature.contains(const QuizipediaPoint(.1, .1)), isTrue);
    expect(feature.contains(const QuizipediaPoint(.5, .5)), isFalse);
    expect(feature.contains(const QuizipediaPoint(2.5, 2.5)), isTrue);
    expect(feature.contains(const QuizipediaPoint(1.5, 1.5)), isFalse);
  });

  test('scene conversion applies the inverse transform once', () {
    expect(
      scenePoint(
        const QuizipediaPoint(30, 50),
        scale: 2,
        translation: const QuizipediaPoint(10, 20),
      ),
      const QuizipediaPoint(10, 15),
    );
  });

  test(
    'session randomizes unique targets, has four choices, and scores once',
    () {
      final session = QuizipediaSession([
        'a',
        'b',
        'c',
        'd',
        'e',
      ], (correct) => ['a', 'b', 'c', 'd', 'e']);
      final seen = <String>{};
      while (true) {
        expect(seen.add(session.current), isTrue);
        expect(session.options.length, 4);
        expect(session.options.where((id) => id == session.current).length, 1);
        expect(session.submit('wrong'), isFalse);
        expect(session.submit(session.current), isFalse);
        if (session.finished) break;
        session.next();
      }
      expect(seen.length, 5);
      expect(session.score, 0);
      session.restart();
      expect(session.score, 0);
      expect(session.seen, hasLength(1));
      final correct = session.current;
      expect(session.submit(correct), isTrue);
      expect(session.score, 1);
      expect(session.submit(correct), isFalse);
      expect(session.score, 1);
      session.restart();
      expect(session.score, 0);
    },
  );

  test('catalog validates references, unique IDs and numeric bounds', () {
    final valid = fixture();
    expect(QuizipediaCatalog.fromJson(valid).mapTargetIds, hasLength(4));
    expect(
      () => QuizipediaCatalog.fromJson({
        ...valid,
        'map_target_ids': ['missing'],
      }),
      throwsFormatException,
    );
    final countries = (valid['countries'] as List).cast<Map<String, dynamic>>();
    expect(
      () => QuizipediaCatalog.fromJson({
        ...valid,
        'countries': [
          {...countries.first, 'difficulty_level': 11},
          ...countries.skip(1),
        ],
      }),
      throwsFormatException,
    );
    expect(
      () => QuizipediaCatalog.fromJson({
        ...valid,
        'countries': [...countries, countries.first],
      }),
      throwsFormatException,
    );
    expect(
      () => QuizipediaCatalog.fromJson({
        ...valid,
        'anatomy': {
          ...valid['anatomy'] as Map<String, dynamic>,
          'credit_id': 'missing',
        },
      }),
      throwsFormatException,
    );
    final landmarks = (valid['landmarks'] as List).cast<Map<String, dynamic>>();
    expect(
      () => QuizipediaCatalog.fromJson({
        ...valid,
        'landmarks': [
          {...landmarks.first, 'image_asset': ''},
          ...landmarks.skip(1),
        ],
      }),
      throwsFormatException,
    );
    final stars = (valid['constellations'] as List)
        .cast<Map<String, dynamic>>();
    expect(
      () => QuizipediaCatalog.fromJson({
        ...valid,
        'constellations': [
          {
            ...stars.first,
            'lines': [
              ['a', 'missing'],
            ],
          },
          ...stars.skip(1),
        ],
      }),
      throwsFormatException,
    );
  });

  test(
    'J2000 projection unwraps RA and uses one scale with RA increasing left',
    () {
      final points = projectConstellation([
        {
          'id': 'east',
          'ra_hours': 0.2,
          'dec_degrees': 0,
          'magnitude': 1,
          'name': 'East',
        },
        {
          'id': 'west',
          'ra_hours': 23.8,
          'dec_degrees': 0,
          'magnitude': 1,
          'name': 'West',
        },
        {
          'id': 'north',
          'ra_hours': 0.2,
          'dec_degrees': 1,
          'magnitude': 1,
          'name': 'North',
        },
        {
          'id': 'far',
          'ra_hours': 1.2,
          'dec_degrees': 0,
          'magnitude': 1,
          'name': 'Far',
        },
      ], const Size(400, 400));
      expect(points['east']!.dx, lessThan(points['west']!.dx));
      expect(
        (points['east']!.dx - points['west']!.dx).abs(),
        lessThan((points['east']!.dx - points['far']!.dx).abs()),
      );
      expect(points['north']!.dy, lessThan(points['east']!.dy));
    },
  );

  testWidgets('map challenge has a check step and no revealed correct answer', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: QuizipediaPage(bundle: _Bundle(fixture()))),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Training'));
    await tester.tap(find.text('World map and flags'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Training · local unranked'), findsOneWidget);
    expect(find.text('Correct answer'), findsNothing);
    expect(find.byKey(const Key('quizipedia-map')), findsOneWidget);
    expect(find.text('Check'), findsOneWidget);
    await tester.ensureVisible(find.text('Spot 1'));
    await tester.tap(find.text('Spot 1'));
    await tester.pump();
    await tester.ensureVisible(find.text('Check'));
    await tester.tap(find.text('Check'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('quizipedia-feedback')), findsOneWidget);
    await tester.ensureVisible(find.text('Next'));
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Which country is highlighted?'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('transformed production map respects polygon holes and ocean', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: QuizipediaPage(bundle: _Bundle(fixture()))),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Training'));
    await tester.tap(find.text('World map and flags'));
    await tester.pumpAndSettle();

    final prompt = tester
        .widget<Text>(find.textContaining('Tap the country for this flag:'))
        .data!;
    final targetIndex = _mapFlags.indexWhere(prompt.contains);
    expect(targetIndex, greaterThanOrEqualTo(0));
    final left = .04 + .23 * targetIndex;
    final viewport = find.byKey(const Key('quizipedia-viewport'));
    await tester.ensureVisible(find.byTooltip('Zoom in'));
    await tester.tap(find.byTooltip('Zoom in'));
    await tester.pumpAndSettle();
    final controller = tester
        .widget<InteractiveViewer>(viewport)
        .transformationController!;
    expect(controller.value.storage[0], greaterThan(1));
    await tester.ensureVisible(viewport);
    await tester.pumpAndSettle();
    final pan = await tester.startGesture(tester.getCenter(viewport));
    await pan.moveBy(Offset(targetIndex < 2 ? 25 : -25, 0));
    await tester.pump();
    await pan.moveBy(Offset(targetIndex < 2 ? 25 : -25, 0));
    await tester.pump();
    // The first drag distance starts the gesture instead of panning the map.
    // Pan toward the tested country to keep its ring and hole in view.
    await pan.moveBy(Offset(targetIndex < 2 ? 25 : -25, 0));
    await pan.up();
    await tester.pumpAndSettle();
    expect(controller.value.storage[12], isNot(0));

    Future<void> tapScene(double x, double y) async {
      final size = tester.getSize(find.byKey(const Key('quizipedia-map')));
      final box = tester.renderObject<RenderBox>(
        find.byKey(const Key('quizipedia-map')),
      );
      await tester.tapAt(
        box.localToGlobal(Offset(x * size.width, y * size.height)),
      );
      await tester.pump();
    }

    FilledButton check() =>
        tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Check'));
    await tapScene(left + .025, .23); // Within the target's outer ring.
    expect(check().onPressed, isNotNull);
    await tapScene(left + .09, .31); // Inside its closed hole.
    expect(check().onPressed, isNull);
    await tapScene(left + .025, .23);
    expect(check().onPressed, isNotNull);
    await tapScene(left + .025, .58); // Ocean, outside every feature.
    expect(check().onPressed, isNull);
    await tapScene(left + .025, .23);
    await tester.ensureVisible(find.text('Check'));
    await tester.tap(find.text('Check'));
    await tester.pumpAndSettle();
    expect(find.text('Correct'), findsOneWidget);
    expect(find.textContaining('Score 1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'explore selects countries outside the training set and search finds them',
    (tester) async {
      final data = fixture();
      (data['countries'] as List).add({
        'id': 'extra-country',
        'name_ru': 'Дополнительная страна',
        'name_en': 'Extra country',
        'polygons': [
          [_rectangle(.12, .65, .23, .8)],
        ],
      });
      tester.view.physicalSize = const Size(361, 682);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(home: QuizipediaPage(bundle: _Bundle(data))),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('World map and flags'));
      await tester.pumpAndSettle();
      final map = find.byKey(const Key('quizipedia-map'));
      final box = tester.renderObject<RenderBox>(map);
      await tester.tapAt(
        box.localToGlobal(Offset(box.size.width * .17, box.size.height * .72)),
      );
      await tester.pump();
      expect(
        tester.widget<Text>(find.byKey(const Key('map-selection-label'))).data,
        'Extra country',
      );
      expect(
        (tester.widget<CustomPaint>(map).painter as dynamic).selected,
        'extra-country',
      );
      await tester.tap(find.byTooltip('Show selected country'));
      await tester.pumpAndSettle();
      final controller = tester
          .widget<InteractiveViewer>(
            find.byKey(const Key('quizipedia-viewport')),
          )
          .transformationController!;
      expect(controller.value.getMaxScaleOnAxis(), greaterThan(1));
      await tester.tap(find.byTooltip('Reset view'));
      await tester.pump();
      expect(controller.value.getMaxScaleOnAxis(), 1);
      await tester.ensureVisible(find.byKey(const Key('map-country-search')));
      await tester.tap(find.byKey(const Key('map-country-search')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Extra');
      await tester.pump();
      expect(find.widgetWithText(ListTile, 'Extra country'), findsOneWidget);
      expect(find.widgetWithText(ListTile, 'Name test0'), findsNothing);
      await tester.tap(find.widgetWithText(ListTile, 'Extra country'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('zoom buttons preserve the gesture scale limits', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: QuizipediaPage(bundle: _Bundle(fixture()))),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('World map and flags'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byTooltip('Zoom in'));
    final controller = tester
        .widget<InteractiveViewer>(find.byKey(const Key('quizipedia-viewport')))
        .transformationController!;
    for (var i = 0; i < 12; i++) {
      await tester.tap(find.byTooltip('Zoom in'));
      await tester.pump();
    }
    expect(controller.value.getMaxScaleOnAxis(), closeTo(6, .000001));
    for (var i = 0; i < 12; i++) {
      await tester.tap(find.byTooltip('Zoom out'));
      await tester.pump();
    }
    expect(controller.value.getMaxScaleOnAxis(), closeTo(1, .000001));
  });

  testWidgets('anatomy directions both reach the check step', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: QuizipediaPage(bundle: _Bundle(fixture()))),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Training'));
    await tester.tap(find.text('Endocrine system'));
    await tester.runAsync(() async {
      await tester.pump();
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('quizipedia-anatomy')), findsOneWidget);
    await tester.ensureVisible(find.text('Check'));
    await tester.tap(find.textContaining('Spot ').first);
    await tester.pump();
    await tester.ensureVisible(find.text('Check'));
    await tester.tap(find.text('Check'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Next'));
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Which gland is highlighted?'), findsOneWidget);
    expect(find.textContaining('Name gland:'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('narrow scaled home scrolls and missing photo blocks questions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: QuizipediaPage(bundle: _Bundle(fixture())),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('World map and flags'), findsOneWidget);
    await tester.ensureVisible(find.text('Landmark photographs'));
    await tester.tap(find.text('Landmark photographs'));
    await tester.pumpAndSettle();
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Check'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

const _mapFlags = ['🇦🇷', '🇧🇷', '🇨🇦', '🇩🇰'];

List<List<double>> _rectangle(
  double left,
  double top,
  double right,
  double bottom,
) => [
  [left, top],
  [right, top],
  [right, bottom],
  [left, bottom],
  [left, top],
];

Map<String, dynamic> fixture() {
  Map<String, dynamic> common(String id) => {
    'id': id,
    'name_ru': 'Название $id',
    'name_en': 'Name $id',
    'difficulty_level': 3,
    'tag_ids': ['topic:test'],
    'explanation_ru': 'Объяснение $id',
    'explanation_en': 'Explanation $id',
    'source_url': 'https://example.org/$id',
  };
  final ids = List.generate(4, (i) => 'test$i');
  return {
    'schema_version': 'qm-quizipedia/v1',
    'credits': [
      {
        'id': 'credit',
        'attribution': 'Test author',
        'source_url': 'https://example.org',
        'license': 'CC BY',
        'license_url': 'https://example.org/license',
      },
    ],
    'countries': [
      for (var i = 0; i < ids.length; i++)
        {
          ...common('country:${ids[i]}'),
          'flag': _mapFlags[i],
          'polygons': [
            [
              _rectangle(.04 + .23 * i, .2, .21 + .23 * i, .42),
              _rectangle(.11 + .23 * i, .28, .15 + .23 * i, .34),
            ],
          ],
        },
      {
        'id': 'country:background',
        'name_ru': 'Фон',
        'name_en': 'Background',
        'polygons': [
          [_rectangle(.92, .2, .99, .42)],
        ],
      },
    ],
    'map_target_ids': [for (final id in ids) 'country:$id'],
    'anatomy': {
      'image_asset': 'assets/missing.png',
      'width': 200,
      'height': 300,
      'credit_id': 'credit',
      'targets': [
        for (var i = 0; i < 4; i++)
          {
            ...common('gland:$i'),
            'hotspots': [
              {'x': .2 + .2 * i, 'y': .2, 'radius': .05},
            ],
          },
      ],
    },
    'landmarks': [
      for (var i = 0; i < 4; i++)
        {
          ...common('landmark:$i'),
          'image_asset': 'assets/missing$i.png',
          'credit_id': 'credit',
          'country_iso2': 'FR',
          'city_ru': 'Город $i',
          'city_en': 'City $i',
        },
    ],
    'constellations': [
      for (var i = 0; i < 4; i++)
        {
          ...common('sky:$i'),
          'credit_id': 'credit',
          'stars': [
            {
              'id': 'a',
              'name': 'Alpha',
              'ra_hours': 1.0,
              'dec_degrees': 2.0,
              'magnitude': 2.0,
            },
            {
              'id': 'b',
              'name': 'Beta',
              'ra_hours': 2.0,
              'dec_degrees': 3.0,
              'magnitude': 3.0,
            },
          ],
          'lines': [
            ['a', 'b'],
          ],
        },
    ],
  };
}

class _Bundle extends CachingAssetBundle {
  _Bundle(this.catalog);
  final Map<String, dynamic> catalog;
  @override
  Future<ByteData> load(String key) async {
    if (key == 'assets/missing.png') {
      return ByteData.sublistView(
        base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAADElEQVR4nGP4//8/AAX+Av4N70a4AAAAAElFTkSuQmCC',
        ),
      );
    }
    if (key != 'assets/quizipedia/catalog.json') {
      throw FlutterError('Missing $key');
    }
    return ByteData.sublistView(
      Uint8List.fromList(utf8.encode(jsonEncode(catalog))),
    );
  }
}
