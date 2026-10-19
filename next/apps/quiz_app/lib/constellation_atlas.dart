/// A touch-first explorer for the fixed J2000 constellation patterns.
library;

import 'fact_practice.dart';

import 'package:flutter/material.dart';
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
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, update) => SafeArea(
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * .78,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  TextField(
                    key: const Key('constellation-search'),
                    controller: _search,
                    decoration: InputDecoration(
                      labelText: _t('Find a constellation', 'Найти созвездие'),
                      prefixIcon: const Icon(Icons.search),
                    ),
                    onChanged: (_) => update(() {}),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _ConstellationPicker(
                      rows: _matches,
                      selected: _selected['id'] as String,
                      name: _name,
                      onSelected: (row) {
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

  void _reset() => setState(() => _controller.value = Matrix4.identity());

  void _zoomAt(Offset focalPoint, double factor) {
    final scene = _controller.toScene(focalPoint);
    final next = Matrix4.copy(_controller.value)
      ..translateByDouble(scene.dx, scene.dy, 0, 1)
      ..scaleByDouble(factor, factor, 1, 1)
      ..translateByDouble(-scene.dx, -scene.dy, 0, 1);
    final scale = next.getMaxScaleOnAxis();
    if (scale >= 1 && scale <= 8) setState(() => _controller.value = next);
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
        child: SingleChildScrollView(
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
              const SizedBox(height: 12),
              _ConstellationCanvas(
                controller: _controller,
                stars: stars,
                lines: lines,
                showNames: _showNames,
                showLines: _showLines,
                russian: _russian,
                onDoubleTapDown: (details) =>
                    _doubleTapAt = details.localPosition,
                onDoubleTap: () => _zoomAt(_doubleTapAt, 1.8),
                onStar: (star) => setState(() => _star = star),
              ),
              _ZoomToolbar(
                onZoomIn: () => _zoomAt(const Offset(160, 150), 1.35),
                onZoomOut: () => _zoomAt(const Offset(160, 150), 1 / 1.35),
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
                onSelected: (star) => setState(() => _star = star),
                russian: _russian,
              ),
              if (_star != null) _StarCard(star: _star!, russian: _russian),
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
      return Padding(padding: const EdgeInsets.all(8), child: Text(emptyLabel));
    }
    final sorted = [...rows]..sort((a, b) => name(a).compareTo(name(b)));
    return ListView.builder(
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
                  if (nearest != null && distance < 30) onStar(nearest);
                },
                child: CustomPaint(
                  key: const Key('constellation-canvas'),
                  size: Size(constraints.maxWidth, 340),
                  painter: _SkyPainter(
                    stars,
                    lines,
                    showNames: showNames,
                    showLines: showLines,
                    russian: russian,
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

class _SkyPainter extends CustomPainter {
  const _SkyPainter(
    this.stars,
    this.lines, {
    required this.showNames,
    required this.showLines,
    required this.russian,
  });
  final List<Map<String, dynamic>> stars;
  final List<List> lines;
  final bool showNames, showLines, russian;
  @override
  void paint(Canvas canvas, Size size) {
    final points = projectConstellation(stars, size);
    final linePaint = Paint()
      ..color = const Color(0xff72b6ee)
      ..strokeWidth = 1.5;
    if (showLines) {
      for (final line in lines) {
        canvas.drawLine(points[line[0]]!, points[line[1]]!, linePaint);
      }
    }
    for (final star in stars) {
      final magnitude = (star['magnitude'] as num).toDouble();
      final radius = (5.6 - magnitude).clamp(2.2, 5.2).toDouble();
      final point = points[star['id']]!;
      canvas.drawCircle(
        point,
        radius + 2,
        Paint()..color = const Color(0xffd9efff).withValues(alpha: .16),
      );
      canvas.drawCircle(
        point,
        radius,
        Paint()..color = const Color(0xfff5fbff),
      );
    }
    if (!showNames) return;

    final occupied = <Rect>[];
    final maxLabelWidth = size.width < 420 ? 92.0 : 120.0;
    final ordered = [
      ...stars,
    ]..sort((a, b) => (a['magnitude'] as num).compareTo(b['magnitude'] as num));
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    for (final star in ordered) {
      final point = points[star['id']]!;
      final painter = TextPainter(
        text: TextSpan(
          text: starLabel(star, russian),
          style: TextStyle(
            color: const Color(0xffd9efff),
            fontSize: size.width < 420 ? 11 : 12,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: maxLabelWidth);
      final right = (point.dx + 8).clamp(4.0, size.width - painter.width - 4);
      final left = (point.dx - painter.width - 8).clamp(
        4.0,
        size.width - painter.width - 4,
      );
      final top = (point.dy - painter.height - 8).clamp(
        4.0,
        size.height - painter.height - 4,
      );
      final bottom = (point.dy + 8).clamp(
        4.0,
        size.height - painter.height - 4,
      );
      final candidates = [
        Offset(right, top),
        Offset(left, top),
        Offset(right, bottom),
        Offset(left, bottom),
      ];
      final offset = candidates.where((candidate) {
        final rect = candidate & painter.size;
        return occupied.every((other) => !other.inflate(4).overlaps(rect));
      }).firstOrNull;
      if (offset == null) continue;
      occupied.add(offset & painter.size);
      painter.paint(canvas, offset);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SkyPainter old) =>
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
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        russian
            ? '${starLabel(star, true)} · звёздная величина ${star['magnitude']} · прямое восхождение ${star['ra_hours']} ч · склонение ${star['dec_degrees']}°'
            : '${starLabel(star, false)} · magnitude ${star['magnitude']} · right ascension ${star['ra_hours']} h · declination ${star['dec_degrees']}°',
      ),
    ),
  );
}
