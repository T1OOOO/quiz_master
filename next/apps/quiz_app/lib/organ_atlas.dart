library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'organ_atlas_models.dart';

Future<OrganAtlas> loadOrganAtlas([AssetBundle? bundle]) async {
  final raw = await (bundle ?? rootBundle).loadString(organAtlasAsset);
  return OrganAtlas.fromJson(Map<String, dynamic>.from(jsonDecode(raw) as Map));
}

/// The x/y basis scale; Matrix4.getMaxScaleOnAxis also includes the unchanged z
/// basis and therefore cannot tell whether a 2D map has zoomed out.
double organAtlasCameraScale(Matrix4 matrix) => matrix.storage[0].abs();

class OrganAtlasPage extends StatefulWidget {
  const OrganAtlasPage({super.key, this.bundle, this.training = false});
  final AssetBundle? bundle;
  final bool training;
  @override
  State<OrganAtlasPage> createState() => _OrganAtlasPageState();
}

class _OrganAtlasPageState extends State<OrganAtlasPage> {
  late Future<OrganAtlas> _future = _load();
  bool _initialTrainingStarted = false;
  int _originalTotal = 0;
  Future<OrganAtlas> _load() async {
    final atlas = await loadOrganAtlas(widget.bundle);
    if (widget.training && !_initialTrainingStarted) {
      _round = atlas.round(seed: _seed++, count: 10);
      _originalTotal = _round.length;
      _finished = _round.isEmpty;
      _initialTrainingStarted = true;
    }
    return atlas;
  }

  final _search = TextEditingController();
  final _camera = TransformationController();
  String _region = '', _system = '', _kind = '';
  OrganStructure? _selected;
  bool _training = false, _checked = false, _finished = false, _review = false;
  List<OrganQuestion> _round = [], _missed = [];
  int _index = 0, _score = 0, _seed = 31;
  String? _answer;
  @override
  void initState() {
    super.initState();
    _training = widget.training;
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _search.dispose();
    _camera.dispose();
    super.dispose();
  }

  bool get _ru => Localizations.localeOf(context).languageCode == 'ru';
  String _t(String en, String ru) => _ru ? ru : en;
  String _name(OrganStructure item) => _ru ? item.nameRu : item.nameEn;
  String _v(String en, String ru) => _ru ? ru : en;
  void _reset() => setState(() => _camera.value = Matrix4.identity());
  void _zoom(double value) {
    final next = Matrix4.copy(_camera.value)..scaleByDouble(value, value, 1, 1);
    if (organAtlasCameraScale(next) >= .6 && organAtlasCameraScale(next) <= 5) {
      setState(() => _camera.value = next);
    }
  }

  void _select(OrganStructure value) {
    setState(() => _selected = value);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (context) => FractionallySizedBox(
        heightFactor: .78,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
          child: _Detail(item: value, atlas: _loadedAtlas!, russian: _ru),
        ),
      ),
    );
  }

  OrganAtlas? _loadedAtlas;
  void _fit() {
    final width = MediaQuery.sizeOf(context).width - 32;
    final scale = (width / 300).clamp(.6, 1.0);
    setState(
      () => _camera.value = Matrix4.identity()
        ..translateByDouble(
          (width - 300 * scale) / 2,
          (430 - 430 * scale) / 2,
          0,
          1,
        )
        ..scaleByDouble(scale, scale, 1, 1),
    );
  }

  List<OrganStructure> _visible(OrganAtlas atlas) {
    final query = _search.text.trim().toLowerCase();
    return atlas.organs.where((item) {
      final words =
          '${item.nameEn} ${item.nameRu} ${item.functionEn} ${item.functionRu} ${item.systemIds.join(' ')} ${item.kind} ${item.region}'
              .toLowerCase();
      return (_region.isEmpty || item.region == _region) &&
          (_kind.isEmpty || item.kind == _kind) &&
          (_system.isEmpty || item.systemIds.contains(_system)) &&
          words.contains(query);
    }).toList()..sort((a, b) => _name(a).compareTo(_name(b)));
  }

  void _start(
    OrganAtlas atlas,
    List<OrganStructure> visible, {
    List<OrganQuestion>? retry,
  }) => setState(() {
    _round =
        retry ??
        atlas.round(
          seed: _seed++,
          count: 10,
          allowedIds: visible.map((item) => item.id),
        );
    _training = true;
    _index = 0;
    if (retry == null) {
      _score = 0;
      _originalTotal = _round.length;
    }
    _checked = false;
    _finished = _round.isEmpty;
    _answer = null;
    if (retry == null) {
      _missed = [];
      _review = false;
    }
  });
  void _check() => setState(() {
    if (_answer == null || _checked) return;
    _checked = true;
    final q = _round[_index];
    if (_answer == q.correctId && !_review) _score++;
    if (_answer != q.correctId && !_review) _missed.add(q);
  });
  void _next() => setState(() {
    if (_index + 1 >= _round.length) {
      _finished = true;
    } else {
      _index++;
      _checked = false;
      _answer = null;
    }
  });
  @override
  Widget build(BuildContext context) => FutureBuilder<OrganAtlas>(
    future: _future,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return _shell(const Center(child: CircularProgressIndicator()));
      }
      if (snapshot.hasError) {
        return _shell(
          _Notice(
            _t('The atlas could not load.', 'Атлас не удалось загрузить.'),
            _t('Retry', 'Повторить'),
            () => setState(() => _future = _load()),
          ),
        );
      }
      final atlas = snapshot.data!;
      _loadedAtlas = atlas;
      if (atlas.organs.isEmpty) {
        return _shell(
          _Notice(
            _t(
              'No structures are available yet.',
              'Структуры пока не добавлены.',
            ),
            _t('Retry', 'Повторить'),
            () => setState(() => _future = _load()),
          ),
        );
      }
      return _training ? _quiz(atlas) : _browse(atlas);
    },
  );
  Widget _shell(Widget child) => Scaffold(
    appBar: AppBar(
      title: Text(_t('Human organs and glands', 'Атлас органов и желёз')),
    ),
    body: SafeArea(child: child),
  );
  Widget _browse(OrganAtlas atlas) {
    final shown = _visible(atlas);
    final regions = atlas.organs.map((item) => item.region).toSet().toList()
      ..sort();
    final systems =
        atlas.organs.expand((item) => item.systemIds).toSet().toList()..sort();
    final kinds = atlas.organs.map((item) => item.kind).toSet().toList()
      ..sort();
    return Scaffold(
      appBar: AppBar(
        title: Text(_t('Human organs and glands', 'Атлас органов и желёз')),
        actions: [
          TextButton.icon(
            onPressed: () => _start(atlas, shown),
            icon: const Icon(Icons.quiz_outlined),
            label: Text(_t('Practice', 'Тренировка')),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          key: const Key('organ-scroll'),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(_v(atlas.coverageNoteEn, atlas.coverageNoteRu)),
              const SizedBox(height: 8),
              Text(
                _t(
                  'Anterior view: the patient’s right is on your left. Female and male reproductive structures are combined as variants in this overview; paired, deep and distributed structures are approximate schematic layers, not diagnostic anatomy.',
                  'Вид спереди: правая сторона пациента слева от вас. Женские и мужские репродуктивные структуры показаны как варианты в одном обзоре; парные, глубокие и распределённые структуры даны приблизительно, это не диагностическая анатомия.',
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('organ-search'),
                controller: _search,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  border: const OutlineInputBorder(),
                  labelText: _t(
                    'Search organs, glands and systems',
                    'Поиск органов, желёз и систем',
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ExpansionTile(
                key: const Key('organ-filters'),
                title: Text(
                  _t(
                    'Filter by region, system or type',
                    'Фильтры: область, система, тип',
                  ),
                ),
                tilePadding: EdgeInsets.zero,
                children: [
                  _Filters(
                    label: _t('Region', 'Область'),
                    values: regions,
                    selected: _region,
                    onChanged: (v) => setState(() => _region = v),
                  ),
                  _Filters(
                    label: _t('System', 'Система'),
                    values: systems,
                    selected: _system,
                    onChanged: (v) => setState(() => _system = v),
                  ),
                  _Filters(
                    label: _t('Type', 'Тип'),
                    values: kinds,
                    selected: _kind,
                    onChanged: (v) => setState(() => _kind = v),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _BodyMap(
                controller: _camera,
                organs: shown,
                selected: _selected,
                name: _name,
                onSelected: _select,
              ),
              Wrap(
                children: [
                  IconButton(
                    tooltip: _t('Zoom in', 'Увеличить'),
                    icon: const Icon(Icons.add),
                    onPressed: () => _zoom(1.25),
                  ),
                  IconButton(
                    tooltip: _t('Zoom out', 'Уменьшить'),
                    icon: const Icon(Icons.remove),
                    onPressed: () => _zoom(.8),
                  ),
                  TextButton.icon(
                    onPressed: _fit,
                    icon: const Icon(Icons.center_focus_strong),
                    label: Text(_t('Fit', 'Вписать')),
                  ),
                  TextButton.icon(
                    onPressed: _reset,
                    icon: const Icon(Icons.replay),
                    label: Text(_t('Reset', 'Сбросить')),
                  ),
                ],
              ),
              Text(
                _t(
                  'Pinch to zoom and drag the diagram. Selecting a structure never moves the camera.',
                  'Масштабируйте щипком и перетаскивайте схему. Выбор структуры не меняет камеру.',
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              Text(
                _t('Accessible list', 'Доступный список'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (shown.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    _t('No matching structures.', 'Нет подходящих структур.'),
                  ),
                ),
              for (final item in shown)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: OutlinedButton(
                    key: Key('organ-list-${item.id}'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(44, 48),
                      alignment: Alignment.centerLeft,
                      backgroundColor: _selected?.id == item.id
                          ? Theme.of(context).colorScheme.secondaryContainer
                          : null,
                    ),
                    onPressed: () => _select(item),
                    child: Text(_name(item)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quiz(OrganAtlas atlas) {
    if (_finished || _round.isEmpty) {
      return _shell(
        Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _round.isEmpty
                      ? _t(
                          'No fair questions match these filters.',
                          'Нет подходящих вопросов для этих фильтров.',
                        )
                      : '${_t('Original score', 'Исходный результат')}: $_score/$_originalTotal',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (_missed.isNotEmpty && !_review)
                  FilledButton(
                    onPressed: () {
                      setState(() => _review = true);
                      _start(atlas, const [], retry: _missed);
                    },
                    child: Text(
                      _t(
                        'Review mistakes (${_missed.length})',
                        'Разобрать ошибки (${_missed.length})',
                      ),
                    ),
                  ),
                TextButton(
                  onPressed: () => setState(() => _training = false),
                  child: Text(_t('Back to atlas', 'Вернуться к атласу')),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final question = _round[_index];
    final options = question.optionIds.map(atlas.organ).toList();
    return _shell(
      SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _t(
                'Local unranked practice · ${_index + 1}/${_round.length}',
                'Локальная тренировка без рейтинга · ${_index + 1}/${_round.length}',
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _v(question.stemEn, question.stemRu),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            for (final item in options)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: OutlinedButton(
                  key: Key('organ-option-${item.id}'),
                  onPressed: _checked
                      ? null
                      : () => setState(() => _answer = item.id),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(44, 48),
                    backgroundColor: _answer == item.id
                        ? Theme.of(context).colorScheme.secondaryContainer
                        : null,
                  ),
                  child: Text(_name(item)),
                ),
              ),
            if (!_checked)
              FilledButton(
                key: const Key('organ-check'),
                onPressed: _answer == null ? null : _check,
                child: Text(_t('Check', 'Проверить')),
              ),
            if (_checked) ...[
              Text(
                _answer == question.correctId
                    ? _t('Correct.', 'Верно.')
                    : _t('Not quite.', 'Не совсем.'),
              ),
              Text(_v(question.explanationEn, question.explanationRu)),
              for (final source in question.sourceIds)
                Text(
                  '${_t('Source', 'Источник')}: ${atlas.source(source).title}',
                ),
              FilledButton(
                key: const Key('organ-next'),
                onPressed: _next,
                child: Text(_t('Next', 'Далее')),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters({
    required this.label,
    required this.values,
    required this.selected,
    required this.onChanged,
  });
  final String label, selected;
  final List<String> values;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        Text('$label:'),
        ChoiceChip(
          label: Text(
            Localizations.localeOf(context).languageCode == 'ru'
                ? 'Все'
                : 'All',
          ),
          selected: selected.isEmpty,
          onSelected: (_) => onChanged(''),
        ),
        for (final value in values)
          ChoiceChip(
            label: Text(_filterLabel(context, value)),
            selected: selected == value,
            onSelected: (_) => onChanged(value),
          ),
      ],
    ),
  );
}

String _filterLabel(BuildContext context, String value) {
  final ru = Localizations.localeOf(context).languageCode == 'ru';
  const en = {
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
  };
  const russian = {
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
    'nervous': 'Нервная',
    'endocrine': 'Эндокринная',
    'digestive': 'Пищеварительная',
    'respiratory': 'Дыхательная',
    'cardiovascular': 'Сердечно-сосудистая',
    'urinary': 'Мочевая',
    'reproductive': 'Репродуктивная',
    'lymphatic': 'Лимфатическая',
    'integumentary': 'Покровная',
    'sensory': 'Органы чувств',
    'musculoskeletal': 'Опорно-двигательная',
  };
  return (ru ? russian : en)[value] ?? value.replaceAll('_', ' ');
}

class _Notice extends StatelessWidget {
  const _Notice(this.title, this.action, this.onAction);
  final String title, action;
  final VoidCallback onAction;
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title),
        TextButton(onPressed: onAction, child: Text(action)),
      ],
    ),
  );
}

class _BodyMap extends StatefulWidget {
  const _BodyMap({
    required this.controller,
    required this.organs,
    required this.selected,
    required this.name,
    required this.onSelected,
  });
  final TransformationController controller;
  final List<OrganStructure> organs;
  final OrganStructure? selected;
  final String Function(OrganStructure) name;
  final ValueChanged<OrganStructure> onSelected;
  @override
  State<_BodyMap> createState() => _BodyMapState();
}

class _BodyMapState extends State<_BodyMap> {
  int _page = 0;
  @override
  void didUpdateWidget(covariant _BodyMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.organs.map((e) => e.id).join(',') !=
        widget.organs.map((e) => e.id).join(',')) {
      _page = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ru = Localizations.localeOf(context).languageCode == 'ru';
    final count = (widget.organs.length / 8).ceil();
    final page = widget.organs.skip(_page * 8).take(8).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          ru
              ? 'Выберите орган на схеме или подпись под ней'
              : 'Select an organ on the diagram or a callout below',
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 430,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: ColoredBox(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              child: InteractiveViewer(
                key: const Key('organ-map'),
                transformationController: widget.controller,
                minScale: .6,
                maxScale: 5,
                constrained: false,
                boundaryMargin: const EdgeInsets.all(120),
                child: SizedBox(
                  width: 300,
                  height: 430,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapUp: (details) {
                      final point = details.localPosition;
                      final boxes = <String, Rect>{
                        'brain': const Rect.fromLTWH(119, 32, 62, 43),
                        'heart': const Rect.fromLTWH(148, 151, 40, 57),
                        'stomach': const Rect.fromLTWH(165, 260, 42, 52),
                        'liver': const Rect.fromLTWH(82, 225, 80, 40),
                        'kidneys': const Rect.fromLTWH(103, 279, 31, 46),
                        'bladder': const Rect.fromLTWH(130, 340, 40, 31),
                        'lungs': const Rect.fromLTWH(92, 128, 115, 92),
                      };
                      for (final entry in boxes.entries) {
                        final organ = widget.organs
                            .where((o) => o.id == entry.key)
                            .firstOrNull;
                        if (organ != null &&
                            (entry.value.contains(point) ||
                                (entry.key == 'kidneys' &&
                                    const Rect.fromLTWH(
                                      165,
                                      278,
                                      32,
                                      48,
                                    ).contains(point)))) {
                          widget.onSelected(organ);
                          return;
                        }
                      }
                    },
                    child: Stack(
                      children: [
                        CustomPaint(
                          size: const Size(300, 430),
                          painter: _BodyPainter(
                            widget.organs,
                            widget.selected?.id,
                            Theme.of(context).colorScheme,
                          ),
                        ),
                        CustomPaint(
                          size: const Size(300, 430),
                          painter: _CalloutPainter(
                            page,
                            Theme.of(context).colorScheme,
                          ),
                        ),
                        for (var i = 0; i < page.length; i++)
                          Positioned(
                            left: i.isEven ? 0 : 252,
                            top: 20 + (i ~/ 2) * 95.0,
                            width: 48,
                            height: 44,
                            child: Tooltip(
                              message: widget.name(page[i]),
                              child: FilledButton(
                                key: Key('organ-map-target-${page[i].id}'),
                                style: FilledButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                ),
                                onPressed: () => widget.onSelected(page[i]),
                                child: Text('${_page * 8 + i + 1}'),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (count > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                key: const Key('organ-callouts-previous'),
                tooltip: ru ? 'Предыдущие подписи' : 'Previous callouts',
                onPressed: _page > 0 ? () => setState(() => _page--) : null,
                icon: const Icon(Icons.chevron_left),
              ),
              Text('${_page + 1} / $count'),
              IconButton(
                key: const Key('organ-callouts-next'),
                tooltip: ru ? 'Следующие подписи' : 'Next callouts',
                onPressed: _page + 1 < count
                    ? () => setState(() => _page++)
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        for (var i = 0; i < page.length; i++)
          TextButton(
            key: Key('organ-callout-${page[i].id}'),
            style: TextButton.styleFrom(
              alignment: Alignment.centerLeft,
              minimumSize: const Size(44, 44),
            ),
            onPressed: () => widget.onSelected(page[i]),
            child: Text(
              '${_page * 8 + i + 1}. ${widget.name(page[i])} · ${_filterLabel(context, page[i].region)}',
            ),
          ),
      ],
    );
  }
}

Offset _organAnchor(OrganStructure organ) {
  const points = <String, Offset>{
    'brain': Offset(150, 53),
    'heart': Offset(169, 179),
    'lungs': Offset(120, 170),
    'liver': Offset(120, 245),
    'stomach': Offset(185, 280),
    'kidneys': Offset(118, 301),
    'bladder': Offset(150, 356),
  };
  return points[organ.id] ??
      Offset(
        150,
        switch (organ.region) {
          'head' => 60,
          'neck' => 105,
          'thorax' => 170,
          'abdomen' => 255,
          'pelvis' => 345,
          _ => 390,
        }.toDouble(),
      );
}

class _CalloutPainter extends CustomPainter {
  const _CalloutPainter(this.organs, this.colors);
  final List<OrganStructure> organs;
  final ColorScheme colors;
  @override
  void paint(Canvas canvas, Size size) {
    final pen = Paint()
      ..color = colors.outline
      ..strokeWidth = 1;
    for (var i = 0; i < organs.length; i++) {
      final target = _organAnchor(organs[i]);
      final start = Offset(i.isEven ? 48 : 252, 42 + (i ~/ 2) * 95.0);
      canvas.drawLine(start, target, pen);
      canvas.drawCircle(target, 3, Paint()..color = colors.onSurface);
    }
  }

  @override
  bool shouldRepaint(covariant _CalloutPainter old) =>
      old.organs != organs || old.colors != colors;
}

class _BodyPainter extends CustomPainter {
  const _BodyPainter(this.organs, this.selected, this.colors);
  final List<OrganStructure> organs;
  final String? selected;
  final ColorScheme colors;
  @override
  void paint(Canvas canvas, Size size) {
    final body = Paint()..color = colors.surfaceContainerHighest;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(106, 10, 88, 105),
        const Radius.circular(44),
      ),
      body,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(72, 95, 156, 280),
        const Radius.circular(62),
      ),
      body,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(46, 115, 35, 210),
        const Radius.circular(20),
      ),
      body,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(219, 115, 35, 210),
        const Radius.circular(20),
      ),
      body,
    );
    final shapes = <String, Path>{};
    Path p() => Path();
    shapes['brain'] = p()..addOval(const Rect.fromLTWH(119, 32, 62, 43));
    shapes['heart'] = p()
      ..moveTo(164, 166)
      ..cubicTo(124, 128, 123, 190, 169, 211)
      ..cubicTo(215, 190, 214, 128, 174, 166)
      ..close();
    shapes['lungs'] = p()
      ..addOval(const Rect.fromLTWH(92, 128, 56, 92))
      ..addOval(const Rect.fromLTWH(153, 128, 56, 92));
    shapes['liver'] = p()
      ..addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(82, 225, 105, 43),
          const Radius.circular(18),
        ),
      );
    shapes['stomach'] = p()..addOval(const Rect.fromLTWH(165, 247, 42, 65));
    shapes['kidneys'] = p()
      ..addOval(const Rect.fromLTWH(103, 278, 32, 48))
      ..addOval(const Rect.fromLTWH(165, 278, 32, 48));
    shapes['bladder'] = p()..addOval(const Rect.fromLTWH(130, 340, 40, 31));
    // Enlarged teaching silhouettes; the written card gives the actual position.
    shapes['thyroid'] = p()
      ..moveTo(150, 102)
      ..cubicTo(133, 87, 128, 104, 139, 118)
      ..lineTo(148, 111)
      ..lineTo(152, 111)
      ..lineTo(161, 118)
      ..cubicTo(172, 104, 167, 87, 150, 102)
      ..close();
    shapes['parathyroids'] = p()
      ..addOval(const Rect.fromLTWH(137, 100, 5, 5))
      ..addOval(const Rect.fromLTWH(137, 110, 5, 5))
      ..addOval(const Rect.fromLTWH(158, 100, 5, 5))
      ..addOval(const Rect.fromLTWH(158, 110, 5, 5));
    shapes['adrenals'] = p()
      ..moveTo(103, 274)
      ..lineTo(120, 263)
      ..lineTo(136, 274)
      ..close()
      ..moveTo(164, 274)
      ..quadraticBezierTo(180, 258, 197, 274)
      ..close();
    shapes['pancreas'] = p()
      ..moveTo(121, 265)
      ..cubicTo(136, 255, 164, 266, 187, 260)
      ..quadraticBezierTo(204, 269, 186, 276)
      ..cubicTo(164, 279, 141, 270, 124, 279)
      ..quadraticBezierTo(115, 273, 121, 265)
      ..close();
    shapes['thymus'] = p()
      ..addOval(const Rect.fromLTWH(140, 124, 10, 29))
      ..addOval(const Rect.fromLTWH(151, 124, 10, 29));

    const depth = {
      'pancreas': -1,
      'adrenals': -1,
      'thyroid': 7,
      'parathyroids': 8,
      'thymus': 1,
      'lungs': 0,
      'kidneys': 1,
      'liver': 2,
      'stomach': 3,
      'bladder': 4,
      'brain': 5,
      'heart': 6,
    };
    final ordered = [...organs]
      ..sort(
        (a, b) => (a.id == selected ? 100 : depth[a.id] ?? 10).compareTo(
          b.id == selected ? 100 : depth[b.id] ?? 10,
        ),
      );
    const organColors = {
      'heart': Color(0xffda7978),
      'lungs': Color(0xff82b9d4),
      'brain': Color(0xffd4a6c5),
      'liver': Color(0xffb78468),
      'stomach': Color(0xffe5b88a),
      'kidneys': Color(0xffac91c8),
      'bladder': Color(0xffddc578),
    };
    for (final organ in ordered) {
      if (organ.region == 'distributed') continue;
      final key = organ.id.toLowerCase();
      Path? shape;
      for (final entry in shapes.entries) {
        if (key.contains(entry.key) ||
            (entry.key == 'lungs' &&
                (key.contains('lung') || key.contains('bronch')))) {
          shape = entry.value;
          break;
        }
      }
      if (shape == null && organ.id != selected) continue;
      shape ??= _regionMark(organ.region);
      final paint = Paint()
        ..color = organ.id == selected
            ? colors.primary
            : organColors[organ.id] ?? _colorFor(organ.kind, colors);
      canvas.drawPath(shape, paint);
      canvas.drawPath(
        shape,
        Paint()
          ..color = colors.onSurface.withValues(alpha: .55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
  }

  Path _regionMark(String region) {
    if (region == 'distributed') {
      return Path()..addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(78, 102, 144, 267),
          const Radius.circular(58),
        ),
      );
    }
    final y = switch (region) {
      'head' => 60,
      'neck' => 105,
      'thorax' => 170,
      'abdomen' => 255,
      'pelvis' => 345,
      _ => 395,
    };
    return Path()
      ..addOval(Rect.fromCircle(center: Offset(150, y.toDouble()), radius: 7));
  }

  Color _colorFor(String kind, ColorScheme c) => switch (kind) {
    'endocrine_gland' => c.tertiary,
    'exocrine_gland' => c.secondary,
    'mixed_gland' => c.primaryContainer,
    'gland_group' => c.tertiaryContainer,
    _ => c.secondaryContainer,
  };
  @override
  bool shouldRepaint(covariant _BodyPainter old) =>
      old.organs != organs || old.selected != selected || old.colors != colors;
}

class _Detail extends StatelessWidget {
  const _Detail({
    required this.item,
    required this.atlas,
    required this.russian,
  });
  final OrganStructure item;
  final OrganAtlas atlas;
  final bool russian;
  String v(String en, String ru) => russian ? ru : en;
  @override
  Widget build(BuildContext context) => Card(
    key: const Key('organ-detail'),
    margin: const EdgeInsets.only(top: 16),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            v(item.nameEn, item.nameRu),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Text(
            '${v('Position', 'Положение')}: ${v(item.positionEn, item.positionRu)}',
          ),
          Text(
            '${v('Function', 'Функция')}: ${v(item.functionEn, item.functionRu)}',
          ),
          if (item.secretionsEn.isNotEmpty)
            Text(
              '${v('Secretions', 'Секреции')}: ${(russian ? item.secretionsRu : item.secretionsEn).join(', ')}',
            ),
          for (final fact in item.facts)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('• ${v(fact.textEn, fact.textRu)}'),
            ),
          if (v(item.noteEn, item.noteRu).isNotEmpty)
            Text('${v('Note', 'Примечание')}: ${v(item.noteEn, item.noteRu)}'),
          for (final id in item.sourceIds)
            TextButton.icon(
              onPressed: () => launchUrl(
                Uri.parse(atlas.source(id).url),
                mode: LaunchMode.externalApplication,
              ),
              icon: const Icon(Icons.open_in_new),
              label: Text(
                '${v('Source', 'Источник')}: ${atlas.source(id).title}',
              ),
            ),
        ],
      ),
    ),
  );
}
