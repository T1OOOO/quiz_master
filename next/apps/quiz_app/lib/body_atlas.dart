/// An interactive, layered body scene for the Quizipedia anatomy atlases.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/gestures.dart' show kDoubleTapTimeout;
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'atlas_media.dart';
import 'body_scene_geometry.dart';
import 'fact_practice.dart';
import 'organ_atlas.dart';
import 'organ_atlas_models.dart';
import 'russian_learning_text.dart';
import 'vascular_atlas.dart';

export 'body_scene_geometry.dart' show BodyLayer;

/// Side panel breakpoint: below this the organ card is a bottom sheet.
const bodyAtlasWideBreakpoint = 840.0;

// ---------------------------------------------------------------------------
// Scene
// ---------------------------------------------------------------------------

class BodyScene extends StatefulWidget {
  const BodyScene({
    super.key,
    required this.controller,
    required this.layers,
    required this.selectedId,
    required this.relatedIds,
    required this.names,
    required this.onSelect,
    required this.semanticsLabel,
    this.visibleFraction = 1,
  });
  final TransformationController controller;
  final Set<BodyLayer> layers;
  final String? selectedId;
  final Set<String> relatedIds;
  final Map<String, String> names;

  /// `null` means a tap on empty space.
  final ValueChanged<String?> onSelect;
  final String semanticsLabel;

  /// The share of the viewport height not hidden by an inline panel; camera
  /// moves centre structures inside it.
  final double visibleFraction;

  @override
  State<BodyScene> createState() => BodySceneState();
}

class BodySceneState extends State<BodyScene>
    with SingleTickerProviderStateMixin {
  static const minScale = 1.0, maxScale = 6.0;
  late final AnimationController _camera = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 240),
  );
  Animation<Matrix4>? _frames;
  // A tap selects at once; a second tap inside the double-tap window zooms.
  // The built-in double-tap recognizer would hold every single tap for 300 ms.
  Timer? _doubleTapTimer;
  Offset? _lastTapAt;
  Size _view = Size.zero;
  late List<BodyStructure> _visible = visibleStructures(widget.layers);
  final _labelCache = <String, TextPainter>{};

  /// Structures of the active layers in paint order (skeleton behind organs,
  /// glands and vessels on top).
  static List<BodyStructure> visibleStructures(Set<BodyLayer> layers) {
    int rank(BodyStructure s) =>
        s.layers.map((layer) => layer.index).reduce(math.max) * 100 + s.depth;
    return bodyStructures.where((s) => s.visibleIn(layers)).toList()
      ..sort((a, b) => rank(a).compareTo(rank(b)));
  }

  @override
  void initState() {
    super.initState();
    _camera.addListener(() {
      if (_frames != null) widget.controller.value = _frames!.value;
    });
  }

  @override
  void didUpdateWidget(covariant BodyScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!setEquals(oldWidget.layers, widget.layers)) {
      _visible = visibleStructures(widget.layers);
    }
  }

  @override
  void dispose() {
    _doubleTapTimer?.cancel();
    _camera.dispose();
    for (final painter in _labelCache.values) {
      painter.dispose();
    }
    super.dispose();
  }

  double get _fit => math.min(
    _view.width / bodySceneSize.width,
    _view.height / bodySceneSize.height,
  );
  Offset get _origin => Offset(
    (_view.width - bodySceneSize.width * _fit) / 2,
    (_view.height - bodySceneSize.height * _fit) / 2,
  );
  Offset _toScene(Offset childPoint) => (childPoint - _origin) / _fit;
  Rect _childRect(Rect sceneRect) => Rect.fromPoints(
    _origin + sceneRect.topLeft * _fit,
    _origin + sceneRect.bottomRight * _fit,
  );
  double get scale => widget.controller.value.getMaxScaleOnAxis();

  /// Keep the viewport over the scene; gestures get the same limit from
  /// `boundaryMargin: EdgeInsets.zero`.
  Matrix4 _clamp(Matrix4 target) {
    final s = target.getMaxScaleOnAxis();
    final t = target.getTranslation();
    return target..setTranslationRaw(
      t.x.clamp(_view.width * (1 - s), 0.0),
      t.y.clamp(_view.height * (1 - s), 0.0),
      0,
    );
  }

  void _move(Matrix4 target) {
    if (_view.isEmpty) return;
    _camera.stop();
    target = _clamp(target);
    if (MediaQuery.disableAnimationsOf(context)) {
      widget.controller.value = target;
      return;
    }
    _frames = Matrix4Tween(
      begin: widget.controller.value.clone(),
      end: target,
    ).animate(CurvedAnimation(parent: _camera, curve: Curves.easeOutCubic));
    _camera.forward(from: 0);
  }

  Matrix4 _cameraAt(Offset childPoint, Offset viewPoint, double s) =>
      Matrix4.identity()
        ..translateByDouble(
          viewPoint.dx - childPoint.dx * s,
          viewPoint.dy - childPoint.dy * s,
          0,
          1,
        )
        ..scaleByDouble(s, s, 1, 1);

  void zoomBy(double factor, [Offset? focalPoint]) {
    final next = (scale * factor).clamp(minScale, maxScale).toDouble();
    if (next == minScale) return fit();
    final center =
        focalPoint ??
        Offset(_view.width / 2, _view.height * widget.visibleFraction / 2);
    _move(_cameraAt(widget.controller.toScene(center), center, next));
  }

  void fit() => _move(Matrix4.identity());

  /// Frame a structure in the uncovered part of the viewport.
  void focusOn(String id, {double maxZoom = maxScale}) {
    final structure = bodyStructureById[id];
    if (structure == null || _view.isEmpty) return;
    final rect = _childRect(structure.bounds).inflate(8);
    final height = _view.height * widget.visibleFraction;
    final next = math
        .min(_view.width * .5 / rect.width, height * .5 / rect.height)
        .clamp(minScale, maxZoom)
        .toDouble();
    _move(_cameraAt(rect.center, Offset(_view.width / 2, height / 2), next));
  }

  /// Pan so a structure is not hidden under an inline panel; zoom in a little
  /// when the whole scene is already shown and panning is impossible.
  void ensureVisible(String id) {
    final structure = bodyStructureById[id];
    if (structure == null || _view.isEmpty) return;
    final matrix = widget.controller.value;
    final rect = MatrixUtils.transformRect(
      matrix,
      _childRect(structure.bounds),
    );
    final limit = _view.height * widget.visibleFraction;
    var dy = 0.0, dx = 0.0;
    if (rect.bottom > limit - 12) dy = limit - 12 - rect.bottom;
    if (rect.top + dy < 12) dy = 12 - rect.top;
    if (rect.right > _view.width - 12) dx = _view.width - 12 - rect.right;
    if (rect.left + dx < 12) dx = 12 - rect.left;
    if (dx == 0 && dy == 0) return;
    if (scale <= 1.01) return focusOn(id, maxZoom: 2.4);
    final t = matrix.getTranslation();
    _move(matrix.clone()..setTranslationRaw(t.x + dx, t.y + dy, 0));
  }

  String? hitTest(Offset scenePoint) {
    final pixel = 1 / (_fit * scale);
    BodyStructure? best;
    var bestScore = double.infinity;
    for (final s in _visible) {
      // Fills get a 10 px margin; every stroke gets at least a 28 px band.
      final tolerance = s.strokeWidth == null
          ? 10 * pixel
          : math.max(0.0, 14 * pixel - s.strokeWidth! / 2);
      final score = s.hitScore(scenePoint, tolerance);
      if (score == null) continue;
      // Closest first; a stroke beats a fill it is drawn over; then smallest.
      final better =
          best == null ||
          score < bestScore ||
          (score == bestScore &&
              (s.isStroke && !best.isStroke ||
                  (s.isStroke == best.isStroke && s.area < best.area)));
      if (better) {
        best = s;
        bestScore = score;
      }
    }
    return best?.id;
  }

  void _onTapUp(TapUpDetails details) {
    final local = details.localPosition;
    final previous = _lastTapAt;
    final doubleTap =
        _doubleTapTimer?.isActive == true &&
        previous != null &&
        (local - previous).distance < 40 / scale;
    _doubleTapTimer?.cancel();
    if (doubleTap) {
      _lastTapAt = null;
      if (scale >= maxScale - .01) {
        fit();
      } else {
        zoomBy(2, MatrixUtils.transformPoint(widget.controller.value, local));
      }
      return;
    }
    _lastTapAt = local;
    _doubleTapTimer = Timer(kDoubleTapTimeout, () => _lastTapAt = null);
    widget.onSelect(hitTest(_toScene(local)));
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final next = Size(constraints.maxWidth, constraints.maxHeight);
      if (next != _view && !_view.isEmpty) {
        // A rotated or resized viewport changes the fitted scene; keep the
        // same scene point under the viewport centre at the same zoom, or
        // the camera is stranded outside the body.
        final s = scale;
        final focus = _toScene(
          widget.controller.toScene(_view.center(Offset.zero)),
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // A camera move started this frame already targets the new size.
          if (!mounted || _camera.isAnimating) return;
          widget.controller.value = _clamp(
            _cameraAt(_origin + focus * _fit, _view.center(Offset.zero), s),
          );
        });
      }
      _view = next;
      final theme = Theme.of(context);
      return Stack(
        fit: StackFit.expand,
        children: [
          InteractiveViewer(
            key: const Key('body-scene'),
            transformationController: widget.controller,
            minScale: minScale,
            maxScale: maxScale,
            boundaryMargin: EdgeInsets.zero,
            child: SizedBox(
              width: _view.width,
              height: _view.height,
              child: Semantics(
                container: true,
                label: widget.semanticsLabel,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: _onTapUp,
                  child: RepaintBoundary(
                    child: CustomPaint(
                      size: _view,
                      painter: _BodyPainter(
                        visible: _visible,
                        selectedId: widget.selectedId,
                        relatedIds: widget.relatedIds,
                        colors: theme.colorScheme,
                        fit: _fit,
                        origin: _origin,
                        names: widget.names,
                        onSelect: widget.onSelect,
                        textDirection: Directionality.of(context),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: ValueListenableBuilder<Matrix4>(
                valueListenable: widget.controller,
                builder: (context, transform, _) => CustomPaint(
                  painter: _LabelPainter(
                    transform: transform,
                    visible: _visible,
                    selectedId: widget.selectedId,
                    relatedIds: widget.relatedIds,
                    names: widget.names,
                    fit: _fit,
                    origin: _origin,
                    colors: theme.colorScheme,
                    textStyle: theme.textTheme.labelSmall!.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                    textScaler: MediaQuery.textScalerOf(context),
                    textDirection: Directionality.of(context),
                    cache: _labelCache,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}

class _BodyPainter extends CustomPainter {
  const _BodyPainter({
    required this.visible,
    required this.selectedId,
    required this.relatedIds,
    required this.colors,
    required this.fit,
    required this.origin,
    required this.names,
    required this.onSelect,
    required this.textDirection,
  });
  final TextDirection textDirection;
  final List<BodyStructure> visible;
  final String? selectedId;
  final Set<String> relatedIds;
  final ColorScheme colors;
  final double fit;
  final Offset origin;
  final Map<String, String> names;
  final ValueChanged<String?> onSelect;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.scale(fit);
    final body = Paint()..color = colors.surfaceContainerHighest;
    for (final part in BodySilhouette.fills) {
      canvas.drawPath(part, body);
    }
    for (final (part, width) in BodySilhouette.strokes) {
      canvas.drawPath(
        part,
        Paint()
          ..color = body.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
    final edge = Paint()
      ..color = colors.onSurface.withValues(alpha: .35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = .8 / fit;
    for (final s in visible) {
      final selected = s.id == selectedId;
      final related = relatedIds.contains(s.id);
      final dim = selectedId != null && !selected && !related;
      final color = dim ? s.color.withValues(alpha: .5) : s.color;
      final highlight = selected
          ? colors.primary
          : related
          ? colors.tertiary
          : null;
      if (s.strokeWidth case final width?) {
        if (highlight != null) {
          canvas.drawPath(
            s.path,
            Paint()
              ..color = highlight.withValues(alpha: selected ? .9 : .6)
              ..style = PaintingStyle.stroke
              ..strokeWidth = width + (selected ? 6 : 3) / fit
              ..strokeCap = StrokeCap.round
              ..strokeJoin = StrokeJoin.round,
          );
        }
        canvas.drawPath(
          s.path,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = width
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round,
        );
      } else {
        canvas.drawPath(s.path, Paint()..color = color);
        canvas.drawPath(s.path, edge);
        if (highlight != null) {
          canvas.drawPath(
            s.path,
            Paint()
              ..color = highlight
              ..style = PaintingStyle.stroke
              ..strokeWidth = (selected ? 3 : 1.8) / fit
              ..strokeJoin = StrokeJoin.round,
          );
        }
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BodyPainter old) =>
      old.visible != visible ||
      old.selectedId != selectedId ||
      !setEquals(old.relatedIds, relatedIds) ||
      old.colors != colors ||
      old.fit != fit ||
      old.origin != origin;

  @override
  SemanticsBuilderCallback get semanticsBuilder =>
      (size) => [
        for (final s in visible.reversed)
          CustomPainterSemantics(
            key: ValueKey('body-structure-${s.id}'),
            rect: Rect.fromPoints(
              origin + s.bounds.topLeft * fit,
              origin + s.bounds.bottomRight * fit,
            ),
            properties: SemanticsProperties(
              label: names[s.id] ?? s.id,
              textDirection: textDirection,
              button: true,
              selected: s.id == selectedId,
              onTap: () => onSelect(s.id),
            ),
          ),
      ];
}

class _LabelPainter extends CustomPainter {
  const _LabelPainter({
    required this.transform,
    required this.visible,
    required this.selectedId,
    required this.relatedIds,
    required this.names,
    required this.fit,
    required this.origin,
    required this.colors,
    required this.textStyle,
    required this.textScaler,
    required this.textDirection,
    required this.cache,
  });
  final Matrix4 transform;
  final List<BodyStructure> visible;
  final String? selectedId;
  final Set<String> relatedIds;
  final Map<String, String> names;
  final double fit;
  final Offset origin;
  final ColorScheme colors;
  final TextStyle textStyle;
  final TextScaler textScaler;
  final TextDirection textDirection;
  final Map<String, TextPainter> cache;

  int _priority(BodyStructure s) => s.id == selectedId
      ? 2
      : relatedIds.contains(s.id)
      ? 1
      : 0;

  @override
  void paint(Canvas canvas, Size size) {
    // Labels near the edge must not spill over the chips or the side panel.
    canvas.clipRect(Offset.zero & size);
    final ordered = [...visible]
      ..sort((a, b) {
        final rank = _priority(b).compareTo(_priority(a));
        return rank != 0 ? rank : b.area.compareTo(a.area);
      });
    // The zoom controls sit in the top-right corner; keep labels out of it.
    final placed = <Rect>[Rect.fromLTWH(size.width - 64, 0, 64, 168)];
    final view = Offset.zero & size;
    final leader = Paint()
      ..color = colors.onSurfaceVariant
      ..strokeWidth = 1;
    final pill = Paint()..color = colors.surface.withValues(alpha: .92);
    final selectedPill = Paint()..color = colors.primaryContainer;
    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final s in ordered) {
      final text = names[s.id];
      if (text == null) continue;
      final selected = s.id == selectedId;
      final related = relatedIds.contains(s.id);
      final screen = MatrixUtils.transformRect(
        transform,
        Rect.fromPoints(
          origin + s.bounds.topLeft * fit,
          origin + s.bounds.bottomRight * fit,
        ),
      );
      if (!screen.overlaps(view)) continue;
      // Small structures stay unlabelled until the learner zooms in.
      if (!selected && !related && screen.longestSide < 18) continue;
      final at = MatrixUtils.transformPoint(transform, origin + s.anchor * fit);
      if (!view.inflate(24).contains(at)) continue;
      final painter = cache.putIfAbsent(
        '$text|${textScaler.scale(10)}|${textStyle.color?.toARGB32()}',
        () => TextPainter(
          text: TextSpan(text: text, style: textStyle),
          textDirection: textDirection,
          textScaler: textScaler,
          maxLines: 1,
          ellipsis: '…',
        )..layout(maxWidth: 150),
      );
      final w = painter.width + 12, h = painter.height + 6;
      final right = at.dx >= size.width / 2;
      var rect = Rect.fromLTWH(
        right ? at.dx + 14 : at.dx - 14 - w,
        at.dy - h / 2,
        w,
        h,
      );
      if (rect.right > size.width - 2) {
        rect = rect.translate(size.width - 2 - rect.right, 0);
      }
      if (rect.left < 2) rect = rect.translate(2 - rect.left, 0);
      if (placed.any((other) => other.overlaps(rect.inflate(2)))) {
        if (!selected) continue;
        rect = rect.translate(0, h + 4);
      }
      placed.add(rect);
      final attach = Offset(
        (at.dx - rect.left).abs() < (at.dx - rect.right).abs()
            ? rect.left
            : rect.right,
        rect.center.dy,
      );
      canvas.drawLine(at, attach, leader);
      canvas.drawCircle(
        at,
        2.5,
        Paint()..color = selected ? colors.primary : colors.onSurfaceVariant,
      );
      final rounded = RRect.fromRectAndRadius(rect, Radius.circular(h / 2));
      canvas.drawRRect(rounded, selected ? selectedPill : pill);
      canvas.drawRRect(
        rounded,
        border..color = selected ? colors.primary : colors.outlineVariant,
      );
      painter.paint(canvas, Offset(rect.left + 6, rect.top + 3));
    }
  }

  @override
  bool shouldRepaint(covariant _LabelPainter old) =>
      old.transform != transform ||
      old.visible != visible ||
      old.selectedId != selectedId ||
      !setEquals(old.relatedIds, relatedIds) ||
      old.names != names ||
      old.fit != fit ||
      old.origin != origin ||
      old.colors != colors;
}

// ---------------------------------------------------------------------------
// Page
// ---------------------------------------------------------------------------

class BodyAtlasPage extends StatefulWidget {
  const BodyAtlasPage({
    super.key,
    this.bundle,
    this.initialLayers = const {BodyLayer.organs, BodyLayer.endocrine},
  });
  final AssetBundle? bundle;
  final Set<BodyLayer> initialLayers;
  @override
  State<BodyAtlasPage> createState() => _BodyAtlasPageState();
}

class _Entry {
  const _Entry({required this.id, this.organ, this.vessel});
  final String id;
  final OrganStructure? organ;
  final VascularRecord? vessel;
  String get scope => vessel == null ? 'organs' : 'vascular';
  String name(bool ru) => organ != null
      ? (ru ? organ!.nameRu : organ!.nameEn)
      : (ru ? vessel!.nameRu : vessel!.nameEn);
  bool get onScene => bodyStructureById.containsKey(id);
  bool matches(String query) =>
      '${organ?.nameRu ?? vessel?.nameRu} ${organ?.nameEn ?? vessel?.nameEn} ${organ?.nameLa ?? ''}'
          .toLowerCase()
          .contains(query);
}

class _BodyAtlasData {
  _BodyAtlasData(this.organs, this.vessels)
    : entries = List.unmodifiable([
        for (final organ in organs.organs) _Entry(id: organ.id, organ: organ),
        for (final vessel in vessels?.records ?? const <VascularRecord>[])
          _Entry(id: vessel.id, vessel: vessel),
      ]);
  final OrganAtlas organs;
  final VascularAtlas? vessels;
  final List<_Entry> entries;
  late final Map<String, _Entry> byId = {for (final e in entries) e.id: e};
}

class _BodyAtlasPageState extends State<BodyAtlasPage> {
  late Future<_BodyAtlasData> _future = _load();
  final _camera = TransformationController();
  final _sceneKey = GlobalKey<BodySceneState>();
  final _search = TextEditingController();
  final _searchFocus = FocusNode();
  // Replaced, never mutated: the scene compares old and new layer sets.
  late Set<BodyLayer> _layers = Set.unmodifiable(widget.initialLayers);
  String? _selectedId;
  bool _searching = false;

  Future<_BodyAtlasData> _load() async {
    final organs = loadOrganAtlas(widget.bundle);
    VascularAtlas? vessels;
    try {
      vessels = await loadVascularAtlas(widget.bundle);
    } catch (_) {
      // The vessel layer is optional; the organ atlas still opens.
    }
    return _BodyAtlasData(await organs, vessels);
  }

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _camera.dispose();
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  bool get _ru => Localizations.localeOf(context).languageCode == 'ru';
  String _t(String en, String ru) => _ru ? ru : en;

  String _layerName(BodyLayer layer) => switch (layer) {
    BodyLayer.skeleton => _t('Skeleton', 'Скелет'),
    BodyLayer.organs => _t('Organs', 'Органы'),
    BodyLayer.endocrine => _t('Endocrine', 'Эндокринная'),
    BodyLayer.vascular => _t('Vessels', 'Сосуды'),
  };

  void _select(String? id, {bool focus = false}) {
    setState(() {
      _selectedId = id;
      _searching = false;
      _search.clear();
    });
    final structure = id == null ? null : bodyStructureById[id];
    if (structure == null) return;
    if (!structure.visibleIn(_layers)) {
      setState(
        () => _layers = Set.unmodifiable({..._layers, structure.layers.first}),
      );
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final scene = _sceneKey.currentState;
      if (scene == null || !mounted) return;
      focus ? scene.focusOn(id!) : scene.ensureVisible(id!);
    });
  }

  Set<String> _related(_BodyAtlasData data, String? id) {
    final entry = id == null ? null : data.byId[id];
    if (entry == null) return const {};
    final out = <String>{};
    for (final s in bodyStructures) {
      if (s.id == id) continue;
      final other = data.byId[s.id];
      if (other == null) continue;
      if (entry.organ case final organ?) {
        if (other.organ case final o?) {
          if (o.systemIds.any(organ.systemIds.contains)) out.add(s.id);
        } else if (organ.systemIds.contains('cardiovascular')) {
          out.add(s.id);
        }
      } else if (entry.vessel case final vessel?) {
        if (other.vessel case final v?) {
          if (v.circuits.any(vessel.circuits.contains)) out.add(s.id);
        } else if (s.id == 'heart') {
          out.add(s.id);
        }
      }
    }
    return out;
  }

  List<BodyStructure> _ordered() =>
      bodyStructures.where((s) => s.visibleIn(_layers)).toList()..sort((a, b) {
        final dy = a.anchor.dy.compareTo(b.anchor.dy);
        return dy != 0 ? dy : a.anchor.dx.compareTo(b.anchor.dx);
      });

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.escape) {
      if (_selectedId == null && !_searching) return KeyEventResult.ignored;
      _select(null);
      return KeyEventResult.handled;
    }
    final forward = key == LogicalKeyboardKey.arrowRight;
    if ((!forward && key != LogicalKeyboardKey.arrowLeft) ||
        _searchFocus.hasFocus) {
      return KeyEventResult.ignored;
    }
    final ordered = _ordered();
    if (ordered.isEmpty) return KeyEventResult.ignored;
    final index = ordered.indexWhere((s) => s.id == _selectedId);
    final next = forward
        ? (index + 1) % ordered.length
        : (index <= 0 ? ordered.length - 1 : index - 1);
    _select(ordered[next].id);
    return KeyEventResult.handled;
  }

  void _openCatalogue(String which) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => switch (which) {
        'vascular' => VascularAtlasPage(bundle: widget.bundle),
        'bones' => OrganAtlasPage(
          bundle: widget.bundle,
          initialScope: OrganAtlasScope.bones,
        ),
        _ => OrganAtlasPage(
          bundle: widget.bundle,
          initialScope: OrganAtlasScope.organs,
        ),
      },
    ),
  );

  void _practice(_Entry entry, _BodyAtlasData data) => Navigator.of(context)
      .push(
        MaterialPageRoute<void>(
          builder: (_) => FactPracticePage(
            scope: entry.scope,
            bundle: widget.bundle,
            facts: entry.vessel == null || data.vessels == null
                ? null
                : vascularStudyFacts(
                    data.vessels!.records,
                    data.vessels!.sources,
                  ),
            entityIds: {entry.id},
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => FutureBuilder<_BodyAtlasData>(
    future: _future,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return _shell(
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _t(
                    'The atlas could not load.',
                    'Атлас не удалось загрузить.',
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _future = _load()),
                  child: Text(_t('Retry', 'Повторить')),
                ),
              ],
            ),
          ),
        );
      }
      final data = snapshot.data;
      if (data == null) {
        return _shell(const Center(child: CircularProgressIndicator()));
      }
      return _page(data);
    },
  );

  Widget _shell(Widget child) => Scaffold(
    appBar: AppBar(title: Text(_t('Body atlas', 'Атлас тела'))),
    body: SafeArea(child: child),
  );

  Widget _page(_BodyAtlasData data) {
    final hasVessels = data.vessels != null;
    final names = {
      for (final s in bodyStructures)
        if (data.byId[s.id] case final entry?) s.id: entry.name(_ru),
    };
    final related = _related(data, _selectedId);
    final selected = _selectedId == null ? null : data.byId[_selectedId!];
    return Scaffold(
      appBar: AppBar(
        title: Text(_t('Body atlas', 'Атлас тела')),
        actions: [
          IconButton(
            key: const Key('body-search-action'),
            tooltip: _t('Find a structure', 'Найти структуру'),
            icon: Icon(_searching ? Icons.search_off : Icons.search),
            onPressed: () => setState(() {
              _searching = !_searching;
              if (!_searching) _search.clear();
            }),
          ),
          FactPracticeAction(scope: 'organs', bundle: widget.bundle),
          PopupMenuButton<String>(
            key: const Key('body-catalogue'),
            tooltip: _t('Catalogues', 'Каталоги'),
            icon: const Icon(Icons.menu_book_outlined),
            onSelected: _openCatalogue,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'organs',
                child: Text(_t('Organ catalogue', 'Каталог органов')),
              ),
              PopupMenuItem(
                value: 'bones',
                child: Text(_t('Bone catalogue', 'Каталог костей')),
              ),
              if (hasVessels)
                PopupMenuItem(
                  value: 'vascular',
                  child: Text(_t('Vessel catalogue', 'Каталог сосудов')),
                ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Focus(
          autofocus: true,
          onKeyEvent: _onKey,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= bodyAtlasWideBreakpoint;
              return wide
                  ? _wideLayout(data, names, related, selected, hasVessels)
                  : _phoneLayout(data, names, related, selected, hasVessels);
            },
          ),
        ),
      ),
    );
  }

  Widget _phoneLayout(
    _BodyAtlasData data,
    Map<String, String> names,
    Set<String> related,
    _Entry? selected,
    bool hasVessels,
  ) => Column(
    children: [
      if (_searching)
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: _searchField(autofocus: true),
        ),
      _layerChips(hasVessels),
      Expanded(
        // The scene stays mounted under the search results, so the camera
        // and layers survive a search.
        child: Stack(
          children: [
            Positioned.fill(
              child: _sceneArea(
                names,
                related,
                visibleFraction: selected == null ? 1 : .58,
              ),
            ),
            if (_searching)
              Positioned.fill(
                child: Material(
                  color: Theme.of(context).colorScheme.surface,
                  child: _results(data),
                ),
              )
            else if (selected != null)
              DraggableScrollableSheet(
                key: const Key('body-sheet'),
                initialChildSize: .42,
                minChildSize: .16,
                maxChildSize: .92,
                snap: true,
                builder: (context, scroll) => Material(
                  elevation: 8,
                  color: Theme.of(context).colorScheme.surface,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: ListView(
                    controller: scroll,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.outlineVariant,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      _panel(selected, data),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    ],
  );

  Widget _wideLayout(
    _BodyAtlasData data,
    Map<String, String> names,
    Set<String> related,
    _Entry? selected,
    bool hasVessels,
  ) => Row(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Expanded(
        child: Column(
          children: [
            _layerChips(hasVessels),
            Expanded(child: _sceneArea(names, related)),
          ],
        ),
      ),
      const VerticalDivider(width: 1),
      SizedBox(
        width: 360,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: _searchField(autofocus: false),
            ),
            Expanded(
              child: _search.text.trim().isNotEmpty
                  ? _results(data)
                  : selected == null
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        _t(
                          'Tap a structure on the scene, or search by name. Use ← and → to step through the visible structures.',
                          'Нажмите на структуру на схеме или найдите её по названию. Клавиши ← и → переключают видимые структуры.',
                        ),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: _panel(selected, data),
                    ),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _layerChips(bool hasVessels) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    child: Row(
      children: [
        for (final layer in BodyLayer.values)
          if (layer != BodyLayer.vascular || hasVessels)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: FilterChip(
                key: Key('body-layer-${layer.name}'),
                label: Text(_layerName(layer)),
                selected: _layers.contains(layer),
                showCheckmark: false,
                avatar: Icon(switch (layer) {
                  BodyLayer.skeleton => Icons.accessibility,
                  BodyLayer.organs => Icons.favorite_outline,
                  BodyLayer.endocrine => Icons.water_drop_outlined,
                  BodyLayer.vascular => Icons.route_outlined,
                }, size: 18),
                onSelected: (on) => setState(() {
                  _layers = Set.unmodifiable(
                    on ? {..._layers, layer} : _layers.where((l) => l != layer),
                  );
                }),
              ),
            ),
      ],
    ),
  );

  Widget _sceneArea(
    Map<String, String> names,
    Set<String> related, {
    double visibleFraction = 1,
  }) => Stack(
    children: [
      Positioned.fill(
        child: BodyScene(
          key: _sceneKey,
          controller: _camera,
          layers: _layers,
          selectedId: _selectedId,
          relatedIds: related,
          names: names,
          onSelect: (id) => _select(id),
          visibleFraction: visibleFraction,
          semanticsLabel: _t(
            'Body diagram, front view. Tap a structure to open its card.',
            'Схема тела спереди. Нажмите на структуру, чтобы открыть карточку.',
          ),
        ),
      ),
      Positioned(
        right: 8,
        top: 8,
        child: Column(
          children: [
            IconButton.filledTonal(
              key: const Key('body-zoom-in'),
              tooltip: _t('Zoom in', 'Увеличить'),
              constraints: const BoxConstraints.tightFor(width: 48, height: 48),
              onPressed: () => _sceneKey.currentState?.zoomBy(1.5),
              icon: const Icon(Icons.add),
            ),
            const SizedBox(height: 4),
            IconButton.filledTonal(
              key: const Key('body-zoom-out'),
              tooltip: _t('Zoom out', 'Уменьшить'),
              constraints: const BoxConstraints.tightFor(width: 48, height: 48),
              onPressed: () => _sceneKey.currentState?.zoomBy(1 / 1.5),
              icon: const Icon(Icons.remove),
            ),
            const SizedBox(height: 4),
            IconButton.filledTonal(
              key: const Key('body-fit'),
              tooltip: _t('Whole body', 'Всё тело'),
              constraints: const BoxConstraints.tightFor(width: 48, height: 48),
              onPressed: () => _sceneKey.currentState?.fit(),
              icon: const Icon(Icons.fit_screen_outlined),
            ),
          ],
        ),
      ),
      if (_selectedId == null)
        Positioned(
          left: 12,
          right: 68,
          bottom: 12,
          child: IgnorePointer(
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface
                      .withValues(alpha: .9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: Text(
                    _t(
                      'Tap a structure · double-tap to zoom',
                      'Нажмите на структуру · двойной тап — зум',
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
            ),
          ),
        ),
    ],
  );

  Widget _searchField({required bool autofocus}) => TextField(
    key: const Key('body-search'),
    controller: _search,
    focusNode: _searchFocus,
    autofocus: autofocus,
    textInputAction: TextInputAction.search,
    decoration: InputDecoration(
      isDense: true,
      prefixIcon: const Icon(Icons.search),
      hintText: _t('Find an organ or vessel', 'Найти орган или сосуд'),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
      suffixIcon: _search.text.isEmpty
          ? null
          : IconButton(
              tooltip: _t('Clear', 'Очистить'),
              icon: const Icon(Icons.clear),
              onPressed: _search.clear,
            ),
    ),
  );

  Widget _results(_BodyAtlasData data) {
    final query = _search.text.trim().toLowerCase();
    final items =
        (query.isEmpty
                ? data.entries.where(
                    (e) => bodyStructureById[e.id]?.visibleIn(_layers) ?? false,
                  )
                : data.entries.where((e) => e.matches(query)))
            .toList()
          ..sort((a, b) {
            final scene = (a.onScene ? 0 : 1).compareTo(b.onScene ? 0 : 1);
            return scene != 0 ? scene : a.name(_ru).compareTo(b.name(_ru));
          });
    if (items.isEmpty) {
      return Center(child: Text(_t('Nothing found.', 'Ничего не найдено.')));
    }
    return ListView.builder(
      key: const Key('body-results'),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final entry = items[index];
        return ListTile(
          key: Key('body-result-${entry.id}'),
          leading: Icon(
            entry.onScene ? Icons.my_location : Icons.article_outlined,
          ),
          title: Text(entry.name(_ru)),
          subtitle: Text(_kindLabel(entry)),
          onTap: () => _select(entry.id, focus: entry.onScene),
        );
      },
    );
  }

  String _kindLabel(_Entry entry) {
    if (entry.vessel case final vessel?) {
      return [
        _t(
          vessel.vascularClass == 'artery' ? 'Artery' : 'Vein',
          vessel.vascularClass == 'artery' ? 'Артерия' : 'Вена',
        ),
        for (final circuit in vessel.circuits)
          switch (circuit) {
            'systemic' => _t('systemic circuit', 'большой круг'),
            'pulmonary' => _t('pulmonary circuit', 'малый круг'),
            _ => _t('portal system', 'воротная система'),
          },
      ].join(' · ');
    }
    final organ = entry.organ!;
    return [
      organFilterLabel(context, organ.kind),
      for (final system in organ.systemIds) organFilterLabel(context, system),
    ].join(' · ');
  }

  Widget _panel(_Entry entry, _BodyAtlasData data) => _StructurePanel(
    key: const Key('body-panel'),
    entry: entry,
    subtitle: _kindLabel(entry),
    russian: _ru,
    sourceTitle: (id) => entry.vessel == null
        ? data.organs.sources.where((s) => s.id == id).firstOrNull?.title
        : data.vessels?.sources[id]?.title,
    sourceUrl: (id) => entry.vessel == null
        ? data.organs.sources.where((s) => s.id == id).firstOrNull?.url
        : data.vessels?.sources[id]?.url,
    onClose: () => _select(null),
    onPractice: () => _practice(entry, data),
    onShow: entry.onScene ? () => _select(entry.id, focus: true) : null,
  );
}

class _StructurePanel extends StatelessWidget {
  const _StructurePanel({
    super.key,
    required this.entry,
    required this.subtitle,
    required this.russian,
    required this.sourceTitle,
    required this.sourceUrl,
    required this.onClose,
    required this.onPractice,
    required this.onShow,
  });
  final _Entry entry;
  final String subtitle;
  final bool russian;
  final String? Function(String id) sourceTitle, sourceUrl;
  final VoidCallback onClose, onPractice;
  final VoidCallback? onShow;

  String _t(String en, String ru) => russian ? ru : en;
  String _v(String en, String ru) => russian ? russianLearningText(ru) : en;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final organ = entry.organ, vessel = entry.vessel;
    final rows = <(String, String)>[
      if (organ != null) ...[
        (_t('Position', 'Положение'), _v(organ.positionEn, organ.positionRu)),
        (_t('Function', 'Функция'), _v(organ.functionEn, organ.functionRu)),
        if (organ.secretionsEn.isNotEmpty)
          (
            _t('Secretions', 'Секреции'),
            (russian ? organ.secretionsRu : organ.secretionsEn).join(', '),
          ),
        if (organ.boneCount case final count?)
          (_t('Bones in group', 'Костей в группе'), '$count'),
        if (_v(organ.noteEn, organ.noteRu).isNotEmpty)
          (_t('Note', 'Примечание'), _v(organ.noteEn, organ.noteRu)),
      ],
      if (vessel != null) ...[
        (_t('Position', 'Расположение'), vessel.positionRu),
        (_t('Role', 'Роль'), vessel.functionRu),
      ],
    ];
    final facts = [
      if (organ != null)
        for (final fact in organ.facts) _v(fact.textEn, fact.textRu),
      if (vessel != null) vessel.factRu,
    ];
    final sourceIds = organ?.sourceIds ?? vessel!.sourceIds;
    final secondary = [
      if (organ != null) russian ? organ.nameEn : organ.nameRu,
      ?organ?.nameLa,
      if (vessel != null) russian ? vessel.nameEn : vessel.nameRu,
    ].join(' · ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                entry.name(russian),
                key: const Key('body-panel-title'),
                style: theme.textTheme.titleLarge,
              ),
            ),
            IconButton(
              key: const Key('body-panel-close'),
              tooltip: _t('Close', 'Закрыть'),
              onPressed: onClose,
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        if (secondary.isNotEmpty)
          Text(
            secondary,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        Text(subtitle, style: theme.textTheme.bodySmall),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.tonalIcon(
              key: const Key('body-practice'),
              onPressed: onPractice,
              icon: const Icon(Icons.school_outlined),
              label: Text(_t('Practise', 'Тренировать')),
            ),
            OutlinedButton.icon(
              key: const Key('body-show-on-scene'),
              onPressed: onShow,
              icon: const Icon(Icons.my_location),
              label: Text(_t('Show on scene', 'Показать на сцене')),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AtlasMedia(
          scope: entry.scope,
          entityId: entry.id,
          hideWhenMissing: true,
        ),
        for (final (label, value) in rows)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        for (final fact in facts)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('• $fact'),
          ),
        for (final id in sourceIds)
          if (sourceUrl(id) case final url?)
            TextButton.icon(
              onPressed: () => launchUrl(
                Uri.parse(url),
                mode: LaunchMode.externalApplication,
              ),
              icon: const Icon(Icons.open_in_new, size: 18),
              label: Text(
                '${_t('Source', 'Источник')}: ${learningSourceTitle(sourceTitle(id) ?? url, russian: russian)}',
              ),
            ),
      ],
    );
  }
}
