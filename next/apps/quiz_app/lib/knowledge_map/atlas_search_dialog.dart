import 'package:flutter/material.dart';

class AtlasSearchEntry {
  const AtlasSearchEntry({
    required this.kind,
    required this.id,
    required this.name,
    required this.detail,
  });
  final String kind, id, name, detail;
}

Future<AtlasSearchEntry?> showAtlasSearch(
  BuildContext context, {
  required List<AtlasSearchEntry> entries,
  required bool russian,
}) => showDialog<AtlasSearchEntry>(
  context: context,
  builder: (context) => _AtlasSearchDialog(entries: entries, russian: russian),
);

class _AtlasSearchDialog extends StatefulWidget {
  const _AtlasSearchDialog({required this.entries, required this.russian});
  final List<AtlasSearchEntry> entries;
  final bool russian;
  @override
  State<_AtlasSearchDialog> createState() => _AtlasSearchDialogState();
}

class _AtlasSearchDialogState extends State<_AtlasSearchDialog> {
  String query = '';
  @override
  Widget build(BuildContext context) {
    String normalize(String value) =>
        value.trim().toLowerCase().replaceAll('ё', 'е');
    final needle = normalize(query);
    int rank(AtlasSearchEntry entry) {
      final name = normalize(entry.name);
      if (name == needle) return 0;
      if (name.startsWith(needle)) return 1;
      if (name.contains(needle)) return 2;
      return 3;
    }

    final results = needle.isEmpty
        ? <AtlasSearchEntry>[]
        : (widget.entries
              .where(
                (entry) =>
                    normalize(entry.name).contains(needle) ||
                    normalize(entry.detail).contains(needle),
              )
              .toList()
            ..sort((a, b) {
              final order = rank(a).compareTo(rank(b));
              return order != 0
                  ? order
                  : normalize(a.name).compareTo(normalize(b.name));
            }));
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: Text(
                      widget.russian ? 'Поиск на карте' : 'Search the map',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: widget.russian ? 'Закрыть' : 'Close',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                autofocus: true,
                onChanged: (value) => setState(() => query = value),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: widget.russian
                      ? 'Страна, столица, место'
                      : 'Country, capital, place',
                ),
              ),
            ),
            Flexible(
              child: results.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        needle.isEmpty
                            ? (widget.russian
                                  ? 'Начните вводить название'
                                  : 'Start typing a name')
                            : (widget.russian
                                  ? 'Ничего не найдено'
                                  : 'No results found'),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: results.length > 80 ? 80 : results.length,
                      itemBuilder: (context, index) {
                        final entry = results[index];
                        final (icon, color) = switch (entry.kind) {
                          'country' => (Icons.public, const Color(0xff165b64)),
                          'capital' => (
                            Icons.location_city,
                            const Color(0xff265d80),
                          ),
                          _ => (Icons.place_outlined, const Color(0xffa56b25)),
                        };
                        return ListTile(
                          leading: Icon(icon, color: color),
                          title: Text(entry.name),
                          subtitle: Text(entry.detail),
                          onTap: () => Navigator.pop(context, entry),
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
