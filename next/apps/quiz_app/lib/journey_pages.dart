part of 'main.dart';

class CatalogPage extends ConsumerStatefulWidget {
  const CatalogPage({super.key, this.quizId, this.round = 0});
  final String? quizId;
  final int round;
  @override
  ConsumerState<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends ConsumerState<CatalogPage> {
  final _name = TextEditingController();
  @override
  void initState() {
    super.initState();
    if (widget.quizId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref
              .read(journeyProvider.notifier)
              .openQuiz(widget.quizId!, round: widget.round);
        }
      });
    }
  }

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
    ref.listen(journeyProvider.select((s) => s.feedback), (previous, feedback) {
      if (feedback != null && !feedback.correct && feedback != previous) {
        _showFeedback(context, feedback, controller.nextQuestion);
      }
    });
    final title =
        ref
            .watch(discoveryCatalogProvider)
            .asData
            ?.value
            .where((p) => p.id == widget.quizId)
            .firstOrNull
            ?.title ??
        '';
    if (widget.quizId != null &&
        attempt != null &&
        catalog != null &&
        journey.index < attempt.snapshots.length &&
        !journey.loading) {
      return SourceScaffold(
        compact: true,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => context.go('/library'),
                        child: Text(l10n.browseQuizzes),
                      ),
                      Text(l10n.roundLabel(widget.round + 1)),
                    ],
                  ),
                  Expanded(
                    child: _QuestionStep(
                      journey: journey,
                      question: _orderedQuestion(
                        catalog,
                        attempt.snapshots[journey.index],
                      ),
                      fitScreen: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    final body = ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              children: [
                if (widget.quizId != null)
                  Text(
                    ref
                            .watch(discoveryCatalogProvider)
                            .asData
                            ?.value
                            .where((p) => p.id == widget.quizId)
                            .firstOrNull
                            ?.title ??
                        '',
                    style: const TextStyle(
                      color: _cream,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                TextButton(
                  onPressed: () => context.go('/library'),
                  child: Text(l10n.browseQuizzes),
                ),
                if (widget.quizId != null &&
                    (journey.loading || catalog == null)) ...[
                  if (journey.loading || journey.error == null)
                    const CircularProgressIndicator()
                  else
                    _ErrorPanel(
                      message: l10n.catalogLoadError,
                      retryable: journey.errorRetryable,
                      onRetry: () => controller.openQuiz(
                        widget.quizId!,
                        round: widget.round,
                      ),
                    ),
                ] else if (journey.session == null) ...[
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
                    onPressed: journey.submitting ? null : controller.complete,
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
                    style: Theme.of(context).textTheme.headlineMedium
                        ?.copyWith(color: _cream),
                  ),
                  if (journey.postFinishError != null)
                    _ErrorPanel(
                      message: l10n.resultsLoadError,
                      retryable: journey.postFinishRetryable,
                      onRetry: controller.complete,
                    ),
                  const SizedBox(height: 8),
                  if (widget.quizId != null &&
                      (widget.round + 1) * 20 < catalog.quiz.questions.length)
                    FilledButton(
                      onPressed: () => context.go(
                        '/quiz/${widget.quizId}?round=${widget.round + 1}',
                      ),
                      child: Text(l10n.nextRound),
                    ),
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
                if (widget.quizId == null)
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
    );
    return widget.quizId == null
        ? AppScaffold(title: l10n.catalogTitle, body: body)
        : SourceScaffold(compact: true, body: body);
  }
}

class _QuestionStep extends ConsumerStatefulWidget {
  const _QuestionStep({
    required this.journey,
    required this.question,
    this.fitScreen = false,
  });
  final bool fitScreen;
  final JourneyState journey;
  final PublicQuestion? question;

  @override
  ConsumerState<_QuestionStep> createState() => _QuestionStepState();
}

class _QuestionStepState extends ConsumerState<_QuestionStep>
    with WidgetsBindingObserver {
  Timer? _advance;
  int _seconds = 3;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didUpdateWidget(_QuestionStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.journey.feedback != oldWidget.journey.feedback) {
      _advance?.cancel();
      _advance = null;
      if (widget.journey.feedback?.correct == true) _resume();
    }
  }

  void _pause() {
    _advance?.cancel();
    setState(() => _advance = null);
  }

  void _resume() {
    _seconds = 3;
    _advance = Timer.periodic(const Duration(seconds: 1), (_) {
      if (ModalRoute.of(context)?.isCurrent != true) {
        _pause();
      } else if (_seconds == 1) {
        _next();
      } else {
        setState(() => _seconds--);
      }
    });
  }

  void _next() {
    _pause();
    ref.read(journeyProvider.notifier).nextQuestion();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && _advance != null) _pause();
  }

  @override
  void dispose() {
    _advance?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final journey = widget.journey;
    final question = widget.question;
    final fitScreen = widget.fitScreen;
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
        LinearProgressIndicator(
          value: journey.index / attempt.snapshots.length,
          minHeight: 6,
          borderRadius: BorderRadius.circular(8),
        ),
        const SizedBox(height: 8),
        Text('${journey.index + 1}/${attempt.snapshots.length}'),
        if (fitScreen)
          Expanded(
            child: SingleChildScrollView(
              key: ValueKey(current.id),
              child: QuestionCard(
                key: ValueKey(current.id),
                question: current,
                submitting:
                    journey.submitting ||
                    journey.receipts.length > journey.index,
                reveal: journey.feedback?.reveal,
                showExplanation: false,
                onAnswer: (value) => ref
                    .read(journeyProvider.notifier)
                    .stage(current.kind, value),
              ),
            ),
          )
        else
          QuestionCard(
            key: ValueKey(current.id),
            question: current,
            submitting:
                journey.submitting || journey.receipts.length > journey.index,
            onAnswer: (value) =>
                ref.read(journeyProvider.notifier).stage(current.kind, value),
          ),
        const SizedBox(height: 8),
        if (journey.feedback != null)
          TextButton.icon(
            key: const Key('answer-explanation'),
            icon: Icon(
              journey.feedback!.correct ? Icons.check_circle : Icons.cancel,
              color: journey.feedback!.correct
                  ? const Color(0xff1e5e22)
                  : const Color(0xffa52a2a),
            ),
            label: Text(_feedbackLabel(context, journey.feedback!.correct)),
            onPressed: () {
              _pause();
              _showFeedback(context, journey.feedback!, _next);
            },
          ),
        if (journey.feedback?.correct == true)
          TextButton.icon(
            key: Key(_advance == null ? 'auto-resume' : 'auto-pause'),
            onPressed: _advance == null ? () => setState(_resume) : _pause,
            icon: Icon(_advance == null ? Icons.play_arrow : Icons.pause),
            label: Text(
              _advance == null
                  ? l10n.resumeAutoAdvance
                  : l10n.autoAdvanceIn(_seconds),
            ),
          ),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: journey.feedback != null
                ? _next
                : journey.staged == null || journey.submitting
                ? null
                : ref.read(journeyProvider.notifier).submit,
            child: Text(
              journey.submitting ? l10n.submitting : l10n.continueLabel,
            ),
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

String _feedbackLabel(BuildContext context, bool correct) =>
    Localizations.localeOf(context).languageCode == 'ru'
    ? (correct ? 'Верно' : 'Неверно')
    : (correct ? 'Correct' : 'Incorrect');

void _showFeedback(
  BuildContext context,
  PracticeFeedback feedback,
  VoidCallback next,
) {
  showDialog<void>(
    context: context,
    builder: (sheetContext) => Theme(
      data: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xffe8791b),
          surface: const Color(0xffead9bf),
        ),
        textTheme: Theme.of(context).textTheme.apply(
          bodyColor: const Color(0xff655444),
          displayColor: const Color(0xff655444),
        ),
      ),
      child: Dialog(
        backgroundColor: const Color(0xffead9bf),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(27)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 600,
            maxHeight: MediaQuery.sizeOf(sheetContext).height * .65,
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _feedbackLabel(context, feedback.correct),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: feedback.correct
                              ? const Color(0xff1e5e22)
                              : const Color(0xffa52a2a),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: MaterialLocalizations.of(context)
                          .closeButtonTooltip,
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                Flexible(
                  child: SingleChildScrollView(
                    child: DefaultTextStyle.merge(
                      style: const TextStyle(color: Color(0xff655444)),
                      child: ExplanationPanel(reveal: feedback.reveal),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    key: const Key('feedback-next'),
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      next();
                    },
                    child: Text(AppLocalizations.of(context)!.continueLabel),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
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
