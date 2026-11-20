import 'package:flutter/material.dart';

import 'history_event_symbol.dart';
import 'history_timeline.dart';

class HistoryEventIndex extends StatefulWidget {
  const HistoryEventIndex({
    super.key,
    required this.rows,
    required this.period,
    required this.region,
    required this.russian,
    required this.countriesOf,
    required this.onOpen,
  });
  final List<Map> rows;
  final String period, region;
  final bool russian;
  final String Function(Map) countriesOf;
  final ValueChanged<Map> onOpen;

  @override
  State<HistoryEventIndex> createState() => _HistoryEventIndexState();
}

class _HistoryEventIndexState extends State<HistoryEventIndex> {
  String query = '';
  String t(String ru, String en) => widget.russian ? ru : en;

  @override
  Widget build(BuildContext context) {
    final lang = widget.russian ? 'ru' : 'en';
    String kind(Map r) {
      final style = HistoryEventStyle.forKind(r['kind']);
      return widget.russian ? style.ru : style.en;
    }

    final found = query.isEmpty
        ? widget.rows
        : widget.rows
              .where(
                (r) => [
                  r['title_$lang'],
                  r['place_$lang'],
                  widget.countriesOf(r),
                  kind(r),
                  historyEventDate(r),
                ].join(' ').toLowerCase().contains(query),
              )
              .toList();
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 580),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('${t("События", "Events")} · ${widget.period}'),
              subtitle: Text(
                widget.region,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                tooltip: t('Закрыть', 'Close'),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            if (widget.rows.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: TextField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    labelText: t(
                      'Событие, страна или тема',
                      'Event, country or topic',
                    ),
                  ),
                  onChanged: (value) =>
                      setState(() => query = value.trim().toLowerCase()),
                ),
              ),
            Flexible(
              child: found.isEmpty
                  ? SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        widget.rows.isEmpty
                            ? t(
                                'В этом периоде событий нет. Выберите другие годы или страну.',
                                'No events in this period. Choose different years or a country.',
                              )
                            : t(
                                'По этому запросу событий нет.',
                                'No matching events.',
                              ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.only(bottom: 12),
                      itemCount: found.length,
                      itemBuilder: (context, index) {
                        final r = found[index];
                        final place = r['place_$lang'] ?? widget.countriesOf(r);
                        final groupStart =
                            index == 0 ||
                            found[index - 1]['start'] != r['start'];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (groupStart)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  16,
                                  16,
                                  2,
                                ),
                                child: Text(
                                  '${r["start"]}',
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                            ListTile(
                              leading: HistoryEventSeal(r['kind'], size: 30),
                              title: Text(r['title_$lang']),
                              subtitle: Text(
                                [
                                  if (r['end'] != r['start'])
                                    historyEventDate(r),
                                  kind(r),
                                  if (place.isNotEmpty) place,
                                ].join(' · '),
                              ),
                              trailing: const Icon(
                                Icons.chevron_right,
                                size: 18,
                              ),
                              onTap: () {
                                FocusScope.of(context).unfocus();
                                widget.onOpen(r);
                              },
                            ),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
