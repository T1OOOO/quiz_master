library;

import 'fact_practice.dart';

import 'russian_learning_text.dart';

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'organ_atlas_models.dart';
import 'map_interaction.dart';

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
  String _v(String en, String ru) => _ru ? russianLearningText(ru) : en;
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
  List<OrganStructure> _visible(OrganAtlas atlas) {
    final query = _search.text.trim().toLowerCase();
    return atlas.organs.where((item) {
      final words =
          '${item.nameEn} ${item.nameRu} ${item.nameLa ?? ''} ${item.functionEn} ${item.functionRu} ${item.systemIds.join(' ')} ${item.kind} ${item.region}'
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
  }) {
    final round =
        retry ??
        atlas.round(
          seed: _seed++,
          count: 10,
          allowedIds: visible.map((item) => item.id),
        );
    if (retry == null && round.isEmpty && visible.isNotEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => FactPracticePage(
            scope: 'organs',
            bundle: widget.bundle,
            entityIds: visible.map((item) => item.id).toSet(),
          ),
        ),
      );
      return;
    }
    setState(() {
      _round = round;
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
  }

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
    final searching =
        _search.text.trim().isNotEmpty ||
        _region.isNotEmpty ||
        _system.isNotEmpty ||
        _kind.isNotEmpty;
    final rows = [
      for (final item in shown)
        ListTile(
          key: Key('organ-list-${item.id}'),
          title: Text(_name(item)),
          subtitle: Text(_filterLabel(context, item.kind)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _select(item),
        ),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(_t('Human anatomy', 'Органы и системы')),
        actions: [
          FactPracticeAction(scope: 'organs', bundle: widget.bundle),
          IconButton(
            tooltip: _t('Anatomy questions', 'Вопросы об органах'),
            onPressed: () => _start(atlas, shown),
            icon: const Icon(Icons.quiz_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: MapScrollView(
          key: const Key('organ-scroll'),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _BodyMap(
                controller: _camera,
                organs: shown,
                selected: _selected,
                name: _name,
                onSelected: _select,
              ),
              Wrap(
                alignment: WrapAlignment.center,
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
                    onPressed: _reset,
                    icon: const Icon(Icons.center_focus_strong),
                    label: Text(_t('Fit', 'Вся схема')),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('organ-search'),
                controller: _search,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  labelText: _t(
                    'Search organs, glands and bones',
                    'Найти орган, железу или кость',
                  ),
                ),
              ),
              ExpansionTile(
                key: const Key('organ-filters'),
                title: Text(_t('Filters', 'Фильтры')),
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
              if (shown.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _t('No matching structures.', 'Ничего не найдено.'),
                  ),
                ),
              if (searching)
                ...rows
              else
                ExpansionTile(
                  key: const Key('organ-directory'),
                  title: Text(_t('All structures', 'Все структуры')),
                  subtitle: Text(
                    _t(
                      'Organs, glands, bones and brain regions',
                      'Органы, железы, кости и отделы мозга',
                    ),
                  ),
                  trailing: Text('${shown.length}'),
                  children: rows,
                ),
              TextButton.icon(
                icon: const Icon(Icons.info_outline),
                label: Text(_t('About the diagram', 'О схеме и источниках')),
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(_t('About this atlas', 'О схеме')),
                    content: Text(
                      _v(atlas.coverageNoteEn, atlas.coverageNoteRu),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(_t('Close', 'Закрыть')),
                      ),
                    ],
                  ),
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
                    disabledForegroundColor: Theme.of(context)
                        .colorScheme
                        .onSurface,
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
                  '${_t('Source', 'Источник')}: ${learningSourceTitle(atlas.source(source).title, russian: _ru)}',
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
    'upper_limb': 'Upper limb',
    'lower_limb': 'Lower limb',
    'spine': 'Spine',
    'organ': 'Organ',
    'endocrine_gland': 'Endocrine gland',
    'exocrine_gland': 'Exocrine gland',
    'mixed_gland': 'Mixed gland',
    'gland_group': 'Gland group',
    'endocrine_tissue': 'Endocrine tissue',
    'bone_group': 'Bone group',
    'bone': 'Bone',
    'brain_region': 'Brain region',
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
    'upper_limb': 'Верхняя конечность',
    'lower_limb': 'Нижняя конечность',
    'spine': 'Позвоночник',
    'organ': 'Орган',
    'endocrine_gland': 'Эндокринная железа',
    'exocrine_gland': 'Экзокринная железа',
    'mixed_gland': 'Смешанная железа',
    'gland_group': 'Группа желёз',
    'endocrine_tissue': 'Эндокринная ткань',
    'bone_group': 'Группа костей',
    'bone': 'Кость',
    'brain_region': 'Отдел мозга',
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
  // Positions refer to the visible organs in the anterior overview image.
  static const _illustratedAnchors = <String, Offset>{
    'brain': Offset(150, 28),
    'thyroid': Offset(150, 118),
    'lungs': Offset(112, 172),
    'heart': Offset(165, 195),
    'liver': Offset(120, 234),
    'stomach': Offset(177, 250),
  };
  @override
  Widget build(BuildContext context) {
    final ru = Localizations.localeOf(context).languageCode == 'ru';
    final targets = [
      for (final id in _illustratedAnchors.keys)
        ...widget.organs.where((item) => item.id == id),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          ru
              ? 'Нажмите на орган на схеме или выберите его название.'
              : 'Tap an organ on the diagram or choose its name.',
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: (MediaQuery.sizeOf(context).height * .55).clamp(300.0, 450.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: LayoutBuilder(
              builder: (context, box) {
                final scale = (box.maxWidth / 300).clamp(
                  0.0,
                  box.maxHeight / 450,
                );
                final left = (box.maxWidth - 300 * scale) / 2;
                final top = (box.maxHeight - 450 * scale) / 2;
                // Keep raw touch coordinates on Web; named accessible controls are below.
                return Semantics(
                  label: ru
                      ? 'Схема органов: вид спереди'
                      : 'Anterior organ overview',
                  child: ExcludeSemantics(
                    child: MapInteraction(
                      child: InteractiveViewer(
                        key: const Key('organ-map'),
                        transformationController: widget.controller,
                        minScale: .6,
                        maxScale: 5,
                        boundaryMargin: const EdgeInsets.all(120),
                        child: SizedBox(
                          width: box.maxWidth,
                          height: box.maxHeight,
                          child: Stack(
                            children: [
                              Positioned(
                                left: left,
                                top: top,
                                width: 300 * scale,
                                height: 450 * scale,
                                child: Image.asset(
                                  'assets/quizipedia/anatomy-orientation.png',
                                  fit: BoxFit.contain,
                                  semanticLabel: ru
                                      ? 'Схема органов: вид спереди'
                                      : 'Anterior organ overview',
                                ),
                              ),
                              for (var i = 0; i < targets.length; i++)
                                Positioned(
                                  left:
                                      left +
                                      _illustratedAnchors[targets[i].id]!.dx *
                                          scale -
                                      22,
                                  top:
                                      top +
                                      _illustratedAnchors[targets[i].id]!.dy *
                                          scale -
                                      22,
                                  width: 44,
                                  height: 44,
                                  child: Tooltip(
                                    message: widget.name(targets[i]),
                                    child: Semantics(
                                      label: widget.name(targets[i]),
                                      child: IconButton(
                                        key: Key(
                                          'organ-map-target-${targets[i].id}',
                                        ),
                                        onPressed: () =>
                                            widget.onSelected(targets[i]),
                                        padding: EdgeInsets.zero,
                                        icon: Container(
                                          width: 24,
                                          height: 24,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primaryContainer,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                            ),
                                          ),
                                          child: Text(
                                            '${i + 1}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onPrimaryContainer,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            for (var i = 0; i < targets.length; i++)
              TextButton(
                key: Key('organ-map-card-${targets[i].id}'),
                onPressed: () => widget.onSelected(targets[i]),
                child: Text('${i + 1}. ${widget.name(targets[i])}'),
              ),
          ],
        ),
        if (widget.selected != null &&
            !_illustratedAnchors.containsKey(widget.selected!.id))
          Text(
            ru
                ? '${widget.name(widget.selected!)}: расположение и функции — в карточке ниже.'
                : '${widget.name(widget.selected!)}: see the card for location and function.',
          ),
      ],
    );
  }
}

// Retained as a fallback sketch for future non-illustrated anatomy views.
// ignore: unused_element
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
  String v(String en, String ru) => russian ? russianLearningText(ru) : en;
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
          if (item.nameLa != null)
            ExpansionTile(
              key: const Key('organ-latin-name'),
              tilePadding: EdgeInsets.zero,
              title: Text(v('Latin name', 'Латинское название')),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(item.nameLa!),
                ),
              ],
            ),
          if (item.boneCount != null)
            Text(
              v(
                'Bones in group: ${item.boneCount}',
                'Костей в группе: ${item.boneCount}',
              ),
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
                '${v('Source', 'Источник')}: ${learningSourceTitle(atlas.source(id).title, russian: russian)}',
              ),
            ),
        ],
      ),
    ),
  );
}
