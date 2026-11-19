import 'package:flutter/material.dart';

import 'history_event_symbol.dart';

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
    required this.century,
    required this.countryName,
    required this.events,
    required this.rows,
    required this.onYear,
    required this.pickYear,
    required this.pickCentury,
    required this.pickCountry,
    required this.setCentury,
    required this.openEvents,
    required this.openEvent,
  });
  final int year;
  final String centuryName, countryName;
  final bool russian, century;
  final List<Map> events, rows;
  final ValueChanged<int> onYear;
  final ValueChanged<bool> setCentury;
  final VoidCallback pickYear, pickCentury, pickCountry, openEvents;
  final ValueChanged<Map> openEvent;

  static const ink = Color(0xff193b43);
  static const accent = Color(0xff8b532c);
  static const paper = Color(0xfffff6e5);
  String t(String ru, String en) => russian ? ru : en;

  @override
  Widget build(BuildContext context) {
    final years = events.map((r) => r['start'] as int).toSet().toList()..sort();
    final previous = years.where((v) => v < year).lastOrNull;
    final next = years.where((v) => v > year).firstOrNull;
    final featured = closestHistoryEvent(rows.isEmpty ? events : rows, year);
    final country = TextButton.icon(
      style: TextButton.styleFrom(
        foregroundColor: ink,
        padding: const EdgeInsets.symmetric(horizontal: 6),
      ),
      icon: const Icon(Icons.public, size: 16),
      label: Text(countryName, overflow: TextOverflow.ellipsis, maxLines: 1),
      onPressed: pickCountry,
    );
    Widget step(int? target, bool forward) => IconButton(
      color: ink,
      disabledColor: const Color(0xffa69d89),
      tooltip: forward
          ? t('Следующий год с событием', 'Next event year')
          : t('Предыдущий год с событием', 'Previous event year'),
      icon: Icon(
        forward ? Icons.skip_next_rounded : Icons.skip_previous_rounded,
        size: 20,
      ),
      onPressed: target == null ? null : () => onYear(target),
    );
    return Material(
      color: paper,
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    TextButton(
                      onPressed: pickYear,
                      style: TextButton.styleFrom(foregroundColor: ink),
                      child: Text(
                        '$year',
                        style: const TextStyle(
                          fontFamily: 'serif',
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                    ),
                    step(previous, false),
                    Expanded(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: CustomPaint(
                              size: const Size(double.infinity, 22),
                              painter: _EventTicks(years),
                            ),
                          ),
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: const Color(0xff9a683b),
                              inactiveTrackColor: const Color(0xffc7bcaa),
                              thumbColor: ink,
                              trackHeight: 3,
                              overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 11,
                              ),
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 8,
                              ),
                              tickMarkShape: SliderTickMarkShape.noTickMark,
                            ),
                            child: Slider(
                              min: 1501,
                              max: 2000,
                              divisions: 499,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              label: '$year',
                              semanticFormatterCallback: (v) => '${v.round()}',
                              value: year.toDouble(),
                              onChanged: (v) => onYear(v.round()),
                            ),
                          ),
                        ],
                      ),
                    ),
                    step(next, true),
                    TextButton(
                      onPressed: pickCentury,
                      style: TextButton.styleFrom(foregroundColor: accent),
                      child: Text('$centuryName ${t("век", "century")}'),
                    ),
                  ],
                ),
                if (featured != null)
                  _StoryPreview(
                    key: ValueKey((year, countryName, century)),
                    rows: [featured, ...rows.where((e) => e != featured)],
                    nearest: rows.isEmpty,
                    russian: russian,
                    onOpen: openEvent,
                  ),
                Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: country,
                      ),
                    ),
                    PopupMenuButton<bool>(
                      tooltip: t('Период событий', 'Event period'),
                      initialValue: century,
                      onSelected: setCentury,
                      itemBuilder: (_) => [
                        for (final c in [false, true])
                          PopupMenuItem(
                            value: c,
                            child: Text(
                              c
                                  ? t('За век', 'Full century')
                                  : t('За год', 'This year'),
                            ),
                          ),
                      ],
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 10,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              century
                                  ? t('За век', 'Century')
                                  : t('За год', 'Year'),
                              style: const TextStyle(color: ink),
                            ),
                            const Icon(
                              Icons.arrow_drop_down,
                              size: 17,
                              color: ink,
                            ),
                          ],
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: openEvents,
                      style: TextButton.styleFrom(foregroundColor: accent),
                      child: Text('${t("События", "Events")} · ${rows.length}'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StoryPreview extends StatefulWidget {
  const _StoryPreview({
    super.key,
    required this.rows,
    required this.russian,
    required this.nearest,
    required this.onOpen,
  });
  final List<Map> rows;
  final bool russian, nearest;
  final ValueChanged<Map> onOpen;
  @override
  State<_StoryPreview> createState() => _StoryPreviewState();
}

class _StoryPreviewState extends State<_StoryPreview> {
  int index = 0;
  void move(int delta) =>
      setState(() => index = (index + delta) % widget.rows.length);
  @override
  Widget build(BuildContext context) {
    final event = widget.rows[index];
    final style = HistoryEventStyle.forKind(event['kind']);
    final ru = widget.russian;
    final many = widget.rows.length > 1;
    final meta = [
      if (widget.nearest) ru ? 'Ближайшее событие' : 'Nearest event',
      historyEventDate(event),
      ru ? style.ru : style.en,
    ].join(' · ');
    return GestureDetector(
      onHorizontalDragEnd: many
          ? (details) {
              final speed = details.primaryVelocity ?? 0;
              if (speed.abs() > 60) move(speed < 0 ? 1 : -1);
            }
          : null,
      child: Material(
        color: const Color(0xfff4ead6),
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => widget.onOpen(event),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  child: Row(
                    children: [
                      HistoryEventSeal(event['kind']),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              meta,
                              style: TextStyle(
                                color: style.color,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              event[ru ? 'title_ru' : 'title_en'],
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: HistoryTimeline.ink,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                height: 1.16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!many)
                        const Icon(
                          Icons.chevron_right,
                          color: HistoryTimeline.ink,
                        ),
                    ],
                  ),
                ),
              ),
            ),
            if (many)
              IconButton(
                tooltip: ru ? 'Листать события' : 'Cycle through events',
                onPressed: () => move(1),
                icon: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.arrow_forward,
                      size: 18,
                      color: HistoryTimeline.ink,
                    ),
                    Text(
                      '${index + 1}/${widget.rows.length}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: HistoryTimeline.ink,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
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
        Offset(x, size.height / 2 + 3),
        Offset(x, size.height / 2 + 7),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_EventTicks old) => old.years != years;
}
