import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:url_launcher/url_launcher.dart';

import 'country_number_format.dart';
import 'map_state.dart';

Future<String?> showCountryConnections(
  BuildContext context, {
  required MapCountry country,
  required List<MapCountry> countries,
  required Map borders,
  required Map waters,
  required bool russian,
}) => showDialog<String>(
  context: context,
  builder: (context) => _Connections(
    country: country,
    catalog: {for (final entry in countries) entry.id: entry},
    borders: borders,
    waters: waters,
    ru: russian,
  ),
);

class _Connections extends StatelessWidget {
  const _Connections({
    required this.country,
    required this.catalog,
    required this.borders,
    required this.waters,
    required this.ru,
  });

  final MapCountry country;
  final Map<String, MapCountry> catalog;
  final Map borders, waters;
  final bool ru;

  String tr(String en, String russian) => ru ? russian : en;
  String name(MapCountry row) => ru ? row.nameRu : row.nameEn;
  List<Map> waterRows(String id) => (waters[id] as List? ?? const [])
      .whereType<Map>()
      .where((row) => row['id'] is String && row['id'] != '')
      .toList();
  Map border(String id) =>
      (borders['countries'] as Map?)?[id] as Map? ?? const {};
  Map<String, num> distances(String id) {
    final totals = <String, num>{};
    for (final pair
        in (border(id)['pairs'] as List? ?? const []).whereType<Map>()) {
      final neighbour = pair['country_id'];
      final length = pair['length_km'];
      if (neighbour is String && length is num) {
        totals.update(neighbour, (n) => n + length, ifAbsent: () => length);
      }
    }
    return totals;
  }

  String km(num n) {
    final fmt = NumberFormat.decimalPattern(ru ? 'ru' : 'en')
      ..maximumFractionDigits = n < 10 ? 1 : 0;
    return '${fmt.format(n)} ${tr('km', 'км')}';
  }

  String waterName(Map row) =>
      (row[ru ? 'name_ru' : 'name_en'] ?? row['name_en'] ?? row['id'])
          .toString();
  String waterKind(Map row) => switch (row['relation']) {
    'flows' => tr('River', 'Река'),
    'coast' => tr('Coastal waters', 'Омывает берега'),
    'border' => tr('Boundary waters', 'Пограничный водоём'),
    _ => tr('Inland waters', 'Внутренние воды'),
  };

  Widget neighbour(
    BuildContext context,
    MapCountry other,
    Map<String, num> lengths,
    List<Map> localWaters,
  ) {
    final estimates = {
      if (lengths[other.id] != null) lengths[other.id]!,
      if (distances(other.id)[country.id] != null)
        distances(other.id)[country.id]!,
    }.toList()..sort();
    final commonIds = waterRows(other.id).map((r) => r['id']).toSet();
    final shared = localWaters
        .where((r) => commonIds.contains(r['id']))
        .toList();
    final area = other.area;
    final distance = estimates.isEmpty
        ? tr('Length unavailable', 'Нет данных о длине')
        : km(estimates.first) == km(estimates.last)
        ? '≈ ${km(estimates.first)}'
        : '${km(estimates.first)} – ${km(estimates.last)}';
    return ExpansionTile(
      key: PageStorageKey('${country.id}-${other.id}'),
      tilePadding: const EdgeInsets.symmetric(horizontal: 4),
      title: Text(
        name(other),
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text('${tr('Shared border', 'Общая граница')} · $distance'),
      expandedAlignment: Alignment.centerLeft,
      childrenPadding: const EdgeInsets.fromLTRB(12, 0, 8, 12),
      children: [
        if (area != null)
          Text(
            '${tr('Country area', 'Площадь страны')} · ${formatCountryNumber(area, russian: ru)} ${tr('km²', 'км²')}',
          ),
        const SizedBox(height: 6),
        if (shared.isEmpty)
          Text(
            tr(
              'No shared waters listed in the atlas',
              'В атласе пока нет сведений об общих водах',
            ),
          )
        else ...[
          Text(
            tr('Waters in both countries', 'Общие воды'),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          for (final row in shared)
            Text('${waterName(row)} · ${waterKind(row)}'),
        ],
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => Navigator.pop(context, other.id),
            icon: const Icon(Icons.location_on_outlined, size: 17),
            label: Text(tr('Show on map', 'Показать на карте')),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final lengths = distances(country.id);
    final ids = country.neighbors.toSet();
    final neighbours = catalog.values.where((c) => ids.contains(c.id)).toList()
      ..sort((a, b) => name(a).compareTo(name(b)));
    final rows = waterRows(country.id)
      ..sort((a, b) => waterName(a).compareTo(waterName(b)));
    final info = border(country.id);
    final total = info['total_km'];
    final metadata = borders['source'] as Map? ?? const {};
    final ref = metadata['commit'];
    final file = info['source_file'];
    final size = MediaQuery.sizeOf(context);
    final theme = Theme.of(context);
    return PointerInterceptor(
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          width: 560,
          height: (size.height * .8).clamp(200.0, 620.0),
          child: DefaultTabController(
            length: 2,
            child: Column(
              children: [
                Container(
                  color: const Color(0xff165b60),
                  padding: const EdgeInsets.fromLTRB(18, 12, 6, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name(country),
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              tr('Borders and waters', 'Границы и воды'),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: tr('Close', 'Закрыть'),
                        color: Colors.white,
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                TabBar(
                  tabs: [
                    Tab(
                      text:
                          '${tr('Neighbours', 'Соседи')} · ${neighbours.length}',
                    ),
                    Tab(text: tr('Waters', 'Воды')),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      ListView(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                        children: [
                          if (total is num)
                            Text(
                              '${tr('Land boundaries in total', 'Сухопутные границы всего')} · ${total == 0 ? '' : '≈ '}${km(total)}',
                              style: theme.textTheme.titleSmall,
                            ),
                          if (info['components_km'] case final Map components)
                            for (final entry in components.entries.where(
                              (e) => e.value is num,
                            ))
                              Text(
                                '${switch (entry.key) {
                                  'metropolitan France' => tr('Metropolitan France', 'Европейская часть Франции'),
                                  'French Guiana' => tr('French Guiana', 'Французская Гвиана'),
                                  _ => entry.key,
                                }} · ${km(entry.value as num)}',
                              ),
                          if (country.area != null)
                            Text(
                              '${tr('Area', 'Площадь')} · ${formatCountryNumber(country.area, russian: ru)} ${tr('km²', 'км²')}',
                            ),
                          if (ref is String && file is String)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                onPressed: () => launchUrl(
                                  Uri.https(
                                    'github.com',
                                    '/factbook/factbook.json/blob/$ref/$file',
                                  ),
                                  mode: LaunchMode.externalApplication,
                                ),
                                icon: const Icon(Icons.open_in_new, size: 14),
                                label: Text(
                                  tr(
                                    'Source of lengths · World Factbook',
                                    'Источник длин границ · World Factbook',
                                  ),
                                ),
                              ),
                            ),
                          if (neighbours.isEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(
                                total == 0
                                    ? tr(
                                        'No land neighbours',
                                        'Нет сухопутных соседей',
                                      )
                                    : tr(
                                        'No land neighbours listed in the atlas',
                                        'В атласе нет данных о сухопутных соседях',
                                      ),
                              ),
                            ),
                          for (final other in neighbours)
                            neighbour(context, other, lengths, rows),
                        ],
                      ),
                      ListView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        children: [
                          if (rows.isEmpty)
                            Text(
                              tr(
                                'No bodies of water listed yet',
                                'Данных о водоёмах пока нет',
                              ),
                            ),
                          for (final row in rows)
                            Builder(
                              builder: (context) {
                                final linked =
                                    catalog.values
                                        .where(
                                          (c) =>
                                              c.id != country.id &&
                                              waterRows(c.id).any(
                                                (w) => w['id'] == row['id'],
                                              ),
                                        )
                                        .toList()
                                      ..sort(
                                        (a, b) => name(a).compareTo(name(b)),
                                      );
                                return ExpansionTile(
                                  tilePadding: EdgeInsets.zero,
                                  leading: const Icon(
                                    Icons.water_outlined,
                                    color: Color(0xff227791),
                                  ),
                                  title: Text(waterName(row)),
                                  subtitle: Text(waterKind(row)),
                                  expandedAlignment: Alignment.centerLeft,
                                  childrenPadding: const EdgeInsets.fromLTRB(
                                    8,
                                    0,
                                    8,
                                    12,
                                  ),
                                  children: [
                                    Text(
                                      linked.isEmpty
                                          ? tr(
                                              'No other country listed for these waters',
                                              'Другие страны для этого водоёма пока не указаны',
                                            )
                                          : '${tr('Also listed for', 'Также в атласе у стран')} · ${linked.map(name).join(', ')}',
                                    ),
                                  ],
                                );
                              },
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
