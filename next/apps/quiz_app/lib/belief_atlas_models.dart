import 'dart:math';

const beliefAtlasAsset = 'assets/quizipedia/belief_atlas.json';

String _string(Map<String, dynamic> row, String key, {bool empty = false}) {
  final value = row[key];
  if (value is! String || (!empty && value.trim().isEmpty)) {
    throw FormatException('$key required');
  }
  return value.trim();
}

String _labels(Map<String, dynamic> row, String key) {
  final value = row[key];
  if (value is! List || value.any((v) => v is! String || v.trim().isEmpty)) {
    throw FormatException('$key string list required');
  }
  return value.cast<String>().join(', ');
}

List<String> _ids(Object? value, String label) {
  if (value is! List ||
      value.isEmpty ||
      value.any((v) => v is! String || v.trim().isEmpty)) {
    throw FormatException('$label ids required');
  }
  return List.unmodifiable(value.cast<String>());
}

List<Map<String, dynamic>> _rows(Object? value, String label) {
  if (value is! List) throw FormatException('$label list required');
  return List.unmodifiable(
    value.map((v) {
      if (v is! Map) throw FormatException('$label row');
      return Map<String, dynamic>.from(v);
    }),
  );
}

bool _date(String value) {
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) return false;
  final parsed = DateTime.tryParse(value);
  return parsed != null && parsed.toIso8601String().startsWith(value);
}

class BeliefSource {
  BeliefSource(this.id, this.title, this.url, this.checkedOn);
  final String id, title, url, checkedOn;
  factory BeliefSource.fromJson(Map<String, dynamic> r) {
    final url = _string(r, 'url');
    final uri = Uri.tryParse(url);
    if (uri?.scheme != 'https' ||
        uri?.host.isEmpty != false ||
        !_date(_string(r, 'checked_on'))) {
      throw FormatException('invalid source');
    }
    return BeliefSource(
      _string(r, 'id'),
      _string(r, 'title'),
      url,
      _string(r, 'checked_on'),
    );
  }
}

class BeliefFact {
  BeliefFact(this.ru, this.en, this.sourceIds);
  final String ru, en;
  final List<String> sourceIds;
  factory BeliefFact.fromJson(Map<String, dynamic> r) => BeliefFact(
    _string(r, 'text_ru'),
    _string(r, 'text_en'),
    _ids(r['source_ids'], 'fact source'),
  );
}

class BeliefNode {
  BeliefNode({
    required this.id,
    required this.section,
    required this.ru,
    required this.en,
    required this.groupRu,
    required this.groupEn,
    required this.summaryRu,
    required this.summaryEn,
    required this.domainsRu,
    required this.domainsEn,
    required this.symbolsRu,
    required this.symbolsEn,
    required this.facts,
    required this.noteRu,
    required this.noteEn,
    required this.sourceIds,
  });
  final String id,
      section,
      ru,
      en,
      groupRu,
      groupEn,
      summaryRu,
      summaryEn,
      domainsRu,
      domainsEn,
      symbolsRu,
      symbolsEn,
      noteRu,
      noteEn;
  final List<BeliefFact> facts;
  final List<String> sourceIds;
  factory BeliefNode.fromJson(Map<String, dynamic> r) => BeliefNode(
    id: _string(r, 'id'),
    section: _string(r, 'section'),
    ru: _string(r, 'name_ru'),
    en: _string(r, 'name_en'),
    groupRu: _string(r, 'group_ru'),
    groupEn: _string(r, 'group_en'),
    summaryRu: _string(r, 'summary_ru'),
    summaryEn: _string(r, 'summary_en'),
    domainsRu: _labels(r, 'domains_ru'),
    domainsEn: _labels(r, 'domains_en'),
    symbolsRu: _labels(r, 'symbols_ru'),
    symbolsEn: _labels(r, 'symbols_en'),
    facts: _rows(
      r['facts'],
      'facts',
    ).map(BeliefFact.fromJson).toList(growable: false),
    noteRu: _string(r, 'variant_note_ru', empty: true),
    noteEn: _string(r, 'variant_note_en', empty: true),
    sourceIds: _ids(r['source_ids'], 'node source'),
  );
}

class BeliefEdge {
  BeliefEdge(
    this.id,
    this.from,
    this.to,
    this.ru,
    this.en,
    this.scopeRu,
    this.scopeEn,
    this.sourceIds,
  );
  final String id, from, to, ru, en, scopeRu, scopeEn;
  final List<String> sourceIds;
  factory BeliefEdge.fromJson(Map<String, dynamic> r) => BeliefEdge(
    _string(r, 'id'),
    _string(r, 'from_id'),
    _string(r, 'to_id'),
    _string(r, 'label_ru'),
    _string(r, 'label_en'),
    _string(r, 'scope_ru'),
    _string(r, 'scope_en'),
    _ids(r['source_ids'], 'edge source'),
  );
}

class BeliefQuestion {
  BeliefQuestion(
    this.id,
    this.section,
    this.ru,
    this.en,
    this.options,
    this.correct,
    this.explainRu,
    this.explainEn,
    this.sourceIds,
  );
  final String id, section, ru, en, correct, explainRu, explainEn;
  final List<String> options, sourceIds;
  factory BeliefQuestion.fromJson(Map<String, dynamic> r) {
    final o = _ids(r['option_ids'], 'question option');
    if (o.length != 4 || o.toSet().length != 4) {
      throw FormatException('four unique options');
    }
    final correct = _string(r, 'correct_id');
    if (o.where((id) => id == correct).length != 1) {
      throw FormatException('correct option');
    }
    return BeliefQuestion(
      _string(r, 'id'),
      _string(r, 'section'),
      _string(r, 'stem_ru'),
      _string(r, 'stem_en'),
      o,
      correct,
      _string(r, 'explanation_ru'),
      _string(r, 'explanation_en'),
      _ids(r['source_ids'], 'question source'),
    );
  }
}

class BeliefAtlas {
  BeliefAtlas(
    this.coverageRu,
    this.coverageEn,
    this.sources,
    this.nodes,
    this.edges,
    this.questions,
  );
  final String coverageRu, coverageEn;
  final List<BeliefSource> sources;
  final List<BeliefNode> nodes;
  final List<BeliefEdge> edges;
  final List<BeliefQuestion> questions;
  factory BeliefAtlas.fromJson(Map<String, dynamic> r) {
    if (_string(r, 'schema_version') != 'qm-belief-atlas/v1') {
      throw FormatException('schema');
    }
    final sources = _rows(
      r['sources'],
      'sources',
    ).map(BeliefSource.fromJson).toList();
    final nodes = _rows(r['nodes'], 'nodes').map(BeliefNode.fromJson).toList();
    final edges = _rows(r['edges'], 'edges').map(BeliefEdge.fromJson).toList();
    final questions = _rows(
      r['questions'],
      'questions',
    ).map(BeliefQuestion.fromJson).toList();
    final ids = nodes.map((v) => v.id).toSet(),
        sourceIds = sources.map((v) => v.id).toSet(),
        edgeIds = edges.map((v) => v.id).toSet(),
        questionIds = questions.map((v) => v.id).toSet();
    if (ids.length != nodes.length ||
        sourceIds.length != sources.length ||
        edgeIds.length != edges.length ||
        questionIds.length != questions.length ||
        nodes.any((n) => n.section != 'greek' && n.section != 'religions') ||
        questions.any(
          (q) => q.section != 'greek' && q.section != 'religions',
        )) {
      throw FormatException('unique ids/section');
    }
    bool refs(List<String> v) => v.every(sourceIds.contains);
    if (nodes.any(
          (n) => !refs(n.sourceIds) || n.facts.any((f) => !refs(f.sourceIds)),
        ) ||
        edges.any(
          (e) =>
              !refs(e.sourceIds) ||
              !ids.contains(e.from) ||
              !ids.contains(e.to) ||
              nodes.firstWhere((n) => n.id == e.from).section !=
                  nodes.firstWhere((n) => n.id == e.to).section,
        ) ||
        questions.any(
          (q) =>
              !refs(q.sourceIds) ||
              !q.options.every(ids.contains) ||
              !ids.contains(q.correct) ||
              q.options.any(
                (id) =>
                    nodes.firstWhere((n) => n.id == id).section != q.section,
              ),
        )) {
      throw FormatException('unresolved reference');
    }
    return BeliefAtlas(
      _string(r, 'coverage_note_ru'),
      _string(r, 'coverage_note_en'),
      List.unmodifiable(sources),
      List.unmodifiable(nodes),
      List.unmodifiable(edges),
      List.unmodifiable(questions),
    );
  }
  List<BeliefQuestion> round(String section, {int? seed}) {
    final list = questions.where((q) => q.section == section).toList()
      ..shuffle(Random(seed));
    return List.unmodifiable(list.take(min(10, list.length)));
  }
}
