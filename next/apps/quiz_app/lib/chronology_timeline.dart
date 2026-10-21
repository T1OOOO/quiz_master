import 'package:flutter/material.dart';

class ChronologyEntry {
  const ChronologyEntry({
    required this.id,
    required this.year,
    required this.date,
    required this.title,
  });
  final String id, date, title;
  final int year;
}

/// Dates remain explicit: equal card spacing represents order, not elapsed time.
class ChronologyTimeline extends StatefulWidget {
  const ChronologyTimeline({
    super.key,
    required this.entries,
    required this.onSelected,
    this.selectedId,
  });
  final List<ChronologyEntry> entries;
  final ValueChanged<String> onSelected;
  final String? selectedId;
  @override
  State<ChronologyTimeline> createState() => _ChronologyTimelineState();
}

class _ChronologyTimelineState extends State<ChronologyTimeline> {
  final _scroll = ScrollController();
  double _scale = 1;
  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entries = [...widget.entries]
      ..sort((a, b) => a.year.compareTo(b.year));
    final colors = Theme.of(context).colorScheme;
    final textScaler = MediaQuery.textScalerOf(context);
    final textStyle = DefaultTextStyle.of(context).style;
    final dateStyle = textStyle.copyWith(
      color: colors.primary,
      fontWeight: FontWeight.bold,
    );
    final entryWidth = 164 * _scale;
    double heightOf(String text, TextStyle style, {int? maxLines}) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: Directionality.of(context),
        textScaler: textScaler,
        locale: Localizations.maybeLocaleOf(context),
        maxLines: maxLines,
        ellipsis: maxLines == null ? null : '…',
      )..layout(maxWidth: entryWidth - 16);
      final height = painter.height;
      painter.dispose();
      return height;
    }

    double dateHeight = 0;
    double titleHeight = 0;
    for (final entry in entries) {
      final date = heightOf(entry.date, dateStyle);
      final title = heightOf(entry.title, textStyle, maxLines: 3);
      if (date > dateHeight) dateHeight = date;
      if (title > titleHeight) titleHeight = title;
    }
    final contentHeight = 24 + dateHeight + 10 + 20 + 16 + titleHeight;
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Линия времени',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  tooltip: 'Уменьшить шкалу',
                  onPressed: _scale > .8
                      ? () =>
                            setState(() => _scale = (_scale - .2).clamp(.8, 2))
                      : null,
                  icon: const Icon(Icons.remove),
                ),
                IconButton(
                  tooltip: 'Увеличить шкалу',
                  onPressed: _scale < 2
                      ? () =>
                            setState(() => _scale = (_scale + .2).clamp(.8, 2))
                      : null,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'Листайте по горизонтали и выбирайте события. Интервалы между датами сжаты.',
              style: TextStyle(fontSize: 12),
            ),
          ),
          SizedBox(
            height: contentHeight > textScaler.scale(180)
                ? contentHeight
                : textScaler.scale(180),
            child: Scrollbar(
              controller: _scroll,
              child: ListView.builder(
                key: const Key('chronology-timeline'),
                controller: _scroll,
                scrollDirection: Axis.horizontal,
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  final selected = widget.selectedId == entry.id;
                  return SizedBox(
                    width: entryWidth,
                    child: InkWell(
                      key: Key('chronology-entry-${entry.id}'),
                      onTap: () => widget.onSelected(entry.id),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Column(
                          children: [
                            SizedBox(
                              height: dateHeight,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                child: Align(
                                  alignment: Alignment.bottomCenter,
                                  child: Text(
                                    entry.date,
                                    textAlign: TextAlign.center,
                                    style: dateStyle,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 20,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Divider(color: colors.primary),
                                  ),
                                  Icon(
                                    selected
                                        ? Icons.radio_button_checked
                                        : Icons.circle,
                                    size: selected ? 20 : 12,
                                    color: colors.primary,
                                  ),
                                  Expanded(
                                    child: Divider(color: colors.primary),
                                  ),
                                ],
                              ),
                            ),
                            Flexible(
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text(
                                  entry.title,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          if (entries.isEmpty)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('В этом периоде пока нет событий. Измените фильтр.'),
            ),
        ],
      ),
    );
  }
}
