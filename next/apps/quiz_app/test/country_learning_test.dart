import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/country_learning.dart';
import 'package:quiz_app/country_labels_ru.dart';

import 'dart:convert';
import 'dart:io';

void main() {
  test('localizes the capital of Montserrat', () {
    expect(russianCountryLabel('Brades'), 'Брейдс');
  });
  test('shipped relation topics all produce single-answer questions', () {
    final doc = jsonDecode(
      File('assets/quizipedia/country_facts.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final facts = (doc['countries'] as List)
        .map((r) => CountryFact.fromJson(r as Map<String, dynamic>))
        .toList();
    final relations = <String, List<CountryAssociation>>{};
    for (final name in ['country_waters.json', 'country_links.json']) {
      final file = jsonDecode(
        File('assets/quizipedia/$name').readAsStringSync(),
      ) as Map<String, dynamic>;
      (file['countries'] as Map).forEach((id, rows) {
        relations
            .putIfAbsent(id as String, () => [])
            .addAll(
              (rows as List).map(
                (r) => CountryAssociation.fromJson(r as Map<String, dynamic>),
              ),
            );
      });
    }
    final pool = CountryQuestion.associations(facts, relations);
    for (final kind in [
      'water',
      'resource',
      'desert',
      'wonder',
      'landmark',
      'bridge',
      'scientist',
      'food',
      'sports_team',
    ]) {
      expect(pool.where((q) => q.kind == kind), isNotEmpty, reason: kind);
    }
    for (final q in pool) {
      expect(q.options, hasLength(6), reason: q.kind);
      final valid = relations[q.country.id]!
          .where((r) => r.kind == q.kind)
          .map((r) => r.nameEn)
          .toSet();
      expect(
        q.options.where(valid.contains).length,
        1,
        reason: '${q.country.id}/${q.kind}',
      );
    }
    expect(facts.firstWhere((f) => f.id == 'DE').neighbors, contains('FR'));
    expect(facts.firstWhere((f) => f.id == 'CA').neighbors, contains('DK'));
  });
  test(
    'shipped snapshot parses and every requested basic topic is playable',
    () {
      final doc = jsonDecode(
        File('assets/quizipedia/country_facts.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final facts = (doc['countries'] as List)
          .map((r) => CountryFact.fromJson(r as Map<String, dynamic>))
          .toList();
      expect(facts.length, 250);
      final pool = CountryQuestion.build(facts);
      expect(
        pool.firstWhere((q) => q.kind == 'population').prompt,
        contains('2024'),
      );
      for (final kind in [
        'flag',
        'capital',
        'language',
        'currency',
        'population',
        'area',
        'region',
      ]) {
        expect(
          pool.where((q) => q.kind == kind).length,
          greaterThan(3),
          reason: kind,
        );
      }
      for (final q in pool) { expect(q.options, hasLength(6), reason: q.kind); }
      final belgium = pool
          .where((q) => q.kind == 'language' && q.country.id == 'BE')
          .toList();
      expect(
        belgium,
        isNotEmpty,
        reason: 'Multilingual countries need official-language practice too.',
      );
      for (final q in belgium) {
        expect(
          q.options.where((v) => v != q.answer),
          isNot(contains(anyOf('French', 'German', 'Dutch'))),
        );
      }
    },
  );
  test('country facts only create questions with distinct answer values', () {
    final facts = [
      const CountryFact(
        id: 'FR',
        nameEn: 'France',
        nameRu: 'Франция',
        capital: 'Paris',
        languages: ['French'],
        currencies: ['EUR'],
        population: 68000000,
        populationYear: 2024,
        region: 'Europe',
      ),
      const CountryFact(
        id: 'DE',
        nameEn: 'Germany',
        nameRu: 'Германия',
        capital: 'Berlin',
        languages: ['German'],
        currencies: ['EUR'],
        population: 84000000,
        populationYear: 2024,
        region: 'Europe',
      ),
      const CountryFact(
        id: 'JP',
        nameEn: 'Japan',
        nameRu: 'Япония',
        capital: 'Tokyo',
        languages: ['Japanese'],
        currencies: ['JPY'],
        population: 124000000,
        populationYear: 2024,
        region: 'Asia',
      ),
      const CountryFact(
        id: 'BR',
        nameEn: 'Brazil',
        nameRu: 'Бразилия',
        capital: 'Brasília',
        languages: ['Portuguese'],
        currencies: ['BRL'],
        population: 212000000,
        populationYear: 2024,
        region: 'Americas',
      ),
    ];

    final questions = CountryQuestion.build(facts, count: 10);

    expect(questions, isNotEmpty);
    expect(
      questions.every((q) => q.options.toSet().length == q.options.length),
      isTrue,
    );
    expect(questions.every((q) => q.options.contains(q.answer)), isTrue);
    expect(questions.every((q) => q.options.length == 4), isTrue);
  });

  test('population questions use bands instead of an exact changing total', () {
    expect(populationBand(68000000), '50–100 million');
    expect(populationBand(124000000), '100–250 million');
  });

  test(
    'association questions never use another true relation as a distractor',
    () {
      final facts = [
        const CountryFact(
          id: 'FR',
          nameEn: 'France',
          nameRu: 'Франция',
          capital: '',
          languages: [],
          currencies: [],
          population: 0,
          populationYear: 0,
          region: 'Europe',
        ),
        const CountryFact(
          id: 'DE',
          nameEn: 'Germany',
          nameRu: 'Германия',
          capital: '',
          languages: [],
          currencies: [],
          population: 0,
          populationYear: 0,
          region: 'Europe',
        ),
        const CountryFact(
          id: 'IT',
          nameEn: 'Italy',
          nameRu: 'Италия',
          capital: '',
          languages: [],
          currencies: [],
          population: 0,
          populationYear: 0,
          region: 'Europe',
        ),
        const CountryFact(
          id: 'ES',
          nameEn: 'Spain',
          nameRu: 'Испания',
          capital: '',
          languages: [],
          currencies: [],
          population: 0,
          populationYear: 0,
          region: 'Europe',
        ),
      ];
      final questions = CountryQuestion.associations(facts, {
        'FR': [
          const CountryAssociation(
            id: 'a',
            kind: 'water',
            nameEn: 'Atlantic Ocean',
            nameRu: 'Атлантический океан',
          ),
          const CountryAssociation(
            id: 'b',
            kind: 'water',
            nameEn: 'Mediterranean Sea',
            nameRu: 'Средиземное море',
          ),
        ],
        'DE': [
          const CountryAssociation(
            id: 'c',
            kind: 'water',
            nameEn: 'North Sea',
            nameRu: 'Северное море',
          ),
        ],
        'IT': [
          const CountryAssociation(
            id: 'd',
            kind: 'water',
            nameEn: 'Adriatic Sea',
            nameRu: 'Адриатическое море',
          ),
        ],
        'ES': [
          const CountryAssociation(
            id: 'e',
            kind: 'water',
            nameEn: 'Bay of Biscay',
            nameRu: 'Бискайский залив',
          ),
        ],
      });
      final france = questions.where((q) => q.country.id == 'FR').first;
      final otherTrue = france.answer == 'Atlantic Ocean'
          ? 'Mediterranean Sea'
          : 'Atlantic Ocean';
      expect(
        france.options.where((option) => option != france.answer),
        isNot(contains(otherTrue)),
      );
    },
  );
}
