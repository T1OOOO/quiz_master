import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/fact_practice_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('shipped anatomy includes all adult skeletal groups and source-linked brain practice', () async {
    final all = await loadStudyFacts('all');
    final organs = all.where((f) => f.scope == 'organs').toList();
    final counts = organs.where((f) => f.fieldPath == 'bone_count').toList();
    expect(counts, hasLength(8));
    expect(counts.fold<int>(0, (sum, f) => sum + int.parse(f.valueRu)), 206);
    expect(
      organs.where((f) => f.fieldPath == 'kind' && f.valueRu == 'Отдел мозга'),
      hasLength(15),
    );
    expect(organs.map((f) => f.entityId).toSet(), hasLength(75));
    final summary = {
      'facts': all.length,
      'sections': all.map((f) => f.scope).toSet().length,
      'organs': 75,
      'bone_groups': counts.length,
    };
    // This receipt supplies measured coverage to the release package producer.
    // ignore: avoid_print
    print('FACT_COVERAGE ${jsonEncode(summary)}');
  });
  test('skeletal counts and optional Latin are available to fact practice in Russian', () {
    final assets = <String, Map<String, dynamic>>{
      for (final name in [
        'country_facts',
        'country_religions',
        'catalog',
        'music_learning',
        'organ_atlas',
        'belief_atlas',
        'food_atlas',
        'brands',
        'knowledge_atlas',
        'country_links',
        'country_culture',
        'country_waters',
        'country_presidents',
      ])
        'assets/quizipedia/$name.json': {},
    };
    assets['assets/quizipedia/organ_atlas.json'] = {
      'sources': [
        {
          'id': 'anatomy',
          'title': 'Анатомия',
          'url': 'https://openstax.org/books/anatomy-and-physiology-2e/pages/7-2-the-skull',
        },
      ],
      'organs': [
        {
          'id': 'cranial-bones',
          'name_ru': 'Кости мозгового черепа',
          'name_en': 'Cranial bones',
          'name_la': 'Ossa cranii',
          'bone_count': 8,
          'kind': 'bone_group',
          'region': 'head',
          'source_ids': ['anatomy'],
        },
      ],
    };
    final facts = extractStudyFacts(assets);
    expect(facts.singleWhere((f) => f.fieldPath == 'region').valueRu, 'Голова');
    expect(
      facts.singleWhere((f) => f.fieldPath == 'kind').valueRu,
      'Группа костей',
    );
    expect(facts.singleWhere((f) => f.fieldPath == 'bone_count').valueRu, '8');
    expect(
      facts.singleWhere((f) => f.fieldPath == 'name_la').valueRu,
      'Ossa cranii',
    );
  });
}
