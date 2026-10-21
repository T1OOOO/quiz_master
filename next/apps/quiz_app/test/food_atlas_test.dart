import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/food_atlas.dart';
import 'package:quiz_app/food_atlas_models.dart';

void main() {
  test('a dish may omit undocumented variants', () {
    final data = _fixture();
    (data['dishes'] as List).first['variants'] = <Object>[];
    expect(FoodAtlas.fromJson(data).dishes.first.variants, isEmpty);
  });
  test(
    'food atlas validates references and creates an unambiguous frozen round',
    () {
      final atlas = FoodAtlas.fromJson(_fixture());
      final round = atlas.round(seed: 3);

      expect(round, hasLength(10));
      expect(round.map((question) => question.dishId).toSet(), hasLength(10));
      for (final question in round) {
        expect(question.optionsEn, hasLength(6));
        expect(question.optionsEn.toSet(), hasLength(6));
        expect(
          question.optionsEn.where((option) => option == question.answerEn),
          hasLength(1),
        );
        expect(
          question.optionsRu.where((option) => option == question.answerRu),
          hasLength(1),
        );
      }
    },
  );

  test('food atlas rejects unresolved references, bad dates and ambiguous signatures', () {
    final source = _fixture();
    source['sources'] = [
      {
        ...((source['sources'] as List).first as Map<String, dynamic>),
        'checked_on': '2026-02-30',
      },
    ];
    expect(() => FoodAtlas.fromJson(source), throwsFormatException);

    final unresolved = _fixture();
    (unresolved['dishes'] as List).first['source_ids'] = ['none'];
    expect(() => FoodAtlas.fromJson(unresolved), throwsFormatException);

    final duplicate = _fixture();
    final dishes = duplicate['dishes'] as List;
    dishes[1]['ingredients'] = List<Map<String, String>>.from(
      dishes[0]['ingredients'] as List,
    );
    expect(() => FoodAtlas.fromJson(duplicate), throwsFormatException);
  });

  testWidgets(
    'selection down the list scrolls to readable detail and survives filtering',
    (tester) async {
      tester.view.physicalSize = const Size(360, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: FoodAtlasPage(bundle: _Bundle(jsonEncode(_fixture()))),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.byKey(const Key('food-dish-9')),
        300,
        scrollable: find
            .descendant(
              of: find.byKey(const Key('food-scroll')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.tap(find.byKey(const Key('food-dish-9')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('food-detail')), findsOneWidget);
      expect(
        tester.getTopLeft(find.byKey(const Key('food-detail'))).dy,
        greaterThanOrEqualTo(0),
      );
      await tester.enterText(find.byKey(const Key('food-search')), 'no match');
      await tester.pump();
      expect(find.byKey(const Key('food-detail')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  test('Russian answer labels and ingredient signatures are unambiguous', () {
    final regions = _fixture();
    final rows = regions['dishes'] as List;
    rows[1]['region_ru'] = rows[0]['region_ru'];
    expect(() => FoodAtlas.fromJson(regions), throwsFormatException);
    final ingredients = _fixture();
    final dishes = ingredients['dishes'] as List;
    for (var j = 0; j < 3; j++) {
      dishes[1]['ingredients'][j]['name_ru'] =
          dishes[0]['ingredients'][j]['name_ru'];
    }
    expect(() => FoodAtlas.fromJson(ingredients), throwsFormatException);
  });
  test(
    'training-sized data without four distinct regions is rejected at load',
    () {
      final data = _fixture();
      for (final dish in data['dishes'] as List) {
        dish['region_en'] = 'One region';
        dish['region_ru'] = 'Один регион';
      }
      expect(() => FoodAtlas.fromJson(data), throwsFormatException);
    },
  );
  testWidgets('load failure keeps navigation and can retry successfully', (
    tester,
  ) async {
    final bundle = _RecoveryBundle(jsonEncode(_fixture()));
    await tester.pumpWidget(MaterialApp(home: FoodAtlasPage(bundle: bundle)));
    await tester.pumpAndSettle();
    expect(find.byType(Scaffold), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('food-search')), findsOneWidget);
    expect(bundle.loads, 2);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'checked answers finish and finite mistakes review preserves original score',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: FoodAtlasPage(bundle: _Bundle(jsonEncode(_fixture()))),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('food-train')));
      await tester.pumpAndSettle();
      final round = FoodAtlas.fromJson(_fixture()).round(seed: 17);
      for (var pass = 0; pass < 2; pass++) {
        for (final question in round) {
          final wrong = question.optionsEn.firstWhere(
            (v) => v != question.answerEn,
          );
          final option = find.widgetWithText(OutlinedButton, wrong);
          await tester.ensureVisible(option);
          await tester.tap(option);
          await tester.pump();
          final check = find.widgetWithText(FilledButton, 'Check');
          await tester.ensureVisible(check);
          await tester.tap(check);
          await tester.pump();
          expect(find.text('Not quite.'), findsOneWidget);
          final next = find.widgetWithText(FilledButton, 'Next');
          await tester.scrollUntilVisible(next, 160);
          await tester.tap(next);
          await tester.pumpAndSettle();
        }
        expect(find.text('Original score: 0 correct.'), findsOneWidget);
        if (pass == 0) {
          await tester.tap(find.text('Retry missed'));
          await tester.pumpAndSettle();
        }
      }
      expect(find.text('Mistakes review complete.'), findsOneWidget);
      expect(find.text('Start again'), findsOneWidget);
      expect(find.text('Retry missed'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}

class _RecoveryBundle extends _Bundle {
  _RecoveryBundle(super.value);
  int loads = 0;
  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    if (++loads == 1) throw const FormatException('broken asset');
    return super.loadString(key, cache: cache);
  }
}

class _Bundle extends CachingAssetBundle {
  _Bundle(this.value);
  final String value;
  @override
  Future<ByteData> load(String key) async => throw FlutterError('binary $key');
  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    if (key == foodAtlasAsset) return value;
    throw FlutterError('asset $key');
  }
}

Map<String, dynamic> _fixture() => {
  'schema_version': 'qm-food-atlas/v1',
  'coverage_note_ru': 'Учебная подборка.',
  'coverage_note_en': 'Learning sample.',
  'sources': [
    {
      'id': 's1',
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
        'summary_ru': 'Краткое описание.',
        'summary_en': 'Short description.',
        'classic_note_ru': 'Региональная классическая версия.',
        'classic_note_en': 'Regional classic version.',
        'origin_ru': 'Связано с регионом $i.',
        'origin_en': 'Associated with region $i.',
        'servings_ru': 'На 4 порции.',
        'servings_en': 'Makes 4 servings.',
        'ingredients': [
          for (var j = 0; j < 3; j++)
            {
              'name_ru': 'Ингредиент ${i}_$j',
              'name_en': 'Ingredient ${i}_$j',
              'amount_ru': '${j + 1} шт.',
              'amount_en': '${j + 1} item',
            },
        ],
        'steps': [
          for (var j = 0; j < 3; j++)
            {
              'text_ru': 'Шаг ${j + 1}: готовить 10 минут.',
              'text_en': 'Step ${j + 1}: cook for 10 minutes.',
            },
        ],
        'facts': [
          {
            'text_ru': 'Факт $i.',
            'text_en': 'Fact $i.',
            'source_ids': ['s1'],
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
            'source_ids': ['s1'],
          },
        ],
        'source_ids': ['s1'],
      },
  ],
};
