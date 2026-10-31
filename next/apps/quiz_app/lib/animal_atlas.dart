/// A source-linked Russian animal catalogue backed by the reviewed JSON asset.
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'atlas_media.dart';
import 'fact_practice.dart';
import 'fact_practice_models.dart';

const _animalsAsset = 'assets/quizipedia/animals.json';

class AnimalRecord {
  const AnimalRecord({
    required this.id,
    required this.nameRu,
    required this.wikiTitle,
    required this.groupRu,
    required this.kindRu,
    required this.factRu,
    required this.sourceUrl,
    this.highlightsRu = const [],
  });

  final String id, nameRu, wikiTitle, groupRu, kindRu, factRu, sourceUrl;
  final List<String> highlightsRu;

  factory AnimalRecord.fromJson(Map<String, dynamic> json) {
    final sourceUrl = _requiredAnimalString(json, 'source_url');
    final source = Uri.tryParse(sourceUrl);
    if (source?.scheme != 'https' || source!.host.isEmpty) {
      throw const FormatException('Animal source URL must use HTTPS');
    }
    final rawHighlights = json['highlights_ru'];
    final highlightsRu = rawHighlights is List
        ? [
            for (final item in rawHighlights)
              if (item is String && item.trim().isNotEmpty) item.trim(),
          ]
        : const <String>[];
    return AnimalRecord(
      id: _requiredAnimalString(json, 'id'),
      nameRu: _requiredAnimalString(json, 'name_ru'),
      wikiTitle: _requiredAnimalString(json, 'wiki_title'),
      groupRu: _requiredAnimalString(json, 'group_ru'),
      kindRu: _requiredAnimalString(json, 'kind_ru'),
      factRu: _requiredAnimalString(json, 'fact_ru'),
      sourceUrl: sourceUrl,
      highlightsRu: List.unmodifiable(highlightsRu),
    );
  }
}

String _requiredAnimalString(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('Animal $field is required');
  }
  return value;
}

Future<List<AnimalRecord>> loadAnimals(AssetBundle bundle) async {
  final decoded = jsonDecode(await bundle.loadString(_animalsAsset));
  if (decoded is! Map || decoded['schema_version'] != 'qm-animals/v1') {
    throw const FormatException('Unsupported animal catalogue');
  }
  final animals = decoded['animals'];
  if (animals is! List) throw const FormatException('Missing animals');
  final ids = <String>{};
  final records = <AnimalRecord>[];
  for (final value in animals) {
    if (value is! Map) throw const FormatException('Invalid animal record');
    final record = AnimalRecord.fromJson(Map<String, dynamic>.from(value));
    if (!ids.add(record.id)) throw const FormatException('Duplicate animal id');
    records.add(record);
  }
  return List.unmodifiable(records);
}

List<StudyFact> animalStudyFacts(Iterable<AnimalRecord> animals) => [
  // Group and kind are visible catalogue labels. Their five and two distinct
  // values cannot support a truthful six-choice practice question.
  for (final animal in animals)
    StudyFact(
      id: 'animals.${animal.id}.fact',
      scope: 'animals',
      entityId: animal.id,
      nameRu: animal.nameRu,
      nameEn: animal.wikiTitle,
      fieldPath: 'fact_ru',
      fieldRu: 'Факт',
      fieldEn: 'Fact',
      valueRu: animal.factRu,
      valueEn: animal.factRu,
      sources: [
        FactSource(
          titleRu: 'Источник',
          titleEn: 'Source',
          url: animal.sourceUrl,
        ),
      ],
    ),
];

class AnimalsPage extends StatefulWidget {
  const AnimalsPage({super.key, this.bundle, this.training = false});

  final AssetBundle? bundle;
  final bool training;

  @override
  State<AnimalsPage> createState() => _AnimalsPageState();
}

class _AnimalsPageState extends State<AnimalsPage> {
  final _search = TextEditingController();
  String? _group;
  AnimalRecord? _selected;
  late final Future<List<AnimalRecord>> _animals = _load();

  Future<List<AnimalRecord>> _load() =>
      loadAnimals(widget.bundle ?? DefaultAssetBundle.of(context));

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Животные'),
      actions: [
        FutureBuilder<List<AnimalRecord>>(
          future: _animals,
          builder: (context, snapshot) => IconButton(
            tooltip: 'Тренировка по фактам',
            icon: const Icon(Icons.fact_check_outlined),
            onPressed: snapshot.hasData
                ? () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => FactPracticePage(
                        scope: 'animals',
                        facts: animalStudyFacts(snapshot.data!),
                      ),
                    ),
                  )
                : null,
          ),
        ),
      ],
    ),
    body: FutureBuilder<List<AnimalRecord>>(
      future: _animals,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Не удалось загрузить каталог животных.'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final animals = snapshot.data!;
        final groups = <String>{
          for (final animal in animals) animal.groupRu,
        }.toList()..sort();
        final query = _search.text.trim().toLowerCase();
        final visible = animals.where((animal) {
          return (_group == null || animal.groupRu == _group) &&
              (query.isEmpty ||
                  '${animal.nameRu} ${animal.wikiTitle}'.toLowerCase().contains(
                    query,
                  ));
        }).toList();
        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                key: const Key('animal-search'),
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Найти животное',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    key: const Key('animal-group-all'),
                    label: Text('Все (${animals.length})'),
                    selected: _group == null,
                    onSelected: (_) => setState(() => _group = null),
                  ),
                  for (final group in groups)
                    ChoiceChip(
                      key: Key('animal-group-$group'),
                      label: Text(
                        '$group (${animals.where((animal) => animal.groupRu == group).length})',
                      ),
                      selected: _group == group,
                      onSelected: (_) => setState(() => _group = group),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Найдено: ${visible.length}',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              for (final animal in visible)
                Card(
                  child: ListTile(
                    key: Key('animal-${animal.id}'),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    leading: AtlasMedia(
                      scope: 'animals',
                      entityId: animal.id,
                      compact: true,
                    ),
                    title: Text(animal.nameRu),
                    subtitle: Text('${animal.kindRu} · ${animal.groupRu}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => setState(() => _selected = animal),
                  ),
                ),
            ],
          ),
        );
      },
    ),
    bottomSheet: _selected == null
        ? null
        : _AnimalDetails(
            animal: _selected!,
            onClose: () => setState(() => _selected = null),
          ),
  );
}

class _AnimalDetails extends StatelessWidget {
  const _AnimalDetails({required this.animal, required this.onClose});

  final AnimalRecord animal;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => Material(
    elevation: 12,
    child: SafeArea(
      top: false,
      child: SingleChildScrollView(
        key: const Key('animal-details'),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    animal.nameRu,
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
            Text('${animal.kindRu} · ${animal.groupRu}'),
            const SizedBox(height: 12),
            AtlasMedia(scope: 'animals', entityId: animal.id),
            const SizedBox(height: 12),
            Text(animal.factRu),
            if (animal.highlightsRu.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Интересные и известные факты',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 6),
              for (final highlight in animal.highlightsRu)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text('• $highlight'),
                ),
            ],
            TextButton.icon(
              onPressed: () => _open(animal.sourceUrl),
              icon: const Icon(Icons.open_in_new),
              label: const Text('Источник факта'),
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
