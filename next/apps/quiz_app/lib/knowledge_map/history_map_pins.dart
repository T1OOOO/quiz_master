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
  final _sizes = <String, Size>{};
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
    final maxWidth = math.min(152.0, size.width - 8);
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
    for (final g in [
      ?focused,
      ...groups.where((g) => g != focused && g.pins.length == 1),
    ]) {
      final active = g == focused;
      final pin = active ? focus! : g.pins.first;
      final title = active ? widget.caption ?? pin.title : pin.title;
      final measured = _sizes.putIfAbsent(title, () {
        final painter = TextPainter(
          text: TextSpan(text: title, style: style),
          textDirection: direction,
          textScaler: scaler,
          maxLines: 2,
          ellipsis: '…',
        )..layout(maxWidth: maxWidth - 10);
        final measured = Size(
          painter.width.ceilToDouble() + 10,
          painter.height.ceilToDouble() + 4,
        );
        painter.dispose();
        return measured;
      });
      final rect = _captionRect(g.at, measured, size, occupied);
      if (rect == null) continue;
      occupied.add(rect.inflate(2));
      captions.add(
        Positioned.fromRect(
          rect: rect,
          child: ExcludeSemantics(
            excluding: g.pins.length == 1 && title == pin.title,
            child: Material(
              color: active ? const Color(0xf522424a) : const Color(0xf4fffaf0),
              borderRadius: BorderRadius.circular(5),
              child: InkWell(
                onTap: () => onOpen([pin]),
                borderRadius: BorderRadius.circular(5),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: style.copyWith(
                      color: active ? Colors.white : const Color(0xff213f47),
                    ),
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
                    : (widget.russian
                          ? 'События рядом · $count'
                          : 'Nearby events · $count');
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
                              : CircleAvatar(
                                  radius: active ? 14 : 12,
                                  backgroundColor: const Color(0xff244f59),
                                  child: Text(
                                    '$count',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
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
  List<Rect> occupied,
) {
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
