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
  testWidgets(
    'religion map layer and country details preserve a manual camera',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
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
      final viewer = tester.widget<InteractiveViewer>(
        find.byKey(const Key('quizipedia-viewport')),
      );
      final camera = Matrix4.identity()
        ..translateByDouble(-20, -10, 0, 1)
        ..scaleByDouble(1.8, 1.8, 1, 1);
      viewer.transformationController!.value = camera;
      await tester.ensureVisible(find.byKey(const Key('country-map-settings')));
      await tester.tap(find.byKey(const Key('country-map-settings')));
      await tester.pumpAndSettle();
      final layer = find.byKey(const Key('country-sheet-layer-religion'));
      await tester.tap(layer);
      await tester.pump();
      expect(tester.widget<FilterChip>(layer).selected, isTrue);
      expect(viewer.transformationController!.value, camera);
      await tester.ensureVisible(find.byKey(const Key('country-apply-layer')));
      await tester.tap(find.byKey(const Key('country-apply-layer')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('country-map-settings')));
      await tester.tap(find.byKey(const Key('country-map-settings')));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('2020 estimates (published 2025)'),
        findsOneWidget,
      );
      expect(find.text('Pew Research Center'), findsOneWidget);
      Navigator.of(tester.element(find.text('Pew Research Center'))).pop();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('map-country-search')));
      await tester.enterText(
        find.byKey(const Key('map-country-search')),
        'Islam',
      );
      await tester.pumpAndSettle();
      expect(find.widgetWithText(ActionChip, 'Afghanistan'), findsOneWidget);
      expect(find.widgetWithText(ActionChip, 'France'), findsNothing);
      await tester.enterText(
        find.byKey(const Key('map-country-search')),
        'France',
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.widgetWithText(ActionChip, 'France'),
        180,
        scrollable: find
            .descendant(
              of: find.byWidgetPredicate(
                (w) => w is ListView && w.scrollDirection == Axis.horizontal,
              ),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.ensureVisible(find.widgetWithText(ActionChip, 'France'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ActionChip, 'France'));
      await tester.pumpAndSettle();
      expect(viewer.transformationController!.value, camera);
      await tester.tap(find.byKey(const Key('country-selected-details')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const Key('country-religion-details')),
      );
      expect(find.textContaining('Religiously unaffiliated:'), findsOneWidget);
      expect(find.textContaining('Muslims:'), findsOneWidget);
      expect(
        find.textContaining('not official state religion. Unaffiliated'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
