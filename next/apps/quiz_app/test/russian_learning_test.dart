import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/music_learning.dart';
import 'package:quiz_app/brand_atlas.dart';
import 'package:quiz_app/russian_learning_text.dart';

void main() {
  test('every shipped learning source retains a named Russian caption', () {
    for (final asset in [
      'music_learning',
      'organ_atlas',
      'belief_atlas',
      'brands',
      'food_atlas',
    ]) {
      final document = jsonDecode(
        File('assets/quizipedia/$asset.json').readAsStringSync(),
      ) as Map;
      for (final source in document['sources'] as List) {
        final title = source['title'] as String;
        expect(russianSourceTitles, contains(title), reason: '$asset: $title');
        expect(learningSourceTitle(title, russian: true), isNot('Источник'));
        expect(learningSourceTitle(title, russian: false), title);
      }
    }
  });

  testWidgets(
    'Russian brand search and owner card use translated display names',
    (tester) async {
      final raw = File('assets/quizipedia/brands.json').readAsStringSync();
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ru'),
          supportedLocales: const [Locale('ru'), Locale('en')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: BrandAtlasPage(bundle: _Bundle(raw)),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Гугл');
      await tester.pumpAndSettle();
      final googleCard = find.widgetWithText(ListTile, 'Гугл');
      expect(googleCard, findsOneWidget);
      expect(find.text('Google'), findsNothing);
      await tester.ensureVisible(googleCard);
      await tester.tap(googleCard);
      await tester.pumpAndSettle();
      expect(find.textContaining('Алфабет'), findsWidgets);
      expect(find.text('Alphabet Inc.'), findsNothing);
      await tester.tap(find.byTooltip('Закрыть'));
      await tester.pumpAndSettle();
      // A founder prompt can have several valid source rows. Use the owner
      // topic so the randomly selected displayed prompt identifies one answer.
      final topic = find.byTooltip('Тема тренировки');
      await tester.ensureVisible(topic);
      await tester.tap(topic);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Владельцы').last);
      await tester.pumpAndSettle();
      final practice = find.widgetWithText(FilledButton, 'Тренировка');
      await tester.ensureVisible(practice);
      await tester.tap(practice);
      await tester.pumpAndSettle();
      final atlas = BrandAtlas.fromJson(jsonDecode(raw));
      final question = atlas.questions.firstWhere(
        (q) => q.kind == BrandQuestionKind.owner &&
            find.text(russianLearningText(q.promptRu)).evaluate().isNotEmpty,
      );
      final answer = find.widgetWithText(
        OutlinedButton,
        russianLearningText(question.answer),
      );
      await tester.scrollUntilVisible(answer, 150, scrollable: find.byType(Scrollable).first);
      await tester.tap(answer);
      await tester.pump();
      final check = find.widgetWithText(FilledButton, 'Проверить');
      await tester.ensureVisible(check);
      await tester.tap(check);
      await tester.pumpAndSettle();
      expect(find.text('Верно'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Russian music details do not add English names or source captions',
    (tester) async {
      final raw = jsonDecode(
        File('assets/quizipedia/music_learning.json').readAsStringSync(),
      );
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ru'),
          supportedLocales: const [Locale('ru'), Locale('en')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: MusicLearningPage(
            bundle: _Bundle(jsonEncode(raw)),
            initialEntryId: 'koto',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Кото'), findsWidgets);
      expect(find.text('Koto'), findsNothing);
      expect(find.textContaining('Ministry of Foreign Affairs'), findsNothing);
      expect(
        find.textContaining('Министерство иностранных дел Японии'),
        findsOneWidget,
      );
    },
  );
}

class _Bundle extends CachingAssetBundle {
  _Bundle(this.value);
  final String value;
  @override
  Future<String> loadString(String key, {bool cache = true}) async => value;
  @override
  Future<ByteData> load(String key) => throw UnimplementedError();
}
