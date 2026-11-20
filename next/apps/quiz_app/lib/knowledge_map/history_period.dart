import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

(int, int) historyPeriod(int year, int length) =>
    (year, (year + length - 1).clamp(year, 2000));

bool historyEventOverlaps(Map event, int start, int end) =>
    event['start'] <= end && event['end'] >= start;

typedef PeriodChoice = (int, int, bool);

Future<PeriodChoice?> showHistoryPeriodMenu(
  BuildContext anchor,
  HistoryPeriodMenu picker,
) {
  final overlay =
      Navigator.of(anchor).overlay!.context.findRenderObject() as RenderBox;
  final box = anchor.findRenderObject() as RenderBox;
  final origin = box.localToGlobal(Offset.zero, ancestor: overlay);
  final width = math.min(392.0, overlay.size.width - 20);
  final height = math.min(
    430.0,
    math.max(140.0, origin.dy - MediaQuery.paddingOf(anchor).top - 12),
  );
  return showMenu<PeriodChoice>(
    context: anchor,
    semanticLabel: picker.russian ? 'Выбор периода' : 'Choose period',
    position: RelativeRect.fromRect(
      Rect.fromLTWH(origin.dx, origin.dy - height - 4, box.size.width, height),
      Offset.zero & overlay.size,
    ),
    constraints: BoxConstraints.tightFor(width: width),
    menuPadding: EdgeInsets.zero,
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    items: [_PeriodEntry(height: height, child: picker)],
  );
}

class _PeriodEntry extends PopupMenuEntry<PeriodChoice> {
  const _PeriodEntry({required this.height, required this.child});
  @override
  final double height;
  final Widget child;
  @override
  bool represents(PeriodChoice? value) => false;
  @override
  State<_PeriodEntry> createState() => _PeriodEntryState();
}

class _PeriodEntryState extends State<_PeriodEntry> {
  @override
  Widget build(BuildContext context) => SizedBox(
    height: math.min(
      widget.height,
      math.max(
        140.0,
        MediaQuery.sizeOf(context).height -
            MediaQuery.viewInsetsOf(context).bottom -
            32,
      ),
    ),
    child: widget.child,
  );
}

class HistoryPeriodMenu extends StatefulWidget {
  const HistoryPeriodMenu({
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
  State<HistoryPeriodMenu> createState() => _HistoryPeriodMenuState();
}

class _HistoryPeriodMenuState extends State<HistoryPeriodMenu> {
  static const steps = [1, 5, 10, 25, 50, 100];
  late int step = widget.customRange ? 1 : widget.step;
  late bool custom = widget.customRange;
  bool typing = false;
  final currentRow = GlobalKey();
  (int, int)? revealed;
  late int anchorYear = widget.year;
  late String from = '${widget.year}',
      to = '${historyPeriod(widget.year, widget.step).$2}';
  String exact = '';
  bool editedRange = false;
  String t(String ru, String en) => widget.russian ? ru : en;
  String span(int a, int b) => a == b ? '$a' : '$a–$b';
  int count(int a, int b) =>
      widget.events.where((r) => historyEventOverlaps(r, a, b)).length;
  String amount(int n) {
    if (!widget.russian) return '$n ${n == 1 ? "event" : "events"}';
    if (n % 100 >= 11 && n % 100 <= 14) return '$n событий';
    return '$n ${n % 10 == 1
        ? "событие"
        : n % 10 >= 2 && n % 10 <= 4
        ? "события"
        : "событий"}';
  }

  void choose(int a, int length, bool range) =>
      Navigator.pop(context, (a, length, range));
  int get block => 1501 + (anchorYear - 1501) ~/ (10 * step) * 10 * step;
  int get last => math.min(2000, block + 10 * step - 1);
  String groupName(int start) =>
      span(start, math.min(2000, start + 10 * step - 1));
  int? get nearby {
    int? nearest;
    int distance = 501;
    for (final r in widget.events) {
      if (historyEventOverlaps(r, block, last)) return null;
      final later = r['start'] > last;
      final int y = later ? r['start'] : r['end'];
      final d = later ? y - last : block - y;
      if (y >= 1501 && y <= 2000 && (d < distance || d == distance && later)) {
        nearest = y;
        distance = d;
      }
    }
    return nearest;
  }

  Widget numericField(
    String label,
    String value,
    ValueChanged<String> change, {
    VoidCallback? submit,
    bool autofocus = false,
  }) => TextFormField(
    key: ValueKey(label),
    initialValue: value,
    autofocus: autofocus,
    decoration: InputDecoration(
      labelText: label,
      isDense: true,
      border: const OutlineInputBorder(),
    ),
    keyboardType: TextInputType.number,
    textInputAction: TextInputAction.done,
    inputFormatters: [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(4),
    ],
    onChanged: (v) => setState(() => change(v)),
    onFieldSubmitted: (_) => submit?.call(),
  );

  (int, int)? get entered {
    final first = int.tryParse(custom ? from : exact);
    if (first == null || first < 1501 || first > 2000) return null;
    final end = custom ? int.tryParse(to) : historyPeriod(first, step).$2;
    return end == null || end < first || end > 2000 ? null : (first, end);
  }

  void apply() {
    final dates = entered;
    if (dates != null) {
      choose(dates.$1, custom ? dates.$2 - dates.$1 + 1 : step, custom);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dates = entered;
    final lengths = DropdownButton<int>(
      isExpanded: true,
      value: custom ? 0 : step,
      underline: const SizedBox.shrink(),
      items: [
        for (final n in [...steps, 0])
          DropdownMenuItem(
            value: n,
            child: Text(
              n == 0
                  ? t('Свой диапазон', 'Custom range')
                  : n == 1
                  ? t('1 год', '1 year')
                  : '$n ${t("лет", "years")}',
            ),
          ),
      ],
      onChanged: (v) {
        if (v == null) return;
        setState(() {
          if (v == 0 && !editedRange && !widget.customRange) {
            to = '${historyPeriod(widget.year, step).$2}';
          }
          custom = v == 0;
          if (!custom) step = v;
          typing = false;
        });
      },
    );
    final header = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                t('Период', 'Period'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            IconButton(
              tooltip: t('Закрыть', 'Close'),
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, size: 20),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t('Длительность', 'Duration'),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  lengths,
                ],
              ),
            ),
            if (!custom && !typing) ...[
              const SizedBox(width: 10),
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t('Группа лет', 'Year group'),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    DropdownButton<int>(
                      value: block,
                      isExpanded: true,
                      underline: const SizedBox.shrink(),
                      menuMaxHeight: 300,
                      items: [
                        for (var i = 1501; i <= 2000; i += 10 * step)
                          DropdownMenuItem(value: i, child: Text(groupName(i))),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => anchorYear = v);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ],
    );
    Widget tile(int y) {
      final e = historyPeriod(y, step).$2, n = count(y, e);
      final active =
          !widget.customRange && step == widget.step && y == widget.year;
      final label = span(y, e);
      void select() => choose(y, step, false);
      return Semantics(
        key: y <= anchorYear && anchorYear <= e ? currentRow : null,
        button: true,
        selected: active,
        label: '$label · ${amount(n)}',
        onTap: select,
        excludeSemantics: true,
        child: ListTile(
          dense: true,
          minTileHeight: 46,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          tileColor: active ? colors.primaryContainer : null,
          title: Text(
            label,
            style: TextStyle(
              fontWeight: active ? FontWeight.bold : FontWeight.w500,
            ),
          ),
          trailing: Text(
            amount(n),
            style: TextStyle(
              color: n > 0 ? colors.primary : colors.onSurfaceVariant,
            ),
          ),
          onTap: select,
        ),
      );
    }

    final periodList = [
      if (nearby case final y?)
        TextButton.icon(
          icon: const Icon(Icons.event_available, size: 18),
          onPressed: () => setState(() => anchorYear = y),
          label: Text(t('К событиям $y года', 'Browse events in $y')),
        ),
      for (var y = block; y <= last; y += step) tile(y),
    ];
    final fields = <Widget>[
      if (custom)
        Row(
          children: [
            Expanded(
              child: numericField(t('С года', 'From'), from, (v) {
                from = v;
                editedRange = true;
              }),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: numericField(t('По год', 'Through'), to, (v) {
                to = v;
                editedRange = true;
              }, submit: apply),
            ),
          ],
        )
      else
        numericField(
          t('Год начала', 'Starting year'),
          exact,
          (v) => exact = v,
          submit: apply,
          autofocus: true,
        ),
      const SizedBox(height: 8),
      Text(
        dates != null
            ? '${span(dates.$1, dates.$2)} · ${amount(count(dates.$1, dates.$2))}'
            : custom &&
                  from.length == 4 &&
                  to.length == 4 &&
                  from.compareTo(to) > 0
            ? t(
                'Последний год должен быть не раньше первого',
                'End year must be on or after the start',
              )
            : t('Годы от 1501 до 2000', 'Years from 1501 to 2000'),
      ),
      Align(
        alignment: AlignmentDirectional.centerEnd,
        child: FilledButton(
          onPressed: dates == null ? null : apply,
          child: Text(custom ? t('Применить', 'Apply') : t('Перейти', 'Go')),
        ),
      ),
    ];
    final toggle = Align(
      alignment: AlignmentDirectional.centerStart,
      child: TextButton.icon(
        onPressed: () => setState(() {
          typing = !typing;
          exact = '';
        }),
        icon: Icon(typing ? Icons.list : Icons.keyboard_outlined, size: 18),
        label: Text(
          typing
              ? t('К списку дат', 'Date list')
              : t('Ввести год', 'Enter a year'),
        ),
      ),
    );
    return Material(
      color: colors.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: LayoutBuilder(
          builder: (context, box) {
            if (custom ||
                typing ||
                box.maxHeight < 265 ||
                MediaQuery.textScalerOf(context).scale(16) > 22) {
              return ListView(
                key: ValueKey((custom, typing, block, step)),
                padding: EdgeInsets.zero,
                children: [
                  header,
                  if (custom || typing) ...fields else ...periodList,
                  if (!custom) toggle,
                ],
              );
            }
            if (revealed != (anchorYear, step)) {
              revealed = (anchorYear, step);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final row = currentRow.currentContext;
                if (row != null && row.mounted) {
                  Scrollable.of(row).position.ensureVisible(
                    row.findRenderObject()!,
                    alignmentPolicy:
                        ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
                  );
                }
              });
            }
            return Column(
              children: [
                header,
                Divider(height: 1, color: colors.outlineVariant),
                Expanded(
                  child: SingleChildScrollView(
                    key: ValueKey((block, step)),
                    child: Column(children: periodList),
                  ),
                ),
                toggle,
              ],
            );
          },
        ),
      ),
    );
  }
}
