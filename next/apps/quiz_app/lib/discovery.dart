part of 'main.dart';

class CatalogPack {
  const CatalogPack(
    this.id,
    this.title,
    this.description,
    this.category,
    this.questions,
  );
  final String id, title, description, category;
  final int questions;

  factory CatalogPack.fromJson(Map<String, dynamic> json) {
    _closed(json, {
      'quiz_id',
      'title',
      'description',
      'category',
      'questions_count',
    });
    for (final key in ['quiz_id', 'title', 'description', 'category']) {
      if (json[key] is! String || (json[key] as String).trim().isEmpty) {
        throw const FormatException('catalog metadata');
      }
    }
    if (!_validId(json['quiz_id'] as String) ||
        json['questions_count'] is! int ||
        (json['questions_count'] as int) < 1) {
      throw const FormatException('catalog metadata');
    }
    return CatalogPack(
      json['quiz_id'] as String,
      json['title'] as String,
      json['description'] as String,
      (json['category'] as String).replaceAll('\\', '/'),
      json['questions_count'] as int,
    );
  }
}

// Temporary public metadata only. Stage 2 replaces this loader with the API.
final discoveryCatalogProvider = FutureProvider<List<CatalogPack>>((ref) async {
  final value = jsonDecode(await rootBundle.loadString('assets/catalog.json'));
  if (value is! List) throw const FormatException('catalog collection');
  final packs = value.map((item) => CatalogPack.fromJson(_map(item))).toList();
  if (packs.map((pack) => pack.id).toSet().length != packs.length) {
    throw const FormatException('duplicate catalog ID');
  }
  return packs;
});

class DiscoveryPage extends ConsumerStatefulWidget {
  const DiscoveryPage({super.key, required this.folder, required this.query});
  final String folder, query;

  @override
  ConsumerState<DiscoveryPage> createState() => _DiscoveryPageState();
}

class _DiscoveryPageState extends ConsumerState<DiscoveryPage> {
  late final _search = TextEditingController(text: widget.query);
  @override
  void didUpdateWidget(DiscoveryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_search.text != widget.query) _search.text = widget.query;
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String _location(String folder, [String query = '']) => Uri(
    path: '/library',
    queryParameters: {
      if (folder.isNotEmpty) 'folder': folder,
      if (query.isNotEmpty) 'q': query,
    },
  ).toString();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final catalog = ref.watch(discoveryCatalogProvider);
    final compact = MediaQuery.sizeOf(context).height < 720;
    return SourceScaffold(
      compact: compact,
      body: catalog.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.catalogLoadError),
              TextButton(
                onPressed: () => ref.invalidate(discoveryCatalogProvider),
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
        data: (packs) {
          final query = widget.query.trim().toLowerCase();
          final folders = <String>{};
          final visible = <CatalogPack>[];
          for (final pack in packs) {
            if (query.isNotEmpty) {
              if ('${pack.title} ${pack.description} ${pack.category}'
                  .toLowerCase()
                  .contains(query)) {
                visible.add(pack);
              }
            } else if (pack.category == widget.folder ||
                (widget.folder.isEmpty &&
                    ['Разное', 'General', ''].contains(pack.category))) {
              visible.add(pack);
            } else if (widget.folder.isEmpty ||
                pack.category.startsWith('${widget.folder}/')) {
              final rest = widget.folder.isEmpty
                  ? pack.category
                  : pack.category.substring(widget.folder.length + 1);
              folders.add(rest.split('/').first);
            }
          }
          visible.sort((a, b) => a.title.compareTo(b.title));
          final sortedFolders = folders.toList()..sort();
          final segments = widget.folder.isEmpty
              ? <String>[]
              : widget.folder.split('/');
          return ListView(
            padding: EdgeInsets.all(compact ? 12 : 20),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 992),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.catalogInventory(
                          packs.length,
                          packs.fold(
                            0,
                            (total, pack) => total + pack.questions,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        key: const Key('catalog-search'),
                        controller: _search,
                        decoration: InputDecoration(
                          labelText: l10n.searchQuizzes,
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onChanged: (value) =>
                            context.replace(_location(widget.folder, value)),
                      ),
                      SizedBox(height: compact ? 8 : 28),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          TextButton(
                            key: const Key('catalog-root'),
                            onPressed: () => context.go('/library'),
                            child: Text(l10n.catalogRoot),
                          ),
                          for (var i = 0; i < segments.length; i++) ...[
                            const Icon(Icons.chevron_right, size: 18),
                            TextButton(
                              onPressed: () => context.go(
                                _location(segments.take(i + 1).join('/')),
                              ),
                              child: Text(segments[i]),
                            ),
                          ],
                        ],
                      ),
                      if (sortedFolders.isNotEmpty) ...[
                        Text(
                          l10n.categories,
                          style: const TextStyle(color: _cream, fontSize: 18),
                        ),
                        const SizedBox(height: 12),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final columns = constraints.maxWidth < 600 ? 2 : 4;
                            final width =
                                (constraints.maxWidth - 12 * (columns - 1)) /
                                columns;
                            return Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                for (final folder in sortedFolders)
                                  SizedBox(
                                    width: width,
                                    child: SourceFolderCard(
                                      title: folder,
                                      coverHeight: compact
                                          ? (columns == 2 ||
                                                    sortedFolders.length > 8
                                                ? 40
                                                : 72)
                                          : (sortedFolders.length > 8
                                                ? 72
                                                : 112),
                                      category: widget.folder.isEmpty
                                          ? folder
                                          : widget.folder,
                                      onTap: () => context.go(
                                        _location(
                                          [
                                            if (widget.folder.isNotEmpty)
                                              widget.folder,
                                            folder,
                                          ].join('/'),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ],
                      for (final pack in visible)
                        Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            children: [
                              ListTile(
                                key: Key('pack-${pack.id}'),
                                isThreeLine: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 16,
                                ),
                                title: Text(pack.title),
                                subtitle: Text(
                                  '${pack.description}\n${l10n.questionsCount(pack.questions)}',
                                ),
                                trailing: const Icon(Icons.play_arrow),
                                onTap: () => context.go('/quiz/${pack.id}'),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  16,
                                ),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      for (
                                        var round = 0;
                                        round < (pack.questions + 19) ~/ 20;
                                        round++
                                      )
                                        ActionChip(
                                          label: Text(
                                            '${l10n.roundLabel(round + 1)} · ${l10n.roundQuestions((pack.questions - round * 20).clamp(1, 20))}',
                                          ),
                                          onPressed: () => context.go(
                                            '/quiz/${pack.id}?round=$round',
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (sortedFolders.isEmpty && visible.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            query.isEmpty
                                ? l10n.catalogEmpty
                                : l10n.noSearchResults,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
