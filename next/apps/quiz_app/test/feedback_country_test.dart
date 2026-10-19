import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/country_learning.dart';
import 'package:quiz_app/quizipedia.dart';

const _catalog = QuizipediaCatalog(
  countries: [],
  countryRows: [],
  mapTargetIds: [],
  anatomy: {},
  landmarks: [],
  constellations: [],
  credits: [],
);

void main() {
  testWidgets('country picker opens a searchable country sheet on a phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
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

    await tester.tap(find.byKey(const Key('country-list-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('country-list-search')), findsOneWidget);
    expect(find.text('Choose a country'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a country answer shows feedback on its first tap', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(
        const MaterialApp(home: CountryAtlasPage(catalog: _catalog)),
      );
      await tester.pump();
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Train 10 questions'));
    await tester.tap(find.text('Train 10 questions'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(OutlinedButton).first);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('quizipedia-feedback')), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    expect(find.text('Check'), findsNothing);
  });

  testWidgets(
    'flag layer renders a compact country raster without moving camera',
    (tester) async {
      final controller = TransformationController(
        Matrix4.identity()..translateByDouble(-18, -12, 0, 1),
      );
      addTearDown(controller.dispose);
      const france = QuizipediaFeature(
        id: 'FR',
        nameRu: 'Франция',
        nameEn: 'France',
        polygons: [
          [
            [
              QuizipediaPoint(.2, .2),
              QuizipediaPoint(.8, .2),
              QuizipediaPoint(.8, .8),
              QuizipediaPoint(.2, .8),
              QuizipediaPoint(.2, .2),
            ],
          ],
        ],
      );
      final camera = controller.value.clone();
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 320,
            height: 300,
            child: QuizipediaWorldMap(
              features: const [france],
              controller: controller,
              onSelect: (_) {},
              overlayLabels: const {'FR': 'France'},
              showFlags: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('map-country-flag-fr')), findsOneWidget);
      expect(find.text('France'), findsNothing);
      expect(controller.value, camera);
    },
  );
}
