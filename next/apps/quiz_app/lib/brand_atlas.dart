/// A small source-linked, local brand reference and practice screen.
library;

import 'fact_practice.dart';
import 'atlas_media.dart';

import 'russian_learning_text.dart';

import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

const _brandAsset = 'assets/quizipedia/brands.json';

String _brandRequired(Map<String, dynamic> row, String key) {
  final value = row[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('$key required');
  }
  return value.trim();
}

List<Map<String, dynamic>> _brandRows(Object? value, String label) {
  if (value is! List) throw FormatException('$label list required');
  return value
      .map((item) {
        if (item is! Map) throw FormatException('$label row');
        return Map<String, dynamic>.from(item);
      })
      .toList(growable: false);
}

List<String> _brandIds(Object? value, String label) {
  if (value is! List || value.any((item) => item is! String || item.isEmpty)) {
    throw FormatException('$label ids');
  }
  return List.unmodifiable(value.cast<String>());
}

void _checkDate(String value, String label) {
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
    throw FormatException('$label date');
  }
  final parts = value.split('-').map(int.parse).toList(growable: false);
  final parsed = DateTime.tryParse(value);
  if (parsed == null ||
      parsed.year != parts[0] ||
      parsed.month != parts[1] ||
      parsed.day != parts[2]) {
    throw FormatException('$label date');
  }
}

class BrandSource {
  const BrandSource({
    required this.id,
    required this.title,
    required this.url,
    required this.checkedOn,
  });
  final String id, title, url, checkedOn;
  factory BrandSource.fromJson(Map<String, dynamic> row) {
    final url = _brandRequired(row, 'url');
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      throw const FormatException('source url');
    }
    final checkedOn = _brandRequired(row, 'checked_on');
    _checkDate(checkedOn, 'source');
    return BrandSource(
      id: _brandRequired(row, 'id'),
      title: _brandRequired(row, 'title'),
      url: url,
      checkedOn: checkedOn,
    );
  }
}

class BrandOwner {
  const BrandOwner({
    required this.id,
    required this.name,
    required this.descriptionRu,
    required this.descriptionEn,
    required this.sourceIds,
  });
  final String id, name, descriptionRu, descriptionEn;
  final List<String> sourceIds;
  factory BrandOwner.fromJson(Map<String, dynamic> row) => BrandOwner(
    id: _brandRequired(row, 'id'),
    name: _brandRequired(row, 'name'),
    descriptionRu: _brandRequired(row, 'description_ru'),
    descriptionEn: _brandRequired(row, 'description_en'),
    sourceIds: _brandIds(row['source_ids'], 'owner source'),
  );
}

class BrandFormerName {
  const BrandFormerName({
    required this.name,
    required this.fromYear,
    required this.toYear,
    required this.noteRu,
    required this.noteEn,
    required this.sourceIds,
    required this.quizEnabled,
  });
  final String name, noteRu, noteEn;
  final int? fromYear, toYear;
  final List<String> sourceIds;
  final bool quizEnabled;
  factory BrandFormerName.fromJson(Map<String, dynamic> row) {
    final from = row['from_year'];
    final to = row['to_year'];
    if (from != null && from is! int || to != null && to is! int) {
      throw const FormatException('former name year');
    }
    if (from is int && to is int && to < from) {
      throw const FormatException('former name order');
    }
    final quizEnabled = row['quiz_enabled'] ?? true;
    if (quizEnabled is! bool) {
      throw const FormatException('former name quiz flag');
    }
    return BrandFormerName(
      name: _brandRequired(row, 'name'),
      fromYear: from as int?,
      toYear: to as int?,
      noteRu: _brandRequired(row, 'note_ru'),
      noteEn: _brandRequired(row, 'note_en'),
      sourceIds: _brandIds(row['source_ids'], 'former name source'),
      quizEnabled: quizEnabled,
    );
  }
}

class BrandFact {
  const BrandFact({
    required this.textRu,
    required this.textEn,
    required this.sourceIds,
  });
  final String textRu, textEn;
  final List<String> sourceIds;
  factory BrandFact.fromJson(Map<String, dynamic> row) => BrandFact(
    textRu: _brandRequired(row, 'text_ru'),
    textEn: _brandRequired(row, 'text_en'),
    sourceIds: _brandIds(row['source_ids'], 'fact source'),
  );
}

class BrandLogoMoment {
  const BrandLogoMoment({
    required this.year,
    required this.textRu,
    required this.textEn,
    required this.sourceIds,
  });
  final int? year;
  final String textRu, textEn;
  final List<String> sourceIds;
  factory BrandLogoMoment.fromJson(Map<String, dynamic> row) {
    final year = row['year'];
    if (year != null && year is! int) throw const FormatException('logo year');
    return BrandLogoMoment(
      year: year as int?,
      textRu: _brandRequired(row, 'text_ru'),
      textEn: _brandRequired(row, 'text_en'),
      sourceIds: _brandIds(row['source_ids'], 'logo source'),
    );
  }
}

class Brand {
  const Brand({
    required this.id,
    required this.name,
    required this.sectorRu,
    required this.sectorEn,
    required this.countryRu,
    required this.countryEn,
    required this.foundedYear,
    required this.dateScope,
    required this.dateNoteRu,
    required this.dateNoteEn,
    required this.ownerId,
    required this.ownershipNoteRu,
    required this.ownershipNoteEn,
    required this.ownershipCheckedOn,
    required this.founders,
    required this.formerNames,
    required this.facts,
    required this.logoHistory,
    required this.sourceIds,
  });
  final String id, name, sectorRu, sectorEn, countryRu, countryEn;
  final int? foundedYear;
  final String dateScope;
  final String dateNoteRu,
      dateNoteEn,
      ownerId,
      ownershipNoteRu,
      ownershipNoteEn;
  final String ownershipCheckedOn;
  final List<String> founders, sourceIds;
  final List<BrandFormerName> formerNames;
  final List<BrandFact> facts;
  final List<BrandLogoMoment> logoHistory;
  factory Brand.fromJson(Map<String, dynamic> row) {
    final founded = row['founded_year'];
    if (founded != null && founded is! int) {
      throw const FormatException('brand founded year');
    }
    final ownershipChecked = _brandRequired(row, 'ownership_checked_on');
    _checkDate(ownershipChecked, 'ownership');
    final dateScope = row['date_scope'] ?? 'company';
    const validScopes = {
      'company',
      'brand',
      'product',
      'service',
      'predecessor',
      'rename',
      'first_store',
      'first_restaurant',
      'first_franchise',
    };
    if (dateScope is! String || !validScopes.contains(dateScope)) {
      throw const FormatException('brand date scope');
    }
    return Brand(
      id: _brandRequired(row, 'id'),
      name: _brandRequired(row, 'name'),
      sectorRu: _brandRequired(row, 'sector_ru'),
      sectorEn: _brandRequired(row, 'sector_en'),
      countryRu: _brandRequired(row, 'country_ru'),
      countryEn: _brandRequired(row, 'country_en'),
      foundedYear: founded as int?,
      dateScope: dateScope,
      dateNoteRu: _brandRequired(row, 'date_note_ru'),
      dateNoteEn: _brandRequired(row, 'date_note_en'),
      ownerId: _brandRequired(row, 'owner_id'),
      ownershipNoteRu: _brandRequired(row, 'ownership_note_ru'),
      ownershipNoteEn: _brandRequired(row, 'ownership_note_en'),
      ownershipCheckedOn: ownershipChecked,
      founders: _brandIds(row['founders'], 'founder'),
      formerNames: _brandRows(
        row['former_names'],
        'former names',
      ).map(BrandFormerName.fromJson).toList(growable: false),
      facts: _brandRows(
        row['facts'],
        'facts',
      ).map(BrandFact.fromJson).toList(growable: false),
      logoHistory: _brandRows(
        row['logo_history'],
        'logo history',
      ).map(BrandLogoMoment.fromJson).toList(growable: false),
      sourceIds: _brandIds(row['source_ids'], 'brand source'),
    );
  }
}

enum BrandQuestionKind { owner, foundation, formerName, founder, logo }

String _datePromptRu(String scope) => switch (scope) {
  'brand' => 'Какой год появления бренда',
  'product' => 'Какой год первого выпуска продукта',
  'service' => 'Какой год запуска сервиса',
  'predecessor' => 'Какой год основания предшественника',
  'rename' => 'Какой год появления этого названия',
  'first_store' => 'Какой год открытия первого магазина',
  'first_restaurant' => 'Какой год открытия первого ресторана',
  'first_franchise' => 'Какой год первой франшизы',
  _ => 'Какой год основания компании',
};

String _datePromptEn(String scope) => switch (scope) {
  'brand' => 'Which brand-launch year',
  'product' => 'Which first-product-release year',
  'service' => 'Which service-launch year',
  'predecessor' => 'Which predecessor-foundation year',
  'rename' => 'Which year this name appeared',
  'first_store' => 'Which first-store opening year',
  'first_restaurant' => 'Which first-restaurant opening year',
  'first_franchise' => 'Which first-franchise year',
  _ => 'Which company-foundation year',
};

class BrandQuestion {
  const BrandQuestion({
    required this.kind,
    required this.promptRu,
    required this.promptEn,
    required this.answer,
    required this.options,
    required this.explanationRu,
    required this.explanationEn,
    required this.sourceIds,
  });
  final BrandQuestionKind kind;
  final String promptRu, promptEn, answer, explanationRu, explanationEn;
  final List<String> options, sourceIds;
}

class BrandAtlas {
  const BrandAtlas({
    required this.coverageNoteRu,
    required this.coverageNoteEn,
    required this.sources,
    required this.owners,
    required this.brands,
  });
  final String coverageNoteRu, coverageNoteEn;
  final List<BrandSource> sources;
  final List<BrandOwner> owners;
  final List<Brand> brands;

  factory BrandAtlas.fromJson(Map<String, dynamic> json) {
    if (json['schema_version'] != 'qm-brand-atlas/v1') {
      throw const FormatException('brand atlas schema');
    }
    final sources = _brandRows(
      json['sources'],
      'sources',
    ).map(BrandSource.fromJson).toList();
    final owners = _brandRows(
      json['owners'],
      'owners',
    ).map(BrandOwner.fromJson).toList();
    final brands = _brandRows(
      json['brands'],
      'brands',
    ).map(Brand.fromJson).toList()..sort((a, b) => a.name.compareTo(b.name));
    void unique(Iterable<String> values, String label) {
      if (values.toSet().length != values.length) {
        throw FormatException('duplicate $label');
      }
    }

    unique(sources.map((item) => item.id), 'source');
    unique(owners.map((item) => item.id), 'owner');
    unique(brands.map((item) => item.id), 'brand');
    final sourceIds = sources.map((item) => item.id).toSet();
    final ownerIds = owners.map((item) => item.id).toSet();
    bool referenced(Iterable<String> values) =>
        values.isNotEmpty && values.every(sourceIds.contains);
    if (!owners.every((item) => referenced(item.sourceIds))) {
      throw const FormatException('owner source relation');
    }
    for (final brand in brands) {
      if (!ownerIds.contains(brand.ownerId) || !referenced(brand.sourceIds)) {
        throw const FormatException('brand relation');
      }
      if (!brand.formerNames.every((item) => referenced(item.sourceIds)) ||
          !brand.facts.every((item) => referenced(item.sourceIds)) ||
          !brand.logoHistory.every((item) => referenced(item.sourceIds))) {
        throw const FormatException('brand claim source relation');
      }
    }
    return BrandAtlas(
      coverageNoteRu: _brandRequired(json, 'coverage_note_ru'),
      coverageNoteEn: _brandRequired(json, 'coverage_note_en'),
      sources: List.unmodifiable(sources),
      owners: List.unmodifiable(owners),
      brands: List.unmodifiable(brands),
    );
  }

  BrandOwner ownerFor(Brand brand) =>
      owners.firstWhere((item) => item.id == brand.ownerId);
  BrandSource sourceFor(String id) =>
      sources.firstWhere((item) => item.id == id);

  List<BrandQuestion> questionsFor({int seed = 0}) {
    final result = <BrandQuestion>[];
    List<String>? choices(String answer, Iterable<String> candidates) {
      final others = candidates.where((item) => item != answer).toSet().toList()
        ..sort();
      final count = brands.length >= 6 ? 5 : 3;
      if (others.length < count) return null;
      return [answer, ...others.take(count)];
    }

    for (final brand in brands) {
      final owner = ownerFor(brand);
      final ownerOptions = choices(owner.name, owners.map((item) => item.name));
      if (ownerOptions != null) {
        result.add(
          BrandQuestion(
            kind: BrandQuestionKind.owner,
            promptRu:
                'Какая компания или группа указана владельцем бренда «${brand.name}» на ${brand.ownershipCheckedOn}?',
            promptEn:
                'Which company or group is listed as the owner of “${brand.name}” as of ${brand.ownershipCheckedOn}?',
            answer: owner.name,
            options: ownerOptions,
            explanationRu: '${owner.name}. ${brand.ownershipNoteRu}',
            explanationEn: '${owner.name}. ${brand.ownershipNoteEn}',
            sourceIds: brand.sourceIds,
          ),
        );
      }
      if (brand.foundedYear != null) {
        final answer = '${brand.foundedYear}';
        final options = choices(
          answer,
          brands
              .where((item) => item.foundedYear != null)
              .map((item) => '${item.foundedYear}'),
        );
        if (options != null) {
          result.add(
            BrandQuestion(
              kind: BrandQuestionKind.foundation,
              promptRu:
                  '${_datePromptRu(brand.dateScope)} указан в этом справочнике для «${brand.name}»?',
              promptEn:
                  '${_datePromptEn(brand.dateScope)} is recorded by this reference for “${brand.name}”?',
              answer: answer,
              options: options,
              explanationRu: '$answer. ${brand.dateNoteRu}',
              explanationEn: '$answer. ${brand.dateNoteEn}',
              sourceIds: brand.sourceIds,
            ),
          );
        }
      }
      for (final former in brand.formerNames.where(
        (item) => item.quizEnabled,
      )) {
        final options = choices(
          brand.name,
          brands
              .where((item) => item.id != brand.id)
              .where(
                (item) =>
                    !item.formerNames.any((name) => name.name == former.name),
              )
              .map((item) => item.name),
        );
        if (options != null) {
          result.add(
            BrandQuestion(
              kind: BrandQuestionKind.formerName,
              promptRu:
                  'С каким брендом в справочнике связано историческое название «${former.name}»?',
              promptEn:
                  'Which brand is linked to the historical name “${former.name}” in this reference?',
              answer: brand.name,
              options: options,
              explanationRu: '${brand.name}: ${former.noteRu}',
              explanationEn: '${brand.name}: ${former.noteEn}',
              sourceIds: former.sourceIds,
            ),
          );
        }
      }
      for (final founder in brand.founders) {
        final candidates = brands
            .expand((item) => item.founders)
            .where((item) => !brand.founders.contains(item));
        final options = choices(founder, candidates);
        if (options != null) {
          result.add(
            BrandQuestion(
              kind: BrandQuestionKind.founder,
              promptRu: 'Кто указан основателем бренда «${brand.name}»?',
              promptEn: 'Who is listed as a founder of “${brand.name}”?',
              answer: founder,
              options: options,
              explanationRu:
                  '$founder указан среди основателей «${brand.name}».',
              explanationEn:
                  '$founder is listed among the founders of “${brand.name}”.',
              sourceIds: brand.sourceIds,
            ),
          );
        }
      }
      for (final moment in brand.logoHistory.where(
        (item) =>
            item.year != null &&
            !RegExp('\\b${item.year}\\b')
                .hasMatch('${item.textRu} ${item.textEn}'),
      )) {
        final answer = '${moment.year}';
        final options = choices(
          answer,
          brands
              .expand((item) => item.logoHistory)
              .where((item) => item.year != null)
              .map((item) => '${item.year}'),
        );
        if (options != null) {
          result.add(
            BrandQuestion(
              kind: BrandQuestionKind.logo,
              promptRu:
                  'В каком году относится запись об истории знака «${brand.name}»: ${moment.textRu}?',
              promptEn:
                  'What year is attached to this “${brand.name}” logo-history entry: ${moment.textEn}?',
              answer: answer,
              options: options,
              explanationRu: '$answer. ${moment.textRu}',
              explanationEn: '$answer. ${moment.textEn}',
              sourceIds: moment.sourceIds,
            ),
          );
        }
      }
    }
    final shuffled = result
        .map(
          (item) => BrandQuestion(
            kind: item.kind,
            promptRu: item.promptRu,
            promptEn: item.promptEn,
            answer: item.answer,
            options: List<String>.from(item.options)
              ..shuffle(Random(seed ^ item.promptEn.hashCode)),
            explanationRu: item.explanationRu,
            explanationEn: item.explanationEn,
            sourceIds: item.sourceIds,
          ),
        )
        .toList(growable: false);
    shuffled.shuffle(Random(seed));
    return List.unmodifiable(shuffled);
  }

  List<BrandQuestion> get questions => questionsFor();
}

Future<BrandAtlas> loadBrandAtlas([AssetBundle? bundle]) async {
  final raw = await (bundle ?? rootBundle).loadString(_brandAsset);
  return BrandAtlas.fromJson(Map<String, dynamic>.from(jsonDecode(raw) as Map));
}

class BrandAtlasPage extends StatefulWidget {
  const BrandAtlasPage({super.key, this.bundle});
  final AssetBundle? bundle;
  @override
  State<BrandAtlasPage> createState() => _BrandAtlasPageState();
}

class _BrandAtlasPageState extends State<BrandAtlasPage> {
  late Future<BrandAtlas> _future = loadBrandAtlas(widget.bundle);
  final _scroll = ScrollController();
  final _practiceScroll = ScrollController();
  String _query = '', _sort = 'name';
  bool _ascending = true, _practice = false;
  String? _sector, _selectedBrand, _selectedOwner, _chosen;
  BrandQuestionKind? _topic;
  int _question = 0, _correct = 0;
  final List<BrandQuestion> _missed = [],
      _retryQuestions = [],
      _roundQuestions = [];
  bool _checked = false, _retrying = false, _finished = false;

  bool get _ru => Localizations.localeOf(context).languageCode == 'ru';
  String _t(String en, String ru) => _ru ? ru : en;
  String _sectorName(Brand brand) => _ru ? brand.sectorRu : brand.sectorEn;
  String _country(Brand brand) => _ru ? brand.countryRu : brand.countryEn;
  String _claim(String ru, String en) => _ru ? russianLearningText(ru) : en;
  String _factClaim(String ru, String en) =>
      _ru ? russianLearningText(ru.replaceAll('AWS', 'Эй-дабл-ю-эс')) : en;
  String _displayName(String value) => _ru ? russianLearningText(value) : value;
  String _topicName(BrandQuestionKind? value) => switch (value) {
    null => _t('Mixed topics', 'Все темы'),
    BrandQuestionKind.owner => _t('Owners', 'Владельцы'),
    BrandQuestionKind.foundation => _t('Foundation', 'Основание'),
    BrandQuestionKind.formerName => _t('Former names', 'Прежние названия'),
    BrandQuestionKind.founder => _t('Founders', 'Основатели'),
    BrandQuestionKind.logo => _t('Logo history', 'История знака'),
  };

  @override
  void dispose() {
    _scroll.dispose();
    _practiceScroll.dispose();
    super.dispose();
  }

  void _showBrand(String id) {
    setState(() {
      _selectedBrand = id;
      _selectedOwner = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          0,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showOwner(String id) {
    setState(() {
      _selectedOwner = id;
      _selectedBrand = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          0,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _practiceTop() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (_practiceScroll.hasClients) {
      _practiceScroll.animateTo(
        0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
      );
    }
  });

  void _practiceBottom() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (_practiceScroll.hasClients) {
      _practiceScroll.animateTo(
        _practiceScroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
      );
    }
  });

  @override
  Widget build(BuildContext context) => FutureBuilder<BrandAtlas>(
    future: _future,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Scaffold(
          appBar: AppBar(
            title: Text(_t('Brand atlas', 'Атлас брендов')),
            actions: [
              FactPracticeAction(scope: 'brands', bundle: widget.bundle),
            ],
          ),
          body: Center(
            child: FilledButton.icon(
              key: const Key('brand-retry'),
              onPressed: () =>
                  setState(() => _future = loadBrandAtlas(widget.bundle)),
              icon: const Icon(Icons.refresh),
              label: Text(_t('Retry', 'Повторить')),
            ),
          ),
        );
      }
      if (!snapshot.hasData) {
        return Scaffold(
          appBar: AppBar(
            title: Text(_t('Brand atlas', 'Атлас брендов')),
            actions: [
              FactPracticeAction(scope: 'brands', bundle: widget.bundle),
            ],
          ),
          body: const Center(child: CircularProgressIndicator()),
        );
      }
      final atlas = snapshot.data!;
      return Scaffold(
        appBar: AppBar(
          title: Text(_t('Brand atlas', 'Атлас брендов')),
          actions: [FactPracticeAction(scope: 'brands', bundle: widget.bundle)],
        ),
        body: _practice ? _practiceView(atlas) : _explorer(atlas),
      );
    },
  );

  Widget _explorer(BrandAtlas atlas) {
    final sectors = atlas.brands.map(_sectorName).toSet().toList()..sort();
    final matches = atlas.brands.where((brand) {
      final haystack =
          '${brand.name} ${brand.sectorRu} ${brand.sectorEn} ${brand.countryRu} ${brand.countryEn} ${brand.founders.join(' ')} ${brand.formerNames.map((item) => item.name).join(' ')} ${atlas.ownerFor(brand).name} ${_displayName(brand.name)} ${_displayName(atlas.ownerFor(brand).name)} ${brand.formerNames.map((item) => _displayName(item.name)).join(' ')}'
              .toLowerCase();
      return (_sector == null || _sector == _sectorName(brand)) &&
          haystack.contains(_query.toLowerCase());
    }).toList();
    matches.sort((a, b) {
      if (_sort == 'year') {
        return _ascending
            ? _compareYears(a.foundedYear, b.foundedYear)
            : _compareYears(b.foundedYear, a.foundedYear);
      }
      final value = _displayName(a.name).compareTo(_displayName(b.name));
      return _ascending ? value : -value;
    });
    final selected = atlas.brands
        .where((item) => item.id == _selectedBrand)
        .firstOrNull;
    final owner = atlas.owners
        .where((item) => item.id == _selectedOwner)
        .firstOrNull;
    return SafeArea(
      child: ListView(
        controller: _scroll,
        key: const Key('brand-scroll'),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 32),
        children: [
          Text(
            _t(
              'Source-linked reference · local unranked practice',
              'Справочник с источниками · локальная тренировка без рейтинга',
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Text(
            atlas.coverageNoteRu.isEmpty
                ? atlas.coverageNoteEn
                : _claim(atlas.coverageNoteRu, atlas.coverageNoteEn),
          ),
          const SizedBox(height: 12),
          if (owner != null) _ownerCard(atlas, owner),
          if (selected != null) _brandCard(atlas, selected),
          TextField(
            key: const Key('brand-search'),
            onChanged: (value) => setState(() => _query = value.trim()),
            decoration: InputDecoration(
              labelText: _t(
                'Find a brand, group, founder or former name',
                'Найти бренд, группу, основателя или старое название',
              ),
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ChoiceChip(
                label: Text(_t('All sectors', 'Все отрасли')),
                selected: _sector == null,
                onSelected: (_) => setState(() => _sector = null),
              ),
              ...sectors.map(
                (value) => ChoiceChip(
                  label: Text(value),
                  selected: _sector == value,
                  onSelected: (_) => setState(() => _sector = value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              PopupMenuButton<String>(
                tooltip: _t('Sort', 'Сортировка'),
                initialValue: _sort,
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'name',
                    child: Text(_t('Name', 'Название')),
                  ),
                  PopupMenuItem(
                    value: 'year',
                    child: Text(_t('Founded', 'Год основания')),
                  ),
                ],
                onSelected: (value) => setState(() => _sort = value),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          _sort == 'name'
                              ? _t('Name', 'Название')
                              : _t('Founded', 'Год основания'),
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => setState(() => _ascending = !_ascending),
                icon: Icon(
                  _ascending ? Icons.arrow_upward : Icons.arrow_downward,
                ),
                label: Text(_t('Order', 'Порядок')),
              ),
              PopupMenuButton<String>(
                tooltip: _t('Training topic', 'Тема тренировки'),
                initialValue: _topic?.name ?? 'all',
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'all', child: Text(_topicName(null))),
                  ...BrandQuestionKind.values.map(
                    (item) => PopupMenuItem(
                      value: item.name,
                      child: Text(_topicName(item)),
                    ),
                  ),
                ],
                onSelected: (value) => setState(
                  () => _topic = value == 'all'
                      ? null
                      : BrandQuestionKind.values.byName(value),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(child: Text(_topicName(_topic))),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
              FilledButton.icon(
                key: const Key('brand-train'),
                onPressed:
                    atlas.questions
                        .where((item) => _topic == null || item.kind == _topic)
                        .isEmpty
                    ? null
                    : () => setState(() {
                        final seed = DateTime.now().microsecondsSinceEpoch;
                        _roundQuestions
                          ..clear()
                          ..addAll(
                            atlas
                                .questionsFor(seed: seed)
                                .where(
                                  (item) =>
                                      _topic == null || item.kind == _topic,
                                )
                                .take(10),
                          );
                        _practice = true;
                        _question = 0;
                        _correct = 0;
                        _chosen = null;
                        _checked = false;
                        _retrying = false;
                        _finished = false;
                        _missed.clear();
                        _retryQuestions.clear();
                      }),
                icon: const Icon(Icons.play_arrow),
                label: Text(_t('Practice', 'Тренировка')),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _t('${matches.length} brands', '${matches.length} брендов'),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          ...matches.map(
            (brand) => Card(
              child: ListTile(
                key: Key('brand-${brand.id}'),
                leading: AtlasMedia(
                  scope: 'brands',
                  entityId: brand.id,
                  compact: true,
                ),
                title: Text(_displayName(brand.name)),
                subtitle: Text(
                  '${_displayName(atlas.ownerFor(brand).name)}\n${_sectorName(brand)} · ${_country(brand)}${brand.foundedYear == null ? '' : ' · ${brand.foundedYear}'}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showBrand(brand.id),
              ),
            ),
          ),
          if (matches.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(_t('No matching brands', 'Бренды не найдены')),
            ),
        ],
      ),
    );
  }

  int _compareYears(int? left, int? right) {
    if (left == null && right == null) return 0;
    if (left == null) return 1;
    if (right == null) return -1;
    return left.compareTo(right);
  }

  Widget _brandCard(BrandAtlas atlas, Brand brand) {
    final owner = atlas.ownerFor(brand);
    return Card(
      key: const Key('brand-detail'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AtlasMedia(scope: 'brands', entityId: brand.id),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _displayName(brand.name),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                IconButton(
                  tooltip: _t('Close', 'Закрыть'),
                  onPressed: () => setState(() => _selectedBrand = null),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            Text('${_sectorName(brand)} · ${_country(brand)}'),
            const SizedBox(height: 8),
            Text(
              '${_t('Founded', 'Основан')}: ${brand.foundedYear?.toString() ?? _t('Unknown year', 'Год не указан')}. ${_claim(brand.dateNoteRu, brand.dateNoteEn)}',
            ),
            if (brand.founders.isNotEmpty)
              Text(
                '${_t('Founders', 'Основатели')}: ${brand.founders.join(', ')}',
              ),
            const SizedBox(height: 8),
            Text(
              '${_t('Owner', 'Владелец')}: ${_displayName(owner.name)}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Text(_claim(brand.ownershipNoteRu, brand.ownershipNoteEn)),
            Text(
              '${_t('Checked', 'Проверено')}: ${brand.ownershipCheckedOn}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            TextButton(
              onPressed: () => _showOwner(owner.id),
              child: Text(_t('Open owner card', 'Открыть карточку владельца')),
            ),
            if (brand.formerNames.isNotEmpty)
              _sourcedSection(
                atlas,
                _t(
                  'Former names and predecessors',
                  'Прежние названия и предшественники',
                ),
                brand.formerNames.map(
                  (item) => _SourcedText(
                    _claim(
                      '${item.name}${_yearRange(item.fromYear, item.toYear)}. ${item.noteRu}',
                      '${item.name}${_yearRange(item.fromYear, item.toYear)}. ${item.noteEn}',
                    ),
                    item.sourceIds,
                  ),
                ),
              ),
            if (brand.facts.isNotEmpty)
              _sourcedSection(
                atlas,
                _t('Facts', 'Факты'),
                brand.facts.map(
                  (item) => _SourcedText(
                    _factClaim(item.textRu, item.textEn),
                    item.sourceIds,
                  ),
                ),
              ),
            if (brand.logoHistory.isNotEmpty)
              _sourcedSection(
                atlas,
                _t('Logo history', 'История знака'),
                brand.logoHistory.map(
                  (item) => _SourcedText(
                    _claim(
                      '${item.year == null ? '' : '${item.year}: '}${item.textRu}',
                      '${item.year == null ? '' : '${item.year}: '}${item.textEn}',
                    ),
                    item.sourceIds,
                  ),
                ),
              ),
            _sourceButtons(atlas, brand.sourceIds),
          ],
        ),
      ),
    );
  }

  String _yearRange(int? start, int? end) =>
      start == null && end == null ? '' : ' (${start ?? '?'}–${end ?? '…'})';
  Widget _sourcedSection(
    BrandAtlas atlas,
    String title,
    Iterable<_SourcedText> rows,
  ) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        ...rows.map(
          (item) => Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ${item.text}'),
                _sourceButtons(atlas, item.sourceIds),
              ],
            ),
          ),
        ),
      ],
    ),
  );
  Widget _ownerCard(BrandAtlas atlas, BrandOwner owner) {
    final owned = atlas.brands
        .where((item) => item.ownerId == owner.id)
        .toList();
    return Card(
      key: const Key('brand-owner-detail'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _displayName(owner.name),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                IconButton(
                  tooltip: _t('Close', 'Закрыть'),
                  onPressed: () => setState(() => _selectedOwner = null),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            Text(_claim(owner.descriptionRu, owner.descriptionEn)),
            const SizedBox(height: 8),
            Text(
              _t(
                'Brands in this learning set',
                'Бренды в этой учебной подборке',
              ),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: owned
                  .map(
                    (brand) => ActionChip(
                      label: Text(_displayName(brand.name)),
                      onPressed: () => _showBrand(brand.id),
                    ),
                  )
                  .toList(),
            ),
            _sourceButtons(atlas, owner.sourceIds),
          ],
        ),
      ),
    );
  }

  Widget _sourceButtons(BrandAtlas atlas, List<String> ids) => Wrap(
    spacing: 6,
    children: ids.map((id) {
      final source = atlas.sourceFor(id);
      return TextButton.icon(
        onPressed: () => _open(source.url),
        icon: const Icon(Icons.open_in_new, size: 16),
        label: Text(learningSourceTitle(source.title, russian: _ru)),
      );
    }).toList(),
  );
  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null ||
        !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _t('Could not open source', 'Не удалось открыть источник'),
            ),
          ),
        );
      }
    }
  }

  List<_BrandOptionDetail> _optionDetails(
    BrandAtlas atlas,
    BrandQuestion question,
    String option,
  ) {
    List<_BrandOptionDetail> fallback() => [
      _BrandOptionDetail(
        question.explanationRu,
        question.explanationEn,
        question.sourceIds,
      ),
    ];
    switch (question.kind) {
      case BrandQuestionKind.owner:
        final owners = atlas.owners.where((owner) => owner.name == option);
        final details = owners
            .map(
              (owner) => _BrandOptionDetail(
                owner.descriptionRu,
                owner.descriptionEn,
                owner.sourceIds,
              ),
            )
            .toList(growable: false);
        return details.isEmpty ? fallback() : details;
      case BrandQuestionKind.foundation:
        final brands = atlas.brands.where(
          (brand) => '${brand.foundedYear}' == option,
        );
        final details = brands
            .map(
              (brand) => _BrandOptionDetail(
                '«${brand.name}»: ${_datePromptRu(brand.dateScope)} — $option. ${brand.dateNoteRu}',
                '“${brand.name}”: ${_datePromptEn(brand.dateScope)} — $option. ${brand.dateNoteEn}',
                brand.sourceIds,
              ),
            )
            .toList(growable: false);
        return details.isEmpty ? fallback() : details;
      case BrandQuestionKind.formerName:
        final brands = atlas.brands.where((brand) => brand.name == option);
        final details = brands
            .expand(
              (brand) => [
                _BrandOptionDetail(
                  '«${brand.name}»: ${brand.ownershipNoteRu}',
                  '“${brand.name}”: ${brand.ownershipNoteEn}',
                  brand.sourceIds,
                ),
                ...brand.facts.map(
                  (fact) => _BrandOptionDetail.fact(
                    fact.textRu,
                    fact.textEn,
                    fact.sourceIds,
                  ),
                ),
              ],
            )
            .toList(growable: false);
        return details.isEmpty ? fallback() : details;
      case BrandQuestionKind.founder:
        final brands = atlas.brands.where(
          (brand) => brand.founders.contains(option),
        );
        final details = brands
            .expand(
              (brand) => [
                _BrandOptionDetail(
                  '«${brand.name}»: $option указан среди основателей.',
                  '“${brand.name}”: $option is listed among the founders.',
                  brand.sourceIds,
                ),
                ...brand.facts.map(
                  (fact) => _BrandOptionDetail.fact(
                    fact.textRu,
                    fact.textEn,
                    fact.sourceIds,
                  ),
                ),
              ],
            )
            .toList(growable: false);
        return details.isEmpty ? fallback() : details;
      case BrandQuestionKind.logo:
        final details = atlas.brands
            .expand(
              (brand) => brand.logoHistory
                  .where((moment) => '${moment.year}' == option)
                  .map(
                    (moment) => _BrandOptionDetail(
                      '«${brand.name}»: ${moment.textRu}',
                      '“${brand.name}”: ${moment.textEn}',
                      moment.sourceIds,
                    ),
                  ),
            )
            .toList(growable: false);
        return details.isEmpty ? fallback() : details;
    }
  }

  Widget _practiceView(BrandAtlas atlas) {
    if (_finished) return _practiceResult(atlas);
    final all = _retrying ? _retryQuestions : _roundQuestions;
    if (all.isEmpty) return _practiceResult(atlas);
    final q = all[_question];
    return SafeArea(
      child: ListView(
        key: const Key('brand-practice-scroll'),
        controller: _practiceScroll,
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            _t('Unranked practice', 'Тренировка без рейтинга'),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Text(
            '${_question + 1} / ${all.length}${_retrying ? ' · ${_t('retry', 'повтор ошибок')}' : ''}',
          ),
          const SizedBox(height: 16),
          Text(
            _claim(q.promptRu, q.promptEn),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          ...q.options.indexed.map((entry) {
            final index = entry.$1;
            final option = entry.$2;
            final correct = option == q.answer;
            final selected = option == _chosen;
            final selectedWrong = _checked && selected && !correct;
            final colors = Theme.of(context).colorScheme;
            final background = !_checked
                ? (selected ? colors.secondaryContainer : null)
                : correct
                ? colors.primaryContainer
                : selectedWrong
                ? colors.errorContainer
                : colors.surfaceContainerHighest;
            final status = correct
                ? _t('Correct answer', 'Правильный ответ')
                : selectedWrong
                ? _t('Your answer: incorrect', 'Ваш ответ: неверно')
                : _t('Not selected', 'Не выбран');
            final icon = correct
                ? Icons.check_circle_outline
                : selectedWrong
                ? Icons.cancel_outlined
                : Icons.circle_outlined;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: OutlinedButton(
                key: Key('brand-option-$index'),
                onPressed: _checked
                    ? null
                    : () => setState(() => _chosen = option),
                style: OutlinedButton.styleFrom(
                  backgroundColor: background,
                  disabledBackgroundColor: background,
                  disabledForegroundColor: colors.onSurface,
                  minimumSize: const Size.fromHeight(48),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (_checked) Icon(icon),
                        if (_checked) const SizedBox(width: 8),
                        Expanded(child: Text(_displayName(option))),
                      ],
                    ),
                    if (_checked)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(
                          start: 32,
                          top: 2,
                        ),
                        child: Text(
                          status,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
          if (!_checked)
            FilledButton(
              onPressed: _chosen == null
                  ? null
                  : () {
                      setState(() {
                        _checked = true;
                        if (_chosen == q.answer) {
                          if (!_retrying) _correct++;
                        } else if (!_retrying) {
                          _missed.add(q);
                        }
                      });
                      _practiceBottom();
                    },
              child: Text(_t('Check', 'Проверить')),
            ),
          if (_checked)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _chosen == q.answer
                          ? _t('Correct', 'Верно')
                          : _t('Not quite', 'Пока неверно'),
                    ),
                    if (_chosen != q.answer)
                      Text(
                        key: const Key('brand-feedback-your'),
                        _t(
                          'Your answer: ${_displayName(_chosen!)}',
                          'Ваш ответ: ${_displayName(_chosen!)}',
                        ),
                      ),
                    Text(
                      key: const Key('brand-feedback-correct'),
                      _t(
                        'Correct answer: ${_displayName(q.answer)}',
                        'Правильный ответ: ${_displayName(q.answer)}',
                      ),
                    ),
                    Text(_claim(q.explanationRu, q.explanationEn)),
                    _sourceButtons(atlas, q.sourceIds),
                  ],
                ),
              ),
            ),
          if (_checked)
            FilledButton(
              key: const Key('brand-next'),
              onPressed: () {
                setState(() {
                  if (_question + 1 >= all.length) {
                    _finished = true;
                  } else {
                    _question++;
                  }
                  _chosen = null;
                  _checked = false;
                });
                _practiceTop();
              },
              child: Text(_t('Next', 'Дальше')),
            ),
          if (_checked)
            ExpansionTile(
              key: const Key('brand-option-explanations'),
              title: Text(
                _t(
                  'Explanations for every option',
                  'Пояснения ко всем вариантам',
                ),
              ),
              children: q.options.indexed
                  .map((entry) {
                    final index = entry.$1;
                    final option = entry.$2;
                    final correct = option == q.answer;
                    final selectedWrong = option == _chosen && !correct;
                    final details = _optionDetails(atlas, q, option);
                    final sourceIds = details
                        .expand((detail) => detail.sourceIds)
                        .toSet()
                        .toList(growable: false);
                    return ListTile(
                      key: Key('brand-option-explanation-$index'),
                      leading: Icon(
                        correct
                            ? Icons.check_circle_outline
                            : selectedWrong
                            ? Icons.cancel_outlined
                            : Icons.circle_outlined,
                      ),
                      title: Text(_displayName(option)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            correct
                                ? _t('Correct option', 'Правильный вариант')
                                : selectedWrong
                                ? _t(
                                    'Your answer: incorrect',
                                    'Ваш ответ: неверно',
                                  )
                                : _t('Not selected', 'Не выбран'),
                          ),
                          ...details.map(
                            (detail) => Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                detail.isFact
                                    ? _factClaim(detail.ru, detail.en)
                                    : _claim(detail.ru, detail.en),
                              ),
                            ),
                          ),
                          _sourceButtons(atlas, sourceIds),
                        ],
                      ),
                    );
                  })
                  .toList(growable: false),
            ),
          TextButton(
            onPressed: () => setState(() => _practice = false),
            child: Text(_t('Back to brands', 'К брендам')),
          ),
        ],
      ),
    );
  }

  Widget _practiceResult(BrandAtlas atlas) => SafeArea(
    child: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _t(
                'Practice complete: $_correct / ${_roundQuestions.length} correct',
                'Тренировка завершена: верных $_correct из ${_roundQuestions.length}',
              ),
            ),
            if (_missed.isNotEmpty)
              FilledButton.tonal(
                onPressed: () => setState(() {
                  _retryQuestions
                    ..clear()
                    ..addAll(_missed);
                  _retrying = true;
                  _finished = false;
                  _question = 0;
                  _chosen = null;
                  _checked = false;
                }),
                child: Text(
                  _t(
                    'Retry missed (${_missed.length})',
                    'Повторить ошибки (${_missed.length})',
                  ),
                ),
              ),
            FilledButton(
              onPressed: () => setState(() => _practice = false),
              child: Text(_t('Back to brands', 'К брендам')),
            ),
          ],
        ),
      ],
    ),
  );
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

class _SourcedText {
  const _SourcedText(this.text, this.sourceIds);
  final String text;
  final List<String> sourceIds;
}

class _BrandOptionDetail {
  const _BrandOptionDetail(this.ru, this.en, this.sourceIds) : isFact = false;
  const _BrandOptionDetail.fact(this.ru, this.en, this.sourceIds)
    : isFact = true;
  final String ru, en;
  final List<String> sourceIds;
  final bool isFact;
}
