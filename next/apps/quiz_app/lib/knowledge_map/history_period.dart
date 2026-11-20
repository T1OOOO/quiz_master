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
  late bool hasCustomDraft = widget.customRange;
  late int decade = (widget.year - 1) ~/ 10 * 10 + 1;
  int get century => (decade - 1) ~/ 100 * 100 + 1;
  _Page page = _Page.years;
  bool enteringYear = false;
  String typedYear = '';
  int? get jumpYear {
    final year = int.tryParse(typedYear);
    return year != null && year >= 1501 && year <= 2000 ? year : null;
  }

  int count(int start, int end) =>
      widget.events.where((e) => historyEventOverlaps(e, start, end)).length;
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
        hasCustomDraft = true;
        if (first) {
          from = v;
        } else {
          to = v;
        }
      }),
    ),
  );

  Widget yearTile(int year) {
    final n = count(year, year);
    final current = year == widget.year;
    final colors = Theme.of(context).colorScheme;
    final ink = current
        ? colors.onPrimary
        : n > 0
        ? colors.onSecondaryContainer
        : colors.onSurfaceVariant;
    void select() => choose(year, step, false);
    return Semantics(
      button: true,
      selected: current,
      label: '$year · ${eventCount(n)}',
      excludeSemantics: true,
      onTap: select,
      child: TextButton(
        style: TextButton.styleFrom(
          minimumSize: const Size(0, 56),
          padding: const EdgeInsets.symmetric(vertical: 5),
          backgroundColor: current
              ? colors.primary
              : n > 0
              ? colors.secondaryContainer
              : colors.surfaceContainerLow,
          foregroundColor: ink,
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
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            Text('$n', style: const TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget rowOfYears() {
    final screen = MediaQuery.sizeOf(context);
    final scaled = MediaQuery.textScalerOf(context).scale(16);
    final columns = ((screen.width.clamp(0, 456) - 48) / (3 * scaled + 5))
        .floor()
        .clamp(1, 5);
    return Column(
      children: [
        for (var offset = 0; offset < 10; offset += columns)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              spacing: 4,
              children: [
                for (var i = offset; i < offset + columns; i++)
                  Expanded(
                    child: i < 10 ? yearTile(decade + i) : const SizedBox(),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget pageButton(String label, _Page destination) => TextButton(
    style: TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 4),
    ),
    onPressed: () => setState(() => page = destination),
    child: Text(label),
  );

  int? nearestYearOutsideEmptyDecade() {
    int? nearest;
    var bestDistance = 501;
    final last = decade + 9;
    for (final event in widget.events) {
      if (historyEventOverlaps(event, decade, last)) return null;
      final later = event['start'] > last;
      final int year = later ? event['start'] : event['end'];
      if (year < 1501 || year > 2000) continue;
      final distance = later ? year - last : decade - year;
      if (distance < bestDistance || (distance == bestDistance && later)) {
        nearest = year;
        bestDistance = distance;
      }
    }
    return nearest;
  }

  Widget calendar() {
    if (page == _Page.years) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
                child: Wrap(
                  alignment: WrapAlignment.center,
                  children: [
                    pageButton(centuryName(century), _Page.centuries),
                    pageButton('$decade–${decade + 9}', _Page.decades),
                  ],
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
          Text(
            step == 1
                ? t('Событий за год', 'Events per year')
                : t(
                    'Выберите начало · событий за год',
                    'Choose a start · events per year',
                  ),
            style: Theme.of(context).textTheme.labelMedium,
          ),
          rowOfYears(),
          if (nearestYearOutsideEmptyDecade() case final year?)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                icon: const Icon(Icons.event_available_outlined, size: 18),
                label: Text(
                  t('К событиям $year года', 'Browse events in $year'),
                ),
                onPressed: () =>
                    setState(() => decade = (year - 1) ~/ 10 * 10 + 1),
              ),
            ),
        ],
      );
    }
    final centuries = page == _Page.centuries;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            IconButton(
              tooltip: t('Назад', 'Back'),
              icon: const Icon(Icons.arrow_back),
              onPressed: () => setState(() => page = _Page.years),
            ),
            if (!centuries) pageButton(centuryName(century), _Page.centuries),
            Text(
              centuries
                  ? t('Выберите век', 'Choose a century')
                  : t('Выберите десятилетие', 'Choose a decade'),
            ),
          ],
        ),
        Wrap(
          spacing: 6,
          children: [
            for (final first
                in centuries
                    ? [1501, 1601, 1701, 1801, 1901]
                    : List.generate(10, (i) => century + 10 * i))
              OutlinedButton(
                onPressed: () => setState(() {
                  decade = first;
                  page = centuries ? _Page.decades : _Page.years;
                }),
                child: Text(
                  centuries ? centuryName(first) : '$first–${first + 9}',
                ),
              ),
          ],
        ),
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
    final jump = jumpYear;
    final showCurrent = widget.customRange || step != widget.step;
    return AlertDialog(
      insetPadding: const EdgeInsets.all(12),
      titlePadding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
      contentPadding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      scrollable: true,
      title: Row(
        children: [
          Expanded(
            child: Text(
              t('Календарь лет', 'Year calendar'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          IconButton(
            tooltip: t('Закрыть', 'Close'),
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 4,
              children: [
                for (final length in [1, 10, 50, 0])
                  ChoiceChip(
                    showCheckmark: false,
                    padding: EdgeInsets.zero,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 7),
                    selected: length == 0 ? custom : !custom && step == length,
                    label: Text(
                      length == 0
                          ? t('Диапазон', 'Range')
                          : length == 1
                          ? t('1 год', '1 year')
                          : '$length ${t("лет", "years")}',
                    ),
                    onSelected: (_) => setState(() {
                      custom = length == 0;
                      if (custom) {
                        enteringYear = false;
                        if (!hasCustomDraft) {
                          to = historyPeriod(widget.year, step).$2.toString();
                        }
                      } else {
                        step = length;
                      }
                    }),
                  ),
              ],
            ),
            if (custom) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  field(true),
                  const SizedBox(width: 12),
                  field(false),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                valid
                    ? eventCount(count(start, end))
                    : t(
                        'Укажите период от 1501 до 2000 года',
                        'Enter a period within 1501–2000',
                      ),
              ),
            ] else if (enteringYear) ...[
              const SizedBox(height: 8),
              TextFormField(
                autofocus: true,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: t('Год начала', 'Starting year'),
                  helperText: '1501–2000',
                  errorText: typedYear.length == 4 && jump == null
                      ? t('Год вне диапазона', 'Year out of range')
                      : null,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                onChanged: (v) => setState(() => typedYear = v),
                onFieldSubmitted: (_) {
                  if (jumpYear case final year?) choose(year, step, false);
                },
              ),
            ] else
              calendar(),
            if (!custom)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  icon: Icon(
                    enteringYear
                        ? Icons.calendar_month_outlined
                        : Icons.keyboard_outlined,
                    size: 18,
                  ),
                  label: Text(
                    enteringYear
                        ? t('К выбору года', 'Browse years')
                        : t('Ввести год', 'Enter a year'),
                  ),
                  onPressed: () => setState(() {
                    enteringYear = !enteringYear;
                    typedYear = '';
                  }),
                ),
              ),
          ],
        ),
      ),
      actions: [
        if (custom)
          FilledButton(
            onPressed: valid
                ? () => choose(start, end - start + 1, true)
                : null,
            child: Text(t('Применить', 'Apply')),
          )
        else if (enteringYear)
          FilledButton(
            onPressed: jump == null ? null : () => choose(jump, step, false),
            child: Text(t('Перейти', 'Go')),
          )
        else if (showCurrent)
          FilledButton(
            onPressed: () => choose(widget.year, step, false),
            child: Text('${t("Показать", "Show")} ${a == b ? "$a" : "$a–$b"}'),
          ),
      ],
    );
  }
}
