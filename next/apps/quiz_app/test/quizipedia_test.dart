import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quiz_app/main.dart';
import 'package:quiz_app/quizipedia.dart';
import 'package:quiz_app/country_learning.dart';

void main() {
  testWidgets(
    'map feedback teaches loaded facts instead of repeating the task',
    (tester) async {
      final data = fixture();
      final catalog = QuizipediaCatalog.fromJson(data);
      final rows = catalog.countryRows;
      for (final row in rows) {
        row.remove('explanation_en');
        row.remove('explanation_ru');
      }
      await tester.pumpWidget(
        MaterialApp(
          home: quizipediaLocationTraining(
            catalog,
            countryFacts: [
              for (final row in rows)
                CountryFact(
                  id: row['id'] as String,
                  nameEn: 'Example',
                  nameRu: 'Пример',
                  capital: 'Paris',
                  languages: const [],
                  currencies: const [],
                  population: 1,
                  populationYear: 2024,
                  region: 'Europe',
                ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Capital: Paris'), findsNothing);
      await tester.ensureVisible(find.text('Spot 1'));
      await tester.tap(find.text('Spot 1'));
      await tester.pump();
      await tester.ensureVisible(find.text('Check'));
      await tester.tap(find.text('Check'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Capital: Paris'), findsOneWidget);
      expect(find.textContaining('Explanation '), findsNothing);
      expect(
        find.textContaining('Find this country on the world map.'),
        findsNothing,
      );
    },
  );
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
      expect(find.widgetWithText(AppBar, 'Quizipedia'), findsOneWidget);
      await tester.runAsync(() async {
        await tester.tap(find.text('Countries of the world'));
        await tester.pump();
        await Future<void>.delayed(const Duration(milliseconds: 400));
      });
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('quizipedia-map')), findsOneWidget);
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Quiz library'));
      await tester.pumpAndSettle();
      expect(find.byType(DiscoveryPage), findsOneWidget);
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await tester.tap(find.widgetWithText(ListTile, 'Quizipedia'));
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
      expect(find.text('Countries of the world'), findsOneWidget);
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
      MaterialApp(
        home: quizipediaLocationTraining(QuizipediaCatalog.fromJson(fixture())),
      ),
    );
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
    final mapFixture = fixture();
    (mapFixture['countries'] as List).removeWhere(
      (row) => row['id'] == 'country:background',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: quizipediaLocationTraining(
          QuizipediaCatalog.fromJson(mapFixture),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final prompt = tester
        .widget<Text>(find.textContaining(' on the map'))
        .data!;
    final targetIndex = List.generate(
      4,
      (i) => 'Name country:test$i',
    ).indexWhere(prompt.contains);
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
      await tester.pump(const Duration(milliseconds: 350));
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
      await tester.runAsync(() async {
        await tester.tap(find.text('Countries of the world'));
        await tester.pump();
        await Future<void>.delayed(const Duration(milliseconds: 400));
      });
      await tester.pumpAndSettle();
      final map = find.byKey(const Key('quizipedia-map'));
      await tester.ensureVisible(map);
      await tester.pumpAndSettle();
      final box = tester.renderObject<RenderBox>(map);
      await tester.tapAt(
        box.localToGlobal(Offset(box.size.width * .17, box.size.height * .72)),
      );
      await tester.pump(const Duration(milliseconds: 350));
      expect(
        find.descendant(
          of: find.byKey(const Key('country-selected-details')),
          matching: find.text('Extra country'),
        ),
        findsOneWidget,
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
      await tester.pumpAndSettle();
      expect(controller.value.getMaxScaleOnAxis(), 1);
      await tester.enterText(find.byType(TextField), 'Extra');
      await tester.pump();
      expect(
        tester
            .widget<QuizipediaWorldMap>(find.byType(QuizipediaWorldMap))
            .features
            .any((f) => f.id == 'extra-country'),
        isTrue,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('zoomed map badges keep a readable screen size', (tester) async {
    final controller = TransformationController();
    addTearDown(controller.dispose);
    final feature = QuizipediaFeature(
      id: 'brazil',
      nameRu: 'Бразилия',
      nameEn: 'Brazil',
      polygons: [
        [
          _rectangle(
            .35,
            .3,
            .65,
            .7,
          ).map((p) => QuizipediaPoint(p[0], p[1])).toList(),
        ],
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 300,
          height: 200,
          child: QuizipediaWorldMap(
            features: [feature],
            controller: controller,
            onSelect: (_) {},
            selected: 'brazil',
            highlighted: 'brazil',
          ),
        ),
      ),
    );
    await tester.pump();
    Future<int> whitePixels(double scale) async {
      controller.value = Matrix4.diagonal3Values(scale, scale, 1);
      await tester.pump();
      final map = tester.widget<CustomPaint>(
        find.byKey(const Key('quizipedia-map')),
      );
      final size = tester.getSize(find.byKey(const Key('quizipedia-map')));
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder)
        ..translate(120, 60)
        ..scale(scale);
      canvas.translate(-size.width / 2, -size.height / 2);
      map.painter!.paint(canvas, size);
      final picture = recorder.endRecording();
      final image = await picture.toImage(240, 120);
      final bytes = (await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      ))!;
      var white = 0;
      for (var i = 0; i < bytes.lengthInBytes; i += 4) {
        if (bytes.getUint8(i) > 245 &&
            bytes.getUint8(i + 1) > 245 &&
            bytes.getUint8(i + 2) > 245) {
          white++;
        }
      }
      image.dispose();
      picture.dispose();
      return white;
    }

    final normal = await tester.runAsync(() => whitePixels(1));
    final zoomed = await tester.runAsync(() => whitePixels(6));
    expect(normal, greaterThan(100));
    expect(
      zoomed,
      closeTo(normal!, normal * .2),
      reason: 'The country badge must not grow to cover the map at 6x zoom.',
    );
  });

  testWidgets('zoom buttons preserve the gesture scale limits', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: quizipediaLocationTraining(QuizipediaCatalog.fromJson(fixture())),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byTooltip('Zoom in'));
    final controller = tester
        .widget<InteractiveViewer>(find.byKey(const Key('quizipedia-viewport')))
        .transformationController!;
    for (var i = 0; i < 12; i++) {
      await tester.tap(find.byTooltip('Zoom in'));
      await tester.pumpAndSettle();
    }
    expect(controller.value.getMaxScaleOnAxis(), closeTo(16, .000001));
    for (var i = 0; i < 12; i++) {
      await tester.tap(find.byTooltip('Zoom out'));
      await tester.pumpAndSettle();
    }
    expect(controller.value.getMaxScaleOnAxis(), closeTo(1, .000001));
  });

  testWidgets(
    'endocrine learning is reached through the unified organ section',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: QuizipediaPage(bundle: _Bundle(fixture()))),
      );
      await tester.pumpAndSettle();
      expect(find.text('Endocrine system'), findsNothing);
      await tester.scrollUntilVisible(
        find.text('Human organs and glands'),
        200,
      );
      expect(find.text('Human organs and glands'), findsOneWidget);
    },
  );

  testWidgets('photo browsing evicts old full-size images', (tester) async {
    final bundle = _PhotoBundle(fixture());
    await tester.pumpWidget(MaterialApp(home: QuizipediaPage(bundle: bundle)));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await tester.tap(find.text('Landmark photographs'));
      await tester.pump();
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
    for (var i = 0; i < 4; i++) {
      await tester.ensureVisible(find.byTooltip('Next photograph'));
      await tester.runAsync(() async {
        await tester.tap(find.byTooltip('Next photograph'));
        await tester.pump();
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
    }
    expect(
      bundle.photos.where((p) => p == 'assets/missing0.png'),
      hasLength(2),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('photo feedback explains every other option', (tester) async {
    final data = fixture();
    for (final row
        in (data['landmarks'] as List).cast<Map<String, dynamic>>()) {
      row['image_asset'] = 'assets/missing.png';
    }
    await tester.pumpWidget(
      MaterialApp(home: QuizipediaPage(bundle: _Bundle(data))),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Training'));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await tester.tap(find.text('Landmark photographs'));
      await tester.pump();
      await Future<void>.delayed(const Duration(milliseconds: 150));
    });
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(OutlinedButton).first);
    await tester.tap(find.byType(OutlinedButton).first);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Check'));
    await tester.tap(find.text('Check'));
    await tester.pumpAndSettle();
    final others = find.byKey(const Key('landmark-other-options'));
    await tester.ensureVisible(others);
    await tester.tap(others);
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: others,
        matching: find.byWidgetPredicate(
          (w) => w is ListTile && w.onTap == null,
        ),
      ),
      findsNWidgets(3),
    );
    await tester.ensureVisible(find.text('Next'));
    await tester.runAsync(() async {
      await tester.tap(find.text('Next'));
      await tester.pump();
      await Future<void>.delayed(const Duration(milliseconds: 150));
    });
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(OutlinedButton).first);
    await tester.tap(find.byType(OutlinedButton).first);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Check'));
    await tester.tap(find.text('Check'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Correct answer: City'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('photo rounds offer six real choices with smaller-pool fallback', () {
    final six = ['a', 'b', 'c', 'd', 'e', 'f'];
    final round = QuizipediaSession(six, (_) => six, choiceCount: 6);
    expect(round.options, hasLength(6));
    expect(round.options.toSet(), hasLength(6));
    expect(round.options, contains(round.current));
    final four = six.take(4).toList();
    expect(
      QuizipediaSession(four, (_) => four, choiceCount: 6).options,
      hasLength(4),
    );
  });

  testWidgets('mobile landmark picker searches city and selects an object', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(361, 738);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final data = fixture();
    for (final row
        in (data['landmarks'] as List).cast<Map<String, dynamic>>()) {
      row['image_asset'] = 'assets/missing.png';
    }
    (data['landmarks'] as List)[3].addAll({
      'country_iso2': 'SG',
      'country_name_en': 'Singapore',
      'country_name_ru': 'Сингапур',
    });
    final bundle = _PhotoBundle(data)..failThumbs = true;
    await tester.pumpWidget(MaterialApp(home: QuizipediaPage(bundle: bundle)));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await tester.tap(find.text('Landmark photographs'));
      await tester.pump();
      await Future<void>.delayed(const Duration(milliseconds: 150));
    });
    await tester.pumpAndSettle();
    final picker = find.byKey(const Key('landmark-picker'));
    await tester.ensureVisible(picker);
    await tester.tap(picker);
    await tester.pumpAndSettle();
    expect(bundle.thumbLoads, 1);
    expect(find.byKey(const Key('landmark-thumbnails-retry')), findsOneWidget);
    bundle.failThumbs = false;
    await tester.tap(find.byKey(const Key('landmark-thumbnails-retry')));
    await tester.pumpAndSettle();
    expect(bundle.thumbLoads, 2);
    expect(find.byKey(const Key('landmark-thumbnails-retry')), findsNothing);
    expect(
      bundle.photos,
      hasLength(1),
      reason: 'Picker must not fetch full-size images',
    );
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    addTearDown(tester.view.resetViewInsets);
    await tester.pump();
    await tester.enterText(find.byKey(const Key('landmark-search')), 'City 3');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('landmark-choice-landmark:3')), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('landmark-search')),
      'Singapore',
    );
    await tester.pumpAndSettle();
    expect(find.text('City 3 · Singapore'), findsOneWidget);
    expect(find.byKey(const Key('landmark-choice-landmark:0')), findsNothing);
    await tester.tap(find.byKey(const Key('landmark-choice-landmark:3')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('landmark-search')), findsNothing);
    expect(find.text('Location: City 3'), findsOneWidget);
    expect(find.byKey(const Key('landmark-photo-training')), findsOneWidget);
    await tester.ensureVisible(
      find.byKey(const Key('landmark-photo-training')),
    );
    await tester.runAsync(() async {
      await tester.tap(find.byKey(const Key('landmark-photo-training')));
      await tester.pump();
      await Future<void>.delayed(const Duration(milliseconds: 150));
    });
    await tester.pumpAndSettle();
    expect(find.text('Name this landmark'), findsOneWidget);
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
    expect(find.text('Countries of the world'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Landmark photographs'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
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

class _PhotoBundle extends _Bundle {
  _PhotoBundle(super.catalog);
  final photos = <String>[];
  int thumbLoads = 0;
  bool failThumbs = false;
  @override
  Future<ByteData> load(String key) {
    if (key == 'assets/quizipedia/landmark_thumbnails.json') {
      thumbLoads++;
      if (failThumbs) return Future.error(FlutterError('missing previews'));
      final text = jsonEncode({
        'schema_version': 'qm-landmark-thumbnails/v1',
        'photos': {
          for (final row in catalog['landmarks'] as List) row['id']: 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAADElEQVR4nGP4//8/AAX+Av4N70a4AAAAAElFTkSuQmCC',
        },
      });
      return Future.value(
        ByteData.sublistView(Uint8List.fromList(utf8.encode(text))),
      );
    }
    if (key.startsWith('assets/missing')) {
      photos.add(key);
      return super.load('assets/missing.png');
    }
    return super.load(key);
  }
}
