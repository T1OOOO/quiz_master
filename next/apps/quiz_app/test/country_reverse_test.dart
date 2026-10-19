import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/country_learning.dart';

void main() {
  test('official language provenance is kept with the fact', () {
    final fact = CountryFact.fromJson({
      'id': 'CA',
      'name_en': 'Canada',
      'name_ru': 'Канада',
      'official_languages': ['English', 'French'],
      'official_languages_source': 'https://www.canada.ca/',
    });
    expect(fact.officialLanguagesSource, 'https://www.canada.ca/');
  });
  test('reverse associations exclude every other genuinely linked country', () {
    final doc = jsonDecode(
      File('assets/quizipedia/country_facts.json').readAsStringSync(),
    );
    final facts = (doc['countries'] as List)
        .map((r) => CountryFact.fromJson(r))
        .toList();
    final docLinks = jsonDecode(
      File('assets/quizipedia/country_links.json').readAsStringSync(),
    );
    final links = <String, List<CountryAssociation>>{
      for (final e in (docLinks['countries'] as Map).entries)
        e.key: (e.value as List)
            .map((r) => CountryAssociation.fromJson(r))
            .toList(),
    };
    final questions = CountryQuestion.associations(facts, links, reverse: true);
    expect(questions, isNotEmpty);
    for (final q in questions) {
      expect(q.reverse, isTrue);
      final valid = facts
          .where(
            (f) => (links[f.id] ?? []).any(
              (r) => r.kind == q.kind && r.nameEn == q.association!.nameEn,
            ),
          )
          .map((f) => f.nameEn)
          .toSet();
      expect(q.options.where(valid.contains), [q.answer]);
      expect(q.options.toSet().length, inInclusiveRange(4, 6));
    }
  });
}
