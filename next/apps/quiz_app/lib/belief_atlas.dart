library;

import 'russian_learning_text.dart';

import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'belief_atlas_models.dart';

class BeliefAtlasPage extends StatefulWidget {
  const BeliefAtlasPage({
    super.key,
    this.bundle,
    this.initialSection = 'greek',
  });
  final AssetBundle? bundle;
  final String initialSection;
  @override
  State<BeliefAtlasPage> createState() => _BeliefAtlasPageState();
}

class _BeliefAtlasPageState extends State<BeliefAtlasPage> {
  final _search = TextEditingController(),
      _transform = TransformationController();
  BeliefAtlas? _atlas;
  Object? _error;
  String _section = 'greek', _selected = '';
  bool _full = false, _loading = true;
  @override
  void initState() {
    super.initState();
    _section = widget.initialSection == 'religions' ? 'religions' : 'greek';
    _search.addListener(() => setState(() {}));
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final text = await (widget.bundle ?? rootBundle).loadString(
        beliefAtlasAsset,
      );
      final a = BeliefAtlas.fromJson(jsonDecode(text) as Map<String, dynamic>);
      if (mounted) {
        setState(() {
          _atlas = a;
          final sectionNodes = a.nodes.where((n) => n.section == _section);
          _selected = sectionNodes.isEmpty ? '' : sectionNodes.first.id;
          _error = null;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e;
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _search.dispose();
    _transform.dispose();
    super.dispose();
  }

  bool get _ru => Localizations.localeOf(context).languageCode == 'ru';
  String _t(String en, String ru) => _ru ? ru : en;
  String _name(BeliefNode n) => _ru ? n.ru : n.en;
  String _v(String en, String ru) => _ru ? russianLearningText(ru) : en;
  List<BeliefNode> get _nodes =>
      _atlas!.nodes.where((n) => n.section == _section).toList();
  BeliefNode get _node => _atlas!.nodes.firstWhere((n) => n.id == _selected);
  List<BeliefEdge> get _edges => _atlas!.edges
      .where(
        (e) =>
            _nodes.any((n) => n.id == e.from) &&
            _nodes.any((n) => n.id == e.to),
      )
      .toList();
  int get _shownCount => _full
      ? _nodes.length
      : _nodes
            .where(
              (n) =>
                  n.id == _selected ||
                  _edges.any((e) => e.from == _selected && e.to == n.id) ||
                  _edges.any((e) => e.to == _selected && e.from == n.id),
            )
            .length;
  void _choose(String id) {
    setState(() => _selected = id);
  }

  void _zoom(double f) {
    final scene = _transform.toScene(const Offset(160, 140));
    final m = Matrix4.copy(_transform.value)
      ..translateByDouble(scene.dx, scene.dy, 0, 1)
      ..scaleByDouble(f, f, 1, 1)
      ..translateByDouble(-scene.dx, -scene.dy, 0, 1);
    if (m.entry(0, 0) >= .25 && m.entry(0, 0) <= 5) {
      setState(() => _transform.value = m);
    }
  }

  void _fit() {
    final rows = max(1, (_shownCount / 3).ceil());
    final sceneHeight = max(280.0, rows * 110.0 + 80);
    final viewportWidth = MediaQuery.sizeOf(context).width - 32;
    final sceneWidth = max(520.0, MediaQuery.sizeOf(context).width);
    final scale = min(
      viewportWidth / sceneWidth,
      280 / sceneHeight,
    ).clamp(.25, 1.0);
    final matrix = Matrix4.identity()..scaleByDouble(scale, scale, 1, 1);
    setState(() => _transform.value = matrix);
  }

  @override
  Widget build(BuildContext c) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(_t('Belief atlas', 'Атлас верований'))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: Text(_t('Belief atlas', 'Атлас верований'))),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _t('Could not load the atlas.', 'Не удалось загрузить атлас.'),
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
    final a = _atlas!;
    if (_nodes.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(_t('Belief atlas', 'Атлас верований'))),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _t(
                  'No entries in this section.',
                  'В этом разделе пока нет записей.',
                ),
              ),
              for (final section in ['greek', 'religions'])
                if (section != _section &&
                    a.nodes.any((n) => n.section == section))
                  TextButton(
                    onPressed: () => setState(() {
                      _section = section;
                      _selected = a.nodes
                          .firstWhere((n) => n.section == section)
                          .id;
                    }),
                    child: Text(
                      section == 'greek'
                          ? _t('Greek gods', 'Греческие боги')
                          : _t('Religions', 'Религии'),
                    ),
                  ),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(_t('Belief atlas', 'Атлас верований'))),
      body: SafeArea(
        child: SingleChildScrollView(
          key: const Key('belief-scroll'),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _t('Explore · local unranked', 'Изучение · без рейтинга'),
                style: Theme.of(c).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(
                    value: 'greek',
                    label: Text(_t('Greek gods', 'Греческие боги')),
                  ),
                  ButtonSegment(
                    value: 'religions',
                    label: Text(_t('Religions', 'Религии')),
                  ),
                ],
                selected: {_section},
                onSelectionChanged: (v) => setState(() {
                  _section = v.first;
                  final first = a.nodes.where((n) => n.section == _section);
                  _selected = first.isEmpty ? '' : first.first.id;
                  _full = false;
                }),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('belief-search'),
                controller: _search,
                decoration: InputDecoration(
                  labelText: _t(
                    'Find a person or tradition',
                    'Найти персонажа или традицию',
                  ),
                  prefixIcon: const Icon(Icons.search),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              _Graph(
                controller: _transform,
                nodes: _nodes,
                edges: _edges,
                selected: _selected,
                full: _full,
                name: _name,
                russian: _ru,
                onTap: _choose,
              ),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  IconButton(
                    tooltip: _t('Zoom in', 'Увеличить'),
                    onPressed: () => _zoom(1.3),
                    icon: const Icon(Icons.add),
                  ),
                  IconButton(
                    tooltip: _t('Zoom out', 'Уменьшить'),
                    onPressed: () => _zoom(1 / 1.3),
                    icon: const Icon(Icons.remove),
                  ),
                  TextButton.icon(
                    key: const Key('belief-fit'),
                    onPressed: _fit,
                    icon: const Icon(Icons.fit_screen),
                    label: Text(_t('Fit', 'Вписать')),
                  ),
                  TextButton.icon(
                    onPressed: () =>
                        setState(() => _transform.value = Matrix4.identity()),
                    icon: const Icon(Icons.replay),
                    label: Text(_t('Reset', 'Сбросить')),
                  ),
                  FilterChip(
                    label: Text(_t('Full graph', 'Весь граф')),
                    selected: _full,
                    onSelected: (v) => setState(() => _full = v),
                  ),
                ],
              ),
              Text(
                _t(
                  'Pinch to zoom and drag the graph. Choosing a node never changes your view.',
                  'Масштабируйте щипком и перетаскивайте граф. Выбор узла не меняет вид.',
                ),
                style: Theme.of(c).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              Text(
                _t('Accessible list', 'Доступный список'),
                style: Theme.of(c).textTheme.titleMedium,
              ),
              _NodeList(
                nodes: _nodes
                    .where(
                      (n) => '${n.en} ${n.ru}'.toLowerCase().contains(
                        _search.text.toLowerCase(),
                      ),
                    )
                    .toList(),
                selected: _selected,
                name: _name,
                onTap: _choose,
              ),
              const SizedBox(height: 12),
              _Detail(node: _node, atlas: a, ru: _ru, onTap: _choose),
              const SizedBox(height: 12),
              if (a.round(_section).isEmpty)
                Text(
                  _t(
                    'No quiz questions in this section yet.',
                    'В этом разделе пока нет вопросов.',
                  ),
                )
              else
                FilledButton.icon(
                  key: const Key('belief-quiz'),
                  onPressed: () => Navigator.of(c).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          _BeliefQuiz(atlas: a, section: _section, ru: _ru),
                    ),
                  ),
                  icon: const Icon(Icons.play_arrow),
                  label: Text(
                    _t('Start local quiz', 'Начать локальную викторину'),
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                _v(a.coverageEn, a.coverageRu),
                style: Theme.of(c).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NodeList extends StatelessWidget {
  const _NodeList({
    required this.nodes,
    required this.selected,
    required this.name,
    required this.onTap,
  });
  final List<BeliefNode> nodes;
  final String selected;
  final String Function(BeliefNode) name;
  final ValueChanged<String> onTap;
  @override
  Widget build(BuildContext c) => nodes.isEmpty
      ? Text(
          Localizations.localeOf(c).languageCode == 'ru'
              ? 'Нет совпадений'
              : 'No matches',
        )
      : Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final n in nodes)
              OutlinedButton(
                key: Key('belief-list-${n.id}'),
                onPressed: () => onTap(n.id),
                style: OutlinedButton.styleFrom(
                  backgroundColor: n.id == selected
                      ? Theme.of(c).colorScheme.secondaryContainer
                      : null,
                ),
                child: Text(name(n)),
              ),
          ],
        );
}

class _Graph extends StatelessWidget {
  const _Graph({
    required this.controller,
    required this.nodes,
    required this.edges,
    required this.selected,
    required this.full,
    required this.name,
    required this.russian,
    required this.onTap,
  });
  final TransformationController controller;
  final List<BeliefNode> nodes;
  final List<BeliefEdge> edges;
  final String selected;
  final bool full;
  final String Function(BeliefNode) name;
  final bool russian;
  final ValueChanged<String> onTap;
  @override
  Widget build(BuildContext c) {
    final shown = full
        ? nodes
        : nodes
              .where(
                (n) =>
                    n.id == selected ||
                    edges.any(
                      (e) =>
                          (e.from == selected && e.to == n.id) ||
                          (e.to == selected && e.from == n.id),
                    ),
              )
              .toList();
    if (!shown.any((n) => n.id == selected)) {
      shown.add(nodes.firstWhere((n) => n.id == selected));
    }
    final edgeRows = edges
        .where(
          (e) =>
              shown.any((n) => n.id == e.from) &&
              shown.any((n) => n.id == e.to),
        )
        .toList();
    final rows = max(1, (shown.length / 3).ceil());
    final sceneHeight = max(280.0, rows * 110.0 + 80);
    final edgeSummary = edgeRows
        .map(
          (e) =>
              '${name(nodes.firstWhere((n) => n.id == e.from))} → ${name(nodes.firstWhere((n) => n.id == e.to))}: ${russian ? e.ru : e.en}; ${russian ? e.scopeRu : e.scopeEn}',
        )
        .join('. ');
    return Semantics(
      label: russian
          ? 'Интерактивный граф связей. $edgeSummary'
          : 'Interactive relationship graph. $edgeSummary',
      child: SizedBox(
        height: 280,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(c).colorScheme.surfaceContainerLow,
              border: Border.all(color: Theme.of(c).colorScheme.outlineVariant),
            ),
            child: InteractiveViewer(
              key: const Key('belief-graph'),
              transformationController: controller,
              minScale: .25,
              maxScale: 5,
              constrained: false,
              boundaryMargin: const EdgeInsets.all(140),
              child: SizedBox(
                key: const Key('belief-scene'),
                width: max(520, MediaQuery.sizeOf(c).width),
                height: sceneHeight,
                child: Stack(
                  children: [
                    CustomPaint(
                      size: Size(
                        max(520, MediaQuery.sizeOf(c).width),
                        sceneHeight,
                      ),
                      painter: _EdgePainter(
                        shown,
                        edgeRows,
                        russian,
                        Theme.of(c).colorScheme.onSurface,
                        Theme.of(c).colorScheme.surfaceContainerLow,
                      ),
                    ),
                    for (var i = 0; i < shown.length; i++)
                      Positioned(
                        left: 40 + (i % 3) * 165.0,
                        top: 36 + (i ~/ 3) * 110.0,
                        width: 140,
                        height: 56,
                        child: Semantics(
                          button: true,
                          label: name(shown[i]),
                          child: FilledButton(
                            key: Key('belief-node-${shown[i].id}'),
                            onPressed: () => onTap(shown[i].id),
                            style: FilledButton.styleFrom(
                              backgroundColor: shown[i].id == selected
                                  ? Theme.of(c).colorScheme.primary
                                  : Theme.of(c).colorScheme.secondary,
                            ),
                            child: Text(
                              name(shown[i]),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
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
      ),
    );
  }
}

/// Ends the arrow outside the destination button, so it remains visible.
Offset beliefArrowTip(Rect target, Offset from) {
  final delta = from - target.center;
  if (delta.distance == 0) return target.topCenter - const Offset(0, 6);
  final unit = delta / delta.distance;
  final padded = target.inflate(6);
  final reach = min(
    unit.dx == 0 ? double.infinity : padded.width / 2 / unit.dx.abs(),
    unit.dy == 0 ? double.infinity : padded.height / 2 / unit.dy.abs(),
  );
  return target.center + unit * reach;
}

class _EdgePainter extends CustomPainter {
  _EdgePainter(
    this.nodes,
    this.edges,
    this.russian,
    this.labelColor,
    this.labelBackground,
  );
  final Color labelColor, labelBackground;
  final List<BeliefNode> nodes;
  final List<BeliefEdge> edges;
  final bool russian;
  Offset p(String id) {
    final i = nodes.indexWhere((n) => n.id == id);
    return Offset(110 + (i % 3) * 165, 64 + (i ~/ 3) * 110);
  }

  @override
  void paint(Canvas c, Size s) {
    final paint = Paint()
      ..color = Colors.blueGrey
      ..strokeWidth = 2;
    for (final e in edges) {
      final source = p(e.from), target = p(e.to);
      final a = beliefArrowTip(
        Rect.fromCenter(center: source, width: 140, height: 56),
        target,
      );
      final b = beliefArrowTip(
        Rect.fromCenter(center: target, width: 140, height: 56),
        source,
      );
      c.drawLine(a, b, paint);
      final direction = (b - a) / (b - a).distance;
      final wing = Offset(-direction.dy, direction.dx);
      final arrow = Path()
        ..moveTo(b.dx, b.dy)
        ..lineTo(
          b.dx - direction.dx * 12 + wing.dx * 5,
          b.dy - direction.dy * 12 + wing.dy * 5,
        )
        ..lineTo(
          b.dx - direction.dx * 12 - wing.dx * 5,
          b.dy - direction.dy * 12 - wing.dy * 5,
        )
        ..close();
      c.drawPath(arrow, paint);
      final t = TextPainter(
        text: TextSpan(
          text: russian ? e.ru : e.en,
          style: TextStyle(
            fontSize: 10,
            color: labelColor,
            backgroundColor: labelBackground,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 90);
      t.paint(c, Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _EdgePainter o) =>
      o.nodes != nodes ||
      o.edges != edges ||
      o.russian != russian ||
      o.labelColor != labelColor ||
      o.labelBackground != labelBackground;
}

class _Detail extends StatelessWidget {
  const _Detail({
    required this.node,
    required this.atlas,
    required this.ru,
    required this.onTap,
  });
  final BeliefNode node;
  final BeliefAtlas atlas;
  final bool ru;
  final ValueChanged<String> onTap;
  String v(String en, String r) => ru ? russianLearningText(r) : en;
  @override
  Widget build(BuildContext c) {
    final links = atlas.edges
        .where((e) => e.from == node.id || e.to == node.id)
        .map((e) => e.from == node.id ? e.to : e.from)
        .toSet();
    final relations = atlas.edges
        .where((e) => e.from == node.id || e.to == node.id)
        .toList();
    return Card(
      key: const Key('belief-detail'),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              v(node.en, node.ru),
              style: Theme.of(c).textTheme.headlineSmall,
            ),
            Text(v(node.groupEn, node.groupRu)),
            const SizedBox(height: 6),
            Text(v(node.summaryEn, node.summaryRu)),
            if (v(node.domainsEn, node.domainsRu).isNotEmpty)
              Text(
                '${v('Roles / domains', 'Роли / области')}: ${v(node.domainsEn, node.domainsRu)}',
              ),
            if (v(node.symbolsEn, node.symbolsRu).isNotEmpty)
              Text(
                '${v('Symbols', 'Символы')}: ${v(node.symbolsEn, node.symbolsRu)}',
              ),
            for (final f in node.facts)
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text('• ${v(f.en, f.ru)}'),
              ),
            if (v(node.noteEn, node.noteRu).isNotEmpty)
              Text(
                '${v('Version note', 'Примечание о версии')}: ${v(node.noteEn, node.noteRu)}',
              ),
            if (relations.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                v('Linked relations', 'Связанные отношения'),
                style: Theme.of(c).textTheme.titleSmall,
              ),
              for (final edge in relations)
                Text(
                  '${edge.from == node.id ? '→' : '←'} ${v(edge.en, edge.ru)} · ${v(edge.scopeEn, edge.scopeRu)}',
                ),
            ],
            Wrap(
              children: [
                for (final id in links)
                  TextButton(
                    onPressed: () => onTap(id),
                    child: Text(
                      v(
                        atlas.nodes.firstWhere((n) => n.id == id).en,
                        atlas.nodes.firstWhere((n) => n.id == id).ru,
                      ),
                    ),
                  ),
              ],
            ),
            for (final id in node.sourceIds)
              TextButton.icon(
                onPressed: () => launchUrl(
                  Uri.parse(atlas.sources.firstWhere((s) => s.id == id).url),
                  mode: LaunchMode.externalApplication,
                ),
                icon: const Icon(Icons.open_in_new),
                label: Text(
                  '${v('Source', 'Источник')}: ${learningSourceTitle(atlas.sources.firstWhere((s) => s.id == id).title, russian: ru)}',
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BeliefQuiz extends StatefulWidget {
  const _BeliefQuiz({
    required this.atlas,
    required this.section,
    required this.ru,
  });
  final BeliefAtlas atlas;
  final String section;
  final bool ru;
  @override
  State<_BeliefQuiz> createState() => _BeliefQuizState();
}

class _BeliefQuizState extends State<_BeliefQuiz> {
  late List<BeliefQuestion> _round;
  int _i = 0;
  String? _answer;
  bool _checked = false;
  final List<BeliefQuestion> _missed = [];
  int _score = 0;
  bool _review = false;
  @override
  void initState() {
    super.initState();
    _round = widget.atlas.round(widget.section);
  }

  @override
  Widget build(BuildContext c) {
    final ru = widget.ru;
    String t(String e, String r) => ru ? r : e;
    if (_i >= _round.length) {
      return Scaffold(
        appBar: AppBar(title: Text(t('Quiz result', 'Результат'))),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${t('Original score:', 'Исходный результат:')} $_score ${t('correct.', 'верных.')}',
                style: Theme.of(c).textTheme.titleLarge,
              ),
              if (_review)
                Text(t('Mistakes review complete.', 'Разбор ошибок завершён.')),
              if (_missed.isNotEmpty && !_review)
                FilledButton(
                  onPressed: () {
                    setState(() {
                      _round = List.of(_missed);
                      _i = 0;
                      _answer = null;
                      _checked = false;
                      _review = true;
                    });
                  },
                  child: Text(t('Retry missed', 'Повторить ошибки')),
                ),
              TextButton(
                onPressed: () => Navigator.pop(c),
                child: Text(t('Back', 'Назад')),
              ),
            ],
          ),
        ),
      );
    }
    final q = _round[_i];
    final opts = List.of(q.options)..shuffle(Random(_i));
    return Scaffold(
      appBar: AppBar(
        title: Text(t('Local unranked quiz', 'Локальная викторина')),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _round.length < 10
                    ? t(
                        '${_i + 1}/${_round.length} · ${_round.length} questions available',
                        '${_i + 1}/${_round.length} · доступно вопросов: ${_round.length}',
                      )
                    : '${_i + 1}/${_round.length}',
              ),
              Text(
                ru ? russianLearningText(q.ru) : q.en,
                style: Theme.of(c).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              for (var j = 0; j < opts.length; j++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: OutlinedButton(
                    key: Key('belief-option-$j'),
                    onPressed: _checked
                        ? null
                        : () => setState(() => _answer = opts[j]),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: _answer == opts[j]
                          ? Theme.of(c).colorScheme.secondaryContainer
                          : null,
                    ),
                    child: Text(
                      ru
                          ? widget.atlas.nodes
                                .firstWhere((n) => n.id == opts[j])
                                .ru
                          : widget.atlas.nodes
                                .firstWhere((n) => n.id == opts[j])
                                .en,
                    ),
                  ),
                ),
              if (!_checked)
                FilledButton(
                  key: const Key('belief-check'),
                  onPressed: _answer == null
                      ? null
                      : () => setState(() {
                          _checked = true;
                          if (_answer == q.correct && !_review) _score++;
                          if (_answer != q.correct && !_review) _missed.add(q);
                        }),
                  child: Text(t('Check', 'Проверить')),
                ),
              if (_checked) ...[
                Text(
                  _answer == q.correct
                      ? t('Correct.', 'Верно.')
                      : t('Not quite.', 'Не совсем.'),
                ),
                Text(ru ? russianLearningText(q.explainRu) : q.explainEn),
                Text(
                  '${t('Source', 'Источник')}: ${learningSourceTitle(widget.atlas.sources.firstWhere((s) => s.id == q.sourceIds.first).title, russian: ru)}',
                ),
                FilledButton(
                  key: const Key('belief-next'),
                  onPressed: () => setState(() {
                    _i++;
                    _answer = null;
                    _checked = false;
                  }),
                  child: Text(t('Next', 'Далее')),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
