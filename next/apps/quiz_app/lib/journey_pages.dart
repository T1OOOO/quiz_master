part of 'main.dart';

class CatalogPage extends ConsumerStatefulWidget {
  const CatalogPage({super.key, this.quizId, this.round, this.difficulty});
  final String? quizId;
  final int? round;
  final DifficultyBand? difficulty;
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
              .openQuiz(
                widget.quizId!,
                round: widget.round,
                difficulty: widget.difficulty,
              );
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
    final activeQuizId =
        catalog?.quiz.id ??
        (widget.quizId == null ? null : playableQuizId(widget.quizId!));
    ref.listen(journeyProvider.select((s) => s.feedback), (previous, feedback) {
      if (feedback != null && feedback != previous) {
        _showFeedback(
          context,
          feedback,
          controller.nextQuestion,
          _submittedAnswerText(journey),
        );
      }
    });
    final pack = ref
        .watch(discoveryCatalogProvider)
        .asData
        ?.value
        .where((p) => p.id == activeQuizId)
        .firstOrNull;
    final title = pack?.title ?? '';
    if (widget.quizId != null &&
        attempt != null &&
        catalog != null &&
        finish == null &&
        !journey.loading) {
      return SourceScaffold(
        compact: true,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        flex: 4,
                        child: Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 20,
                            height: 1.2,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          widget.round == null
                              ? l10n.allQuestions
                              : l10n.roundLabel(widget.round! + 1),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
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
                            .where((p) => p.id == activeQuizId)
                            .firstOrNull
                            ?.title ??
                        '',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                TextButton(
                  onPressed: () => context.go(
                    Uri(
                      path: '/library',
                      queryParameters: {
                        if (widget.difficulty != null)
                          'difficulty': widget.difficulty!.wireName,
                      },
                    ).toString(),
                  ),
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
                        difficulty: widget.difficulty,
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
                ] else if (attempt != null && finish == null) ...[
                  _QuestionStep(
                    journey: journey,
                    question: _orderedQuestion(
                      catalog,
                      attempt.snapshots[journey.index],
                    ),
                  ),
                ] else if (finish != null) ...[
                  Text(
                    l10n.score(finish.score),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  if (journey.postFinishError != null)
                    _ErrorPanel(
                      message: l10n.resultsLoadError,
                      retryable: journey.postFinishRetryable,
                      onRetry: controller.complete,
                    ),
                  const SizedBox(height: 8),
                  if (widget.quizId != null &&
                      widget.round != null &&
                      widget.round! + 1 <
                          questionRoundCount(catalog.quiz.questions.length))
                    FilledButton(
                      onPressed: () => context.go(
                        _quizLocation(
                          activeQuizId!,
                          widget.round! + 1,
                          widget.difficulty,
                        ),
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
                  TextButton.icon(
                    key: const Key('result-feedback'),
                    onPressed: () => context
                        .findAncestorStateOfType<_FeedbackOverlayState>()
                        ?._open(),
                    icon: const Icon(Icons.support_agent),
                    label: Text(l10n.feedbackSendFeedback),
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

class _QuestionStep extends ConsumerWidget {
  const _QuestionStep({
    required this.journey,
    required this.question,
    this.fitScreen = false,
  });
  final bool fitScreen;
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
    final answered = journey.isAnsweredAt(journey.index);
    final reviewing = answered && journey.feedback == null;
    final reveal =
        journey.feedback?.reveal ??
        (reviewing ? journey.reviewRevealAt(journey.index) : null);
    return Column(
      children: [
        LinearProgressIndicator(
          value: journey.index / attempt.snapshots.length,
          minHeight: 3,
          borderRadius: BorderRadius.circular(8),
        ),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: _QuestionNavigator(journey: journey),
              ),
            ),
            if (MediaQuery.sizeOf(context).width < 360 ||
                MediaQuery.textScalerOf(context).scale(14) > 20)
              IconButton(
                key: const Key('mark-question-uncertain'),
                tooltip: Localizations.localeOf(context).languageCode == 'ru'
                    ? 'Отметить: не уверен'
                    : 'Mark for review',
                isSelected: journey.uncertainIndices.contains(journey.index),
                onPressed: journey.submitting || journey.feedback != null
                    ? null
                    : ref.read(journeyProvider.notifier).toggleUncertain,
                icon: const Icon(Icons.bookmark_border),
                selectedIcon: const Icon(Icons.bookmark),
              )
            else
              TextButton.icon(
                key: const Key('mark-question-uncertain'),
                onPressed: journey.submitting || journey.feedback != null
                    ? null
                    : ref.read(journeyProvider.notifier).toggleUncertain,
                icon: Icon(
                  journey.uncertainIndices.contains(journey.index)
                      ? Icons.bookmark
                      : Icons.bookmark_border,
                ),
                label: Text(
                  Localizations.localeOf(context).languageCode == 'ru'
                      ? 'Не уверен'
                      : 'Mark for review',
                ),
              ),
          ],
        ),
        if (fitScreen)
          Expanded(
            child: SingleChildScrollView(
              key: ValueKey(current.id),
              child: QuestionCard(
                key: ValueKey(current.id),
                question: current,
                submitting:
                    journey.submitting ||
                    answered ||
                    journey.sentByIndex.containsKey(journey.index),
                initialAnswer: journey.stagedByIndex[journey.index],
                reveal: reveal,
                showExplanation: reviewing,
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
                journey.submitting ||
                answered ||
                journey.sentByIndex.containsKey(journey.index),
            initialAnswer: journey.stagedByIndex[journey.index],
            reveal: reveal,
            showExplanation: reviewing,
            onAnswer: (value) =>
                ref.read(journeyProvider.notifier).stage(current.kind, value),
          ),
        if (!answered &&
            !journey.sentByIndex.containsKey(journey.index) &&
            (!fitScreen || current.kind == AnswerKind.multipleChoice))
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed:
                  journey.staged == null ||
                      journey.submitting ||
                      journey.feedback != null
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
        if (journey.error == null &&
            journey.sentByIndex.containsKey(journey.index) &&
            !journey.submitting)
          FilledButton.icon(
            key: const Key('retry-saved-answer'),
            onPressed: ref.read(journeyProvider.notifier).submit,
            icon: const Icon(Icons.sync),
            label: Text(l10n.retry),
          ),
        if (journey.isComplete)
          FilledButton(
            onPressed: journey.submitting
                ? null
                : ref.read(journeyProvider.notifier).complete,
            child: Text(journey.submitting ? l10n.finishing : l10n.finishQuiz),
          ),
      ],
    );
  }
}

class _QuestionNavigator extends ConsumerWidget {
  const _QuestionNavigator({required this.journey});
  final JourneyState journey;
  @override
  Widget build(BuildContext context, WidgetRef ref) => TextButton.icon(
    key: const Key('question-navigation-menu'),
    icon: const Icon(Icons.grid_view_rounded, size: 19),
    label: Text('${journey.index + 1} / ${journey.attempt!.snapshots.length}'),
    onPressed: journey.submitting || journey.feedback != null
        ? null
        : () => showModalBottomSheet<void>(
            context: context,
            showDragHandle: true,
            useSafeArea: true,
            isScrollControlled: true,
            builder: (context) => ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * .75,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _questionNavigatorLabel(context),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (
                          var index = 0;
                          index < journey.attempt!.snapshots.length;
                          index++
                        )
                          _QuestionNavigatorButton(
                            index: index,
                            selected: journey.index == index,
                            progress: journey.progressAt(index),
                            marked: journey.uncertainIndices.contains(index),
                            enabled: true,
                            onSelected: () => Navigator.pop(context),
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

class _QuestionNavigatorButton extends ConsumerWidget {
  const _QuestionNavigatorButton({
    required this.index,
    required this.selected,
    required this.progress,
    required this.enabled,
    required this.marked,
    this.onSelected,
  });

  final int index;
  final bool selected;
  final QuestionProgress progress;
  final bool enabled;
  final bool marked;
  final VoidCallback? onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Tooltip(
    message:
        '${index + 1}: ${_questionProgressLabel(context, progress)}${marked ? ' ★' : ''}',
    child: Semantics(
      button: true,
      selected: selected,
      label:
          '${index + 1}: ${_questionProgressLabel(context, progress)}${marked ? ' · ${Localizations.localeOf(context).languageCode == 'ru' ? 'не уверен' : 'marked for review'}' : ''}',
      child: selected
          ? FilledButton.tonal(
              key: Key('question-nav-$index'),
              style: _questionNavigatorButtonStyle,
              onPressed: enabled
                  ? () {
                      ref.read(journeyProvider.notifier).goToQuestion(index);
                      onSelected?.call();
                    }
                  : null,
              child: _questionNavigatorButtonContent(index, progress, marked),
            )
          : OutlinedButton(
              key: Key('question-nav-$index'),
              style: _questionNavigatorButtonStyle,
              onPressed: enabled
                  ? () {
                      ref.read(journeyProvider.notifier).goToQuestion(index);
                      onSelected?.call();
                    }
                  : null,
              child: _questionNavigatorButtonContent(index, progress, marked),
            ),
    ),
  );
}

final _questionNavigatorButtonStyle = ButtonStyle(
  minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
  padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 6)),
  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
);

Widget _questionNavigatorButtonContent(
  int index,
  QuestionProgress progress,
  bool marked,
) => Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    _questionProgressIcon(progress),
    const SizedBox(width: 2),
    Text('${index + 1}'),
    if (marked) const Icon(Icons.bookmark, size: 14),
  ],
);

Widget _questionProgressIcon(QuestionProgress progress) =>
    Icon(switch (progress) {
      QuestionProgress.answered => Icons.check_circle,
      QuestionProgress.uncertain => Icons.help_outline,
      QuestionProgress.unanswered => Icons.circle_outlined,
    }, size: 18);

String _questionNavigatorLabel(BuildContext context) =>
    Localizations.localeOf(context).languageCode == 'ru'
    ? 'Навигация по вопросам'
    : 'Question navigation';

String _questionProgressLabel(BuildContext context, QuestionProgress progress) {
  final russian = Localizations.localeOf(context).languageCode == 'ru';
  return switch (progress) {
    QuestionProgress.answered => russian ? 'отвечен' : 'answered',
    QuestionProgress.uncertain => russian ? 'не уверен' : 'uncertain',
    QuestionProgress.unanswered => russian ? 'без ответа' : 'unanswered',
  };
}

String _feedbackLabel(BuildContext context, bool correct) =>
    Localizations.localeOf(context).languageCode == 'ru'
    ? (correct ? 'Верно' : 'Неверно')
    : (correct ? 'Correct' : 'Incorrect');

String? _submittedAnswerText(JourneyState journey) {
  final answer =
      journey.sentByIndex[journey.index] ??
      journey.stagedByIndex[journey.index];
  final attempt = journey.attempt, catalog = journey.catalog;
  if (answer is NormalizedTextAnswer) return answer.text;
  if (attempt == null || catalog == null) return null;
  final question = _orderedQuestion(catalog, attempt.snapshots[journey.index]);
  final ids = switch (answer) {
    SingleChoiceAnswer(:final optionId) => {optionId},
    MultipleChoiceAnswer(:final optionIds) => optionIds,
    _ => <String>{},
  };
  return question?.options
      .where((option) => ids.contains(option.id))
      .map((option) => option.text)
      .join(', ');
}

void _showFeedback(
  BuildContext context,
  PracticeFeedback feedback,
  VoidCallback next,
  String? answer,
) {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) =>
        _FeedbackDialog(feedback: feedback, next: next, answer: answer),
  );
}

class _FeedbackDialog extends StatelessWidget {
  const _FeedbackDialog({
    required this.feedback,
    required this.next,
    this.answer,
  });
  final PracticeFeedback feedback;
  final VoidCallback next;
  final String? answer;
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ru = Localizations.localeOf(context).languageCode == 'ru';
    final colors = Theme.of(context).colorScheme;
    void advance() {
      Navigator.pop(context);
      next();
    }

    return PopScope(
      canPop: false,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 600,
            maxHeight: MediaQuery.sizeOf(context).height * .8,
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      feedback.correct ? Icons.check_circle : Icons.cancel,
                      color: feedback.correct
                          ? const Color(0xff2d966a)
                          : colors.error,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _feedbackLabel(context, feedback.correct),
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (!feedback.correct)
                      IconButton(
                        tooltip: MaterialLocalizations.of(context)
                            .closeButtonTooltip,
                        onPressed: advance,
                        icon: const Icon(Icons.close),
                      ),
                  ],
                ),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (!feedback.correct &&
                            answer != null &&
                            answer!.isNotEmpty)
                          Container(
                            key: const Key('feedback-your-answer'),
                            margin: const EdgeInsets.only(top: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colors.errorContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ru ? 'Ваш ответ' : 'Your answer',
                                  style: TextStyle(
                                    color: colors.onErrorContainer,
                                  ),
                                ),
                                Text(
                                  answer!,
                                  style: TextStyle(
                                    color: colors.onErrorContainer,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ExplanationPanel(reveal: feedback.reveal),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  key: const Key('feedback-next'),
                  onPressed: advance,
                  child: Text(l10n.continueLabel),
                ),
              ],
            ),
          ),
        ),
      ),
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
    media: source.media,
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
