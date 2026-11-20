import 'package:flutter/material.dart';

import 'history_period.dart' show historyCenturyNumerals;

String historyEventDate(Map r) =>
    r['start'] == r['end'] ? '${r['start']}' : '${r['start']}–${r['end']}';

class HistoryTimeline extends StatelessWidget {
  const HistoryTimeline({
    super.key,
    this.dateButton,
    required this.period,
    required this.step,
    required this.russian,
    required this.countryName,
    required this.eventCount,
    required this.onYear,
    required this.openCalendar,
    required this.pickCountry,
    required this.openEvents,
  });
  final Key? dateButton;
  final (int, int) period;
  final int step, eventCount;
  final String countryName;
  final bool russian;
  final ValueChanged<int> onYear;
  final VoidCallback openCalendar, pickCountry, openEvents;
  String t(String ru, String en) => russian ? ru : en;

  @override
  Widget build(BuildContext context) {
    final (start, end) = period;
    final date = start == end ? '$start' : '$start–$end';
    final firstCentury = historyCenturyNumerals[(start - 1501) ~/ 100];
    final lastCentury = historyCenturyNumerals[(end - 1501) ~/ 100];
    final era = firstCentury == lastCentury
        ? '$firstCentury ${t("век", "century")}'
        : '$firstCentury–$lastCentury ${t("вв.", "centuries")}';
    final count = '${t("События", "Events")} · $eventCount';
    return Material(
      color: const Color(0xfffff6e5),
      child: LayoutBuilder(
        builder: (context, box) {
          final compact = box.maxWidth < 580;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                IconButton(
                  tooltip: t('Предыдущий период', 'Previous period'),
                  icon: const Icon(Icons.chevron_left),
                  onPressed: start > 1501
                      ? () => onYear((start - step).clamp(1501, 2000))
                      : null,
                ),
                Expanded(
                  flex: 3,
                  child: TextButton(
                    key: dateButton,
                    onPressed: openCalendar,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!compact)
                            const Icon(Icons.calendar_month_outlined, size: 18),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ExcludeSemantics(
                                child: Text(
                                  era,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    height: 1.05,
                                  ),
                                ),
                              ),
                              Text(
                                date,
                                style: const TextStyle(
                                  fontSize: 18,
                                  height: 1.12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const Icon(Icons.arrow_drop_down, size: 18),
                        ],
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: t('Следующий период', 'Next period'),
                  icon: const Icon(Icons.chevron_right),
                  onPressed: end < 2000 ? () => onYear(end + 1) : null,
                ),
                if (compact)
                  IconButton(
                    tooltip: countryName,
                    onPressed: pickCountry,
                    icon: const Icon(Icons.public, size: 20),
                  )
                else
                  Expanded(
                    flex: 2,
                    child: TextButton.icon(
                      onPressed: pickCountry,
                      icon: const Icon(Icons.public, size: 18),
                      label: Text(
                        countryName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                Expanded(
                  flex: 2,
                  child: TextButton(
                    onPressed: openEvents,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                    ),
                    child: FittedBox(fit: BoxFit.scaleDown, child: Text(count)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
