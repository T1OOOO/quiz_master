import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/constellation_atlas.dart';
import 'package:quiz_app/country_learning.dart';
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
      'explanation_en': 'A winter pattern.',
      'explanation_ru': 'Зимний рисунок.',
      'credit_id': 'sky-modern',
      'stars': [
        {
          'id': 'a',
          'name': 'Betelgeuse',
          'name_ru': 'Бетельгейзе',
          'ra_hours': 5.9,
          'dec_degrees': 7.4,
          'magnitude': .5,
        },
        {
          'id': 'b',
          'name': 'Rigel',
          'name_ru': 'Ригель',
          'ra_hours': 5.2,
          'dec_degrees': -8.2,
          'magnitude': .1,
        },
      ],
      'lines': [
        ['a', 'b'],
      ],
    },
  ],
);

void main() {
  testWidgets(
    'phone constellation controls are touch sized and use Russian semantics',
    (tester) async {
      tester.view.physicalSize = const Size(360, 760);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ru'),
          supportedLocales: const [Locale('ru'), Locale('en')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
            child: ConstellationAtlasPage(
              catalog: _catalog,
              trainingBuilder: (_) => const Placeholder(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      for (final chip in find.byType(FilterChip).evaluate()) {
        expect(
          tester.getSize(find.byWidget(chip.widget)).height,
          greaterThanOrEqualTo(48),
        );
      }
      expect(find.bySemanticsLabel(RegExp('Схема созвездия')), findsOneWidget);
      await _pinchAndPan(tester);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('country map keeps a usable phone height', (tester) async {
    tester.view.physicalSize = const Size(360, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(() async {
      await tester.pumpWidget(
        const MaterialApp(home: CountryAtlasPage(catalog: _catalog)),
      );
      await tester.pump();
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await tester.pumpAndSettle();
    final map = find.byKey(const Key('quizipedia-viewport'));
    await tester.ensureVisible(map);
    expect(tester.getSize(map).height, closeTo(180, 2));
    await tester.tap(find.byKey(const Key('country-expand-map')));
    await tester.pumpAndSettle();
    final expandedMap = find.byKey(const Key('quizipedia-viewport'));
    expect(tester.getSize(expandedMap).height, greaterThanOrEqualTo(300));
    await _pinchAndPan(tester);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pinchAndPan(WidgetTester tester) async {
  final viewer = find.byType(InteractiveViewer).first;
  await tester.ensureVisible(viewer);
  final controller = tester
      .widget<InteractiveViewer>(viewer)
      .transformationController!;
  final before = controller.value.storage[0].abs();
  final center = tester.getCenter(viewer);
  final one = await tester.createGesture(
    pointer: 21,
    kind: PointerDeviceKind.touch,
  );
  final two = await tester.createGesture(
    pointer: 22,
    kind: PointerDeviceKind.touch,
  );
  await one.down(center - const Offset(30, 0));
  await two.down(center + const Offset(30, 0));
  await tester.pump();
  for (var i = 1; i <= 4; i++) {
    await one.moveTo(center - Offset(30 + i * 12, 0));
    await two.moveTo(center + Offset(30 + i * 12, 0));
    await tester.pump(const Duration(milliseconds: 20));
  }
  await one.up();
  await two.up();
  await tester.pumpAndSettle();
  expect(controller.value.storage[0].abs(), greaterThan(before));
  final offset = controller.value.getTranslation();
  final finger = await tester.startGesture(
    center,
    pointer: 23,
    kind: PointerDeviceKind.touch,
  );
  await finger.moveBy(const Offset(24, 16));
  await tester.pump();
  await finger.moveBy(const Offset(24, 16));
  await tester.pump();
  await finger.moveBy(const Offset(24, 16));
  await tester.pump();
  await finger.up();
  await tester.pumpAndSettle();
  expect(controller.value.getTranslation(), isNot(offset));
}
