import 'dart:convert';

import 'package:flutter/material.dart';

import '../country_labels_ru.dart';
import 'country_number_format.dart';
import 'map_state.dart';

class CountriesBrowser extends StatefulWidget {
  const CountriesBrowser({
    super.key,
    required this.countries,
    required this.onSelect,
    this.selectedId,
    this.mappedIds,
    this.flags = const {},
    this.onClose,
  });

  final List<MapCountry> countries;
  final ValueChanged<MapCountry> onSelect;
  final String? selectedId;
  final VoidCallback? onClose;
  final Set<String>? mappedIds;
  final Map<String, dynamic> flags;

  @override
  State<CountriesBrowser> createState() => _CountriesBrowserState();
}

class _CountriesBrowserState extends State<CountriesBrowser> {
  String query = '';
  bool table = false;

  @override
  Widget build(BuildContext context) {
    final ru = Localizations.localeOf(context).languageCode == 'ru';
    String tr(String en, String russian) => ru ? russian : en;
    String name(MapCountry c) => ru ? c.nameRu : c.nameEn;
    String number(num? value) => formatCountryNumber(value, russian: ru);
    String capital(MapCountry c) => c.capital == null
        ? '—'
        : ru
        ? russianCountryLabel(c.capital!)
        : c.capital!;
    final items =
        widget.countries
            .where(
              (c) => [
                c.id,
                c.nameRu,
                c.nameEn,
                c.capital ?? '',
              ].any((s) => s.toLowerCase().contains(query)),
            )
            .toList()
          ..sort((a, b) => name(a).compareTo(name(b)));
    Widget flag(MapCountry c) {
      final encoded = widget.flags[c.id];
      if (encoded is! String) return const SizedBox(width: 30);
      try {
        return Image.memory(
          base64Decode(encoded),
          width: 30,
          height: 20,
          errorBuilder: (_, _, _) => const SizedBox(width: 30),
        );
      } on FormatException {
        return const SizedBox(width: 30);
      }
    }

    Widget countryName(MapCountry c) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        flag(c),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(name(c)),
              if (widget.mappedIds != null && !widget.mappedIds!.contains(c.id))
                Text(
                  tr('Not on map', 'Нет на карте'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
        ),
      ],
    );
    return Column(
      children: [
        if (widget.onClose != null)
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              tooltip: tr('Close', 'Закрыть'),
              onPressed: widget.onClose,
              icon: const Icon(Icons.close),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: TextField(
            decoration: InputDecoration(
              labelText: tr('Search countries', 'Поиск стран'),
              prefixIcon: const Icon(Icons.search),
            ),
            onChanged: (value) =>
                setState(() => query = value.trim().toLowerCase()),
          ),
        ),
        SegmentedButton<bool>(
          segments: [
            ButtonSegment(value: false, label: Text(tr('List', 'Список'))),
            ButtonSegment(value: true, label: Text(tr('Table', 'Таблица'))),
          ],
          selected: {table},
          onSelectionChanged: (value) => setState(() => table = value.first),
        ),
        if (table)
          Text(
            tr(
              'Swipe sideways to see the table',
              'Прокрутите таблицу в сторону',
            ),
          ),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(tr('No countries found', 'Страны не найдены')),
          ),
        if (items.isNotEmpty)
          Expanded(
            child: table
                ? SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: DataTable(
                        dataRowMaxHeight: double.infinity,
                        showCheckboxColumn: false,
                        columns: [
                          DataColumn(label: Text(tr('Country', 'Страна'))),
                          DataColumn(label: Text(tr('Capital', 'Столица'))),
                          DataColumn(
                            label: Text(tr('Population', 'Население')),
                          ),
                          DataColumn(
                            label: Text(tr('Area, km²', 'Площадь, км²')),
                          ),
                        ],
                        rows: [
                          for (final c in items)
                            DataRow(
                              selected: c.id == widget.selectedId,
                              onSelectChanged: (_) => widget.onSelect(c),
                              cells: [
                                DataCell(countryName(c)),
                                DataCell(Text(capital(c))),
                                DataCell(Text(number(c.population))),
                                DataCell(Text(number(c.area))),
                              ],
                            ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final c = items[index];
                      return ListTile(
                        selected: c.id == widget.selectedId,
                        title: countryName(c),
                        subtitle: Text(
                          '${tr('Capital', 'Столица')}: ${capital(c)} · ${tr('Population', 'Население')}: ${number(c.population)} · ${tr('Area, km²', 'Площадь, км²')}: ${number(c.area)}',
                        ),
                        onTap: () => widget.onSelect(c),
                      );
                    },
                  ),
          ),
      ],
    );
  }
}
