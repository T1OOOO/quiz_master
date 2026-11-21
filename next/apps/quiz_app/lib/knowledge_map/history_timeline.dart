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
      color: const Color(0xfffcf7ed),
      elevation: 4,
      child: Builder(
        builder: (context) {
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

          final centuryMenu = PopupMenuButton<int>(
            tooltip: t('Выбрать век', 'Choose century'),
            position: PopupMenuPosition.under,
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
          );
          final stepMenu = PopupMenuButton<int>(
            tooltip: t('Шаг перелистывания', 'Navigation step'),
            position: PopupMenuPosition.under,
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
            child: _TimelineOption(stepText(step)),
          );
          const ink = Color(0xff503a27);
          final actionStyle = TextButton.styleFrom(
            foregroundColor: ink,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            minimumSize: const Size(0, 44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          );
          Widget arrow(String label, IconData icon, VoidCallback? change) =>
              SizedBox(
                width: 35,
                height: 44,
                child: IconButton(
                  tooltip: label,
                  icon: Icon(icon, color: ink),
                  onPressed: change,
                  padding: EdgeInsets.zero,
                ),
              );
          final navigation = DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xfff1e4d0),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                arrow(
                  t('Предыдущий период', 'Previous period'),
                  Icons.chevron_left,
                  start > 1501
                      ? () => onYear((start - step).clamp(1501, 2000))
                      : null,
                ),
                Expanded(
                  child: TextButton(
                    key: dateButton,
                    onPressed: openCalendar,
                    style: actionStyle,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        date,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
                arrow(
                  t('Следующий период', 'Next period'),
                  Icons.chevron_right,
                  end < 2000 ? () => onYear(end + 1) : null,
                ),
              ],
            ),
          );
          Widget dropdown(
            Key? key,
            IconData icon,
            String label,
            VoidCallback open, {
            bool emphasized = false,
          }) => TextButton(
            key: key,
            onPressed: open,
            style: emphasized
                ? actionStyle.copyWith(
                    backgroundColor: const WidgetStatePropertyAll(
                      Color(0xffefd7b5),
                    ),
                  )
                : actionStyle,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.expand_more, size: 16),
              ],
            ),
          );
          final filters = Row(
            children: [
              Expanded(
                child: dropdown(
                  countryButton,
                  Icons.public,
                  countryName,
                  pickCountry,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: dropdown(
                  eventsButton,
                  Icons.list_alt_outlined,
                  count,
                  openEvents,
                  emphasized: true,
                ),
              ),
            ],
          );
          final dates = Row(
            children: [
              Expanded(flex: 3, child: centuryMenu),
              const SizedBox(width: 4),
              Expanded(flex: 6, child: navigation),
              const SizedBox(width: 4),
              Expanded(flex: 3, child: stepMenu),
            ],
          );
          return Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [dates, filters],
                ),
              ),
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
    padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 10),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge
                ?.copyWith(color: const Color(0xff503a27)),
          ),
        ),
        const Icon(Icons.arrow_drop_down, size: 18, color: Color(0xff503a27)),
      ],
    ),
  );
}
