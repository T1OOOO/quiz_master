import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'history_event_symbol.dart';

/// Lays out tap targets in screen pixels in both map projections.
class HistoryMapPins extends StatelessWidget {
  const HistoryMapPins({
    required this.size,
    required this.pins,
    required this.project,
    required this.focus,
    required this.caption,
    required this.onOpen,
    required this.russian,
    super.key,
  });

  final Size size;
  final Iterable<HistoryEventPin> pins;
  final Offset? Function(HistoryEventPin) project;
  final HistoryEventPin? focus;
  final String? caption;
  final bool russian;
  final ValueChanged<List<HistoryEventPin>> onOpen;

  @override
  Widget build(BuildContext context) {
    final groups = <({Offset at, List<HistoryEventPin> pins})>[];
    final bounds = (Offset.zero & size).inflate(historyPinTarget / 2);
    for (final pin in {...pins, ?focus}) {
      final at = project(pin);
      if (at == null || !bounds.contains(at)) continue;
      final near = groups
          .where((g) => (g.at - at).distance < historyPinTarget)
          .firstOrNull;
      if (near == null) {
        groups.add((at: at, pins: [pin]));
      } else {
        near.pins.add(pin);
      }
    }
    final focused = groups.where((g) => g.pins.contains(focus)).firstOrNull;
    final labelWidth = math.min(190.0, math.max(0.0, size.width - 12));
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
                    : (russian
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
                                  size: active ? 33 : 26,
                                )
                              : CircleAvatar(
                                  radius: active ? 17 : 15,
                                  backgroundColor: const Color(0xff244f59),
                                  child: Text(
                                    '$count',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
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
        if (focused != null &&
            caption != null &&
            size.width >= 90 &&
            size.height >= 100)
          Positioned(
            left: (focused.at.dx - labelWidth / 2).clamp(
              6.0,
              size.width - labelWidth - 6,
            ),
            width: labelWidth,
            top: focused.at.dy < size.height - 90 ? focused.at.dy + 21 : null,
            bottom: focused.at.dy >= size.height - 90
                ? size.height - focused.at.dy + 21
                : null,
            child: Center(
              child: Material(
                color: const Color(0xf51c3a42),
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => onOpen([focus!]),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    child: Text(
                      caption!,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        height: 1.15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
