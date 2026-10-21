import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:quiz_app/belief_atlas.dart';

class _Bundle extends CachingAssetBundle {
  _Bundle(this.data);
  final Map<String, dynamic> data;
  @override
  Future<String> loadString(String key, {bool cache = true}) async =>
      jsonEncode(data);
  @override
  Future<ByteData> load(String key) => throw UnimplementedError();
}

Map<String, dynamic> _fixture() => {
  'schema_version': 'qm-belief-atlas/v1',
  'coverage_note_ru': 'Учебная подборка.',
  'coverage_note_en': 'Learning sample.',
  'sources': [
    {
      'id': 's',
      'title': 'Reference',
      'url': 'https://example.com/belief',
      'checked_on': '2026-10-21',
    },
  ],
  'nodes': [
    for (final id in ['a', 'b', 'c', 'd', 'e', 'f'])
      {
        'id': id,
        'section': 'greek',
        'name_ru': 'Имя $id',
        'name_en': 'Name $id',
        'group_ru': 'Группа',
        'group_en': 'Group',
        'summary_ru': 'Описание $id.',
        'summary_en': 'Summary $id.',
        'domains_ru': ['Область $id'],
        'domains_en': ['Domain $id'],
        'symbols_ru': ['Символ $id'],
        'symbols_en': ['Symbol $id'],
        'facts': [
          {
            'text_ru': 'Факт $id.',
            'text_en': 'Fact $id.',
            'source_ids': ['s'],
          },
        ],
        'variant_note_ru': '',
        'variant_note_en': '',
        'source_ids': ['s'],
      },
  ],
  'edges': [],
  'questions': [
    {
      'id': 'q',
      'section': 'greek',
      'stem_ru': 'Вопрос',
      'stem_en': 'Question',
      'option_ids': ['a', 'b', 'c', 'd', 'e', 'f'],
      'correct_id': 'a',
      'explanation_ru': 'Объяснение.',
      'explanation_en': 'Explanation.',
      'source_ids': ['s'],
    },
  ],
};

void main() {
  testWidgets('wrong belief choice reveals six sourced explanations', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: BeliefAtlasPage(bundle: _Bundle(_fixture()))),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('belief-quiz')));
    await tester.tap(find.byKey(const Key('belief-quiz')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('belief-choice-explanations')), findsNothing);

    final wrong = find.widgetWithText(OutlinedButton, 'Name b');
    await tester.tap(wrong);
    await tester.pump();
    await tester.tap(find.byKey(const Key('belief-check')));
    await tester.pumpAndSettle();

    expect(find.text('Your choice was incorrect.'), findsOneWidget);
    expect(find.text('Correct answer.'), findsOneWidget);
    final explanations = find.byKey(const Key('belief-choice-explanations'));
    expect(explanations, findsOneWidget);
    expect(find.byKey(const Key('belief-next')), findsOneWidget);
    await tester.scrollUntilVisible(explanations, 160);
    await tester.tap(explanations);
    await tester.pumpAndSettle();
    for (final id in ['a', 'b', 'c', 'd', 'e', 'f']) {
      expect(find.byKey(Key('belief-choice-explanation-$id')), findsOneWidget);
    }
    expect(find.textContaining('Summary b.'), findsOneWidget);
    expect(find.text('Reference'), findsWidgets);
  });
  testWidgets('Russian belief explanations normalize stored source terms', (
    tester,
  ) async {
    final data = _fixture();
    for (final node in data['nodes'] as List) {
      node['summary_ru'] = 'Google';
    }
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        supportedLocales: const [Locale('ru'), Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: BeliefAtlasPage(bundle: _Bundle(data)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('belief-quiz')));
    await tester.tap(find.byKey(const Key('belief-quiz')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('belief-choice-explanations')), findsNothing);

    final wrong = find.widgetWithText(OutlinedButton, 'Имя b');
    await tester.tap(wrong);
    await tester.pump();
    await tester.tap(find.byKey(const Key('belief-check')));
    await tester.pumpAndSettle();

    final explanations = find.byKey(const Key('belief-choice-explanations'));
    expect(explanations, findsOneWidget);
    expect(find.byKey(const Key('belief-next')), findsOneWidget);
    await tester.scrollUntilVisible(explanations, 160);
    await tester.tap(explanations);
    await tester.pumpAndSettle();
    for (final id in ['a', 'b', 'c', 'd', 'e', 'f']) {
      expect(find.byKey(Key('belief-choice-explanation-$id')), findsOneWidget);
    }
    expect(find.textContaining('Google'), findsNothing);
    expect(find.textContaining('Гугл'), findsNWidgets(6));
  });
}
