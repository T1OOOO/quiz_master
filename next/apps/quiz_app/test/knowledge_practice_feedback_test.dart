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
  testWidgets(
    'phone practice has a persistent close control after explanations',
    (tester) async {
      tester.view.physicalSize = const Size(361, 738);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final data = _fixture();
      await tester.pumpWidget(
        MaterialApp(
          home: KnowledgeAtlasPage(section: 'history', bundle: _Bundle(data)),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('knowledge-train')));
      await tester.pumpAndSettle();
      for (var answer = 0; answer < 6; answer++) {
        final option = find.byKey(const Key('knowledge-option-0'));
        await tester.ensureVisible(option);
        await tester.tap(option);
        await tester.pump();
        final check = find.byKey(const Key('knowledge-check'));
        await tester.ensureVisible(check);
        await tester.tap(check);
        await tester.pumpAndSettle();
        if (answer < 5) {
          final next = find.byKey(const Key('knowledge-next'));
          await tester.ensureVisible(next);
          await tester.tap(next);
          await tester.pumpAndSettle();
        }
      }
      final explanations = find.byKey(
        const Key('knowledge-choice-explanations'),
      );
      await tester.scrollUntilVisible(
        explanations,
        160,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(explanations);
      await tester.pumpAndSettle();

      final close = find.byKey(const Key('knowledge-close-training'));
      expect(close, findsOneWidget);
      expect(tester.getRect(close).bottom, lessThanOrEqualTo(738));
      await tester.tap(close);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('knowledge-train')), findsOneWidget);
      expect(find.byKey(const Key('knowledge-close-training')), findsNothing);
    },
  );

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

  testWidgets('culture training stays with the searched visible work', (
    tester,
  ) async {
    final data = jsonDecode(
      File('assets/quizipedia/knowledge_atlas.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final work = Map<String, dynamic>.from(
      (data['works'] as List).first as Map,
    );
    for (final event in data['events'] as List) {
      (event as Map<String, dynamic>)['source_url'] =
          'https://example.com/shared';
    }
    for (final item in data['works'] as List) {
      (item as Map<String, dynamic>)['source_url'] =
          'https://example.com/shared';
    }
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        supportedLocales: const [Locale('ru'), Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: KnowledgeAtlasPage(section: 'culture', bundle: _Bundle(data)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('knowledge-search')),
      work['title_ru'] as String,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('knowledge-train')));
    await tester.pumpAndSettle();

    final sheet = find.byType(BottomSheet);
    for (var index = 0; index < 3; index++) {
      expect(
        find.descendant(
          of: sheet,
          matching: find.textContaining(work['title_ru'] as String),
        ),
        findsWidgets,
      );
      expect(
        find.descendant(
          of: sheet,
          matching: find.textContaining('В каком году произошло'),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: sheet,
          matching: find.textContaining('Примерно когда произошло'),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: sheet,
          matching: find.textContaining('Какое из этих событий'),
        ),
        findsNothing,
      );
      expect(
        find.descendant(of: sheet, matching: find.byType(OutlinedButton)),
        findsNWidgets(6),
      );
      if (index < 2) {
        await tester.tap(find.byKey(const Key('knowledge-option-0')));
        await tester.pump();
        await tester.tap(find.byKey(const Key('knowledge-check')));
        await tester.pumpAndSettle();
        final next = find.byKey(const Key('knowledge-next'));
        await tester.ensureVisible(next);
        await tester.tap(next);
        await tester.pumpAndSettle();
      }
    }
  });

  testWidgets('history training follows the selected era event target', (
    tester,
  ) async {
    final data = _fixture();
    final events = data['events'] as List;
    (events.first as Map<String, dynamic>)['era'] = 'ancient';
    await tester.pumpWidget(
      MaterialApp(
        home: KnowledgeAtlasPage(section: 'history', bundle: _Bundle(data)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Ancient world').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('knowledge-train')));
    await tester.pumpAndSettle();

    final sheet = find.byType(BottomSheet);
    expect(
      find.descendant(of: sheet, matching: find.textContaining('Event 0')),
      findsWidgets,
    );
    expect(
      find.descendant(of: sheet, matching: find.textContaining('Event 1')),
      findsNothing,
    );
  });

  testWidgets('empty culture search disables unrelated training', (
    tester,
  ) async {
    final data = jsonDecode(
      File('assets/quizipedia/knowledge_atlas.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    await tester.pumpWidget(
      MaterialApp(
        home: KnowledgeAtlasPage(section: 'culture', bundle: _Bundle(data)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('knowledge-search')),
      'no match',
    );
    await tester.pumpAndSettle();

    final button = tester.widget<FilledButton>(
      find.byKey(const Key('knowledge-train')),
    );
    expect(button.onPressed, isNull);
    expect(find.text('No practice for this selection'), findsOneWidget);
  });

  testWidgets(
    'people training keeps the searched person as the answer target',
    (tester) async {
      final data = jsonDecode(
        File('assets/quizipedia/knowledge_atlas.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final atlas = KnowledgeAtlas.fromJson(data);
      final target = atlas.people.firstWhere(
        (person) =>
            atlas.questions.any((question) => question.personId == person.id),
      );
      final question = atlas.questions.firstWhere(
        (question) => question.personId == target.id,
      );
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
          home: KnowledgeAtlasPage(section: 'people', bundle: _Bundle(data)),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('knowledge-search')),
        target.nameRu,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('knowledge-train')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(OutlinedButton, wrongName));
      await tester.pump();
      await tester.tap(find.byKey(const Key('knowledge-check')));
      await tester.pumpAndSettle();

      final sheet = find.byType(BottomSheet);
      expect(
        find.descendant(
          of: sheet,
          matching: find.text('Правильный ответ: ${target.nameRu}'),
        ),
        findsOneWidget,
      );
    },
  );
}
