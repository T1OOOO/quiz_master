import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:quiz_app/knowledge_atlas.dart';

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
  'schema_version': 'qm-knowledge-atlas/v1',
  'events': [
    for (var i = 0; i < 6; i++)
      {
        'id': 'event-$i',
        'year': 1000 + i,
        'era': 'medieval',
        'title_ru': 'Событие $i',
        'title_en': 'Event $i',
        'what_ru': 'Описание события $i.',
        'what_en': 'Event description $i.',
        'why_ru': 'Причина $i.',
        'why_en': 'Reason $i.',
        'consequences_ru': 'Следствие $i.',
        'consequences_en': 'Consequence $i.',
        'source_url': 'https://example.com/event-$i',
      },
  ],
  'works': [],
  'people': [],
};

void main() {
  testWidgets('wrong knowledge choice reveals six sourced explanations', (
    tester,
  ) async {
    final data = _fixture();
    final question = KnowledgeAtlas.fromJson(data).questions.first;
    final wrong = question.options.firstWhere(
      (option) => option != question.answer,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: KnowledgeAtlasPage(section: 'history', bundle: _Bundle(data)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('knowledge-train')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('knowledge-choice-explanations')),
      findsNothing,
    );
    await tester.tap(find.widgetWithText(OutlinedButton, wrong));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Check'));
    await tester.pumpAndSettle();

    expect(find.text('Your choice was incorrect.'), findsOneWidget);
    expect(find.text('Correct answer.'), findsOneWidget);
    final explanations = find.byKey(const Key('knowledge-choice-explanations'));
    expect(explanations, findsOneWidget);
    expect(find.byKey(const Key('knowledge-next')), findsOneWidget);
    await tester.scrollUntilVisible(
      explanations,
      160,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(explanations);
    await tester.pumpAndSettle();
    for (var i = 0; i < 6; i++) {
      expect(
        find.byKey(Key('knowledge-choice-explanation-$i')),
        findsOneWidget,
      );
    }
    expect(find.textContaining('Event description'), findsWidgets);
  });
  testWidgets('Russian event explanations normalize stored source terms', (
    tester,
  ) async {
    final data = _fixture();
    for (final event in data['events'] as List) {
      event['what_ru'] = 'Google';
      event['year'] = -(event['year'] as int);
      event['approximate'] = true;
    }
    final question = KnowledgeAtlas.fromJson(data).questions.first;
    final wrong = question.options.firstWhere(
      (option) => option != question.answer,
    );
    final wrongLabel = wrong
        .replaceAll('BCE', 'до н. э.')
        .replaceFirst('≈ ', 'около ');
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        supportedLocales: const [Locale('ru'), Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: KnowledgeAtlasPage(section: 'history', bundle: _Bundle(data)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('knowledge-train')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('knowledge-choice-explanations')),
      findsNothing,
    );
    await tester.tap(find.widgetWithText(OutlinedButton, wrongLabel));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Проверить'));
    await tester.pumpAndSettle();

    final explanations = find.byKey(const Key('knowledge-choice-explanations'));
    expect(explanations, findsOneWidget);
    expect(find.byKey(const Key('knowledge-next')), findsOneWidget);
    await tester.scrollUntilVisible(
      explanations,
      160,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(explanations);
    await tester.pumpAndSettle();
    for (var i = 0; i < 6; i++) {
      expect(
        find.byKey(Key('knowledge-choice-explanation-$i')),
        findsOneWidget,
      );
    }
    expect(find.textContaining('Google'), findsNothing);
    expect(find.textContaining('Гугл'), findsWidgets);
    expect(find.textContaining('BCE'), findsNothing);
    expect(find.textContaining('≈ '), findsNothing);
  });
  testWidgets('Russian people explanations localize biographies and roles', (
    tester,
  ) async {
    final data = jsonDecode(
      File('assets/quizipedia/knowledge_atlas.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    data['events'] = <dynamic>[];
    for (final person in data['people'] as List) {
      person['bio_ru'] = 'Google';
    }
    final atlas = KnowledgeAtlas.fromJson(data);
    final question = atlas.questions.first;
    final wrong = question.options.firstWhere(
      (option) => option != question.answer,
    );
    final wrongName = atlas.people
        .firstWhere((person) => person.nameEn == wrong)
        .nameRu;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        supportedLocales: const [Locale('ru'), Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: KnowledgeAtlasPage(section: 'culture', bundle: _Bundle(data)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('knowledge-train')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, wrongName));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Проверить'));
    await tester.pumpAndSettle();
    final explanations = find.byKey(const Key('knowledge-choice-explanations'));
    await tester.scrollUntilVisible(
      explanations,
      160,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(explanations);
    await tester.pumpAndSettle();
    for (var i = 0; i < 6; i++) {
      final tile = tester.widget<ListTile>(
        find.byKey(Key('knowledge-choice-explanation-$i')),
      );
      final detail = ((tile.subtitle! as Column).children.first as Text).data!;
      expect(detail, contains('Гугл'));
      expect(RegExp('[A-Za-z]').hasMatch(detail), isFalse);
    }
  });
}
