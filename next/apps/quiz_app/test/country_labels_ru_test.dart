import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/country_labels_ru.dart';

void main() {
  test(
    'every shipped capital, source language, and currency has a Russian label',
    () {
      final document = jsonDecode(
        File('assets/quizipedia/country_facts.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final countries = (document['countries'] as List).cast<Map>();
      final values = <String>{
        for (final country in countries)
          if ((country['capital'] as String? ?? '').isNotEmpty)
            country['capital'] as String,
        for (final country in countries)
          ...((country['languages'] as List? ?? const []).cast<String>()),
        for (final country in countries)
          ...((country['currencies'] as List? ?? const []).cast<String>()),
      };

      expect(values.length, greaterThan(500));
      expect(russianCountryLabels.keys, containsAll(values));
      for (final value in values) {
        final label = russianCountryLabel(value);
        expect(label, isNot(value), reason: value);
        expect(label, isNot(matches(RegExp(r'[A-Za-z]'))), reason: value);
      }
    },
  );

  test('composite capitals retain their qualifier in Russian', () {
    expect(
      russianCountryLabel(
        'Pretoria (administrative); Cape Town (legislative); Bloemfontein (judicial)',
      ),
      'Претория (административная); Кейптаун (законодательная); Блумфонтейн (судебная)',
    );
  });

  test('unknown synthetic values remain unchanged', () {
    expect(
      russianCountryLabel('Synthetic fixture value'),
      'Synthetic fixture value',
    );
  });
}
