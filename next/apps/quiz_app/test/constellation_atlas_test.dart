import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/constellation_atlas.dart';
import 'package:quiz_app/quizipedia.dart';

const _catalog = QuizipediaCatalog(
  countries: [],
  countryRows: [],
  mapTargetIds: [],
  anatomy: {},
  landmarks: [],
  credits: [],
  constellations: [
    {
      'id': 'ori',
      'name_en': 'Orion',
      'name_ru': 'Орион',
      'explanation_en': 'A bright winter constellation.',
      'explanation_ru': 'Яркое зимнее созвездие.',
      'credit_id': 'sky-modern',
      'stars': [
        {
          'id': 'betelgeuse',
          'name': 'Betelgeuse',
          'ra_hours': 5.9,
          'dec_degrees': 7.4,
          'magnitude': .5,
        },
        {
          'id': 'rigel',
          'name': 'Rigel',
          'ra_hours': 5.2,
          'dec_degrees': -8.2,
          'magnitude': .1,
        },
      ],
      'lines': [
        ['betelgeuse', 'rigel'],
      ],
    },
    {
      'id': 'uma',
      'name_en': 'Ursa Major',
      'name_ru': 'Большая Медведица',
      'explanation_en': 'The Great Bear contains the Big Dipper asterism.',
      'explanation_ru': 'В Большой Медведице находится астеризм Ковш.',
      'credit_id': 'sky-modern',
      'stars': [
        {
          'id': 'dubhe',
          'name': 'Dubhe',
          'ra_hours': 11.1,
          'dec_degrees': 61.8,
          'magnitude': 1.8,
        },
        {
          'id': 'merak',
          'name': 'Merak',
          'ra_hours': 11.0,
          'dec_degrees': 56.4,
          'magnitude': 2.3,
        },
      ],
      'lines': [
        ['dubhe', 'merak'],
      ],
    },
  ],
);

Widget _app({TextScaler? scaler}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(textScaler: scaler ?? TextScaler.noScaling),
    child: ConstellationAtlasPage(
      catalog: _catalog,
      trainingBuilder: (_) => const Placeholder(),
    ),
  ),
);

void main() {
  testWidgets('a visible star can be tapped on a phone width canvas', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_app());
    final canvas = find.byKey(const Key('constellation-canvas'));
    await tester.ensureVisible(canvas);
    final size = tester.getSize(canvas);
    final stars = (_catalog.constellations.first['stars'] as List)
        .cast<Map<String, dynamic>>();
    final at = projectConstellation(stars, size)['betelgeuse']!;
    await tester.tapAt(tester.getTopLeft(canvas) + at);
    await tester.pumpAndSettle();
    expect(find.textContaining('magnitude'), findsWidgets);
  });
  testWidgets('search selects a constellation and exposes its stars', (
    tester,
  ) async {
    await tester.pumpWidget(_app());

    expect(find.byKey(const Key('constellation-search')), findsNothing);
    await tester.tap(find.byKey(const Key('constellation-choose')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('constellation-search')),
      'ursa',
    );
    await tester.pump();
    expect(find.byKey(const Key('constellation-option-uma')), findsOneWidget);
    expect(find.byKey(const Key('constellation-option-ori')), findsNothing);

    await tester.tap(find.byKey(const Key('constellation-option-uma')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('constellation-search')), findsNothing);
    expect(find.text('Dubhe'), findsOneWidget);
    expect(
      find.text('The Great Bear contains the Big Dipper asterism.'),
      findsOneWidget,
    );
  });

  testWidgets('previous and next buttons cycle through constellations', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    expect(find.text('Orion'), findsWidgets);

    await tester.tap(find.byTooltip('Next constellation'));
    await tester.pumpAndSettle();
    expect(find.text('Ursa Major'), findsWidgets);

    await tester.tap(find.byTooltip('Previous constellation'));
    await tester.pumpAndSettle();
    expect(find.text('Orion'), findsWidgets);
  });

  testWidgets(
    'reset is available after zoom and large text keeps the controls usable',
    (tester) async {
      tester.view.physicalSize = const Size(360, 760);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_app(scaler: const TextScaler.linear(1.5)));

      final pageScroll = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        find.byTooltip('Zoom in'),
        200,
        scrollable: pageScroll,
      );
      await tester.tap(find.byTooltip('Zoom in'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byTooltip('Reset view'),
        200,
        scrollable: pageScroll,
      );
      expect(find.byTooltip('Reset view'), findsOneWidget);
      await tester.tap(find.byTooltip('Reset view'));
      await tester.pumpAndSettle();
      expect(find.text('Start training'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
