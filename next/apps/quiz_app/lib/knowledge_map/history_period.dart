import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

(int, int) historyPeriod(int year, int length) =>
    (year, (year + length - 1).clamp(year, 2000));

bool historyEventOverlaps(Map event, int start, int end) =>
    event['start'] <= end && event['end'] >= start;

enum _Page { centuries, decades, years }

class HistoryPeriodDialog extends StatefulWidget {
  const HistoryPeriodDialog({
    super.key,
    required this.year,
    required this.step,
    required this.customRange,
    required this.events,
    required this.russian,
  });
  final int year, step;
  final bool customRange, russian;
  final List<Map> events;

  @override
  State<HistoryPeriodDialog> createState() => _HistoryPeriodDialogState();
}

class _HistoryPeriodDialogState extends State<HistoryPeriodDialog> {
  late int step = widget.step;
  late bool custom = widget.customRange;
  late int decade = (widget.year - 1) ~/ 10 * 10 + 1;
  int get century => (decade - 1) ~/ 100 * 100 + 1;
  _Page page = _Page.years;
  late String from = widget.year.toString(),
      to = historyPeriod(widget.year, widget.step).$2.toString();
  String t(String ru, String en) => widget.russian ? ru : en;
  String centuryName(int first) {
    const roman = ['XVI', 'XVII', 'XVIII', 'XIX', 'XX'];
    return '${roman[(first - 1501) ~/ 100]} ${t("век", "century")}';
  }

  String eventCount(int n) {
    if (!widget.russian) return '$n ${n == 1 ? "event" : "events"}';
    final tens = n % 100, last = n % 10;
    if (tens >= 11 && tens <= 14) return '$n событий';
    if (last == 1) return '$n событие';
    return last >= 2 && last <= 4 ? '$n события' : '$n событий';
  }

  void choose(int start, int length, bool custom) =>
      Navigator.pop(context, (start, length, custom));

  Widget field(bool first) => Expanded(
    child: TextFormField(
      initialValue: first ? from : to,
      decoration: InputDecoration(
        labelText: first ? t('С года', 'From') : t('По год', 'Through'),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(4),
      ],
      onChanged: (v) => setState(() {
        if (first) {
          from = v;
        } else {
          to = v;
        }
      }),
    ),
  );

  Widget yearTile(int year) {
    final n = widget.events
        .where((e) => historyEventOverlaps(e, year, year))
        .length;
    final current = year == widget.year;
    final colors = Theme.of(context).colorScheme;
    void select() => choose(year, step, false);
    return SizedBox(
      width: 82,
      child: Semantics(
        button: true,
        selected: current,
        label: '$year · ${eventCount(n)}',
        excludeSemantics: true,
        onTap: select,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 52),
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 5),
            backgroundColor: current ? colors.primaryContainer : null,
            side: BorderSide(
              color: current ? colors.primary : colors.outlineVariant,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: select,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$year',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                eventCount(n),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget calendar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 6,
          children: [
            if (page == _Page.centuries)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(t('Выберите век', 'Choose a century')),
              )
            else
              TextButton.icon(
                icon: const Icon(Icons.expand_more, size: 16),
                onPressed: () => setState(() => page = _Page.centuries),
                label: Text(centuryName(century)),
              ),
            if (page == _Page.years)
              TextButton.icon(
                icon: const Icon(Icons.expand_more, size: 16),
                onPressed: () => setState(() => page = _Page.decades),
                label: Text('$decade–${decade + 9}'),
              ),
          ],
        ),
        if (page == _Page.centuries)
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              for (var first = 1501; first < 2000; first += 100)
                OutlinedButton(
                  onPressed: () => setState(() {
                    decade = first;
                    page = _Page.decades;
                  }),
                  child: Text(centuryName(first)),
                ),
            ],
          )
        else if (page == _Page.decades)
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              for (var first = century; first < century + 100; first += 10)
                OutlinedButton(
                  onPressed: () => setState(() {
                    decade = first;
                    page = _Page.years;
                  }),
                  child: Text('$first–${first + 9}'),
                ),
            ],
          )
        else ...[
          Row(
            children: [
              IconButton(
                tooltip: t('Предыдущие 10 лет', 'Previous 10 years'),
                icon: const Icon(Icons.chevron_left),
                onPressed: decade > 1501
                    ? () => setState(() => decade -= 10)
                    : null,
              ),
              Expanded(
                child: Text(
                  step == 1
                      ? t('Выберите год', 'Choose a year')
                      : t('Начало периода', 'Period starts in'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              IconButton(
                tooltip: t('Следующие 10 лет', 'Next 10 years'),
                icon: const Icon(Icons.chevron_right),
                onPressed: decade < 1991
                    ? () => setState(() => decade += 10)
                    : null,
              ),
            ],
          ),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [for (var i = decade; i < decade + 10; i++) yearTile(i)],
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final start = int.tryParse(from), end = int.tryParse(to);
    final valid =
        start != null &&
        end != null &&
        start >= 1501 &&
        start <= end &&
        end <= 2000;
    final (a, b) = historyPeriod(widget.year, step);
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      title: Text(t('Календарь лет', 'Year calendar')),
      scrollable: true,
      content: SizedBox(
        width: 400,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 2,
              children: [
                for (final length in [1, 10, 50])
                  ChoiceChip(
                    showCheckmark: false,
                    selected: !custom && step == length,
                    label: Text(
                      length == 1
                          ? t('1 год', '1 year')
                          : '$length ${t("лет", "years")}',
                    ),
                    onSelected: (_) => setState(() {
                      step = length;
                      custom = false;
                    }),
                  ),
                ChoiceChip(
                  showCheckmark: false,
                  selected: custom,
                  label: Text(t('Свой диапазон', 'Custom range')),
                  onSelected: (_) => setState(() => custom = true),
                ),
              ],
            ),
            if (!custom)
              calendar()
            else ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  field(true),
                  const SizedBox(width: 12),
                  field(false),
                ],
              ),
              Text(
                t(
                  '1501–2000, включая оба года',
                  '1501–2000, both years included',
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(t('Закрыть', 'Close')),
        ),
        if (custom)
          FilledButton(
            onPressed: valid
                ? () => choose(start, end - start + 1, true)
                : null,
            child: Text(t('Применить', 'Apply')),
          )
        else if (page == _Page.years &&
            widget.year >= decade &&
            widget.year < decade + 10)
          FilledButton(
            onPressed: () => choose(widget.year, step, false),
            child: Text('${t("Показать", "Show")} ${a == b ? "$a" : "$a–$b"}'),
          ),
      ],
    );
  }
}
