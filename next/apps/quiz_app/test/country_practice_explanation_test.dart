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

const _bridgeOptions = [
  'Sydney Harbour Bridge',
  'Charles Bridge',
  'Ponte Vecchio',
  'Tower Bridge',
  'Golden Gate Bridge',
  'Akashi Kaikyo Bridge',
];

void main() {
  test(
    'every Australia bridge choice keeps its dataset-backed country relation',
    () async {
      final facts = await CountryFact.load();
      final associations = await loadCountryAssociations(
        'assets/quizipedia/country_links.json',
        defaultKind: 'link',
      );
      final australia = facts.singleWhere((fact) => fact.id == 'AU');
      final sydneyHarbour = associations['AU']!.singleWhere(
        (row) => row.nameEn == 'Sydney Harbour Bridge',
      );
      final question = CountryQuestion(
        'bridge',
        australia,
        'Which bridge is in Australia?',
        sydneyHarbour.nameEn,
        _bridgeOptions,
        association: sydneyHarbour,
      );

      final explanations = countryChoiceExplanations(
        question,
        facts,
        associations,
        russian: true,
      );

      expect(explanations, hasLength(6));
      expect(
        explanations.map((item) => item.option),
        orderedEquals(_bridgeOptions),
      );
      expect(explanations.every((item) => item.text.isNotEmpty), isTrue);
      expect(
        explanations
            .singleWhere((item) => item.option == 'Akashi Kaikyo Bridge')
            .text,
        'Мост Акаси-Кайкё · Япония\nНаходится в стране',
      );
    },
  );

  test(
    'shared association choices retain every matching atlas country',
    () async {
      final facts = await CountryFact.load();
      final associations = await loadCountryAssociations(
        'assets/quizipedia/country_waters.json',
      );
      final albania = facts.singleWhere((fact) => fact.id == 'AL');
      final adriatic = associations['AL']!.singleWhere(
        (row) => row.nameEn == 'Adriatic Sea',
      );
      final explanations = countryChoiceExplanations(
        CountryQuestion(
          'water',
          albania,
          'Which water body is listed for Albania?',
          adriatic.nameEn,
          [adriatic.nameEn],
          association: adriatic,
        ),
        facts,
        associations,
        russian: true,
      );

      expect(explanations.single.text, contains('Албания'));
      expect(explanations.single.text, contains('Босния и Герцеговина'));
      expect(explanations.single.text, contains('Хорватия'));
      expect(explanations.single.text, contains('Черногория'));
    },
  );

  testWidgets(
    'a wrong Australia bridge response expands all six explanations',
    (tester) async {
      late List<CountryFact> facts;
      late Map<String, List<CountryAssociation>> associations;
      await tester.runAsync(() async {
        facts = await CountryFact.load();
        associations = await loadCountryAssociations(
          'assets/quizipedia/country_links.json',
          defaultKind: 'link',
        );
      });
      final australia = facts.singleWhere((fact) => fact.id == 'AU');
      final sydneyHarbour = associations['AU']!.singleWhere(
        (row) => row.nameEn == 'Sydney Harbour Bridge',
      );
      final explanations = countryChoiceExplanations(
        CountryQuestion(
          'bridge',
          australia,
          'Which bridge is in Australia?',
          sydneyHarbour.nameEn,
          _bridgeOptions,
          association: sydneyHarbour,
        ),
        facts,
        associations,
        russian: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CountryChoiceExplanationPanel(
              explanations: explanations,
              title: 'О каждом варианте',
              display: (value) => value,
            ),
          ),
        ),
      );
      expect(
        find.byKey(const Key('country-choice-explanation-0')),
        findsNothing,
      );
      await tester.tap(find.byKey(const Key('country-choice-explanations')));
      await tester.pump();

      for (var index = 0; index < 6; index++) {
        expect(
          find.byKey(Key('country-choice-explanation-$index')),
          findsOneWidget,
        );
      }
      expect(
        find.text('Мост Акаси-Кайкё · Япония\nНаходится в стране'),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  test(
    'reverse country choices explain the atlas relation or its absence',
    () async {
      final facts = await CountryFact.load();
      final associations = await loadCountryAssociations(
        'assets/quizipedia/country_links.json',
        defaultKind: 'link',
      );
      final australia = facts.singleWhere((fact) => fact.id == 'AU');
      final sydneyHarbour = associations['AU']!.singleWhere(
        (row) => row.nameEn == 'Sydney Harbour Bridge',
      );
      final wrong = facts.firstWhere((fact) => fact.id != 'AU');
      final question = CountryQuestion(
        'bridge',
        australia,
        'Which country lists Sydney Harbour Bridge?',
        australia.nameEn,
        [australia.nameEn, wrong.nameEn],
        association: sydneyHarbour,
        reverse: true,
      );

      final explanations = countryChoiceExplanations(
        question,
        facts,
        associations,
        russian: true,
      );

      expect(explanations, hasLength(2));
      expect(
        explanations.first.text,
        contains('Мост Харбор-Бридж · Австралия'),
      );
      expect(explanations.last.text, contains('в этом справочнике нет связи'));
    },
  );

  testWidgets(
    'Layers opens visible wrapping choices that retain toggle state',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: CountryAtlasPage(catalog: _catalog)),
      );
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 1200));
      });
      await tester.pump();
      await tester.pump();
      expect(
        tester.widget<OutlinedButton>(
          find.byKey(const Key('country-direct-layers')),
        ),
        isNotNull,
      );
      await tester.ensureVisible(find.byKey(const Key('country-map-settings')));
      await tester.tap(find.byKey(const Key('country-map-settings')));
      await tester.pumpAndSettle();

      final flagLayer = find.byKey(const Key('country-sheet-layer-flag'));
      expect(flagLayer, findsOneWidget);
      expect(tester.widget<FilterChip>(flagLayer).selected, isFalse);
      await tester.tap(flagLayer);
      await tester.pump();
      expect(tester.widget<FilterChip>(flagLayer).selected, isTrue);

      await tester.ensureVisible(
        find.byKey(const Key('country-apply-layer')),
      );
      await tester.tap(find.byKey(const Key('country-apply-layer')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const Key('country-start-training')),
      );
      await tester.tap(find.byKey(const Key('country-start-training')));
      await tester.pump();
      expect(
        find.byKey(const Key('country-choice-explanations')),
        findsNothing,
      );
      await tester.tap(find.byType(OutlinedButton).first);
      await tester.pump();
      expect(
        find.byKey(const Key('country-choice-explanations')),
        findsOneWidget,
      );
    },
  );
}
