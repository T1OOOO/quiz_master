import 'dart:math';

const organAtlasAsset = 'assets/quizipedia/organ_atlas.json';

const organRegions = {
  'head',
  'neck',
  'thorax',
  'abdomen',
  'pelvis',
  'distributed',
};
const organKinds = {
  'organ',
  'endocrine_gland',
  'exocrine_gland',
  'mixed_gland',
  'gland_group',
  'endocrine_tissue',
};
const organSystems = {
  'nervous',
  'endocrine',
  'digestive',
  'respiratory',
  'cardiovascular',
  'urinary',
  'reproductive',
  'lymphatic',
  'integumentary',
  'sensory',
  'musculoskeletal',
};
const organQuestionTopics = {'function', 'secretion', 'location', 'fact'};

String _string(Map<String, dynamic> json, String key, {bool empty = false}) {
  final value = json[key];
  if (value is! String || (!empty && value.trim().isEmpty)) {
    throw FormatException('$key required');
  }
  return value.trim();
}

List<Map<String, dynamic>> _objects(Object? value, String label) {
  if (value is! List) throw FormatException('$label list required');
  return List.unmodifiable(
    value.map((item) {
      if (item is! Map) throw FormatException('$label object required');
      return Map<String, dynamic>.from(item);
    }),
  );
}

List<String> _strings(Object? value, String label, {bool allowEmpty = false}) {
  if (value is! List ||
      value.any((item) => item is! String || item.trim().isEmpty)) {
    throw FormatException('$label strings required');
  }
  final result = value
      .cast<String>()
      .map((item) => item.trim())
      .toList(growable: false);
  if (!allowEmpty && result.isEmpty) throw FormatException('$label nonempty');
  return List.unmodifiable(result);
}

void _calendarDate(String value) {
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
    throw const FormatException('checked_on date');
  }
  final parsed = DateTime.tryParse(value);
  if (parsed == null || parsed.toIso8601String().substring(0, 10) != value) {
    throw const FormatException('checked_on calendar date');
  }
}

class OrganSource {
  const OrganSource({
    required this.id,
    required this.title,
    required this.url,
    required this.checkedOn,
  });
  final String id, title, url, checkedOn;
  factory OrganSource.fromJson(Map<String, dynamic> json) {
    final url = _string(json, 'url');
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      throw const FormatException('source https URL required');
    }
    final checkedOn = _string(json, 'checked_on');
    _calendarDate(checkedOn);
    return OrganSource(
      id: _string(json, 'id'),
      title: _string(json, 'title'),
      url: url,
      checkedOn: checkedOn,
    );
  }
}

class OrganFact {
  const OrganFact({
    required this.textRu,
    required this.textEn,
    required this.sourceIds,
  });
  final String textRu, textEn;
  final List<String> sourceIds;
  factory OrganFact.fromJson(Map<String, dynamic> json) => OrganFact(
    textRu: _string(json, 'text_ru'),
    textEn: _string(json, 'text_en'),
    sourceIds: _strings(json['source_ids'], 'fact source'),
  );
}

class OrganStructure {
  const OrganStructure({
    required this.id,
    required this.nameRu,
    required this.nameEn,
    required this.systemIds,
    required this.kind,
    required this.region,
    required this.positionRu,
    required this.positionEn,
    required this.functionRu,
    required this.functionEn,
    required this.secretionsRu,
    required this.secretionsEn,
    required this.facts,
    required this.noteRu,
    required this.noteEn,
    required this.sourceIds,
  });
  final String id,
      nameRu,
      nameEn,
      kind,
      region,
      positionRu,
      positionEn,
      functionRu,
      functionEn,
      noteRu,
      noteEn;
  final List<String> systemIds, secretionsRu, secretionsEn, sourceIds;
  final List<OrganFact> facts;
  factory OrganStructure.fromJson(Map<String, dynamic> json) {
    final kind = _string(json, 'kind'), region = _string(json, 'region');
    final systems = _strings(json['system_ids'], 'system');
    if (!organKinds.contains(kind) ||
        !organRegions.contains(region) ||
        systems.any((id) => !organSystems.contains(id))) {
      throw const FormatException('organ classification');
    }
    final ru = _strings(
      json['secretions_ru'],
      'secretions_ru',
      allowEmpty: true,
    );
    final en = _strings(
      json['secretions_en'],
      'secretions_en',
      allowEmpty: true,
    );
    if (ru.length != en.length) {
      throw const FormatException('secretion translations');
    }
    final facts = _objects(
      json['facts'],
      'facts',
    ).map(OrganFact.fromJson).toList(growable: false);
    if (facts.isEmpty) throw const FormatException('organ facts required');
    return OrganStructure(
      id: _string(json, 'id'),
      nameRu: _string(json, 'name_ru'),
      nameEn: _string(json, 'name_en'),
      systemIds: systems,
      kind: kind,
      region: region,
      positionRu: _string(json, 'position_ru'),
      positionEn: _string(json, 'position_en'),
      functionRu: _string(json, 'function_ru'),
      functionEn: _string(json, 'function_en'),
      secretionsRu: ru,
      secretionsEn: en,
      facts: List.unmodifiable(facts),
      noteRu: _string(json, 'note_ru', empty: true),
      noteEn: _string(json, 'note_en', empty: true),
      sourceIds: _strings(json['source_ids'], 'organ source'),
    );
  }
}

class OrganQuestion {
  const OrganQuestion({
    required this.id,
    required this.topic,
    required this.stemRu,
    required this.stemEn,
    required this.optionIds,
    required this.correctId,
    required this.explanationRu,
    required this.explanationEn,
    required this.sourceIds,
  });
  final String id,
      topic,
      stemRu,
      stemEn,
      correctId,
      explanationRu,
      explanationEn;
  final List<String> optionIds, sourceIds;
  factory OrganQuestion.fromJson(Map<String, dynamic> json) {
    final topic = _string(json, 'topic');
    final options = _strings(json['option_ids'], 'question options');
    if (!organQuestionTopics.contains(topic) ||
        options.length != 4 ||
        options.toSet().length != 4) {
      throw const FormatException('question topic/options');
    }
    final correct = _string(json, 'correct_id');
    if (!options.contains(correct)) {
      throw const FormatException('question correct option');
    }
    return OrganQuestion(
      id: _string(json, 'id'),
      topic: topic,
      stemRu: _string(json, 'stem_ru'),
      stemEn: _string(json, 'stem_en'),
      optionIds: options,
      correctId: correct,
      explanationRu: _string(json, 'explanation_ru'),
      explanationEn: _string(json, 'explanation_en'),
      sourceIds: _strings(json['source_ids'], 'question source'),
    );
  }
}

class OrganAtlas {
  const OrganAtlas({
    required this.coverageNoteRu,
    required this.coverageNoteEn,
    required this.sources,
    required this.organs,
    required this.questions,
  });
  final String coverageNoteRu, coverageNoteEn;
  final List<OrganSource> sources;
  final List<OrganStructure> organs;
  final List<OrganQuestion> questions;
  factory OrganAtlas.fromJson(Map<String, dynamic> json) {
    if (json['schema_version'] != 'qm-organ-atlas/v1') {
      throw const FormatException('organ atlas schema');
    }
    final sources = _objects(
      json['sources'],
      'sources',
    ).map(OrganSource.fromJson).toList(growable: false);
    final organs = _objects(
      json['organs'],
      'organs',
    ).map(OrganStructure.fromJson).toList(growable: false);
    final questions = _objects(
      json['questions'],
      'questions',
    ).map(OrganQuestion.fromJson).toList(growable: false);
    void unique(Iterable<String> ids, String kind) {
      if (ids.toSet().length != ids.length) {
        throw FormatException('duplicate $kind');
      }
    }

    unique(sources.map((value) => value.id), 'source');
    unique(organs.map((value) => value.id), 'organ');
    unique(questions.map((value) => value.id), 'question');
    final sourceIds = sources.map((value) => value.id).toSet(),
        organIds = organs.map((value) => value.id).toSet();
    bool linked(List<String> ids) =>
        ids.isNotEmpty && ids.every(sourceIds.contains);
    for (final organ in organs) {
      if (!linked(organ.sourceIds) ||
          organ.facts.any((fact) => !linked(fact.sourceIds))) {
        throw const FormatException('organ source relation');
      }
    }
    for (final question in questions) {
      if (!linked(question.sourceIds) ||
          !organIds.contains(question.correctId) ||
          question.optionIds.any((id) => !organIds.contains(id))) {
        throw const FormatException('question relation');
      }
    }
    return OrganAtlas(
      coverageNoteRu: _string(json, 'coverage_note_ru'),
      coverageNoteEn: _string(json, 'coverage_note_en'),
      sources: List.unmodifiable(sources),
      organs: List.unmodifiable(organs),
      questions: List.unmodifiable(questions),
    );
  }
  OrganStructure organ(String id) => organs.firstWhere((item) => item.id == id);
  OrganSource source(String id) => sources.firstWhere((item) => item.id == id);
  List<OrganQuestion> round({
    int seed = 0,
    int count = 10,
    Iterable<String>? allowedIds,
  }) {
    final allowed = allowedIds?.toSet();
    final eligible =
        questions
            .where(
              (item) => allowed == null || allowed.contains(item.correctId),
            )
            .toList()
          ..shuffle(Random(seed));
    return List.unmodifiable(
      eligible.take(min(count, eligible.length)).toList(),
    );
  }
}
