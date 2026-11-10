import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart'
    show PointerDeviceKind, PointerHoverEvent, kDoubleTapTimeout;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show KeyUpEvent, LogicalKeyboardKey;

import 'map_interaction.dart';
import 'waterways_models.dart';

String _t(BuildContext context, String en, String ru) =>
    Localizations.localeOf(context).languageCode == 'ru' ? ru : en;

class QuizipediaPoint {
  const QuizipediaPoint(this.x, this.y);
  final double x;
  final double y;
  @override
  bool operator ==(Object other) =>
      other is QuizipediaPoint && x == other.x && y == other.y;
  @override
  int get hashCode => Object.hash(x, y);
}

/// For callers holding viewport coordinates. Child-local InteractiveViewer
/// callbacks are already in scene coordinates and must not call this again.
QuizipediaPoint scenePoint(
  QuizipediaPoint point, {
  required double scale,
  required QuizipediaPoint translation,
}) => QuizipediaPoint(
  (point.x - translation.x) / scale,
  (point.y - translation.y) / scale,
);

class QuizipediaFeature {
  const QuizipediaFeature({
    required this.id,
    required this.nameRu,
    required this.nameEn,
    required this.polygons,
    this.flag,
  });
  final String id;
  final String nameRu;
  final String nameEn;
  final List<List<List<QuizipediaPoint>>> polygons;
  final String? flag;

  bool contains(QuizipediaPoint point) => polygons.any(
    (polygon) =>
        polygon.isNotEmpty &&
        _inRing(point, polygon.first) &&
        !polygon.skip(1).any((hole) => _inRing(point, hole)),
  );
}

bool _inRing(QuizipediaPoint point, List<QuizipediaPoint> ring) {
  var inside = false;
  for (var i = 0, j = ring.length - 1; i < ring.length; j = i++) {
    final a = ring[i], b = ring[j];
    if ((a.y > point.y) != (b.y > point.y) &&
        point.x < (b.x - a.x) * (point.y - a.y) / (b.y - a.y) + a.x) {
      inside = !inside;
    }
  }
  return inside;
}

/// A map has its own gesture area and controls; the page does not intercept pan.
class QuizipediaWorldMap extends StatefulWidget {
  const QuizipediaWorldMap({
    super.key,
    required this.features,
    required this.controller,
    required this.onSelect,
    this.selected,
    this.highlighted,
    this.correct,
    this.numbers = const [],
    this.showLabels = true,
    this.selectionEnabled = true,
    this.focusTarget,
    this.focusRequest = 0,
    this.labelPriorityIds = const {},
    this.neighborIds = const {},
    this.overlayLabels = const {},
    this.capitalPoints = const {},
    this.capitalLabels = const {},
    this.flagPoints = const {},
    this.pointCountryNames = const {},
    this.showFlags = false,
    this.alwaysShowCountryNames = false,
    this.showSelectionLabel = true,
    this.waters = const [],
    this.selectedWater,
    this.showWaterLabels = true,
    this.onWaterSelect,
  });
  final List<QuizipediaFeature> features;
  final TransformationController controller;
  final ValueChanged<String?> onSelect;
  final String? selected, highlighted, correct;
  final List<String> numbers;
  final bool showLabels, selectionEnabled;

  /// A search result can request camera focus without revealing a quiz answer.
  final String? focusTarget;
  final int focusRequest;
  final Set<String> labelPriorityIds;

  /// Land neighbours of the selected country get a separate outline.
  final Set<String> neighborIds;
  final Map<String, String> overlayLabels;

  /// Normalised world coordinates for capital dots (west→east, north→south).
  /// Labels remain owned by the caller so they use verified local fact text.
  final Map<String, Offset> capitalPoints;
  final Map<String, String> capitalLabels;

  /// Optional coordinates and names for microstates/islands without polygons.
  final Map<String, Offset> flagPoints;
  final Map<String, ({String en, String ru})> pointCountryNames;
  final bool showFlags, showSelectionLabel, alwaysShowCountryNames;
  final List<WaterShape> waters;
  final String? selectedWater;
  final bool showWaterLabels;
  final ValueChanged<String>? onWaterSelect;

  @override
  State<QuizipediaWorldMap> createState() => _QuizipediaWorldMapState();
}

class _QuizipediaWorldMapState extends State<QuizipediaWorldMap>
    with SingleTickerProviderStateMixin {
  // A full-screen route keeps the compact map mounted below it.  The two map
  // states deliberately share one controller, so retain the active viewport
  // with the controller rather than with either state.
  static final Expando<Size> _cameraViewports = Expando<Size>(
    'quizipedia map viewport',
  );
  late final AnimationController _camera = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
  );
  Animation<Matrix4>? _cameraFrames;
  // A tap selects at once; a second tap inside the double-tap window zooms.
  // The built-in double-tap recognizer would hold every single tap for 300 ms.
  Timer? _doubleTapTimer;
  Offset? _lastTapAt;
  bool _cameraActive = false;
  int _viewportRevision = 0;

  bool get _ownsCamera =>
      _cameraActive && (ModalRoute.of(context)?.isCurrent ?? true);

  @override
  void initState() {
    super.initState();
    _camera.addListener(() {
      if (_ownsCamera && _cameraFrames != null) {
        widget.controller.value = _cameraFrames!.value;
      }
    });
    if (widget.focusTarget != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focus(widget.focusTarget);
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final active = TickerMode.valuesOf(context).enabled;
    if (active == _cameraActive) return;
    _cameraActive = active;
    if (!active) {
      _camera.stop();
    } else {
      _syncCameraViewport();
    }
  }

  @override
  void didUpdateWidget(covariant QuizipediaWorldMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusTarget != null &&
        (widget.focusTarget != oldWidget.focusTarget ||
            widget.focusRequest != oldWidget.focusRequest)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focus(widget.focusTarget);
      });
    }
  }

  @override
  void dispose() {
    _doubleTapTimer?.cancel();
    _hover.dispose();
    _focusNode.dispose();
    _camera.dispose();
    super.dispose();
  }

  /// Keep the viewport over the map so no camera move shows blank space
  /// beyond its edges; gestures get the same limit from `boundaryMargin`.
  Matrix4 _clampToView(Matrix4 target) {
    final scale = target.getMaxScaleOnAxis();
    final t = target.getTranslation();
    return target..setTranslationRaw(
      t.x.clamp(_view.width * (1 - scale), 0.0),
      t.y.clamp(_view.height * (1 - scale), 0.0),
      t.z,
    );
  }

  void _moveCamera(Matrix4 target) {
    if (!_ownsCamera) return;
    _camera.stop();
    target = _clampToView(target);
    if (MediaQuery.disableAnimationsOf(context)) {
      widget.controller.value = target;
      return;
    }
    _cameraFrames = Matrix4Tween(
      begin: widget.controller.value.clone(),
      end: target,
    ).animate(CurvedAnimation(parent: _camera, curve: Curves.easeOutCubic));
    _camera.forward(from: 0);
  }

  Size _view = Size.zero;

  // Geometry summaries per feature. The label pass ran these over all 10k
  // vertices on every pan frame; they only change with the feature list.
  List<QuizipediaFeature>? _metricsSource;
  final _metrics = <String, _FeatureMetrics>{};
  Map<String, _FeatureMetrics> get _featureMetrics {
    if (!identical(_metricsSource, widget.features)) {
      _metricsSource = widget.features;
      _metrics
        ..clear()
        ..addEntries(
          widget.features.map(
            (feature) => MapEntry(feature.id, _FeatureMetrics.of(feature)),
          ),
        );
    }
    return _metrics;
  }

  Size get _scene => Size(
    math.min(_view.width, _view.height * 2),
    math.min(_view.width, _view.height * 2) / 2,
  );
  QuizipediaFeature? get _selected => widget.features
      .where((feature) => feature.id == widget.selected)
      .firstOrNull;

  static Size _sceneFor(Size view) {
    final width = math.min(view.width, view.height * 2);
    return Size(width, width / 2);
  }

  /// Reframe a manual transform around the same normalised world point when
  /// the route changes the viewport's size or centred map origin.
  Matrix4 _reframeCamera(Size previous, Size next) {
    final previousScene = _sceneFor(previous);
    final nextScene = _sceneFor(next);
    final oldCenter = Offset(previous.width / 2, previous.height / 2);
    final oldFocal = widget.controller.toScene(oldCenter);
    final world = Offset(
      (oldFocal.dx - (previous.width - previousScene.width) / 2) /
          previousScene.width,
      (oldFocal.dy - (previous.height - previousScene.height) / 2) /
          previousScene.height,
    );
    final nextFocal = Offset(
      (next.width - nextScene.width) / 2 + world.dx * nextScene.width,
      (next.height - nextScene.height) / 2 + world.dy * nextScene.height,
    );
    final scale = widget.controller.value.getMaxScaleOnAxis();
    return Matrix4.identity()
      ..translateByDouble(
        next.width / 2 - nextFocal.dx * scale,
        next.height / 2 - nextFocal.dy * scale,
        0,
        1,
      )
      ..scaleByDouble(scale, scale, scale, 1);
  }

  void _syncCameraViewport() {
    final revision = ++_viewportRevision;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          !_ownsCamera ||
          _view.isEmpty ||
          revision != _viewportRevision) {
        return;
      }
      final previous = _cameraViewports[widget.controller];
      if (previous != null && previous != _view && !previous.isEmpty) {
        _camera.stop();
        widget.controller.value = _reframeCamera(previous, _view);
      }
      _cameraViewports[widget.controller] = _view;
    });
  }

  void _zoom(double factor, [Offset? focalPoint]) {
    final scale = widget.controller.value.getMaxScaleOnAxis();
    final next = (scale * factor).clamp(1.0, 16.0).toDouble();
    if (next == 1) {
      _moveCamera(Matrix4.identity());
      return;
    }
    final center = focalPoint ?? Offset(_view.width / 2, _view.height / 2);
    final scene = widget.controller.toScene(center);
    _moveCamera(
      Matrix4.identity()
        ..translateByDouble(
          center.dx - scene.dx * next,
          center.dy - scene.dy * next,
          0,
          1,
        )
        ..scaleByDouble(next, next, next, 1),
    );
  }

  void _focus([String? id]) {
    if (_view.isEmpty) return;
    final targetId = id ?? widget.selected;
    final feature = id == null
        ? _selected
        : widget.features.where((f) => f.id == id).firstOrNull;
    if (feature == null) {
      final point = targetId == null
          ? null
          : (widget.flagPoints[targetId] ?? widget.capitalPoints[targetId]);
      if (point != null) {
        _focusBounds(Rect.fromCenter(center: point, width: .025, height: .025));
      }
      return;
    }
    // Use the largest part, avoiding distant islands stretching the camera.
    Rect? bounds;
    for (final polygon in feature.polygons) {
      final ring = polygon.first;
      final xs = ring.map((p) => p.x), ys = ring.map((p) => p.y);
      final rect = Rect.fromLTRB(
        xs.reduce(math.min),
        ys.reduce(math.min),
        xs.reduce(math.max),
        ys.reduce(math.max),
      );
      if (bounds == null ||
          rect.width * rect.height > bounds.width * bounds.height) {
        bounds = rect;
      }
    }
    _focusBounds(bounds!);
  }

  QuizipediaFeature? _featureAt(QuizipediaPoint point, Size scene) =>
      widget.features.reversed.where((f) => f.contains(point)).firstOrNull ??
      _nearestSmallFeature(point, scene);

  /// Pointer hover state for the desktop tooltip. A notifier keeps mouse
  /// moves from rebuilding the map; only the caption listens.
  final _hover = ValueNotifier<(QuizipediaFeature, Offset)?>(null);
  final _focusNode = FocusNode(debugLabel: 'world map');

  void _onHover(PointerHoverEvent event, Size scene) {
    if (event.kind != PointerDeviceKind.mouse) return;
    final local = event.localPosition;
    final feature = _featureAt(
      QuizipediaPoint(local.dx / scene.width, local.dy / scene.height),
      scene,
    );
    if (feature == null) {
      if (_hover.value != null) _hover.value = null;
      return;
    }
    final origin = Offset(
      (_view.width - scene.width) / 2,
      (_view.height - scene.height) / 2,
    );
    _hover.value = (
      feature,
      MatrixUtils.transformPoint(widget.controller.value, local + origin),
    );
  }

  /// Arrow keys pan, +/- zoom, Home shows the whole world.
  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    const step = 80.0;
    final key = event.logicalKey;
    Offset? pan;
    if (key == LogicalKeyboardKey.arrowLeft) pan = const Offset(step, 0);
    if (key == LogicalKeyboardKey.arrowRight) pan = const Offset(-step, 0);
    if (key == LogicalKeyboardKey.arrowUp) pan = const Offset(0, step);
    if (key == LogicalKeyboardKey.arrowDown) pan = const Offset(0, -step);
    if (pan != null) {
      _moveCamera(
        Matrix4.translationValues(
          pan.dx,
          pan.dy,
          0,
        ).multiplied(widget.controller.value),
      );
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.equal ||
        key == LogicalKeyboardKey.add ||
        key == LogicalKeyboardKey.numpadAdd) {
      _zoom(1.5);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.minus ||
        key == LogicalKeyboardKey.numpadSubtract) {
      _zoom(1 / 1.5);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.home || key == LogicalKeyboardKey.digit0) {
      _moveCamera(Matrix4.identity());
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  /// Islands and city states are a few pixels wide on the world map; when
  /// nothing was hit, accept a tap within 12 px of such a small feature.
  QuizipediaFeature? _nearestSmallFeature(QuizipediaPoint point, Size scene) {
    final scale = widget.controller.value.getMaxScaleOnAxis();
    final tx = 12 / (scene.width * scale), ty = 12 / (scene.height * scale);
    QuizipediaFeature? best;
    var bestDistance = double.infinity;
    for (final feature in widget.features) {
      final rect = _featureRect(feature);
      if (rect.width > 2 * tx || rect.height > 2 * ty) continue;
      final dx = (point.x - rect.center.dx).abs() - rect.width / 2;
      final dy = (point.y - rect.center.dy).abs() - rect.height / 2;
      if (dx > tx || dy > ty) continue;
      final distance = math.max(dx / tx, dy / ty);
      if (distance < bestDistance) {
        bestDistance = distance;
        best = feature;
      }
    }
    return best;
  }

  static Rect _featureRect(QuizipediaFeature feature) {
    var left = 1.0, top = 1.0, right = 0.0, bottom = 0.0;
    for (final polygon in feature.polygons) {
      if (polygon.isEmpty) continue;
      for (final p in polygon.first) {
        if (p.x < left) left = p.x;
        if (p.x > right) right = p.x;
        if (p.y < top) top = p.y;
        if (p.y > bottom) bottom = p.y;
      }
    }
    return Rect.fromLTRB(left, top, right, bottom);
  }

  void _focusBounds(Rect bounds) {
    final worldWidth = _scene.width;
    final worldHeight = _scene.height;
    final scale = math
        .min(
          _view.width * .7 / math.max(1, bounds.width * worldWidth),
          _view.height * .7 / math.max(1, bounds.height * worldHeight),
        )
        .clamp(1.0, 16.0)
        .toDouble();
    final center = Offset(
      bounds.center.dx * worldWidth + (_view.width - worldWidth) / 2,
      bounds.center.dy * worldHeight + (_view.height - worldHeight) / 2,
    );
    _moveCamera(
      Matrix4.identity()
        ..translateByDouble(
          _view.width / 2 - center.dx * scale,
          _view.height / 2 - center.dy * scale,
          0,
          1,
        )
        ..scaleByDouble(scale, scale, scale, 1),
    );
  }

  void _focusWater() {
    final water = widget.waters
        .where((f) => f.id == widget.selectedWater)
        .firstOrNull;
    if (water == null || _view.isEmpty) return;
    final parts = [...water.polygons.map((p) => p.first), ...water.lines];
    // Focus the part containing its real label anchor; do not span the date line.
    final anchor = Offset(water.anchor.x, water.anchor.y);
    final bounds = parts
        .map(
          (points) => Rect.fromLTRB(
            points.map((p) => p.x).reduce(math.min),
            points.map((p) => p.y).reduce(math.min),
            points.map((p) => p.x).reduce(math.max),
            points.map((p) => p.y).reduce(math.max),
          ),
        )
        .toList();
    final matching = bounds.where((b) => b.contains(anchor)).toList()
      ..sort((a, b) => (a.width * a.height).compareTo(b.width * b.height));
    var target = matching.isEmpty ? bounds.first : matching.first;
    // Polar oceans cover all longitudes. Inspect a region around the water anchor.
    if (target.width > .6) {
      target = Rect.fromCenter(
        center: anchor,
        width: .4,
        height: math.min(.25, target.height),
      );
    }
    _focusBounds(target);
  }

  Widget _factLabels(Size scene) => IgnorePointer(
    child: ValueListenableBuilder<Matrix4>(
      valueListenable: widget.controller,
      builder: (context, transform, _) {
        final occupied = <Rect>[];
        final capitalMarkers = <Rect>[];
        final labels = <Widget>[];
        final countryNames = <Widget>[];
        Rect? selectedFlagRect;
        final scale = transform.getMaxScaleOnAxis();
        final capitalIds =
            widget.capitalPoints.keys
                .where(widget.capitalLabels.containsKey)
                .toList()
              ..sort(
                (a, b) => (a == widget.selected ? 1 : 0).compareTo(
                  b == widget.selected ? 1 : 0,
                ),
              );
        for (final id in capitalIds.reversed) {
          final point = widget.capitalPoints[id]!;
          final at = MatrixUtils.transformPoint(
            transform,
            Offset(
              point.dx * scene.width + (_view.width - scene.width) / 2,
              point.dy * scene.height + (_view.height - scene.height) / 2,
            ),
          );
          final marker = Rect.fromCenter(center: at, width: 18, height: 18);
          final visible =
              id == widget.selected ||
              scale >= 2.25 ||
              !capitalMarkers.any(
                (other) => other.overlaps(marker.inflate(12)),
              );
          if (!visible) continue;
          capitalMarkers.add(marker);
          if ((id == widget.selected || scale >= 2.25) && !widget.showFlags) {
            final text = TextPainter(
              text: TextSpan(
                text: widget.capitalLabels[id],
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              textDirection: Directionality.of(context),
              maxLines: 1,
              ellipsis: '…',
            )..layout(maxWidth: 108);
            occupied.add(
              Rect.fromLTWH(
                at.dx + 5,
                at.dy - text.height - 5,
                text.width + 6,
                text.height + 4,
              ),
            );
            text.dispose();
          } else if (!widget.showFlags) {
            occupied.add(marker.inflate(3));
          }
        }
        final featureMetrics = _featureMetrics;
        int priority(QuizipediaFeature feature) => feature.id == widget.selected
            ? 2
            : widget.labelPriorityIds.contains(feature.id)
            ? 1
            : 0;
        final ordered = [...widget.features]
          ..sort((a, b) {
            final rank = priority(b).compareTo(priority(a));
            return rank != 0
                ? rank
                : featureMetrics[b.id]!.area.compareTo(
                    featureMetrics[a.id]!.area,
                  );
          });
        for (final feature in ordered) {
          final text = widget.overlayLabels[feature.id];
          if (text == null && !widget.alwaysShowCountryNames) continue;
          final metric = featureMetrics[feature.id]!;
          final center = metric.anchor;
          if (center == null) continue;
          final landBounds = metric.landBounds;
          final at = MatrixUtils.transformPoint(
            transform,
            Offset(
              center.dx * scene.width + (_view.width - scene.width) / 2,
              center.dy * scene.height + (_view.height - scene.height) / 2,
            ),
          );
          if (widget.alwaysShowCountryNames &&
              at.dx >= 0 &&
              at.dx <= _view.width &&
              at.dy >= 0 &&
              at.dy <= _view.height) {
            const nameWidth = 112.0;
            countryNames.add(
              Positioned(
                left: (at.dx - nameWidth / 2).clamp(
                  4.0,
                  _view.width - nameWidth - 4,
                ),
                top: (at.dy - 12).clamp(4.0, _view.height - 4),
                width: nameWidth,
                child: Semantics(
                  label: _t(
                    context,
                    'Country: ${feature.nameEn}',
                    'Страна: ${feature.nameRu}',
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface
                          .withValues(alpha: .88),
                    ),
                    child: Text(
                      Localizations.localeOf(context).languageCode == 'ru'
                          ? feature.nameRu
                          : feature.nameEn,
                      key: Key('map-country-name-${feature.id.toLowerCase()}'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }
          if (text == null || text.isEmpty) continue;
          final countryWidth = landBounds.width * scene.width * scale;
          final countryHeight = landBounds.height * scene.height * scale;
          final isSelected = feature.id == widget.selected;
          final hasFlag = widget.showFlags;
          if (!hasFlag &&
              !isSelected &&
              (countryWidth < 28 || countryHeight < 14)) {
            continue;
          }
          final textScale = MediaQuery.textScalerOf(context).scale(11) / 11;
          final labelStyle = DefaultTextStyle.of(context).style.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: widget.labelPriorityIds.contains(feature.id)
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface,
            backgroundColor: Theme.of(context).colorScheme.surface
                .withValues(alpha: .94),
          );
          final showFlagCaption = isSelected || scale >= 2.2;
          final flagW = showFlagCaption ? 34.0 : (scale >= 1.45 ? 22.0 : 18.0);
          final flagH = showFlagCaption ? 22.0 : (scale >= 1.45 ? 15.0 : 12.0);
          late final double labelWidth;
          late final double labelHeight;
          if (hasFlag) {
            labelWidth = showFlagCaption ? 64.0 : flagW + 2;
            labelHeight = showFlagCaption ? 38.0 : flagH + 2;
          } else {
            final metrics = TextPainter(
              text: TextSpan(text: text, style: labelStyle),
              textDirection: Directionality.of(context),
              textScaler: MediaQuery.textScalerOf(context),
              maxLines: 2,
              ellipsis: '…',
            )..layout(maxWidth: 160 * textScale);
            labelWidth = metrics.width + 8;
            labelHeight = metrics.height + 6;
            metrics.dispose();
          }
          final edgePad = hasFlag && !showFlagCaption ? 2.0 : 8.0;
          final collidePad = hasFlag && !showFlagCaption ? 1.0 : 3.0;
          // Anchor labels and flag markers on land. Their compact overlay may
          // extend over a coastline, but never repaints a country polygon.
          if (labelWidth > _view.width - 2 * edgePad ||
              labelHeight > _view.height - 2 * edgePad ||
              at.dx < 0 ||
              at.dx > _view.width ||
              at.dy < 0 ||
              at.dy > _view.height) {
            continue;
          }
          final rect = Rect.fromCenter(
            center: Offset(
              at.dx.clamp(
                labelWidth / 2 + edgePad,
                _view.width - labelWidth / 2 - edgePad,
              ),
              at.dy.clamp(
                labelHeight / 2 + edgePad,
                _view.height - labelHeight / 2 - edgePad,
              ),
            ),
            width: labelWidth,
            height: labelHeight,
          );
          if (rect.left < 0 ||
              rect.right > _view.width ||
              rect.top < edgePad ||
              rect.bottom > _view.height - edgePad ||
              occupied.any((r) => r.overlaps(rect.inflate(collidePad)))) {
            continue;
          }
          occupied.add(rect);
          if (hasFlag && isSelected) selectedFlagRect = rect;
          labels.add(
            Positioned.fromRect(
              rect: rect,
              child: Center(
                child: hasFlag
                    ? Semantics(
                        image: true,
                        label: _t(
                          context,
                          'Flag of ${feature.nameEn}',
                          'Флаг: ${feature.nameRu}',
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: .88),
                                borderRadius: BorderRadius.circular(2),
                                border: Border.all(
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.black26,
                                  width: isSelected ? 1.2 : .5,
                                ),
                              ),
                              child: SizedBox(
                                width: flagW,
                                height: flagH,
                                child: Image.asset(
                                  'assets/quizipedia/flag-${feature.id.toLowerCase()}.png',
                                  key: Key(
                                    'map-country-flag-${feature.id.toLowerCase()}',
                                  ),
                                  fit: BoxFit.contain,
                                  cacheWidth: 96,
                                  errorBuilder: (_, _, _) =>
                                      const Icon(Icons.flag_outlined, size: 12),
                                ),
                              ),
                            ),
                            if (showFlagCaption)
                              Text(
                                text,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: labelStyle.copyWith(fontSize: 9),
                              ),
                          ],
                        ),
                      )
                    : Text(
                        text,
                        key: Key('map-overlay-label-${feature.id}'),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: labelStyle,
                      ),
              ),
            ),
          );
          if (!hasFlag && labels.length == 40) break;
        }
        if (widget.showFlags && widget.flagPoints.isNotEmpty) {
          final pointIds =
              widget.flagPoints.keys
                  .where((id) => !featureMetrics.containsKey(id))
                  .toList()
                ..sort(
                  (a, b) => (b == widget.selected ? 1 : 0).compareTo(
                    a == widget.selected ? 1 : 0,
                  ),
                );
          for (final id in pointIds) {
            final center = widget.flagPoints[id]!;
            final at = MatrixUtils.transformPoint(
              transform,
              Offset(
                center.dx * scene.width + (_view.width - scene.width) / 2,
                center.dy * scene.height + (_view.height - scene.height) / 2,
              ),
            );
            final isSelected = id == widget.selected;
            final showFlagCaption = isSelected || scale >= 2.2;
            final flagW = showFlagCaption
                ? 34.0
                : (scale >= 1.45 ? 22.0 : 18.0);
            final flagH = showFlagCaption
                ? 22.0
                : (scale >= 1.45 ? 15.0 : 12.0);
            final labelWidth = showFlagCaption ? 64.0 : flagW + 2;
            final labelHeight = showFlagCaption ? 38.0 : flagH + 2;
            final edgePad = showFlagCaption ? 8.0 : 2.0;
            final collidePad = showFlagCaption ? 3.0 : 1.0;
            if (labelWidth > _view.width - 2 * edgePad ||
                labelHeight > _view.height - 2 * edgePad ||
                at.dx < 0 ||
                at.dx > _view.width ||
                at.dy < 0 ||
                at.dy > _view.height) {
              continue;
            }
            final rect = Rect.fromCenter(
              center: Offset(
                at.dx.clamp(
                  labelWidth / 2 + edgePad,
                  _view.width - labelWidth / 2 - edgePad,
                ),
                at.dy.clamp(
                  labelHeight / 2 + edgePad,
                  _view.height - labelHeight / 2 - edgePad,
                ),
              ),
              width: labelWidth,
              height: labelHeight,
            );
            if (rect.left < 0 ||
                rect.right > _view.width ||
                rect.top < edgePad ||
                rect.bottom > _view.height - edgePad ||
                occupied.any((r) => r.overlaps(rect.inflate(collidePad)))) {
              continue;
            }
            occupied.add(rect);
            if (isSelected) selectedFlagRect = rect;
            final names = widget.pointCountryNames[id];
            final nameEn = names?.en ?? widget.overlayLabels[id] ?? id;
            final nameRu = names?.ru ?? widget.overlayLabels[id] ?? id;
            final text =
                widget.overlayLabels[id] ??
                (Localizations.localeOf(context).languageCode == 'ru'
                    ? nameRu
                    : nameEn);
            final labelStyle = DefaultTextStyle.of(context).style.copyWith(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
              backgroundColor: Theme.of(context).colorScheme.surface
                  .withValues(alpha: .94),
            );
            labels.add(
              Positioned.fromRect(
                rect: rect,
                child: Center(
                  child: Semantics(
                    image: true,
                    label: _t(context, 'Flag of $nameEn', 'Флаг: $nameRu'),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .88),
                            borderRadius: BorderRadius.circular(2),
                            border: Border.all(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.black26,
                              width: isSelected ? 1.2 : .5,
                            ),
                          ),
                          child: SizedBox(
                            width: flagW,
                            height: flagH,
                            child: Image.asset(
                              'assets/quizipedia/flag-${id.toLowerCase()}.png',
                              key: Key('map-country-flag-${id.toLowerCase()}'),
                              fit: BoxFit.contain,
                              cacheWidth: 96,
                              errorBuilder: (_, _, _) =>
                                  const Icon(Icons.flag_outlined, size: 12),
                            ),
                          ),
                        ),
                        if (showFlagCaption)
                          Text(
                            text,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: labelStyle,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }
        }
        final selectedId = widget.selected;
        final selectedCapital = selectedId == null
            ? null
            : widget.capitalPoints[selectedId];
        final selectedCapitalLabel = selectedId == null
            ? null
            : widget.capitalLabels[selectedId];
        if (widget.showFlags &&
            selectedCapital != null &&
            selectedCapitalLabel != null) {
          final at = MatrixUtils.transformPoint(
            transform,
            Offset(
              selectedCapital.dx * scene.width +
                  (_view.width - scene.width) / 2,
              selectedCapital.dy * scene.height +
                  (_view.height - scene.height) / 2,
            ),
          );
          final textPainter = TextPainter(
            text: TextSpan(
              text: selectedCapitalLabel,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
            ),
            textDirection: Directionality.of(context),
            textScaler: MediaQuery.textScalerOf(context),
            maxLines: 1,
          )..layout(maxWidth: 108);
          final width = textPainter.width + 8;
          final height = textPainter.height + 4;
          textPainter.dispose();
          // Country flags use a geographic centroid, which can be far from a
          // capital in a large country. The capital caption must always use
          // the source capital coordinate as its anchor.
          final reference = Rect.fromCenter(center: at, width: 10, height: 10);
          final centeredLeft = (at.dx - width / 2)
              .clamp(4.0, _view.width - width - 4)
              .toDouble();
          final defaultTop = (at.dy - 11)
              .clamp(4.0, _view.height - height - 4)
              .toDouble();
          final aboveTop = reference.top - height - 4;
          final belowTop = reference.bottom + 4;
          final clearedAboveTop =
              (selectedFlagRect?.top ?? aboveTop) - height - 4;
          final clearedBelowTop = (selectedFlagRect?.bottom ?? belowTop) + 4;
          final candidates =
              <Rect>[
                Rect.fromLTWH(reference.right + 4, defaultTop, width, height),
                Rect.fromLTWH(
                  reference.left - width - 4,
                  defaultTop,
                  width,
                  height,
                ),
                Rect.fromLTWH(centeredLeft, aboveTop, width, height),
                Rect.fromLTWH(centeredLeft, belowTop, width, height),
                Rect.fromLTWH(centeredLeft, clearedAboveTop, width, height),
                Rect.fromLTWH(centeredLeft, clearedBelowTop, width, height),
              ].where(
                (rect) =>
                    rect.left >= 4 &&
                    rect.right <= _view.width - 4 &&
                    rect.top >= 4 &&
                    rect.bottom <= _view.height - 4,
              );
          final blockers = <Rect>[...occupied, ?selectedFlagRect];
          var caption = candidates.firstOrNull;
          for (final candidate in candidates) {
            if (!blockers.any(
              (other) => other.overlaps(candidate.inflate(3)),
            )) {
              caption = candidate;
              break;
            }
          }
          if (at.dx < 0 ||
              at.dx > _view.width ||
              at.dy < 0 ||
              at.dy > _view.height) {
            return Stack(children: [...labels, ...countryNames]);
          }
          labels.add(
            Positioned(
              left: at.dx - 5,
              top: at.dy - 5,
              child: const IgnorePointer(
                child: DecoratedBox(
                  key: Key('map-selected-capital-dot'),
                  decoration: BoxDecoration(
                    color: Color(0xfff6c762),
                    shape: BoxShape.circle,
                    border: Border.fromBorderSide(
                      BorderSide(color: Colors.white),
                    ),
                  ),
                  child: SizedBox(width: 10, height: 10),
                ),
              ),
            ),
          );
          labels.add(
            Positioned(
              left: caption?.left ?? reference.right + 4,
              top: caption?.top ?? defaultTop,
              width: width,
              child: Text(
                selectedCapitalLabel,
                key: const Key('map-selected-capital-label'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        }
        return Stack(children: [...labels, ...countryNames]);
      },
    ),
  );

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final view = Size(constraints.maxWidth, constraints.maxHeight);
      if (view != _view) {
        _view = view;
        if (_cameraActive) _syncCameraViewport();
      }
      final scene = _scene;
      final selected = _selected;
      final name = selected == null
          ? (widget.selectionEnabled
                ? _t(context, 'Tap a country', 'Нажмите на страну')
                : _t(context, 'Choose an answer below', 'Выберите ответ ниже'))
          : (Localizations.localeOf(context).languageCode == 'ru'
                ? selected.nameRu
                : selected.nameEn);
      // The map can be compact even on a tall phone page.  Its own bounds,
      // not the outer MediaQuery, decide whether a four-button vertical rail
      // would be clipped.
      final compactControls = constraints.maxHeight < 240;
      final canFocusSelected =
          selected != null ||
          (widget.selected != null &&
              (widget.flagPoints.containsKey(widget.selected) ||
                  widget.capitalPoints.containsKey(widget.selected)));
      Widget selectionLabel() => IgnorePointer(
        child: Semantics(
          liveRegion: true,
          child: Material(
            color: const Color(0xff173f57),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Text(
                name,
                key: const Key('map-selection-label'),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      );
      Widget zoomControls() => Material(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        child: Flex(
          direction: compactControls ? Axis.horizontal : Axis.vertical,
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: _t(context, 'Zoom in', 'Увеличить'),
              icon: const Icon(Icons.add),
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              onPressed: () => _zoom(1.5),
            ),
            IconButton(
              tooltip: _t(context, 'Zoom out', 'Уменьшить'),
              icon: const Icon(Icons.remove),
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              onPressed: () => _zoom(1 / 1.5),
            ),
            IconButton(
              tooltip: _t(context, 'Reset view', 'Весь мир'),
              icon: const Icon(Icons.public),
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              onPressed: () => _moveCamera(Matrix4.identity()),
            ),
            IconButton(
              tooltip: _t(
                context,
                widget.selectedWater == null
                    ? 'Show selected country'
                    : 'Show selected water body',
                widget.selectedWater == null
                    ? 'Показать выбранную страну'
                    : 'Показать выбранный водоём',
              ),
              icon: const Icon(Icons.center_focus_strong),
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              onPressed: widget.selectedWater != null
                  ? _focusWater
                  : !canFocusSelected
                  ? null
                  : () => _focus(),
            ),
          ],
        ),
      );
      return Focus(
        focusNode: _focusNode,
        onKeyEvent: _onKey,
        includeSemantics: false,
        child: MapInteraction(
          child: ColoredBox(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xff101f2d)
                : const Color(0xffd9edfc),
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRect(
                    child: InteractiveViewer(
                      key: const Key('quizipedia-viewport'),
                      transformationController: widget.controller,
                      constrained: false,
                      boundaryMargin: EdgeInsets.zero,
                      minScale: 1,
                      maxScale: 16,
                      trackpadScrollCausesScale: true,
                      onInteractionStart: (_) => _camera.stop(),
                      child: SizedBox(
                        width: _view.width,
                        height: _view.height,
                        child: Center(
                          child: Semantics(
                            label: _t(
                              context,
                              'Interactive world map',
                              'Интерактивная карта мира',
                            ),
                            child: MouseRegion(
                              onHover: (event) => _onHover(event, scene),
                              onExit: (_) => _hover.value = null,
                              child: GestureDetector(
                                // Country lists and answer buttons retain named actions.
                                excludeFromSemantics: true,
                                behavior: HitTestBehavior.opaque,
                                onTapUp: (details) {
                                  final local = details.localPosition;
                                  final previous = _lastTapAt;
                                  final doubleTap =
                                      _doubleTapTimer?.isActive == true &&
                                      previous != null &&
                                      (local - previous).distance < 40;
                                  _doubleTapTimer?.cancel();
                                  if (doubleTap) {
                                    _lastTapAt = null;
                                    final origin = Offset(
                                      (_view.width - scene.width) / 2,
                                      (_view.height - scene.height) / 2,
                                    );
                                    _zoom(
                                      2,
                                      MatrixUtils.transformPoint(
                                        widget.controller.value,
                                        local + origin,
                                      ),
                                    );
                                    return;
                                  }
                                  _lastTapAt = local;
                                  _doubleTapTimer = Timer(
                                    kDoubleTapTimeout,
                                    () => _lastTapAt = null,
                                  );
                                  if (!widget.selectionEnabled) {
                                    _focusNode.requestFocus();
                                    return;
                                  }
                                  final point = QuizipediaPoint(
                                    local.dx / scene.width,
                                    local.dy / scene.height,
                                  );
                                  final hit = _featureAt(point, scene);
                                  final water =
                                      widget.waters
                                          .where(
                                            (w) =>
                                                w.kind != 'marine' &&
                                                w.contains(
                                                  WaterPoint(point.x, point.y),
                                                  tolerance:
                                                      6 /
                                                      (scene.width *
                                                          widget
                                                              .controller
                                                              .value
                                                              .getMaxScaleOnAxis()),
                                                ),
                                          )
                                          .firstOrNull ??
                                      (hit == null
                                          ? widget.waters
                                                .where(
                                                  (w) => w.contains(
                                                    WaterPoint(
                                                      point.x,
                                                      point.y,
                                                    ),
                                                  ),
                                                )
                                                .firstOrNull
                                          : null);
                                  if (water != null &&
                                      widget.onWaterSelect != null) {
                                    widget.onWaterSelect!(water.id);
                                  } else if (hit != null) {
                                    widget.onSelect(hit.id);
                                  } else if (widget.showFlags &&
                                      widget.flagPoints.isNotEmpty) {
                                    final scale = widget.controller.value
                                        .getMaxScaleOnAxis();
                                    final rx = 14 / (scene.width * scale);
                                    final ry = 14 / (scene.height * scale);
                                    String? pointHit;
                                    var best = double.infinity;
                                    for (final entry
                                        in widget.flagPoints.entries) {
                                      if (_featureMetrics.containsKey(
                                        entry.key,
                                      )) {
                                        continue;
                                      }
                                      final dx =
                                          (point.x - entry.value.dx).abs() / rx;
                                      final dy =
                                          (point.y - entry.value.dy).abs() / ry;
                                      if (dx <= 1 && dy <= 1) {
                                        final d = dx * dx + dy * dy;
                                        if (d < best) {
                                          best = d;
                                          pointHit = entry.key;
                                        }
                                      }
                                    }
                                    widget.onSelect(pointHit);
                                  } else {
                                    widget.onSelect(null);
                                  }
                                  // After the callbacks: pages unfocus the
                                  // search field on selection, which would
                                  // otherwise drop the map's keyboard focus.
                                  _focusNode.requestFocus();
                                },
                                child: ValueListenableBuilder<Matrix4>(
                                  valueListenable: widget.controller,
                                  builder: (context, transform, child) =>
                                      CustomPaint(
                                        key: const Key('quizipedia-map'),
                                        size: scene,
                                        painter: _MapPainter(
                                          features: widget.features,
                                          waters: widget.waters,
                                          selectedWater: widget.selectedWater,
                                          showWaterLabels:
                                              widget.showWaterLabels,
                                          dark:
                                              Theme.of(context).brightness ==
                                              Brightness.dark,
                                          flags: const {},
                                          highlighted: widget.highlighted,
                                          selected: widget.selected,
                                          correct: widget.correct,
                                          numbers: widget.numbers,
                                          neighborIds: widget.neighborIds,
                                          capitalPoints: widget.capitalPoints,
                                          capitalLabels: widget.capitalLabels,
                                          showFlags: widget.showFlags,
                                          showLabels: widget.showLabels,
                                          sceneScale: transform
                                              .getMaxScaleOnAxis(),
                                          russian:
                                              Localizations.localeOf(context)
                                                  .languageCode ==
                                              'ru',
                                        ),
                                      ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(child: _factLabels(scene)),
                // Overlays live inside their own Positioned.fill: a Positioned
                // returned from a builder is not a direct Stack child.
                Positioned.fill(
                  child: IgnorePointer(
                    child: ValueListenableBuilder<(QuizipediaFeature, Offset)?>(
                      valueListenable: _hover,
                      builder: (context, hover, _) {
                        if (hover == null) return const SizedBox.shrink();
                        final (feature, at) = hover;
                        final colors = Theme.of(context).colorScheme;
                        return Stack(
                          children: [
                            Positioned(
                              left: (at.dx + 14).clamp(
                                0.0,
                                math.max(0.0, _view.width - 170),
                              ),
                              top: (at.dy + 16).clamp(
                                0.0,
                                math.max(0.0, _view.height - 32),
                              ),
                              child: Material(
                                key: const Key('map-hover-label'),
                                color: colors.inverseSurface,
                                borderRadius: BorderRadius.circular(6),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  child: Text(
                                    Localizations.localeOf(context)
                                                .languageCode ==
                                            'ru'
                                        ? feature.nameRu
                                        : feature.nameEn,
                                    style: TextStyle(
                                      color: colors.onInverseSurface,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: ListenableBuilder(
                      listenable: _focusNode,
                      builder: (context, _) {
                        final keyboard =
                            _focusNode.hasFocus &&
                            FocusManager.instance.highlightMode ==
                                FocusHighlightMode.traditional;
                        if (!keyboard) return const SizedBox.shrink();
                        return DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(context).colorScheme.primary,
                              width: 2,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                if (widget.showSelectionLabel)
                  Positioned(
                    top: 8,
                    left: 8,
                    right: 8,
                    child: selectionLabel(),
                  ),
                Positioned(
                  top: compactControls
                      ? null
                      : (widget.showSelectionLabel ? 56 : 8),
                  bottom: compactControls ? 12 : null,
                  right: compactControls ? 12 : 8,
                  child: zoomControls(),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

/// Per-feature label geometry, computed once per feature list.
class _FeatureMetrics {
  const _FeatureMetrics({
    required this.area,
    required this.landBounds,
    required this.anchor,
  });

  /// Bounding-box area of the largest outer ring (normalised units).
  final double area;

  /// Bounds of the largest land part, where the label is anchored.
  final Rect landBounds;

  /// Label anchor on land, or null when no safe inland point exists.
  final Offset? anchor;

  static Rect _bounds(List<QuizipediaPoint> ring) {
    var left = 1.0, top = 1.0, right = 0.0, bottom = 0.0;
    for (final p in ring) {
      if (p.x < left) left = p.x;
      if (p.x > right) right = p.x;
      if (p.y < top) top = p.y;
      if (p.y > bottom) bottom = p.y;
    }
    return Rect.fromLTRB(left, top, right, bottom);
  }

  factory _FeatureMetrics.of(QuizipediaFeature feature) {
    Rect? land;
    var area = 0.0;
    for (final polygon in feature.polygons) {
      if (polygon.isEmpty || polygon.first.isEmpty) continue;
      final rect = _bounds(polygon.first);
      final size = rect.width * rect.height;
      if (land == null || size > area) {
        land = rect;
        area = size;
      }
    }
    if (land == null) {
      return const _FeatureMetrics(
        area: 0,
        landBounds: Rect.zero,
        anchor: null,
      );
    }
    Offset? anchor = land.center;
    if (!feature.contains(QuizipediaPoint(anchor.dx, anchor.dy))) {
      // Do not shift a name away from an internal hole into a neighbour.
      if (feature.polygons.any((polygon) => polygon.length > 1)) {
        anchor = null;
      } else {
        final bounds = land;
        final candidates =
            [
              for (final x in [.25, .5, .75])
                for (final y in [.25, .5, .75])
                  Offset(
                    bounds.left + bounds.width * x,
                    bounds.top + bounds.height * y,
                  ),
            ]..sort(
              (a, b) => (a - bounds.center).distanceSquared.compareTo(
                (b - bounds.center).distanceSquared,
              ),
            );
        anchor = candidates
            .where((p) => feature.contains(QuizipediaPoint(p.dx, p.dy)))
            .firstOrNull;
      }
    }
    return _FeatureMetrics(area: area, landBounds: land, anchor: anchor);
  }
}

/// Scene-space paths for one geometry list, rebuilt only when the scene size
/// changes. Rebuilding 10k vertices twice per frame dominated pinch frames.
class _PathCache<T> {
  _PathCache(this.build);
  final List<Path> Function(T item, Size size) build;
  Size _size = Size.zero;
  final _paths = <T, List<Path>>{};

  List<Path> of(T item, Size size) {
    if (size != _size) {
      _paths.clear();
      _size = size;
    }
    return _paths[item] ??= build(item, size);
  }
}

Path _ringsPath(Iterable<Iterable<({double x, double y})>> rings, Size size) {
  final path = Path()..fillType = PathFillType.evenOdd;
  for (final ring in rings) {
    var first = true;
    for (final point in ring) {
      if (first) {
        path.moveTo(point.x * size.width, point.y * size.height);
        first = false;
      } else {
        path.lineTo(point.x * size.width, point.y * size.height);
      }
    }
    path.close();
  }
  return path;
}

class _MapPainter extends CustomPainter {
  static final _featurePaths = _PathCache<QuizipediaFeature>(
    (feature, size) => [
      for (final polygon in feature.polygons)
        _ringsPath(
          polygon.map((ring) => ring.map((p) => (x: p.x, y: p.y))),
          size,
        ),
    ],
  );
  static final _waterPaths = _PathCache<WaterShape>(
    (water, size) => [
      for (final polygon in water.polygons)
        _ringsPath(
          polygon.map((ring) => ring.map((p) => (x: p.x, y: p.y))),
          size,
        ),
    ],
  );
  static final _waterLinePaths = _PathCache<WaterShape>(
    (water, size) => [
      for (final line in water.lines)
        Path()
          ..moveTo(line.first.x * size.width, line.first.y * size.height)
          ..addPolygon([
            for (final p in line.skip(1))
              Offset(p.x * size.width, p.y * size.height),
          ], false),
    ],
  );

  const _MapPainter({
    required this.features,
    this.flags = const {},
    this.dark = false,
    required this.highlighted,
    required this.selected,
    required this.correct,
    required this.numbers,
    required this.neighborIds,
    this.capitalPoints = const {},
    this.capitalLabels = const {},
    this.showFlags = false,
    required this.showLabels,
    required this.russian,
    required this.sceneScale,
    this.waters = const [],
    this.selectedWater,
    this.showWaterLabels = true,
  });
  final List<WaterShape> waters;
  final String? selectedWater;
  final bool showWaterLabels;
  final List<QuizipediaFeature> features;
  final Map<String, ui.Image> flags;
  final String? highlighted, selected, correct;
  final List<String> numbers;
  final Set<String> neighborIds;
  final Map<String, Offset> capitalPoints;
  final Map<String, String> capitalLabels;
  final bool showFlags;
  final bool showLabels, russian, dark;
  final double sceneScale;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = dark ? const Color(0xff101f2d) : const Color(0xffd9edfc),
    );
    _paintWaters(canvas, size, marine: true);
    for (final feature in features) {
      for (final path in _featurePaths.of(feature, size)) {
        final fill = feature.id == correct
            ? const Color(0xff3caa70)
            : feature.id == selected
            ? const Color(0xff467eaf)
            : feature.id == highlighted
            ? const Color(0xff537b9a)
            : (dark
                  ? const [
                      Color(0xff253d50),
                      Color(0xff294756),
                      Color(0xff354356),
                      Color(0xff344c51),
                      Color(0xff354553),
                      Color(0xff30414c),
                    ]
                  : const [
                      Color(0xffd6e7b5),
                      Color(0xfff2d7a4),
                      Color(0xffc4dfd0),
                      Color(0xffead2bd),
                      Color(0xffd9d7ec),
                      Color(0xfff2e5b6),
                    ])[feature.id.codeUnits
                      .fold<int>(0, (a, b) => a * 31 + b)
                      .abs() %
                  6];
        canvas.drawPath(path, Paint()..color = fill);
      }
    }
    _paintWaters(canvas, size, marine: false);
    for (final feature in [
      ...features.where((f) => f.id != selected),
      ...features.where((f) => f.id == selected),
    ]) {
      for (final path in _featurePaths.of(feature, size)) {
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = (feature.id == selected ? 1.4 : .5) / sceneScale
            ..color = feature.id == selected
                ? (dark ? const Color(0xff9bceff) : const Color(0xff194b7c))
                : neighborIds.contains(feature.id)
                ? (dark ? const Color(0xfff2c879) : const Color(0xff9a6500))
                : (dark ? const Color(0xff617b90) : const Color(0xff8296a4)),
        );
      }
    }
    _paintWaterLabels(canvas, size);
    _paintCapitalMarkers(canvas, size);
    if (showLabels) {
      for (final feature in features) {
        if (feature.id != highlighted) continue;
        final at = _centroid(feature, size);
        paintMapLabel(
          canvas,
          at,
          russian ? feature.nameRu : feature.nameEn,
          Colors.black,
          Colors.white,
          sceneScale: sceneScale,
        );
      }
    }
    for (var i = 0; i < numbers.length; i++) {
      final feature = features
          .where((feature) => feature.id == numbers[i])
          .firstOrNull;
      if (feature == null) continue;
      paintMapLabel(
        canvas,
        _centroid(feature, size),
        '${i + 1}',
        Colors.white,
        const Color(0xff263d58),
        sceneScale: sceneScale,
      );
    }
  }

  void _paintCapitalMarkers(Canvas canvas, Size size) {
    // At world scale, capitals are a dense geographic layer. Keep a sparse,
    // stable set of dots until the user zooms; the selected capital is never
    // culled. Labels wait for a closer view so they cannot obscure countries.
    final markers = <Rect>[];
    final occupied = <Rect>[];
    final ids = capitalPoints.keys.where(capitalLabels.containsKey).toList()
      ..sort((a, b) {
        final selectedFirst = (a == selected ? 1 : 0).compareTo(
          b == selected ? 1 : 0,
        );
        return selectedFirst != 0 ? -selectedFirst : a.compareTo(b);
      });
    for (final id in ids) {
      final point = capitalPoints[id]!;
      if (point.dx < 0 || point.dx > 1 || point.dy < 0 || point.dy > 1) {
        continue;
      }
      final at = Offset(point.dx * size.width, point.dy * size.height);
      final radius = (id == selected ? 5.0 : 3.5) / sceneScale;
      final marker = Rect.fromCircle(
        center: at,
        radius: math.max(radius, 12 / sceneScale),
      );
      final showMarker =
          id == selected ||
          sceneScale >= 2.25 ||
          !markers.any(
            (other) => other.overlaps(marker.inflate(12 / sceneScale)),
          );
      if (!showMarker) continue;
      markers.add(marker);
      canvas.drawCircle(
        at,
        radius,
        Paint()
          ..color = id == selected
              ? const Color(0xfff6c762)
              : const Color(0xff153f62),
      );
      canvas.drawCircle(
        at,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1 / sceneScale
          ..color = Colors.white,
      );
      if ((id != selected && sceneScale < 2.25) ||
          (showFlags && id == selected)) {
        continue;
      }
      final text = capitalLabels[id]!;
      final painter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: dark ? Colors.white : const Color(0xff102a43),
            fontSize: 10 / sceneScale,
            fontWeight: id == selected ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: 108 / sceneScale);
      final rect = Rect.fromLTWH(
        at.dx + 5 / sceneScale,
        at.dy - painter.height - 5 / sceneScale,
        painter.width + 6 / sceneScale,
        painter.height + 4 / sceneScale,
      );
      final canLabel =
          id == selected ||
          (rect.left >= 0 &&
              rect.top >= 0 &&
              rect.right <= size.width &&
              !occupied.any(
                (other) => other.overlaps(rect.inflate(3 / sceneScale)),
              ));
      if (!canLabel) {
        painter.dispose();
        continue;
      }
      occupied.add(rect);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(3 / sceneScale)),
        Paint()
          ..color = (dark ? const Color(0xff102333) : Colors.white).withValues(
            alpha: .9,
          ),
      );
      painter.paint(
        canvas,
        rect.topLeft + Offset(3 / sceneScale, 2 / sceneScale),
      );
      painter.dispose();
    }
  }

  void _paintWaters(Canvas canvas, Size size, {required bool marine}) {
    final matching = waters.where((w) => (w.kind == 'marine') == marine);
    for (final water in [
      ...matching.where((w) => w.id != selectedWater),
      ...matching.where((w) => w.id == selectedWater),
    ]) {
      final selected = water.id == selectedWater;
      final color = selected
          ? const Color(0xfff6c762)
          : dark
          ? const Color(0xff4a90b8)
          : const Color(0xff378cc0);
      for (final path in _waterPaths.of(water, size)) {
        canvas.drawPath(
          path,
          Paint()
            ..color = selected
                ? color.withValues(alpha: .55)
                : marine
                ? (dark ? const Color(0xff153044) : const Color(0xffc8e5f6))
                : color,
        );
        if (selected) {
          canvas.drawPath(
            path,
            Paint()
              ..color = color
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2 / sceneScale,
          );
        }
      }
      for (final path in _waterLinePaths.of(water, size)) {
        canvas.drawPath(
          path,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..strokeWidth = (selected ? 3 : 1.4) / sceneScale,
        );
      }
    }
  }

  void _paintWaterLabels(Canvas canvas, Size size) {
    if (!showWaterLabels) return;
    final occupied = <Rect>[];
    final ordered = [
      ...waters.where((w) => w.id == selectedWater),
      ...waters.where((w) => w.id != selectedWater),
    ];
    for (final water in ordered) {
      final selected = water.id == selectedWater;
      if (!selected &&
          sceneScale < 2.5 &&
          !const {'Q97', 'Q98', 'Q1239', 'Q788', 'Q7354'}.contains(water.id)) {
        continue;
      }
      final text = russian ? water.nameRu : water.nameEn;
      final at = Offset(
        water.anchor.x * size.width,
        water.anchor.y * size.height,
      );
      final label = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            fontSize: 12 / sceneScale,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final rect = Rect.fromCenter(
        center: at,
        width: label.width + 12 / sceneScale,
        height: 24 / sceneScale,
      );
      if (!selected &&
          (!(Offset.zero & size).contains(rect.topLeft) ||
              !(Offset.zero & size).contains(rect.bottomRight) ||
              occupied.any((r) => r.overlaps(rect)))) {
        continue;
      }
      occupied.add(rect);
      paintMapLabel(
        canvas,
        at,
        text,
        selected ? const Color(0xff251f12) : Colors.white,
        selected ? const Color(0xfff6c762) : const Color(0xff164760),
        sceneScale: sceneScale,
      );
    }
  }

  Offset _centroid(QuizipediaFeature feature, Size size) {
    final ring = feature.polygons.first.first;
    final points = ring.length > 1 && ring.first == ring.last
        ? ring.take(ring.length - 1)
        : ring;
    var x = 0.0, y = 0.0, count = 0;
    for (final point in points) {
      x += point.x;
      y += point.y;
      count++;
    }
    return Offset(x / count * size.width, y / count * size.height);
  }

  @override
  bool shouldRepaint(covariant _MapPainter old) =>
      features != old.features ||
      waters != old.waters ||
      selectedWater != old.selectedWater ||
      showWaterLabels != old.showWaterLabels ||
      dark != old.dark ||
      flags != old.flags ||
      highlighted != old.highlighted ||
      selected != old.selected ||
      correct != old.correct ||
      showLabels != old.showLabels ||
      showFlags != old.showFlags ||
      russian != old.russian ||
      sceneScale != old.sceneScale ||
      neighborIds != old.neighborIds ||
      capitalPoints != old.capitalPoints ||
      capitalLabels != old.capitalLabels ||
      numbers != old.numbers;
}

/// A boxed caption that keeps its screen size at any map zoom.
void paintMapLabel(
  Canvas canvas,
  Offset center,
  String text,
  Color foreground,
  Color background, {
  double sceneScale = 1,
}) {
  canvas.save();
  canvas.translate(center.dx, center.dy);
  canvas.scale(1 / sceneScale);
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        color: foreground,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  final rect = Rect.fromCenter(
    center: Offset.zero,
    width: painter.width + 8,
    height: painter.height + 4,
  );
  if (background != Colors.transparent) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(5)),
      Paint()..color = background,
    );
  }
  painter.paint(canvas, rect.topLeft + const Offset(4, 2));
  canvas.restore();
}
