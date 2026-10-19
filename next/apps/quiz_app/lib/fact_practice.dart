import 'dart:math';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'fact_practice_models.dart';

const factPracticeSections = <String, (String, String)>{
  'countries': ('Страны', 'Countries'),
  'sky': ('Созвездия', 'Constellations'),
  'endocrine': ('Эндокринная система', 'Endocrine system'),
  'landmarks': ('Достопримечательности', 'Landmarks'),
  'music': ('Музыка', 'Music'),
  'organs': ('Органы и железы', 'Organs and glands'),
  'greek': ('Древнегреческие боги', 'Greek gods'),
  'religions': ('Религии и традиции', 'Religions and traditions'),
  'food': ('Блюда', 'Food'),
  'brands': ('Бренды', 'Brands'),
  'history': ('История', 'History'),
  'works': ('Фильмы, книги и опера', 'Films, books and opera'),
  'people': ('Люди культуры', 'People of culture'),
};

class FactPracticeAction extends StatelessWidget {
  const FactPracticeAction({super.key, required this.scope, this.bundle});
  final String scope;
  final AssetBundle? bundle;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: Localizations.localeOf(context).languageCode == 'ru'
        ? 'Вопросы по всем фактам'
        : 'Practise all facts',
    icon: const Icon(Icons.fact_check_outlined),
    onPressed: () => Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FactPracticePage(scope: scope, bundle: bundle),
      ),
    ),
  );
}

class FactPracticePage extends StatefulWidget {
  const FactPracticePage({
    super.key,
    required this.scope,
    this.bundle,
    this.facts,
    this.entityIds,
  });
  final String scope;
  final AssetBundle? bundle;
  final List<StudyFact>? facts;
  final Set<String>? entityIds;
  @override
  State<FactPracticePage> createState() => _FactPracticePageState();
}

class _FactPracticePageState extends State<FactPracticePage> {
  late Future<List<FactQuestion>> _future = _load();
  late String _scope = widget.scope;
  String _query = '';
  String? _field, _chosen;
  List<FactQuestion>? _round;
  List<FactQuestion> _pool = [];
  final List<FactQuestion> _missed = [];
  final Set<String> _seen = {};
  int _index = 0, _score = 0, _seed = 0;
  bool _checked = false, _finished = false;
  final _scroll = ScrollController();

  bool get _ru => Localizations.localeOf(context).languageCode == 'ru';
  String _t(String ru, String en) => _ru ? ru : en;
  String _section(String id) {
    final value = factPracticeSections[id];
    return value == null ? id : (_ru ? value.$1 : value.$2);
  }

  Future<List<FactQuestion>> _load() async {
    final facts =
        widget.facts ??
        await loadStudyFacts(widget.scope, bundle: widget.bundle);
    final questions = buildFactQuestions(facts);
    final entityIds = widget.entityIds;
    return entityIds == null
        ? questions
        : questions.where((q) => entityIds.contains(q.fact.entityId)).toList();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _top() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted && _scroll.hasClients) _scroll.jumpTo(0);
  });

  void _start(
    List<FactQuestion> questions, {
    bool retry = false,
    bool single = false,
    List<FactQuestion>? continueWith,
  }) {
    final candidates = questions
        .where((q) => !_seen.contains(q.fact.id))
        .toList();
    final pool = retry || single
        ? List.of(questions)
        : (candidates.isEmpty ? List.of(questions) : candidates);
    if (pool.isEmpty) return;
    if (!retry && !single) pool.shuffle(Random(_seed++));
    setState(() {
      if (!retry) _pool = List.of(continueWith ?? questions);
      _round = pool
          .take(
            single
                ? 1
                : retry
                ? pool.length
                : 10,
          )
          .toList();
      _missed.clear();
      _index = 0;
      _score = 0;
      _chosen = null;
      _checked = false;
      _finished = false;
    });
    _top();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(_t('Тренировка по фактам', 'Fact practice'))),
    body: SafeArea(
      child: FutureBuilder<List<FactQuestion>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _t(
                        'Не удалось загрузить факты.',
                        'Could not load facts.',
                      ),
                    ),
                    FilledButton(
                      onPressed: () => setState(() => _future = _load()),
                      child: Text(_t('Повторить', 'Retry')),
                    ),
                  ],
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_round != null) return _quiz(snapshot.data!);
          return _browse(snapshot.data!);
        },
      ),
    ),
  );

  Widget _browse(List<FactQuestion> bank) {
    final scoped = bank
        .where((q) => _scope == 'all' || q.fact.scope == _scope)
        .toList();
    final fields = <String, String>{
      for (final q in scoped) q.fact.fieldRu: q.fact.fieldEn,
    };
    final query = _query.toLowerCase().trim();
    final visible = scoped
        .where(
          (q) =>
              (_field == null || q.fact.fieldRu == _field) &&
              '${q.fact.nameRu} ${q.fact.nameEn} ${q.fact.fieldRu} ${q.fact.fieldEn}'
                  .toLowerCase()
                  .contains(query),
        )
        .toList();
    return CustomScrollView(
      controller: _scroll,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _t(
                    'Факты из карточек · вопросы с проверкой ответа',
                    'Facts from the cards · checked answers',
                  ),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  _t(
                    'Локальная тренировка без рейтинга. Выберите тему или отдельный факт. В каждом раунде — до 10 вопросов; ошибки можно повторить.',
                    'Local unranked practice. Choose a topic or individual fact. Each round has up to 10 questions, with mistake review.',
                  ),
                ),
                const SizedBox(height: 16),
                if (widget.scope == 'all') ...[
                  DropdownButtonFormField<String>(
                    initialValue: _scope,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: _t('Раздел', 'Section'),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'all',
                        child: Text(_t('Все разделы', 'All sections')),
                      ),
                      for (final id in factPracticeSections.keys)
                        DropdownMenuItem(
                          value: id,
                          child: Text(
                            _section(id),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (v) => setState(() {
                      _scope = v ?? 'all';
                      _field = null;
                    }),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  decoration: InputDecoration(
                    labelText: _t('Название или тема', 'Name or topic'),
                    prefixIcon: const Icon(Icons.search),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: ValueKey(_scope),
                  initialValue: _field,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: _t('Тип факта', 'Fact topic'),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: null,
                      child: Text(_t('Все факты', 'All facts')),
                    ),
                    for (final entry in fields.entries)
                      DropdownMenuItem(
                        value: entry.key,
                        child: Text(
                          _ru ? entry.key : entry.value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (v) => setState(() => _field = v),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: visible.isEmpty ? null : () => _start(visible),
                  icon: const Icon(Icons.quiz_outlined),
                  label: Text(_t('Начать тренировку', 'Start practice')),
                ),
                const SizedBox(height: 12),
                Text(
                  _t(
                    'Доступно вопросов: ${visible.length}',
                    '${visible.length} questions available',
                  ),
                ),
                if (visible.isEmpty)
                  Text(
                    _t(
                      'Измените поиск или тему.',
                      'Change the search or topic.',
                    ),
                  ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
          sliver: SliverList.builder(
            itemCount: visible.length,
            itemBuilder: (context, index) {
              final q = visible[index];
              return Card(
                child: ListTile(
                  key: Key('fact-open-${q.fact.id}'),
                  title: Text(_ru ? q.fact.nameRu : q.fact.nameEn),
                  subtitle: Text(_ru ? q.fact.fieldRu : q.fact.fieldEn),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _start([q], single: true, continueWith: visible),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _quiz(List<FactQuestion> bank) {
    if (_finished) {
      return ListView(
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        children: [
          Text(
            _t(
              'Верных ответов: $_score из ${_round!.length}',
              'Correct: $_score of ${_round!.length}',
            ),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          if (_missed.isNotEmpty)
            FilledButton(
              onPressed: () => _start(List.of(_missed), retry: true),
              child: Text(_t('Повторить ошибки', 'Retry mistakes')),
            ),
          FilledButton.tonal(
            onPressed: () => _start(_pool),
            child: Text(_t('Следующий раунд', 'Next round')),
          ),
          TextButton(
            onPressed: () {
              setState(() => _round = null);
              _top();
            },
            child: Text(_t('К списку фактов', 'Back to facts')),
          ),
        ],
      );
    }
    final q = _round![_index];
    final f = q.fact;
    return ListView(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      children: [
        Text(
          _t(
            'Без рейтинга · вопрос ${_index + 1} из ${_round!.length}',
            'Unranked · question ${_index + 1} of ${_round!.length}',
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _ru
              ? 'Что указано в разделе «${f.fieldRu}» для «${f.nameRu}»?'
              : 'What is listed under “${f.fieldEn}” for “${f.nameEn}”?',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        for (final choice in q.options)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                padding: const EdgeInsets.all(16),
                backgroundColor: _checked && choice.id == q.correctId
                    ? Theme.of(context).colorScheme.primaryContainer
                    : _chosen == choice.id
                    ? Theme.of(context).colorScheme.errorContainer
                    : null,
                disabledForegroundColor: Theme.of(context)
                    .colorScheme
                    .onSurface,
              ),
              onPressed: _checked
                  ? null
                  : () => setState(() {
                      _chosen = choice.id;
                      _checked = true;
                      _seen.add(f.id);
                      if (_chosen == q.correctId) {
                        _score++;
                      } else {
                        _missed.add(q);
                      }
                    }),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(_ru ? choice.textRu : choice.textEn),
              ),
            ),
          ),
        if (_checked) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _chosen == q.correctId
                        ? _t('Верно', 'Correct')
                        : _t('Пока неверно', 'Not quite'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _t(
                      'Правильный ответ: ${f.valueRu}',
                      'Correct answer: ${f.valueEn}',
                    ),
                  ),
                  for (final source in f.sources)
                    TextButton.icon(
                      onPressed: () => launchUrl(
                        Uri.parse(source.url),
                        mode: LaunchMode.externalApplication,
                      ),
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: Text(_ru ? source.titleRu : source.titleEn),
                    ),
                ],
              ),
            ),
          ),
          FilledButton(
            onPressed: () {
              setState(() {
                if (_index + 1 == _round!.length) {
                  _finished = true;
                } else {
                  _index++;
                }
                _chosen = null;
                _checked = false;
              });
              _top();
            },
            child: Text(
              _index + 1 == _round!.length
                  ? _t('Завершить', 'Finish')
                  : _t('Дальше', 'Next'),
            ),
          ),
        ],
        TextButton(
          onPressed: () {
            setState(() => _round = null);
            _top();
          },
          child: Text(_t('К списку фактов', 'Back to facts')),
        ),
      ],
    );
  }
}
