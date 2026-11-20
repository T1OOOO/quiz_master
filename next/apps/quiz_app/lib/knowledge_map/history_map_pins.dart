import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'history_event_symbol.dart';

/// Lays out tap targets in screen pixels in both map projections.
class HistoryMapPins extends StatefulWidget {
  const HistoryMapPins({
    required this.size,
    required this.pins,
    required this.project,
    required this.focus,
    required this.caption,
    required this.onOpen,
    required this.russian,
    this.obstacles = const [],
    super.key,
  });

  final Size size;
  final Iterable<HistoryEventPin> pins;
  final Offset? Function(HistoryEventPin) project;
  final HistoryEventPin? focus;
  final String? caption;
  final bool russian;
  final ValueChanged<List<HistoryEventPin>> onOpen;

  final List<Rect> obstacles;

  @override
  State<HistoryMapPins> createState() => _HistoryMapPinsState();
}

typedef _PinGroup = ({Offset at, List<HistoryEventPin> pins});

class _HistoryMapPinsState extends State<HistoryMapPins> {
  // The globe reprojects the same titles on every frame of a rotation.
  final _sizes = <(String, int, double), Size>{};
  double _lastWidth = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sizes.clear();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size, focus = widget.focus, onOpen = widget.onOpen;
    final groups = <_PinGroup>[];
    if (size.shortestSide < historyPinTarget) return const SizedBox.shrink();
    const radius = historyPinTarget / 2;
    final bounds = (Offset.zero & size).inflate(historyPinTarget / 2);
    for (final pin in {...widget.pins, ?focus}) {
      final point = widget.project(pin);
      if (point == null || !bounds.contains(point)) continue;
      final at = Offset(
        point.dx.clamp(radius, size.width - radius),
        point.dy.clamp(radius, size.height - radius),
      );
      final near = groups
          .where(
            (g) =>
                (g.at.dx - at.dx).abs() < historyPinTarget &&
                (g.at.dy - at.dy).abs() < historyPinTarget,
          )
          .firstOrNull;
      if (near == null) {
        groups.add((at: at, pins: [pin]));
      } else {
        near.pins.add(pin);
      }
    }
    final focused = groups.where((g) => g.pins.contains(focus)).firstOrNull;
    final occupied = [
      ...widget.obstacles,
      for (final g in groups) Rect.fromCircle(center: g.at, radius: radius),
    ];
    final captions = <Widget>[];
    final leaders = <(Offset, Offset)>[];
    final maxWidth = math.min(210.0, size.width - 8);
    if (_lastWidth != maxWidth) {
      _sizes.clear();
      _lastWidth = maxWidth;
    }
    final style = DefaultTextStyle.of(context).style.copyWith(
      fontSize: 11.5,
      height: 1.15,
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
    );
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    Size measure(String title, int lines, double width) =>
        _sizes.putIfAbsent((title, lines, width), () {
          final painter = TextPainter(
            text: TextSpan(text: title, style: style),
            textDirection: direction,
            textScaler: scaler,
            maxLines: lines,
            ellipsis: '…',
          )..layout(maxWidth: width - 10);
          final measured = Size(
            painter.width.ceilToDouble(),
            painter.height.ceilToDouble(),
          );
          painter.dispose();
          return measured;
        });
    final others = groups.where((g) => g != focused).toList()
      ..sort((a, b) => b.pins.length.compareTo(a.pins.length));
    for (final g in [?focused, ...others]) {
      final active = g == focused;
      final preview = !active && g.pins.length > 1;
      final pin = active ? focus! : g.pins.first;
      final titles = preview
          ? g.pins.take(2).map((p) => p.title).toList()
          : [active ? widget.caption ?? pin.title : pin.title];
      final width = preview ? maxWidth : math.min(maxWidth, 152.0);
      final lines = preview ? 1 : 2;
      final sizes = [for (final title in titles) measure(title, lines, width)];
      final measured = Size(
        sizes.map((s) => s.width).reduce(math.max) + 10,
        sizes.fold(4.0, (h, s) => h + s.height),
      );
      final rect =
          _captionRect(g.at, measured, size, occupied) ??
          (preview && measured.width > 112
              ? _captionRect(g.at, Size(112, measured.height), size, occupied)
              : null) ??
          (preview
              ? _captionRect(
                  g.at,
                  Size(math.min(154, measured.width), measured.height),
                  size,
                  occupied,
                  allowDistant: true,
                )
              : null);
      if (rect == null) continue;
      if (preview) {
        final end = Offset(
          g.at.dx.clamp(rect.left, rect.right),
          g.at.dy.clamp(rect.top, rect.bottom),
        );
        leaders.add((g.at, end));
      }
      occupied.add(rect.inflate(2));
      captions.add(
        Positioned.fromRect(
          rect: rect,
          child: ExcludeSemantics(
            excluding: !active || titles.first == pin.title,
            child: Material(
              color: active ? const Color(0xf522424a) : const Color(0xf4fffaf0),
              borderRadius: BorderRadius.circular(5),
              child: InkWell(
                onTap: () => onOpen(preview ? g.pins : [pin]),
                borderRadius: BorderRadius.circular(5),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: preview
                        ? CrossAxisAlignment.start
                        : CrossAxisAlignment.center,
                    children: [
                      for (final title in titles)
                        Text(
                          title,
                          maxLines: lines,
                          overflow: TextOverflow.ellipsis,
                          textAlign: preview
                              ? TextAlign.start
                              : TextAlign.center,
                          style: style.copyWith(
                            color: active
                                ? Colors.white
                                : const Color(0xff213f47),
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
    return Stack(
      children: [
        if (leaders.isNotEmpty)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _PinLeaders(leaders)),
            ),
          ),
        for (final g in groups)
          Positioned.fromRect(
            rect: Rect.fromCenter(
              center: g.at,
              width: historyPinTarget,
              height: historyPinTarget,
            ),
            child: Builder(
              builder: (context) {
                final pin = g.pins.first;
                final active = g.pins.contains(focus);
                final count = g.pins.length;
                final label = count == 1
                    ? pin.title
                    : [
                        widget.russian
                            ? 'События рядом · $count'
                            : 'Nearby events · $count',
                        ...g.pins.take(3).map((p) => p.title),
                        if (count > 3)
                          widget.russian
                              ? 'И ещё ${count - 3}'
                              : 'And ${count - 3} more',
                      ].join('\n');
                return Semantics(
                  button: true,
                  label: label,
                  child: Tooltip(
                    message: label,
                    excludeFromSemantics: true,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onOpen(g.pins),
                      child: Center(
                        child: Container(
                          key: active
                              ? const ValueKey('history-focus-ring')
                              : null,
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: active
                                ? const Color(0xffffd681)
                                : const Color(0xfffbf2da),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x66312217),
                                blurRadius: 3,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          child: count == 1
                              ? HistoryEventSeal(
                                  pin.kind,
                                  size: active ? 27 : 22,
                                )
                              : SizedBox(
                                  width: 38,
                                  height: 30,
                                  child: Stack(
                                    children: [
                                      Positioned(
                                        left: 0,
                                        top: 0,
                                        child: HistoryEventSeal(
                                          pin.kind,
                                          size: 23,
                                        ),
                                      ),
                                      Positioned(
                                        right: 0,
                                        bottom: 0,
                                        child: HistoryEventSeal(
                                          g.pins[1].kind,
                                          size: 23,
                                        ),
                                      ),
                                      if (count > 2)
                                        Positioned(
                                          right: 0,
                                          top: 0,
                                          child: DecoratedBox(
                                            decoration: BoxDecoration(
                                              color: const Color(0xff213f47),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 2,
                                                  ),
                                              child: Text(
                                                '+${count - 2}',
                                                textScaler:
                                                    TextScaler.noScaling,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 10,
                                                  height: 1.15,
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
                  ),
                );
              },
            ),
          ),
        ...captions,
      ],
    );
  }
}

Rect? _captionRect(
  Offset anchor,
  Size label,
  Size viewport,
  List<Rect> occupied, {
  bool allowDistant = false,
}) {
  const gap = historyPinTarget / 2 + 2;
  final w = label.width, h = label.height;
  if (w > viewport.width - 6 || h > viewport.height - 6) return null;
  final x = anchor.dx, y = anchor.dy;
  for (final corner in [
    Offset(x - w / 2, y + gap),
    Offset(x - w / 2, y - gap - h),
    Offset(x + gap, y - h / 2),
    Offset(x - gap - w, y - h / 2),
    Offset(x + gap, y + gap),
    Offset(x - gap - w, y + gap),
    Offset(x + gap, y - gap - h),
    Offset(x - gap - w, y - gap - h),
    if (allowDistant)
      for (
        double distance = gap + 24;
        distance <= math.min(viewport.longestSide / 2, 230);
        distance += 24
      )
        for (final dx in [0.0, -w / 2, w / 2])
          for (final top in [y - distance - h, y + distance])
            Offset(x - w / 2 + dx, top),
  ]) {
    final rect =
        Offset(
          corner.dx.clamp(3.0, viewport.width - w - 3),
          corner.dy.clamp(3.0, viewport.height - h - 3),
        ) &
        label;
    if (!occupied.any(rect.overlaps)) return rect;
  }
  return null;
}

class _PinLeaders extends CustomPainter {
  const _PinLeaders(this.lines);
  final List<(Offset, Offset)> lines;

  @override
  void paint(Canvas canvas, Size size) {
    final halo = Paint()
      ..color = const Color(0xd9fff7e6)
      ..strokeWidth = 3;
    final ink = Paint()
      ..color = const Color(0xdd36575a)
      ..strokeWidth = 1.25;
    for (final (start, end) in lines) {
      canvas.drawLine(start, end, halo);
      canvas.drawLine(start, end, ink);
    }
  }

  @override
  bool shouldRepaint(_PinLeaders oldDelegate) => true;
}
