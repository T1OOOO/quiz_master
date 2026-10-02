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
    return AppScaffold(
      title: l10n.catalogTitle,
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
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1056),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.browseQuizzes,
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      const SizedBox(height: 8),
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
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (value) =>
                            context.replace(_location(widget.folder, value)),
                      ),
                      const SizedBox(height: 16),
                      Text(l10n.catalogPreview),
                      const SizedBox(height: 12),
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
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final columns = constraints.maxWidth < 600 ? 2 : 3;
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
                                    child: Card(
                                      child: InkWell(
                                        key: Key('folder-$folder'),
                                        borderRadius: BorderRadius.circular(12),
                                        onTap: () => context.go(
                                          _location(
                                            [
                                              if (widget.folder.isNotEmpty)
                                                widget.folder,
                                              folder,
                                            ].join('/'),
                                          ),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(20),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Icon(
                                                Icons.folder_outlined,
                                                size: 32,
                                              ),
                                              const SizedBox(height: 12),
                                              Text(
                                                folder,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium,
                                              ),
                                            ],
                                          ),
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
                          child: ListTile(
                            key: Key('pack-${pack.id}'),
                            isThreeLine: true,
                            title: Text(pack.title),
                            subtitle: Text(
                              '${pack.description}\n${l10n.questionsCount(pack.questions)}${pack.id == 'home-alone-1-part-1' ? '' : ' · ${l10n.packPending}'}',
                            ),
                            trailing: Icon(
                              pack.id == 'home-alone-1-part-1'
                                  ? Icons.play_arrow
                                  : Icons.hourglass_empty,
                            ),
                            onTap: pack.id == 'home-alone-1-part-1'
                                ? () => context.push('/')
                                : null,
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
