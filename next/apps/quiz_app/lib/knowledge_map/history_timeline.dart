import 'package:flutter/material.dart';

int _distanceTo(Map event, int year) {
  final start = event['start'] as int;
  final end = event['end'] as int;
  return year < start
      ? start - year
      : year > end
      ? year - end
      : 0;
}

/// Inside an interval prefer the event that started most recently.
Map? closestHistoryEvent(Iterable<Map> events, int year) {
  Map? best;
  for (final event in events) {
    final distance = _distanceTo(event, year);
    if (best == null ||
        distance < _distanceTo(best, year) ||
        (distance == _distanceTo(best, year) &&
            (event['start'] as int) > (best['start'] as int))) {
      best = event;
    }
  }
  return best;
}

String historyEventDate(Map r) =>
    r['start'] == r['end'] ? '${r['start']}' : '${r['start']}–${r['end']}';

class HistoryTimeline extends StatelessWidget {
  const HistoryTimeline({
    super.key,
    required this.year,
    required this.centuryName,
    required this.russian,
    required this.countryName,
    required this.events,
    required this.eventCount,
    this.period,
    required this.onYear,
    required this.pickYear,
    required this.pickCentury,
    required this.pickCountry,
    required this.openEvents,
  });
  final int year, eventCount;
  final (int, int)? period;
  final String centuryName, countryName;
  final bool russian;
  final List<Map> events;
  final ValueChanged<int> onYear;
  final VoidCallback pickYear, pickCentury, pickCountry, openEvents;

  static const ink = Color(0xff193b43);
  static const accent = Color(0xff8b532c);
  static const paper = Color(0xfffff6e5);
  String t(String ru, String en) => russian ? ru : en;

  @override
  Widget build(BuildContext context) {
    final years = events.map((r) => r['start'] as int).toSet().toList()..sort();
    final (start, end) = period ?? (year, year);
    final interval = start != end;
    final previous = start > 1501
        ? (start - (end - start + 1)).clamp(1501, 2000)
        : null;
    final next = end < 2000 ? end + 1 : null;
    Widget step(int? target, bool forward) => IconButton(
      color: ink,
      disabledColor: const Color(0xffa69d89),
      tooltip: interval
          ? (forward
                ? t('Следующий период', 'Next period')
                : t('Предыдущий период', 'Previous period'))
          : forward
          ? t('Следующий год', 'Next year')
          : t('Предыдущий год', 'Previous year'),
      icon: Icon(
        forward ? Icons.skip_next_rounded : Icons.skip_previous_rounded,
      ),
      onPressed: target == null ? null : () => onYear(target),
    );
    final style = TextButton.styleFrom(
      foregroundColor: ink,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      minimumSize: const Size(44, 44),
    );
    final countLabel = '${t("События", "Events")} · $eventCount';
    return Material(
      color: paper,
      child: LayoutBuilder(
        builder: (context, box) {
          final compact = box.maxWidth < 580;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 48,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: CustomPaint(painter: _EventTicks(years)),
                      ),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: accent,
                          inactiveTrackColor: const Color(0xffcbbda6),
                          thumbColor: ink,
                          trackHeight: 8,
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 22,
                          ),
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 11,
                          ),
                          tickMarkShape: SliderTickMarkShape.noTickMark,
                        ),
                        child: Slider(
                          min: 1501,
                          max: 2000,
                          divisions: 499,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          label: '$year',
                          semanticFormatterCallback: (v) => '${v.round()}',
                          value: year.toDouble(),
                          onChanged: (v) => onYear(v.round()),
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    step(previous, false),
                    TextButton(
                      style: style,
                      onPressed: pickYear,
                      child: Text(
                        '$year',
                        maxLines: 1,
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    step(next, true),
                    Expanded(
                      child: TextButton(
                        style: style,
                        onPressed: pickCentury,
                        child: Text(
                          '$centuryName ${t("век", "century")}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    if (compact)
                      IconButton(
                        color: ink,
                        tooltip: countryName,
                        onPressed: pickCountry,
                        icon: const Icon(Icons.public),
                      )
                    else
                      Expanded(
                        flex: 3,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            style: style,
                            onPressed: pickCountry,
                            icon: const Icon(Icons.public, size: 18),
                            label: Text(
                              countryName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                    Tooltip(
                      message: countLabel,
                      excludeFromSemantics: true,
                      child: Semantics(
                        label: compact ? t('События', 'Events') : null,
                        child: TextButton.icon(
                          style: style,
                          onPressed: openEvents,
                          icon: const Icon(Icons.list_alt_outlined, size: 18),
                          label: Text(
                            compact ? '$eventCount' : countLabel,
                            maxLines: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _EventTicks extends CustomPainter {
  const _EventTicks(this.years);
  final List<int> years;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xffa68c69)
      ..strokeWidth = 1;
    for (final y in years) {
      final x = (y - 1501) / 499 * size.width;
      canvas.drawLine(
        Offset(x, size.height / 2 + 6),
        Offset(x, size.height / 2 + 10),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_EventTicks old) => old.years != years;
}
