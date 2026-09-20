part of 'main.dart';

class CatalogPage extends ConsumerStatefulWidget {
  const CatalogPage({super.key});
  @override
  ConsumerState<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends ConsumerState<CatalogPage> {
  final _name = TextEditingController();
  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final journey = ref.watch(journeyProvider);
    final controller = ref.read(journeyProvider.notifier);
    final catalog = journey.catalog;
    final attempt = journey.attempt;
    final finish = journey.finish;
    return AppScaffold(
      title: l10n.catalogTitle,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                children: [
                  if (journey.session == null) ...[
                    TextField(
                      controller: _name,
                      enabled: !journey.loading,
                      decoration: InputDecoration(labelText: l10n.displayName),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: journey.loading
                          ? null
                          : () => controller.bootstrap(_name.text),
                      child: Text(
                        journey.loading ? l10n.loading : l10n.continueLabel,
                      ),
                    ),
                    if (journey.error != null)
                      _ErrorPanel(
                        message: l10n.catalogLoadError,
                        retryable: journey.errorRetryable,
                        onRetry: () => controller.bootstrap(_name.text),
                      ),
                  ] else if (catalog == null) ...[
                    if (journey.loading) ...[
                      const CircularProgressIndicator(),
                      const SizedBox(height: 8),
                      Text(l10n.loading),
                    ] else
                      _ErrorPanel(
                        message: l10n.catalogLoadError,
                        retryable: journey.errorRetryable,
                        onRetry: controller.reloadCatalog,
                      ),
                  ] else if (catalog.quiz.questions.isEmpty) ...[
                    Text(l10n.catalogEmpty, key: const Key('catalog-empty')),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: journey.loading
                          ? null
                          : controller.reloadCatalog,
                      child: Text(journey.loading ? l10n.loading : l10n.retry),
                    ),
                  ] else if (attempt != null &&
                      journey.index < attempt.snapshots.length) ...[
                    _QuestionStep(
                      journey: journey,
                      question: _orderedQuestion(
                        catalog,
                        attempt.snapshots[journey.index],
                      ),
                    ),
                  ] else if (attempt != null && finish == null) ...[
                    FilledButton(
                      onPressed: journey.submitting
                          ? null
                          : controller.complete,
                      child: Text(
                        journey.submitting ? l10n.finishing : l10n.finishQuiz,
                      ),
                    ),
                    if (journey.error != null)
                      _ErrorPanel(
                        message: l10n.journeyError,
                        retryable: journey.errorRetryable,
                        onRetry: controller.retry,
                      ),
                  ] else if (finish != null) ...[
                    Text(
                      l10n.score(finish.score),
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    if (journey.postFinishError != null)
                      _ErrorPanel(
                        message: l10n.resultsLoadError,
                        retryable: journey.postFinishRetryable,
                        onRetry: controller.complete,
                      ),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: controller.newQuiz,
                      child: Text(l10n.newQuiz),
                    ),
                    TextButton(
                      onPressed: () => context.push('/history'),
                      child: Text(l10n.history),
                    ),
                    for (final reveal in journey.reveals)
                      ExplanationPanel(reveal: reveal),
                  ] else ...[
                    PackTile(
                      title: catalog.quiz.id,
                      subtitle: l10n.questionsCount(
                        catalog.quiz.questions.length,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: journey.loading ? null : controller.start,
                      child: Text(
                        journey.loading ? l10n.loading : l10n.startQuiz,
                      ),
                    ),
                    if (journey.error != null)
                      _ErrorPanel(
                        message: l10n.journeyError,
                        retryable: journey.errorRetryable,
                        onRetry: controller.retry,
                      ),
                  ],
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => context.push('/gallery'),
                    child: Text(l10n.openGallery),
                  ),
                  if (journey.session != null && finish == null)
                    TextButton(
                      onPressed: () => context.push('/history'),
                      child: Text(l10n.history),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionStep extends ConsumerWidget {
  const _QuestionStep({required this.journey, required this.question});
  final JourneyState journey;
  final PublicQuestion? question;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final attempt = journey.attempt;
    final current = question;
    if (attempt == null || current == null) {
      return _ErrorPanel(
        message: l10n.journeyError,
        retryable: false,
        onRetry: () {},
      );
    }
    return Column(
      children: [
        Text('${journey.index + 1}/${attempt.snapshots.length}'),
        QuestionCard(
          key: ValueKey(current.id),
          question: current,
          submitting: journey.submitting,
          onAnswer: (value) =>
              ref.read(journeyProvider.notifier).stage(current.kind, value),
        ),
        FilledButton(
          onPressed: journey.staged == null || journey.submitting
              ? null
              : ref.read(journeyProvider.notifier).submit,
          child: Text(
            journey.submitting ? l10n.submitting : l10n.continueLabel,
          ),
        ),
        if (journey.error != null)
          _ErrorPanel(
            message: l10n.journeyError,
            retryable: journey.errorRetryable,
            onRetry: ref.read(journeyProvider.notifier).retry,
          ),
      ],
    );
  }
}

PublicQuestion? _orderedQuestion(Catalog catalog, AttemptSnapshot snapshot) {
  PublicQuestion? source;
  for (final question in catalog.quiz.questions) {
    if (question.id == snapshot.questionId) {
      source = question;
      break;
    }
  }
  if (source == null) return null;
  final byId = {for (final option in source.options) option.id: option};
  final ordered = <PublicOption>[];
  for (final id in snapshot.optionOrder) {
    final option = byId[id];
    if (option == null) return null;
    ordered.add(option);
  }
  return PublicQuestion(
    quizId: source.quizId,
    id: source.id,
    revision: source.revision,
    stem: source.stem,
    kind: source.kind,
    options: ordered,
  );
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({
    required this.message,
    required this.retryable,
    required this.onRetry,
  });
  final String message;
  final bool retryable;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Column(
      children: [
        Text(message, key: const Key('journey-error')),
        if (retryable)
          FilledButton(
            onPressed: onRetry,
            child: Text(AppLocalizations.of(context)!.retry),
          ),
      ],
    ),
  );
}

class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});
  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  Future<List<Finish>>? _future;
  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    final future = ref.read(quizApiProvider).history();
    setState(() {
      _future = future;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppScaffold(
      title: l10n.history,
      body: FutureBuilder<List<Finish>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 8),
                  Text(l10n.loading),
                ],
              ),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.historyLoadError),
                  FilledButton(onPressed: _reload, child: Text(l10n.retry)),
                ],
              ),
            );
          }
          final values = snapshot.data ?? const <Finish>[];
          if (values.isEmpty) return Center(child: Text(l10n.noHistory));
          return ListView(
            children: [
              for (final finish in values)
                ListTile(
                  title: Text(l10n.score(finish.score)),
                  subtitle: Text(finish.attemptId),
                ),
            ],
          );
        },
      ),
    );
  }
}
