/// Interactive periodic table for Quizipedia: a scalable 18-column grid that
/// fits the viewport, colour modes with a legend, search, keyboard navigation,
/// an element panel (side panel on wide screens, bottom sheet on phones) and
/// two training modes. Element values come from `periodic_data.dart`.
library;

import 'dart:async';
import 'dart:math';

import 'package:flutter/gestures.dart' show kDoubleTapTimeout;
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show SemanticsProperties;
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'map_interaction.dart';
import 'periodic_elements.dart';

export 'periodic_elements.dart'
    show PeriodicElement, periodicElements, ElementColorMode;

/// Side panel instead of a bottom sheet from this width on.
const periodicWideBreakpoint = 840.0;

/// Columns and rows of the drawn grid in cell units (labels and the f-block
/// gap included); the grid keeps this aspect ratio.
const _gridColumns = 18.6, _gridRows = 10.1;

enum PeriodicView { table, list }

String _t(BuildContext context, String en, String ru) =>
    Localizations.localeOf(context).languageCode == 'ru' ? ru : en;

bool _isRussian(BuildContext context) =>
    Localizations.localeOf(context).languageCode == 'ru';

/// Cell colour for a legend key in the given mode.
Color legendColor(String key, ElementColorMode mode, Brightness brightness) {
  final (hue, saturation) = switch (mode) {
    ElementColorMode.category => switch (key) {
      'Alkali metal' => (2.0, .62),
      'Alkaline earth metal' => (30.0, .72),
      'Transition metal' => (50.0, .72),
      'Post-transition metal' => (140.0, .42),
      'Metalloid' => (172.0, .48),
      'Nonmetal' => (207.0, .62),
      'Halogen' => (262.0, .5),
      'Noble gas' => (300.0, .45),
      'Lanthanide' => (92.0, .5),
      'Actinide' => (338.0, .5),
      _ => (0.0, 0.0),
    },
    ElementColorMode.state => switch (key) {
      'solid' => (207.0, .55),
      'liquid' => (172.0, .55),
      'gas' => (30.0, .75),
      _ => (0.0, 0.0),
    },
    ElementColorMode.block => switch (key) {
      's' => (2.0, .6),
      'p' => (50.0, .7),
      'd' => (207.0, .6),
      _ => (140.0, .45),
    },
    ElementColorMode.metal => switch (key) {
      'metal' => (207.0, .6),
      'metalloid' => (50.0, .7),
      _ => (30.0, .7),
    },
  };
  final dark = brightness == Brightness.dark;
  final grey = saturation == 0;
  return HSLColor.fromAHSL(
    1,
    hue,
    saturation,
    grey ? (dark ? .3 : .86) : (dark ? .32 : .8),
  ).toColor();
}

Color elementColor(
  PeriodicElement e,
  ElementColorMode mode,
  Brightness brightness,
) => legendColor(e.colorKey(mode), mode, brightness);

class PeriodicTablePage extends StatefulWidget {
  const PeriodicTablePage({super.key});
  @override
  State<PeriodicTablePage> createState() => _PeriodicTablePageState();
}

class _PeriodicTablePageState extends State<PeriodicTablePage> {
  final _search = TextEditingController();
  final _gridFocus = FocusNode(debugLabel: 'periodic-grid');
  final _zoom = TransformationController();
  String _query = '';
  PeriodicView _view = PeriodicView.table;
  ElementColorMode _mode = ElementColorMode.category;
  String? _filterKey;
  int? _selected, _cursor, _hovered;
  (int, int)? _zoomTarget;
  var _zoomRevision = 0;

  @override
  void dispose() {
    _search.dispose();
    _gridFocus.dispose();
    _zoom.dispose();
    super.dispose();
  }

  List<PeriodicElement> get _matches => searchElements(_query);

  bool _isDimmed(PeriodicElement e) {
    if (_query.trim().isNotEmpty) {
      return !_matches.any((m) => m.number == e.number);
    }
    return _filterKey != null && e.colorKey(_mode) != _filterKey;
  }

  bool _wide(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= periodicWideBreakpoint;

  void _select(PeriodicElement e, {bool open = false, bool focusCell = false}) {
    setState(() {
      _selected = e.number;
      _cursor = e.number;
      if (focusCell) _zoomTarget = (e.number, ++_zoomRevision);
    });
    if (open && !_wide(context)) _openSheet(e);
  }

  void _step(int delta) {
    final current = _selected;
    if (current == null) return;
    final next = current + delta;
    if (next < 1 || next > periodicElements.length) return;
    _select(elementByNumber(next), focusCell: true);
  }

  Future<void> _openSheet(PeriodicElement e) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (sheetContext) => _ElementSheet(
      initial: e,
      mode: _mode,
      onChanged: (next) {
        if (mounted) _select(next, focusCell: true);
      },
      onTrain: (element) {
        Navigator.of(sheetContext).pop();
        _openTraining(element);
      },
    ),
  );

  void _openTraining(PeriodicElement? e) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ElementTrainingPage(initialNumber: e?.number),
    ),
  );

  KeyEventResult _onGridKey(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    final direction = switch (key) {
      LogicalKeyboardKey.arrowLeft => GridDirection.left,
      LogicalKeyboardKey.arrowRight => GridDirection.right,
      LogicalKeyboardKey.arrowUp => GridDirection.up,
      LogicalKeyboardKey.arrowDown => GridDirection.down,
      _ => null,
    };
    if (direction != null) {
      final from = elementByNumber(_cursor ?? _selected ?? 1);
      final next = _cursor == null && _selected == null
          ? from
          : neighborElement(from, direction);
      if (next != null) setState(() => _cursor = next.number);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter ||
        key == LogicalKeyboardKey.space) {
      final cursor = _cursor;
      if (cursor != null) _select(elementByNumber(cursor), open: true);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final wide = _wide(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_t(context, 'Periodic table', 'Таблица Менделеева')),
        actions: [
          if (wide)
            TextButton.icon(
              onPressed: () => _openTraining(
                _selected == null ? null : elementByNumber(_selected!),
              ),
              icon: const Icon(Icons.school_outlined),
              label: Text(_t(context, 'Practise', 'Тренировка')),
            )
          else
            IconButton(
              tooltip: _t(context, 'Practise', 'Тренировка'),
              onPressed: () => _openTraining(
                _selected == null ? null : elementByNumber(_selected!),
              ),
              icon: const Icon(Icons.school_outlined),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: wide ? _wideBody(context) : _narrowBody(context),
    );
  }

  Widget _wideBody(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: _controls(context),
            ),
            Expanded(
              child: _view == PeriodicView.table
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                      child: _grid(context, zoomable: false),
                    )
                  : _elementList(context, scrollable: true),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: _legend(context),
            ),
          ],
        ),
      ),
      const VerticalDivider(width: 1),
      SizedBox(
        width: 380,
        child: _selected == null
            ? _panelPlaceholder(context)
            : SingleChildScrollView(
                key: ValueKey('panel-$_selected'),
                padding: const EdgeInsets.all(20),
                child: _ElementDetails(
                  element: elementByNumber(_selected!),
                  mode: _mode,
                  onPrevious: _selected! > 1 ? () => _step(-1) : null,
                  onNext: _selected! < periodicElements.length
                      ? () => _step(1)
                      : null,
                  onTrain: () => _openTraining(elementByNumber(_selected!)),
                ),
              ),
      ),
    ],
  );

  Widget _narrowBody(BuildContext context) => MapScrollView(
    padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _controls(context),
        const SizedBox(height: 8),
        if (_view == PeriodicView.table) ...[
          MapInteraction(
            child: AspectRatio(
              aspectRatio: _gridColumns / _gridRows,
              child: _grid(context, zoomable: true),
            ),
          ),
          const SizedBox(height: 8),
          if (_selected != null) _selectedStrip(context),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(
              _t(
                context,
                'Tap selects, double tap zooms in, pinch to scale.',
                'Тап — выбрать, двойной тап — приблизить, щипок — масштаб.',
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          _legend(context),
        ] else
          _elementList(context, scrollable: false),
      ],
    ),
  );

  Widget _controls(BuildContext context) {
    final matches = _query.trim().isEmpty
        ? const <PeriodicElement>[]
        : _matches;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const Key('periodic-search'),
          controller: _search,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            isDense: true,
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    tooltip: _t(context, 'Clear', 'Очистить'),
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _search.clear();
                      setState(() => _query = '');
                    },
                  ),
            labelText: _t(
              context,
              'Name, symbol or number',
              'Название, символ или номер',
            ),
          ),
          onChanged: (value) => setState(() => _query = value),
          onSubmitted: (_) {
            if (matches.isNotEmpty) {
              _select(matches.first, open: true, focusCell: true);
            }
          },
        ),
        if (_query.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: matches.isEmpty
                ? Text(_t(context, 'No elements found', 'Элементы не найдены'))
                : Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      for (final e in matches.take(8))
                        ActionChip(
                          key: Key('match-${e.number}'),
                          avatar: CircleAvatar(
                            backgroundColor: elementColor(
                              e,
                              _mode,
                              Theme.of(context).brightness,
                            ),
                            child: Text(
                              e.symbol,
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ),
                          label: Text(
                            '${_isRussian(context) ? e.nameRu : e.name} · ${e.number}',
                          ),
                          onPressed: () =>
                              _select(e, open: true, focusCell: true),
                        ),
                    ],
                  ),
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            SegmentedButton<PeriodicView>(
              showSelectedIcon: false,
              style: const ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              segments: [
                ButtonSegment(
                  value: PeriodicView.table,
                  icon: const Icon(Icons.grid_view_outlined),
                  tooltip: _t(context, 'Table', 'Таблица'),
                ),
                ButtonSegment(
                  value: PeriodicView.list,
                  icon: const Icon(Icons.view_list_outlined),
                  tooltip: _t(context, 'List', 'Список'),
                ),
              ],
              selected: {_view},
              onSelectionChanged: (s) => setState(() => _view = s.first),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _view == PeriodicView.table
                    ? _t(context, 'Table', 'Таблица')
                    : _t(context, 'List of elements', 'Список элементов'),
                style: Theme.of(context).textTheme.labelLarge,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _grid(BuildContext context, {required bool zoomable}) {
    final brightness = Theme.of(context).brightness;
    return _PeriodicGrid(
      key: const Key('periodic-grid'),
      russian: _isRussian(context),
      colorOf: (e) => elementColor(e, _mode, brightness),
      isDimmed: _isDimmed,
      selected: _selected,
      cursor: _cursor,
      hovered: _hovered,
      onHover: (e) {
        if (e?.number != _hovered) setState(() => _hovered = e?.number);
      },
      onSelect: (e) {
        if (!_wide(context) && _selected == e.number) {
          _openSheet(e);
        } else {
          _select(e);
        }
      },
      zoomable: zoomable,
      controller: zoomable ? _zoom : null,
      zoomTarget: zoomable ? _zoomTarget : null,
      focusNode: _gridFocus,
      onKey: _onGridKey,
    );
  }

  Widget _legend(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final russian = _isRussian(context);
    final modes = {
      ElementColorMode.category: _t(context, 'Category', 'Категория'),
      ElementColorMode.state: _t(context, 'State', 'Состояние'),
      ElementColorMode.block: _t(context, 'Block', 'Блок'),
      ElementColorMode.metal: _t(context, 'Metals', 'Металлы'),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 2,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              _t(context, 'Colour by:', 'Цвет:'),
              style: Theme.of(context).textTheme.labelLarge,
            ),
            for (final entry in modes.entries)
              ChoiceChip(
                key: Key('mode-${entry.key.name}'),
                label: Text(entry.value),
                selected: _mode == entry.key,
                visualDensity: VisualDensity.compact,
                onSelected: (_) => setState(() {
                  _mode = entry.key;
                  _filterKey = null;
                }),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          runSpacing: 2,
          children: [
            for (final (key, label) in legendEntries(_mode, russian: russian))
              FilterChip(
                key: Key('legend-$key'),
                avatar: CircleAvatar(
                  backgroundColor: legendColor(key, _mode, brightness),
                ),
                label: Text(label),
                selected: _filterKey == key,
                showCheckmark: false,
                visualDensity: VisualDensity.compact,
                onSelected: (_) =>
                    setState(() => _filterKey = _filterKey == key ? null : key),
              ),
          ],
        ),
      ],
    );
  }

  Widget _selectedStrip(BuildContext context) {
    final e = elementByNumber(_selected!);
    final russian = _isRussian(context);
    return Card(
      key: const Key('selected-strip'),
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openSheet(e),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 6, 2, 6),
          child: Row(
            children: [
              _SymbolTile(element: e, mode: _mode, size: 44),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      russian ? e.nameRu : e.name,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '№ ${e.number} · ${familySingular(e.family, russian: russian)}',
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: _t(context, 'Previous element', 'Предыдущий элемент'),
                onPressed: e.number > 1 ? () => _step(-1) : null,
                icon: const Icon(Icons.chevron_left),
              ),
              IconButton(
                tooltip: _t(context, 'Next element', 'Следующий элемент'),
                onPressed: e.number < periodicElements.length
                    ? () => _step(1)
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
              IconButton(
                tooltip: _t(context, 'Details', 'Подробнее'),
                onPressed: () => _openSheet(e),
                icon: const Icon(Icons.info_outline),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _elementList(BuildContext context, {required bool scrollable}) {
    final russian = _isRussian(context);
    final brightness = Theme.of(context).brightness;
    final items = [
      for (final e in _query.trim().isEmpty ? periodicElements : _matches)
        if (_filterKey == null || e.colorKey(_mode) == _filterKey) e,
    ];
    Widget tile(PeriodicElement e) => ListTile(
      key: Key('element-tile-${e.number}'),
      leading: _SymbolTile(element: e, mode: _mode, size: 44),
      title: Text(russian ? e.nameRu : e.name),
      subtitle: Text(
        '№ ${e.number} · ${familySingular(e.family, russian: russian)}',
      ),
      trailing: Text(
        e.mass,
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
      selected: _selected == e.number,
      selectedTileColor: elementColor(
        e,
        _mode,
        brightness,
      ).withValues(alpha: .3),
      onTap: () => _select(e, open: true),
    );
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(_t(context, 'No elements found', 'Элементы не найдены')),
      );
    }
    if (scrollable) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: items.length,
        itemBuilder: (context, i) => tile(items[i]),
      );
    }
    return Column(children: [for (final e in items) tile(e)]);
  }

  Widget _panelPlaceholder(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.science_outlined,
          size: 48,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: 12),
        Text(
          _t(
            context,
            'Select an element in the table',
            'Выберите элемент в таблице',
          ),
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          _t(
            context,
            'Hover highlights the period and group. Arrow keys move, Enter opens.',
            'Наведение подсвечивает период и группу. Стрелки — перемещение, Enter — открыть.',
          ),
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

/// The grid itself: a CustomPaint that fits its constraints, with per-cell
/// semantics, hover, optional pinch zoom and manual double-tap detection.
class _PeriodicGrid extends StatefulWidget {
  const _PeriodicGrid({
    super.key,
    required this.russian,
    required this.colorOf,
    required this.isDimmed,
    required this.onSelect,
    this.selected,
    this.cursor,
    this.hovered,
    this.onHover,
    this.marks = const {},
    this.zoomable = false,
    this.tapZoomsWhenSmall = false,
    this.controller,
    this.zoomTarget,
    this.focusNode,
    this.onKey,
  });

  final bool russian;
  final Color Function(PeriodicElement) colorOf;
  final bool Function(PeriodicElement) isDimmed;
  final ValueChanged<PeriodicElement> onSelect;
  final ValueChanged<PeriodicElement?>? onHover;
  final int? selected, cursor, hovered;

  /// Fill overrides, e.g. correct/wrong answers in training.
  final Map<int, Color> marks;
  final bool zoomable;

  /// On small cells a single tap zooms in first instead of selecting.
  final bool tapZoomsWhenSmall;
  final TransformationController? controller;

  /// (element number, revision): when the revision changes the view zooms to
  /// that element (zoomable grids only).
  final (int, int)? zoomTarget;
  final FocusNode? focusNode;
  final FocusOnKeyEventCallback? onKey;

  @override
  State<_PeriodicGrid> createState() => _PeriodicGridState();
}

class _PeriodicGridState extends State<_PeriodicGrid> {
  static const minScale = 1.0, maxScale = 6.0;
  TransformationController? _ownController;
  TransformationController get _controller =>
      widget.controller ?? (_ownController ??= TransformationController());
  final _glyphs = <String, TextPainter>{};
  PeriodicGridGeometry? _geometry;
  Offset? _lastTapAt;
  Timer? _doubleTapTimer;

  @override
  void didUpdateWidget(covariant _PeriodicGrid old) {
    super.didUpdateWidget(old);
    if (widget.zoomable &&
        widget.zoomTarget != null &&
        widget.zoomTarget != old.zoomTarget) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _zoomToElement(widget.zoomTarget!.$1);
      });
    }
  }

  @override
  void dispose() {
    _doubleTapTimer?.cancel();
    _ownController?.dispose();
    for (final painter in _glyphs.values) {
      painter.dispose();
    }
    super.dispose();
  }

  double get _scale => _controller.value.getMaxScaleOnAxis();

  void _zoomTo(double scale, Offset focal) {
    final geometry = _geometry;
    if (geometry == null) return;
    final s = scale.clamp(minScale, maxScale).toDouble();
    if (s <= minScale) {
      _controller.value = Matrix4.identity();
      return;
    }
    final size = geometry.size;
    final tx = (focal.dx * (1 - s)).clamp(size.width * (1 - s), 0.0);
    final ty = (focal.dy * (1 - s)).clamp(size.height * (1 - s), 0.0);
    _controller.value = Matrix4.identity()
      ..translateByDouble(tx, ty, 0, 1)
      ..scaleByDouble(s, s, 1, 1);
  }

  void _zoomToElement(int number) {
    final geometry = _geometry;
    if (geometry == null) return;
    final e = elementByNumber(number);
    final center = geometry.cellRect(e.gridRow, e.gridColumn).center;
    _zoomTo(max(_scale, max(2.5, 44 / geometry.cell)), center);
  }

  void _onTapUp(TapUpDetails details) {
    widget.focusNode?.requestFocus();
    final geometry = _geometry;
    if (geometry == null) return;
    final local = details.localPosition;
    if (widget.zoomable) {
      final previous = _lastTapAt;
      final doubleTap =
          _doubleTapTimer?.isActive == true &&
          previous != null &&
          (local - previous).distance < 40 / _scale;
      _doubleTapTimer?.cancel();
      if (doubleTap) {
        _lastTapAt = null;
        if (_scale > 1.2) {
          _controller.value = Matrix4.identity();
        } else {
          _zoomTo(max(2.5, 44 / geometry.cell), local);
        }
        return;
      }
      _lastTapAt = local;
      final e = geometry.hitElement(local);
      // A tap on the already selected cell opens it, so it waits out the
      // double-tap window; a fresh selection responds at once.
      final deferred = e != null && e.number == widget.selected;
      _doubleTapTimer = Timer(kDoubleTapTimeout, () {
        _lastTapAt = null;
        if (deferred && mounted) widget.onSelect(e);
      });
      if (widget.tapZoomsWhenSmall && geometry.cell * _scale < 32) {
        _zoomTo(max(2.5, 44 / geometry.cell), local);
        return;
      }
      if (deferred) return;
      if (e != null) widget.onSelect(e);
      return;
    }
    final e = geometry.hitElement(local);
    if (e != null) widget.onSelect(e);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth.isFinite
          ? constraints.maxWidth
          : 18 * 56.0;
      final height = constraints.maxHeight.isFinite
          ? constraints.maxHeight
          : width * _gridRows / _gridColumns;
      final geometry = PeriodicGridGeometry.fit(Size(width, height));
      _geometry = geometry;
      return Focus(
        focusNode: widget.focusNode,
        onKeyEvent: widget.onKey,
        child: Builder(
          builder: (context) => _buildPaint(
            context,
            geometry,
            showCursor: Focus.of(context).hasFocus,
          ),
        ),
      );
    },
  );

  Widget _buildPaint(
    BuildContext context,
    PeriodicGridGeometry geometry, {
    required bool showCursor,
  }) {
    final width = geometry.size.width;
    final height = geometry.size.height;
    final theme = Theme.of(context);
    final painter = _TablePainter(
      geometry: geometry,
      glyphs: _glyphs,
      russian: widget.russian,
      colorOf: widget.colorOf,
      isDimmed: widget.isDimmed,
      marks: widget.marks,
      selected: widget.selected,
      cursor: widget.cursor,
      hovered: widget.hovered,
      showCursor: showCursor,
      colors: theme.colorScheme,
      onSelect: widget.onSelect,
    );
    Widget paint = MouseRegion(
      onHover: widget.onHover == null
          ? null
          : (event) =>
                widget.onHover!(geometry.hitElement(event.localPosition)),
      onExit: widget.onHover == null ? null : (_) => widget.onHover!(null),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: _onTapUp,
        child: CustomPaint(size: geometry.size, painter: painter),
      ),
    );
    if (widget.zoomable) {
      paint = InteractiveViewer(
        transformationController: _controller,
        minScale: minScale,
        maxScale: maxScale,
        boundaryMargin: EdgeInsets.zero,
        child: SizedBox(width: width, height: height, child: paint),
      );
    }
    return paint;
  }
}

/// Cell layout of the drawn grid inside a box of [size]; exposed so tests
/// can tap a cell without duplicating the layout rules.
class PeriodicGridGeometry {
  const PeriodicGridGeometry({
    required this.cell,
    required this.origin,
    required this.size,
  });

  /// The largest grid that fits [size], centred.
  factory PeriodicGridGeometry.fit(Size size) {
    final cell = min(size.width / _gridColumns, size.height / _gridRows);
    return PeriodicGridGeometry(
      cell: cell,
      origin: Offset(
        (size.width - cell * _gridColumns) / 2,
        (size.height - cell * _gridRows) / 2,
      ),
      size: size,
    );
  }
  final double cell;
  final Offset origin;
  final Size size;

  double get labelWidth => cell * .6;
  double get headerHeight => cell * .6;

  /// Vertical cell offset of a logical row (the f-block rows sit lower).
  double rowY(int row) => row <= 6 ? row.toDouble() : row + .5;

  Rect cellRect(int row, int column) => Rect.fromLTWH(
    origin.dx + labelWidth + column * cell,
    origin.dy + headerHeight + rowY(row) * cell,
    cell,
    cell,
  );

  PeriodicElement? hitElement(Offset p) {
    final x = (p.dx - origin.dx - labelWidth) / cell;
    final y = (p.dy - origin.dy - headerHeight) / cell;
    if (x < 0 || x >= 18 || y < 0) return null;
    final int row;
    if (y < 7) {
      row = y.floor();
    } else if (y >= 7.5 && y < 9.5) {
      row = (y - .5).floor();
    } else {
      return null;
    }
    return elementAt(row, x.floor());
  }
}

class _TablePainter extends CustomPainter {
  _TablePainter({
    required this.geometry,
    required this.glyphs,
    required this.russian,
    required this.colorOf,
    required this.isDimmed,
    required this.marks,
    required this.selected,
    required this.cursor,
    required this.hovered,
    required this.showCursor,
    required this.colors,
    required this.onSelect,
  });

  final PeriodicGridGeometry geometry;
  final Map<String, TextPainter> glyphs;
  final bool russian;
  final Color Function(PeriodicElement) colorOf;
  final bool Function(PeriodicElement) isDimmed;
  final Map<int, Color> marks;
  final int? selected, cursor, hovered;
  final bool showCursor;
  final ColorScheme colors;
  final ValueChanged<PeriodicElement> onSelect;

  TextPainter _glyph(
    String text,
    double size,
    Color color, {
    FontWeight weight = FontWeight.normal,
  }) {
    final key = '$text|${size.toStringAsFixed(2)}|${color.toARGB32()}|$weight';
    return glyphs.putIfAbsent(
      key,
      () => TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(fontSize: size, color: color, fontWeight: weight),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      )..layout(),
    );
  }

  void _paintText(
    Canvas canvas,
    String text,
    double size,
    Color color,
    Offset center, {
    FontWeight weight = FontWeight.normal,
    double? maxWidth,
  }) {
    var painter = _glyph(text, size, color, weight: weight);
    if (maxWidth != null && painter.width > maxWidth) {
      final shrunk = size * maxWidth / painter.width;
      if (shrunk < size * .6) return;
      painter = _glyph(text, shrunk, color, weight: weight);
    }
    painter.paint(
      canvas,
      center - Offset(painter.width / 2, painter.height / 2),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final g = geometry;
    final cell = g.cell;
    final hoveredElement = hovered == null ? null : elementByNumber(hovered!);
    final labelColor = colors.onSurfaceVariant;
    final labelSize = (cell * .34).clamp(6.0, 14.0);

    // Period and group bands for the hovered element.
    if (hoveredElement != null) {
      final band = Paint()..color = colors.primary.withValues(alpha: .1);
      final row = hoveredElement.gridRow;
      final first = g.cellRect(row, 0);
      final last = g.cellRect(row, 17);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(
            first.left - g.labelWidth,
            first.top,
            last.right,
            first.bottom,
          ),
          Radius.circular(cell * .15),
        ),
        band,
      );
      if (!hoveredElement.isFBlockRow) {
        final col = hoveredElement.gridColumn;
        final top = g.cellRect(0, col);
        final bottom = g.cellRect(6, col);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTRB(
              top.left,
              top.top - g.headerHeight,
              top.right,
              bottom.bottom,
            ),
            Radius.circular(cell * .15),
          ),
          band,
        );
      }
    }

    // Group numbers above the columns, period numbers left of the rows.
    for (var col = 0; col < 18; col++) {
      final rect = g.cellRect(0, col);
      final active = hoveredElement?.gridColumn == col;
      _paintText(
        canvas,
        '${col + 1}',
        labelSize,
        active ? colors.primary : labelColor,
        Offset(rect.center.dx, rect.top - g.headerHeight / 2),
        weight: active ? FontWeight.bold : FontWeight.normal,
      );
    }
    for (var row = 0; row < 7; row++) {
      final rect = g.cellRect(row, 0);
      final active = hoveredElement?.gridRow == row;
      _paintText(
        canvas,
        '${row + 1}',
        labelSize,
        active ? colors.primary : labelColor,
        Offset(rect.left - g.labelWidth / 2, rect.center.dy),
        weight: active ? FontWeight.bold : FontWeight.normal,
      );
    }
    // Placeholders in period 6/7, group 3 pointing to the detached rows.
    for (final (row, text) in [(5, '57–71'), (6, '89–103')]) {
      final rect = g.cellRect(row, 2).deflate(cell * .08);
      final color = colorOf(elementByNumber(row == 5 ? 57 : 89));
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(cell * .12)),
        Paint()
          ..color = color.withValues(alpha: .45)
          ..style = PaintingStyle.stroke
          ..strokeWidth = max(1, cell * .03),
      );
      _paintText(
        canvas,
        text,
        cell * .22,
        labelColor,
        rect.center,
        maxWidth: rect.width * .9,
      );
    }

    final gap = cell * .06;
    final radius = Radius.circular(cell * .12);
    final showNumber = cell >= 22;
    final showName = cell >= 54;
    for (final e in periodicElements) {
      final rect = g.cellRect(e.gridRow, e.gridColumn).deflate(gap);
      final dimmed = isDimmed(e);
      final mark = marks[e.number];
      var fill = mark ?? colorOf(e);
      var ink = mark == null ? colors.onSurface : Colors.white;
      if (dimmed && mark == null) {
        fill = fill.withValues(alpha: .2);
        ink = ink.withValues(alpha: .35);
      }
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, radius),
        Paint()..color = fill,
      );
      if (hovered == e.number) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, radius),
          Paint()
            ..color = colors.onSurface.withValues(alpha: .7)
            ..style = PaintingStyle.stroke
            ..strokeWidth = max(1, cell * .04),
        );
      }
      if (selected == e.number) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, radius),
          Paint()
            ..color = colors.primary
            ..style = PaintingStyle.stroke
            ..strokeWidth = max(2, cell * .08),
        );
      }
      if (showCursor && cursor == e.number) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect.inflate(gap * .8), radius),
          Paint()
            ..color = colors.tertiary
            ..style = PaintingStyle.stroke
            ..strokeWidth = max(1.5, cell * .05),
        );
      }
      final symbolSize = showName ? cell * .34 : cell * .42;
      final symbolY = showName
          ? rect.top + cell * .46
          : showNumber
          ? rect.top + cell * .56
          : rect.center.dy;
      _paintText(
        canvas,
        e.symbol,
        symbolSize,
        ink,
        Offset(rect.center.dx, symbolY),
        weight: FontWeight.bold,
        maxWidth: rect.width * .95,
      );
      if (showNumber) {
        _paintText(
          canvas,
          '${e.number}',
          cell * .2,
          ink.withValues(alpha: ink.a * .85),
          Offset(rect.left + cell * .06 + cell * .14, rect.top + cell * .15),
        );
      }
      if (showName) {
        _paintText(
          canvas,
          russian ? e.nameRu : e.name,
          cell * .15,
          ink.withValues(alpha: ink.a * .9),
          Offset(rect.center.dx, rect.bottom - cell * .14),
          maxWidth: rect.width * .92,
        );
      }
    }
  }

  @override
  SemanticsBuilderCallback get semanticsBuilder =>
      (size) => [
        for (final e in periodicElements)
          CustomPainterSemantics(
            rect: geometry.cellRect(e.gridRow, e.gridColumn),
            properties: SemanticsProperties(
              label:
                  '${e.symbol}, ${(russian ? e.nameRu : e.name).toLowerCase()}, ${e.number}',
              textDirection: TextDirection.ltr,
              button: true,
              selected: selected == e.number,
              onTap: () => onSelect(e),
            ),
          ),
      ];

  @override
  bool shouldRepaint(covariant _TablePainter old) => true;

  @override
  bool shouldRebuildSemantics(covariant _TablePainter old) =>
      old.selected != selected ||
      old.russian != russian ||
      old.geometry.cell != geometry.cell ||
      old.geometry.origin != geometry.origin;
}

/// Coloured square with the symbol and number, for lists and panels.
class _SymbolTile extends StatelessWidget {
  const _SymbolTile({
    required this.element,
    required this.mode,
    required this.size,
  });
  final PeriodicElement element;
  final ElementColorMode mode;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: elementColor(element, mode, theme.brightness),
        borderRadius: BorderRadius.circular(size * .14),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            element.symbol,
            style: TextStyle(
              fontSize: size * .38,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
              height: 1,
            ),
            textScaler: TextScaler.noScaling,
          ),
          Text(
            '${element.number}',
            style: TextStyle(
              fontSize: size * .2,
              color: theme.colorScheme.onSurface,
              height: 1.2,
            ),
            textScaler: TextScaler.noScaling,
          ),
        ],
      ),
    );
  }
}

/// Element details for the side panel and the bottom sheet.
class _ElementDetails extends StatelessWidget {
  const _ElementDetails({
    required this.element,
    required this.mode,
    required this.onPrevious,
    required this.onNext,
    required this.onTrain,
  });
  final PeriodicElement element;
  final ElementColorMode mode;
  final VoidCallback? onPrevious, onNext, onTrain;

  String _temperature(double? kelvin, {required bool russian}) {
    if (kelvin == null) return russian ? 'нет данных' : 'no data';
    final k = kelvin == kelvin.roundToDouble()
        ? kelvin.toStringAsFixed(0)
        : kelvin.toStringAsFixed(2);
    final c = (kelvin - 273.15).toStringAsFixed(
      (kelvin - 273.15).abs() < 10 ? 2 : 0,
    );
    return '$k K ($c °C)';
  }

  @override
  Widget build(BuildContext context) {
    final e = element;
    final theme = Theme.of(context);
    final russian = _isRussian(context);
    String t(String en, String ru) => russian ? ru : en;
    final stateLabel = switch (e.state) {
      MatterState.solid => t('solid', 'твёрдое'),
      MatterState.liquid => t('liquid', 'жидкое'),
      MatterState.gas => t('gas', 'газ'),
      MatterState.unknown => t('unknown', 'неизвестно'),
    };
    final predicted = t(' (predicted)', ' (предсказание)');
    final facts = <(String, String, String?)>[
      (
        t('Atomic mass', 'Атомная масса'),
        '${e.mass} ${t('u', 'а. е. м.')}',
        e.massIsIsotope
            ? t(
                'Mass of the longest-lived or best-known isotope.',
                'Масса наиболее долгоживущего или известного изотопа.',
              )
            : null,
      ),
      (
        t('State at standard conditions', 'Состояние при н. у.'),
        '$stateLabel${e.statePredicted ? predicted : ''}',
        null,
      ),
      (
        t('Electron configuration', 'Электронная конфигурация'),
        '${e.electronConfiguration}${e.configurationPredicted ? predicted : ''}',
        null,
      ),
      if (e.electronegativity.isNotEmpty)
        (
          t('Electronegativity (Pauling)', 'Электроотрицательность (Полинг)'),
          e.electronegativity,
          null,
        ),
      if (e.oxidationStates.isNotEmpty)
        (t('Oxidation states', 'Степени окисления'), e.oxidationStates, null),
      (
        t('Melting point', 'Температура плавления'),
        _temperature(e.meltingPointK, russian: russian),
        null,
      ),
      (
        t('Boiling point', 'Температура кипения'),
        _temperature(e.boilingPointK, russian: russian),
        null,
      ),
      if (e.density.isNotEmpty)
        (
          t('Density', 'Плотность'),
          '${e.density} ${t('g/cm³', 'г/см³')}',
          null,
        ),
      if (e.yearDiscovered.isNotEmpty)
        (
          t('Discovered', 'Открыт'),
          e.yearDiscovered == 'Ancient'
              ? t('known since antiquity', 'известен с древности')
              : e.yearDiscovered,
          null,
        ),
    ];
    final blockLabel = switch (e.block) {
      ElementBlock.s => t('s-block', 's-блок'),
      ElementBlock.p => t('p-block', 'p-блок'),
      ElementBlock.d => t('d-block', 'd-блок'),
      ElementBlock.f => t('f-block', 'f-блок'),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _SymbolTile(element: e, mode: mode, size: 72),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    russian ? e.nameRu : e.name,
                    style: theme.textTheme.headlineSmall,
                  ),
                  Text(
                    '${russian ? e.name : e.nameRu} · № ${e.number}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: t('Previous element', 'Предыдущий элемент'),
              onPressed: onPrevious,
              icon: const Icon(Icons.chevron_left),
            ),
            IconButton(
              tooltip: t('Next element', 'Следующий элемент'),
              onPressed: onNext,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            Chip(
              avatar: CircleAvatar(
                backgroundColor: elementColor(
                  e,
                  ElementColorMode.category,
                  theme.brightness,
                ),
              ),
              label: Text(familyLabel(e.family, russian: russian)),
              visualDensity: VisualDensity.compact,
            ),
            Chip(
              label: Text('${t('Period', 'Период')} ${e.period}'),
              visualDensity: VisualDensity.compact,
            ),
            Chip(
              label: Text(
                e.group == null
                    ? t('No group (f-block row)', 'Вне групп (f-ряд)')
                    : '${t('Group', 'Группа')} ${e.group}',
              ),
              visualDensity: VisualDensity.compact,
            ),
            Chip(label: Text(blockLabel), visualDensity: VisualDensity.compact),
          ],
        ),
        const Divider(height: 24),
        for (final (label, value, note) in facts)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(value, style: theme.textTheme.bodyLarge),
                if (note != null) Text(note, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        const Divider(height: 24),
        Text(
          t('Sources', 'Источники'),
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        TextButton.icon(
          style: TextButton.styleFrom(padding: EdgeInsets.zero),
          onPressed: () => launchUrl(
            Uri.parse(e.pubChemUrl),
            mode: LaunchMode.externalApplication,
          ),
          icon: const Icon(Icons.open_in_new, size: 18),
          label: Text('PubChem (NCBI/NLM): ${e.name}'),
        ),
        Text(
          t(
            'Russian names: project glossary.',
            'Русские названия: словарь проекта.',
          ),
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          key: const Key('train-element'),
          onPressed: onTrain,
          icon: const Icon(Icons.school_outlined),
          label: Text(t('Practise', 'Тренировать')),
        ),
      ],
    );
  }
}

class _ElementSheet extends StatefulWidget {
  const _ElementSheet({
    required this.initial,
    required this.mode,
    required this.onChanged,
    required this.onTrain,
  });
  final PeriodicElement initial;
  final ElementColorMode mode;
  final ValueChanged<PeriodicElement> onChanged;
  final ValueChanged<PeriodicElement> onTrain;

  @override
  State<_ElementSheet> createState() => _ElementSheetState();
}

class _ElementSheetState extends State<_ElementSheet> {
  late PeriodicElement element = widget.initial;

  void _step(int delta) {
    final next = element.number + delta;
    if (next < 1 || next > periodicElements.length) return;
    setState(() => element = elementByNumber(next));
    widget.onChanged(element);
  }

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * .8,
    ),
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: _ElementDetails(
        element: element,
        mode: widget.mode,
        onPrevious: element.number > 1 ? () => _step(-1) : null,
        onNext: element.number < periodicElements.length
            ? () => _step(1)
            : null,
        onTrain: () => widget.onTrain(element),
      ),
    ),
  );
}

enum ElementTrainingMode { find, name }

/// Two quick drills on the table: find a named element, or name the
/// highlighted one. Distractors are neighbours by period and group.
class ElementTrainingPage extends StatefulWidget {
  const ElementTrainingPage({
    super.key,
    this.initialNumber,
    this.initialMode = ElementTrainingMode.find,
    this.seed,
  });

  /// First question is about this element, if given.
  final int? initialNumber;
  final ElementTrainingMode initialMode;
  final int? seed;

  @override
  State<ElementTrainingPage> createState() => _ElementTrainingPageState();
}

class _ElementTrainingPageState extends State<ElementTrainingPage> {
  late final Random _random = Random(widget.seed);
  late ElementTrainingMode _mode = widget.initialMode;
  final _zoom = TransformationController();
  final _recent = <int>[];
  late PeriodicElement _target;
  List<PeriodicElement> _distractors = const [];
  final _order = <int, double>{};
  int? _answer;
  var _correct = 0, _total = 0;
  (int, int)? _zoomTarget;
  var _zoomRevision = 0;

  @override
  void initState() {
    super.initState();
    _pickQuestion(first: widget.initialNumber);
  }

  @override
  void dispose() {
    _zoom.dispose();
    super.dispose();
  }

  void _nextQuestion() => setState(_pickQuestion);

  void _pickQuestion({int? first}) {
    PeriodicElement target;
    if (first != null) {
      target = elementByNumber(first);
    } else {
      do {
        target = periodicElements[_random.nextInt(periodicElements.length)];
      } while (_recent.contains(target.number));
    }
    _recent.add(target.number);
    if (_recent.length > 12) _recent.removeAt(0);
    _target = target;
    _distractors = elementDistractors(target, 5, _random);
    _order
      ..clear()
      ..[target.number] = _random.nextDouble();
    for (final d in _distractors) {
      _order[d.number] = _random.nextDouble();
    }
    _answer = null;
    _zoomTarget = _mode == ElementTrainingMode.name
        ? (target.number, ++_zoomRevision)
        : null;
    if (_mode == ElementTrainingMode.find) _zoom.value = Matrix4.identity();
  }

  /// Four options on phones, six on wide screens; the target is always in.
  List<PeriodicElement> _options(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= periodicWideBreakpoint;
    return [_target, ..._distractors.take(wide ? 5 : 3)]
      ..sort((a, b) => _order[a.number]!.compareTo(_order[b.number]!));
  }

  void _answerWith(PeriodicElement e) {
    if (_answer != null) return;
    setState(() {
      _answer = e.number;
      _total++;
      if (e.number == _target.number) _correct++;
    });
  }

  void _switchMode(ElementTrainingMode mode) {
    if (mode == _mode) return;
    _mode = mode;
    _nextQuestion();
  }

  Map<int, Color> get _marks {
    final answer = _answer;
    if (answer == null) return const {};
    return {
      _target.number: const Color(0xFF2E7D32),
      if (answer != _target.number) answer: const Color(0xFFC62828),
    };
  }

  String _describe(PeriodicElement e, {required bool russian}) {
    final name = russian ? e.nameRu : e.name;
    final group = e.group == null
        ? (russian ? 'f-ряд' : 'f-block row')
        : (russian ? 'группа ${e.group}' : 'group ${e.group}');
    final period = russian ? 'период ${e.period}' : 'period ${e.period}';
    return '${e.symbol} — $name, № ${e.number}: ${familySingular(e.family, russian: russian)}, $period, $group.';
  }

  Widget _grid(BuildContext context, {required bool zoomable}) {
    final brightness = Theme.of(context).brightness;
    final naming = _mode == ElementTrainingMode.name;
    return _PeriodicGrid(
      key: const Key('training-grid'),
      russian: _isRussian(context),
      colorOf: (e) => elementColor(e, ElementColorMode.category, brightness),
      isDimmed: (e) => naming && _answer == null && e.number != _target.number,
      selected: naming ? _target.number : null,
      marks: _marks,
      onSelect: naming ? (_) {} : _answerWith,
      zoomable: zoomable,
      tapZoomsWhenSmall: !naming,
      controller: zoomable ? _zoom : null,
      zoomTarget: zoomable ? _zoomTarget : null,
    );
  }

  Widget _prompt(BuildContext context) {
    final theme = Theme.of(context);
    final russian = _isRussian(context);
    final name = russian ? _target.nameRu : _target.name;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _mode == ElementTrainingMode.find
                  ? _t(context, 'Find on the table:', 'Найдите в таблице:')
                  : _t(
                      context,
                      'Which element is highlighted?',
                      'Что это за элемент?',
                    ),
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 4),
            Text(
              _mode == ElementTrainingMode.find
                  ? name
                  : _t(
                      context,
                      'Pick the name of the outlined cell',
                      'Выберите название выделенной клетки',
                    ),
              key: const Key('training-prompt'),
              style: _mode == ElementTrainingMode.find
                  ? theme.textTheme.headlineSmall
                  : theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              '${_t(context, 'Score', 'Счёт')}: $_correct / $_total',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _optionButtons(BuildContext context) {
    final russian = _isRussian(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final option in _options(context))
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Builder(
              builder: (context) {
                final answered = _answer != null;
                final isTarget = option.number == _target.number;
                final isChosen = option.number == _answer;
                Color? background;
                if (answered && isTarget) {
                  background = const Color(0xFF2E7D32);
                } else if (answered && isChosen) {
                  background = const Color(0xFFC62828);
                }
                return FilledButton.tonal(
                  key: Key('option-${option.number}'),
                  style: background == null
                      ? null
                      : FilledButton.styleFrom(
                          backgroundColor: background,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: background,
                          disabledForegroundColor: Colors.white,
                        ),
                  onPressed: answered ? null : () => _answerWith(option),
                  child: Text(russian ? option.nameRu : option.name),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _feedback(BuildContext context) {
    final answer = _answer;
    if (answer == null) return const SizedBox.shrink();
    final russian = _isRussian(context);
    final theme = Theme.of(context);
    final correct = answer == _target.number;
    final chosen = elementByNumber(answer);
    return Card(
      key: const Key('training-feedback'),
      margin: EdgeInsets.zero,
      color: correct
          ? const Color(0xFF2E7D32).withValues(alpha: .18)
          : const Color(0xFFC62828).withValues(alpha: .16),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              correct
                  ? _t(context, 'Correct!', 'Верно!')
                  : _t(context, 'Not quite.', 'Неверно.'),
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            if (!correct)
              Text(
                '${_t(context, 'You chose', 'Вы выбрали')} ${_describe(chosen, russian: russian)}',
              ),
            Text(_describe(_target, russian: russian)),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                key: const Key('training-next'),
                onPressed: _nextQuestion,
                child: Text(_t(context, 'Next', 'Далее')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _modeSwitch(BuildContext context) =>
      SegmentedButton<ElementTrainingMode>(
        showSelectedIcon: false,
        segments: [
          ButtonSegment(
            value: ElementTrainingMode.find,
            label: Text(_t(context, 'Find on table', 'Найти в таблице')),
          ),
          ButtonSegment(
            value: ElementTrainingMode.name,
            label: Text(_t(context, 'Name the element', 'Назвать элемент')),
          ),
        ],
        selected: {_mode},
        onSelectionChanged: (s) => _switchMode(s.first),
      );

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= periodicWideBreakpoint;
    final naming = _mode == ElementTrainingMode.name;
    return Scaffold(
      appBar: AppBar(
        title: Text(_t(context, 'Element practice', 'Тренировка: элементы')),
      ),
      body: wide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _grid(context, zoomable: false),
                  ),
                ),
                const VerticalDivider(width: 1),
                SizedBox(
                  width: 380,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _modeSwitch(context),
                      const SizedBox(height: 12),
                      _prompt(context),
                      const SizedBox(height: 12),
                      if (naming) _optionButtons(context),
                      if (!naming && _answer == null)
                        Text(
                          _t(
                            context,
                            'Click the element’s cell in the table.',
                            'Нажмите на клетку элемента в таблице.',
                          ),
                        ),
                      _feedback(context),
                    ],
                  ),
                ),
              ],
            )
          : MapScrollView(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _modeSwitch(context),
                  const SizedBox(height: 10),
                  _prompt(context),
                  const SizedBox(height: 10),
                  MapInteraction(
                    child: AspectRatio(
                      aspectRatio: _gridColumns / _gridRows,
                      child: _grid(context, zoomable: true),
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (!naming && _answer == null)
                    Text(
                      _t(
                        context,
                        'Tap to zoom in, then tap the element’s cell.',
                        'Нажмите, чтобы приблизить, затем выберите клетку.',
                      ),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  const SizedBox(height: 6),
                  if (naming) _optionButtons(context),
                  _feedback(context),
                ],
              ),
            ),
    );
  }
}
