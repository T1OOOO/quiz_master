/// Source-year estimates of affiliation, never a country's legal religion.
library;

import 'dart:convert';

import 'package:flutter/services.dart';

const countryReligionsAsset = 'assets/quizipedia/country_religions.json';

class ReligionGroup {
  const ReligionGroup(this.nameEn, this.nameRu, this.searchTerms);
  final String nameEn, nameRu, searchTerms;
  String name(bool ru) => ru ? nameRu : nameEn;
}

const religionGroups = <String, ReligionGroup>{
  'Christians': ReligionGroup(
    'Christians',
    'Христиане',
    'Christianity христианство',
  ),
  'Muslims': ReligionGroup('Muslims', 'Мусульмане', 'Islam ислам'),
  'Religiously_unaffiliated': ReligionGroup(
    'Religiously unaffiliated',
    'Без религиозной принадлежности',
    'unaffiliated без религиозной принадлежности',
  ),
  'Buddhists': ReligionGroup('Buddhists', 'Буддисты', 'Buddhism буддизм'),
  'Hindus': ReligionGroup('Hindus', 'Индуисты', 'Hinduism индуизм'),
  'Jews': ReligionGroup('Jews', 'Иудеи', 'Judaism иудаизм'),
  'Other_religions': ReligionGroup(
    'Other religions (combined)',
    'Другие религии (суммарно)',
    'other другие',
  ),
};

String affiliationPercent(double value) =>
    value > 0 && value < .1 ? '<0.1%' : '${value.toStringAsFixed(1)}%';

class CountryReligion {
  const CountryReligion(this.id, this.sourceName, this.shares);
  final String id, sourceName;
  final Map<String, double> shares;

  List<String> get largestGroups {
    final rounded = shares.map(
      (id, share) => MapEntry(id, (share * 10).round()),
    );
    final largest = rounded.values.reduce((a, b) => a > b ? a : b);
    return rounded.keys
        .where((id) => rounded[id] == largest)
        .toList(growable: false);
  }

  String mapLabel({required bool ru, required int year}) {
    final groups = largestGroups;
    return '${groups.map((id) => religionGroups[id]!.name(ru)).join(' / ')} '
        '${affiliationPercent(shares[groups.first]!)} · $year';
  }

  bool matches(String query) => largestGroups.any((id) {
    final group = religionGroups[id]!;
    return '${group.nameRu} ${group.nameEn} ${group.searchTerms}'
        .toLowerCase()
        .contains(query.trim().toLowerCase());
  });
}

class CountryReligions {
  const CountryReligions({
    required this.year,
    required this.publishedYear,
    required this.sourceUrl,
    required this.methodologyUrl,
    required this.countries,
  });
  final int year, publishedYear;
  final String sourceUrl, methodologyUrl;
  final Map<String, CountryReligion> countries;

  static Future<CountryReligions> load([AssetBundle? bundle]) async =>
      CountryReligions.fromJson(
        jsonDecode(
          await (bundle ?? rootBundle).loadString(countryReligionsAsset),
        ) as Map<String, dynamic>,
      );

  factory CountryReligions.fromJson(Map<String, dynamic> data) {
    if (data['schema_version'] != 'qm-country-religions/v1') {
      throw const FormatException('country religion schema');
    }
    final year = data['year'], published = data['published_year'];
    if (year is! int ||
        published is! int ||
        year < 1900 ||
        year > 2100 ||
        published < year ||
        published > 2100) {
      throw const FormatException('religion source years');
    }
    String url(String field) {
      final value = data[field];
      final parsed = value is String ? Uri.tryParse(value) : null;
      if (parsed == null || parsed.scheme != 'https' || parsed.host.isEmpty) {
        throw FormatException('$field HTTPS URL');
      }
      return value as String;
    }

    final checked = data['checked_on'];
    final parsed = checked is String ? DateTime.tryParse(checked) : null;
    if (checked is! String ||
        !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(checked) ||
        parsed == null ||
        parsed.toIso8601String().substring(0, 10) != checked) {
      throw const FormatException('religion checked date');
    }
    final rows = data['countries'];
    if (rows is! List) throw const FormatException('religion countries');
    final countries = <String, CountryReligion>{};
    for (final row in rows) {
      if (row is! Map) throw const FormatException('religion country row');
      final id = row['id'], name = row['source_name'], values = row['shares'];
      if (id is! String ||
          !RegExp(r'^[A-Z]{2}$').hasMatch(id) ||
          countries.containsKey(id) ||
          name is! String ||
          name.trim().isEmpty ||
          values is! Map ||
          values.length != religionGroups.length) {
        throw const FormatException('religion country fields');
      }
      final shares = <String, double>{};
      for (final group in religionGroups.keys) {
        final value = values[group];
        if (value is! num || !value.isFinite || value < 0 || value > 100) {
          throw const FormatException('religion percentage');
        }
        shares[group] = value.toDouble();
      }
      if ((shares.values.reduce((a, b) => a + b) - 100).abs() > .1) {
        throw const FormatException('religion percentages total');
      }
      countries[id] = CountryReligion(id, name, Map.unmodifiable(shares));
    }
    return CountryReligions(
      year: year,
      publishedYear: published,
      sourceUrl: url('source_url'),
      methodologyUrl: url('methodology_url'),
      countries: Map.unmodifiable(countries),
    );
  }
}
