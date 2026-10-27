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
  testWidgets('country and fact search explains an empty result', (
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

    await tester.enterText(
      find.byKey(const Key('map-country-search')),
      'no such atlas entry',
    );
    await tester.pumpAndSettle();

    expect(
      find.text('No countries or facts match this search'),
      findsOneWidget,
    );
  });

  testWidgets('country picker explains an empty result', (tester) async {
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
    await tester.enterText(
      find.byKey(const Key('country-list-search')),
      'no such country',
    );
    await tester.pumpAndSettle();

    expect(find.text('No countries match this search'), findsOneWidget);
  });

  testWidgets('map search can be cleared with an accessible control', (
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

    await tester.enterText(
      find.byKey(const Key('map-country-search')),
      'France',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Clear search'));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<TextField>(find.byKey(const Key('map-country-search')))
          .controller
          ?.text,
      isEmpty,
    );
  });
}
