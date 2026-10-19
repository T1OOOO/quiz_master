/// Sourced local music reference and finite, unranked visual practice.
library;

import 'fact_practice.dart';

import 'russian_learning_text.dart';

import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

const musicCategories = <String, (String, String)>{
  'all': ('All topics', 'Все темы'),
  'notes': ('Read notes', 'Чтение нот'),
  'notation': ('Signs and clefs', 'Знаки и ключи'),
  'rhythm': ('Rhythm and rests', 'Ритм и паузы'),
  'dynamics': ('Dynamics', 'Динамика'),
  'tempo': ('Tempo', 'Темп'),
  'technique': ('Performance', 'Исполнение'),
  'harmony': ('Harmony basics', 'Основы гармонии'),
  'instruments': ('Orchestra', 'Оркестр'),
  'world': ('World traditions', 'Традиции мира'),
};

Map<String, dynamic> _object(Object? value) {
  if (value is! Map || value.keys.any((k) => k is! String)) {
    throw const FormatException('Expected an object');
  }
  return Map<String, dynamic>.from(value);
}

String _text(Map<String, dynamic> row, String key) {
  final value = row[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('Missing $key');
  }
  return value.trim();
}

List<Map<String, dynamic>> _rows(Object? value) {
  if (value is! List || value.isEmpty) {
    throw const FormatException('Expected nonempty rows');
  }
  return value.map(_object).toList(growable: false);
}

List<String> _ids(Object? value) {
  if (value is! List ||
      value.isEmpty ||
      value.any((v) => v is! String || v.trim().isEmpty) ||
      value.toSet().length != value.length) {
    throw const FormatException('Expected unique nonempty IDs');
  }
  return List.unmodifiable(value.cast<String>());
}

Map<String, dynamic>? _visual(Object? value) {
  if (value == null) return null;
  final row = _object(value);
  if (row.length != 1 ||
      !(row['note'] is int &&
              (row['note'] as int) >= 0 &&
              (row['note'] as int) <= 6 ||
          row['glyph'] is int &&
              (row['glyph'] as int) >= 0xE000 &&
              (row['glyph'] as int) <= 0xF8FF ||
          row['text'] is String && (row['text'] as String).trim().isNotEmpty)) {
    throw const FormatException('Invalid music visual');
  }
  return Map.unmodifiable(row);
}

class MusicSource {
  MusicSource(Map<String, dynamic> row)
    : id = _text(row, 'id'),
      title = _text(row, 'title'),
      url = _text(row, 'url'),
      checkedOn = _text(row, 'checked_on') {
    final uri = Uri.tryParse(url);
    final date = DateTime.tryParse(checkedOn);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        date == null ||
        date.toIso8601String().substring(0, 10) != checkedOn) {
      throw const FormatException('Invalid source URL or date');
    }
  }
  final String id, title, url, checkedOn;
}

class MusicEntry {
  MusicEntry(Map<String, dynamic> row)
    : id = _text(row, 'id'),
      category = _text(row, 'category'),
      nameRu = _text(row, 'name_ru'),
      nameEn = _text(row, 'name_en'),
      descriptionRu = _text(row, 'description_ru'),
      descriptionEn = _text(row, 'description_en'),
      exampleRu = _text(row, 'example_ru'),
      exampleEn = _text(row, 'example_en'),
      sourceIds = _ids(row['source_ids']),
      visual = _visual(row['visual']) {
    if (!musicCategories.containsKey(category) || category == 'all') {
      throw const FormatException('Unknown category');
    }
  }
  final String id,
      category,
      nameRu,
      nameEn,
      descriptionRu,
      descriptionEn,
      exampleRu,
      exampleEn;
  final List<String> sourceIds;
  final Map<String, dynamic>? visual;
  String name(bool ru) => ru ? nameRu : nameEn;
  String description(bool ru) =>
      ru ? russianLearningText(descriptionRu) : descriptionEn;
  String example(bool ru) => ru ? russianLearningText(exampleRu) : exampleEn;
  bool matches(String query) =>
      '$nameRu $nameEn $descriptionRu $descriptionEn $exampleRu $exampleEn'
          .toLowerCase()
          .contains(query.trim().toLowerCase());
}

class MusicQuestion {
  MusicQuestion(Map<String, dynamic> row)
    : id = _text(row, 'id'),
      stemRu = _text(row, 'stem_ru'),
      stemEn = _text(row, 'stem_en'),
      optionIds = _ids(row['option_ids']),
      correctId = _text(row, 'correct_id'),
      explanationRu = _text(row, 'explanation_ru'),
      explanationEn = _text(row, 'explanation_en'),
      sourceIds = _ids(row['source_ids']),
      visual = _visual(row['visual']) {
    if (optionIds.length != 4 || !optionIds.contains(correctId)) {
      throw const FormatException('Four options including the answer required');
    }
  }
  final String id, stemRu, stemEn, correctId, explanationRu, explanationEn;
  final List<String> optionIds, sourceIds;
  final Map<String, dynamic>? visual;
}

class MusicCatalog {
  MusicCatalog._(this.entries, this.questions, this.sources);
  final Map<String, MusicEntry> entries;
  final List<MusicQuestion> questions;
  final Map<String, MusicSource> sources;

  factory MusicCatalog.fromJson(Object? value) {
    final raw = _object(value);
    if (raw['schema'] != 'qm-music-learning/v1') {
      throw const FormatException('Music schema');
    }
    final sourceList = _rows(raw['sources']).map(MusicSource.new).toList();
    final entryList = _rows(raw['entries']).map(MusicEntry.new).toList();
    final questions = _rows(raw['questions']).map(MusicQuestion.new).toList();
    final sources = {for (final s in sourceList) s.id: s};
    final entries = {for (final e in entryList) e.id: e};
    if (sources.length != sourceList.length ||
        entries.length != entryList.length ||
        questions.map((q) => q.id).toSet().length != questions.length) {
      throw const FormatException('Duplicate IDs');
    }
    for (final refs in [
      ...entryList.map((e) => e.sourceIds),
      ...questions.map((q) => q.sourceIds),
    ]) {
      if (refs.any((id) => !sources.containsKey(id))) {
        throw const FormatException('Unknown source');
      }
    }
    for (final q in questions) {
      if (q.optionIds.any((id) => !entries.containsKey(id))) {
        throw const FormatException('Unknown option');
      }
    }
    return MusicCatalog._(
      Map.unmodifiable(entries),
      List.unmodifiable(questions),
      Map.unmodifiable(sources),
    );
  }
  static Future<MusicCatalog> load([AssetBundle? bundle]) async =>
      MusicCatalog.fromJson(
        jsonDecode(
          await (bundle ?? rootBundle).loadString(
            'assets/quizipedia/music_learning.json',
          ),
        ),
      );
}

/// The semantic label is supplied by the caller: practice visuals never announce the answer.
class MusicVisual extends StatelessWidget {
  const MusicVisual({
    super.key,
    required this.visual,
    required this.label,
    this.compact = false,
  });
  final Map<String, dynamic> visual;
  final String label;
  final bool compact;
  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    image: true,
    child: ExcludeSemantics(
      child: Container(
        height: compact ? 72 : 168,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: visual.containsKey('text')
            ? Text(
                switch (visual['text']) {
                  'tie' => '⌒',
                  'crescendo' => '＜',
                  _ =>
                    Localizations.localeOf(context).languageCode == 'ru'
                        ? russianLearningText(visual['text'] as String)
                        : visual['text'] as String,
                },
                textAlign: TextAlign.center,
                style: compact
                    ? Theme.of(context).textTheme.headlineMedium
                    : Theme.of(context).textTheme.headlineLarge,
              )
            : CustomPaint(
                size: Size(compact ? 76 : 260, compact ? 68 : 156),
                painter: _MusicPainter(
                  visual,
                  Theme.of(context).colorScheme.onSurface,
                ),
              ),
      ),
    ),
  );
}

class _MusicPainter extends CustomPainter {
  _MusicPainter(this.visual, this.color);
  final Map<String, dynamic> visual;
  final Color color;
  void glyph(Canvas canvas, int codepoint, Offset origin, double size) {
    final text = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(codepoint),
        style: TextStyle(fontFamily: 'Bravura', fontSize: size, color: color),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final baseline = text.computeDistanceToActualBaseline(
      TextBaseline.alphabetic,
    );
    text.paint(canvas, Offset(origin.dx, origin.dy - baseline));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2;
    if (visual['note'] case final int note) {
      for (var i = 0; i < 5; i++) {
        canvas.drawLine(
          Offset(22, 40 + i * 12),
          Offset(size.width - 22, 40 + i * 12),
          paint,
        );
      }
      glyph(canvas, 0xE050, const Offset(36, 76), 48);
      final y = 100.0 - note * 6;
      if (note == 0) canvas.drawLine(Offset(130, y), Offset(158, y), paint);
      glyph(canvas, 0xE0A4, Offset(136, y), 48);
      canvas.drawLine(Offset(147, y), Offset(147, y - 36), paint);
    } else if (visual['glyph'] case final int codepoint) {
      if ([0xE050, 0xE062, 0xE05C, 0xE4E3, 0xE4E4].contains(codepoint)) {
        for (var i = 0; i < 5; i++) {
          canvas.drawLine(
            Offset(22, 40 + i * 12),
            Offset(size.width - 22, 40 + i * 12),
            paint,
          );
        }
        // SMuFL clef origins sit on their reference line. Rest origins sit
        // on a line too: the line distinguishes hanging and sitting rectangles.
        final y = switch (codepoint) {
          0xE050 => 76.0,
          0xE062 => 52.0,
          _ => 64.0,
        };
        glyph(canvas, codepoint, Offset(size.width / 2 - 15, y), 48);
      } else if ([0xE4A2, 0xE4A0, 0xE4C0].contains(codepoint)) {
        glyph(canvas, 0xE1D5, Offset(size.width / 2 - 8, 115), 60);
        glyph(canvas, codepoint, Offset(size.width / 2 - 8, 51), 60);
      } else {
        glyph(canvas, codepoint, Offset(size.width / 2 - 15, 106), 76);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MusicPainter oldDelegate) =>
      oldDelegate.visual != visual || oldDelegate.color != color;
}

class MusicLearningPage extends StatefulWidget {
  const MusicLearningPage({
    super.key,
    this.bundle,
    this.training = false,
    this.initialEntryId,
  });
  final AssetBundle? bundle;
  final bool training;
  final String? initialEntryId;
  @override
  State<MusicLearningPage> createState() => _MusicLearningPageState();
}

class _MusicLearningPageState extends State<MusicLearningPage> {
  MusicCatalog? _catalog;
  Object? _error;
  String _query = '', _category = 'all';
  bool _practice = false, _checked = false, _retry = false;
  int _index = 0, _score = 0, _total = 0;
  String? _choice;
  List<MusicQuestion> _round = [];
  final List<MusicQuestion> _missed = [];
  Map<String, List<String>> _options = {};
  bool get _ru => Localizations.localeOf(context).languageCode == 'ru';
  String _t(String en, String ru) => _ru ? ru : en;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final catalog = await MusicCatalog.load(widget.bundle);
      if (!mounted) return;
      setState(() {
        _catalog = catalog;
        if (widget.training) _startRound();
      });
      final initial = catalog.entries[widget.initialEntryId];
      if (initial != null && !widget.training) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _details(initial);
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  List<MusicEntry> get _visible => _catalog!.entries.values
      .where(
        (e) =>
            (_category == 'all' || e.category == _category) &&
            e.matches(_query),
      )
      .toList(growable: false);
  List<MusicQuestion> get _available {
    final ids = _visible.map((e) => e.id).toSet();
    return _catalog!.questions.where((q) => ids.contains(q.correctId)).toList();
  }

  void _startRound({List<MusicQuestion>? mistakes}) {
    _round = mistakes ?? ((_available..shuffle(Random())).take(10).toList());
    _options = {
      for (final q in _round)
        q.id: (List<String>.of(q.optionIds)..shuffle(Random())),
    };
    _index = 0;
    _choice = null;
    _checked = false;
    _practice = true;
    _retry = mistakes != null;
    if (!_retry) {
      _score = 0;
      _total = _round.length;
    }
    _missed.clear();
  }

  Widget _sources(List<String> ids) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (final id in ids)
        TextButton.icon(
          onPressed: () => launchUrl(
            Uri.parse(_catalog!.sources[id]!.url),
            mode: LaunchMode.externalApplication,
          ),
          icon: const Icon(Icons.open_in_new, size: 16),
          label: Text(
            '${learningSourceTitle(_catalog!.sources[id]!.title, russian: _ru)} · ${_catalog!.sources[id]!.checkedOn}',
          ),
        ),
    ],
  );
  void _details(MusicEntry entry) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (context) => SizedBox(
      key: const Key('music-detail'),
      height: MediaQuery.sizeOf(context).height * .82,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              entry.name(_ru),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            if (!_ru) Text(entry.nameRu),
            const SizedBox(height: 16),
            if (entry.visual != null)
              MusicVisual(visual: entry.visual!, label: entry.name(_ru)),
            const SizedBox(height: 16),
            Text(
              entry.description(_ru),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Text(entry.example(_ru)),
            const SizedBox(height: 16),
            _sources(entry.sourceIds),
          ],
        ),
      ),
    ),
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      actions: [FactPracticeAction(scope: 'music', bundle: widget.bundle)],
      title: Text(
        _t('Music · learn and practise', 'Музыка · изучение и тренировка'),
      ),
      leading: _practice
          ? IconButton(
              tooltip: _t('Back to reference', 'К справочнику'),
              icon: const Icon(Icons.arrow_back),
              onPressed: () => setState(() => _practice = false),
            )
          : null,
    ),
    body: SafeArea(
      child: _error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _t(
                      'Could not load music cards',
                      'Не удалось загрузить карточки',
                    ),
                  ),
                  FilledButton(
                    onPressed: _load,
                    child: Text(_t('Retry', 'Повторить')),
                  ),
                ],
              ),
            )
          : _catalog == null
          ? const Center(child: CircularProgressIndicator())
          : _practice
          ? _quiz()
          : _reference(),
    ),
  );
  Widget _reference() => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      Text(
        _t(
          'Read a score, recognise a sign, discover an instrument',
          'Прочитай ноту, узнай знак, открой инструмент',
        ),
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 8),
      Text(
        _t(
          'A foundation in Western notation plus selected world traditions. Not an exhaustive dictionary of every musical culture. Note examples use treble clef and octave 4 (middle C to B).',
          'Основы западной нотной записи и избранные традиции мира. Это не полный словарь всех музыкальных культур. Нотные примеры: скрипичный ключ, первая октава (до–си).',
        ),
      ),
      const SizedBox(height: 16),
      TextField(
        key: const Key('music-search'),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search),
          labelText: _t(
            'Find a term, sign or instrument',
            'Найти термин, знак или инструмент',
          ),
          border: const OutlineInputBorder(),
        ),
        onChanged: (value) => setState(() => _query = value),
      ),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(
        key: const Key('music-category'),
        initialValue: _category,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: _t('Topic', 'Тема'),
          border: const OutlineInputBorder(),
        ),
        items: [
          for (final c in musicCategories.entries)
            DropdownMenuItem(
              value: c.key,
              child: Text(_ru ? c.value.$2 : c.value.$1),
            ),
        ],
        onChanged: (value) => setState(() => _category = value ?? 'all'),
      ),
      const SizedBox(height: 12),
      FilledButton.icon(
        key: const Key('music-practice'),
        onPressed: _available.isEmpty
            ? null
            : () => setState(() => _startRound()),
        icon: const Icon(Icons.quiz_outlined),
        label: Text(
          _t(
            'Practise · ${_available.length} questions',
            'Тренировка · вопросов: ${_available.length}',
          ),
        ),
      ),
      Text(
        _t(
          'Local practice · no ranking. Filters choose the questions; all answer choices remain available.',
          'Локально, без рейтинга. Фильтры выбирают вопросы; варианты ответов сохраняются.',
        ),
      ),
      const SizedBox(height: 12),
      Text(_t('${_visible.length} cards', 'Карточек: ${_visible.length}')),
      if (_visible.isEmpty)
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            _t(
              'Nothing found. Change the search or topic.',
              'Ничего не найдено. Измените поиск или тему.',
            ),
          ),
        ),
      for (final e in _visible)
        Card(
          child: ListTile(
            key: Key('music-entry-${e.id}'),
            leading: e.visual != null
                ? SizedBox(
                    width: 76,
                    child: MusicVisual(
                      visual: e.visual!,
                      label: e.name(_ru),
                      compact: true,
                    ),
                  )
                : const Icon(Icons.piano),
            title: Text(e.name(_ru)),
            subtitle: Text(
              e.description(_ru),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _details(e),
          ),
        ),
    ],
  );
  Widget _quiz() {
    if (_round.isEmpty || _index >= _round.length) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            _t('Score $_score / $_total', 'Счёт $_score / $_total'),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          if (_retry)
            Text(
              _t(
                'Mistake review finished; original score retained.',
                'Повторение завершено; сохранён исходный счёт.',
              ),
            ),
          if (_missed.isNotEmpty)
            OutlinedButton(
              onPressed: () =>
                  setState(() => _startRound(mistakes: List.of(_missed))),
              child: Text(_t('Retry mistakes', 'Повторить ошибки')),
            ),
          FilledButton(
            onPressed: () => setState(() => _startRound()),
            child: Text(_t('New round', 'Новый раунд')),
          ),
          TextButton(
            onPressed: () => setState(() => _practice = false),
            child: Text(_t('Back to reference', 'К справочнику')),
          ),
        ],
      );
    }
    final q = _round[_index];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          _t('Local unranked practice', 'Локальная тренировка без рейтинга'),
        ),
        Text('${_index + 1} / ${_round.length}'),
        const SizedBox(height: 12),
        Text(
          _ru ? q.stemRu : q.stemEn,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        if (q.visual != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: MusicVisual(
              visual: q.visual!,
              label: _t(
                'Music notation to identify',
                'Нотный пример для определения',
              ),
            ),
          ),
        for (final id in _options[q.id]!)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: OutlinedButton(
              key: Key('music-option-$id'),
              onPressed: _checked ? null : () => setState(() => _choice = id),
              style: OutlinedButton.styleFrom(
                backgroundColor: _choice == id
                    ? Theme.of(context).colorScheme.secondaryContainer
                    : null,
              ),
              child: Text(_catalog!.entries[id]!.name(_ru)),
            ),
          ),
        const SizedBox(height: 12),
        if (!_checked)
          FilledButton(
            key: const Key('music-check'),
            onPressed: _choice == null
                ? null
                : () {
                    if (_checked) return;
                    setState(() {
                      _checked = true;
                      if (_choice == q.correctId) {
                        if (!_retry) _score++;
                      } else {
                        _missed.add(q);
                      }
                    });
                  },
            child: Text(_t('Check', 'Проверить')),
          ),
        if (_checked) ...[
          Text(
            _choice == q.correctId
                ? _t('Correct', 'Верно')
                : _t(
                    'Answer: ${_catalog!.entries[q.correctId]!.name(_ru)}',
                    'Ответ: ${_catalog!.entries[q.correctId]!.name(_ru)}',
                  ),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Text(_ru ? russianLearningText(q.explanationRu) : q.explanationEn),
          _sources(q.sourceIds),
          FilledButton(
            key: const Key('music-next'),
            onPressed: () => setState(() {
              _index++;
              _choice = null;
              _checked = false;
            }),
            child: Text(_t('Next', 'Далее')),
          ),
        ],
      ],
    );
  }
}
