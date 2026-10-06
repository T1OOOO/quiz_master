part of 'main.dart';

const _studyPaperInk = Color(0xff3f2f23);
const _studyPaperLink = Color(0xff005f52);
const _studyPaperLine = Color(0xffb89b78);
const _studyPaperSurface = Color(0xffead9bf);

MarkdownStyleSheet _studyMarkdownStyle(BuildContext context) {
  final base = MarkdownStyleSheet.fromTheme(Theme.of(context));
  final body = base.p!.copyWith(color: _studyPaperInk, height: 1.55);
  return base.copyWith(
    p: body,
    a: body.copyWith(
      color: _studyPaperLink,
      decoration: TextDecoration.underline,
      decorationColor: _studyPaperLink,
    ),
    h1: base.h1!.copyWith(color: _studyPaperInk),
    h2: base.h2!.copyWith(color: _studyPaperInk),
    h3: base.h3!.copyWith(color: _studyPaperInk),
    h4: base.h4!.copyWith(color: _studyPaperInk),
    h5: base.h5!.copyWith(color: _studyPaperInk),
    h6: base.h6!.copyWith(color: _studyPaperInk),
    listBullet: body,
    code: body.copyWith(backgroundColor: const Color(0xfffff5e8)),
    blockquote: body,
    blockquoteDecoration: const BoxDecoration(
      color: Color(0xfffff5e8),
      border: Border(left: BorderSide(color: _studyPaperLink, width: 3)),
    ),
    tableHead: body.copyWith(fontWeight: FontWeight.w700),
    tableBody: body,
    tableBorder: TableBorder.all(color: _studyPaperLine),
    tableColumnWidth: const FlexColumnWidth(),
    tableCellsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    tableHeadCellsPadding: const EdgeInsets.symmetric(
      horizontal: 12,
      vertical: 10,
    ),
    tableCellsDecoration: const BoxDecoration(color: Color(0xfffffbf4)),
    tableHeadCellsDecoration: const BoxDecoration(color: Color(0xffffecd2)),
  );
}

class _StudyPaperCard extends StatelessWidget {
  const _StudyPaperCard({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
    color: _studyPaperSurface,
    child: DefaultTextStyle.merge(
      style: const TextStyle(color: _studyPaperInk),
      child: child,
    ),
  );
}

sealed class _StudyArticleBlock {
  const _StudyArticleBlock();
}

class _StudyMarkdownBlock extends _StudyArticleBlock {
  const _StudyMarkdownBlock(this.markdown);
  final String markdown;
}

class _StudyTableBlock extends _StudyArticleBlock {
  const _StudyTableBlock(this.headers, this.rows);
  final List<String> headers;
  final List<List<String>> rows;
}

List<_StudyArticleBlock> _studyMobileBlocks(String markdown) {
  final lines = markdown.split('\n');
  final blocks = <_StudyArticleBlock>[];
  final prose = <String>[];
  var inFence = false;

  void flushProse() {
    if (prose.isNotEmpty) {
      blocks.add(_StudyMarkdownBlock(prose.join('\n')));
      prose.clear();
    }
  }

  for (var i = 0; i < lines.length;) {
    if (RegExp(r'^\s*(```|~~~)').hasMatch(lines[i])) {
      inFence = !inFence;
    }
    final headers = inFence ? null : _studyTableCells(lines[i]);
    final divider = i + 1 < lines.length && !inFence
        ? _studyTableCells(lines[i + 1])
        : null;
    if (headers != null &&
        divider != null &&
        headers.isNotEmpty &&
        headers.length == divider.length &&
        divider.every((cell) => RegExp(r'^:?-{3,}:?$').hasMatch(cell))) {
      final rows = <List<String>>[];
      var next = i + 2;
      while (next < lines.length) {
        final row = _studyTableCells(lines[next]);
        if (row == null || row.length != headers.length) break;
        rows.add(row);
        next++;
      }
      if (rows.isNotEmpty &&
          headers.every(_isPlainStudyTableCell) &&
          rows.expand((row) => row).every(_isPlainStudyTableCell)) {
        flushProse();
        blocks.add(_StudyTableBlock(headers, rows));
        i = next;
        continue;
      }
    }
    prose.add(lines[i]);
    i++;
  }
  flushProse();
  return blocks;
}

bool _isPlainStudyTableCell(String value) =>
    !RegExp(r'[\[\]`*_<>~]').hasMatch(value);

List<String>? _studyTableCells(String line) {
  if (!line.contains('|')) return null;
  final cells = <String>[];
  final buffer = StringBuffer();
  var escaped = false;
  for (final rune in line.runes) {
    final character = String.fromCharCode(rune);
    if (escaped) {
      if (character == '|' || character == '\\') {
        buffer.write(character);
      } else {
        buffer.write('\\');
        buffer.write(character);
      }
      escaped = false;
    } else if (character == '\\') {
      escaped = true;
    } else if (character == '|') {
      cells.add(buffer.toString().trim());
      buffer.clear();
    } else {
      buffer.write(character);
    }
  }
  if (escaped) buffer.write('\\');
  cells.add(buffer.toString().trim());
  if (line.trimLeft().startsWith('|')) cells.removeAt(0);
  if (line.trimRight().endsWith('|')) cells.removeLast();
  return cells;
}

int _studyImageCacheWidth(BuildContext context) {
  final logicalWidth = min(
    920.0,
    max(1.0, MediaQuery.sizeOf(context).width - 40),
  );
  return (logicalWidth * MediaQuery.devicePixelRatioOf(context)).round();
}

class _StudyMobileTable extends StatelessWidget {
  const _StudyMobileTable({required this.headers, required this.rows});
  final List<String> headers;
  final List<List<String>> rows;

  @override
  Widget build(BuildContext context) => Column(
    key: const Key('study-mobile-table'),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (var rowIndex = 0; rowIndex < rows.length; rowIndex++)
        Container(
          key: Key('study-mobile-table-row-$rowIndex'),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xfffffbf4),
            border: Border.all(color: _studyPaperLine),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (
                var cellIndex = 0;
                cellIndex < headers.length;
                cellIndex++
              ) ...[
                if (cellIndex > 0) const Divider(color: _studyPaperLine),
                Text(
                  headers[cellIndex],
                  style: const TextStyle(
                    color: _studyPaperInk,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  rows[rowIndex][cellIndex],
                  style: const TextStyle(color: _studyPaperInk),
                ),
              ],
            ],
          ),
        ),
    ],
  );
}

class StudySource {
  const StudySource({required this.id, required this.title, required this.url});
  final String id, title, url;
}

class StudyQuestion {
  const StudyQuestion({
    required this.id,
    required this.text,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
    required this.sourceRefs,
  });
  final String id, text, explanation;
  final List<String> options;
  final int correctAnswer;
  final List<String> sourceRefs;
}

class StudyModule {
  const StudyModule({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.readingMinutesEstimate,
    required this.articleMarkdown,
    required this.objectives,
    required this.sourceQuizIds,
    required this.sources,
    required this.questions,
  });
  final String id, title, description, category, articleMarkdown;
  final int readingMinutesEstimate;
  final List<String> objectives, sourceQuizIds;
  final List<StudySource> sources;
  final List<StudyQuestion> questions;

  factory StudyModule.fromJson(Map<String, dynamic> json) => StudyModule(
    id: json['id'] as String,
    title: json['title'] as String,
    description: json['description'] as String,
    category: json['category'] as String,
    readingMinutesEstimate: json['reading_minutes_estimate'] as int,
    articleMarkdown: json['article_markdown'] as String,
    objectives: List<String>.from(json['objectives'] as List),
    sourceQuizIds: List<String>.from(json['source_quiz_ids'] as List),
    sources: (json['sources'] as List)
        .map(
          (v) => StudySource(
            id: v['id'] as String,
            title: v['title'] as String,
            url: v['url'] as String,
          ),
        )
        .toList(growable: false),
    questions: (json['questions'] as List)
        .map(
          (v) => StudyQuestion(
            id: v['id'] as String,
            text: v['text'] as String,
            options: List<String>.from(v['options'] as List),
            correctAnswer: v['correct_answer'] as int,
            explanation: v['explanation'] as String,
            sourceRefs: List<String>.from(v['source_refs'] as List),
          ),
        )
        .toList(growable: false),
  );
}

final studyModulesProvider = FutureProvider<List<StudyModule>>((ref) async {
  final data = jsonDecode(
    await rootBundle.loadString('assets/study/catalog.json'),
  ) as Map<String, dynamic>;
  final modules = (data['modules'] as List)
      .map((v) => StudyModule.fromJson(v as Map<String, dynamic>))
      .toList(growable: false);
  if (modules.map((m) => m.id).toSet().length != modules.length) {
    throw const FormatException('duplicate study module id');
  }
  return modules;
});

class StudyLibraryPage extends ConsumerWidget {
  const StudyLibraryPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => SourceScaffold(
    backLocation: '/library',
    body: ref
        .watch(studyModulesProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => _StudyMessage(
            text: AppLocalizations.of(context)!.studyLoadError,
            action: FilledButton(
              onPressed: () => ref.invalidate(studyModulesProvider),
              child: Text(AppLocalizations.of(context)!.retry),
            ),
          ),
          data: (modules) => modules.isEmpty
              ? Center(child: Text(AppLocalizations.of(context)!.studyMissing))
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1032),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                      children: [
                        Text(
                          AppLocalizations.of(context)!.studyLibrary,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(color: _cream),
                        ),
                        const SizedBox(height: 8),
                        Text(AppLocalizations.of(context)!.studyIntro),
                        const SizedBox(height: 16),
                        LayoutBuilder(
                          builder: (context, box) {
                            final columns = box.maxWidth > 760
                                ? 3
                                : box.maxWidth > 480
                                ? 2
                                : 1;
                            const cardExtent = 248.0;
                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: columns,
                                    crossAxisSpacing: 14,
                                    mainAxisSpacing: 14,
                                    mainAxisExtent: cardExtent,
                                  ),
                              itemCount: modules.length,
                              itemBuilder: (context, index) {
                                final module = modules[index];
                                return Semantics(
                                  button: true,
                                  child: SourceFolderCard(
                                    title: module.title,
                                    category: module.category,
                                    coverAsset:
                                        'assets/study/${module.id}-hero.png',
                                    coverHeight: 112,
                                    onTap: () => context.push(
                                      '/study/${Uri.encodeComponent(module.id)}',
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
        ),
  );
}

class StudyArticlePage extends ConsumerWidget {
  const StudyArticlePage({super.key, required this.moduleId});
  final String moduleId;
  @override
  Widget build(BuildContext context, WidgetRef ref) => SourceScaffold(
    backLocation: '/study',
    body: ref
        .watch(studyModulesProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => _StudyMessage(
            text: AppLocalizations.of(context)!.studyLoadError,
            action: FilledButton(
              onPressed: () => ref.invalidate(studyModulesProvider),
              child: Text(AppLocalizations.of(context)!.retry),
            ),
          ),
          data: (modules) {
            final module = _studyFind(modules, moduleId);
            if (module == null) {
              return Center(
                child: Text(AppLocalizations.of(context)!.studyMissing),
              );
            }
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 920),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  children: [
                    _StudyPaperCard(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              module.title,
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(color: const Color(0xff655444)),
                            ),
                            const SizedBox(height: 8),
                            Text(module.description),
                            const SizedBox(height: 12),
                            Text(
                              AppLocalizations.of(context)!.studyReadingMinutes(
                                module.readingMinutesEstimate,
                              ),
                            ),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: () => context.push(
                                '/study/${Uri.encodeComponent(module.id)}/practice',
                              ),
                              icon: const Icon(Icons.quiz_outlined),
                              label: Text(
                                AppLocalizations.of(context)!.studyPractice,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    _StudyArticleContent(module: module),
                    if (module.objectives.isNotEmpty)
                      _StudyPaperCard(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.studyObjectives,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              for (final objective in module.objectives)
                                ListTile(
                                  dense: true,
                                  leading: const Icon(
                                    Icons.check_circle_outline,
                                  ),
                                  title: Text(objective),
                                ),
                            ],
                          ),
                        ),
                      ),
                    if (module.sources.isNotEmpty)
                      _StudyPaperCard(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.studySources,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              for (final source in module.sources)
                                ListTile(
                                  leading: const Icon(Icons.open_in_new),
                                  title: Text(source.title),
                                  onTap: () => _openStudyUrl(source.url),
                                ),
                            ],
                          ),
                        ),
                      ),
                    for (final quizId in module.sourceQuizIds)
                      _StudyQuizLink(quizId: quizId),
                  ],
                ),
              ),
            );
          },
        ),
  );
}

class _StudyArticleContent extends StatefulWidget {
  const _StudyArticleContent({required this.module});
  final StudyModule module;
  @override
  State<_StudyArticleContent> createState() => _StudyArticleContentState();
}

class _StudyArticleContentState extends State<_StudyArticleContent> {
  late List<String> sections;
  late List<GlobalKey> sectionKeys;
  @override
  void initState() {
    super.initState();
    _parse();
  }

  @override
  void didUpdateWidget(_StudyArticleContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.module.id != widget.module.id ||
        oldWidget.module.articleMarkdown != widget.module.articleMarkdown) {
      _parse();
    }
  }

  void _parse() {
    sections = widget.module.articleMarkdown
        .split(RegExp(r'(?=^#{1,6}\s)', multiLine: true))
        .where((section) => section.trim().isNotEmpty)
        .toList();
    sectionKeys = List.generate(sections.length, (_) => GlobalKey());
  }

  String _heading(String section) =>
      section.split('\n').first.replaceFirst(RegExp(r'^#{1,6}\s*'), '').trim();

  int _headingLevel(String section) =>
      RegExp(r'^#+').firstMatch(section)?.group(0)?.length ?? 0;

  Widget _markdownBody(BuildContext context, String markdown) => MarkdownBody(
    data: markdown,
    styleSheet: _studyMarkdownStyle(context),
    onTapLink: (_, href, _) => _openStudyUrl(href),
    imageBuilder: (uri, title, alt) =>
        uri.scheme == 'resource' && uri.path.startsWith('assets/study/')
        ? ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: Image.asset(
                uri.path,
                width: double.infinity,
                cacheWidth: _studyImageCacheWidth(context),
                semanticLabel: alt?.isEmpty ?? true ? null : alt,
                excludeFromSemantics: alt?.isEmpty ?? true,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          )
        : const SizedBox.shrink(),
  );

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (sections.length > 1)
        _StudyPaperCard(
          key: const Key('study-contents'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.studyContents,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                for (var i = 0; i < sections.length; i++)
                  if (_headingLevel(sections[i]) >= 2 &&
                      _heading(sections[i]).isNotEmpty)
                    Padding(
                      padding: EdgeInsetsDirectional.only(
                        start: _headingLevel(sections[i]) > 2 ? 16 : 0,
                      ),
                      child: TextButton.icon(
                        key: Key('study-contents-item-$i'),
                        style: TextButton.styleFrom(
                          foregroundColor: _studyPaperLink,
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                        ),
                        onPressed: () {
                          final target = sectionKeys[i].currentContext;
                          if (target != null) {
                            Scrollable.ensureVisible(
                              target,
                              duration: const Duration(milliseconds: 250),
                              alignment: 0.04,
                            );
                          }
                        },
                        icon: const Icon(Icons.arrow_downward, size: 18),
                        label: Text(_heading(sections[i])),
                      ),
                    ),
              ],
            ),
          ),
        ),
      _StudyPaperCard(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < sections.length; i++)
                Container(
                  key: sectionKeys[i],
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final block
                          in MediaQuery.sizeOf(context).width < 600
                              ? _studyMobileBlocks(sections[i])
                              : <_StudyArticleBlock>[
                                  _StudyMarkdownBlock(sections[i]),
                                ])
                        switch (block) {
                          _StudyMarkdownBlock(:final markdown) => _markdownBody(
                            context,
                            markdown,
                          ),
                          _StudyTableBlock(:final headers, :final rows) =>
                            _StudyMobileTable(headers: headers, rows: rows),
                        },
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    ],
  );
}

class _StudyQuizLink extends ConsumerWidget {
  const _StudyQuizLink({required this.quizId});
  final String quizId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packs =
        ref.watch(discoveryCatalogProvider).asData?.value ??
        const <CatalogPack>[];
    CatalogPack? pack;
    for (final item in packs) {
      if (item.id == quizId) {
        pack = item;
        break;
      }
    }
    final readableId = quizId
        .split(RegExp(r'[-_]'))
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
    return _StudyPaperCard(
      child: ListTile(
        leading: const Icon(Icons.quiz_outlined),
        title: Text(pack?.title ?? readableId),
        subtitle: Text(
          pack?.description ?? AppLocalizations.of(context)!.browseQuizzes,
        ),
        onTap: () => context.push('/quiz/${Uri.encodeComponent(quizId)}'),
      ),
    );
  }
}

class StudyPracticePage extends ConsumerStatefulWidget {
  const StudyPracticePage({super.key, required this.moduleId});
  final String moduleId;
  @override
  ConsumerState<StudyPracticePage> createState() => _StudyPracticePageState();
}

class _StudyPracticePageState extends ConsumerState<StudyPracticePage>
    with WidgetsBindingObserver {
  final _feedbackScope = FocusScopeNode();
  late List<int> _order;
  int _index = 0, _score = 0;
  bool? _wasCorrect;
  Timer? _continueTimer;
  bool _paused = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _order = [];
  }

  @override
  void didUpdateWidget(StudyPracticePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.moduleId != widget.moduleId) {
      _continueTimer?.cancel();
      _order = [];
      _index = 0;
      _score = 0;
      _wasCorrect = null;
      _paused = false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _feedbackScope.dispose();
    _continueTimer?.cancel();
    super.dispose();
  }

  void _pause() {
    _continueTimer?.cancel();
    if (mounted && _wasCorrect == true && !_paused) {
      setState(() => _paused = true);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _pause();
  }

  void _start(StudyModule module) {
    if (_order.isEmpty) {
      _order = (List<int>.generate(
        module.questions.length,
        (i) => i,
      )..shuffle(Random())).take(20).toList();
    }
  }

  void _answer(
    StudyQuestion question,
    String optionId,
    Map<String, int> optionIndexes,
  ) {
    if (_wasCorrect != null || !optionIndexes.containsKey(optionId)) return;
    final correct = optionIndexes[optionId] == question.correctAnswer;
    setState(() {
      _wasCorrect = correct;
      if (correct) _score++;
    });
    if (correct) {
      _continueTimer?.cancel();
      _continueTimer = Timer(const Duration(seconds: 1), () {
        if (mounted && !_paused) {
          if (ModalRoute.of(context)?.isCurrent ?? true) {
            _advance();
          } else {
            _pause();
          }
        }
      });
    }
  }

  void _advance() {
    _continueTimer?.cancel();
    setState(() {
      _wasCorrect = null;
      _paused = false;
      _index++;
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(studyModulesProvider, (previous, next) {
      if (next.isLoading || next.hasError) _pause();
    });
    return SourceScaffold(
      backLocation: '/study/${Uri.encodeComponent(widget.moduleId)}',
      body: ref
          .watch(studyModulesProvider)
          .when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => _StudyMessage(
              text: AppLocalizations.of(context)!.studyLoadError,
              action: FilledButton(
                onPressed: () => ref.invalidate(studyModulesProvider),
                child: Text(AppLocalizations.of(context)!.retry),
              ),
            ),
            data: (modules) {
              final module = _studyFind(modules, widget.moduleId);
              if (module == null) {
                return Center(
                  child: Text(AppLocalizations.of(context)!.studyMissing),
                );
              }
              _start(module);
              if (module.questions.isEmpty || _index >= _order.length) {
                return _StudyMessage(
                  text:
                      '${AppLocalizations.of(context)!.studyComplete}\n${AppLocalizations.of(context)!.studyScore(_score, _order.length)}',
                  action: Wrap(
                    spacing: 8,
                    children: [
                      FilledButton(
                        onPressed: () => setState(() {
                          _index = 0;
                          _score = 0;
                          _wasCorrect = null;
                          _order = [];
                          _start(module);
                        }),
                        child: Text(AppLocalizations.of(context)!.studyRetry),
                      ),
                      OutlinedButton(
                        onPressed: () => context.go(
                          '/study/${Uri.encodeComponent(module.id)}',
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.studyBackArticle,
                        ),
                      ),
                    ],
                  ),
                );
              }
              final question = module.questions[_order[_index]];
              final shuffled = List<int>.generate(
                question.options.length,
                (i) => i,
              )..shuffle(Random(question.id.hashCode));
              final publicQuestion = PublicQuestion(
                quizId: 'study-local',
                id: question.id,
                revision: Revision(1, '0' * 64),
                stem: question.text,
                kind: AnswerKind.singleChoice,
                options: [
                  for (final i in shuffled)
                    PublicOption(
                      id: 'study-${question.id}-option-$i',
                      text: question.options[i],
                    ),
                ],
              );
              final optionIndexes = {
                for (var i = 0; i < question.options.length; i++)
                  'study-${question.id}-option-$i': i,
              };
              final wrongOrPaused =
                  _wasCorrect == false || (_wasCorrect == true && _paused);
              final reveal = wrongOrPaused
                  ? Reveal(
                      answer: question.options[question.correctAnswer],
                      explanation: question.explanation,
                      correctOptionIds: {
                        'study-${question.id}-option-${question.correctAnswer}',
                      },
                    )
                  : null;
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 820),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      ExcludeFocus(
                        excluding: _wasCorrect != null,
                        child: ExcludeSemantics(
                          excluding: _wasCorrect != null,
                          child: AbsorbPointer(
                            absorbing: _wasCorrect != null,
                            child: ListView(
                              padding: const EdgeInsets.all(20),
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        AppLocalizations.of(context)!
                                            .studyUnranked,
                                        key: const Key('study-unranked-label'),
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
                                      ),
                                    ),
                                    Text('${_index + 1} / ${_order.length}'),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                LinearProgressIndicator(
                                  value: (_index + 1) / _order.length,
                                ),
                                const SizedBox(height: 20),
                                QuestionCard(
                                  key: ValueKey(question.id),
                                  question: publicQuestion,
                                  submitting: _wasCorrect != null,
                                  reveal: null,
                                  showExplanation: false,
                                  onAnswer: (value) => _answer(
                                    question,
                                    value as String,
                                    optionIndexes,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (_wasCorrect != null)
                        Positioned.fill(
                          child: Stack(
                            children: [
                              const Positioned.fill(
                                child: ModalBarrier(
                                  key: Key('study-feedback-barrier'),
                                  dismissible: false,
                                  color: Color(0xaa1b100b),
                                ),
                              ),
                              Center(
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.all(20),
                                  child: FocusScope(
                                    node: _feedbackScope,
                                    autofocus: true,
                                    child: BlockSemantics(
                                      child: _StudyFeedbackDialog(
                                        question: question,
                                        module: module,
                                        reveal: reveal,
                                        correct: _wasCorrect!,
                                        paused: _paused,
                                        onPause: _pause,
                                        onContinue: _advance,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
    );
  }
}

class _StudyFeedbackDialog extends StatelessWidget {
  const _StudyFeedbackDialog({
    required this.question,
    required this.module,
    required this.reveal,
    required this.correct,
    required this.paused,
    required this.onPause,
    required this.onContinue,
  });
  final StudyQuestion question;
  final StudyModule module;
  final Reveal? reveal;
  final bool correct, paused;
  final VoidCallback onPause, onContinue;
  @override
  Widget build(BuildContext context) {
    final referenced = module.sources.where(
      (source) => question.sourceRefs.contains(source.id),
    );
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Card(
          key: const Key('study-feedback-overlay'),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  correct ? Icons.check_circle : Icons.info_outline,
                  color: Theme.of(context).colorScheme.primary,
                  size: 48,
                ),
                Text(
                  correct
                      ? AppLocalizations.of(context)!.studyCorrect
                      : AppLocalizations.of(context)!.studyIncorrect,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (reveal != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ExplanationPanel(reveal: reveal!),
                  ),
                if (reveal != null)
                  for (final source in referenced)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.open_in_new),
                        title: Text(source.title),
                        onTap: () => _openStudyUrl(source.url),
                      ),
                    ),
                if (correct && !paused)
                  Text(AppLocalizations.of(context)!.studyNextSecond),
                const SizedBox(height: 8),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (correct && !paused)
                      TextButton(
                        autofocus: true,
                        key: const Key('study-pause'),
                        onPressed: onPause,
                        child: Text(AppLocalizations.of(context)!.studyPause),
                      ),
                    FilledButton(
                      autofocus: !correct || paused,
                      key: const Key('study-continue'),
                      onPressed: onContinue,
                      child: Text(AppLocalizations.of(context)!.studyContinue),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StudyMessage extends StatelessWidget {
  const _StudyMessage({required this.text, this.action});
  final String text;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text, textAlign: TextAlign.center),
          if (action != null) ...[const SizedBox(height: 16), action!],
        ],
      ),
    ),
  );
}

StudyModule? _studyFind(List<StudyModule> modules, String id) {
  for (final module in modules) {
    if (module.id == id) return module;
  }
  return null;
}

Future<void> _openStudyUrl(String? value) async {
  final uri = value == null ? null : Uri.tryParse(value);
  if (uri != null && uri.scheme == 'https' && uri.host.isNotEmpty) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
