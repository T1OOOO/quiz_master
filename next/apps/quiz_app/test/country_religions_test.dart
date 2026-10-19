import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/country_religions.dart';

void main() {
  test(
    'affiliation categories have no inferred official status or atheist label',
    () {
      final atlas = CountryReligions.fromJson(_fixture());
      expect(atlas.year, 2020);
      expect(atlas.countries['AA']!.largestGroups, [
        'Religiously_unaffiliated',
      ]);
      expect(
        religionGroups['Religiously_unaffiliated']!.nameRu,
        'Без религиозной принадлежности',
      );
      expect(
        atlas.countries['AA']!.mapLabel(ru: false, year: atlas.year),
        contains('2020'),
      );
    },
  );

  test('rounded ties do not silently select one religion', () {
    final data = _fixture();
    data['countries'][0]['shares'] = {
      'Christians': 40.04,
      'Muslims': 40.03,
      'Religiously_unaffiliated': 19.93,
      'Buddhists': 0,
      'Hindus': 0,
      'Jews': 0,
      'Other_religions': 0,
    };
    final row = CountryReligions.fromJson(data).countries['AA']!;
    expect(row.largestGroups, containsAll(['Christians', 'Muslims']));
    expect(row.largestGroups, hasLength(2));
  });

  test(
    'invalid shares, duplicate IDs and impossible dates fail at the boundary',
    () {
      final badShare = _fixture();
      badShare['countries'][0]['shares']['Christians'] = double.nan;
      expect(() => CountryReligions.fromJson(badShare), throwsFormatException);
      final sum = _fixture();
      sum['countries'][0]['shares']['Christians'] = 75;
      expect(() => CountryReligions.fromJson(sum), throwsFormatException);
      final duplicate = _fixture();
      duplicate['countries'].add(duplicate['countries'][0]);
      expect(() => CountryReligions.fromJson(duplicate), throwsFormatException);
      final date = _fixture()..['checked_on'] = '2026-02-30';
      expect(() => CountryReligions.fromJson(date), throwsFormatException);
    },
  );

  test(
    'Pew snapshot is mapped to country IDs with source year and seven shares',
    () {
      final atlas = CountryReligions.fromJson(
        jsonDecode(
          File('assets/quizipedia/country_religions.json').readAsStringSync(),
        ) as Map<String, dynamic>,
      );
      expect(atlas.year, 2020);
      expect(atlas.publishedYear, 2025);
      expect(atlas.countries, hasLength(200));
      expect(atlas.countries.keys, containsAll(['US', 'CN', 'IN', 'JP', 'XK']));
      expect(
        atlas.countries.keys,
        isNot(contains('GG')),
        reason: 'Channel Islands aggregate must not be assigned to Guernsey.',
      );
      expect(atlas.countries.keys, isNot(contains('JE')));
      final countries = jsonDecode(
        File('assets/quizipedia/country_facts.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final ids = (countries['countries'] as List).map((r) => r['id']).toSet();
      expect(atlas.countries.keys.every(ids.contains), isTrue);
      expect(atlas.countries['US']!.largestGroups, ['Christians']);
      expect(atlas.countries['CN']!.largestGroups, [
        'Religiously_unaffiliated',
      ]);
      expect(atlas.countries['IN']!.largestGroups, ['Hindus']);
    },
  );
}

Map<String, dynamic> _fixture() => {
  'schema_version': 'qm-country-religions/v1',
  'year': 2020,
  'published_year': 2025,
  'checked_on': '2026-10-19',
  'source_url': 'https://www.pewresearch.org/religion/feature/religious-composition-by-country-2010-2020/',
  'methodology_url': 'https://www.pewresearch.org/religion/2025/06/09/global-religious-change-methodology/',
  'countries': <Map<String, dynamic>>[
    {
      'id': 'AA',
      'source_name': 'Example',
      'shares': <String, dynamic>{
        'Christians': 10,
        'Muslims': 5,
        'Religiously_unaffiliated': 80,
        'Buddhists': 2,
        'Hindus': 1,
        'Jews': 1,
        'Other_religions': 1,
      },
    },
  ],
};
