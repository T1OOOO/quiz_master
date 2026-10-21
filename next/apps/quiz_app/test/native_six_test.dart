import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/brand_atlas.dart';
import 'package:quiz_app/food_atlas_models.dart';
import 'package:quiz_app/organ_atlas_models.dart';
import 'package:quiz_app/belief_atlas_models.dart';

void main() {
  test('all shipped anatomy and belief questions offer six reviewed unique choices', () {
    final organs = OrganAtlas.fromJson(
      jsonDecode(File('assets/quizipedia/organ_atlas.json').readAsStringSync()),
    );
    final beliefs = BeliefAtlas.fromJson(
      jsonDecode(
        File('assets/quizipedia/belief_atlas.json').readAsStringSync(),
      ),
    );
    for (final q in organs.questions) {
      expect(q.optionIds.toSet(), hasLength(6), reason: q.id);
      expect(q.optionIds.where((id) => id == q.correctId), hasLength(1));
    }
    for (final q in beliefs.questions) {
      expect(q.options.toSet(), hasLength(6), reason: q.id);
      expect(q.options.where((id) => id == q.correct), hasLength(1));
    }
  });
  test('shipped brands and dishes offer six unique choices with one key', () {
    final brands = BrandAtlas.fromJson(
      jsonDecode(File('assets/quizipedia/brands.json').readAsStringSync()),
    );
    final food = FoodAtlas.fromJson(
      jsonDecode(File('assets/quizipedia/food_atlas.json').readAsStringSync()),
    );
    expect(brands.questions, isNotEmpty);
    for (final question in brands.questions) {
      expect(question.options.toSet(), hasLength(6));
      expect(
        question.options.where((option) => option == question.answer),
        hasLength(1),
      );
    }
    for (final question in food.round()) {
      expect(question.optionsRu.toSet(), hasLength(6));
      expect(question.optionsEn.toSet(), hasLength(6));
      expect(
        question.optionsEn.where((option) => option == question.answerEn),
        hasLength(1),
      );
    }
  });
}
