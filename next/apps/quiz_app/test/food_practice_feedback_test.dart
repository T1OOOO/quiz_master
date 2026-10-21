import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:quiz_app/food_atlas.dart';
import 'package:quiz_app/food_atlas_models.dart';

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
  'schema_version': 'qm-food-atlas/v1',
  'coverage_note_ru': 'Учебная подборка.',
  'coverage_note_en': 'Learning sample.',
  'sources': [
    {
      'id': 's',
      'title': 'Reference',
      'url': 'https://example.com/food',
      'checked_on': '2026-10-19',
    },
  ],
  'dishes': [
    for (var i = 0; i < 10; i++)
      {
        'id': 'dish-$i',
        'name_ru': 'Блюдо $i',
        'name_en': 'Dish $i',
        'category_ru': 'Категория',
        'category_en': 'Category',
        'country_ru': 'Страна $i',
        'country_en': 'Country $i',
        'region_ru': 'Регион $i',
        'region_en': 'Region $i',
        'summary_ru': 'Краткое описание $i.',
        'summary_en': 'Summary $i.',
        'classic_note_ru': 'Классическая заметка $i.',
        'classic_note_en': 'Classic note $i.',
        'origin_ru': 'Связано с регионом $i.',
        'origin_en': 'Associated with region $i.',
        'servings_ru': 'На 4 порции.',
        'servings_en': 'Makes 4 servings.',
        'ingredients': [
          for (var j = 0; j < 3; j++)
            {
              'name_ru': 'Ингредиент ${i}_$j',
              'name_en': 'Ingredient ${i}_$j',
              'amount_ru': '${j + 1}',
              'amount_en': '${j + 1}',
            },
        ],
        'steps': [
          for (var j = 0; j < 3; j++)
            {'text_ru': 'Шаг $j.', 'text_en': 'Step $j.'},
        ],
        'facts': [
          {
            'text_ru': 'Факт $i.',
            'text_en': 'Fact $i.',
            'source_ids': ['s'],
          },
        ],
        'variants': [
          {
            'name_ru': 'Вариант $i',
            'name_en': 'Variant $i',
            'region_ru': 'Регион $i',
            'region_en': 'Region $i',
            'difference_ru': 'Отличие.',
            'difference_en': 'Difference.',
            'source_ids': ['s'],
          },
        ],
        'source_ids': ['s'],
      },
  ],
};

void main() {
  testWidgets('wrong food composition choice reveals all six sourced choices', (
    tester,
  ) async {
    final data = _fixture();
    final question = FoodAtlas.fromJson(data)
        .round(
          // The initial default start consumes seed 17 before the topic chip
          // restarts this selected composition round with seed 18.
          seed: 18,
          topic: FoodQuestionKind.composition,
        )
        .first;
    final wrong = question.optionsEn.firstWhere(
      (option) => option != question.answerEn,
    );
    await tester.pumpWidget(
      MaterialApp(home: FoodAtlasPage(bundle: _Bundle(data))),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('food-train')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Composition'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('food-choice-explanations')), findsNothing);
    final wrongButton = find.widgetWithText(OutlinedButton, wrong);
    await tester.ensureVisible(wrongButton);
    await tester.tap(wrongButton);
    await tester.pump();
    final check = find.widgetWithText(FilledButton, 'Check');
    await tester.ensureVisible(check);
    await tester.tap(check);
    await tester.pumpAndSettle();
    expect(find.text('Your choice was incorrect.'), findsOneWidget);
    expect(find.text('Correct answer.'), findsOneWidget);
    final explanations = find.byKey(const Key('food-choice-explanations'));
    await tester.drag(find.byType(ListView), const Offset(0, -240));
    await tester.pumpAndSettle();
    await tester.tap(explanations);
    await tester.pumpAndSettle();
    for (var i = 0; i < 6; i++) {
      expect(find.byKey(Key('food-choice-explanation-$i')), findsOneWidget);
    }
    expect(find.textContaining('Summary'), findsWidgets);
  });
  testWidgets('Russian food explanations normalize stored source terms', (
    tester,
  ) async {
    final data = _fixture();
    for (final dish in data['dishes'] as List) {
      dish['summary_ru'] = 'Маргарита STG использует MSG.';
      for (final ingredient in dish['ingredients'] as List) {
        ingredient['name_ru'] = '${ingredient['name_ru']} MSG';
      }
    }
    final question = FoodAtlas.fromJson(data)
        .round(
          // The initial default start consumes seed 17 before the topic chip
          // restarts this selected composition round with seed 18.
          seed: 18,
          topic: FoodQuestionKind.composition,
        )
        .first;
    final wrong = question.optionsRu.firstWhere(
      (option) => option != question.answerRu,
    );
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        supportedLocales: const [Locale('ru'), Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: FoodAtlasPage(bundle: _Bundle(data)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('food-train')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Состав'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('food-choice-explanations')), findsNothing);
    final wrongButton = find.widgetWithText(OutlinedButton, wrong);
    await tester.ensureVisible(wrongButton);
    await tester.tap(wrongButton);
    await tester.pump();
    final check = find.widgetWithText(FilledButton, 'Проверить');
    await tester.ensureVisible(check);
    await tester.tap(check);
    await tester.pumpAndSettle();
    final explanations = find.byKey(const Key('food-choice-explanations'));
    await tester.drag(find.byType(ListView), const Offset(0, -240));
    await tester.pumpAndSettle();
    await tester.tap(explanations);
    await tester.pumpAndSettle();
    for (var i = 0; i < 6; i++) {
      expect(find.byKey(Key('food-choice-explanation-$i')), findsOneWidget);
    }
    expect(find.textContaining('STG'), findsNothing);
    expect(find.textContaining('MSG'), findsNothing);
    expect(find.textContaining('глутамат натрия'), findsWidgets);
  });
}
