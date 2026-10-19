/// Source-linked, local fact practice data. This keeps the atlas assets canonical.
library;

import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';

import 'country_labels_ru.dart';
import 'russian_learning_text.dart';

class FactSource {
  const FactSource({
    required this.titleRu,
    required this.titleEn,
    required this.url,
  });
  final String titleRu, titleEn, url;
}

class StudyFact {
  const StudyFact({
    required this.id,
    required this.scope,
    required this.entityId,
    required this.nameRu,
    required this.nameEn,
    required this.fieldPath,
    required this.fieldRu,
    required this.fieldEn,
    required this.valueRu,
    required this.valueEn,
    required this.sources,
  });
  final String id, scope, entityId, nameRu, nameEn, fieldPath;
  final String fieldRu, fieldEn, valueRu, valueEn;
  final List<FactSource> sources;
}

class FactChoice {
  const FactChoice({
    required this.id,
    required this.textRu,
    required this.textEn,
  });
  final String id, textRu, textEn;
}

class FactQuestion {
  const FactQuestion({
    required this.fact,
    required this.options,
    required this.correctId,
  });
  final StudyFact fact;
  final List<FactChoice> options;
  final String correctId;
}

const _assets = <String>[
  'assets/quizipedia/country_facts.json',
  'assets/quizipedia/country_religions.json',
  'assets/quizipedia/country_links.json',
  'assets/quizipedia/country_culture.json',
  'assets/quizipedia/country_waters.json',
  'assets/quizipedia/country_presidents.json',
  'assets/quizipedia/catalog.json',
  'assets/quizipedia/music_learning.json',
  'assets/quizipedia/organ_atlas.json',
  'assets/quizipedia/belief_atlas.json',
  'assets/quizipedia/food_atlas.json',
  'assets/quizipedia/brands.json',
  'assets/quizipedia/knowledge_atlas.json',
];

/// Loads one frozen fact scope, or every scope when [scope] is `all`.
Future<List<StudyFact>> loadStudyFacts(
  String scope, {
  AssetBundle? bundle,
}) async {
  final assets = await Future.wait(
    _assets.map(
      (path) async => MapEntry(
        path,
        Map<String, dynamic>.from(
          jsonDecode(await (bundle ?? rootBundle).loadString(path)) as Map,
        ),
      ),
    ),
  );
  final values = {for (final entry in assets) entry.key: entry.value};
  final facts = extractStudyFacts(values);
  if (scope == 'all') return facts;
  return List.unmodifiable(facts.where((fact) => fact.scope == scope));
}

/// Pure asset extraction, exposed for small fixtures and contract tests.
List<StudyFact> extractStudyFacts(Map<String, Map<String, dynamic>> assets) {
  final out = <StudyFact>[];
  final country = assets['assets/quizipedia/country_facts.json']!;
  final religion = assets['assets/quizipedia/country_religions.json']!;
  final catalog = assets['assets/quizipedia/catalog.json']!;
  final music = assets['assets/quizipedia/music_learning.json']!;
  final organ = assets['assets/quizipedia/organ_atlas.json']!;
  final belief = assets['assets/quizipedia/belief_atlas.json']!;
  final food = assets['assets/quizipedia/food_atlas.json']!;
  final brands = assets['assets/quizipedia/brands.json']!;
  final knowledge = assets['assets/quizipedia/knowledge_atlas.json']!;

  final countryNames = <String, (String, String)>{};
  for (final row in _rows(country['countries'])) {
    countryNames[_text(row, 'id')] = (
      _text(row, 'name_ru'),
      _text(row, 'name_en'),
    );
  }
  _countryFacts(out, country, religion, countryNames, [
    ('links', assets['assets/quizipedia/country_links.json']!),
    ('culture', assets['assets/quizipedia/country_culture.json']!),
    ('waters', assets['assets/quizipedia/country_waters.json']!),
    ('presidents', assets['assets/quizipedia/country_presidents.json']!),
  ]);
  _catalogFacts(out, catalog, countryNames);
  _musicFacts(out, music);
  _organFacts(out, organ);
  _beliefFacts(out, belief);
  _foodFacts(out, food);
  _brandFacts(out, brands);
  _knowledgeFacts(out, knowledge);
  out.sort((a, b) => a.id.compareTo(b.id));
  return List.unmodifiable(out);
}

void _countryFacts(
  List<StudyFact> out,
  Map<String, dynamic> data,
  Map<String, dynamic> religion,
  Map<String, (String, String)> names,
  List<(String, Map<String, dynamic>)> relationAssets,
) {
  final source = _sourceMap(data);
  const countryRefs = ['countries'];
  for (final row in _rows(data['countries'])) {
    final id = _text(row, 'id');
    final ru = _text(row, 'name_ru'), en = _text(row, 'name_en');
    void add(
      String path,
      String fieldRu,
      String fieldEn,
      Object? ruValue,
      Object? enValue, {
      List<String>? refs,
    }) => _add(
      out,
      'countries',
      id,
      ru,
      en,
      path,
      fieldRu,
      fieldEn,
      ruValue,
      enValue,
      _refs(source, refs ?? countryRefs),
    );
    add(
      'capital',
      'Столица',
      'Capital',
      russianCountryLabel(_textOr(row, 'capital')),
      _textOr(row, 'capital'),
    );
    for (final entry in _strings(row['languages']).indexed) {
      add(
        'languages.${entry.$1}',
        'Язык',
        'Language',
        russianCountryLabel(entry.$2),
        entry.$2,
      );
    }
    for (final entry in _strings(row['official_languages']).indexed) {
      add(
        'official_languages.${entry.$1}',
        'Официальный язык',
        'Official language',
        russianCountryLabel(entry.$2),
        entry.$2,
      );
    }
    for (final entry in _strings(row['currencies']).indexed) {
      add(
        'currencies.${entry.$1}',
        'Валюта',
        'Currency',
        russianCountryLabel(entry.$2),
        entry.$2,
      );
    }
    final population = row['population'];
    final populationYear = row['population_year'];
    if (population is num && population > 0) {
      final yearSuffix = populationYear is int && populationYear > 0
          ? ' ($populationYear)'
          : '';
      add(
        'population',
        'Население$yearSuffix',
        'Population$yearSuffix',
        '$population$yearSuffix',
        '$population$yearSuffix',
        refs: const ['population'],
      );
    }
    for (final neighbor in _strings(row['neighbors']).indexed) {
      final neighborName = names[neighbor.$2];
      if (neighborName == null) continue;
      final neighborUrl = Map<String, dynamic>.from(
        row['neighbor_sources'] as Map? ?? const {},
      )[neighbor.$2];
      _add(
        out,
        'countries',
        id,
        ru,
        en,
        'neighbors.${neighbor.$1}',
        'Соседняя страна',
        'Neighbouring country',
        neighborName.$1,
        neighborName.$2,
        neighborUrl is String
            ? _urlSource(neighborUrl, 'Справочник стран', 'Country data source')
            : _refs(source, countryRefs),
      );
    }
    add(
      'region',
      'Регион',
      'Region',
      russianCountryLabel(_textOr(row, 'region')),
      _textOr(row, 'region'),
    );
    add(
      'subregion',
      'Субрегион',
      'Subregion',
      russianCountryLabel(_textOr(row, 'subregion')),
      _textOr(row, 'subregion'),
    );
    final area = row['area_km2'];
    if (area is num && area > 0) {
      add('area_km2', 'Площадь', 'Area', '$area км²', '$area km²');
    }
  }
  final url = _textOr(religion, 'source_url');
  final religionSource = [
    FactSource(
      titleRu: 'Исследование религиозного состава',
      titleEn: 'Religious composition study',
      url: url,
    ),
  ];
  for (final row in _rows(religion['countries'])) {
    final id = _text(row, 'id');
    final name =
        names[id] ?? (_textOr(row, 'source_name'), _textOr(row, 'source_name'));
    final shares = Map<String, dynamic>.from(row['shares'] as Map? ?? const {});
    final year = religion['year'];
    final yearSuffix = year is int ? ' ($year)' : '';
    for (final entry in shares.entries) {
      if (entry.value is num) {
        final group = _religionGroup(entry.key);
        _add(
          out,
          'countries',
          id,
          name.$1,
          name.$2,
          'religion_shares.${entry.key}',
          'Доля: ${group.$1}$yearSuffix',
          'Share: ${group.$2}$yearSuffix',
          '${(entry.value as num).toStringAsFixed(3)}%',
          '${(entry.value as num).toStringAsFixed(3)}%',
          religionSource,
        );
      }
    }
  }
  for (final asset in relationAssets) {
    final sourceMap = _sourceMap(asset.$2);
    final countries = Map<String, dynamic>.from(
      asset.$2['countries'] as Map? ?? const {},
    );
    if (asset.$1 == 'presidents') {
      for (final entry in countries.entries) {
        final row = Map<String, dynamic>.from(entry.value as Map);
        final name = names[entry.key] ?? (entry.key, entry.key);
        _add(
          out,
          'countries',
          entry.key,
          name.$1,
          name.$2,
          'president.name',
          'Глава государства',
          'Head of state',
          _textOr(row, 'name_ru'),
          _textOr(row, 'name_en'),
          _refs(sourceMap, [_textOr(row, 'source_id')]),
        );
      }
      continue;
    }
    for (final countryEntry in countries.entries) {
      final name =
          names[countryEntry.key] ?? (countryEntry.key, countryEntry.key);
      for (final item in _rows(countryEntry.value)) {
        final itemId = _textOr(item, 'id').isEmpty
            ? _textOr(item, 'name_en')
            : _textOr(item, 'id');
        final refs = _refs(sourceMap, [_textOr(item, 'source_id')]);
        _add(
          out,
          'countries',
          countryEntry.key,
          name.$1,
          name.$2,
          '${asset.$1}.${_textOr(item, 'kind')}.$itemId.name',
          _relationLabelRu(asset.$1, item),
          _relationLabelEn(asset.$1, item),
          _textOr(item, 'name_ru'),
          _textOr(item, 'name_en'),
          refs,
        );
        final itemKind = _textOr(item, 'kind');
        _add(
          out,
          'countries',
          '${countryEntry.key}:${asset.$1}:${itemKind.isEmpty ? 'item' : itemKind}:$itemId',
          name.$1,
          name.$2,
          '${asset.$1}.$itemKind.$itemId.relation',
          _relationFieldRu(asset.$1, item),
          _relationFieldEn(asset.$1, item),
          _relationValueRu(asset.$1, item),
          _relationValueEn(asset.$1, item),
          refs,
        );
      }
    }
  }
}

void _catalogFacts(
  List<StudyFact> out,
  Map<String, dynamic> data,
  Map<String, (String, String)> countryNames,
) {
  for (final row in _rows(data['constellations'])) {
    final id = _text(row, 'id'),
        ru = _text(row, 'name_ru'),
        en = _text(row, 'name_en');
    final sources = _urlSource(
      _textOr(row, 'source_url'),
      'Карта созвездия',
      'Constellation chart',
    );
    _add(
      out,
      'sky',
      id,
      ru,
      en,
      'iau_abbreviation',
      'Сокращение МАС',
      'IAU abbreviation',
      _textOr(row, 'iau_abbreviation'),
      _textOr(row, 'iau_abbreviation'),
      sources,
    );
    _add(
      out,
      'sky',
      id,
      ru,
      en,
      'explanation',
      'Описание',
      'Description',
      _textOr(row, 'explanation_ru'),
      _textOr(row, 'explanation_en'),
      sources,
    );
    _add(
      out,
      'sky',
      id,
      ru,
      en,
      'latin_name',
      'Латинское название',
      'Latin name',
      _textOr(row, 'latin_name'),
      _textOr(row, 'latin_name'),
      sources,
    );
    for (final star in _rows(row['stars'])) {
      final prefix = 'stars.${_text(star, 'id')}';
      _add(
        out,
        'sky',
        id,
        ru,
        en,
        '$prefix.name',
        'Название звезды',
        'Star name',
        _textOr(star, 'name_ru'),
        _textOr(star, 'name'),
        sources,
      );
      for (final field in ['magnitude', 'ra_hours', 'dec_degrees']) {
        final value = star[field];
        if (value is num) {
          _add(
            out,
            'sky',
            id,
            ru,
            en,
            '$prefix.$field',
            '${_skyLabelRu(field)} звезды ${_textOr(star, 'name_ru')}',
            '${_skyLabelEn(field)} of ${_textOr(star, 'name')}',
            '$value',
            '$value',
            sources,
          );
        }
      }
    }
  }
  for (final row in _rows(data['landmarks'])) {
    final id = _text(row, 'id'),
        ru = _text(row, 'name_ru'),
        en = _text(row, 'name_en');
    final sources = _urlSource(
      _textOr(row, 'source_url'),
      'Источник о памятнике',
      'Landmark source',
    );
    _add(
      out,
      'landmarks',
      id,
      ru,
      en,
      'city',
      'Город',
      'City',
      _textOr(row, 'city_ru'),
      _textOr(row, 'city_en'),
      sources,
    );
    final country = countryNames[_textOr(row, 'country_iso2')];
    if (country != null) {
      _add(
        out,
        'landmarks',
        id,
        ru,
        en,
        'country',
        'Страна',
        'Country',
        country.$1,
        country.$2,
        sources,
      );
    }
    _add(
      out,
      'landmarks',
      id,
      ru,
      en,
      'explanation',
      'Описание',
      'Description',
      _textOr(row, 'explanation_ru'),
      _textOr(row, 'explanation_en'),
      sources,
    );
  }
  final anatomy = Map<String, dynamic>.from(
    data['anatomy'] as Map? ?? const {},
  );
  for (final row in _rows(anatomy['targets'])) {
    final sources = _urlSource(
      _textOr(row, 'source_url'),
      'Анатомический источник',
      'Anatomy source',
    );
    _add(
      out,
      'endocrine',
      _text(row, 'id'),
      _text(row, 'name_ru'),
      _text(row, 'name_en'),
      'explanation',
      'Описание',
      'Description',
      _textOr(row, 'explanation_ru'),
      _textOr(row, 'explanation_en'),
      sources,
    );
  }
}

void _musicFacts(List<StudyFact> out, Map<String, dynamic> data) {
  final sources = _sourceMap(data);
  for (final row in _rows(data['entries'])) {
    final id = _text(row, 'id'),
        ru = _text(row, 'name_ru'),
        en = _text(row, 'name_en');
    final refs = _refs(sources, _strings(row['source_ids']));
    _add(
      out,
      'music',
      id,
      ru,
      en,
      'category',
      'Категория',
      'Category',
      _musicCategoryRu(_textOr(row, 'category')),
      _textOr(row, 'category'),
      refs,
    );
    _add(
      out,
      'music',
      id,
      ru,
      en,
      'description',
      'Описание',
      'Description',
      _textOr(row, 'description_ru'),
      _textOr(row, 'description_en'),
      refs,
    );
    _add(
      out,
      'music',
      id,
      ru,
      en,
      'example',
      'Пример',
      'Example',
      _textOr(row, 'example_ru'),
      _textOr(row, 'example_en'),
      refs,
    );
  }
}

void _organFacts(List<StudyFact> out, Map<String, dynamic> data) {
  final sources = _sourceMap(data);
  for (final row in _rows(data['organs'])) {
    final id = _text(row, 'id'),
        ru = _text(row, 'name_ru'),
        en = _text(row, 'name_en');
    final refs = _refs(sources, _strings(row['source_ids']));
    void add(
      String path,
      String a,
      String b,
      Object? c,
      Object? d, [
      List<FactSource>? own,
    ]) => _add(out, 'organs', id, ru, en, path, a, b, c, d, own ?? refs);
    add(
      'kind',
      'Тип',
      'Kind',
      _organLabelRu(_textOr(row, 'kind')),
      _organLabelEn(_textOr(row, 'kind')),
    );
    add(
      'region',
      'Область тела',
      'Body region',
      _textOr(row, 'region'),
      _textOr(row, 'region'),
    );
    for (final item in _strings(row['system_ids']).indexed) {
      add(
        'system_ids.${item.$1}',
        'Система',
        'System',
        _organLabelRu(item.$2),
        _organLabelEn(item.$2),
      );
    }
    add(
      'position',
      'Положение',
      'Position',
      _textOr(row, 'position_ru'),
      _textOr(row, 'position_en'),
    );
    add(
      'function',
      'Функция',
      'Function',
      _textOr(row, 'function_ru'),
      _textOr(row, 'function_en'),
    );
    final ruSecretions = _strings(row['secretions_ru']),
        enSecretions = _strings(row['secretions_en']);
    for (var i = 0; i < min(ruSecretions.length, enSecretions.length); i++) {
      add(
        'secretions.$i',
        'Секреция',
        'Secretion',
        ruSecretions[i],
        enSecretions[i],
      );
    }
    for (final item in _rows(row['facts']).indexed) {
      add(
        'facts.${item.$1}',
        'Факт',
        'Fact',
        _textOr(item.$2, 'text_ru'),
        _textOr(item.$2, 'text_en'),
        _refs(sources, _strings(item.$2['source_ids'])),
      );
    }
    add(
      'note',
      'Примечание',
      'Note',
      _textOr(row, 'note_ru'),
      _textOr(row, 'note_en'),
    );
  }
}

void _beliefFacts(List<StudyFact> out, Map<String, dynamic> data) {
  final sources = _sourceMap(data);
  for (final row in _rows(data['nodes'])) {
    final scope = _text(row, 'section'),
        id = _text(row, 'id'),
        ru = _text(row, 'name_ru'),
        en = _text(row, 'name_en');
    final refs = _refs(sources, _strings(row['source_ids']));
    void add(
      String p,
      String a,
      String b,
      Object? c,
      Object? d, [
      List<FactSource>? own,
    ]) => _add(out, scope, id, ru, en, p, a, b, c, d, own ?? refs);
    add(
      'group',
      'Группа',
      'Group',
      _textOr(row, 'group_ru'),
      _textOr(row, 'group_en'),
    );
    add(
      'summary',
      'Описание',
      'Summary',
      _textOr(row, 'summary_ru'),
      _textOr(row, 'summary_en'),
    );
    final domainsRu = _strings(row['domains_ru']),
        domainsEn = _strings(row['domains_en']);
    for (var i = 0; i < min(domainsRu.length, domainsEn.length); i++) {
      add('domains.$i', 'Сфера', 'Domain', domainsRu[i], domainsEn[i]);
    }
    final symbolsRu = _strings(row['symbols_ru']),
        symbolsEn = _strings(row['symbols_en']);
    for (var i = 0; i < min(symbolsRu.length, symbolsEn.length); i++) {
      add('symbols.$i', 'Символ', 'Symbol', symbolsRu[i], symbolsEn[i]);
    }
    for (final item in _rows(row['facts']).indexed) {
      add(
        'facts.${item.$1}',
        'Факт',
        'Fact',
        _textOr(item.$2, 'text_ru'),
        _textOr(item.$2, 'text_en'),
        _refs(sources, _strings(item.$2['source_ids'])),
      );
    }
    add(
      'variant_note',
      'Вариант',
      'Variant note',
      _textOr(row, 'variant_note_ru'),
      _textOr(row, 'variant_note_en'),
    );
  }
  final nodeById = {
    for (final node in _rows(data['nodes'])) _text(node, 'id'): node,
  };
  for (final edge in _rows(data['edges'])) {
    final from = nodeById[_text(edge, 'from_id')];
    if (from == null) continue;
    final scope = _text(from, 'section'), id = _text(edge, 'id');
    final nameRu =
        '${_text(from, 'name_ru')} — ${_text(nodeById[_text(edge, 'to_id')] ?? from, 'name_ru')}';
    final nameEn =
        '${_text(from, 'name_en')} — ${_text(nodeById[_text(edge, 'to_id')] ?? from, 'name_en')}';
    final refs = _refs(sources, _strings(edge['source_ids']));
    _add(
      out,
      scope,
      id,
      nameRu,
      nameEn,
      'edge.label',
      'Связь',
      'Relationship',
      _textOr(edge, 'label_ru'),
      _textOr(edge, 'label_en'),
      refs,
    );
    _add(
      out,
      scope,
      id,
      nameRu,
      nameEn,
      'edge.scope',
      'Контекст связи: ${_textOr(edge, 'label_ru')}',
      'Relationship context: ${_textOr(edge, 'label_en')}',
      _textOr(edge, 'scope_ru'),
      _textOr(edge, 'scope_en'),
      refs,
    );
  }
}

void _foodFacts(List<StudyFact> out, Map<String, dynamic> data) {
  final sources = _sourceMap(data);
  for (final row in _rows(data['dishes'])) {
    final id = _text(row, 'id'),
        ru = _text(row, 'name_ru'),
        en = _text(row, 'name_en');
    final refs = _refs(sources, _strings(row['source_ids']));
    void add(
      String p,
      String a,
      String b,
      Object? c,
      Object? d, [
      List<FactSource>? own,
    ]) => _add(out, 'food', id, ru, en, p, a, b, c, d, own ?? refs);
    for (final pair in [
      ('category', 'Категория', 'Category'),
      ('country', 'Страна', 'Country'),
      ('region', 'Регион', 'Region'),
      ('summary', 'Описание', 'Summary'),
      ('classic_note', 'Классическая версия', 'Classic note'),
      ('origin', 'Происхождение', 'Origin'),
      ('servings', 'Порции', 'Servings'),
    ]) {
      add(
        pair.$1,
        pair.$2,
        pair.$3,
        _textOr(row, '${pair.$1}_ru'),
        _textOr(row, '${pair.$1}_en'),
      );
    }
    for (final item in _rows(row['ingredients']).indexed) {
      add(
        'ingredients.${item.$1}.name',
        'Ингредиент',
        'Ingredient',
        _textOr(item.$2, 'name_ru'),
        _textOr(item.$2, 'name_en'),
      );
      add(
        'ingredients.${item.$1}.amount',
        'Количество ингредиента: ${_textOr(item.$2, 'name_ru')}',
        'Amount of ingredient: ${_textOr(item.$2, 'name_en')}',
        _textOr(item.$2, 'amount_ru'),
        _textOr(item.$2, 'amount_en'),
      );
    }
    for (final item in _rows(row['steps']).indexed) {
      add(
        'steps.${item.$1}',
        'Шаг рецепта',
        'Recipe step',
        _textOr(item.$2, 'text_ru'),
        _textOr(item.$2, 'text_en'),
      );
    }
    for (final item in _rows(row['facts']).indexed) {
      add(
        'facts.${item.$1}',
        'Факт',
        'Fact',
        _textOr(item.$2, 'text_ru'),
        _textOr(item.$2, 'text_en'),
        _refs(sources, _strings(item.$2['source_ids'])),
      );
    }
    for (final item in _rows(row['variants']).indexed) {
      final vrefs = _refs(sources, _strings(item.$2['source_ids']));
      add(
        'variants.${item.$1}.name',
        'Вариант',
        'Variant',
        _textOr(item.$2, 'name_ru'),
        _textOr(item.$2, 'name_en'),
        vrefs,
      );
      add(
        'variants.${item.$1}.region',
        'Регион варианта: ${_textOr(item.$2, 'name_ru')}',
        'Variant region: ${_textOr(item.$2, 'name_en')}',
        _textOr(item.$2, 'region_ru'),
        _textOr(item.$2, 'region_en'),
        vrefs,
      );
      add(
        'variants.${item.$1}.difference',
        'Отличие варианта: ${_textOr(item.$2, 'name_ru')}',
        'Variant difference: ${_textOr(item.$2, 'name_en')}',
        _textOr(item.$2, 'difference_ru'),
        _textOr(item.$2, 'difference_en'),
        vrefs,
      );
    }
  }
}

void _brandFacts(List<StudyFact> out, Map<String, dynamic> data) {
  final sources = _sourceMap(data);
  final owners = {
    for (final owner in _rows(data['owners']))
      _text(owner, 'id'): (
        russianLearningText(_text(owner, 'name')),
        _text(owner, 'name'),
      ),
  };
  for (final owner in _rows(data['owners'])) {
    final id = _text(owner, 'id'), name = _text(owner, 'name');
    _add(
      out,
      'brands',
      'owner:$id',
      russianLearningText(name),
      name,
      'owner.description',
      'Описание владельца',
      'Owner description',
      _textOr(owner, 'description_ru'),
      _textOr(owner, 'description_en'),
      _refs(sources, _strings(owner['source_ids'])),
    );
  }
  for (final row in _rows(data['brands'])) {
    final id = _text(row, 'id'), name = _text(row, 'name');
    final ru = russianLearningText(name);
    final refs = _refs(sources, _strings(row['source_ids']));
    void add(
      String path,
      String fieldRu,
      String fieldEn,
      Object? valueRu,
      Object? valueEn, [
      List<FactSource>? own,
    ]) => _add(
      out,
      'brands',
      id,
      ru,
      name,
      path,
      fieldRu,
      fieldEn,
      valueRu,
      valueEn,
      own ?? refs,
    );
    for (final item in [
      ('sector', 'Сектор', 'Sector'),
      ('country', 'Страна', 'Country'),
      ('date_note', 'Примечание о дате', 'Date note'),
      ('ownership_note', 'Владение', 'Ownership'),
    ]) {
      add(
        item.$1,
        item.$2,
        item.$3,
        _textOr(row, '${item.$1}_ru'),
        _textOr(row, '${item.$1}_en'),
      );
    }
    if (row['founded_year'] is int) {
      add(
        'founded_year',
        'Год основания',
        'Foundation year',
        '${row['founded_year']}',
        '${row['founded_year']}',
      );
    }
    final owner = owners[_textOr(row, 'owner_id')];
    if (owner != null) {
      add('owner.name', 'Владелец', 'Owner', owner.$1, owner.$2);
    }
    for (final founder in _strings(row['founders']).indexed) {
      add(
        'founders.${founder.$1}',
        'Основатель',
        'Founder',
        russianLearningText(founder.$2),
        founder.$2,
      );
    }
    for (final item in _rows(row['former_names']).indexed) {
      if (item.$2['quiz_enabled'] == false) continue;
      final oldEn = _textOr(item.$2, 'name');
      final oldRu = russianLearningText(oldEn);
      final own = _refs(sources, _strings(item.$2['source_ids']));
      add(
        'former_names.${item.$1}.name',
        'Прежнее название',
        'Former name',
        oldRu,
        oldEn,
        own,
      );
      for (final key in ['from_year', 'to_year']) {
        if (item.$2[key] is int) {
          add(
            'former_names.${item.$1}.$key',
            '${key == 'from_year' ? 'Начало названия' : 'Окончание названия'}: $oldRu',
            '${key == 'from_year' ? 'Start of name' : 'End of name'}: $oldEn',
            '${item.$2[key]}',
            '${item.$2[key]}',
            own,
          );
        }
      }
      add(
        'former_names.${item.$1}.note',
        'Примечание о названии: $oldRu',
        'Name note: $oldEn',
        _textOr(item.$2, 'note_ru'),
        _textOr(item.$2, 'note_en'),
        own,
      );
    }
    // The disabled BackRub former-name item is preserved as a separate,
    // qualified research-project fact. Its years remain excluded.
    if (id == 'google') {
      final candidates = _rows(row['former_names'])
          .where((item) => _textOr(item, 'name') == 'BackRub');
      if (candidates.isNotEmpty) {
        final backrub = candidates.first;
        add(
          'historical_project',
          'Исследовательский проект до Гугл',
          'Research project before Google',
          'БэкРаб',
          'BackRub',
          _refs(sources, _strings(backrub['source_ids'])),
        );
      }
    }
    for (final item in _rows(row['facts']).indexed) {
      add(
        'facts.${item.$1}',
        'Факт',
        'Fact',
        _textOr(item.$2, 'text_ru'),
        _textOr(item.$2, 'text_en'),
        _refs(sources, _strings(item.$2['source_ids'])),
      );
    }
    for (final item in _rows(row['logo_history']).indexed) {
      final own = _refs(sources, _strings(item.$2['source_ids']));
      final year = item.$2['year'];
      final suffix = year is int ? ': $year' : '';
      add(
        'logo_history.${item.$1}.text',
        'История логотипа$suffix',
        'Logo history$suffix',
        _textOr(item.$2, 'text_ru'),
        _textOr(item.$2, 'text_en'),
        own,
      );
    }
  }
}

void _knowledgeFacts(List<StudyFact> out, Map<String, dynamic> data) {
  final peopleById = {
    for (final row in _rows(data['people']))
      _text(row, 'id'): (_text(row, 'name_ru'), _text(row, 'name_en')),
  };
  final worksById = {
    for (final row in _rows(data['works']))
      _text(row, 'id'): (_text(row, 'title_ru'), _text(row, 'title_en')),
  };
  void sourceAdd(
    String scope,
    Map<String, dynamic> row,
    String id,
    String nameRu,
    String nameEn,
    String path,
    String fieldRu,
    String fieldEn,
    Object? valueRu,
    Object? valueEn,
  ) => _add(
    out,
    scope,
    id,
    nameRu,
    nameEn,
    path,
    fieldRu,
    fieldEn,
    valueRu,
    valueEn,
    _urlSource(_textOr(row, 'source_url'), 'Источник', 'Source'),
  );
  for (final row in _rows(data['events'])) {
    final id = _text(row, 'id');
    final nameRu = _text(row, 'title_ru'), nameEn = _text(row, 'title_en');
    final year = row['year'];
    if (year is int) {
      final date = _localizedDate(
        year,
        endYear: row['end_year'] is int ? row['end_year'] as int : null,
        approximate: row['approximate'] == true,
      );
      sourceAdd(
        'history',
        row,
        id,
        nameRu,
        nameEn,
        'date',
        'Дата',
        'Date',
        date.$1,
        date.$2,
      );
    }
    for (final item in [
      ('era', 'Эпоха', 'Era'),
      ('what', 'Что произошло', 'What happened'),
      ('why', 'Почему важно', 'Why it matters'),
      ('consequences', 'Последствия', 'Consequences'),
    ]) {
      if (row[item.$1] == null) continue;
      sourceAdd(
        'history',
        row,
        id,
        nameRu,
        nameEn,
        item.$1,
        item.$2,
        item.$3,
        item.$1 == 'era'
            ? _eraRu('${row[item.$1]}')
            : _textOr(row, '${item.$1}_ru'),
        item.$1 == 'era' ? '${row[item.$1]}' : _textOr(row, '${item.$1}_en'),
      );
    }
  }
  for (final row in _rows(data['works'])) {
    final id = _text(row, 'id');
    final nameRu = _text(row, 'title_ru'), nameEn = _text(row, 'title_en');
    final year = row['year'];
    if (year is int) {
      final date = _localizedDate(
        year,
        endYear: row['end_year'] is int ? row['end_year'] as int : null,
        approximate: row['approximate'] == true,
      );
      sourceAdd(
        'works',
        row,
        id,
        nameRu,
        nameEn,
        'date',
        'Дата',
        'Date',
        date.$1,
        date.$2,
      );
    }
    for (final item in [
      ('type', 'Тип', 'Type'),
      ('summary', 'Описание', 'Summary'),
      ('fact', 'Факт', 'Fact'),
    ]) {
      if (row[item.$1] == null) continue;
      sourceAdd(
        'works',
        row,
        id,
        nameRu,
        nameEn,
        item.$1,
        item.$2,
        item.$3,
        item.$1 == 'type'
            ? _workTypeRu('${row[item.$1]}')
            : _textOr(row, '${item.$1}_ru'),
        item.$1 == 'type' ? '${row[item.$1]}' : _textOr(row, '${item.$1}_en'),
      );
    }
    for (final creator in _strings(row['creator_ids']).indexed) {
      final person = peopleById[creator.$2];
      if (person == null) continue;
      sourceAdd(
        'works',
        row,
        id,
        nameRu,
        nameEn,
        'creators.${creator.$1}',
        'Создатель',
        'Creator',
        person.$1,
        person.$2,
      );
    }
    for (final cast in _tuples(row['cast']).indexed) {
      final actor = peopleById[_tupleText(cast.$2, 0)];
      if (actor == null) continue;
      sourceAdd(
        'works',
        row,
        id,
        nameRu,
        nameEn,
        'cast.${cast.$1}.role',
        'Роль: ${actor.$1}',
        'Role: ${actor.$2}',
        _tupleText(cast.$2, 1),
        _tupleText(cast.$2, 2),
      );
    }
  }
  for (final row in _rows(data['people'])) {
    final id = _text(row, 'id');
    final nameRu = _text(row, 'name_ru'), nameEn = _text(row, 'name_en');
    sourceAdd(
      'people',
      row,
      id,
      nameRu,
      nameEn,
      'born',
      'Год рождения',
      'Born',
      _textOr(row, 'born'),
      _textOr(row, 'born'),
    );
    sourceAdd(
      'people',
      row,
      id,
      nameRu,
      nameEn,
      'bio',
      'Биография',
      'Biography',
      _textOr(row, 'bio_ru'),
      _textOr(row, 'bio_en'),
    );
    for (final role in _strings(row['roles']).indexed) {
      sourceAdd(
        'people',
        row,
        id,
        nameRu,
        nameEn,
        'roles.${role.$1}',
        'Роль',
        'Role',
        _roleRu(role.$2),
        role.$2,
      );
    }
    for (final work in _strings(row['credit_work_ids']).indexed) {
      final resolved = worksById[work.$2];
      if (resolved == null) continue;
      sourceAdd(
        'people',
        row,
        id,
        nameRu,
        nameEn,
        'credit_work_ids.${work.$1}',
        'Участие в произведении',
        'Work credit',
        resolved.$1,
        resolved.$2,
      );
    }
  }
}

/// Creates one checkable value question per fact. It never uses another value
/// from the target entity as a distractor, even if that value has a sibling path.
List<FactQuestion> buildFactQuestions(
  Iterable<StudyFact> facts, {
  int seed = 0,
}) {
  final all = facts.toList()..sort((a, b) => a.id.compareTo(b.id));
  final byFamily = <String, List<StudyFact>>{};
  final byValueKind = <String, List<StudyFact>>{};
  final forbiddenRuByEntity = <String, Set<String>>{};
  final forbiddenEnByEntity = <String, Set<String>>{};
  for (final item in all) {
    final scope = item.scope;
    byFamily
        .putIfAbsent('$scope\u0000${_family(item.fieldPath)}', () => [])
        .add(item);
    byValueKind
        .putIfAbsent('$scope\u0000${_valueKind(item)}', () => [])
        .add(item);
    final key = '$scope\u0000${item.entityId}';
    forbiddenRuByEntity.putIfAbsent(key, () => {}).add(_normRu(item));
    forbiddenEnByEntity.putIfAbsent(key, () => {}).add(_normEn(item));
  }
  final result = <FactQuestion>[];
  for (final fact in all) {
    final key = '${fact.scope}\u0000${fact.entityId}';
    final candidates = _takeCandidates(
      byFamily['${fact.scope}\u0000${_family(fact.fieldPath)}']!,
      byValueKind['${fact.scope}\u0000${_valueKind(fact)}']!,
      fact,
      forbiddenRuByEntity[key]!,
      forbiddenEnByEntity[key]!,
      seed,
    );
    final options = <FactChoice>[
      FactChoice(id: fact.id, textRu: fact.valueRu, textEn: fact.valueEn),
      ...candidates
          .take(3)
          .map(
            (item) => FactChoice(
              id: item.id,
              textRu: item.valueRu,
              textEn: item.valueEn,
            ),
          ),
    ]..shuffle(Random(seed ^ _hash(fact.id)));
    if (options.length < 2) {
      throw StateError('No fair alternative for ${fact.id}');
    }
    result.add(
      FactQuestion(
        fact: fact,
        options: List.unmodifiable(options),
        correctId: fact.id,
      ),
    );
  }
  return List.unmodifiable(result);
}

List<StudyFact> _takeCandidates(
  List<StudyFact> compatible,
  List<StudyFact> compatibleKind,
  StudyFact fact,
  Set<String> forbiddenRu,
  Set<String> forbiddenEn,
  int seed,
) {
  final selected = <StudyFact>[];
  final seenRu = <String>{_normRu(fact)};
  final seenEn = <String>{_normEn(fact)};
  void take(Iterable<StudyFact> values) {
    for (final item in values) {
      if (selected.length == 3) return;
      final ru = _normRu(item), en = _normEn(item);
      if (item.entityId != fact.entityId &&
          !forbiddenRu.contains(ru) &&
          !forbiddenEn.contains(en) &&
          seenRu.add(ru) &&
          seenEn.add(en)) {
        selected.add(item);
      }
    }
  }

  Iterable<StudyFact> rotate(List<StudyFact> values) sync* {
    if (values.isEmpty) return;
    final start = (seed ^ _hash(fact.id)).abs() % values.length;
    for (var i = 0; i < values.length; i++) {
      yield values[(start + i) % values.length];
    }
  }

  take(rotate(compatible));
  if (selected.length < 3) take(rotate(compatibleKind));
  return selected;
}

void _add(
  List<StudyFact> out,
  String scope,
  String entityId,
  String nameRu,
  String nameEn,
  String path,
  String fieldRu,
  String fieldEn,
  Object? ru,
  Object? en,
  List<FactSource> sources,
) {
  final valueRu = russianLearningText('${ru ?? ''}'.trim());
  final valueEn = '${en ?? ''}'.trim();
  if (valueRu.isEmpty && valueEn.isEmpty) return;
  if (valueRu.isEmpty || valueEn.isEmpty) {
    throw FormatException('Missing localized value for $scope:$entityId:$path');
  }
  if (sources.isEmpty || sources.any((source) => !_https(source.url))) {
    throw FormatException('Missing secure source for $scope:$entityId:$path');
  }
  out.add(
    StudyFact(
      id: '$scope:$entityId:$path',
      scope: scope,
      entityId: entityId,
      nameRu: russianLearningText(nameRu),
      nameEn: nameEn,
      fieldPath: path,
      fieldRu: fieldRu,
      fieldEn: fieldEn,
      valueRu: valueRu,
      valueEn: valueEn,
      sources: List.unmodifiable(sources),
    ),
  );
}

List<Map<String, dynamic>> _rows(Object? value) => value is List
    ? value.whereType<Map>().map((v) => Map<String, dynamic>.from(v)).toList()
    : const [];
List<String> _strings(Object? value) => value is List
    ? value.whereType<String>().where((v) => v.trim().isNotEmpty).toList()
    : const [];
String _text(Map<String, dynamic> row, String key) => _textOr(row, key).trim();
String _textOr(Map<String, dynamic> row, String key) =>
    row[key] is String ? row[key] as String : '';
List<List<dynamic>> _tuples(Object? value) => value is List
    ? value.whereType<List>().map((item) => List<dynamic>.from(item)).toList()
    : const [];
String _tupleText(List<dynamic> value, int index) =>
    value.length > index && value[index] is String
    ? value[index] as String
    : '';
String _family(String path) {
  if (path == 'historical_project') return 'former_names.name';
  final parts = path.split('.');
  final stable = parts
      .where((part) => int.tryParse(part) == null && part.isNotEmpty)
      .toList();
  if (stable.first == 'links' && stable.length >= 3) {
    return 'links.${stable[1]}.${stable.last}';
  }
  if (stable.length >= 2 &&
      const {
        'stars',
        'ingredients',
        'variants',
        'former_names',
        'logo_history',
        'cast',
        'culture',
        'waters',
      }.contains(stable.first)) {
    return '${stable.first}.${stable.last}';
  }
  return stable.last;
}

String _valueKind(StudyFact fact) {
  final family = _family(fact.fieldPath);
  if (family == 'former_names.name') return 'historical_name';
  final leaf = family.split('.').last;
  if (leaf == 'relation') return 'relation';
  if (const {
    'date',
    'founded_year',
    'from_year',
    'to_year',
    'born',
  }.contains(leaf)) {
    return 'date';
  }
  if (const {
    'population',
    'area_km2',
    'magnitude',
    'ra_hours',
    'dec_degrees',
  }.contains(leaf)) {
    return 'numeric';
  }
  if (leaf == 'amount') {
    return 'amount';
  }
  if (fact.valueEn.contains('%')) {
    return 'percent';
  }
  if (const {
    'summary',
    'description',
    'explanation',
    'function',
    'position',
    'note',
    'fact',
    'what',
    'why',
    'consequences',
    'difference',
    'text',
    'scope',
    'bio',
    'date_note',
    'ownership_note',
  }.contains(leaf)) {
    return 'prose';
  }
  return 'label';
}

String _normRu(StudyFact fact) => _normal(fact.valueRu, russian: true);
String _normEn(StudyFact fact) => _normal(fact.valueEn);
String _normal(String value, {bool russian = false}) => value
    .replaceAll('\u00a0', ' ')
    .toLowerCase()
    .replaceAll(russian ? 'ё' : '\u0000', russian ? 'е' : '')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();
int _hash(String value) {
  var hash = 0;
  for (final code in value.codeUnits) {
    hash = 0x1fffffff & (hash + code);
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    hash ^= hash >> 6;
  }
  return hash;
}

String _skyLabelRu(String field) => switch (field) {
  'magnitude' => 'Звёздная величина',
  'ra_hours' => 'Прямое восхождение',
  _ => 'Склонение',
};
String _skyLabelEn(String field) => switch (field) {
  'magnitude' => 'Magnitude',
  'ra_hours' => 'Right ascension',
  _ => 'Declination',
};
String _musicCategoryRu(String value) =>
    const {
      'notes': 'Чтение нот',
      'notation': 'Знаки и ключи',
      'rhythm': 'Ритм и паузы',
      'dynamics': 'Динамика',
      'tempo': 'Темп',
      'technique': 'Исполнение',
      'harmony': 'Основы гармонии',
      'instruments': 'Оркестр',
      'world': 'Традиции мира',
    }[value] ??
    value;
String _organLabelRu(String value) =>
    const {
      'head': 'Голова',
      'neck': 'Шея',
      'thorax': 'Грудная клетка',
      'abdomen': 'Живот',
      'pelvis': 'Таз',
      'distributed': 'Распределено',
      'organ': 'Орган',
      'endocrine_gland': 'Эндокринная железа',
      'exocrine_gland': 'Экзокринная железа',
      'mixed_gland': 'Смешанная железа',
      'gland_group': 'Группа желёз',
      'endocrine_tissue': 'Эндокринная ткань',
      'nervous': 'Нервная система',
      'endocrine': 'Эндокринная система',
      'digestive': 'Пищеварительная система',
      'respiratory': 'Дыхательная система',
      'cardiovascular': 'Сердечно-сосудистая система',
      'urinary': 'Мочевыделительная система',
      'reproductive': 'Репродуктивная система',
      'lymphatic': 'Лимфатическая система',
      'integumentary': 'Покровная система',
      'sensory': 'Органы чувств',
      'musculoskeletal': 'Опорно-двигательная система',
    }[value] ??
    value;
String _organLabelEn(String value) =>
    const {
      'head': 'Head',
      'neck': 'Neck',
      'thorax': 'Chest',
      'abdomen': 'Abdomen',
      'pelvis': 'Pelvis',
      'distributed': 'Distributed',
      'organ': 'Organ',
      'endocrine_gland': 'Endocrine gland',
      'exocrine_gland': 'Exocrine gland',
      'mixed_gland': 'Mixed gland',
      'gland_group': 'Gland group',
      'endocrine_tissue': 'Endocrine tissue',
      'nervous': 'Nervous system',
      'endocrine': 'Endocrine system',
      'digestive': 'Digestive system',
      'respiratory': 'Respiratory system',
      'cardiovascular': 'Cardiovascular system',
      'urinary': 'Urinary system',
      'reproductive': 'Reproductive system',
      'lymphatic': 'Lymphatic system',
      'integumentary': 'Integumentary system',
      'sensory': 'Sense organs',
      'musculoskeletal': 'Musculoskeletal system',
    }[value] ??
    value;
String _eraRu(String value) =>
    const {
      'prehistory': 'Доисторическое время',
      'ancient': 'Древний мир',
      'medieval': 'Средние века',
      'early_modern': 'Раннее Новое время',
      'modern': 'Новое время',
      'contemporary': 'Современность',
    }[value] ??
    value;
String _workTypeRu(String value) =>
    const {
      'book': 'Книга',
      'play': 'Пьеса',
      'oratorio': 'Оратория',
      'music': 'Музыка',
      'opera': 'Опера',
      'ballet': 'Балет',
      'film': 'Фильм',
    }[value] ??
    value;
String _roleRu(String value) =>
    const {
      'author': 'Автор',
      'composer': 'Композитор',
      'director': 'Режиссёр',
      'actor': 'Актёр',
    }[value] ??
    value;
String _relationLabelRu(String asset, Map<String, dynamic> item) =>
    switch (asset) {
      'links' => _linkKindRu(_textOr(item, 'kind')),
      'culture' => 'Культурная связь',
      _ => 'Водоём',
    };
String _relationLabelEn(String asset, Map<String, dynamic> item) =>
    switch (asset) {
      'links' => _linkKindEn(_textOr(item, 'kind')),
      'culture' => 'Cultural connection',
      _ => 'Water body',
    };
String _relationFieldRu(String asset, Map<String, dynamic> item) {
  final name = russianLearningText(_textOr(item, 'name_ru'));
  return switch (asset) {
    'links' => 'Связь: «$name»',
    'culture' => 'Культурная связь: $name',
    _ => 'Связь с водоёмом: $name',
  };
}

String _relationFieldEn(String asset, Map<String, dynamic> item) {
  final name = _textOr(item, 'name_en');
  return switch (asset) {
    'links' => 'Relation: “$name”',
    'culture' => 'Cultural connection: $name',
    _ => 'Water relation: $name',
  };
}

String _relationValueRu(String asset, Map<String, dynamic> item) {
  final raw = _textOr(item, 'relation_ru');
  if (raw.isNotEmpty) return raw;
  return switch (_textOr(item, 'relation')) {
    'coast' => 'Омывает берега страны',
    'internal' => 'Находится на территории страны',
    'border' => 'Образует часть границы страны',
    'flows' => 'Протекает по территории или вдоль границы страны',
    _ => '',
  };
}

String _relationValueEn(String asset, Map<String, dynamic> item) {
  final raw = _textOr(item, 'relation_en');
  if (raw.isNotEmpty) return raw;
  return switch (_textOr(item, 'relation')) {
    'coast' => 'Coastal water body',
    'internal' => 'Water body within the country',
    'border' => 'Water body forming part of the border',
    'flows' => 'Flows through or along the country border',
    _ => '',
  };
}

String _linkKindRu(String value) =>
    const {
      'resource': 'Природный ресурс',
      'desert': 'Пустыня',
      'wonder': 'Достопримечательность',
      'landmark': 'Достопримечательность',
      'bridge': 'Мост',
      'scientist': 'Учёный',
      'food': 'Блюдо',
      'sports_team': 'Спортивная команда',
    }[value] ??
    'Связанная сущность';
String _linkKindEn(String value) =>
    const {
      'resource': 'Natural resource',
      'desert': 'Desert',
      'wonder': 'Wonder',
      'landmark': 'Landmark',
      'bridge': 'Bridge',
      'scientist': 'Scientist',
      'food': 'Food',
      'sports_team': 'Sports team',
    }[value] ??
    'Related entity';
(String, String) _religionGroup(String value) =>
    const {
      'Christians': ('христиане', 'Christians'),
      'Muslims': ('мусульмане', 'Muslims'),
      'Religiously_unaffiliated': (
        'религиозно неаффилированные',
        'Religiously unaffiliated',
      ),
      'Buddhists': ('буддисты', 'Buddhists'),
      'Hindus': ('индуисты', 'Hindus'),
      'Jews': ('иудеи', 'Jews'),
      'Folk_religions': ('народные религии', 'Folk religions'),
      'Other_religions': ('другие религии', 'Other religions'),
    }[value] ??
    ('религиозная группа', value.replaceAll('_', ' '));
(String, String) _localizedDate(
  int year, {
  int? endYear,
  bool approximate = false,
}) {
  String oneRu(int value) => value < 0 ? '${-value} до н. э.' : '$value';
  String oneEn(int value) => value < 0 ? '${-value} BCE' : '$value';
  final suffixRu = endYear == null ? '' : '–${oneRu(endYear)}';
  final suffixEn = endYear == null ? '' : '–${oneEn(endYear)}';
  return (
    '${approximate ? 'около ' : ''}${oneRu(year)}$suffixRu',
    '${approximate ? 'c. ' : ''}${oneEn(year)}$suffixEn',
  );
}

Map<String, FactSource> _sourceMap(Map<String, dynamic> data) {
  final raw = data['sources'];
  final result = <String, FactSource>{};
  Iterable<MapEntry<String, dynamic>> entries = raw is List
      ? raw.whereType<Map>().map((v) {
          final row = Map<String, dynamic>.from(v);
          return MapEntry(_textOr(row, 'id'), row);
        })
      : raw is Map
      ? Map<String, dynamic>.from(raw).entries
      : const [];
  for (final entry in entries) {
    final row = entry.value is Map
        ? Map<String, dynamic>.from(entry.value as Map)
        : const <String, dynamic>{};
    final url = _textOr(row, 'url');
    if (entry.key.isNotEmpty && _https(url)) {
      final title = _textOr(row, 'title').isEmpty
          ? entry.key
          : _textOr(row, 'title');
      result[entry.key] = FactSource(
        titleRu: _sourceTitleRu(title),
        titleEn: title,
        url: url,
      );
    }
  }
  return result;
}

List<FactSource> _refs(Map<String, FactSource> sourceMap, List<String> ids) =>
    ids.map((id) => sourceMap[id]).whereType<FactSource>().toList();
List<FactSource> _urlSource(String url, String ru, String en) =>
    _https(url) ? [FactSource(titleRu: ru, titleEn: en, url: url)] : const [];
String _sourceTitleRu(String title) {
  final localized = learningSourceTitle(title, russian: true);
  if (localized != 'Источник') return localized;
  final lower = title.toLowerCase();
  if (lower.contains('world factbook') || lower.contains('cia')) {
    return 'Всемирная книга фактов ЦРУ';
  }
  if (lower.contains('world bank')) {
    return 'Всемирный банк';
  }
  if (lower.contains('president') || lower.contains('government')) {
    return 'Официальный государственный портал';
  }
  if (lower.contains('google') && lower.contains('story')) {
    return 'Google: история компании';
  }
  if (lower.contains('country')) {
    return 'Справочник стран';
  }
  return 'Справочный источник';
}

bool _https(String value) {
  final uri = Uri.tryParse(value);
  return uri?.scheme == 'https' && uri?.host.isNotEmpty == true;
}
