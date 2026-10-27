/// A finite, source-linked guide to major vessels, not a complete vessel list.
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'fact_practice.dart';
import 'fact_practice_models.dart';
import 'anatomy_scene.dart';

const vascularAtlasAsset = 'assets/quizipedia/vascular_atlas.json';

class VascularSource {
  const VascularSource(this.id, this.title, this.url);
  final String id, title, url;
  factory VascularSource.fromJson(Map<String, dynamic> row) {
    final url = _string(row, 'url');
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      throw const FormatException('Vessel source must use HTTPS');
    }
    return VascularSource(_string(row, 'id'), _string(row, 'title'), url);
  }
}

class VascularRecord {
  const VascularRecord({
    required this.id,
    required this.nameRu,
    required this.nameEn,
    required this.vascularClass,
    required this.circuits,
    required this.region,
    required this.positionRu,
    required this.functionRu,
    required this.factRu,
    required this.sourceIds,
  });
  final String id,
      nameRu,
      nameEn,
      vascularClass,
      region,
      positionRu,
      functionRu,
      factRu;
  final List<String> circuits, sourceIds;
  factory VascularRecord.fromJson(Map<String, dynamic> row) {
    final facts = row['facts'];
    if (facts is! List || facts.isEmpty || facts.first is! Map) {
      throw const FormatException('Vessel fact is required');
    }
    final fact = Map<String, dynamic>.from(facts.first as Map);
    final classes = _strings(row['circuits']);
    final vascularClass = _string(row, 'vascular_class');
    if (!{'artery', 'vein'}.contains(vascularClass) ||
        classes.any((item) => !_circuits.contains(item))) {
      throw const FormatException('Vessel taxonomy is required');
    }
    final region = _string(row, 'region');
    if (!_regions.contains(region)) {
      throw const FormatException('Vessel body region is required');
    }
    return VascularRecord(
      id: _string(row, 'id'),
      nameRu: _string(row, 'name_ru'),
      nameEn: _string(row, 'name_en'),
      vascularClass: vascularClass,
      circuits: classes,
      region: region,
      positionRu: _string(row, 'position_ru'),
      functionRu: _string(row, 'function_ru'),
      factRu: _string(fact, 'text_ru'),
      sourceIds: _strings(row['source_ids']),
    );
  }
}

class VascularAtlas {
  const VascularAtlas({required this.records, required this.sources});
  final List<VascularRecord> records;
  final Map<String, VascularSource> sources;
  factory VascularAtlas.fromJson(Object? value) {
    if (value is! Map) {
      throw const FormatException('Vascular atlas object required');
    }
    final row = Map<String, dynamic>.from(value);
    if (row['schema_version'] != 'qm-organ-atlas/v1') {
      throw const FormatException('Unsupported vascular atlas');
    }
    final organs = row['organs'];
    if (organs is! List || organs.isEmpty) {
      throw const FormatException('Vessel records required');
    }
    final records = organs
        .map(
          (item) =>
              VascularRecord.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList(growable: false);
    if (records.map((item) => item.id).toSet().length != records.length) {
      throw const FormatException('Duplicate vessel ID');
    }
    final sourceRows = row['sources'];
    if (sourceRows is! List || sourceRows.isEmpty) {
      throw const FormatException('Vessel sources required');
    }
    final sources = <String, VascularSource>{};
    for (final item in sourceRows) {
      final source = VascularSource.fromJson(
        Map<String, dynamic>.from(item as Map),
      );
      if (sources.containsKey(source.id)) {
        throw const FormatException('Duplicate vessel source ID');
      }
      sources[source.id] = source;
    }
    for (final record in records) {
      if (record.sourceIds.any((id) => !sources.containsKey(id))) {
        throw const FormatException('Vessel source reference is unresolved');
      }
    }
    return VascularAtlas(records: records, sources: sources);
  }
}

Future<VascularAtlas> loadVascularAtlas([AssetBundle? bundle]) async =>
    VascularAtlas.fromJson(
      jsonDecode(await (bundle ?? rootBundle).loadString(vascularAtlasAsset)),
    );

List<StudyFact> vascularStudyFacts(
  Iterable<VascularRecord> records, [
  Map<String, VascularSource> sources = const {},
]) => [
  for (final record in records) ...[
    _fact(record, sources, 'position', 'Расположение', record.positionRu),
    _fact(record, sources, 'function', 'Роль', record.functionRu),
    _fact(record, sources, 'fact', 'Факт', record.factRu),
  ],
];

StudyFact _fact(
  VascularRecord record,
  Map<String, VascularSource> sources,
  String field,
  String label,
  String value,
) => StudyFact(
  id: 'vascular:${record.id}:$field',
  scope: 'vascular',
  entityId: record.id,
  nameRu: record.nameRu,
  nameEn: record.nameEn,
  fieldPath: field,
  fieldRu: label,
  fieldEn: label,
  valueRu: value,
  valueEn: value,
  sources: [
    for (final id in record.sourceIds)
      if (sources[id] case final source?)
        FactSource(
          titleRu: source.title,
          titleEn: source.title,
          url: source.url,
        ),
  ],
);

class VascularAtlasPage extends StatefulWidget {
  const VascularAtlasPage({super.key, this.bundle, this.training = false});
  final AssetBundle? bundle;
  final bool training;
  @override
  State<VascularAtlasPage> createState() => _VascularAtlasPageState();
}

class _VascularAtlasPageState extends State<VascularAtlasPage> {
  late final Future<VascularAtlas> _future = loadVascularAtlas(widget.bundle);
  final _search = TextEditingController();
  String? _classFilter, _circuitFilter, _regionFilter;
  VascularRecord? _selected;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Основные сосуды')),
    body: FutureBuilder<VascularAtlas>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text('Не удалось загрузить атлас сосудов.'),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final atlas = snapshot.data!;
        final query = _search.text.trim().toLowerCase();
        final records = atlas.records.where((record) {
          return (_classFilter == null ||
                  record.vascularClass == _classFilter) &&
              (_circuitFilter == null ||
                  record.circuits.contains(_circuitFilter)) &&
              (_regionFilter == null || _regionFilter == record.region) &&
              '${record.nameRu} ${record.nameEn}'.toLowerCase().contains(query);
        }).toList();
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Учебный маршрут из ${atlas.records.length} крупных сосудов, не полный перечень сосудов человека.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 12),
            Text(
              'Выберите область; схема упрощена и не задаёт точные точки сосудов.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            AnatomyScene(
              asset: 'assets/quizipedia/vascular-display.png',
              aspectRatio: 500 / 1107,
              markers: const [
                AnatomySceneMarker(id: 'neck', label: 'Шея', x: .55, y: .17),
                AnatomySceneMarker(
                  id: 'thorax',
                  label: 'Грудная клетка',
                  x: .55,
                  y: .28,
                ),
                AnatomySceneMarker(
                  id: 'abdomen',
                  label: 'Живот',
                  x: .56,
                  y: .39,
                ),
                AnatomySceneMarker(id: 'pelvis', label: 'Таз', x: .56, y: .48),
                AnatomySceneMarker(
                  id: 'lower_limb',
                  label: 'Ноги',
                  x: .47,
                  y: .68,
                ),
              ],
              credit: const AnatomySceneCredit(
                author: 'LadyofHats',
                license: 'Public domain',
                source: 'https://commons.wikimedia.org/wiki/File:Circulatory_System_no_tags.svg',
              ),
              onMarkerTap: (marker) =>
                  setState(() => _regionFilter = marker.id),
              zoomInLabel: 'Увеличить',
              zoomOutLabel: 'Уменьшить',
              resetLabel: 'Вся схема',
              creditLabel: 'Источник изображения',
              hideMarkersLabel: 'Скрыть метки',
              showMarkersLabel: 'Показать метки',
            ),
            if (_regionFilter != null)
              TextButton.icon(
                key: const Key('vascular-region-reset'),
                onPressed: () => setState(() => _regionFilter = null),
                icon: const Icon(Icons.clear),
                label: const Text('Показать все области'),
              ),
            const SizedBox(height: 12),
            _RouteDiagram(
              onNode: (vascularClass, circuit) => setState(() {
                _classFilter = vascularClass;
                _circuitFilter = circuit;
              }),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('vascular-search'),
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Найти сосуд',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 12),
            _FilterChips(
              label: 'Тип',
              values: const {'artery': 'Артерии', 'vein': 'Вены'},
              selected: _classFilter,
              onSelected: (value) => setState(() => _classFilter = value),
            ),
            const SizedBox(height: 8),
            _FilterChips(
              label: 'Маршрут',
              values: const {
                'systemic': 'Большой круг',
                'pulmonary': 'Малый круг',
                'portal': 'Воротная система',
              },
              selected: _circuitFilter,
              onSelected: (value) => setState(() => _circuitFilter = value),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              key: const Key('vascular-practice'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => FactPracticePage(
                    scope: 'vascular',
                    facts: vascularStudyFacts(atlas.records, atlas.sources),
                    entityIds: records.map((record) => record.id).toSet(),
                  ),
                ),
              ),
              icon: const Icon(Icons.fact_check_outlined),
              label: Text('Тренировка · сосудов: ${records.length}'),
            ),
            const SizedBox(height: 8),
            Text('Найдено: ${records.length}'),
            for (final record in records)
              Card(
                child: ListTile(
                  key: Key('vascular-${record.id}'),
                  leading: Icon(
                    record.vascularClass == 'artery'
                        ? Icons.arrow_outward
                        : Icons.arrow_back,
                    color: record.vascularClass == 'artery'
                        ? Colors.red.shade700
                        : Colors.blue.shade700,
                  ),
                  title: Text(record.nameRu),
                  subtitle: Text(
                    '${_classLabel(record.vascularClass)} · ${record.circuits.map(_circuitLabel).join(', ')}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => setState(() => _selected = record),
                ),
              ),
          ],
        );
      },
    ),
    bottomSheet: _selected == null
        ? null
        : _VesselDetails(
            record: _selected!,
            atlas: _future,
            onClose: () => setState(() => _selected = null),
          ),
  );
}

String _classLabel(String value) => value == 'artery' ? 'Артерия' : 'Вена';
String _circuitLabel(String value) => switch (value) {
  'systemic' => 'Большой круг',
  'pulmonary' => 'Малый круг',
  _ => 'Воротная система',
};

class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.label,
    required this.values,
    required this.selected,
    required this.onSelected,
  });
  final String label;
  final String? selected;
  final Map<String, String> values;
  final ValueChanged<String?> onSelected;
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      ChoiceChip(
        label: Text('$label: все'),
        selected: selected == null,
        onSelected: (_) => onSelected(null),
      ),
      for (final entry in values.entries)
        ChoiceChip(
          key: Key('vascular-filter-${entry.key}'),
          label: Text(entry.value),
          selected: selected == entry.key,
          onSelected: (_) => onSelected(entry.key),
        ),
    ],
  );
}

class _RouteDiagram extends StatelessWidget {
  const _RouteDiagram({required this.onNode});
  final void Function(String vascularClass, String circuit) onNode;
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Маршруты большого и малого кругов кровообращения. Выберите группу сосудов.',
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Схема маршрутов',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _RouteLine(
              key: const Key('vascular-route-systemic-veins'),
              color: Colors.blue,
              label: 'Системные вены → правое сердце',
              onTap: () => onNode('vein', 'systemic'),
            ),
            _RouteLine(
              key: const Key('vascular-route-pulmonary-arteries'),
              color: Colors.blue,
              label: 'Лёгочный ствол → лёгочные артерии',
              onTap: () => onNode('artery', 'pulmonary'),
            ),
            _RouteLine(
              key: const Key('vascular-route-pulmonary-veins'),
              color: Colors.red,
              label: 'Лёгочные вены → левое сердце',
              onTap: () => onNode('vein', 'pulmonary'),
            ),
            _RouteLine(
              key: const Key('vascular-route-systemic-arteries'),
              color: Colors.red,
              label: 'Аорта → крупные артерии',
              onTap: () => onNode('artery', 'systemic'),
            ),
          ],
        ),
      ),
    ),
  );
}

class _RouteLine extends StatelessWidget {
  const _RouteLine({
    Key? key,
    required this.color,
    required this.label,
    required this.onTap,
  }) : routeKey = key;
  final Key? routeKey;
  final Color color;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: OutlinedButton.icon(
      key: routeKey,
      onPressed: onTap,
      icon: Icon(Icons.arrow_forward, color: color),
      label: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Text(label),
      ),
    ),
  );
}

class _VesselDetails extends StatelessWidget {
  const _VesselDetails({
    required this.record,
    required this.atlas,
    required this.onClose,
  });
  final VascularRecord record;
  final Future<VascularAtlas> atlas;
  final VoidCallback onClose;
  @override
  Widget build(BuildContext context) => Material(
    elevation: 12,
    child: SafeArea(
      top: false,
      child: SingleChildScrollView(
        key: const Key('vascular-details'),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    record.nameRu,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                IconButton(
                  tooltip: 'Закрыть',
                  onPressed: onClose,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            Text(
              '${_classLabel(record.vascularClass)} · ${record.circuits.map(_circuitLabel).join(', ')}',
            ),
            const SizedBox(height: 12),
            _DetailRow('Расположение', record.positionRu),
            _DetailRow('Роль', record.functionRu),
            _DetailRow('Факт', record.factRu),
            FutureBuilder<VascularAtlas>(
              future: atlas,
              builder: (context, snapshot) {
                final sources = snapshot.data?.sources;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final id in record.sourceIds)
                      if (sources?[id] case final source?)
                        TextButton.icon(
                          onPressed: () => _open(source.url),
                          icon: const Icon(Icons.open_in_new),
                          label: Text(source.title),
                        ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    ),
  );
  void _open(String value) {
    final uri = Uri.tryParse(value);
    if (uri?.scheme == 'https' && uri!.host.isNotEmpty) {
      launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        Text(value),
      ],
    ),
  );
}

String _string(Map<String, dynamic> row, String field) {
  final value = row[field];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('Missing $field');
  }
  return value;
}

List<String> _strings(Object? value) {
  if (value is! List ||
      value.isEmpty ||
      value.any((item) => item is! String || item.trim().isEmpty)) {
    throw const FormatException('Expected nonempty strings');
  }
  return value.cast<String>();
}

const _circuits = {'systemic', 'pulmonary', 'portal'};
const _regions = {'neck', 'thorax', 'abdomen', 'pelvis', 'lower_limb'};
