import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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
    required this.onRead,
    required this.onClose,
    required this.detail,
    required this.onMap,
    required this.year,
    required this.nearby,
  });
  final List<Map> rows;
  final String period, region;
  final bool russian, nearby;
  final int year;
  final Map? detail;
  final String Function(Map) countriesOf;
  final ValueChanged<Map?> onRead;
  final VoidCallback onClose;
  final void Function(Map, bool) onMap;
  @override
  State<HistoryEventIndex> createState() => _HistoryEventIndexState();
}

class _HistoryEventIndexState extends State<HistoryEventIndex> {
  String query = '';
  bool searching = false;
  final searchText = TextEditingController();
  final searchFocus = FocusNode();

  @override
  void dispose() {
    searchText.dispose();
    searchFocus.dispose();
    super.dispose();
  }

  String t(String ru, String en) => widget.russian ? ru : en;
  String get lang => widget.russian ? 'ru' : 'en';
  String kind(Map r) {
    final style = HistoryEventStyle.forKind(r['kind']);
    return widget.russian ? style.ru : style.en;
  }

  String place(Map r) => r['place_$lang'] ?? widget.countriesOf(r);
  @override
  Widget build(BuildContext context) {
    final entry = widget.detail;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final paper = dark ? const Color(0xff202c2a) : const Color(0xfffffcf3);
    final ink = dark ? const Color(0xfff4eee0) : const Color(0xff203b35);
    final rule = dark ? const Color(0xff56645e) : const Color(0xffd7d9c7);
    final title = widget.nearby
        ? t('События рядом', 'Nearby events')
        : t('События', 'Events');
    final found = widget.rows
        .where(
          (r) =>
              query.isEmpty ||
              [
                r['title_$lang'],
                place(r),
                widget.countriesOf(r),
                kind(r),
                historyEventDate(r),
              ].join(' ').toLowerCase().contains(query),
        )
        .toList();
    final header = Material(
      color: const Color(0xff23473e),
      textStyle: const TextStyle(color: Colors.white),
      child: IconTheme(
        data: const IconThemeData(color: Colors.white),
        child: Row(
          children: [
            if (entry != null)
              IconButton(
                color: Colors.white,
                tooltip: t('К списку событий', 'Back to events'),
                onPressed: () => widget.onRead(null),
                icon: const Icon(Icons.arrow_back),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$title · ${widget.period}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      widget.region,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xffdbebdf),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            if (entry == null && widget.rows.isNotEmpty)
              IconButton(
                color: Colors.white,
                tooltip: t('Поиск событий', 'Search events'),
                onPressed: () => setState(() {
                  searching = !searching;
                  query = '';
                  searchText.clear();
                  if (searching) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted && searching && widget.detail == null)
                        searchFocus.requestFocus();
                    });
                  }
                }),
                icon: Icon(searching ? Icons.search_off : Icons.search),
              ),
            IconButton(
              tooltip: t('Закрыть', 'Close'),
              color: Colors.white,
              onPressed: widget.onClose,
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      ),
    );
    final list = ListView(
      key: PageStorageKey((
        'events',
        widget.period,
        widget.region,
        widget.nearby,
      )),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      children: [
        if (searching)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: TextField(
              controller: searchText,
              focusNode: searchFocus,
              decoration: InputDecoration(
                hintText: t(
                  'Событие, страна или тема',
                  'Event, country or topic',
                ),
              ),
              onChanged: (v) => setState(() => query = v.trim().toLowerCase()),
            ),
          ),

        if (found.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text(
              query.isEmpty
                  ? t(
                      'За этот период событий нет. Выберите другие годы или страну.',
                      'No events in this period. Choose other years or a country.',
                    )
                  : t('По этому запросу событий нет.', 'No matching events.'),
            ),
          ),
        for (var i = 0; i < found.length; i++) ...[
          if (i == 0 || found[i - 1]['start'] != found[i]['start'])
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                '${found[i]["start"]}',
                style: TextStyle(
                  color: ink,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: HistoryEventSeal(found[i]['kind'], size: 28),
            title: Text(
              found[i]['title_$lang'],
              style: TextStyle(
                color: ink,
                fontSize: 17,
                fontFamily: 'serif',
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              [
                if (found[i]['start'] != found[i]['end'])
                  historyEventDate(found[i]),
                kind(found[i]),
                if (place(found[i]).isNotEmpty) place(found[i]),
              ].join(' · '),
            ),
            trailing: const Icon(Icons.chevron_right, size: 18),
            onTap: () {
              FocusScope.of(context).unfocus();
              widget.onRead(found[i]);
            },
          ),
          Divider(height: 1, color: rule),
        ],
      ],
    );
    return Material(
      color: paper,
      child: Column(
        children: [
          header,
          Expanded(
            child: entry == null
                ? list
                : ListView(
                    key: ValueKey(entry),
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                    children: [
                      Row(
                        children: [
                          HistoryEventSeal(entry['kind'], size: 27),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${historyEventDate(entry)} · ${kind(entry)}',
                              style: TextStyle(
                                color: ink,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          entry['title_$lang'],
                          style: TextStyle(
                            color: ink,
                            fontFamily: 'serif',
                            fontSize: 23,
                            height: 1.15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        entry['summary_$lang'],
                        style: TextStyle(
                          color: ink,
                          fontSize: 16,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        [
                          if (entry['place_$lang'] != null)
                            entry['place_$lang'],
                          if (entry['location'] == null)
                            t('Регион события', 'Event region'),
                          if (widget.countriesOf(entry).isNotEmpty)
                            widget.countriesOf(entry),
                        ].join(' · '),
                      ),
                      Wrap(
                        spacing: 8,
                        children: [
                          FilledButton.tonalIcon(
                            icon: const Icon(Icons.place_outlined, size: 18),
                            onPressed: () => widget.onMap(entry, false),
                            label: Text(t('На карте', 'Show on map')),
                          ),
                          TextButton.icon(
                            icon: const Icon(Icons.open_in_new, size: 16),
                            onPressed: () => launchUrl(
                              Uri.parse(entry['source_url']),
                              mode: LaunchMode.externalApplication,
                            ),
                            label: Text(t('Источник', 'Source')),
                          ),
                          if (widget.year < entry['start'] ||
                              widget.year > entry['end'])
                            TextButton(
                              onPressed: () => widget.onMap(entry, true),
                              child: Text(
                                t(
                                  'Перейти к ${entry["start"]} году',
                                  'Go to ${entry["start"]}',
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
