import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

import 'history_event_symbol.dart';

class GlobePolity {
  const GlobePolity({required this.name, required this.polygons});
  final String name;

  /// GeoJSON MultiPolygon coordinates: polygons, rings, [longitude, latitude].
  final List polygons;
}

/// Unit-disc orthographic projection; points on the back are not visible.
Offset? projectGlobePoint(
  double longitude,
  double latitude,
  double centerLongitude,
  double centerLatitude,
) {
  final phi = latitude * math.pi / 180;
  final delta = (longitude - centerLongitude) * math.pi / 180;
  final center = centerLatitude * math.pi / 180;
  final depth =
      math.sin(phi) * math.sin(center) +
      math.cos(phi) * math.cos(center) * math.cos(delta);
  if (depth < -1e-10) return null;
  return Offset(
    math.cos(phi) * math.sin(delta),
    math.cos(phi) * math.cos(delta) * math.sin(center) -
        math.sin(phi) * math.cos(center),
  );
}

class HistoryGlobe extends StatefulWidget {
  const HistoryGlobe({
    super.key,
    required this.land,
    required this.polities,
    required this.year,
    required this.onSelect,
    this.selectedName,
    this.eventPins = const [],
    this.onEventTap,
  });
  final List land;
  final List<GlobePolity> polities;
  final int year;
  final ValueChanged<String?> onSelect;
  final String? selectedName;
  final List<HistoryEventPin> eventPins;
  final ValueChanged<HistoryEventPin>? onEventTap;
  @override
  State<HistoryGlobe> createState() => _HistoryGlobeState();
}

class _Vector {
  const _Vector(this.x, this.y, this.z);
  final double x, y, z;
}

List<List<List<_Vector>>> _prepare(List polygons) => [
  for (final polygon in polygons)
    if (polygon is List)
      [
        for (final ring in polygon)
          if (ring is List)
            [
              for (final point in ring)
                if (point is List &&
                    point.length >= 2 &&
                    point[0] is num &&
                    point[1] is num)
                  _coordinate(
                    (point[0] as num).toDouble(),
                    (point[1] as num).toDouble(),
                  ),
            ],
      ],
];
_Vector _coordinate(double lon, double lat) {
  final a = lon * math.pi / 180, b = lat * math.pi / 180;
  return _Vector(
    math.cos(b) * math.sin(a),
    math.sin(b),
    math.cos(b) * math.cos(a),
  );
}

class _Projected {
  const _Projected(this.x, this.y, this.depth);
  final double x, y, depth;
}

class _Scene {
  _Scene(this.land, this.polities, this.radius, this.center, this.grid);
  final Path grid;
  final Path land;
  final List<(String, Path, Color)> polities;
  final double radius;
  final Offset center;
}

class _HistoryGlobeState extends State<HistoryGlobe> {
  late List<List<List<_Vector>>> _land;
  late List<(String, List<List<List<_Vector>>>)> _polities;
  final _prepared = Expando<List<List<List<_Vector>>>>();
  static final _graticule = [
    for (double lon = -180; lon < 180; lon += 30)
      [for (double lat = -90; lat <= 90; lat += 4) _coordinate(lon, lat)],
    for (double lat = -60; lat <= 60; lat += 30)
      [for (double lon = -180; lon <= 180; lon += 4) _coordinate(lon, lat)],
  ];
  double _longitude = 15, _latitude = 30, _zoom = 1;
  double _startZoom = 1;
  String? _selected;
  _Scene? _scene;
  Size? _sceneSize;

  @override
  void initState() {
    super.initState();
    _selected = widget.selectedName;
    _prepareData();
  }

  void _prepareData() {
    _land = _prepared[widget.land] ??= _prepare(widget.land);
    _polities = [
      for (final p in widget.polities)
        (p.name, _prepared[p.polygons] ??= _prepare(p.polygons)),
    ];
    _scene = null;
  }

  @override
  void didUpdateWidget(covariant HistoryGlobe oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.land, widget.land) ||
        !identical(oldWidget.polities, widget.polities)) {
      _prepareData();
    }
    if (widget.year != oldWidget.year ||
        widget.selectedName != oldWidget.selectedName) {
      _selected = widget.selectedName;
    }
  }

  void _invalidate() {
    _scene = null;
  }

  void _changeZoom(double value) => setState(() {
    _zoom = value.clamp(1, 3);
    _invalidate();
  });

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;
    // Browsers report wheel deltas in logical pixels.  Keep the response
    // deliberately small so a trackpad does not jump across the globe.
    final amount = event.scrollDelta.dy;
    if (amount == 0) return;
    _changeZoom(_zoom * math.pow(0.999, amount).toDouble());
  }

  void _panZoomUpdate(Offset delta, double scale) {
    final size = _sceneSize;
    if (size == null || size.isEmpty) return;
    final radius = size.shortestSide * .47 * _zoom;
    setState(() {
      if (delta != Offset.zero) {
        _longitude = (_longitude - delta.dx / radius * 180 / math.pi) % 360;
        _latitude = (_latitude + delta.dy / radius * 180 / math.pi).clamp(
          -85,
          85,
        );
      }
      _zoom = (_startZoom * scale).clamp(1, 3);
      _invalidate();
    });
  }

  _Scene _getScene(Size size) {
    if (_scene != null && _sceneSize == size) return _scene!;
    final radius = math.min(size.width, size.height) * 0.47 * _zoom;
    final center = Offset(size.width / 2, size.height / 2);
    final lon = _longitude * math.pi / 180, lat = _latitude * math.pi / 180;
    final sl = math.sin(lon),
        cl = math.cos(lon),
        sp = math.sin(lat),
        cp = math.cos(lat);
    _Projected project(_Vector p) {
      final x = p.x * cl - p.z * sl;
      final z = p.x * sl + p.z * cl;
      return _Projected(x, z * sp - p.y * cp, z * cp + p.y * sp);
    }

    Offset point(_Projected p) => center + Offset(p.x * radius, p.y * radius);
    Offset horizon(_Projected a, _Projected b) {
      final t = a.depth / (a.depth - b.depth);
      final x = a.x + (b.x - a.x) * t, y = a.y + (b.y - a.y) * t;
      final length = math.sqrt(x * x + y * y);
      if (length < 1e-12) return center + Offset(radius, 0);
      return center + Offset(x / length * radius, y / length * radius);
    }

    Path geometry(List<List<List<_Vector>>> polygons) {
      final result = Path()..fillType = PathFillType.evenOdd;
      for (final polygon in polygons) {
        for (final ring in polygon) {
          if (ring.length < 3) continue;
          final points = [for (final v in ring) project(v)];
          final firstBack = points.indexWhere((p) => p.depth < 0);
          if (firstBack < 0) {
            final start = point(points.first);
            result.moveTo(start.dx, start.dy);
            for (final p in points.skip(1)) {
              final v = point(p);
              result.lineTo(v.dx, v.dy);
            }
            result.close();
            continue;
          }
          Offset? entry;
          for (var step = 1; step <= points.length; step++) {
            final a = points[(firstBack + step - 1) % points.length];
            final b = points[(firstBack + step) % points.length];
            if (a.depth < 0 && b.depth >= 0) {
              entry = horizon(a, b);
              result.moveTo(entry.dx, entry.dy);
              final v = point(b);
              result.lineTo(v.dx, v.dy);
            } else if (a.depth >= 0 && b.depth >= 0 && entry != null) {
              final v = point(b);
              result.lineTo(v.dx, v.dy);
            } else if (a.depth >= 0 && b.depth < 0 && entry != null) {
              final exit = horizon(a, b);
              result.lineTo(exit.dx, exit.dy);
              final startAngle = math.atan2(
                exit.dy - center.dy,
                exit.dx - center.dx,
              );
              final endAngle = math.atan2(
                entry.dy - center.dy,
                entry.dx - center.dx,
              );
              var sweep = endAngle - startAngle;
              while (sweep > math.pi) {
                sweep -= 2 * math.pi;
              }
              while (sweep < -math.pi) {
                sweep += 2 * math.pi;
              }
              result.arcTo(
                Rect.fromCircle(center: center, radius: radius),
                startAngle,
                sweep,
                false,
              );
              result.close();
              entry = null;
            }
          }
        }
      }
      return result;
    }

    const colors = [
      Color(0xff9fc9bd),
      Color(0xffe0b77c),
      Color(0xff9bb8cd),
      Color(0xffc8b0cb),
      Color(0xffbdd09a),
      Color(0xffd5a69a),
    ];
    final grid = Path();
    for (final arc in _graticule) {
      var first = true;
      for (final v in arc) {
        final projected = project(v);
        if (projected.depth < 0) {
          first = true;
          continue;
        }
        final screen = point(projected);
        if (first) {
          grid.moveTo(screen.dx, screen.dy);
        } else {
          grid.lineTo(screen.dx, screen.dy);
        }
        first = false;
      }
    }
    _sceneSize = size;
    return _scene = _Scene(
      geometry(_land),
      [
        for (final item in _polities)
          (
            item.$1,
            geometry(item.$2),
            colors[item.$1.codeUnits.fold<int>(
              0,
              (n, c) => (n * 31 + c) % colors.length,
            )],
          ),
      ],
      radius,
      center,
      grid,
    );
  }

  @override
  Widget build(BuildContext context) {
    final russian = Localizations.localeOf(context).languageCode == 'ru';
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final scene = _getScene(size);
        return Stack(
          fit: StackFit.expand,
          children: [
            Listener(
              behavior: HitTestBehavior.opaque,
              onPointerSignal: _onPointerSignal,
              onPointerPanZoomStart: (_) => _startZoom = _zoom,
              onPointerPanZoomUpdate: (d) =>
                  _panZoomUpdate(d.panDelta, d.scale),
              child: GestureDetector(
                // Native trackpad streams are handled by the Listener above.
                supportedDevices: const {
                  PointerDeviceKind.touch,
                  PointerDeviceKind.mouse,
                  PointerDeviceKind.stylus,
                  PointerDeviceKind.invertedStylus,
                },
                behavior: HitTestBehavior.opaque,
                onScaleStart: (_) => _startZoom = _zoom,
                onScaleUpdate: (details) =>
                    _panZoomUpdate(details.focalPointDelta, details.scale),
                onTapUp: (details) {
                  final point = details.localPosition;
                  String? selection;
                  if ((point - scene.center).distance <= scene.radius) {
                    for (final polity in scene.polities.reversed) {
                      if (polity.$2.contains(point)) {
                        selection = polity.$1;
                        break;
                      }
                    }
                  }
                  setState(() => _selected = selection);
                  widget.onSelect(selection);
                },
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRect(
                      child: CustomPaint(
                        painter: _GlobePainter(scene, _selected),
                        size: Size.infinite,
                      ),
                    ),
                    for (final pin in widget.eventPins)
                      if (projectGlobePoint(
                            pin.longitude,
                            pin.latitude,
                            _longitude,
                            _latitude,
                          )
                          case final p?)
                        Positioned(
                          left:
                              scene.center.dx +
                              p.dx * scene.radius -
                              historyPinTarget / 2,
                          top:
                              scene.center.dy +
                              p.dy * scene.radius -
                              historyPinTarget / 2,
                          width: historyPinTarget,
                          height: historyPinTarget,
                          child: historyPinWidget(
                            pin,
                            () => widget.onEventTap?.call(pin),
                          ),
                        ),
                  ],
                ),
              ),
            ),
            Positioned(
              right: 12,
              bottom: 12,
              child: Material(
                color: const Color(0xfff5f2e7),
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      color: const Color(0xff244e57),
                      tooltip: russian ? 'Увеличить' : 'Zoom in',
                      onPressed: () => _changeZoom(_zoom * 1.25),
                      icon: const Icon(Icons.add),
                    ),
                    IconButton(
                      color: const Color(0xff244e57),
                      tooltip: russian ? 'Уменьшить' : 'Zoom out',
                      onPressed: () => _changeZoom(_zoom / 1.25),
                      icon: const Icon(Icons.remove),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GlobePainter extends CustomPainter {
  const _GlobePainter(this.scene, this.selected);
  final _Scene scene;
  final String? selected;
  @override
  void paint(Canvas canvas, Size size) {
    final globe = Path()
      ..addOval(Rect.fromCircle(center: scene.center, radius: scene.radius));
    canvas.save();
    canvas.clipPath(globe);
    canvas.drawCircle(
      scene.center,
      scene.radius,
      Paint()
        ..shader = ui.Gradient.radial(
          scene.center - Offset(scene.radius * .3, scene.radius * .3),
          scene.radius * 1.5,
          [const Color(0xffb7e0e1), const Color(0xff47839b)],
        ),
    );
    canvas.drawPath(
      scene.grid,
      Paint()
        ..color = const Color(0x46346170)
        ..style = PaintingStyle.stroke
        ..strokeWidth = .7,
    );
    canvas.drawPath(scene.land, Paint()..color = const Color(0xffe6dfca));
    for (final polity in scene.polities) {
      canvas.drawPath(
        polity.$2,
        Paint()
          ..color = polity.$1 == selected ? const Color(0xffdfab4a) : polity.$3,
      );
      canvas.drawPath(
        polity.$2,
        Paint()
          ..color = const Color(0xff557c75)
          ..style = PaintingStyle.stroke
          ..strokeWidth = .55,
      );
    }
    canvas.drawCircle(
      scene.center,
      scene.radius,
      Paint()
        ..shader = ui.Gradient.radial(
          scene.center - Offset(scene.radius * .26, scene.radius * .3),
          scene.radius * 1.35,
          const [Color(0x10ffffff), Color(0x00ffffff), Color(0x460b3444)],
          const [0.0, .52, 1.0],
        ),
    );
    canvas.restore();
    canvas.drawCircle(
      scene.center,
      scene.radius,
      Paint()
        ..color = const Color(0xff1b6371)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant _GlobePainter oldDelegate) =>
      !identical(scene, oldDelegate.scene) || selected != oldDelegate.selected;
}
