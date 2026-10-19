library;

import 'fact_practice.dart';

import 'russian_learning_text.dart';

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'food_atlas_models.dart';

Future<FoodAtlas> loadFoodAtlas([AssetBundle? bundle]) async {
  final raw = await (bundle ?? rootBundle).loadString(foodAtlasAsset);
  return FoodAtlas.fromJson(Map<String, dynamic>.from(jsonDecode(raw) as Map));
}

class FoodAtlasPage extends StatefulWidget {
  const FoodAtlasPage({super.key, this.bundle});
  final AssetBundle? bundle;
  @override
  State<FoodAtlasPage> createState() => _FoodAtlasPageState();
}

class _FoodAtlasPageState extends State<FoodAtlasPage> {
  late Future<FoodAtlas> _future = loadFoodAtlas(widget.bundle);
  String _query = '', _category = '';
  bool _ascending = true,
      _training = false,
      _checked = false,
      _finished = false,
      _reviewing = false;
  FoodDish? _selected;
  List<FoodQuestion> _questions = [], _missed = [];
  int _index = 0, _score = 0, _roundSeed = 17;
  int? _firstScore;
  String? _chosen;
  FoodQuestionKind? _topic;
  final _browseScroll = ScrollController(),
      _practiceScroll = ScrollController();

  @override
  void dispose() {
    _browseScroll.dispose();
    _practiceScroll.dispose();
    super.dispose();
  }

  void _scrollToStart(ScrollController controller) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && controller.hasClients) {
        controller.animateTo(
          0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _select(FoodDish dish) {
    setState(() => _selected = dish);
    _scrollToStart(_browseScroll);
  }

  bool get _ru => Localizations.localeOf(context).languageCode == 'ru';
  String _t(String en, String ru) => _ru ? ru : en;
  String _name(FoodDish dish) => _ru ? dish.nameRu : dish.nameEn;
  String _categoryName(FoodDish dish) =>
      _ru ? dish.categoryRu : dish.categoryEn;
  String _region(FoodDish dish) => _ru ? dish.regionRu : dish.regionEn;
  String _claim(String ru, String en) => _ru ? russianLearningText(ru) : en;

  void _retry() => setState(() {
    _future = loadFoodAtlas(widget.bundle);
  });
  void _start(
    FoodAtlas atlas, {
    List<FoodQuestion>? questions,
    bool reviewing = false,
  }) => setState(() {
    _training = true;
    _reviewing = reviewing;
    _questions = questions ?? atlas.round(seed: _roundSeed++, topic: _topic);
    _index = 0;
    _score = 0;
    _chosen = null;
    _checked = false;
    _finished = false;
    if (!reviewing) {
      _missed = [];
      _firstScore = null;
    }
    _scrollToStart(_practiceScroll);
  });
  void _check() {
    if (_chosen == null || _checked) return;
    setState(() {
      _checked = true;
      if (_chosen ==
          (_ru ? _questions[_index].answerRu : _questions[_index].answerEn)) {
        _score++;
      } else {
        _missed.add(_questions[_index]);
      }
    });
  }

  void _next() => setState(() {
    if (_index + 1 == _questions.length) {
      _finished = true;
      return;
    }
    _index++;
    _chosen = null;
    _checked = false;
    _scrollToStart(_practiceScroll);
  });

  @override
  Widget build(BuildContext context) => FutureBuilder<FoodAtlas>(
    future: _future,
    builder: (context, snapshot) {
      final loading = snapshot.connectionState != ConnectionState.done;
      if (loading || snapshot.hasError || snapshot.data!.dishes.isEmpty) {
        return Scaffold(
          appBar: AppBar(title: Text(_t('Food atlas', 'Атлас блюд'))),
          body: SafeArea(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : _Message(
                    title: snapshot.hasError
                        ? _t(
                            'Food atlas could not load.',
                            'Атлас блюд не удалось загрузить.',
                          )
                        : _t(
                            'No dishes are available yet.',
                            'Блюда пока не добавлены.',
                          ),
                    action: _t('Retry', 'Повторить'),
                    onAction: _retry,
                  ),
          ),
        );
      }
      final atlas = snapshot.data!;
      return _training ? _practice(atlas) : _browse(atlas);
    },
  );

  Widget _browse(FoodAtlas atlas) {
    final categories = atlas.dishes.map(_categoryName).toSet().toList()..sort();
    final visible =
        atlas.dishes.where((dish) {
          final haystack =
              '${dish.nameRu} ${dish.nameEn} ${dish.countryRu} ${dish.countryEn} ${dish.regionRu} ${dish.regionEn} ${dish.ingredients.map((item) => '${item.nameRu} ${item.nameEn}').join(' ')} ${dish.variants.map((item) => '${item.nameRu} ${item.nameEn} ${item.regionRu} ${item.regionEn}').join(' ')}'
                  .toLowerCase();
          return (_category.isEmpty || _categoryName(dish) == _category) &&
              haystack.contains(_query.toLowerCase());
        }).toList()..sort(
          (a, b) => _ascending
              ? _name(a).compareTo(_name(b))
              : _name(b).compareTo(_name(a)),
        );
    return Scaffold(
      appBar: AppBar(
        title: Text(_t('Food atlas', 'Атлас блюд')),
        actions: [
          FactPracticeAction(scope: 'food', bundle: widget.bundle),
          TextButton.icon(
            key: const Key('food-train'),
            onPressed: atlas.dishes.length >= 10 ? () => _start(atlas) : null,
            icon: const Icon(Icons.quiz_outlined),
            label: Text(_t('Practice', 'Тренировка')),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          key: const Key('food-scroll'),
          controller: _browseScroll,
          padding: const EdgeInsets.all(16),
          children: [
            Text(_claim(atlas.coverageNoteRu, atlas.coverageNoteEn)),
            const SizedBox(height: 12),
            TextField(
              key: const Key('food-search'),
              decoration: InputDecoration(
                labelText: _t(
                  'Search dishes, ingredients, regions',
                  'Поиск блюд, ингредиентов, регионов',
                ),
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: Text(_t('All', 'Все')),
                  selected: _category.isEmpty,
                  onSelected: (_) => setState(() => _category = ''),
                ),
                for (final category in categories)
                  ChoiceChip(
                    label: Text(category),
                    selected: _category == category,
                    onSelected: (_) => setState(() => _category = category),
                  ),
                ActionChip(
                  label: Text(_ascending ? _t('A–Z', 'А–Я') : _t('Z–A', 'Я–А')),
                  onPressed: () => setState(() => _ascending = !_ascending),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_selected != null) _detail(atlas, _selected!),
            if (visible.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(_t('No matching dishes.', 'Подходящих блюд нет.')),
              ),
            for (final dish in visible)
              Card(
                child: ListTile(
                  key: Key('food-${dish.id}'),
                  title: Text(_name(dish)),
                  subtitle: Text(
                    '${_claim(dish.countryRu, dish.countryEn)} · ${_region(dish)}\n${_claim(dish.summaryRu, dish.summaryEn)}',
                  ),
                  isThreeLine: true,
                  onTap: () => _select(dish),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _detail(FoodAtlas atlas, FoodDish dish) => Card(
    key: const Key('food-detail'),
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _name(dish),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              IconButton(
                tooltip: _t('Close detail', 'Закрыть'),
                onPressed: () => setState(() => _selected = null),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          Text('${_claim(dish.countryRu, dish.countryEn)} · ${_region(dish)}'),
          const SizedBox(height: 8),
          Text(_claim(dish.classicNoteRu, dish.classicNoteEn)),
          _heading(_t('Classic ingredients', 'Классические ингредиенты')),
          Text(_claim(dish.servingsRu, dish.servingsEn)),
          for (final ingredient in dish.ingredients)
            Text(
              '• ${_claim(ingredient.amountRu, ingredient.amountEn)} ${_claim(ingredient.nameRu, ingredient.nameEn)}',
            ),
          _heading(_t('Recipe', 'Рецепт')),
          for (var i = 0; i < dish.steps.length; i++)
            Text(
              '${i + 1}. ${_claim(dish.steps[i].textRu, dish.steps[i].textEn)}',
            ),
          _heading(
            _t(
              'Origin in this reference version',
              'Происхождение в этой справочной версии',
            ),
          ),
          Text(_claim(dish.originRu, dish.originEn)),
          _heading(_t('Facts', 'Факты')),
          for (final fact in dish.facts)
            Text('• ${_claim(fact.textRu, fact.textEn)}'),
          if (dish.variants.isNotEmpty)
            _heading(
              _t('Variants and related dishes', 'Варианты и связанные блюда'),
            ),
          for (final variant in dish.variants)
            Text(
              '• ${_claim(variant.nameRu, variant.nameEn)} — ${_claim(variant.regionRu, variant.regionEn)}: ${_claim(variant.differenceRu, variant.differenceEn)}',
            ),
          _heading(_t('Sources', 'Источники')),
          Wrap(
            spacing: 8,
            children: [
              for (final id in {
                ...dish.sourceIds,
                ...dish.facts.expand((fact) => fact.sourceIds),
                ...dish.variants.expand((variant) => variant.sourceIds),
              })
                TextButton.icon(
                  onPressed: () => launchUrl(
                    Uri.parse(atlas.sourceFor(id).url),
                    mode: LaunchMode.externalApplication,
                  ),
                  icon: const Icon(Icons.open_in_new),
                  label: Text(
                    learningSourceTitle(
                      atlas.sourceFor(id).title,
                      russian: _ru,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    ),
  );
  Widget _heading(String value) => Padding(
    padding: const EdgeInsets.only(top: 14, bottom: 4),
    child: Text(value, style: Theme.of(context).textTheme.titleMedium),
  );

  Widget _practice(FoodAtlas atlas) {
    if (_finished) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_t('Unranked practice', 'Тренировка без рейтинга')),
          leading: BackButton(
            onPressed: () => setState(() => _training = false),
          ),
        ),
        body: _Message(
          title: _reviewing
              ? _t('Mistakes review complete.', 'Повтор ошибок завершён.')
              : _t(
                  'Practice complete: $_score correct of ${_questions.length}.',
                  'Тренировка завершена: $_score из ${_questions.length}.',
                ),
          action: _reviewing || _missed.isEmpty
              ? _t('Start again', 'Начать снова')
              : _t('Retry missed', 'Повторить ошибки'),
          onAction: () => _reviewing || _missed.isEmpty
              ? _start(atlas)
              : _start(atlas, questions: List.of(_missed), reviewing: true),
          extra: Text(
            _t(
              'Original score: ${_firstScore ?? _score} correct.',
              'Первый результат: ${_firstScore ?? _score} верных.',
            ),
            key: const Key('food-score'),
          ),
        ),
      );
    }
    final question = _questions[_index];
    return Scaffold(
      appBar: AppBar(
        title: Text(_t('Unranked practice', 'Тренировка без рейтинга')),
        leading: BackButton(onPressed: () => setState(() => _training = false)),
      ),
      body: SafeArea(
        child: ListView(
          controller: _practiceScroll,
          padding: const EdgeInsets.all(16),
          children: [
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: Text(_t('Mixed', 'Все темы')),
                  selected: _topic == null,
                  onSelected: (_) {
                    setState(() => _topic = null);
                    _start(atlas);
                  },
                ),
                ChoiceChip(
                  label: Text(_t('Origin', 'Происхождение')),
                  selected: _topic == FoodQuestionKind.origin,
                  onSelected: (_) {
                    setState(() => _topic = FoodQuestionKind.origin);
                    _start(atlas);
                  },
                ),
                ChoiceChip(
                  label: Text(_t('Composition', 'Состав')),
                  selected: _topic == FoodQuestionKind.composition,
                  onSelected: (_) {
                    setState(() => _topic = FoodQuestionKind.composition);
                    _start(atlas);
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              _t(
                'Question ${_index + 1} of ${_questions.length}',
                'Вопрос ${_index + 1} из ${_questions.length}',
              ),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            Text(
              _claim(question.promptRu, question.promptEn),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 14),
            for (final option
                in (_ru ? question.optionsRu : question.optionsEn))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: OutlinedButton(
                  onPressed: _checked
                      ? null
                      : () => setState(() => _chosen = option),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: _chosen == option
                        ? Theme.of(context).colorScheme.secondaryContainer
                        : null,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: Text(option),
                ),
              ),
            if (!_checked)
              FilledButton(
                onPressed: _chosen == null ? null : _check,
                child: Text(_t('Check', 'Проверить')),
              ),
            if (_firstScore != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _t(
                    'Original score: $_firstScore correct.',
                    'Первый результат: $_firstScore верных.',
                  ),
                  key: const Key('food-score'),
                ),
              ),
            if (_checked) ...[
              Text(
                _chosen == (_ru ? question.answerRu : question.answerEn)
                    ? _t('Correct.', 'Верно.')
                    : _t('Not quite.', 'Не совсем.'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(_claim(question.explanationRu, question.explanationEn)),
              _heading(_t('Sources', 'Источники')),
              for (final id in question.sourceIds)
                TextButton(
                  onPressed: () => launchUrl(
                    Uri.parse(atlas.sourceFor(id).url),
                    mode: LaunchMode.externalApplication,
                  ),
                  child: Text(
                    learningSourceTitle(
                      atlas.sourceFor(id).title,
                      russian: _ru,
                    ),
                  ),
                ),
              FilledButton(
                onPressed: () {
                  if (!_reviewing && _index + 1 == _questions.length) {
                    _firstScore = _score;
                  }
                  _next();
                },
                child: Text(_t('Next', 'Далее')),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.title,
    required this.action,
    required this.onAction,
    this.extra,
  });
  final String title, action;
  final VoidCallback onAction;
  final Widget? extra;
  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, textAlign: TextAlign.center),
            if (extra != null) ...[const SizedBox(height: 8), extra!],
            const SizedBox(height: 12),
            FilledButton(onPressed: onAction, child: Text(action)),
          ],
        ),
      ),
    ),
  );
}
