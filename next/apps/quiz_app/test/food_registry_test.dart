import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/food_atlas_models.dart';

void main() {
  test(
    'shipped food questions use regions for origins and names for composition',
    () {
      final atlas = FoodAtlas.fromJson(
        jsonDecode(File('assets/quizipedia/food_atlas.json').readAsStringSync())
            as Map<String, dynamic>,
      );
      for (final topic in [null, ...FoodQuestionKind.values]) {
        for (var seed = 0; seed < 10; seed++) {
          final round = atlas.round(seed: seed, topic: topic);
          expect(round, hasLength(10));
          expect(round.map((q) => q.dishId).toSet(), hasLength(10));
          for (final question in round) {
            final dish = atlas.dishes.firstWhere(
              (d) => d.id == question.dishId,
            );
            final origin = question.kind == FoodQuestionKind.origin;
            expect(question.answerEn, origin ? dish.regionEn : dish.nameEn);
            expect(question.answerRu, origin ? dish.regionRu : dish.nameRu);
            expect(question.optionsEn.toSet(), hasLength(6));
            expect(question.optionsRu.toSet(), hasLength(6));
            expect(
              question.optionsEn.where((v) => v == question.answerEn),
              hasLength(1),
            );
            expect(
              question.optionsRu.where((v) => v == question.answerRu),
              hasLength(1),
            );
            if (topic != null) expect(question.kind, topic);
          }
        }
      }
    },
  );
  test('food registry contains sourced complete classic recipe cards', () {
    final doc = jsonDecode(
      File('assets/quizipedia/food_atlas.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    expect(doc['schema_version'], 'qm-food-atlas/v1');
    final dishes = (doc['dishes'] as List).cast<Map<String, dynamic>>();
    final sources = (doc['sources'] as List).cast<Map<String, dynamic>>();
    expect(dishes.length, greaterThanOrEqualTo(10));
    expect(dishes.map((d) => d['id']).toSet().length, dishes.length);
    expect(
      dishes.map((d) => d['country_en']).toSet().length,
      greaterThanOrEqualTo(8),
    );
    final sourceIds = sources.map((s) => s['id']).toSet();
    expect(sourceIds.length, sources.length);
    for (final source in sources) {
      final uri = Uri.parse(source['url'] as String);
      expect(uri.scheme, 'https');
      expect(uri.host, isNotEmpty);
      expect(DateTime.tryParse(source['checked_on'] as String), isNotNull);
    }
    void references(Map<String, dynamic> row) {
      final ids = row['source_ids'] as List;
      expect(ids, isNotEmpty);
      expect(ids.every(sourceIds.contains), isTrue, reason: '$row');
    }

    void bilingual(Map<String, dynamic> row, List<String> fields) {
      for (final field in fields) {
        for (final language in ['ru', 'en']) {
          expect(row['${field}_$language'], isA<String>());
          expect((row['${field}_$language'] as String).trim(), isNotEmpty);
        }
      }
    }

    for (final dish in dishes) {
      bilingual(dish, [
        'name',
        'category',
        'country',
        'region',
        'summary',
        'classic_note',
        'origin',
        'servings',
      ]);
      references(dish);
      expect(dish['ingredients'], hasLength(greaterThanOrEqualTo(3)));
      for (final ingredient in dish['ingredients'] as List) {
        bilingual(ingredient as Map<String, dynamic>, ['name', 'amount']);
      }
      expect(dish['steps'], hasLength(greaterThanOrEqualTo(3)));
      for (final step in dish['steps'] as List) {
        bilingual(step as Map<String, dynamic>, ['text']);
      }
      expect(dish['facts'], isNotEmpty);
      for (final fact in dish['facts'] as List) {
        bilingual(fact as Map<String, dynamic>, ['text']);
        references(fact);
      }
      expect(dish['variants'], isA<List>());
      for (final variant in dish['variants'] as List) {
        bilingual(variant as Map<String, dynamic>, [
          'name',
          'region',
          'difference',
        ]);
        references(variant);
      }
    }
  });
}
