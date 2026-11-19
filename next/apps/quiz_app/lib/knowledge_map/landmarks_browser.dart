import 'package:flutter/material.dart';

String placeCategory(List categories) {
  for (final category in ['mountains', 'depressions', 'deserts', 'reserves']) {
    if (categories.contains(category)) return category;
  }
  return categories.any((item) => item is String && item.endsWith('_wonders'))
      ? 'wonders'
      : 'landmark';
}

Color placeCategoryColor(String category) => switch (category) {
  'mountains' => const Color(0xff7253ad),
  'depressions' => const Color(0xff397ab0),
  'deserts' => const Color(0xffcc8220),
  'reserves' => const Color(0xff258054),
  'wonders' => const Color(0xffbf4672),
  _ => const Color(0xff247a83),
};

IconData placeCategoryIcon(String category) => switch (category) {
  'mountains' => Icons.terrain,
  'depressions' => Icons.south,
  'deserts' => Icons.wb_sunny_outlined,
  'reserves' => Icons.park_outlined,
  'wonders' => Icons.star,
  _ => Icons.place_outlined,
};

class LandmarksBrowser extends StatefulWidget {
  const LandmarksBrowser({
    super.key,
    required this.features,
    required this.category,
    required this.russian,
    required this.onCategory,
    required this.onSelect,
    required this.onClose,
  });

  final List<dynamic> features;
  final String category;
  final bool russian;
  final ValueChanged<String> onCategory;
  final ValueChanged<String> onSelect;
  final VoidCallback onClose;

  @override
  State<LandmarksBrowser> createState() => _LandmarksBrowserState();
}

class _LandmarksBrowserState extends State<LandmarksBrowser> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final features = widget.features;
    final category = widget.category;
    final russian = widget.russian;
    String tr(String en, String ru) => russian ? ru : en;
    final places =
        features.where((feature) {
          final properties = feature['properties'] as Map;
          final matchesCategory =
              category == 'all' ||
              (properties['categories'] as List? ?? const []).contains(
                category,
              );
          return matchesCategory &&
              ['name_ru', 'name_en', 'city_ru', 'city_en'].any(
                (key) => (properties[key] as String? ?? '')
                    .toLowerCase()
                    .contains(query),
              );
        }).toList()..sort(
          (a, b) => (a['properties'][russian ? 'name_ru' : 'name_en'] as String)
              .compareTo(
                b['properties'][russian ? 'name_ru' : 'name_en'] as String,
              ),
        );
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          ListTile(
            title: Text(tr('Places', 'Достопримечательности')),
            trailing: IconButton(
              tooltip: tr('Close places', 'Закрыть места'),
              onPressed: widget.onClose,
              icon: const Icon(Icons.close),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              decoration: InputDecoration(
                labelText: tr('Search places', 'Поиск мест'),
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: (value) =>
                  setState(() => query = value.trim().toLowerCase()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButton<String>(
              value: category,
              isExpanded: true,
              items: [
                for (final item in [
                  ('all', tr('All places', 'Все места'), 'landmark'),
                  ('new_wonders', tr('New wonders', 'Новые чудеса'), 'wonders'),
                  (
                    'ancient_wonders',
                    tr('Ancient wonders', 'Античные чудеса'),
                    'wonders',
                  ),
                  (
                    'nature_wonders',
                    tr('Nature wonders', 'Чудеса природы'),
                    'wonders',
                  ),
                  ('mountains', tr('Mountains', 'Горы'), 'mountains'),
                  ('depressions', tr('Depressions', 'Впадины'), 'depressions'),
                  ('deserts', tr('Deserts', 'Пустыни'), 'deserts'),
                  ('reserves', tr('Reserves', 'Заповедники'), 'reserves'),
                ])
                  DropdownMenuItem(
                    value: item.$1,
                    child: Row(
                      children: [
                        Icon(
                          placeCategoryIcon(item.$3),
                          color: placeCategoryColor(item.$3),
                        ),
                        const SizedBox(width: 8),
                        Text(item.$2),
                      ],
                    ),
                  ),
              ],
              onChanged: (value) {
                if (value != null) widget.onCategory(value);
              },
            ),
          ),
          Expanded(
            child: places.isEmpty
                ? Center(
                    child: Text(
                      query.isNotEmpty
                          ? tr('No matching places', 'Места не найдены')
                          : tr(
                              'No places in this collection',
                              'В этой подборке пока нет мест',
                            ),
                    ),
                  )
                : ListView.builder(
                    itemCount: places.length,
                    itemBuilder: (context, index) {
                      final p = places[index]['properties'] as Map;
                      final categories = p['categories'] as List? ?? const [];
                      final kind = placeCategory(categories);
                      return ExpansionTile(
                        key: ValueKey(p['id'] as String),
                        leading: Icon(
                          placeCategoryIcon(kind),
                          color: placeCategoryColor(kind),
                        ),
                        title: Text(
                          p[russian ? 'name_ru' : 'name_en'] as String,
                        ),
                        subtitle: Text(
                          p[russian ? 'city_ru' : 'city_en'] as String? ?? '',
                        ),
                        childrenPadding: const EdgeInsets.fromLTRB(
                          16,
                          0,
                          16,
                          8,
                        ),
                        expandedCrossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (p[russian ? 'explanation_ru' : 'explanation_en']
                              is String)
                            Text(
                              p[russian ? 'explanation_ru' : 'explanation_en']
                                  as String,
                            ),
                          TextButton.icon(
                            onPressed: () => widget.onSelect(p['id'] as String),
                            icon: const Icon(Icons.map_outlined),
                            label: Text(tr('Show on map', 'Показать на карте')),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
