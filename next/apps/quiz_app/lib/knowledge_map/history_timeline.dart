import 'package:flutter/material.dart';

import 'history_period.dart' show historyCenturyNumerals, historySteps;

String historyEventDate(Map r) =>
    r['start'] == r['end'] ? '${r['start']}' : '${r['start']}–${r['end']}';

class HistoryTimeline extends StatelessWidget {
  const HistoryTimeline({
    super.key,
    this.dateButton,
    this.countryButton,
    this.eventsButton,
    required this.period,
    required this.step,
    required this.russian,
    required this.countryName,
    required this.eventCount,
    required this.onYear,
    required this.onCentury,
    required this.onStep,
    required this.openCalendar,
    required this.pickCountry,
    required this.openEvents,
  });
  final Key? dateButton, countryButton, eventsButton;
  final (int, int) period;
  final int step, eventCount;
  final String countryName;
  final bool russian;
  final ValueChanged<int> onYear, onCentury, onStep;
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
          final centuryIndex = (start - 1501) ~/ 100;
          String stepText(int size) {
            if (!russian) return '$size ${size == 1 ? 'year' : 'years'}';
            final word = switch ((size % 100, size % 10)) {
              (>= 11 && <= 14, _) => 'лет',
              (_, 1) => 'год',
              (_, 2 || 3 || 4) => 'года',
              _ => 'лет',
            };
            return '$size $word';
          }

          final options = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: PopupMenuButton<int>(
                  tooltip: t('Выбрать век', 'Choose century'),
                  position: PopupMenuPosition.over,
                  initialValue: 1501 + centuryIndex * 100,
                  onSelected: onCentury,
                  itemBuilder: (_) => [
                    for (var i = 0; i < historyCenturyNumerals.length; i++)
                      CheckedPopupMenuItem(
                        value: 1501 + i * 100,
                        checked: i == centuryIndex,
                        child: Text(
                          '${historyCenturyNumerals[i]} ${t('век', 'century')} · ${1501 + i * 100}–${1600 + i * 100}',
                        ),
                      ),
                  ],
                  child: _TimelineOption(era),
                ),
              ),
              Flexible(
                child: PopupMenuButton<int>(
                  tooltip: t('Шаг перелистывания', 'Navigation step'),
                  position: PopupMenuPosition.over,
                  initialValue: step,
                  onSelected: onStep,
                  itemBuilder: (_) => [
                    for (final size in historySteps)
                      CheckedPopupMenuItem(
                        value: size,
                        checked: size == step,
                        child: Text(stepText(size)),
                      ),
                  ],
                  child: _TimelineOption(
                    '${t('Шаг', 'Step')} · ${stepText(step)}',
                  ),
                ),
              ),
            ],
          );
          final navigation = Row(
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
                        Text(
                          date,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
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
                  key: countryButton,
                  tooltip: countryName,
                  onPressed: pickCountry,
                  icon: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.public, size: 18),
                      Icon(Icons.arrow_drop_down, size: 14),
                    ],
                  ),
                )
              else
                Expanded(
                  flex: 2,
                  child: TextButton.icon(
                    key: countryButton,
                    onPressed: pickCountry,
                    icon: const Icon(Icons.public, size: 18),
                    label: Row(
                      children: [
                        Flexible(
                          child: Text(
                            countryName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down, size: 16),
                      ],
                    ),
                  ),
                ),
              Expanded(
                flex: 2,
                child: TextButton(
                  key: eventsButton,
                  onPressed: openEvents,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      children: [
                        Text(count),
                        const Icon(Icons.arrow_drop_down, size: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: box.maxWidth < 740
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [options, navigation],
                  )
                : Row(
                    children: [
                      options,
                      Expanded(child: navigation),
                    ],
                  ),
          );
        },
      ),
    );
  }
}

class _TimelineOption extends StatelessWidget {
  const _TimelineOption(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
        const Icon(Icons.arrow_drop_down, size: 18),
      ],
    ),
  );
}
