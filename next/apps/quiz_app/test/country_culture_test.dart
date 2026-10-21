import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/country_learning.dart';
import 'package:quiz_app/quizipedia.dart';

void main() {
  test(
    'shared traditions exclude every linked country as a reverse distractor',
    () async {
      final facts =
          (jsonDecode(
                    File('assets/quizipedia/country_facts.json')
                        .readAsStringSync(),
                  )['countries']
                  as List)
              .map((e) => CountryFact.fromJson(Map<String, dynamic>.from(e)))
              .toList();
      final raw = jsonDecode(
        File('assets/quizipedia/country_culture.json').readAsStringSync(),
      );
      final associations = (raw['countries'] as Map).map(
        (id, rows) => MapEntry(
          id as String,
          (rows as List)
              .map(
                (r) =>
                    CountryAssociation.fromJson(Map<String, dynamic>.from(r)),
              )
              .toList(),
        ),
      );
      final questions = CountryQuestion.associations(
        facts,
        associations,
        kind: 'culture',
        reverse: true,
      );
      final tango = questions
          .where((q) => q.association!.id == 'tango')
          .toList();
      expect(tango.length, 2);
      for (final q in tango) {
        expect(
          q.options.where((o) => o != q.answer),
          isNot(contains('Argentina')),
        );
        expect(
          q.options.where((o) => o != q.answer),
          isNot(contains('Uruguay')),
        );
        expect(q.options.toSet().length, inInclusiveRange(4, 6));
      }
    },
  );
  testWidgets(
    'instrument map layer and search retain the manually set camera',
    (tester) async {
      const catalog = QuizipediaCatalog(
        countries: [],
        countryRows: [],
        mapTargetIds: [],
        anatomy: {},
        landmarks: [],
        constellations: [],
        credits: [],
      );
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.runAsync(() async {
        await tester.pumpWidget(
          const MaterialApp(home: CountryAtlasPage(catalog: catalog)),
        );
        await tester.pump();
        await Future<void>.delayed(const Duration(milliseconds: 500));
      });
      await tester.pumpAndSettle();
      final viewer = tester.widget<InteractiveViewer>(
        find.byKey(const Key('quizipedia-viewport')),
      );
      final camera = Matrix4.identity()..scaleByDouble(1.7, 1.7, 1, 1);
      viewer.transformationController!.value = camera;
      await tester.ensureVisible(find.byKey(const Key('country-map-settings')));
      await tester.tap(find.byKey(const Key('country-map-settings')));
      await tester.pumpAndSettle();
      final layer = find.byKey(const Key('country-sheet-layer-instrument'));
      await tester.tap(layer);
      await tester.pump();
      expect(tester.widget<FilterChip>(layer).selected, isTrue);
      final map = tester.widget<QuizipediaWorldMap>(
        find.byType(QuizipediaWorldMap),
      );
      expect(map.overlayLabels['JP'], contains('Koto'));
      expect(viewer.transformationController!.value, camera);
      await tester.ensureVisible(find.byKey(const Key('country-apply-layer')));
      await tester.tap(find.byKey(const Key('country-apply-layer')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('country-map-settings')));
      await tester.tap(find.byKey(const Key('country-map-settings')));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Selected cultural associations'),
        findsOneWidget,
      );
      Navigator.of(
        tester.element(find.textContaining('Selected cultural associations')),
      ).pop();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('map-country-search')));
      await tester.enterText(
        find.byKey(const Key('map-country-search')),
        'koto',
      );
      await tester.pumpAndSettle();
      final japan = find.widgetWithText(ActionChip, 'Japan');
      expect(japan, findsOneWidget);
      expect(find.widgetWithText(ActionChip, 'France'), findsNothing);
      await tester.ensureVisible(japan);
      await tester.tap(japan);
      await tester.pumpAndSettle();
      expect(viewer.transformationController!.value, camera);

      expect(tester.takeException(), isNull);
    },
  );
}
