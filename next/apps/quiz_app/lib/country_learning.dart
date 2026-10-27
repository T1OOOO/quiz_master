/// Local country-atlas learning. It deliberately keeps volatile facts in a
/// source-labelled asset and creates no question for fields that are absent.
library;

import 'fact_practice.dart';

import 'russian_learning_text.dart';

import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'quizipedia.dart';
import 'waterways_models.dart';
import 'waterways_page.dart';
import 'country_religions.dart';
import 'music_learning.dart';
import 'country_labels_ru.dart';

const _factsAsset = 'assets/quizipedia/country_facts.json';

const _mapLayers = [
  'flag',
  'capital',
  'currency',
  'population',
  'area',
  'water',
  'resource',
  'neighbor',
  'religion',
  'instrument',
  'culture',
];

const _russianFactLabels = <String, String>{
  'All': 'Весь мир',
  'Europe': 'Европа',
  'Asia': 'Азия',
  'Africa': 'Африка',
  'Americas': 'Америка',
  'Oceania': 'Океания',
  'Antarctic': 'Антарктика',
  'Antarctica': 'Антарктида',
  'German': 'Немецкий',
  'French': 'Французский',
  'English': 'Английский',
  'Spanish': 'Испанский',
  'Portuguese': 'Португальский',
  'Italian': 'Итальянский',
  'Russian': 'Русский',
  'Dutch': 'Нидерландский',
  'Czech': 'Чешский',
  'Danish': 'Датский',
  'Finnish': 'Финский',
  'Swedish': 'Шведский',
  'Greek': 'Греческий',
  'Hungarian': 'Венгерский',
  'Polish': 'Польский',
  'Romanian': 'Румынский',
  'Bulgarian': 'Болгарский',
  'Norwegian': 'Норвежский',
  'Arabic': 'Арабский',
  'Chinese': 'Китайский',
  'Japanese': 'Японский',
  'Hindi': 'Хинди',
  'Turkish': 'Турецкий',
  'Korean': 'Корейский',
  'Paris': 'Париж',
  'Berlin': 'Берлин',
  'Rome': 'Рим',
  'Madrid': 'Мадрид',
  'London': 'Лондон',
  'Tokyo': 'Токио',
  'Beijing': 'Пекин',
  'Moscow': 'Москва',
  'Brasília': 'Бразилиа',
  'Ottawa': 'Оттава',
  'Washington D.C.': 'Вашингтон',
  'Washington, D.C.': 'Вашингтон',
  'Canberra': 'Канберра',
  'New Delhi': 'Нью-Дели',
  'Cairo': 'Каир',
  'Ankara': 'Анкара',
  'Astana': 'Астана',
  'Kyiv': 'Киев',
  'Warsaw': 'Варшава',
  'Lisbon': 'Лиссабон',
  'Prague': 'Прага',
  'Vienna': 'Вена',
  'Athens': 'Афины',
  'Stockholm': 'Стокгольм',
  'Helsinki': 'Хельсинки',
  'Copenhagen': 'Копенгаген',
  'Oslo': 'Осло',
  'Brussels': 'Брюссель',
  'Amsterdam': 'Амстердам',
  'Bern': 'Берн',
  'Budapest': 'Будапешт',
  'Bucharest': 'Бухарест',
  'Sofia': 'София',
  'Belgrade': 'Белград',
  'Dublin': 'Дублин',
  'Mexico City': 'Мехико',
  'Buenos Aires': 'Буэнос-Айрес',
  'Lima': 'Лима',
  'Santiago': 'Сантьяго',
  'Bangkok': 'Бангкок',
  'Hanoi': 'Ханой',
  'Jakarta': 'Джакарта',
  'Seoul': 'Сеул',
  'Riyadh': 'Эр-Рияд',
  'Abu Dhabi': 'Абу-Даби',
  'Tehran': 'Тегеран',
  'Baghdad': 'Багдад',
  'Tbilisi': 'Тбилиси',
  'Yerevan': 'Ереван',
  'Baku': 'Баку',
  'Tashkent': 'Ташкент',
  'Minsk': 'Минск',
  'Riga': 'Рига',
  'Tallinn': 'Таллин',
  'Vilnius': 'Вильнюс',
  'Nairobi': 'Найроби',
  'Rabat': 'Рабат',
  'Tunis': 'Тунис',
  'Pretoria': 'Претория',
  'Cape Town': 'Кейптаун',
  'Bloemfontein': 'Блумфонтейн',
};

class CountryFact {
  const CountryFact({
    required this.id,
    required this.nameEn,
    required this.nameRu,
    required this.capital,
    required this.languages,
    required this.currencies,
    required this.population,
    required this.populationYear,
    required this.region,
    this.sourceLanguages = const [],
    this.areaKm2,
    this.neighbors = const [],
    this.neighborSources = const {},
    this.officialLanguagesSource = '',
  });
  final String id, nameEn, nameRu, capital, region;
  final String officialLanguagesSource;
  final List<String> languages, sourceLanguages, currencies, neighbors;
  final int population, populationYear;
  final double? areaKm2;
  final Map<String, String> neighborSources;

  factory CountryFact.fromJson(Map<String, dynamic> json) => CountryFact(
    id: json['id'] as String,
    nameEn: json['name_en'] as String,
    nameRu: json['name_ru'] as String,
    capital: json['capital'] as String? ?? '',
    languages: (json['official_languages'] as List? ?? [])
        .whereType<String>()
        .toList(),
    sourceLanguages: (json['languages'] as List? ?? [])
        .whereType<String>()
        .toList(),
    currencies: (json['currencies'] as List? ?? [])
        .whereType<String>()
        .toList(),
    population: json['population'] as int? ?? 0,
    populationYear: json['population_year'] as int? ?? 0,
    region: json['region'] as String? ?? '',
    officialLanguagesSource: json['official_languages_source'] as String? ?? '',
    areaKm2: (json['area_km2'] as num?)?.toDouble(),
    neighbors: (json['neighbors'] as List? ?? []).cast<String>(),
    neighborSources: Map<String, String>.from(
      json['neighbor_sources'] as Map? ?? const {},
    ),
  );

  factory CountryFact.fromRestCountries(Map<String, dynamic> json) {
    final name = Map<String, dynamic>.from(json['name'] as Map);
    final translations = json['translations'] is Map
        ? Map<String, dynamic>.from(json['translations'] as Map)
        : const <String, dynamic>{};
    final russian = translations['rus'] is Map
        ? Map<String, dynamic>.from(translations['rus'] as Map)
        : const <String, dynamic>{};
    final languages = json['languages'] is Map
        ? Map<String, dynamic>.from(json['languages'] as Map).values
              .whereType<String>()
              .toList()
        : const <String>[];
    return CountryFact(
      id: json['cca2'] as String,
      nameEn: name['common'] as String,
      nameRu: russian['common'] as String? ?? name['common'] as String,
      capital: (json['capital'] as List? ?? const []).whereType<String>().join(
        ', ',
      ),
      languages: languages,
      sourceLanguages: languages,
      currencies: json['currencies'] is Map
          ? Map<String, dynamic>.from(json['currencies'] as Map).keys.toList()
          : const [],
      population: json['population'] as int? ?? 0,
      populationYear: 0,
      region: json['region'] as String? ?? '',
      areaKm2: (json['area'] as num?)?.toDouble(),
      neighbors: (json['borders'] as List? ?? const [])
          .whereType<String>()
          .toList(),
    );
  }

  static Future<List<CountryFact>> load([AssetBundle? bundle]) async {
    final raw = await (bundle ?? rootBundle).loadString(_factsAsset);
    final decoded = jsonDecode(raw);
    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map(
            (row) =>
                CountryFact.fromRestCountries(Map<String, dynamic>.from(row)),
          )
          .where((fact) => fact.id.length == 2)
          .toList(growable: false);
    }
    final json = decoded as Map<String, dynamic>;
    return (json['countries'] as List)
        .map(
          (row) => CountryFact.fromJson(Map<String, dynamic>.from(row as Map)),
        )
        .toList(growable: false);
  }
}

/// Normalised verified capital positions: dx west→east and dy north→south.
/// This separate source is loaded only after the capital map layer is enabled.
Future<Map<String, Offset>> loadCapitalPoints([AssetBundle? bundle]) async {
  final decoded = jsonDecode(
    await (bundle ?? rootBundle).loadString(
      'assets/quizipedia/capital_points.json',
    ),
  );
  final rows = Map<String, dynamic>.from(decoded as Map)['capitals'] as List;
  return Map.unmodifiable({
    for (final raw in rows.whereType<Map>())
      if ((raw['country_id'] as String?)?.length == 2 &&
          raw['longitude'] is num &&
          raw['latitude'] is num)
        raw['country_id'] as String: Offset(
          ((raw['longitude'] as num).toDouble() + 180) / 360,
          (90 - (raw['latitude'] as num).toDouble()) / 180,
        ),
  });
}

String populationBand(int population) {
  if (population < 1000000) return 'under 1 million';
  if (population < 10000000) return '1–10 million';
  if (population < 50000000) return '10–50 million';
  if (population < 100000000) return '50–100 million';
  if (population < 250000000) return '100–250 million';
  return '250 million+';
}

String areaBand(double area) {
  if (area < 1000) return 'under 1,000 km²';
  if (area < 10000) return '1,000–10,000 km²';
  if (area < 100000) return '10,000–100,000 km²';
  if (area < 1000000) return '100,000–1 million km²';
  if (area < 5000000) return '1–5 million km²';
  return '5 million km²+';
}

class CountryAssociation {
  const CountryAssociation({
    required this.id,
    required this.kind,
    required this.nameEn,
    required this.nameRu,
    this.relationEn = '',
    this.relationRu = '',
    this.sourceId = '',
    this.checked = '',
    this.sourceUrl = '',
  });
  final String id,
      kind,
      nameEn,
      nameRu,
      relationEn,
      relationRu,
      sourceId,
      checked,
      sourceUrl;

  factory CountryAssociation.fromJson(Map<String, dynamic> json) =>
      CountryAssociation(
        id: json['id'] as String,
        kind: json['kind'] as String? ?? 'water',
        nameEn: json['name_en'] as String,
        nameRu: json['name_ru'] as String,
        relationEn:
            json['relation_en'] as String? ??
            switch (json['relation']) {
              'coast' => 'Coastal sea or ocean',
              'internal' => 'Lake within the country',
              'border' => 'Shared border lake',
              'flows' => 'River flowing through or along the country',
              _ => '',
            },
        relationRu:
            json['relation_ru'] as String? ??
            switch (json['relation']) {
              'coast' => 'Омывает берега',
              'internal' => 'Озеро на территории страны',
              'border' => 'Пограничное озеро',
              'flows' => 'Река проходит по территории или границе',
              _ => '',
            },
        sourceId: json['source_id'] as String? ?? '',
        checked: json['checked'] as String? ?? '',
        sourceUrl: json['source_url'] as String? ?? '',
      );
}

Future<Map<String, List<CountryAssociation>>> loadCountryAssociations(
  String asset, {
  String defaultKind = 'water',
  AssetBundle? bundle,
}) async {
  final raw = jsonDecode(
    await (bundle ?? rootBundle).loadString(asset),
  ) as Map<String, dynamic>;
  final sources = {
    for (final source in raw['sources'] as List)
      source['id'] as String: source['url'] as String,
  };
  final countries = Map<String, dynamic>.from(
    raw['countries'] as Map? ?? const {},
  );
  return countries.map(
    (id, rows) => MapEntry(
      id,
      (rows as List).whereType<Map>().map((row) {
        final value = Map<String, dynamic>.from(row);
        value.putIfAbsent('kind', () => defaultKind);
        value['source_url'] = sources[value['source_id']] ?? '';
        return CountryAssociation.fromJson(value);
      }).toList(),
    ),
  );
}

Future<Map<String, List<CountryAssociation>>> loadCountryPresidents([
  AssetBundle? bundle,
]) async {
  final raw = jsonDecode(
    await (bundle ?? rootBundle).loadString(
      'assets/quizipedia/country_presidents.json',
    ),
  ) as Map<String, dynamic>;
  final countries = Map<String, dynamic>.from(
    raw['countries'] as Map? ?? const {},
  );
  final sources = {
    for (final source in raw['sources'] as List)
      source['id'] as String: source['url'] as String,
  };
  return countries.map((id, value) {
    final row = Map<String, dynamic>.from(value as Map);
    return MapEntry(id, [
      CountryAssociation(
        id: 'president-$id',
        kind: 'president',
        nameEn: row['name_en'] as String,
        nameRu: row['name_ru'] as String,
        sourceId: row['source_id'] as String? ?? '',
        checked: row['checked'] as String? ?? '',
        sourceUrl: sources[row['source_id']] ?? '',
      ),
    ]);
  });
}

class CountryQuestion {
  const CountryQuestion(
    this.kind,
    this.country,
    this.prompt,
    this.answer,
    this.options, {
    this.source = '',
    this.association,
    this.reverse = false,
  });
  final String kind, prompt, answer;
  final CountryFact country;
  final List<String> options;
  final String source;
  final CountryAssociation? association;
  final bool reverse;

  static List<CountryQuestion> associations(
    List<CountryFact> facts,
    Map<String, List<CountryAssociation>> associations, {
    String? kind,
    bool reverse = false,
  }) {
    final random = math.Random();
    final result = <CountryQuestion>[];
    for (final fact in facts) {
      final trueRows = (associations[fact.id] ?? const [])
          .where((row) => kind == null || row.kind == kind)
          .toList();
      for (final row in trueRows) {
        if (reverse) {
          final valid = facts
              .where(
                (candidate) => (associations[candidate.id] ?? const []).any(
                  (r) => r.kind == row.kind && r.nameEn == row.nameEn,
                ),
              )
              .map((f) => f.nameEn)
              .toSet();
          final distractors =
              facts.map((f) => f.nameEn).toSet().difference(valid).toList()
                ..shuffle(random);
          if (distractors.length < 3) continue;
          result.add(
            CountryQuestion(
              row.kind,
              fact,
              'According to this atlas, which country lists ${row.nameEn} (${row.relationEn})?',
              fact.nameEn,
              [fact.nameEn, ...distractors.take(5)]..shuffle(random),
              association: row,
              source: row.checked,
              reverse: true,
            ),
          );
          continue;
        }
        final trueNames = trueRows
            .where((candidate) => candidate.kind == row.kind)
            .map((candidate) => candidate.nameEn)
            .toSet();
        final falseNames = associations.values
            .expand(
              (rows) => rows.where((candidate) => candidate.kind == row.kind),
            )
            .map((candidate) => candidate.nameEn)
            .toSet()
            .difference(trueNames)
            .toList();
        if (falseNames.length < 3) continue;
        final options = [row.nameEn, ...(falseNames..shuffle(random)).take(5)]
          ..shuffle(random);
        result.add(
          CountryQuestion(
            row.kind,
            fact,
            _associationPrompt(row, fact.nameEn),
            row.nameEn,
            options,
            association: row,
            source: row.checked,
          ),
        );
      }
    }
    result.shuffle(random);
    return result;
  }

  static String _associationPrompt(
    CountryAssociation row,
    String country,
  ) => switch (row.kind) {
    'neighbor' => 'Which country shares a land border with $country?',
    'water' => 'Which major water body is listed for $country?',
    'president' => 'Who is the president of $country as of ${row.checked}?',
    'scientist' =>
      'Which scientist was born in the territory of modern $country?',
    'food' => 'Which culinary tradition is listed for $country?',
    'sports_team' => 'Which sports club is based in $country?',
    'religion' =>
      'Which affiliation category was largest in $country in Pew Research Center estimates for ${row.checked}?',
    'instrument' =>
      'According to this atlas, which musical instrument is associated with $country?',
    'culture' =>
      'According to this atlas, which cultural tradition is associated with $country?',
    'resource' => 'Which resource is listed for $country?',
    _ => 'Which ${row.kind} is associated with $country?',
  };

  static List<CountryQuestion> build(
    List<CountryFact> facts, {
    int count = 10000,
  }) {
    final random = math.Random();
    final result = <CountryQuestion>[];
    for (final fact in facts) {
      final flagChoices = facts.map((other) => other.nameEn).toSet()
        ..remove(fact.nameEn);
      if (flagChoices.length >= 3) {
        final distractors = flagChoices.toList()..shuffle(random);
        final options = [fact.nameEn, ...distractors.take(5)]..shuffle(random);
        result.add(
          CountryQuestion(
            'flag',
            fact,
            'Which country has this flag?',
            fact.nameEn,
            options,
          ),
        );
      }
      final values = <String, String>{
        if (fact.capital.isNotEmpty) 'capital': fact.capital,
        if (fact.languages.isNotEmpty) 'language': fact.languages.first,
        if (fact.currencies.isNotEmpty) 'currency': fact.currencies.first,
        if (fact.region.isNotEmpty) 'region': fact.region,
        if (fact.population > 0) 'population': populationBand(fact.population),
        if (fact.areaKm2 != null) 'area': areaBand(fact.areaKm2!),
      };
      for (final entry in values.entries) {
        if (entry.key == 'language' || entry.key == 'currency') {
          final valid = entry.key == 'language'
              ? fact.languages
              : fact.currencies;
          final alternatives =
              facts
                  .expand(
                    (f) => entry.key == 'language' ? f.languages : f.currencies,
                  )
                  .toSet()
                  .difference(valid.toSet())
                  .toList()
                ..shuffle(random);
          if (alternatives.length < 3) continue;
          final answer = valid[random.nextInt(valid.length)];
          result.add(
            CountryQuestion(
              entry.key,
              fact,
              entry.key == 'language'
                  ? 'Which is one of the official languages of ${fact.nameEn}?'
                  : 'Which currency is listed for ${fact.nameEn}?',
              answer,
              [answer, ...alternatives.take(5)]..shuffle(random),
            ),
          );
          continue;
        }
        final candidates =
            facts
                .map((other) {
                  switch (entry.key) {
                    case 'capital':
                      return other.capital;
                    case 'language':
                      return other.languages.length == 1
                          ? other.languages.single
                          : '';
                    case 'currency':
                      return other.currencies.length == 1
                          ? other.currencies.single
                          : '';
                    case 'region':
                      return other.region;
                    case 'area':
                      return other.areaKm2 == null
                          ? ''
                          : areaBand(other.areaKm2!);
                    default:
                      return other.population > 0
                          ? populationBand(other.population)
                          : '';
                  }
                })
                .where((value) => value.isNotEmpty)
                .toSet()
              ..remove(entry.value);
        if (candidates.length < 3) continue;
        final distractors = candidates.toList()..shuffle(random);
        final options = [entry.value, ...distractors.take(5)]..shuffle(random);
        final prompt = switch (entry.key) {
          'capital' => 'Capital of ${fact.nameEn}?',
          'language' => 'Official language of ${fact.nameEn}?',
          'currency' => 'Currency used in ${fact.nameEn}?',
          'region' => 'UN-style region for ${fact.nameEn}?',
          'area' => 'Approximate area of ${fact.nameEn}?',
          _ =>
            'Approximate population of ${fact.nameEn} (${fact.populationYear}, World Bank)?',
        };
        result.add(
          CountryQuestion(entry.key, fact, prompt, entry.value, options),
        );
      }
    }
    result.shuffle(random);
    return result.take(count).toList(growable: false);
  }
}

/// A source-backed explanation for one displayed practice choice.
class CountryChoiceExplanation {
  const CountryChoiceExplanation(this.option, this.text);

  final String option;
  final String text;
}

/// Resolves a displayed choice back to the country-atlas rows that support it.
///
/// Association choices are deliberately resolved from every matching row: an
/// object can be shared by more than one country, so arbitrarily picking one
/// would turn a true shared value into a misleading exclusive claim.
List<CountryChoiceExplanation> countryChoiceExplanations(
  CountryQuestion question,
  List<CountryFact> facts,
  Map<String, List<CountryAssociation>> associations, {
  required bool russian,
}) {
  final factsById = {for (final fact in facts) fact.id: fact};
  String countryName(CountryFact fact) => russian ? fact.nameRu : fact.nameEn;
  String valueName(String value) =>
      russian ? russianCountryLabel(value) : value;
  String relation(CountryAssociation row) =>
      russian ? russianLearningText(row.relationRu) : row.relationEn;

  if (question.association != null && question.reverse) {
    final object = question.association!;
    return question.options
        .map((option) {
          final fact = facts
              .where((candidate) => candidate.nameEn == option)
              .firstOrNull;
          if (fact == null) return CountryChoiceExplanation(option, '');
          final row = (associations[fact.id] ?? const [])
              .where(
                (candidate) =>
                    candidate.kind == object.kind &&
                    candidate.nameEn == object.nameEn,
              )
              .firstOrNull;
          if (row == null) {
            final objectName = russian ? object.nameRu : object.nameEn;
            return CountryChoiceExplanation(
              option,
              russian
                  ? '${countryName(fact)} · в этом справочнике нет связи с объектом «$objectName»'
                  : '${countryName(fact)} · this atlas does not list $objectName',
            );
          }
          final objectName = russian ? row.nameRu : row.nameEn;
          final rowRelation = relation(row);
          return CountryChoiceExplanation(
            option,
            '$objectName · ${countryName(fact)}'
            '${rowRelation.isEmpty ? '' : '\n$rowRelation'}',
          );
        })
        .toList(growable: false);
  }

  if (question.association != null) {
    return question.options
        .map((option) {
          final matches = <({CountryFact fact, CountryAssociation row})>[];
          for (final entry in associations.entries) {
            final fact = factsById[entry.key];
            if (fact == null) continue;
            for (final row in entry.value) {
              if (row.kind == question.kind && row.nameEn == option) {
                matches.add((fact: fact, row: row));
              }
            }
          }
          final details = matches
              .map((match) {
                final object = russian ? match.row.nameRu : match.row.nameEn;
                final rowRelation = relation(match.row);
                return '$object · ${countryName(match.fact)}'
                    '${rowRelation.isEmpty ? '' : '\n$rowRelation'}';
              })
              .toSet()
              .join('\n\n');
          return CountryChoiceExplanation(option, details);
        })
        .where((item) => item.text.isNotEmpty)
        .toList(growable: false);
  }

  bool matches(CountryFact fact, String option) => switch (question.kind) {
    'flag' => fact.nameEn == option,
    'capital' => fact.capital == option,
    'language' => fact.languages.contains(option),
    'currency' => fact.currencies.contains(option),
    'region' => fact.region == option,
    'population' =>
      fact.population > 0 && populationBand(fact.population) == option,
    'area' => fact.areaKm2 != null && areaBand(fact.areaKm2!) == option,
    _ => false,
  };

  String detail(CountryFact fact, String option) => switch (question.kind) {
    'flag' =>
      russian
          ? '${countryName(fact)} · столица: ${valueName(fact.capital)}'
          : '${countryName(fact)} · capital: ${fact.capital}',
    'capital' =>
      russian
          ? '${valueName(option)} · столица страны ${countryName(fact)}'
          : '$option · capital of ${countryName(fact)}',
    'language' =>
      russian
          ? '${valueName(option)} · официальный язык страны ${countryName(fact)}'
          : '$option · official language of ${countryName(fact)}',
    'currency' =>
      russian
          ? '${valueName(option)} · валюта страны ${countryName(fact)}'
          : '$option · currency of ${countryName(fact)}',
    'region' =>
      russian
          ? '${countryName(fact)} · регион: ${valueName(option)}'
          : '${countryName(fact)} · region: $option',
    'population' =>
      russian
          ? '${countryName(fact)} · категория численности: ${valueName(option)}'
          : '${countryName(fact)} · population band: $option',
    'area' =>
      russian
          ? '${countryName(fact)} · категория площади: ${valueName(option)}'
          : '${countryName(fact)} · area band: $option',
    _ => '',
  };

  String sharedDetail(List<CountryFact> matches, String option) {
    if (matches.isEmpty) return '';
    if (matches.length == 1) return detail(matches.single, option);
    final count = matches.length;
    return switch (question.kind) {
      'capital' => matches.map((fact) => detail(fact, option)).join('\n'),
      'language' =>
        russian
            ? '${valueName(option)} · официальный язык в $count странах справочника'
            : '$option · official language in $count countries in this atlas',
      'currency' =>
        russian
            ? '${valueName(option)} · валюта в $count странах справочника'
            : '$option · currency in $count countries in this atlas',
      'region' =>
        russian
            ? '${valueName(option)} · регион $count стран справочника'
            : '$option · region of $count countries in this atlas',
      'population' =>
        russian
            ? '${valueName(option)} · категория численности $count стран справочника'
            : '$option · population band of $count countries in this atlas',
      'area' =>
        russian
            ? '${valueName(option)} · категория площади $count стран справочника'
            : '$option · area band of $count countries in this atlas',
      _ => '',
    };
  }

  return question.options
      .map((option) {
        final matchingFacts = facts
            .where((fact) => matches(fact, option))
            .toList();
        final details = sharedDetail(matchingFacts, option);
        return CountryChoiceExplanation(option, details);
      })
      .where((item) => item.text.isNotEmpty)
      .toList(growable: false);
}

class CountryChoiceExplanationPanel extends StatelessWidget {
  const CountryChoiceExplanationPanel({
    super.key,
    required this.explanations,
    required this.title,
    required this.display,
  });

  final List<CountryChoiceExplanation> explanations;
  final String title;
  final String Function(String) display;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: ExpansionTile(
      key: const Key('country-choice-explanations'),
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 8),
      title: Text(title, style: Theme.of(context).textTheme.titleSmall),
      children: [
        for (var index = 0; index < explanations.length; index++)
          Padding(
            key: Key('country-choice-explanation-$index'),
            padding: const EdgeInsets.only(left: 4, right: 4, bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  display(explanations[index].option),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(explanations[index].text),
              ],
            ),
          ),
      ],
    ),
  );
}

class CountryAtlasPage extends StatefulWidget {
  const CountryAtlasPage({
    super.key,
    required this.catalog,
    this.challenge = false,
    this.bundle,
    this.locationTrainingBuilder,
  });
  final QuizipediaCatalog catalog;
  final bool challenge;
  final AssetBundle? bundle;
  final Widget Function(BuildContext, List<CountryFact>)?
  locationTrainingBuilder;
  @override
  State<CountryAtlasPage> createState() => _CountryAtlasPageState();
}

class _CountryAtlasPageState extends State<CountryAtlasPage> {
  final _controller = TransformationController();
  final _practiceScroll = ScrollController();
  final _mapSearch = TextEditingController();
  String _query = '',
      _region = 'All',
      _selected = '',
      _focus = '',
      _topic = 'mixed';
  List<CountryFact> _facts = const [];
  List<CountryQuestion> _questions = const [];
  Map<String, List<CountryAssociation>> _associations = const {};
  int _index = 0, _score = 0;
  String? _choice;
  bool _checked = false, _practice = false;
  bool _reverseRelations = false;
  bool _filtersVisible = false;
  bool _alwaysShowCountryNames = false;
  String _layer = 'none', _sort = 'population';
  final Set<String> _extraLayers = <String>{};
  WaterAtlas? _waters;
  Map<String, Offset> _capitalPoints = const {};
  bool _loadingCapitals = false;
  Object? _capitalError;
  String? _selectedWater;
  bool _loadingWater = false;
  Object? _waterError;
  bool _descending = true;
  Object? _loadError;
  CountryReligions? _religions;
  final List<CountryQuestion> _missed = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _selectWater(String id) {
    setState(() {
      _selectedWater = id;
      _selected = _focus = '';
    });
  }

  Future<void> _loadCapitals() async {
    if (_loadingCapitals || _capitalPoints.isNotEmpty) return;
    setState(() {
      _loadingCapitals = true;
      _capitalError = null;
    });
    try {
      final points = await loadCapitalPoints(widget.bundle);
      if (mounted) setState(() => _capitalPoints = points);
    } catch (error) {
      if (mounted) setState(() => _capitalError = error);
    } finally {
      if (mounted) setState(() => _loadingCapitals = false);
    }
  }

  Future<void> _loadWater() async {
    if (_loadingWater || _waters != null) return;
    setState(() {
      _loadingWater = true;
      _waterError = null;
    });
    try {
      final water = await WaterAtlas.load(widget.bundle);
      if (mounted) setState(() => _waters = water);
    } catch (error) {
      if (mounted) setState(() => _waterError = error);
    } finally {
      if (mounted) setState(() => _loadingWater = false);
    }
  }

  void _load() {
    setState(() => _loadError = null);
    Future.wait([
          CountryFact.load(widget.bundle),
          loadCountryAssociations(
            'assets/quizipedia/country_waters.json',
            bundle: widget.bundle,
          ),
          loadCountryAssociations(
            'assets/quizipedia/country_links.json',
            defaultKind: 'link',
            bundle: widget.bundle,
          ),
          loadCountryPresidents(widget.bundle),
          CountryReligions.load(widget.bundle),
          loadCountryAssociations(
            'assets/quizipedia/country_culture.json',
            bundle: widget.bundle,
          ),
        ])
        .then((loaded) {
          final facts = loaded[0] as List<CountryFact>;
          final associations = <String, List<CountryAssociation>>{};
          for (final value
              in loaded
                  .skip(1)
                  .take(3)
                  .cast<Map<String, List<CountryAssociation>>>()) {
            value.forEach(
              (id, rows) => associations.putIfAbsent(id, () => []).addAll(rows),
            );
          }
          (loaded[5] as Map<String, List<CountryAssociation>>).forEach(
            (id, rows) => associations.putIfAbsent(id, () => []).addAll(rows),
          );
          final religions = loaded[4] as CountryReligions;
          for (final row in religions.countries.values) {
            if (row.largestGroups.length != 1) continue;
            final group = religionGroups[row.largestGroups.single]!;
            associations
                .putIfAbsent(row.id, () => [])
                .add(
                  CountryAssociation(
                    id: 'religion-${row.id}',
                    kind: 'religion',
                    nameEn: group.nameEn,
                    nameRu: group.nameRu,
                    checked: '${religions.year}',
                    sourceUrl: religions.sourceUrl,
                    relationEn:
                        'Largest affiliation category in Pew Research Center estimates (${religions.year}): ${affiliationPercent(row.shares[row.largestGroups.single]!)}. Population affiliation, not official state religion.',
                    relationRu:
                        'Крупнейшая категория религиозной принадлежности по оценке Исследовательского центра Пью (${religions.year}): ${affiliationPercent(row.shares[row.largestGroups.single]!)}. Принадлежность населения, а не официальная религия государства.',
                  ),
                );
          }
          final names = {for (final fact in facts) fact.id: fact};
          for (final fact in facts) {
            for (final id in fact.neighbors) {
              final neighbor = names[id];
              if (neighbor != null) {
                associations
                    .putIfAbsent(fact.id, () => [])
                    .add(
                      CountryAssociation(
                        id: id,
                        kind: 'neighbor',
                        nameEn: neighbor.nameEn,
                        nameRu: neighbor.nameRu,
                        sourceUrl: fact.neighborSources[id] ?? 'https://github.com/mledoze/countries/blob/master/countries.json',
                        relationEn: 'Shares a land border, including overseas territories',
                        relationRu: 'Общая сухопутная граница, включая заморские территории',
                      ),
                    );
              }
            }
          }
          if (mounted) {
            setState(() {
              _facts = facts;
              _religions = religions;
              _associations = associations;
            });
          }
        })
        .catchError((Object error) {
          if (mounted) setState(() => _loadError = error);
        });
  }

  @override
  void dispose() {
    _controller.dispose();
    _practiceScroll.dispose();
    _mapSearch.dispose();
    super.dispose();
  }

  bool get _ru => Localizations.localeOf(context).languageCode == 'ru';
  String _t(String en, String ru) => _ru ? russianLearningText(ru) : en;
  String _display(String value) {
    if (!_ru) return value;
    final localized = russianCountryLabel(value);
    if (localized != value) return localized;
    final country = _facts.where((f) => f.nameEn == value).firstOrNull;
    if (country != null) return country.nameRu;
    final relation = _associations.values
        .expand((r) => r)
        .where((r) => r.nameEn == value)
        .firstOrNull;
    if (relation != null) return relation.nameRu;
    if (value.contains(', ')) return value.split(', ').map(_display).join(', ');
    return _russianFactLabels[value] ??
        value
            .replaceAll('million', 'млн')
            .replaceAll('under', 'менее')
            .replaceAll('km²', 'км²')
            .replaceAll('administrative', 'административная')
            .replaceAll('legislative', 'законодательная')
            .replaceAll('judicial', 'судебная')
            .replaceAll('constitutional capital', 'конституционная столица')
            .replaceAll(
              'capital; government in The Hague',
              'столица; правительство в Гааге',
            );
  }

  Widget _sourceLink(String url, [String? label]) => TextButton.icon(
    onPressed: () {
      final uri = Uri.tryParse(url);
      if (uri != null && ['https', 'http'].contains(uri.scheme)) {
        launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    },
    icon: const Icon(Icons.open_in_new, size: 14),
    label: Text(
      label == null
          ? _t('Source', 'Источник')
          : (_ru ? russianLearningText(label) : label),
    ),
  );
  CountryFact? get _fact => _facts.where((f) => f.id == _selected).firstOrNull;
  bool _matches(CountryFact fact) {
    final query = _query.trim().toLowerCase();
    return [
          fact.nameEn,
          fact.nameRu,
          fact.capital,
          if (_ru) _display(fact.capital),
          if (_ru) ...fact.languages.map(_display),
          if (_ru) ...fact.currencies.map(_display),
          ...fact.languages,
          ...fact.currencies,
          for (final row in _associations[fact.id] ?? <CountryAssociation>[])
            '${row.nameEn} ${row.nameRu}',
        ].any((value) => value.toLowerCase().contains(query)) ||
        (_religions?.countries[fact.id]?.matches(query) ?? false);
  }

  String _layerText(CountryFact fact, [String? layer]) {
    final activeLayer = layer ?? _layer;
    return switch (activeLayer) {
      'religion' =>
        _religions?.countries[fact.id]?.mapLabel(
              ru: _ru,
              year: _religions!.year,
            ) ??
            '',
      'flag' => _ru ? fact.nameRu : fact.nameEn,
      'capital' => _display(fact.capital),
      'currency' => fact.currencies.map(_display).join(', '),
      'population' =>
        fact.population > 0
            ? '${(fact.population / 1000000).toStringAsFixed(1)} ${_t('m', 'млн')} (${fact.populationYear})'
            : '',
      'area' =>
        fact.areaKm2 == null
            ? ''
            : '${fact.areaKm2!.round()} ${_t('km²', 'км²')}',
      _ =>
        (_associations[fact.id] ?? [])
            .where((r) => r.kind == activeLayer)
            .take(2)
            .map((r) => _ru ? r.nameRu : r.nameEn)
            .join(' · '),
    };
  }

  Set<String> get _activeLayers => <String>{
    if (_layer != 'none') _layer,
    ..._extraLayers,
  };

  String _mapLabel(CountryFact fact, {bool includeCountry = true}) {
    final values = <String>[
      if (includeCountry) _ru ? fact.nameRu : fact.nameEn,
    ];
    for (final layer in _activeLayers) {
      if (layer == 'flag' || layer == 'water') continue;
      final value = _layerText(fact, layer);
      if (value.isNotEmpty && !values.contains(value)) values.add(value);
    }
    return values.join('\n');
  }

  String _countryIntro(CountryFact fact) {
    // Prefer a memorable reviewed association over the generic first water or
    // resource record. Every value still comes from the loaded source-backed
    // association files; countries without one fall back to capital and region.
    const priority = [
      'landmark',
      'wonder',
      'scientist',
      'food',
      'culture',
      'instrument',
      'sports_team',
      'bridge',
      'desert',
      'resource',
      'water',
    ];
    final association =
        ([...?_associations[fact.id]]..sort(
              (a, b) =>
                  priority.indexOf(a.kind).compareTo(priority.indexOf(b.kind)),
            ))
            .where((row) => priority.contains(row.kind))
            .firstOrNull;
    if (association != null) {
      final name = _ru ? association.nameRu : association.nameEn;
      final relation = _ru ? association.relationRu : association.relationEn;
      return '$name — $relation';
    }
    final capital = fact.capital.isEmpty ? '' : _display(fact.capital);
    final region = _display(fact.region);
    return capital.isEmpty
        ? '${_t('Region', 'Регион')}: $region'
        : '${_t('Capital', 'Столица')}: $capital · $region';
  }

  void _showRanking() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, update) {
          final rows =
              _facts
                  .where(
                    (f) =>
                        (_region == 'All' || f.region == _region) &&
                        (_sort == 'population'
                            ? f.population > 0
                            : f.areaKm2 != null),
                  )
                  .toList()
                ..sort(
                  (a, b) =>
                      (_sort == 'population'
                          ? a.population.compareTo(b.population)
                          : a.areaKm2!.compareTo(b.areaKm2!)) *
                      (_descending ? -1 : 1),
                );
          return SafeArea(
            child: SizedBox(
              height: MediaQuery.sizeOf(context).height * .82,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: Text(_topicLabel('population')),
                          selected: _sort == 'population',
                          onSelected: (_) => update(() => _sort = 'population'),
                        ),
                        ChoiceChip(
                          label: Text(_topicLabel('area')),
                          selected: _sort == 'area',
                          onSelected: (_) => update(() => _sort = 'area'),
                        ),
                        TextButton.icon(
                          icon: Icon(
                            _descending
                                ? Icons.arrow_downward
                                : Icons.arrow_upward,
                          ),
                          label: Text(
                            _descending
                                ? _t('Descending', 'По убыванию')
                                : _t('Ascending', 'По возрастанию'),
                          ),
                          onPressed: () =>
                              update(() => _descending = !_descending),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: rows.length,
                      itemBuilder: (context, index) {
                        final fact = rows[index];
                        return ListTile(
                          leading: Text('${index + 1}'),
                          title: Text(_ru ? fact.nameRu : fact.nameEn),
                          subtitle: Text(
                            _sort == 'population'
                                ? '${fact.population} · ${fact.populationYear} · ${_t('World Bank', 'Всемирный банк')}'
                                : '${fact.areaKm2!.round()} ${_t('km²', 'км²')}',
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            setState(() {
                              _selectedWater = null;
                              _selected = fact.id;
                              _focus = fact.id;
                            });
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showExpandedMap() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (routeContext) {
          var selected = _selected;
          var focus = _focus;
          return StatefulBuilder(
            builder: (context, refresh) => Scaffold(
              appBar: AppBar(
                title: Text(_t('World map', 'Карта мира')),
                leading: IconButton(
                  key: const Key('country-collapse-map'),
                  tooltip: _t('Collapse map', 'Свернуть карту'),
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              body: SafeArea(
                child: QuizipediaWorldMap(
                  features: _visible,
                  controller: _controller,
                  selected: selected.isEmpty ? null : selected,
                  highlighted: focus.isEmpty ? null : focus,
                  showSelectionLabel: false,
                  showLabels: false,
                  alwaysShowCountryNames: _alwaysShowCountryNames,
                  labelPriorityIds: _fact?.neighbors.toSet() ?? const {},
                  neighborIds: _fact?.neighbors.toSet() ?? const {},
                  waters: _activeLayers.contains('water')
                      ? (_waters?.features ?? const [])
                      : const [],
                  selectedWater: _activeLayers.contains('water')
                      ? _selectedWater
                      : null,
                  onWaterSelect: _selectWater,
                  overlayLabels: {
                    for (final fact in _facts)
                      if (_mapLabel(
                        fact,
                        includeCountry: !_alwaysShowCountryNames,
                      ).isNotEmpty)
                        fact.id: _mapLabel(
                          fact,
                          includeCountry: !_alwaysShowCountryNames,
                        ),
                  },
                  capitalPoints: _activeLayers.contains('capital')
                      ? _capitalPoints
                      : const {},
                  capitalLabels: _activeLayers.contains('capital')
                      ? {
                          for (final fact in _facts)
                            if (fact.capital.isNotEmpty)
                              fact.id: _display(fact.capital),
                        }
                      : const {},
                  showFlags: _activeLayers.contains('flag'),
                  onSelect: (id) {
                    FocusManager.instance.primaryFocus?.unfocus();
                    setState(() {
                      _selectedWater = null;
                      _selected = _focus = id ?? '';
                    });
                    refresh(() {
                      selected = focus = id ?? '';
                    });
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showCountryList() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        var search = '';
        return StatefulBuilder(
          builder: (context, update) {
            final rows =
                _facts.where((fact) {
                  final query = search.trim().toLowerCase();
                  return query.isEmpty ||
                      fact.nameEn.toLowerCase().contains(query) ||
                      fact.nameRu.toLowerCase().contains(query) ||
                      fact.capital.toLowerCase().contains(query);
                }).toList()..sort(
                  (a, b) => (_ru ? a.nameRu : a.nameEn).compareTo(
                    _ru ? b.nameRu : b.nameEn,
                  ),
                );
            return SafeArea(
              child: SizedBox(
                height: MediaQuery.sizeOf(context).height * .78,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        key: const Key('country-list-search'),
                        autofocus: true,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search),
                          labelText: _t('Choose a country', 'Выберите страну'),
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (value) => update(() => search = value),
                      ),
                    ),
                    Expanded(
                      child: rows.isEmpty
                          ? Center(
                              child: Text(
                                _t(
                                  'No countries match this search',
                                  'По этому запросу страны не найдены',
                                ),
                                textAlign: TextAlign.center,
                              ),
                            )
                          : ListView.builder(
                              itemCount: rows.length,
                              itemBuilder: (context, index) {
                                final fact = rows[index];
                                return ListTile(
                                  title: Text(_ru ? fact.nameRu : fact.nameEn),
                                  subtitle: fact.capital.isEmpty
                                      ? null
                                      : Text(_display(fact.capital)),
                                  onTap: () {
                                    Navigator.pop(context);
                                    setState(() {
                                      _selectedWater = null;
                                      _selected = fact.id;
                                      _focus = fact.id;
                                    });
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  List<QuizipediaFeature> get _visible =>
      widget.catalog.countries.where((country) {
        final fact = _facts.where((f) => f.id == country.id).firstOrNull;
        return _region == 'All' || fact?.region == _region;
      }).toList();

  void _start({String? countryId, List<CountryQuestion>? retry}) {
    if (_topic == 'location' && widget.locationTrainingBuilder != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) =>
              widget.locationTrainingBuilder!(context, _facts),
        ),
      );
      return;
    }
    final pool =
        retry ??
        [
          ...CountryQuestion.build(_facts),
          ...CountryQuestion.associations(
            _facts,
            _associations,
            kind: _topic == 'mixed' ? null : _topic,
            reverse: _reverseRelations,
          ),
        ];
    final questions =
        (retry != null
              ? pool
              : (_topic == 'mixed'
                        ? pool
                        : pool
                              .where((question) => question.kind == _topic)
                              .toList())
                    .where(
                      (q) =>
                          (countryId == null || q.country.id == countryId) &&
                          (_region == 'All' || q.country.region == _region),
                    )
                    .toList())
          ..shuffle();
    final round = <CountryQuestion>[];
    if (_topic == 'mixed' && retry == null) {
      final kinds = questions.map((q) => q.kind).toSet().toList()..shuffle();
      final groups = {
        for (final kind in kinds)
          kind: questions.where((q) => q.kind == kind).toList(),
      };
      while (round.length < 10 && groups.values.any((g) => g.isNotEmpty)) {
        for (final kind in kinds) {
          if (groups[kind]!.isNotEmpty && round.length < 10) {
            round.add(groups[kind]!.removeLast());
          }
        }
      }
    } else {
      round.addAll(questions.take(10));
    }
    if (round.isNotEmpty) {
      setState(() {
        _questions = round;
        _index = 0;
        _score = 0;
        _choice = null;
        _checked = false;
        _practice = true;
        _missed.clear();
      });
      _practiceTop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t(
              'No verified questions for this selection yet. Choose another topic or region.',
              'Для этого выбора пока нет проверенных вопросов. Выберите другую тему или регион.',
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_facts.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(_t('Countries', 'Страны'))),
        body: Center(
          child: _loadError == null
              ? const CircularProgressIndicator()
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _t(
                        'Country facts could not load.',
                        'Не удалось загрузить справочник стран.',
                      ),
                    ),
                    FilledButton(
                      onPressed: _load,
                      child: Text(_t('Retry', 'Повторить')),
                    ),
                  ],
                ),
        ),
      );
    }
    if (_practice && _questions.isNotEmpty) return _quiz();
    final chipHeight = math.max(
      48.0,
      MediaQuery.textScalerOf(context).scale(16) + 24,
    );
    final regions = [
      'All',
      ..._facts.map((f) => f.region).where((r) => r.isNotEmpty).toSet(),
    ];
    final topics = [
      'mixed',
      'location',
      'flag',
      'capital',
      'language',
      'currency',
      'population',
      'area',
      'region',
      ..._associations.values
          .expand((rows) => rows.map((row) => row.kind))
          .toSet(),
    ];
    void showSettings() => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (context) => StatefulBuilder(
        builder: (context, refresh) {
          void change(VoidCallback callback) {
            setState(callback);
            refresh(() {});
          }

          void toggleLayer(String layer, bool selected) {
            change(() {
              if (selected) {
                _extraLayers.add(layer);
              } else {
                _extraLayers.remove(layer);
                if (_layer == layer) _layer = 'none';
              }
            });
            if (selected && layer == 'water') _loadWater();
            if (selected && layer == 'capital') _loadCapitals();
          }

          return FractionallySizedBox(
            heightFactor: .8,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _t('Map layers', 'Слои карты'),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final layer in _mapLayers)
                              FilterChip(
                                key: Key('country-sheet-layer-$layer'),
                                label: Text(_topicLabel(layer)),
                                selected: _activeLayers.contains(layer),
                                onSelected: (selected) =>
                                    toggleLayer(layer, selected),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        FilterChip(
                          key: const Key('country-sheet-always-country-names'),
                          label: Text(
                            _t(
                              'Always show country names',
                              'Всегда показывать названия стран',
                            ),
                          ),
                          selected: _alwaysShowCountryNames,
                          onSelected: (selected) =>
                              change(() => _alwaysShowCountryNames = selected),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: ExpansionTile(
                      key: const Key('country-atlas-filters'),
                      title: Text(
                        _t('Filters and practice', 'Фильтры и тренировка'),
                      ),
                      initiallyExpanded: _filtersVisible,
                      onExpansionChanged: (value) =>
                          change(() => _filtersVisible = value),
                      children: [
                        SizedBox(
                          height: chipHeight,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: regions
                                .map(
                                  (region) => Padding(
                                    padding: const EdgeInsets.only(left: 8),
                                    child: ChoiceChip(
                                      label: Text(_display(region)),
                                      selected: _region == region,
                                      onSelected: (_) =>
                                          change(() => _region = region),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                          child: DropdownButtonFormField<String>(
                            key: const Key('atlas-topic-picker'),
                            initialValue: _topic,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: _t(
                                'Questions about',
                                'О чём спрашивать',
                              ),
                              helperText: _t(
                                'Choose the facts for the next 10 questions.',
                                'Выберите факты для следующих 10 вопросов.',
                              ),
                              helperMaxLines: 3,
                              border: const OutlineInputBorder(),
                            ),
                            items: [
                              for (final topic in topics)
                                DropdownMenuItem(
                                  value: topic,
                                  child: Text(
                                    _topicLabel(topic),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                            onChanged: (value) {
                              if (value != null) change(() => _topic = value);
                            },
                          ),
                        ),
                        SwitchListTile(
                          key: const Key('atlas-reverse-relations'),
                          title: Text(
                            _t(
                              'Guess the country from a fact',
                              'Узнать страну по факту',
                            ),
                          ),
                          subtitle: Text(
                            _t(
                              'A river, club or dish is the clue; choose its country.',
                              'Вопрос о реке, клубе или блюде — выберите связанную с ним страну.',
                            ),
                          ),
                          value: _reverseRelations,
                          onChanged: (value) =>
                              change(() => _reverseRelations = value),
                        ),
                      ],
                    ),
                  ),
                  if (_query.trim().isNotEmpty && !_facts.any(_matches))
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        _t(
                          'No matching countries or facts.',
                          'Страны или факты не найдены.',
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Text(
                      _t(
                        'Map layers are directly above the map. Turn on several at once.',
                        'Слои карты находятся прямо над картой. Можно включить несколько сразу.',
                      ),
                    ),
                  ),
                  TextButton.icon(
                    key: const Key('country-apply-layer'),
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.map_outlined),
                    label: Text(_t('Show on the map', 'Показать на карте')),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showRanking();
                    },
                    icon: const Icon(Icons.sort),
                    label: Text(
                      _t(
                        'Compare countries: population and area',
                        'Сравнить страны: население и площадь',
                      ),
                    ),
                  ),
                  if (_activeLayers.any(
                    (layer) => const {'instrument', 'culture'}.contains(layer),
                  ))
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        _t(
                          'Selected cultural associations, not exclusive national ownership. Shared traditions can belong to several countries. No label means this selection has no entry yet.',
                          'Избранные культурные связи, а не исключительная принадлежность стране. Общие традиции могут быть связаны с несколькими странами. Нет подписи — пока нет записи в этой подборке.',
                        ),
                      ),
                    ),
                  if (_activeLayers.contains('religion'))
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _t(
                              'Largest affiliation category · Pew Research Center, 2020 estimates (published 2025). Country labels show population affiliation, not official state religion. No label means no data in this source.',
                              'Крупнейшая категория религиозной принадлежности · оценка Pew Research Center за 2020 год (публикация 2025). Подписи относятся к населению, а не к официальной религии государства. Нет подписи — нет данных в этом источнике.',
                            ),
                          ),
                          if (_religions != null)
                            _sourceLink(
                              _religions!.sourceUrl,
                              'Pew Research Center',
                            ),
                        ],
                      ),
                    ),
                  if (_activeLayers.any(
                    (layer) =>
                        const {'water', 'resource', 'neighbor'}.contains(layer),
                  ))
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        _t(
                          'Selected facts are attached to countries; labels are not exact object locations.',
                          'Подписи показывают связи со странами, а не точные координаты объектов.',
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(_t('Countries', 'Страны')),
        actions: [
          FactPracticeAction(scope: 'countries', bundle: widget.bundle),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        key: const Key('map-country-search'),
                        controller: _mapSearch,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search),
                          labelText: _t(
                            'Search a country or fact',
                            'Найти страну или факт',
                          ),
                          suffixIcon: _query.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: _t('Clear search', 'Очистить поиск'),
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _mapSearch.clear();
                                    setState(() => _query = '');
                                  },
                                ),
                        ),
                        onChanged: (value) => setState(() => _query = value),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.tonalIcon(
                      key: const Key('country-list-button'),
                      icon: const Icon(Icons.format_list_bulleted),
                      label: Text(_t('Countries', 'Страны')),
                      onPressed: _showCountryList,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: OutlinedButton.icon(
                  key: const Key('country-direct-layers'),
                  onPressed: showSettings,
                  icon: const Icon(Icons.layers_outlined),
                  label: Text(
                    _activeLayers.isEmpty
                        ? _t('Layers', 'Слои')
                        : '${_t('Layers', 'Слои')}: ${_activeLayers.map(_topicLabel).join(', ')}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  key: const Key('country-expand-map'),
                  onPressed: _showExpandedMap,
                  icon: const Icon(Icons.fullscreen),
                  label: Text(_t('Expand map', 'Развернуть карту')),
                ),
              ),
              if (_query.isNotEmpty)
                Builder(
                  builder: (context) {
                    final matches = _facts.where(_matches).toList();
                    if (matches.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Semantics(
                          liveRegion: true,
                          child: Text(
                            _t(
                              'No countries or facts match this search',
                              'По этому запросу страны или факты не найдены',
                            ),
                          ),
                        ),
                      );
                    }
                    return SizedBox(
                      height: chipHeight,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: matches
                            .map(
                              (fact) => Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth:
                                        MediaQuery.sizeOf(context).width - 24,
                                  ),
                                  child: ActionChip(
                                    label: Text(
                                      _ru ? fact.nameRu : fact.nameEn,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    onPressed: () {
                                      FocusManager.instance.primaryFocus
                                          ?.unfocus();
                                      setState(() {
                                        _selectedWater = null;
                                        _selected = fact.id;
                                        _focus = fact.id;
                                        _region = 'All';
                                      });
                                    },
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    );
                  },
                ),
              if (_activeLayers.contains('capital')) ...[
                if (_loadingCapitals) const LinearProgressIndicator(),
                if (_capitalError != null)
                  TextButton.icon(
                    key: const Key('capital-points-retry'),
                    onPressed: _loadCapitals,
                    icon: const Icon(Icons.refresh),
                    label: Text(
                      _t('Retry capital points', 'Повторить загрузку столиц'),
                    ),
                  ),
              ],
              if (_activeLayers.contains('water')) ...[
                if (_loadingWater) const LinearProgressIndicator(),
                if (_waterError != null)
                  TextButton.icon(
                    key: const Key('water-geometry-retry'),
                    onPressed: _loadWater,
                    icon: const Icon(Icons.refresh),
                    label: Text(
                      _t('Retry water map', 'Повторить загрузку водоёмов'),
                    ),
                  ),
                if (_waters != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            key: const Key('water-picker'),
                            icon: const Icon(Icons.search),
                            label: Text(
                              _selectedWater == null
                                  ? _t('Water bodies · 63', 'Водоёмы · 63')
                                  : (_waters!.features
                                            .where(
                                              (w) => w.id == _selectedWater,
                                            )
                                            .map(
                                              (w) => _ru ? w.nameRu : w.nameEn,
                                            )
                                            .firstOrNull ??
                                        ''),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onPressed: () async {
                              final id = await pickWater(context, _waters!);
                              if (mounted && id != null) {
                                _selectWater(id);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: _t(
                            'Recognize water bodies',
                            'Узнавать водоёмы',
                          ),
                          icon: const Icon(Icons.quiz_outlined),
                          key: const Key('water-training'),
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => WaterPracticePage(
                                catalog: widget.catalog,
                                atlas: _waters!,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
              const SizedBox(height: 6),
              SizedBox(
                height: math.min(
                  MediaQuery.sizeOf(context).width / 2,
                  math.max(150, MediaQuery.sizeOf(context).height - 430),
                ),
                child: QuizipediaWorldMap(
                  features: _visible,
                  controller: _controller,
                  selected: _selected.isEmpty ? null : _selected,
                  highlighted: _focus.isEmpty ? null : _focus,
                  showSelectionLabel: false,
                  showLabels: false,
                  alwaysShowCountryNames: _alwaysShowCountryNames,
                  labelPriorityIds: _fact?.neighbors.toSet() ?? const {},
                  neighborIds: _fact?.neighbors.toSet() ?? const {},
                  waters: _activeLayers.contains('water')
                      ? (_waters?.features ?? const [])
                      : const [],
                  selectedWater: _activeLayers.contains('water')
                      ? _selectedWater
                      : null,
                  onWaterSelect: _selectWater,
                  overlayLabels: {
                    for (final fact in _facts)
                      if (_mapLabel(
                        fact,
                        includeCountry: !_alwaysShowCountryNames,
                      ).isNotEmpty)
                        fact.id: _mapLabel(
                          fact,
                          includeCountry: !_alwaysShowCountryNames,
                        ),
                  },
                  capitalPoints: _activeLayers.contains('capital')
                      ? _capitalPoints
                      : const {},
                  capitalLabels: _activeLayers.contains('capital')
                      ? {
                          for (final fact in _facts)
                            if (fact.capital.isNotEmpty)
                              fact.id: _display(fact.capital),
                        }
                      : const {},
                  showFlags: _activeLayers.contains('flag'),
                  onSelect: (id) {
                    FocusManager.instance.primaryFocus?.unfocus();
                    setState(() {
                      _selectedWater = null;
                      _selected = id ?? '';
                      _focus = id ?? '';
                    });
                  },
                ),
              ),
              if (_selected.isNotEmpty)
                ListTile(
                  key: const Key('country-selected-details'),
                  leading: SizedBox(
                    width: 48,
                    height: 32,
                    child: Image.asset(
                      'assets/quizipedia/flag-${_selected.toLowerCase()}.png',
                      key: const Key('country-flag-preview'),
                      fit: BoxFit.contain,
                      semanticLabel: _t('Country flag', 'Флаг страны'),
                      errorBuilder: (_, _, _) =>
                          const Icon(Icons.flag_outlined),
                    ),
                  ),
                  dense: true,
                  title: Text(
                    _fact == null
                        ? (_visible
                                  .where((f) => f.id == _selected)
                                  .map((f) => _ru ? f.nameRu : f.nameEn)
                                  .firstOrNull ??
                              _selected)
                        : (_ru ? _fact!.nameRu : _fact!.nameEn),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    _fact == null
                        ? _t(
                            'Details are not available yet',
                            'Сведения пока не добавлены',
                          )
                        : [
                            _countryIntro(_fact!),
                            if (_fact!.capital.isNotEmpty)
                              _display(_fact!.capital),
                            if (_fact!.neighbors.isNotEmpty)
                              '${_t('Neighbours', 'Соседи')}: ${_facts.where((f) => _fact!.neighbors.contains(f.id)).map((f) => _ru ? f.nameRu : f.nameEn).join(', ')}',
                          ].where((value) => value.isNotEmpty).join(' · '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: _fact == null
                      ? null
                      : const Icon(Icons.expand_less),
                  onTap: _fact == null ? null : _showDetails,
                ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        key: const Key('country-map-settings'),
                        onPressed: showSettings,
                        icon: const Icon(Icons.layers_outlined),
                        label: Text(
                          _layer == 'none'
                              ? _t('Layers', 'Слои')
                              : _topicLabel(_layer),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        key: const Key('country-start-training'),
                        onPressed: _start,
                        icon: const Icon(Icons.quiz_outlined),
                        label: Text(_t('Practice', 'Тренировка')),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetails() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (context) => StatefulBuilder(
      builder: (context, refresh) => FractionallySizedBox(
        heightFactor: .82,
        child: _details(refresh: refresh),
      ),
    ),
  );

  String _topicLabel(String topic) => switch (topic) {
    'religion' => _t('Religious affiliation', 'Религиозная принадлежность'),
    'mixed' => _t('Mixed', 'Все темы'),
    'location' => _t('Location', 'Положение на карте'),
    'neighbor' => _t('Land neighbors', 'Сухопутные соседи'),
    'water' => _t('Water bodies', 'Водоёмы'),
    'president' => _t('Presidents', 'Президенты'),
    'sports_team' => _t('Sports teams', 'Спортивные команды'),
    'resource' => _t('Resources', 'Ресурсы'),
    'desert' => _t('Deserts', 'Пустыни'),
    'wonder' => _t('Wonders', 'Чудеса света'),
    'landmark' => _t('Landmarks', 'Достопримечательности'),
    'bridge' => _t('Bridges', 'Мосты'),
    'scientist' => _t('Scientists', 'Учёные'),
    'food' => _t('Food', 'Еда и кухня'),
    'instrument' => _t('Musical instruments', 'Музыкальные инструменты'),
    'culture' => _t('Cultural traditions', 'Культурные традиции'),
    'flag' => _t('Flags', 'Флаги'),
    'capital' => _t('Capitals', 'Столицы'),
    'language' => _t('Official languages', 'Официальные языки'),
    'currency' => _t('Currencies', 'Валюты'),
    'population' => _t('Population', 'Население'),
    'area' => _t('Area', 'Площадь'),
    'region' => _t('Region', 'Регион'),
    _ => topic,
  };

  String _questionText(CountryQuestion question) {
    if (!_ru) return question.prompt;
    if (question.reverse) {
      return 'По этому справочнику: с какой страной связан объект «${question.association!.nameRu}» (${question.association!.relationRu})?';
    }
    final name = question.country.nameRu;
    return switch (question.kind) {
      'religion' =>
        'Какая категория религиозной принадлежности была крупнейшей в стране $name по оценке Исследовательского центра Пью за ${question.association?.checked} год?',
      'flag' => 'Какой стране принадлежит этот флаг?',
      'capital' => 'Столица страны $name?',
      'language' =>
        'Какой из языков является одним из официальных в стране $name?',
      'currency' => 'Какая валюта указана в справочнике для страны $name?',
      'population' =>
        'Примерная численность населения страны $name (${question.country.populationYear}, Всемирный банк)?',
      'area' => 'Примерная площадь $name?',
      'region' => 'Регион страны $name?',
      'neighbor' =>
        'Какая страна или территория имеет сухопутную границу с $name (включая заморские территории)?',
      'water' => 'Какой крупный водоём указан в справочнике страны $name?',
      'president' =>
        'Кто указан президентом страны $name на ${question.association?.checked ?? "дату снимка"}?',
      'scientist' =>
        'Кто из учёных родился на территории современной страны $name?',
      'food' => 'Какая кулинарная традиция включена ЮНЕСКО для страны $name?',
      'sports_team' => 'Какой спортивный клуб базируется в стране $name?',
      'instrument' =>
        'Какой музыкальный инструмент связан со страной $name согласно этому атласу?',
      'culture' =>
        'Какая культурная традиция связана со страной $name согласно этому атласу?',
      'resource' => 'Какой природный ресурс указан в справочнике страны $name?',
      'desert' => 'Какая пустыня расположена на территории страны $name?',
      'bridge' => 'Какой мост находится в стране $name?',
      'wonder' => 'Какое чудо света находится в стране $name?',
      'landmark' => 'Какая достопримечательность находится в стране $name?',
      _ => 'Что связано со страной $name?',
    };
  }

  String _answerExplanation(CountryQuestion question) {
    final fact = question.country;
    final name = _ru ? fact.nameRu : fact.nameEn;
    final answer = _display(question.answer);
    if (question.association case final row?) {
      final object = _ru ? row.nameRu : row.nameEn;
      final relation = _ru
          ? russianLearningText(row.relationRu)
          : row.relationEn;
      return '$name · $object${relation.isEmpty ? '' : '\n$relation'}';
    }
    return switch (question.kind) {
      'capital' => _t(
        '$answer is the capital of $name.',
        '$answer — столица страны $name.',
      ),
      'language' =>
        _t(
              'Official languages of $name: ',
              'Официальные языки страны $name: ',
            ) +
            fact.languages.map(_display).join(', '),
      'currency' =>
        _t('Currencies listed for $name: ', 'Валюты страны $name: ') +
            fact.currencies.map(_display).join(', '),
      'population' =>
        "${_t('Population of $name: ', 'Население страны $name: ')}${fact.population} (${fact.populationYear}, ${_t('World Bank', 'Всемирный банк')}).",
      'area' =>
        "${_t('Area of $name: ', 'Площадь страны $name: ')}${fact.areaKm2?.round()} ${_t('km²', 'км²')}.",
      'region' => _t('$name is in $answer.', '$name: регион — $answer.'),
      'flag' => _t(
        'The flag shown belongs to $name.',
        'На изображении флаг страны $name.',
      ),
      _ => '$name · $answer',
    };
  }

  List<CountryChoiceExplanation> _choiceExplanations(
    CountryQuestion question,
  ) => countryChoiceExplanations(question, _facts, _associations, russian: _ru);

  Widget _religionDetails(CountryFact fact) {
    final data = _religions;
    if (data == null) return const SizedBox.shrink();
    final row = data.countries[fact.id];
    final entries =
        row?.shares.entries.toList() ?? <MapEntry<String, double>>[];
    entries.sort((a, b) => b.value.compareTo(a.value));
    return Column(
      key: const Key('country-religion-details'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(
          '${_topicLabel('religion')} · ${data.year}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (row == null)
          Text(
            _t(
              'No estimates for this country in this source.',
              'Для этой страны нет оценок в этом источнике.',
            ),
          ),
        for (final entry in entries)
          Text(
            '${religionGroups[entry.key]!.name(_ru)}: ${affiliationPercent(entry.value)}',
          ),
        Text(
          _t(
            'Approximate population affiliation; not official state religion. Unaffiliated includes people with no particular religion, agnostics and atheists. Other religions are combined in this source. Rounded percentages may not total 100%.',
            'Оценка принадлежности населения, а не официальная религия государства. Без религиозной принадлежности — в том числе без определённой религии, агностики и атеисты. Другие религии объединены источником. Округлённые доли могут не дать ровно 100%.',
          ),
        ),
        Text(
          _t(
            'Pew Research Center · data ${data.year} · published ${data.publishedYear}',
            'Исследовательский центр Пью · данные ${data.year} · публикация ${data.publishedYear}',
          ),
        ),
        Wrap(
          children: [
            _sourceLink(data.sourceUrl, 'Pew Research Center'),
            _sourceLink(data.methodologyUrl, _t('Methodology', 'Методология')),
          ],
        ),
      ],
    );
  }

  Widget _details({StateSetter? refresh}) {
    void change(VoidCallback callback) {
      setState(callback);
      refresh?.call(() {});
    }

    final fact = _fact;
    if (fact == null) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: FilledButton.icon(
          onPressed: () {
            Navigator.pop(context);
            _start();
          },
          icon: const Icon(Icons.quiz),
          label: Text(_t('Train 10 questions', 'Тренировка: 10 вопросов')),
        ),
      );
    }
    final feature = widget.catalog.countries
        .where((c) => c.id == fact.id)
        .firstOrNull;
    final name = _ru ? fact.nameRu : fact.nameEn;
    String field(String label, String value) => '$label: $value';
    return Container(
      key: const Key('map-details'),
      width: double.infinity,
      padding: const EdgeInsetsDirectional.fromSTEB(12, 12, 12, 16),
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: Theme.of(context).textTheme.titleLarge),
              if (fact.neighbors.isNotEmpty)
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final neighbor in _facts.where(
                      (f) => fact.neighbors.contains(f.id),
                    ))
                      ActionChip(
                        label: Text(_ru ? neighbor.nameRu : neighbor.nameEn),
                        avatar: const Icon(Icons.compare_arrows, size: 16),
                        onPressed: () => change(() {
                          _selectedWater = null;
                          _selected = neighbor.id;
                          _focus = neighbor.id;
                        }),
                      ),
                  ],
                ),
              Image.asset(
                'assets/quizipedia/flag-${fact.id.toLowerCase()}.png',
                height: 36,
                semanticLabel: _t('Flag of $name', 'Флаг: $name'),
              ),
              if (fact.capital.isNotEmpty)
                Text(field(_t('Capital', 'Столица'), _display(fact.capital))),
              if (fact.languages.isNotEmpty)
                Text(
                  field(
                    _t('Official language', 'Официальный язык'),
                    fact.languages.map(_display).join(', '),
                  ),
                ),
              if (fact.officialLanguagesSource.isNotEmpty)
                _sourceLink(
                  fact.officialLanguagesSource,
                  _t('Official language source', 'Источник: официальные языки'),
                ),
              if (fact.sourceLanguages.isNotEmpty)
                Text(
                  field(
                    _t('Languages in source', 'Языки в источнике'),
                    fact.sourceLanguages.map(_display).join(', '),
                  ),
                ),
              if (fact.currencies.isNotEmpty)
                Text(
                  field(
                    _t('Currency', 'Валюта'),
                    fact.currencies.map(_display).join(', '),
                  ),
                ),
              if (fact.population > 0)
                Text(
                  field(
                    _t('Population (approximate)', 'Население (примерно)'),
                    '${fact.population.toString().replaceAllMapped(RegExp(r"\B(?=(\d{3})+(?!\d))"), (_) => " ")} · ${fact.populationYear} · ${_t('World Bank', 'Всемирный банк')}',
                  ),
                ),
              if (fact.areaKm2 != null)
                Text(
                  field(
                    _t('Area', 'Площадь'),
                    '${fact.areaKm2!.round()} ${_t('km²', 'км²')}',
                  ),
                ),
              Text(field(_t('Region', 'Регион'), _display(fact.region))),
              if (feature == null)
                Text(
                  _t(
                    'No outline in this map; country facts are available.',
                    'Контура на этой карте нет; факты и тренировки доступны.',
                  ),
                ),
              _religionDetails(fact),
              for (final kind
                  in (_associations[fact.id] ?? const [])
                      .where((r) => r.kind != 'religion')
                      .map((r) => r.kind)
                      .toSet())
                ExpansionTile(
                  title: Text(_topicLabel(kind)),
                  tilePadding: EdgeInsets.zero,
                  children: [
                    for (final row in _associations[fact.id]!.where(
                      (r) => r.kind == kind,
                    ))
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(_ru ? row.nameRu : row.nameEn),
                        subtitle: Text(
                          '${_ru ? russianLearningText(row.relationRu) : row.relationEn}${row.checked.isEmpty ? '' : ' · ${row.checked}'}',
                        ),
                        trailing: row.sourceUrl.isEmpty
                            ? null
                            : _sourceLink(row.sourceUrl),
                        onTap: row.kind == 'neighbor'
                            ? () => change(() {
                                _selectedWater = null;
                                _selected = row.id;
                                _focus = row.id;
                                _query = '';
                              })
                            : ['instrument', 'culture'].contains(row.kind)
                            ? () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => MusicLearningPage(
                                    bundle: widget.bundle,
                                    initialEntryId: row.id,
                                  ),
                                ),
                              )
                            : null,
                      ),
                  ],
                ),
              Text(
                _t(
                  'Country data: mledoze/countries (ODbL). Population: World Bank, 2024. Major geographic relations are from a historical CIA Factbook snapshot; these are selected facts, not exhaustive lists.',
                  'Страны: mledoze/countries (ODbL). Население: Всемирный банк, 2024. Крупные водоёмы и ресурсы — из географического снимка CIA Factbook. Подборки фактов не являются полными списками.',
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Wrap(
                spacing: 8,
                children: [
                  _sourceLink(
                    'https://github.com/mledoze/countries',
                    'mledoze/countries',
                  ),
                  _sourceLink(
                    'https://data.worldbank.org/indicator/SP.POP.TOTL',
                    'World Bank',
                  ),
                  _sourceLink('https://flagcdn.com/', 'Flagpedia / FlagCDN'),
                  FilledButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _start(countryId: fact.id);
                    },
                    child: Text(
                      _t('Train this country', 'Тренировать эту страну'),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _start();
                    },
                    child: Text(
                      _t('Train all countries', 'Тренировать все страны'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _practiceTop() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted && _practiceScroll.hasClients) _practiceScroll.jumpTo(0);
  });

  void _nextPractice() {
    setState(() {
      _index++;
      _choice = null;
      _checked = false;
    });
    _practiceTop();
  }

  Widget _quiz() {
    if (_index >= _questions.length) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_t('Result', 'Результат')),
          leading: IconButton(
            tooltip: _t('Back to atlas', 'Вернуться к атласу'),
            onPressed: () => setState(() => _practice = false),
            icon: const Icon(Icons.arrow_back),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _t(
                  'Score $_score / ${_questions.length}',
                  'Счёт $_score / ${_questions.length}',
                ),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              FilledButton(
                onPressed: _start,
                child: Text(_t('New round', 'Новый раунд')),
              ),
              if (_missed.isNotEmpty)
                OutlinedButton(
                  onPressed: () => _start(retry: List.of(_missed)),
                  child: Text(_t('Retry mistakes', 'Повторить ошибки')),
                ),
            ],
          ),
        ),
      );
    }
    final q = _questions[_index];
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: _t('Back to atlas', 'Вернуться к атласу'),
          onPressed: () => setState(() => _practice = false),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(
          _t(
            'Training · local unranked',
            'Тренировка · локальная, без рейтинга',
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _practiceScroll,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('${_index + 1} / ${_questions.length}'),
              const SizedBox(height: 12),
              Text(
                _questionText(q),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              if (q.kind == 'flag')
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Image.asset(
                    'assets/quizipedia/flag-${q.country.id.toLowerCase()}.png',
                    height: 110,
                    semanticLabel: _t(
                      'Flag to identify',
                      'Флаг для определения',
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              if (_checked)
                Container(
                  key: const Key('quizipedia-feedback'),
                  padding: const EdgeInsets.all(12),
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _choice == q.answer
                            ? _t('Correct', 'Верно')
                            : _t('Incorrect', 'Неверно'),
                      ),
                      Text(
                        '${_t('Your answer', 'Ваш ответ')}: ${_display(_choice!)}',
                        key: const Key('country-your-answer'),
                      ),
                      Text(
                        '${_t('Correct answer', 'Правильный ответ')}: ${_display(q.answer)}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _answerExplanation(q),
                        key: const Key('country-answer-explanation'),
                      ),
                      if (_choiceExplanations(q) case final explanations
                          when explanations.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        CountryChoiceExplanationPanel(
                          explanations: explanations,
                          title: _t('About each choice', 'О каждом варианте'),
                          display: _display,
                        ),
                      ],
                      if (q.association?.sourceUrl.isNotEmpty ?? false)
                        _sourceLink(q.association!.sourceUrl),
                      if (q.kind == 'population')
                        _sourceLink(
                          'https://data.worldbank.org/indicator/SP.POP.TOTL',
                          'World Bank · ${q.country.populationYear}',
                        ),
                      if (q.kind == 'language' &&
                          q.country.officialLanguagesSource.isNotEmpty)
                        _sourceLink(q.country.officialLanguagesSource),
                      if (q.source.isNotEmpty)
                        Text(
                          '${q.kind == 'religion' ? _t('Data year', 'Год данных') : _t('Checked', 'Проверено')}: ${q.source}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
              ...q.options.map(
                (option) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: OutlinedButton(
                    onPressed: _checked
                        ? null
                        : () {
                            setState(() {
                              _choice = option;
                              _checked = true;
                              if (option == q.answer) {
                                _score++;
                              } else {
                                _missed.add(q);
                              }
                            });
                            _practiceTop();
                          },
                    style: OutlinedButton.styleFrom(
                      disabledForegroundColor: Theme.of(context)
                          .colorScheme
                          .onSurface,
                      foregroundColor: _checked && option != q.answer
                          ? Theme.of(context).colorScheme.onSurfaceVariant
                          : null,
                      backgroundColor: !_checked
                          ? null
                          : option == q.answer
                          ? Theme.of(context).colorScheme.secondaryContainer
                          : _choice == option
                          ? Theme.of(context).colorScheme.errorContainer
                                .withValues(alpha: .45)
                          : Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                    ),
                    child: Row(
                      children: [
                        if (_checked &&
                            (option == q.answer || option == _choice)) ...[
                          Icon(
                            option == q.answer
                                ? Icons.check_circle
                                : Icons.cancel,
                            color: option == q.answer
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: Text(
                            _display(option),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _checked
          ? SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: FilledButton(
                  onPressed: _nextPractice,
                  child: Text(_t('Next', 'Далее')),
                ),
              ),
            )
          : null,
    );
  }
}
