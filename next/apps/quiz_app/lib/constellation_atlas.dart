/// A touch-first explorer for the fixed J2000 constellation patterns.
library;

import 'fact_practice.dart';

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'map_interaction.dart';

import 'package:url_launcher/url_launcher.dart';

import 'quizipedia.dart';

String starLabel(Map<String, dynamic> star, bool russian) {
  final russianName = star['name_ru'];
  if (russian && russianName is String && russianName.trim().isNotEmpty) {
    return russianName;
  }
  return star['name'] as String;
}

class ConstellationAtlasPage extends StatefulWidget {
  const ConstellationAtlasPage({
    super.key,
    required this.catalog,
    required this.trainingBuilder,
    this.challenge = false,
  });

  final QuizipediaCatalog catalog;
  final WidgetBuilder trainingBuilder;
  final bool challenge;

  @override
  State<ConstellationAtlasPage> createState() => _ConstellationAtlasPageState();
}

class _ConstellationAtlasPageState extends State<ConstellationAtlasPage> {
  final _search = TextEditingController();
  final _canvasKey = GlobalKey();
  final _controller = TransformationController();
  late List<Map<String, dynamic>> _constellations;
  var _selectedIndex = 0;
  bool _showNames = true;
  bool _showLines = true;
  Map<String, dynamic>? _star;
  Offset _doubleTapAt = Offset.zero;

  @override
  void initState() {
    super.initState();
    _constellations = List.of(widget.catalog.constellations)
      ..sort(
        (a, b) => (a['name_en'] as String).compareTo(b['name_en'] as String),
      );
    final orion = _constellations.indexWhere((row) => row['id'] == 'ori');
    if (orion >= 0) _selectedIndex = orion;
  }

  @override
  void dispose() {
    _search.dispose();
    _controller.dispose();
    super.dispose();
  }

  bool get _russian => Localizations.localeOf(context).languageCode == 'ru';
  String _t(String en, String ru) => _russian ? ru : en;
  String _name(Map<String, dynamic> row) =>
      row[_russian ? 'name_ru' : 'name_en'] as String;
  String _explanation(Map<String, dynamic> row) =>
      row[_russian ? 'explanation_ru' : 'explanation_en'] as String;
  Map<String, dynamic> get _selected => _constellations[_selectedIndex];
  String get _query => _search.text.trim().toLowerCase();
  List<Map<String, dynamic>> get _matches => _constellations.where((row) {
    if (_query.isEmpty) return true;
    return '${row['name_en']} ${row['name_ru']}'.toLowerCase().contains(_query);
  }).toList();

  Future<void> _choose() async {
    _search.clear();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, update) => SafeArea(
          minimum: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * .78,
            child: CustomScrollView(
              key: const Key('constellation-picker-scroll'),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            key: const Key('constellation-search'),
                            controller: _search,
                            decoration: InputDecoration(
                              labelText: _t(
                                'Find a constellation',
                                'Найти созвездие',
                              ),
                              prefixIcon: const Icon(Icons.search),
                            ),
                            onChanged: (_) => update(() {}),
                          ),
                        ),
                        IconButton(
                          tooltip: _t('Close', 'Закрыть'),
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(sheetContext),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: _ConstellationPicker(
                    rows: _matches,
                    selected: _selected['id'] as String,
                    name: _name,
                    onSelected: (row) {
                      FocusManager.instance.primaryFocus?.unfocus();
                      _select(row);
                      Navigator.pop(sheetContext);
                    },
                    emptyLabel: _t(
                      'No matching constellations',
                      'Созвездия не найдены',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _select(Map<String, dynamic> row) {
    setState(() {
      _selectedIndex = _constellations.indexOf(row);
      _star = null;
      _controller.value = Matrix4.identity();
    });
  }

  void _move(int direction) {
    setState(() {
      _selectedIndex = (_selectedIndex + direction) % _constellations.length;
      if (_selectedIndex < 0) _selectedIndex += _constellations.length;
      _star = null;
      _controller.value = Matrix4.identity();
    });
  }

  Future<void> _showStar(Map<String, dynamic> star) async {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _star = star);
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SizedBox(
        key: const Key('star-details-sheet'),
        height: MediaQuery.sizeOf(context).height * .62,
        child: Column(
          children: [
            ListTile(
              title: Text(
                starLabel(star, _russian),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              subtitle: Text(_name(_selected)),
              trailing: IconButton(
                tooltip: _t('Close star facts', 'Закрыть сведения о звезде'),
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: _StarCard(star: star, russian: _russian),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _zoomCentre(double factor) {
    final box = _canvasKey.currentContext?.findRenderObject();
    if (box is RenderBox) {
      _zoomAtViewport(Offset(box.size.width / 2, box.size.height / 2), factor);
    }
  }

  void _reset() => setState(() => _controller.value = Matrix4.identity());

  void _zoomAtViewport(Offset viewport, double factor) =>
      _zoomAtScene(_controller.toScene(viewport), factor);

  void _zoomAtScene(Offset scene, double factor) {
    final current = _controller.value.getMaxScaleOnAxis();
    final target = (current * factor).clamp(1.0, 8.0).toDouble();
    if (target == current) return;
    if (target == 1) {
      setState(() => _controller.value = Matrix4.identity());
      return;
    }
    final step = target / current;
    setState(
      () => _controller.value = Matrix4.copy(_controller.value)
        ..translateByDouble(scene.dx, scene.dy, 0, 1)
        ..scaleByDouble(step, step, 1, 1)
        ..translateByDouble(-scene.dx, -scene.dy, 0, 1),
    );
  }

  Future<void> _openSource() async {
    final creditId = _selected['credit_id'];
    final credit = widget.catalog.credits.cast<Map<String, dynamic>>().where(
      (row) => row['id'] == creditId,
    );
    if (credit.isEmpty) return;
    final uri = Uri.tryParse(credit.first['source_url'] as String);
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

  @override
  Widget build(BuildContext context) {
    if (_constellations.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(_t('Constellations', 'Созвездия'))),
        body: Center(
          child: Text(_t('No constellation data', 'Нет данных о созвездиях')),
        ),
      );
    }
    final row = _selected;
    final stars = (row['stars'] as List).cast<Map<String, dynamic>>();
    final lines = (row['lines'] as List).cast<List>();
    return Scaffold(
      appBar: AppBar(
        title: Text(_t('Constellations', 'Созвездия')),
        actions: [
          const FactPracticeAction(scope: 'sky'),
          IconButton(
            tooltip: _t('Previous constellation', 'Предыдущее созвездие'),
            onPressed: () => _move(-1),
            icon: const Icon(Icons.chevron_left),
          ),
          IconButton(
            tooltip: _t('Next constellation', 'Следующее созвездие'),
            onPressed: () => _move(1),
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
      body: SafeArea(
        child: MapScrollView(
          key: const Key('constellation-scroll'),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OutlinedButton.icon(
                key: const Key('constellation-choose'),
                onPressed: _choose,
                icon: const Icon(Icons.search),
                label: Text(_name(row)),
              ),
              if (_star == null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    _t(
                      'Tap a star to open its facts. Pinch to zoom; drag to move.',
                      'Нажмите на звезду — откроются её данные. Масштаб — двумя пальцами, перемещение — одним.',
                    ),
                  ),
                )
              else
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    key: const Key('constellation-selected-star'),
                    onPressed: () => _showStar(_star!),
                    icon: const Icon(Icons.star_outline),
                    label: Text(starLabel(_star!, _russian)),
                  ),
                ),
              MapInteraction(
                child: _ConstellationCanvas(
                  key: _canvasKey,
                  selectedStar: _star?['id'] as String?,
                  controller: _controller,
                  stars: stars,
                  lines: lines,
                  showNames: _showNames,
                  showLines: _showLines,
                  russian: _russian,
                  onDoubleTapDown: (details) =>
                      _doubleTapAt = details.localPosition,
                  onDoubleTap: () => _zoomAtScene(_doubleTapAt, 1.8),
                  onStar: _showStar,
                ),
              ),
              _ZoomToolbar(
                onZoomIn: () => _zoomCentre(1.35),
                onZoomOut: () => _zoomCentre(1 / 1.35),
                onReset: _reset,
                russian: _russian,
              ),
              _SkyControls(
                names: _showNames,
                lines: _showLines,
                russian: _russian,
                onNamesChanged: (value) => setState(() => _showNames = value),
                onLinesChanged: (value) => setState(() => _showLines = value),
              ),
              const SizedBox(height: 12),
              _StarList(
                stars: stars,
                selected: _star,
                onSelected: _showStar,
                russian: _russian,
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _t('About this pattern', 'О рисунке'),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(_explanation(row)),
                      TextButton.icon(
                        onPressed: _openSource,
                        icon: const Icon(Icons.open_in_new),
                        label: Text(
                          _t('Open data source', 'Открыть источник данных'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: widget.trainingBuilder),
                ),
                icon: const Icon(Icons.play_arrow),
                label: Text(_t('Start training', 'Начать тренировку')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConstellationPicker extends StatelessWidget {
  const _ConstellationPicker({
    required this.rows,
    required this.selected,
    required this.name,
    required this.onSelected,
    required this.emptyLabel,
  });
  final List<Map<String, dynamic>> rows;
  final String selected;
  final String Function(Map<String, dynamic>) name;
  final ValueChanged<Map<String, dynamic>> onSelected;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Text(emptyLabel),
        ),
      );
    }
    final sorted = [...rows]..sort((a, b) => name(a).compareTo(name(b)));
    return SliverList.builder(
      itemCount: sorted.length,
      itemBuilder: (context, index) {
        final row = sorted[index];
        final id = row['id'] as String;
        return ListTile(
          key: Key('constellation-option-$id'),
          title: Text(name(row)),
          selected: id == selected,
          trailing: id == selected ? const Icon(Icons.check) : null,
          onTap: () => onSelected(row),
        );
      },
    );
  }
}

class _SkyControls extends StatelessWidget {
  const _SkyControls({
    required this.names,
    required this.lines,
    required this.russian,
    required this.onNamesChanged,
    required this.onLinesChanged,
  });
  final bool names, lines;
  final bool russian;
  final ValueChanged<bool> onNamesChanged, onLinesChanged;
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    children: [
      for (final control in [
        (
          label: russian ? 'Подписи' : 'Labels',
          selected: names,
          onSelected: onNamesChanged,
        ),
        (
          label: russian ? 'Линии' : 'Lines',
          selected: lines,
          onSelected: onLinesChanged,
        ),
      ])
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: FilterChip(
            label: Text(control.label),
            selected: control.selected,
            onSelected: control.onSelected,
          ),
        ),
    ],
  );
}

class _ConstellationCanvas extends StatelessWidget {
  const _ConstellationCanvas({
    super.key,
    required this.selectedStar,
    required this.controller,
    required this.stars,
    required this.lines,
    required this.showNames,
    required this.showLines,
    required this.russian,
    required this.onDoubleTapDown,
    required this.onDoubleTap,
    required this.onStar,
  });
  final String? selectedStar;
  final TransformationController controller;
  final List<Map<String, dynamic>> stars;
  final List<List> lines;
  final bool showNames, showLines, russian;
  final GestureTapDownCallback onDoubleTapDown;
  final GestureTapCallback onDoubleTap;
  final ValueChanged<Map<String, dynamic>> onStar;

  @override
  Widget build(BuildContext context) => Semantics(
    label: russian
        ? 'Схема созвездия. Масштабируйте двумя пальцами, перемещайте и увеличивайте двойным касанием.'
        : 'Constellation star pattern. Pinch, pan, and double-tap to inspect.',
    child: ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xff071525),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: SizedBox(
          height: 340,
          child: LayoutBuilder(
            builder: (context, constraints) => InteractiveViewer(
              transformationController: controller,
              minScale: 1,
              maxScale: 8,
              boundaryMargin: const EdgeInsets.all(160),
              child: GestureDetector(
                // A semantic tap has no coordinates and selects the centre.
                // Named star buttons provide the accessible alternative.
                excludeFromSemantics: true,
                behavior: HitTestBehavior.opaque,
                onDoubleTapDown: onDoubleTapDown,
                onDoubleTap: onDoubleTap,
                onTapUp: (details) {
                  final points = projectConstellation(
                    stars,
                    Size(constraints.maxWidth, 340),
                  );
                  Map<String, dynamic>? nearest;
                  var distance = double.infinity;
                  for (final star in stars) {
                    final value =
                        (details.localPosition - points[star['id']]!).distance;
                    if (value < distance) {
                      distance = value;
                      nearest = star;
                    }
                  }
                  final labels = _layoutStarLabels(
                    stars,
                    Size(constraints.maxWidth, 340),
                    russian: russian,
                    showNames: showNames,
                    selectedStar: selectedStar,
                    sceneScale: controller.value.getMaxScaleOnAxis(),
                    textScaler: MediaQuery.textScalerOf(context),
                  );
                  final label = labels
                      .where((l) => l.rect.contains(details.localPosition))
                      .firstOrNull;
                  final labelled = label == null
                      ? null
                      : stars
                            .where((star) => star['id'] == label.id)
                            .firstOrNull;
                  if (labelled != null) {
                    onStar(labelled);
                  } else if (nearest != null &&
                      distance < 24 / controller.value.getMaxScaleOnAxis()) {
                    onStar(nearest);
                  }
                },
                child: ValueListenableBuilder<Matrix4>(
                  valueListenable: controller,
                  builder: (context, transform, _) => CustomPaint(
                    key: const Key('constellation-canvas'),
                    size: Size(constraints.maxWidth, 340),
                    painter: _SkyPainter(
                      stars,
                      lines,
                      showNames: showNames,
                      showLines: showLines,
                      russian: russian,
                      selectedStar: selectedStar,
                      sceneScale: transform.getMaxScaleOnAxis(),
                      textScaler: MediaQuery.textScalerOf(context),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _StarLabel {
  const _StarLabel(this.id, this.rect, this.text);
  final String id;
  final Rect rect;
  final TextPainter text;
}

List<_StarLabel> _layoutStarLabels(
  List<Map<String, dynamic>> stars,
  Size size, {
  required bool russian,
  required bool showNames,
  required String? selectedStar,
  required double sceneScale,
  required TextScaler textScaler,
}) {
  if (!showNames && selectedStar == null) return const [];
  final points = projectConstellation(stars, size);
  double radius(Map<String, dynamic> star) =>
      (5.6 - (star['magnitude'] as num)).clamp(2.2, 5.2).toDouble();
  final occupied = <Rect>[
    for (final star in stars)
      Rect.fromCircle(
        center: points[star['id']]!,
        radius:
            (radius(star) + (star['id'] == selectedStar ? 8 : 3)) / sceneScale,
      ),
  ];
  final ordered = [...stars]
    ..sort(
      (a, b) => a['id'] == selectedStar
          ? -1
          : b['id'] == selectedStar
          ? 1
          : (a['magnitude'] as num).compareTo(b['magnitude'] as num),
    );
  final result = <_StarLabel>[];
  final margin = 4 / sceneScale;
  for (final star in ordered) {
    if (!showNames && star['id'] != selectedStar) continue;
    final point = points[star['id']]!;
    final selected = star['id'] == selectedStar;
    final text =
        TextPainter(
          text: TextSpan(
            text: starLabel(star, russian),
            style: TextStyle(
              color: selected
                  ? const Color(0xffb6dcff)
                  : const Color(0xffd9efff),
              fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
              fontSize: textScaler.scale(selected ? 14 : 13) / sceneScale,
            ),
          ),
          textDirection: TextDirection.ltr,
          maxLines: 1,
          ellipsis: '…',
        )..layout(
          maxWidth: math.max(
            1,
            math.min(
              (size.width < 420 ? 120 : 160) *
                  textScaler.scale(13) /
                  13 /
                  sceneScale,
              size.width - 2 * margin,
            ),
          ),
        );
    final pad = (radius(star) + (selected ? 11 : 6)) / sceneScale;
    double x(double value) =>
        value.clamp(margin, math.max(margin, size.width - text.width - margin));
    double y(double value) => value.clamp(
      margin,
      math.max(margin, size.height - text.height - margin),
    );
    final candidates = [
      Offset(x(point.dx + pad), y(point.dy - text.height - pad)),
      Offset(x(point.dx - text.width - pad), y(point.dy - text.height - pad)),
      Offset(x(point.dx + pad), y(point.dy + pad)),
      Offset(x(point.dx - text.width - pad), y(point.dy + pad)),
    ];
    final offset = candidates
        .where(
          (o) => occupied.every(
            (r) => !r.inflate(2 / sceneScale).overlaps(o & text.size),
          ),
        )
        .firstOrNull;
    if (offset == null) continue;
    final rect = offset & text.size;
    occupied.add(rect);
    result.add(_StarLabel(star['id'] as String, rect, text));
  }
  return result;
}

class _SkyPainter extends CustomPainter {
  const _SkyPainter(
    this.stars,
    this.lines, {
    required this.showNames,
    required this.showLines,
    required this.russian,
    required this.selectedStar,
    required this.sceneScale,
    required this.textScaler,
  });
  final List<Map<String, dynamic>> stars;
  final List<List> lines;
  final bool showNames, showLines, russian;
  final String? selectedStar;
  final double sceneScale;
  final TextScaler textScaler;
  @override
  void paint(Canvas canvas, Size size) {
    final points = projectConstellation(stars, size);
    final linePaint = Paint()
      ..color = const Color(0xff72b6ee)
      ..strokeWidth = 1.5 / sceneScale;
    if (showLines) {
      for (final line in lines) {
        canvas.drawLine(points[line[0]]!, points[line[1]]!, linePaint);
      }
    }
    for (final star in stars) {
      final magnitude = (star['magnitude'] as num).toDouble();
      final radius = (5.6 - magnitude).clamp(2.2, 5.2).toDouble() / sceneScale;
      final point = points[star['id']]!;
      if (star['id'] == selectedStar) {
        canvas.drawCircle(
          point,
          radius + 7 / sceneScale,
          Paint()
            ..color = const Color(0xff9bceff)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2 / sceneScale,
        );
      }
      canvas.drawCircle(
        point,
        radius + 2 / sceneScale,
        Paint()..color = const Color(0xffd9efff).withValues(alpha: .16),
      );
      canvas.drawCircle(
        point,
        radius,
        Paint()..color = const Color(0xfff5fbff),
      );
    }
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    for (final label in _layoutStarLabels(
      stars,
      size,
      russian: russian,
      showNames: showNames,
      selectedStar: selectedStar,
      sceneScale: sceneScale,
      textScaler: textScaler,
    )) {
      label.text.paint(canvas, label.rect.topLeft);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SkyPainter old) =>
      old.textScaler != textScaler ||
      old.selectedStar != selectedStar ||
      old.sceneScale != sceneScale ||
      old.stars != stars ||
      old.lines != lines ||
      old.showNames != showNames ||
      old.showLines != showLines ||
      old.russian != russian;
}

class _ZoomToolbar extends StatelessWidget {
  const _ZoomToolbar({
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onReset,
    required this.russian,
  });
  final VoidCallback onZoomIn, onZoomOut, onReset;
  final bool russian;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        IconButton(
          tooltip: russian ? 'Увеличить' : 'Zoom in',
          icon: const Icon(Icons.add),
          onPressed: onZoomIn,
        ),
        IconButton(
          tooltip: russian ? 'Уменьшить' : 'Zoom out',
          icon: const Icon(Icons.remove),
          onPressed: onZoomOut,
        ),
        Tooltip(
          message: russian ? 'Сбросить вид' : 'Reset view',
          child: TextButton.icon(
            onPressed: onReset,
            icon: const Icon(Icons.replay),
            label: Text(russian ? 'Сбросить' : 'Reset'),
          ),
        ),
      ],
    ),
  );
}

class _StarList extends StatelessWidget {
  const _StarList({
    required this.stars,
    required this.selected,
    required this.onSelected,
    required this.russian,
  });
  final List<Map<String, dynamic>> stars;
  final Map<String, dynamic>? selected;
  final ValueChanged<Map<String, dynamic>> onSelected;
  final bool russian;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        russian ? 'Звёзды: доступный список' : 'Stars: accessible list',
        style: Theme.of(context).textTheme.titleSmall,
      ),
      const SizedBox(height: 4),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final star in stars)
            OutlinedButton(
              onPressed: () => onSelected(star),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(44, 44),
                backgroundColor: selected?['id'] == star['id']
                    ? Theme.of(context).colorScheme.secondaryContainer
                    : null,
              ),
              child: Text(starLabel(star, russian)),
            ),
        ],
      ),
    ],
  );
}

class _StarCard extends StatelessWidget {
  const _StarCard({required this.star, required this.russian});
  final Map<String, dynamic> star;
  final bool russian;
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.all(16),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final row in [
            (
              russian ? 'Звёздная величина' : 'magnitude',
              '${star['magnitude']}',
            ),
            (
              russian
                  ? 'Прямое восхождение · J2000'
                  : 'right ascension · J2000',
              '${star['ra_hours']} ${russian ? 'ч' : 'h'}',
            ),
            (
              russian ? 'Склонение · J2000' : 'declination · J2000',
              '${star['dec_degrees']}°',
            ),
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(row.$1, style: Theme.of(context).textTheme.labelLarge),
                  Text(
                    russian ? row.$2.replaceAll('.', ',') : row.$2,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}
