/// Local country-atlas learning. It deliberately keeps volatile facts in a
/// source-labelled asset and creates no question for fields that are absent.
library;

import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'quizipedia.dart';

const _factsAsset = 'assets/quizipedia/country_facts.json';

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
  });
  final String id, nameEn, nameRu, capital, region;
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
  return '1 million km²+';
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
  });
  final String kind, prompt, answer;
  final CountryFact country;
  final List<String> options;
  final String source;
  final CountryAssociation? association;

  static List<CountryQuestion> associations(
    List<CountryFact> facts,
    Map<String, List<CountryAssociation>> associations, {
    String? kind,
  }) {
    final random = math.Random();
    final result = <CountryQuestion>[];
    for (final fact in facts) {
      final trueRows = (associations[fact.id] ?? const [])
          .where((row) => kind == null || row.kind == kind)
          .toList();
      for (final row in trueRows) {
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
        final options = [row.nameEn, ...(falseNames..shuffle(random)).take(3)]
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

  static String _associationPrompt(CountryAssociation row, String country) =>
      switch (row.kind) {
        'neighbor' => 'Which country shares a land border with $country?',
        'water' => 'Which major water body is listed for $country?',
        'president' => 'Who is the president of $country as of ${row.checked}?',
        'scientist' =>
          'Which scientist was born in the territory of modern $country?',
        'food' => 'Which culinary tradition is listed for $country?',
        'sports_team' => 'Which sports club is based in $country?',
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
        final options = [fact.nameEn, ...distractors.take(3)]..shuffle(random);
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
              [answer, ...alternatives.take(3)]..shuffle(random),
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
        final options = [entry.value, ...distractors.take(3)]..shuffle(random);
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
  final WidgetBuilder? locationTrainingBuilder;
  @override
  State<CountryAtlasPage> createState() => _CountryAtlasPageState();
}

class _CountryAtlasPageState extends State<CountryAtlasPage> {
  final _controller = TransformationController();
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
  Object? _loadError;
  final List<CountryQuestion> _missed = [];

  @override
  void initState() {
    super.initState();
    _load();
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
        ])
        .then((loaded) {
          final facts = loaded[0] as List<CountryFact>;
          final associations = <String, List<CountryAssociation>>{};
          for (final value
              in loaded.skip(1).cast<Map<String, List<CountryAssociation>>>()) {
            value.forEach(
              (id, rows) => associations.putIfAbsent(id, () => []).addAll(rows),
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
    super.dispose();
  }

  bool get _ru => Localizations.localeOf(context).languageCode == 'ru';
  String _t(String en, String ru) => _ru ? ru : en;
  String _display(String value) {
    if (!_ru) return value;
    final country = _facts.where((f) => f.nameEn == value).firstOrNull;
    if (country != null) return country.nameRu;
    final relation = _associations.values
        .expand((r) => r)
        .where((r) => r.nameEn == value)
        .firstOrNull;
    if (relation != null) return relation.nameRu;
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
    label: Text(label ?? _t('Source', 'Источник')),
  );
  CountryFact? get _fact => _facts.where((f) => f.id == _selected).firstOrNull;
  List<QuizipediaFeature> get _visible =>
      widget.catalog.countries.where((country) {
        final fact = _facts.where((f) => f.id == country.id).firstOrNull;
        return _region == 'All' || fact?.region == _region;
      }).toList();

  void _start({String? countryId, List<CountryQuestion>? retry}) {
    if (_topic == 'location' && widget.locationTrainingBuilder != null) {
      Navigator.of(context)
          .push(MaterialPageRoute(builder: widget.locationTrainingBuilder!));
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
    return Scaffold(
      appBar: AppBar(title: Text(_t('Country atlas', 'Атлас стран'))),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, box) => SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    key: const Key('map-country-search'),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      labelText: _t('Find a country', 'Найти страну'),
                    ),
                    onChanged: (value) => setState(() => _query = value),
                  ),
                ),
                if (_query.isNotEmpty)
                  SizedBox(
                    height: chipHeight,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: _facts
                          .where(
                            (fact) => (_ru ? fact.nameRu : fact.nameEn)
                                .toLowerCase()
                                .contains(_query.toLowerCase()),
                          )
                          .take(8)
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
                  ),
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
                                  setState(() => _region = region),
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
                      labelText: _t('Training topic', 'Тема тренировки'),
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
                      if (value != null) setState(() => _topic = value);
                    },
                  ),
                ),
                SizedBox(
                  height: math.max(260, math.min(600, box.maxHeight * .55)),
                  child: QuizipediaWorldMap(
                    features: _visible,
                    controller: _controller,
                    selected: _selected.isEmpty ? null : _selected,
                    highlighted: _focus.isEmpty ? null : _focus,
                    focusTarget: _focus.isEmpty ? null : _focus,
                    onSelect: (id) {
                      FocusManager.instance.primaryFocus?.unfocus();
                      setState(() {
                        _selected = id ?? '';
                        _focus = id ?? '';
                      });
                    },
                  ),
                ),
                _details(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _topicLabel(String topic) => switch (topic) {
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
    final name = question.country.nameRu;
    return switch (question.kind) {
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
      'resource' => 'Какой природный ресурс указан в справочнике страны $name?',
      'desert' => 'Какая пустыня расположена на территории страны $name?',
      'bridge' => 'Какой мост находится в стране $name?',
      'wonder' => 'Какое чудо света находится в стране $name?',
      'landmark' => 'Какая достопримечательность находится в стране $name?',
      _ => 'Что связано со страной $name?',
    };
  }

  Widget _details() {
    final fact = _fact;
    if (fact == null) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: FilledButton.icon(
          onPressed: _start,
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
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .34,
      ),
      width: double.infinity,
      padding: const EdgeInsetsDirectional.fromSTEB(12, 12, 72, 16),
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: Theme.of(context).textTheme.titleLarge),
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
              if (fact.sourceLanguages.isNotEmpty)
                Text(
                  field(
                    _t('Languages in source', 'Языки в источнике'),
                    fact.sourceLanguages.map(_display).join(', '),
                  ),
                ),
              if (fact.currencies.isNotEmpty)
                Text(
                  field(_t('Currency', 'Валюта'), fact.currencies.join(', ')),
                ),
              if (fact.population > 0)
                Text(
                  field(
                    _t('Population (approximate)', 'Население (примерно)'),
                    '${_display(populationBand(fact.population))} · ${fact.populationYear} · World Bank',
                  ),
                ),
              if (fact.areaKm2 != null)
                Text(
                  field(_t('Area', 'Площадь'), '${fact.areaKm2!.round()} km²'),
                ),
              Text(field(_t('Region', 'Регион'), _display(fact.region))),
              if (feature == null)
                Text(
                  _t(
                    'No outline in this map; country facts are available.',
                    'Контура на этой карте нет; факты и тренировки доступны.',
                  ),
                ),
              for (final kind
                  in (_associations[fact.id] ?? const [])
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
                          '${_ru ? row.relationRu : row.relationEn}${row.checked.isEmpty ? '' : ' · ${row.checked}'}',
                        ),
                        trailing: row.sourceUrl.isEmpty
                            ? null
                            : _sourceLink(row.sourceUrl),
                        onTap: row.kind == 'neighbor'
                            ? () => setState(() {
                                _selected = row.id;
                                _focus = row.id;
                                _query = '';
                              })
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
                    onPressed: () => _start(countryId: fact.id),
                    child: Text(
                      _t('Train this country', 'Тренировать эту страну'),
                    ),
                  ),
                  TextButton(
                    onPressed: _start,
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
              ...q.options.map(
                (option) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: OutlinedButton(
                    onPressed: _checked
                        ? null
                        : () => setState(() => _choice = option),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: _choice == option
                          ? Theme.of(context).colorScheme.secondaryContainer
                          : null,
                    ),
                    child: Text(_display(option)),
                  ),
                ),
              ),
              if (_checked)
                Container(
                  key: const Key('quizipedia-feedback'),
                  padding: const EdgeInsets.all(12),
                  color: _choice == q.answer
                      ? Theme.of(context).colorScheme.secondaryContainer
                      : Theme.of(context).colorScheme.errorContainer,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _choice == q.answer
                            ? _t('Correct', 'Верно')
                            : _t(
                                'Not quite. Review the country card.',
                                'Не совсем. Посмотрите карточку страны.',
                              ),
                      ),
                      Text(
                        '${_t('Correct answer', 'Правильный ответ')}: ${_display(q.answer)}',
                      ),
                      if (q.association != null)
                        Text(
                          _ru
                              ? q.association!.relationRu
                              : q.association!.relationEn,
                        ),
                      if (q.association?.sourceUrl.isNotEmpty ?? false)
                        _sourceLink(q.association!.sourceUrl),
                      if (q.kind == 'population')
                        _sourceLink(
                          'https://data.worldbank.org/indicator/SP.POP.TOTL',
                          'World Bank · ${q.country.populationYear}',
                        ),
                      if (q.source.isNotEmpty)
                        Text(
                          '${_t('Checked', 'Проверено')}: ${q.source}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _choice == null
                    ? null
                    : () => setState(() {
                        if (_checked) {
                          _index++;
                          _choice = null;
                          _checked = false;
                        } else {
                          _checked = true;
                          if (_choice == q.answer) {
                            _score++;
                          } else {
                            _missed.add(q);
                          }
                        }
                      }),
                child: Text(
                  _checked ? _t('Next', 'Далее') : _t('Check', 'Проверить'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
