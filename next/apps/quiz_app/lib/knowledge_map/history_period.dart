import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The map uses the anchor year for borders and an inclusive window for events.
(int, int) historyPeriod(int year, int length, {bool calendarCentury = false}) {
  final start = calendarCentury
      ? (year - 1) ~/ 100 * 100 + 1
      : year.clamp(1501, 2001 - length);
  return (start, start + length - 1);
}

class HistoryPeriodDialog extends StatefulWidget {
  const HistoryPeriodDialog({
    super.key,
    required this.year,
    required this.period,
    required this.russian,
  });
  final int year;
  final (int, int) period;
  final bool russian;

  @override
  State<HistoryPeriodDialog> createState() => _HistoryPeriodDialogState();
}

class _HistoryPeriodDialogState extends State<HistoryPeriodDialog> {
  late String from = widget.period.$1.toString(),
      to = widget.period.$2.toString();
  String t(String ru, String en) => widget.russian ? ru : en;

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

  @override
  Widget build(BuildContext context) {
    final start = int.tryParse(from), end = int.tryParse(to);
    final valid =
        start != null &&
        end != null &&
        start >= 1501 &&
        start <= end &&
        end <= 2000;
    return AlertDialog(
      title: Text(t('Период событий', 'Event period')),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 2,
            children: [
              for (final length in [1, 10, 50, 100])
                ActionChip(
                  label: Text(switch (length) {
                    1 => t('1 год', '1 year'),
                    100 => t('Век', 'Century'),
                    _ => '$length ${t("лет", "years")}',
                  }),
                  onPressed: () => Navigator.pop(context, (
                    widget.year,
                    length,
                    length == 100,
                  )),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            t('Свой диапазон', 'Custom range'),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          Row(children: [field(true), const SizedBox(width: 12), field(false)]),
          const SizedBox(height: 6),
          Text(
            t('1501–2000, включая оба года', '1501–2000, both years included'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(t('Закрыть', 'Close')),
        ),
        FilledButton(
          onPressed: valid
              ? () => Navigator.pop(context, (start, end - start + 1, false))
              : null,
          child: Text(t('Применить', 'Apply')),
        ),
      ],
    );
  }
}
