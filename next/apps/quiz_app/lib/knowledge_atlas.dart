/// A small, source-linked atlas for unranked history and culture practice.
library;

import 'fact_practice.dart';
import 'chronology_timeline.dart';
import 'atlas_media.dart';

import 'russian_learning_text.dart';

import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

const _knowledgeAsset = 'assets/quizipedia/knowledge_atlas.json';

String _required(Map<String, dynamic> row, String key) {
  final value = row[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('$key required');
  }
  return value;
}

List<Map<String, dynamic>> _rows(Object? value, String name) {
  if (value is! List) throw FormatException('$name list required');
  return value
      .map((item) {
        if (item is! Map) throw FormatException('$name row');
        return Map<String, dynamic>.from(item);
      })
      .toList(growable: false);
}

enum KnowledgeQuestionKind { date, order, creator, credit }

class AtlasEvent {
  const AtlasEvent({
    required this.id,
    required this.year,
    required this.endYear,
    required this.approximate,
    required this.era,
    required this.titleRu,
    required this.titleEn,
    required this.whatRu,
    required this.whatEn,
    required this.whyRu,
    required this.whyEn,
    required this.consequencesRu,
    required this.consequencesEn,
    required this.sourceUrl,
  });
  final String id, era, titleRu, titleEn, whatRu, whatEn, whyRu, whyEn;
  final String consequencesRu, consequencesEn, sourceUrl;
  final int year;
  final int? endYear;
  final bool approximate;

  factory AtlasEvent.fromJson(Map<String, dynamic> row) {
    final year = row['year'];
    if (year is! int) throw const FormatException('event year');
    final end = row['end_year'];
    if (end != null && (end is! int || end < year)) {
      throw const FormatException('event end_year');
    }
    final source = _required(row, 'source_url');
    if (!source.startsWith('https://')) {
      throw const FormatException('event source');
    }
    return AtlasEvent(
      id: _required(row, 'id'),
      year: year,
      endYear: end as int?,
      approximate: row['approximate'] == true,
      era: _required(row, 'era'),
      titleRu: _required(row, 'title_ru'),
      titleEn: _required(row, 'title_en'),
      whatRu: _required(row, 'what_ru'),
      whatEn: _required(row, 'what_en'),
      whyRu: _required(row, 'why_ru'),
      whyEn: _required(row, 'why_en'),
      consequencesRu: _required(row, 'consequences_ru'),
      consequencesEn: _required(row, 'consequences_en'),
      sourceUrl: source,
    );
  }
}

class AtlasWork {
  const AtlasWork({
    this.approximate = false,
    this.endYear,
    required this.id,
    required this.type,
    required this.year,
    required this.titleRu,
    required this.titleEn,
    required this.creatorIds,
    required this.cast,
    required this.summaryRu,
    required this.summaryEn,
    required this.factRu,
    required this.factEn,
    required this.sourceUrl,
  });
  final String id,
      type,
      titleRu,
      titleEn,
      summaryRu,
      summaryEn,
      factRu,
      factEn,
      sourceUrl;
  final int year;
  final bool approximate;
  final int? endYear;
  final List<String> creatorIds;
  final List<AtlasCredit> cast;
  factory AtlasWork.fromJson(Map<String, dynamic> row) {
    final year = row['year'];
    final endYear = row['end_year'];
    if (endYear != null &&
        (endYear is! int || year is! int || endYear < year)) {
      throw const FormatException('work end_year');
    }
    final creatorIds = row['creator_ids'];
    if (year is! int ||
        creatorIds is! List ||
        creatorIds.isEmpty ||
        creatorIds.any((v) => v is! String)) {
      throw const FormatException('work fields');
    }
    final source = _required(row, 'source_url');
    if (!source.startsWith('https://')) {
      throw const FormatException('work source');
    }
    final cast = <AtlasCredit>[];
    for (final item in (row['cast'] as List? ?? const [])) {
      if (item is! List ||
          item.length != 3 ||
          item.any((value) => value is! String)) {
        throw const FormatException('work cast');
      }
      cast.add(
        AtlasCredit(
          personId: item[0] as String,
          roleRu: item[1] as String,
          roleEn: item[2] as String,
        ),
      );
    }
    return AtlasWork(
      approximate: row['approximate'] == true,
      endYear: endYear as int?,
      id: _required(row, 'id'),
      type: _required(row, 'type'),
      year: year,
      titleRu: _required(row, 'title_ru'),
      titleEn: _required(row, 'title_en'),
      creatorIds: List.unmodifiable(creatorIds.cast<String>()),
      cast: List.unmodifiable(cast),
      summaryRu: _required(row, 'summary_ru'),
      summaryEn: _required(row, 'summary_en'),
      factRu: _required(row, 'fact_ru'),
      factEn: _required(row, 'fact_en'),
      sourceUrl: source,
    );
  }
}

class AtlasCredit {
  const AtlasCredit({
    required this.personId,
    required this.roleRu,
    required this.roleEn,
  });
  final String personId, roleRu, roleEn;
}

class AtlasPerson {
  const AtlasPerson({
    required this.id,
    required this.nameRu,
    required this.nameEn,
    required this.roles,
    required this.born,
    required this.bioRu,
    required this.bioEn,
    required this.sourceUrl,
    required this.creditWorkIds,
  });
  final String id, nameRu, nameEn, born, bioRu, bioEn, sourceUrl;
  final List<String> roles, creditWorkIds;
  factory AtlasPerson.fromJson(Map<String, dynamic> row) {
    final roles = row['roles'];
    final credits = row['credit_work_ids'];
    if (roles is! List ||
        roles.isEmpty ||
        roles.any((value) => value is! String) ||
        credits is! List ||
        credits.isEmpty ||
        credits.any((value) => value is! String)) {
      throw const FormatException('person fields');
    }
    final source = _required(row, 'source_url');
    if (!source.startsWith('https://')) {
      throw const FormatException('person source');
    }
    return AtlasPerson(
      id: _required(row, 'id'),
      nameRu: _required(row, 'name_ru'),
      nameEn: _required(row, 'name_en'),
      roles: List.unmodifiable(roles.cast<String>()),
      born: _required(row, 'born'),
      bioRu: _required(row, 'bio_ru'),
      bioEn: _required(row, 'bio_en'),
      sourceUrl: source,
      creditWorkIds: List.unmodifiable(credits.cast<String>()),
    );
  }
}

class KnowledgeQuestion {
  const KnowledgeQuestion({
    required this.kind,
    required this.promptRu,
    required this.promptEn,
    required this.answer,
    required this.options,
    required this.explanationRu,
    required this.explanationEn,
    required this.sourceUrl,
    this.eventIds = const [],
    this.workId,
    this.personId,
  });
  final KnowledgeQuestionKind kind;
  final String promptRu,
      promptEn,
      answer,
      explanationRu,
      explanationEn,
      sourceUrl;
  final List<String> options;
  final List<String> eventIds;
  final String? workId, personId;
}

class KnowledgeAtlas {
  const KnowledgeAtlas({
    required this.events,
    required this.works,
    required this.people,
  });
  final List<AtlasEvent> events;
  final List<AtlasWork> works;
  final List<AtlasPerson> people;

  factory KnowledgeAtlas.fromJson(Map<String, dynamic> json) {
    if (json['schema_version'] != 'qm-knowledge-atlas/v1') {
      throw const FormatException('knowledge schema');
    }
    final events =
        _rows(json['events'], 'events').map(AtlasEvent.fromJson).toList()
          ..sort((a, b) => a.year.compareTo(b.year));
    final works = _rows(json['works'], 'works').map(AtlasWork.fromJson).toList()
      ..sort((a, b) => a.year.compareTo(b.year));
    final people =
        _rows(json['people'], 'people').map(AtlasPerson.fromJson).toList()
          ..sort((a, b) => a.nameEn.compareTo(b.nameEn));
    void unique(Iterable<String> ids, String label) {
      if (ids.toSet().length != ids.length) {
        throw FormatException('duplicate $label');
      }
    }

    unique(events.map((value) => value.id), 'event');
    unique(works.map((value) => value.id), 'work');
    unique(people.map((value) => value.id), 'person');
    final personIds = people.map((value) => value.id).toSet();
    final workIds = works.map((value) => value.id).toSet();
    for (final work in works) {
      if (!work.creatorIds.every(personIds.contains) ||
          !work.cast.every((credit) => personIds.contains(credit.personId))) {
        throw const FormatException('work person relation');
      }
      final creditedPeople = [
        ...work.creatorIds,
        ...work.cast.map((credit) => credit.personId),
      ];
      if (!creditedPeople.every(
        (id) => people
            .firstWhere((person) => person.id == id)
            .creditWorkIds
            .contains(work.id),
      )) {
        throw const FormatException('missing reciprocal credit');
      }
    }
    for (final person in people) {
      if (!person.creditWorkIds.every(workIds.contains)) {
        throw const FormatException('person work relation');
      }
      if (!person.creditWorkIds.every((workId) {
        final work = works.firstWhere((candidate) => candidate.id == workId);
        return work.creatorIds.contains(person.id) ||
            work.cast.any((credit) => credit.personId == person.id);
      })) {
        throw const FormatException('orphan person credit');
      }
    }
    return KnowledgeAtlas(
      events: List.unmodifiable(events),
      works: List.unmodifiable(works),
      people: List.unmodifiable(people),
    );
  }

  List<KnowledgeQuestion> get questions {
    final result = <KnowledgeQuestion>[];
    final yearLabels = <String>{
      for (final event in events)
        dateLabel(
          event.year,
          endYear: event.endYear,
          approximate: event.approximate,
        ),
    };
    final distinctYearEvents = events
        .where(
          (event) =>
              events.where((other) => other.year == event.year).length == 1,
        )
        .toList();
    for (final event in distinctYearEvents) {
      final answerDate = dateLabel(
        event.year,
        endYear: event.endYear,
        approximate: event.approximate,
      );
      final candidates = yearLabels
          .where((label) => label != answerDate)
          .toSet()
          .toList();
      if (candidates.length >= 5) {
        result.add(
          KnowledgeQuestion(
            kind: KnowledgeQuestionKind.date,
            promptRu: event.approximate
                ? 'Примерно когда произошло событие «${event.titleRu}»?'
                : 'В каком году произошло событие «${event.titleRu}»?',
            promptEn: event.approximate
                ? 'About when did “${event.titleEn}” happen?'
                : 'When did “${event.titleEn}” happen?',
            answer: answerDate,
            options: [answerDate, ...candidates.take(5)],
            explanationRu: '${event.titleRu}: $answerDate. ${event.whatRu}',
            explanationEn: '${event.titleEn}: $answerDate. ${event.whatEn}',
            sourceUrl: event.sourceUrl,
            eventIds: [event.id],
          ),
        );
      }
    }
    for (var index = 5; index < events.length; index += 6) {
      final answer = events[index];
      final options = [
        answer,
        events[index - 1],
        events[index - 2],
        events[index - 3],
        events[index - 4],
        events[index - 5],
      ];
      if (options.map((event) => event.year).toSet().length != options.length) {
        continue;
      }
      result.add(
        KnowledgeQuestion(
          kind: KnowledgeQuestionKind.order,
          promptRu: 'Какое из этих событий произошло последним?',
          promptEn: 'Which of these events happened last?',
          answer: answer.titleEn,
          options: options.map((event) => event.titleEn).toList(),
          explanationRu: '${answer.titleRu} — ${dateLabel(answer.year)}.',
          explanationEn: '${answer.titleEn} — ${dateLabel(answer.year)}.',
          sourceUrl: answer.sourceUrl,
          eventIds: options.map((event) => event.id).toList(),
        ),
      );
    }
    final peopleById = {for (final person in people) person.id: person};
    for (final work in works) {
      final creator = peopleById[work.creatorIds.first]!;
      final distractors = people
          .where((person) => !work.creatorIds.contains(person.id))
          .take(5)
          .map((person) => person.nameEn)
          .toList();
      if (distractors.length == 5) {
        result.add(
          KnowledgeQuestion(
            kind: KnowledgeQuestionKind.creator,
            promptRu: 'Кто создал произведение «${work.titleRu}»?',
            promptEn: 'Who created “${work.titleEn}”?',
            answer: creator.nameEn,
            options: [creator.nameEn, ...distractors],
            explanationRu:
                '${creator.nameRu} связан с произведением «${work.titleRu}».',
            explanationEn:
                '${creator.nameEn} is credited for “${work.titleEn}”.',
            sourceUrl: work.sourceUrl,
            workId: work.id,
            personId: creator.id,
          ),
        );
      }
      for (final credit in work.cast) {
        final actor = peopleById[credit.personId]!;
        final excluded = work.cast.map((item) => item.personId).toSet();
        final distractors = people
            .where((person) => !excluded.contains(person.id))
            .where((person) => person.roles.contains('actor'))
            .take(5)
            .map((person) => person.nameEn)
            .toList();
        if (distractors.length == 5) {
          result.add(
            KnowledgeQuestion(
              kind: KnowledgeQuestionKind.credit,
              promptRu:
                  'Кто сыграл роль «${credit.roleRu}» в «${work.titleRu}»?',
              promptEn: 'Who played ${credit.roleEn} in “${work.titleEn}”?',
              answer: actor.nameEn,
              options: [actor.nameEn, ...distractors],
              explanationRu: '${actor.nameRu} сыграл(а) ${credit.roleRu}.',
              explanationEn: '${actor.nameEn} played ${credit.roleEn}.',
              sourceUrl: work.sourceUrl,
              workId: work.id,
              personId: actor.id,
            ),
          );
        }
      }
    }
    return result
        .map(
          (question) => KnowledgeQuestion(
            kind: question.kind,
            promptRu: question.promptRu,
            promptEn: question.promptEn,
            answer: question.answer,
            options: (List<String>.from(question.options)
              ..shuffle(Random(question.promptEn.hashCode))),
            explanationRu: question.explanationRu,
            explanationEn: question.explanationEn,
            sourceUrl: question.sourceUrl,
            eventIds: question.eventIds,
            workId: question.workId,
            personId: question.personId,
          ),
        )
        .toList(growable: false);
  }
}

String dateLabel(int year, {int? endYear, bool approximate = false}) {
  final mark = approximate ? '≈ ' : '';
  String one(int value) => value < 0 ? '${-value} BCE' : '$value';
  return '$mark${one(year)}${endYear == null ? '' : '–${one(endYear)}'}';
}

String dateLabelRu(int year, {int? endYear, bool approximate = false}) {
  final mark = approximate ? 'около ' : '';
  String one(int value) => value < 0 ? '${-value} до н. э.' : '$value';
  return '$mark${one(year)}${endYear == null ? '' : '–${one(endYear)}'}';
}

class KnowledgeAtlasPage extends StatefulWidget {
  const KnowledgeAtlasPage({super.key, required this.section, this.bundle});
  final String section;
  final AssetBundle? bundle;
  @override
  State<KnowledgeAtlasPage> createState() => _KnowledgeAtlasPageState();
}

class _KnowledgeAtlasPageState extends State<KnowledgeAtlasPage> {
  late Future<KnowledgeAtlas> _future = _load();
  String? _era, _type, _query, _selectedEvent, _selectedWork, _selectedPerson;
  int _questionIndex = 0;
  String? _answer;
  bool _checked = false;

  Future<KnowledgeAtlas> _load() async {
    final source = await (widget.bundle ?? rootBundle).loadString(
      _knowledgeAsset,
    );
    return KnowledgeAtlas.fromJson(
      Map<String, dynamic>.from(jsonDecode(source) as Map),
    );
  }

  bool get _ru => Localizations.localeOf(context).languageCode == 'ru';
  String _text(String en, String ru) => _ru ? russianLearningText(ru) : en;
  String _eventName(AtlasEvent event) =>
      _ru ? russianLearningText(event.titleRu) : event.titleEn;
  String _workName(AtlasWork work) =>
      _ru ? russianLearningText(work.titleRu) : work.titleEn;
  String _personName(AtlasPerson person) =>
      _ru ? russianLearningText(person.nameRu) : person.nameEn;

  @override
  Widget build(BuildContext context) => FutureBuilder<KnowledgeAtlas>(
    future: _future,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Scaffold(
          appBar: AppBar(
            title: Text(_title),
            actions: [
              FactPracticeAction(
                scope: widget.section == 'culture' ? 'works' : widget.section,
                bundle: widget.bundle,
              ),
            ],
          ),
          body: Center(
            child: FilledButton.icon(
              onPressed: () => setState(() => _future = _load()),
              icon: const Icon(Icons.refresh),
              label: Text(_text('Retry', 'Повторить')),
            ),
          ),
        );
      }
      if (!snapshot.hasData) {
        return Scaffold(
          appBar: AppBar(
            title: Text(_title),
            actions: [
              FactPracticeAction(
                scope: widget.section == 'culture' ? 'works' : widget.section,
                bundle: widget.bundle,
              ),
            ],
          ),
          body: const Center(child: CircularProgressIndicator()),
        );
      }
      return Scaffold(
        appBar: AppBar(
          title: Text(_title),
          actions: [
            FactPracticeAction(
              scope: widget.section == 'culture' ? 'works' : widget.section,
              bundle: widget.bundle,
            ),
          ],
        ),
        body: _build(snapshot.data!),
      );
    },
  );

  String get _title => switch (widget.section) {
    'history' => _text('Human history', 'История человечества'),
    'people' => _text('People of culture', 'Люди культуры'),
    _ => _text('Culture atlas', 'Атлас культуры'),
  };

  Widget _build(KnowledgeAtlas atlas) => SafeArea(
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            _text(
              'Local practice · sources open in the browser',
              'Локальная тренировка · источники открываются в браузере',
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        Expanded(
          child: switch (widget.section) {
            'history' => _history(atlas),
            'people' => _people(atlas),
            _ => _culture(atlas),
          },
        ),
      ],
    ),
  );

  Widget _history(KnowledgeAtlas atlas) {
    final eras = [
      'prehistory',
      'ancient',
      'medieval',
      'early_modern',
      'modern',
      'contemporary',
    ];
    final events = atlas.events
        .where((event) => _era == null || event.era == _era)
        .where(
          (event) => _match(
            '${event.titleRu} ${event.titleEn} ${event.era} ${_eraLabel(event.era)}',
            _query,
          ),
        )
        .toList();
    final selected =
        events.where((event) => event.id == _selectedEvent).firstOrNull ??
        (events.isEmpty ? null : events.first);
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
      children: [
        _quizButton(atlas, eventIds: events.map((event) => event.id).toSet()),
        _search(),
        Wrap(
          spacing: 6,
          children: [
            ChoiceChip(
              label: Text(_text('All eras', 'Все периоды')),
              selected: _era == null,
              onSelected: (_) => setState(() => _era = null),
            ),
            ...eras.map(
              (era) => ChoiceChip(
                label: Text(_eraLabel(era)),
                selected: _era == era,
                onSelected: (_) => setState(() => _era = era),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ChronologyTimeline(
          entries: events
              .map(
                (event) => ChronologyEntry(
                  id: event.id,
                  year: event.year,
                  date: _date(
                    event.year,
                    endYear: event.endYear,
                    approximate: event.approximate,
                  ),
                  title: _eventName(event),
                ),
              )
              .toList(),
          selectedId: selected?.id,
          onSelected: (id) => _showEvent(
            atlas,
            events.firstWhere((event) => event.id == id),
            events,
          ),
        ),
        const SizedBox(height: 8),
        ...events.map(
          (event) => Card(
            child: ListTile(
              key: Key('knowledge-event-${event.id}'),
              leading: _yearPill(
                event.year,
                endYear: event.endYear,
                approximate: event.approximate,
              ),
              title: Text(_eventName(event)),
              subtitle: Text(_eraLabel(event.era)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showEvent(atlas, event, events),
            ),
          ),
        ),
      ],
    );
  }

  Widget _culture(KnowledgeAtlas atlas) {
    final types = [
      'film',
      'book',
      'opera',
      'oratorio',
      'ballet',
      'play',
      'music',
    ];
    final works = atlas.works
        .where((work) => _type == null || work.type == _type)
        .where(
          (work) => _match(
            '${work.titleRu} ${work.titleEn} ${_typeLabel(work.type)} ${atlas.people.where((p) => work.creatorIds.contains(p.id) || work.cast.any((c) => c.personId == p.id)).map((p) => '${p.nameRu} ${p.nameEn}').join(' ')}',
            _query,
          ),
        )
        .toList();
    final selected =
        works.where((work) => work.id == _selectedWork).firstOrNull ??
        (works.isEmpty ? null : works.first);
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
      children: [
        _quizButton(atlas, workIds: works.map((work) => work.id).toSet()),
        _search(),
        Wrap(
          spacing: 6,
          children: [
            ChoiceChip(
              label: Text(_text('Everything', 'Всё')),
              selected: _type == null,
              onSelected: (_) => setState(() => _type = null),
            ),
            ...types.map(
              (type) => ChoiceChip(
                label: Text(_typeLabel(type)),
                selected: _type == type,
                onSelected: (_) => setState(() => _type = type),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ChronologyTimeline(
          entries: works
              .map(
                (work) => ChronologyEntry(
                  id: work.id,
                  year: work.year,
                  date: _date(
                    work.year,
                    endYear: work.endYear,
                    approximate: work.approximate,
                  ),
                  title: _workName(work),
                ),
              )
              .toList(),
          selectedId: selected?.id,
          onSelected: (id) =>
              _showWork(atlas, works.firstWhere((work) => work.id == id)),
        ),
        ...works.map(
          (work) => Card(
            child: ListTile(
              key: Key('knowledge-work-${work.id}'),
              leading: _yearPill(
                work.year,
                endYear: work.endYear,
                approximate: work.approximate,
              ),
              title: Text(_workName(work)),
              subtitle: Text(_typeLabel(work.type)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showWork(atlas, work),
            ),
          ),
        ),
      ],
    );
  }

  Widget _people(KnowledgeAtlas atlas) {
    final people = atlas.people
        .where(
          (person) => _match(
            '${person.nameRu} ${person.nameEn} ${person.roles.join(' ')}',
            _query,
          ),
        )
        .toList();
    final selected = people
        .where((person) => person.id == _selectedPerson)
        .firstOrNull;
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
      children: [
        _quizButton(
          atlas,
          personIds: people.map((person) => person.id).toSet(),
        ),
        _search(),
        if (selected != null) _personCard(atlas, selected),
        ...people.map(
          (person) => Card(
            child: ListTile(
              key: Key('knowledge-person-${person.id}'),
              leading: AtlasMedia(
                scope: 'people',
                entityId: person.id,
                compact: true,
              ),
              title: Text(_personName(person)),
              subtitle: Text(
                '${person.born} · ${person.roles.map(_roleLabel).join(', ')}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showPerson(atlas, person),
            ),
          ),
        ),
      ],
    );
  }

  Widget _search() => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: TextField(
      key: const Key('knowledge-search'),
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search),
        hintText: _text(
          'Search names, works, periods',
          'Поиск имён, произведений, периодов',
        ),
        border: const OutlineInputBorder(),
      ),
      onChanged: (value) => setState(() => _query = value),
    ),
  );

  List<KnowledgeQuestion> _scopedQuestions(
    KnowledgeAtlas atlas, {
    Set<String>? eventIds,
    Set<String>? workIds,
    Set<String>? personIds,
  }) => atlas.questions
      .where((question) {
        if (eventIds != null) {
          return question.eventIds.isNotEmpty &&
              question.eventIds.every(eventIds.contains);
        }
        if (workIds != null) return workIds.contains(question.workId);
        if (personIds != null) return personIds.contains(question.personId);
        return false;
      })
      .toList(growable: false);

  Widget _quizButton(
    KnowledgeAtlas atlas, {
    Set<String>? eventIds,
    Set<String>? workIds,
    Set<String>? personIds,
  }) {
    final questions = _scopedQuestions(
      atlas,
      eventIds: eventIds,
      workIds: workIds,
      personIds: personIds,
    );
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: FilledButton.icon(
          key: const Key('knowledge-train'),
          onPressed: questions.isEmpty
              ? null
              : () => _showQuiz(atlas, questions),
          icon: const Icon(Icons.school_outlined),
          label: Text(
            questions.isEmpty
                ? _text(
                    'No practice for this selection',
                    'Для этого выбора нет тренировки',
                  )
                : _text('Train connections', 'Тренировать связи'),
          ),
        ),
      ),
    );
  }

  Widget _eventCard(
    KnowledgeAtlas atlas,
    AtlasEvent event,
    List<AtlasEvent> visible,
    ValueChanged<AtlasEvent> onSelectEvent,
  ) {
    final index = visible.indexOf(event);
    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${_date(event.year, endYear: event.endYear, approximate: event.approximate)} · ${_eraLabel(event.era)}',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                IconButton(
                  tooltip: _text('Previous event', 'Предыдущее событие'),
                  onPressed: index > 0
                      ? () => onSelectEvent(visible[index - 1])
                      : null,
                  icon: const Icon(Icons.arrow_back),
                ),
                IconButton(
                  tooltip: _text('Next event', 'Следующее событие'),
                  onPressed: index + 1 < visible.length
                      ? () => onSelectEvent(visible[index + 1])
                      : null,
                  icon: const Icon(Icons.arrow_forward),
                ),
              ],
            ),
            Text(
              _eventName(event),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 10),
            _labelled(
              _text('What happened', 'Что произошло'),
              _ru ? russianLearningText(event.whatRu) : event.whatEn,
            ),
            _labelled(
              _text('Why it matters', 'Почему это важно'),
              _ru ? russianLearningText(event.whyRu) : event.whyEn,
            ),
            _labelled(
              _text('What changed next', 'Что изменилось дальше'),
              _ru
                  ? russianLearningText(event.consequencesRu)
                  : event.consequencesEn,
            ),
            _sourceButton(event.sourceUrl),
          ],
        ),
      ),
    );
  }

  Widget _workCard(KnowledgeAtlas atlas, AtlasWork work) {
    final people = {for (final person in atlas.people) person.id: person};
    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_date(work.year, endYear: work.endYear, approximate: work.approximate)} · ${_typeLabel(work.type)}',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            Text(
              _workName(work),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            _labelled(
              _text('Briefly', 'Кратко'),
              _ru ? russianLearningText(work.summaryRu) : work.summaryEn,
            ),
            _labelled(
              _text('Fact', 'Факт'),
              _ru ? russianLearningText(work.factRu) : work.factEn,
            ),
            Text(
              _text('Creator', 'Создатель'),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Wrap(
              spacing: 6,
              children: work.creatorIds
                  .map((id) => _personButton(atlas, people[id]!))
                  .toList(),
            ),
            if (work.cast.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                _text('Cast and roles', 'Участники и роли'),
                style: Theme.of(context).textTheme.titleSmall,
              ),
              ...work.cast.map(
                (credit) => TextButton(
                  onPressed: () => _showPerson(atlas, people[credit.personId]!),
                  child: Text(
                    '${_personName(people[credit.personId]!)} — ${_ru ? russianLearningText(credit.roleRu) : credit.roleEn}',
                  ),
                ),
              ),
            ],
            _sourceButton(work.sourceUrl),
          ],
        ),
      ),
    );
  }

  Widget _personCard(KnowledgeAtlas atlas, AtlasPerson person) {
    final works = {for (final work in atlas.works) work.id: work};
    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AtlasMedia(scope: 'people', entityId: person.id),
            Text(
              _personName(person),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text('${person.born} · ${person.roles.map(_roleLabel).join(', ')}'),
            const SizedBox(height: 8),
            Text(_ru ? russianLearningText(person.bioRu) : person.bioEn),
            const SizedBox(height: 8),
            Text(
              _text('Works and participation', 'Произведения и участие'),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Wrap(
              spacing: 6,
              children: person.creditWorkIds
                  .map(
                    (id) => ActionChip(
                      label: Text(_workName(works[id]!)),
                      onPressed: () => _showWork(atlas, works[id]!),
                    ),
                  )
                  .toList(),
            ),
            _sourceButton(person.sourceUrl),
          ],
        ),
      ),
    );
  }

  Widget _personButton(KnowledgeAtlas atlas, AtlasPerson person) => ActionChip(
    label: Text(_personName(person)),
    onPressed: () => _showPerson(atlas, person),
  );

  void _showEvent(
    KnowledgeAtlas atlas,
    AtlasEvent event,
    List<AtlasEvent> visible,
  ) {
    // A modal builder is re-run when MediaQuery changes. Keep this outside
    // it so resizing the viewport preserves the event being read.
    var current = event;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) => SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _eventCard(atlas, current, visible, (next) {
                setSheetState(() => current = next);
                setState(() => _selectedEvent = next.id);
              }),
            ),
          ),
        );
      },
    );
  }

  void _showWork(KnowledgeAtlas atlas, AtlasWork work) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (sheetContext) => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: _workCard(atlas, work),
          ),
        ),
      );

  void _showPerson(KnowledgeAtlas atlas, AtlasPerson person) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (sheetContext) => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: _personCard(atlas, person),
          ),
        ),
      );
  Widget _labelled(String heading, String body) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(heading, style: Theme.of(context).textTheme.titleSmall),
        Text(body),
      ],
    ),
  );
  Widget _sourceButton(String source) => TextButton.icon(
    onPressed: () =>
        launchUrl(Uri.parse(source), mode: LaunchMode.externalApplication),
    icon: const Icon(Icons.open_in_new, size: 16),
    label: Text(_text('Source', 'Источник')),
  );
  Widget _yearPill(int year, {int? endYear, bool approximate = false}) =>
      SizedBox(
        width: 62,
        child: Text(
          _date(year, endYear: endYear, approximate: approximate),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      );
  bool _match(String value, String? query) =>
      query == null ||
      query.trim().isEmpty ||
      value.toLowerCase().contains(query.toLowerCase());

  String _date(int year, {int? endYear, bool approximate = false}) => _ru
      ? dateLabelRu(year, endYear: endYear, approximate: approximate)
      : dateLabel(year, endYear: endYear, approximate: approximate);

  void _showQuiz(KnowledgeAtlas atlas, List<KnowledgeQuestion> questions) {
    if (questions.isEmpty) return;
    setState(() {
      _questionIndex = 0;
      _answer = null;
      _checked = false;
    });
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final question = questions[_questionIndex % questions.length];
          final correct = _answer == question.answer;
          return SafeArea(
            child: SizedBox(
              height: MediaQuery.sizeOf(context).height * .9,
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 64, 20, 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _text('Unranked practice', 'Тренировка без рейтинга'),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _ru
                              ? russianLearningText(question.promptRu)
                              : question.promptEn,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        ...question.options.indexed.map(
                          (option) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _quizOption(
                              atlas,
                              question,
                              option.$2,
                              option.$1,
                              () => setModalState(() => _answer = option.$2),
                            ),
                          ),
                        ),
                        FilledButton(
                          key: const Key('knowledge-check'),
                          onPressed: _answer == null || _checked
                              ? null
                              : () => setModalState(() => _checked = true),
                          child: Text(_text('Check', 'Проверить')),
                        ),
                        if (_checked) ...[
                          const SizedBox(height: 10),
                          Text(
                            correct
                                ? _text('Correct!', 'Верно!')
                                : '${_text('Correct answer:', 'Правильный ответ:')} ${_quizValue(atlas, question.answer)}',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          Text(
                            _ru
                                ? _quizValue(
                                    atlas,
                                    russianLearningText(question.explanationRu),
                                  )
                                : question.explanationEn,
                          ),
                          _sourceButton(question.sourceUrl),
                          FilledButton.tonal(
                            key: const Key('knowledge-next'),
                            onPressed: () => setModalState(() {
                              _questionIndex++;
                              _answer = null;
                              _checked = false;
                            }),
                            child: Text(
                              _text('Next question', 'Следующий вопрос'),
                            ),
                          ),
                          _choiceExplanations(atlas, question),
                        ],
                      ],
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Tooltip(
                      message: _text('Close training', 'Закрыть тренировку'),
                      child: IconButton(
                        key: const Key('knowledge-close-training'),
                        tooltip: _text('Close training', 'Закрыть тренировку'),
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
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
  }

  Widget _quizOption(
    KnowledgeAtlas atlas,
    KnowledgeQuestion question,
    String option,
    int index,
    VoidCallback onSelect,
  ) {
    final colors = Theme.of(context).colorScheme;
    final correct = option == question.answer;
    final selected = option == _answer;
    final wrongChoice = _checked && selected && !correct;
    final label = !_checked
        ? null
        : correct
        ? _text('Correct answer.', 'Правильный ответ.')
        : wrongChoice
        ? _text('Your choice was incorrect.', 'Ваш выбор неверный.')
        : null;
    return OutlinedButton(
      key: Key('knowledge-option-$index'),
      onPressed: _checked ? null : onSelect,
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerLeft,
        disabledForegroundColor: colors.onSurface,
        backgroundColor: !_checked
            ? (selected ? colors.secondaryContainer : null)
            : correct
            ? colors.tertiaryContainer
            : wrongChoice
            ? colors.errorContainer
            : colors.surfaceContainerHighest,
      ),
      child: Row(
        children: [
          if (_checked)
            Icon(
              correct
                  ? Icons.check_circle
                  : wrongChoice
                  ? Icons.cancel
                  : Icons.circle_outlined,
              color: correct
                  ? colors.primary
                  : wrongChoice
                  ? colors.error
                  : colors.onSurfaceVariant,
            ),
          if (_checked) const SizedBox(width: 8),
          Expanded(child: Text(_quizValue(atlas, option))),
          if (label != null) ...[
            const SizedBox(width: 8),
            Flexible(child: Text(label, textAlign: TextAlign.end)),
          ],
        ],
      ),
    );
  }

  Widget _choiceExplanations(
    KnowledgeAtlas atlas,
    KnowledgeQuestion question,
  ) => ExpansionTile(
    key: const Key('knowledge-choice-explanations'),
    title: Text(_text('About every option', 'О каждом варианте')),
    children: [
      for (final option in question.options.indexed)
        _choiceExplanation(atlas, question, option.$2, option.$1),
    ],
  );

  Widget _choiceExplanation(
    KnowledgeAtlas atlas,
    KnowledgeQuestion question,
    String option,
    int index,
  ) {
    final eventQuestion =
        question.kind == KnowledgeQuestionKind.date ||
        question.kind == KnowledgeQuestionKind.order;
    final events = eventQuestion
        ? atlas.events
              .where(
                (event) => question.kind == KnowledgeQuestionKind.date
                    ? dateLabel(
                            event.year,
                            endYear: event.endYear,
                            approximate: event.approximate,
                          ) ==
                          option
                    : event.titleEn == option,
              )
              .toList()
        : const <AtlasEvent>[];
    final people = eventQuestion
        ? const <AtlasPerson>[]
        : atlas.people.where((person) => person.nameEn == option).toList();
    final detail = eventQuestion
        ? events
              .map(
                (event) =>
                    '${_eventName(event)}: ${_ru ? event.whatRu : event.whatEn}',
              )
              .join('\n')
        : people
              .map(
                (person) =>
                    '${_personName(person)} · ${person.roles.map(_roleLabel).join(', ')}\n${_ru ? person.bioRu : person.bioEn}',
              )
              .join('\n');
    final sources =
        (eventQuestion
                ? events.map((event) => event.sourceUrl)
                : people.map((person) => person.sourceUrl))
            .toSet()
            .join(' · ');
    return ListTile(
      key: Key('knowledge-choice-explanation-$index'),
      title: Text(_quizValue(atlas, option)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_ru ? russianLearningText(detail) : detail),
          const SizedBox(height: 4),
          Text('${_text('Source', 'Источник')}: $sources'),
        ],
      ),
    );
  }

  String _eraLabel(String era) => switch (era) {
    'prehistory' => _text('Prehistory', 'Доисторический период'),
    'ancient' => _text('Ancient world', 'Древний мир'),
    'medieval' => _text('Middle Ages', 'Средние века'),
    'early_modern' => _text('Early modern', 'Раннее Новое время'),
    'modern' => _text('Modern world', 'Новое время'),
    _ => _text('Contemporary', 'Новейшее время'),
  };
  String _typeLabel(String type) => switch (type) {
    'film' => _text('Films', 'Фильмы'),
    'book' => _text('Books', 'Книги'),
    'opera' => _text('Opera', 'Опера'),
    'oratorio' => _text('Oratorio', 'Оратория'),
    'ballet' => _text('Ballet', 'Балет'),
    'play' => _text('Plays', 'Пьесы'),
    _ => _text('Music', 'Музыка'),
  };
  String _roleLabel(String role) => switch (role) {
    'actor' => _text('actor', 'актёр'),
    'director' => _text('director', 'режиссёр'),
    'composer' => _text('composer', 'композитор'),
    _ => _text('author', 'автор'),
  };

  String _quizValue(KnowledgeAtlas atlas, String value) {
    if (!_ru) return value;
    for (final person in atlas.people) {
      if (person.nameEn == value) return person.nameRu;
    }
    for (final event in atlas.events) {
      if (event.titleEn == value) return event.titleRu;
    }
    return value
        .replaceAll('BCE', 'до н. э.')
        .replaceAll('до н. э..', 'до н. э.')
        .replaceFirst('≈ ', 'около ');
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
