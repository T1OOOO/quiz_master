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
            height: MediaQuery.textScalerOf(context).scale(180),
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
                    width: 164 * _scale,
                    child: InkWell(
                      key: Key('chronology-entry-${entry.id}'),
                      onTap: () => widget.onSelected(entry.id),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: Text(
                                entry.date,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: colors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(child: Divider(color: colors.primary)),
                                Icon(
                                  selected
                                      ? Icons.radio_button_checked
                                      : Icons.circle,
                                  size: selected ? 20 : 12,
                                  color: colors.primary,
                                ),
                                Expanded(child: Divider(color: colors.primary)),
                              ],
                            ),
                            Flexible(child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text(
                                entry.title,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            )),
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
