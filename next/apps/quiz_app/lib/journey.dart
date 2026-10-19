part of 'main.dart';

final quizApiProvider = Provider<QuizApiClient>(
  (ref) => QuizApiClient(
    baseUri: Uri.parse(
      const String.fromEnvironment(
        'QM_API_BASE_URL',
        defaultValue: 'http://127.0.0.1:8080',
      ),
    ),
  ),
);
final journeyProvider = NotifierProvider<JourneyController, JourneyState>(
  JourneyController.new,
);

// Reviewed minimum-20 aliases.  Resolve only these known historical routes
// before making a practice request; a response for any other ID stays strict.
const legacyPlayableQuizAliases = <String, String>{
  'acting-craft-20261014': 'cinema-people-20261011',
  'cinema-encore-20261011': 'cinema-people-20261011',
  'film-craft-20261013': 'cinema-people-20261011',
  'screen-song-20261014': 'cinema-people-20261011',
  'lotr': 'lotr-trilogy',
  'lotr-fellowship-100': 'lotr-trilogy',
  'lotr-return-king-bts-100': 'lotr-trilogy',
  'lotr-two-towers-lore-100': 'lotr-trilogy',
  'home-alone-2-part-1': 'home-alone-2',
  'home-alone-2-part-2': 'home-alone-2',
  'home-alone-2-part-3': 'home-alone-2',
  'theme-pixar': 'animation-studios-pixar-dreamworks',
  'theme-dreamworks': 'animation-studios-pixar-dreamworks',
  'theme-game-of-thrones': 'theme-tv-series',
  'theme-star-wars': 'cinema-science-fiction-worlds',
  'theme-terminator': 'cinema-science-fiction-worlds',
  'gastronomy-cheeses-and-dairy': 'gastronomy-animal-products',
  'gastronomy-meat-and-fish': 'gastronomy-animal-products',
  'gastronomy-2': 'gastronomy-1',
  'music-encore-20261011': 'music-people-20261011',
  'music-craft-20261013': 'music-people-20261011',
  'cats-biology-anatomy-part-1': 'cats-biology-anatomy',
  'cats-biology-anatomy-part-2': 'cats-biology-anatomy',
  'cats-breeds-man-made': 'cats-breeds',
  'cats-breeds-natural-and-ancient-part-1': 'cats-breeds',
  'cats-breeds-natural-and-ancient-part-2': 'cats-breeds',
  'cats-history-ancient-egypt': 'cats-history-culture',
  'cats-history-famous-and-culture': 'cats-history-culture',
  'cats-history-mythology': 'cats-history-culture',
  'cats-history-other-eras': 'cats-history-culture',
  'cats-trivia-records-and-general-part-1': 'cats-trivia-records',
  'cats-trivia-records-and-general-part-2': 'cats-trivia-records',
  'cats-trivia-records-and-general-part-3': 'cats-trivia-records',
  'cats-trivia-records-and-general-part-4': 'cats-trivia-records',
  'dogs-biology-anatomy-part-1': 'dogs-biology-anatomy',
  'dogs-biology-anatomy-part-2': 'dogs-biology-anatomy',
  'dogs-breeds-sporting-hounds': 'dogs-breeds',
  'dogs-breeds-toy-terrier-rare-part-1': 'dogs-breeds',
  'dogs-breeds-toy-terrier-rare-part-2': 'dogs-breeds',
  'dogs-breeds-working-herding': 'dogs-breeds',
  'dogs-history-ancient-world': 'dogs-history-culture',
  'dogs-history-famous-and-service': 'dogs-history-culture',
  'dogs-history-mythology': 'dogs-history-culture',
  'philias-abstract': 'philias-abstract-other',
  'philias-other': 'philias-abstract-other',
  'philias-animals-part-1': 'philias-animals',
  'philias-animals-part-2': 'philias-animals',
  'philias-nature-part-2': 'philias-nature',
  'philias-people-part-1': 'philias-people',
  'philias-people-part-2': 'philias-people',
  'vocabulary-archaisms': 'vocabulary-historical',
  'vocabulary-church-slavonic': 'vocabulary-historical',
  'vocabulary-art-culture': 'vocabulary-art-intellectual',
  'vocabulary-intellectual': 'vocabulary-art-intellectual',
  'phobias-nature': 'phobias-general',
  'gastronomy-miscellaneous-off-topic': 'prep-capitals-americas',
};

String playableQuizId(String routeQuizId) =>
    legacyPlayableQuizAliases[routeQuizId] ?? routeQuizId;

enum QuestionProgress { answered, unanswered, uncertain }

class JourneyState {
  const JourneyState({
    this.loading = false,
    this.error,
    this.errorRetryable = false,
    this.postFinishError,
    this.postFinishRetryable = false,
    this.session,
    this.catalog,
    this.attempt,
    this.index = 0,
    this.staged,
    this.stagedByIndex = const {},
    this.sentByIndex = const {},
    this.uncertainIndices = const {},
    this.feedbackByIndex = const {},
    this.submitting = false,
    this.finish,
    this.reveals = const [],
    this.receipts = const [],
    this.feedback,
  });
  final bool loading;
  final String? error;
  final bool errorRetryable;
  final String? postFinishError;
  final bool postFinishRetryable;
  final GuestSession? session;
  final Catalog? catalog;
  final Attempt? attempt;
  final int index;
  final StagedAnswer? staged;
  final Map<int, StagedAnswer> stagedByIndex;
  final Map<int, StagedAnswer> sentByIndex;
  final Set<int> uncertainIndices;
  final Map<int, PracticeFeedback> feedbackByIndex;
  final bool submitting;
  final Finish? finish;
  final List<Reveal> reveals;
  final List<Receipt> receipts;
  final PracticeFeedback? feedback;
  JourneyState copyWith({
    bool? loading,
    String? error,
    bool? errorRetryable,
    String? postFinishError,
    bool? postFinishRetryable,
    GuestSession? session,
    Catalog? catalog,
    Attempt? attempt,
    int? index,
    StagedAnswer? staged,
    Map<int, StagedAnswer>? stagedByIndex,
    Map<int, StagedAnswer>? sentByIndex,
    Set<int>? uncertainIndices,
    Map<int, PracticeFeedback>? feedbackByIndex,
    bool? submitting,
    Finish? finish,
    List<Reveal>? reveals,
    List<Receipt>? receipts,
    PracticeFeedback? feedback,
  }) => JourneyState(
    loading: loading ?? this.loading,
    error: error,
    errorRetryable: errorRetryable ?? this.errorRetryable,
    postFinishError: postFinishError,
    postFinishRetryable: postFinishRetryable ?? this.postFinishRetryable,
    session: session ?? this.session,
    catalog: catalog ?? this.catalog,
    attempt: attempt ?? this.attempt,
    index: index ?? this.index,
    staged: staged,
    stagedByIndex: stagedByIndex ?? this.stagedByIndex,
    sentByIndex: sentByIndex ?? this.sentByIndex,
    uncertainIndices: uncertainIndices ?? this.uncertainIndices,
    feedbackByIndex: feedbackByIndex ?? this.feedbackByIndex,
    submitting: submitting ?? this.submitting,
    finish: finish ?? this.finish,
    reveals: reveals ?? this.reveals,
    receipts: receipts ?? this.receipts,
    feedback: feedback,
  );

  bool isAnsweredAt(int questionIndex) {
    final attempt = this.attempt;
    if (attempt == null ||
        questionIndex < 0 ||
        questionIndex >= attempt.snapshots.length) {
      return false;
    }
    final questionId = attempt.snapshots[questionIndex].questionId;
    return receipts.any((receipt) => receipt.questionId == questionId);
  }

  QuestionProgress progressAt(int questionIndex) {
    if (isAnsweredAt(questionIndex)) return QuestionProgress.answered;
    return isUncertainAt(questionIndex)
        ? QuestionProgress.uncertain
        : QuestionProgress.unanswered;
  }

  int? get firstUnansweredIndex {
    final attempt = this.attempt;
    if (attempt == null) return null;
    for (var index = 0; index < attempt.snapshots.length; index++) {
      if (progressAt(index) == QuestionProgress.unanswered) return index;
    }
    return null;
  }

  int? get firstPendingIndex {
    final attempt = this.attempt;
    if (attempt == null) return null;
    for (var index = 0; index < attempt.snapshots.length; index++) {
      if (!isAnsweredAt(index)) return index;
    }
    return null;
  }

  bool get isComplete => attempt != null && firstPendingIndex == null;

  bool isUncertainAt(int index) =>
      uncertainIndices.contains(index) ||
      (!isAnsweredAt(index) && stagedByIndex.containsKey(index));

  bool get canComplete => isComplete;

  StagedAnswer? answerForSubmissionAt(int questionIndex) =>
      sentByIndex[questionIndex] ?? stagedByIndex[questionIndex];

  Reveal? reviewRevealAt(int questionIndex) =>
      feedbackByIndex[questionIndex]?.reveal;
}

class JourneyController extends Notifier<JourneyState> {
  String? _quizId;
  int? _round;
  DifficultyBand? _difficulty;
  int _generation = 0;
  @override
  JourneyState build() => const JourneyState();
  Future<void> openQuiz(
    String id, {
    int? round,
    DifficultyBand? difficulty,
  }) async {
    final generation = ++_generation;
    final canonicalId = playableQuizId(id);
    _quizId = canonicalId;
    _round = round;
    _difficulty = difficulty;
    state = JourneyState(session: state.session, loading: true);
    try {
      final api = ref.read(quizApiProvider);
      final results = await Future.wait<Object>([
        state.session == null
            ? api.bootstrap('Guest')
            : Future.value(state.session!),
        api.catalog(quizId: canonicalId, difficulty: difficulty),
      ]);
      final session = results[0] as GuestSession;
      final catalog = results[1] as Catalog;
      if (generation != _generation) return;
      if (catalog.quiz.id != canonicalId) {
        throw const FormatException('selected quiz mismatch');
      }
      state = state.copyWith(session: session, catalog: catalog);
      await start();
    } on ApiClientException catch (e) {
      if (generation != _generation) return;
      state = state.copyWith(
        loading: false,
        error: e.code,
        errorRetryable: e.retryable,
      );
    } on FormatException {
      if (generation != _generation) return;
      state = state.copyWith(
        loading: false,
        error: 'invalid_response',
        errorRetryable: false,
      );
    }
  }

  Future<void> bootstrap(String name) async {
    final generation = ++_generation;
    _quizId = null;
    _round = null;
    _difficulty = null;
    state = state.copyWith(loading: true, error: null, errorRetryable: false);
    try {
      final session = await ref.read(quizApiProvider).bootstrap(name);
      if (generation != _generation) return;
      state = state.copyWith(loading: true, session: session);
      final catalog = await ref
          .read(quizApiProvider)
          .catalog(quizId: _quizId, difficulty: _difficulty);
      if (generation != _generation) return;
      state = state.copyWith(
        loading: false,
        session: session,
        catalog: catalog,
      );
    } on ApiClientException catch (e) {
      if (generation != _generation) return;
      state = state.copyWith(
        loading: false,
        error: e.code,
        errorRetryable: e.retryable,
      );
    } on FormatException {
      if (generation != _generation) return;
      state = state.copyWith(
        loading: false,
        error: 'invalid_response',
        errorRetryable: false,
      );
    }
  }

  Future<void> reloadCatalog() async {
    if (state.session == null || state.loading) return;
    final generation = _generation;
    state = state.copyWith(loading: true, error: null, errorRetryable: false);
    try {
      final catalog = await ref
          .read(quizApiProvider)
          .catalog(quizId: _quizId, difficulty: _difficulty);
      if (generation != _generation) return;
      state = state.copyWith(loading: false, catalog: catalog);
    } on ApiClientException catch (e) {
      if (generation != _generation) return;
      state = state.copyWith(
        loading: false,
        error: e.code,
        errorRetryable: e.retryable,
      );
    } on FormatException {
      if (generation != _generation) return;
      state = state.copyWith(
        loading: false,
        error: 'invalid_response',
        errorRetryable: false,
      );
    }
  }

  Future<void> start() async {
    final generation = ++_generation;
    final catalog = state.catalog;
    if (catalog == null) return;
    state = state.copyWith(loading: true, error: null, errorRetryable: false);
    try {
      final attempt = await ref
          .read(quizApiProvider)
          .startAttempt(
            quizId: _quizId,
            round: _round,
            difficulty: _difficulty,
            practice: _quizId != null,
          );
      validateAttemptCatalog(attempt, catalog);
      if (generation != _generation) return;
      state = state.copyWith(
        loading: false,
        attempt: attempt,
        index: 0,
        staged: null,
        stagedByIndex: const {},
        sentByIndex: const {},
        uncertainIndices: const {},
        feedbackByIndex: const {},
        receipts: const [],
        feedback: null,
        finish: null,
        reveals: const [],
      );
    } on ApiClientException catch (e) {
      if (generation != _generation) return;
      state = state.copyWith(
        loading: false,
        error: e.code,
        errorRetryable: e.retryable,
      );
    } on FormatException {
      if (generation != _generation) return;
      state = state.copyWith(
        loading: false,
        error: 'invalid_response',
        errorRetryable: false,
      );
    }
  }

  void toggleUncertain() {
    final attempt = state.attempt;
    if (attempt == null ||
        state.submitting ||
        state.finish != null ||
        state.index < 0 ||
        state.index >= attempt.snapshots.length) {
      return;
    }
    final marked = Set<int>.of(state.uncertainIndices);
    marked.contains(state.index)
        ? marked.remove(state.index)
        : marked.add(state.index);
    state = state.copyWith(
      staged: state.staged,
      feedback: state.feedback,
      error: state.error,
      uncertainIndices: marked,
    );
  }

  void stage(AnswerKind kind, Object value) {
    if (state.submitting ||
        state.feedback != null ||
        state.isAnsweredAt(state.index) ||
        state.sentByIndex.containsKey(state.index)) {
      return;
    }
    final staged = StagedAnswer.fromInput(kind, value);
    state = state.copyWith(
      staged: staged,
      stagedByIndex: {...state.stagedByIndex, state.index: staged},
    );
    if (_quizId != null && kind != AnswerKind.multipleChoice) submit();
  }

  void goToQuestion(int index) {
    final attempt = state.attempt;
    if (attempt == null ||
        state.submitting ||
        state.feedback != null ||
        index < 0 ||
        index >= attempt.snapshots.length) {
      return;
    }
    state = state.copyWith(
      index: index,
      staged: state.stagedByIndex[index],
      feedback: null,
    );
  }

  void nextQuestion() {
    if (state.feedback == null || state.submitting) return;
    final attempt = state.attempt;
    if (attempt == null) return;
    state = state.copyWith(
      index: state.firstPendingIndex ?? state.index,
      staged: state.firstPendingIndex == null
          ? null
          : state.stagedByIndex[state.firstPendingIndex!],
      feedback: null,
    );
  }

  Future<void> submit() async {
    final generation = _generation;
    final attempt = state.attempt;
    final index = state.index;
    final quizId = _quizId;
    final staged = state.answerForSubmissionAt(index) ?? state.staged;
    if (attempt == null ||
        (staged == null && !state.isAnsweredAt(index)) ||
        state.submitting ||
        state.finish != null ||
        index < 0 ||
        index >= attempt.snapshots.length ||
        (state.isAnsweredAt(index) &&
            (quizId == null || state.feedbackByIndex.containsKey(index)))) {
      return;
    }
    final snapshot = attempt.snapshots[index];
    bool stale() => generation != _generation || state.attempt != attempt;
    state = state.copyWith(
      submitting: true,
      error: null,
      errorRetryable: false,
    );
    try {
      if (!state.isAnsweredAt(index)) {
        final answer = staged!;
        state = state.copyWith(
          staged: answer,
          stagedByIndex: {...state.stagedByIndex, index: answer},
          sentByIndex: {...state.sentByIndex, index: answer},
        );
        final receipt = await ref
            .read(quizApiProvider)
            .submitAnswer(
              attempt,
              snapshot,
              answer,
              idempotencyKey:
                  'a-${sha256.convert(utf8.encode('${attempt.id}/${snapshot.questionId}'))}',
            );
        if (stale()) return;
        state = state.copyWith(
          staged: answer,
          submitting: true,
          receipts: [...state.receipts, receipt],
          sentByIndex: Map.of(state.sentByIndex)..remove(index),
        );
      }
      if (quizId != null) {
        final feedback = await ref
            .read(quizApiProvider)
            .feedback(attempt, snapshot, quizId);
        if (stale()) return;
        state = state.copyWith(
          staged: staged,
          submitting: false,
          feedback: feedback,
          feedbackByIndex: {...state.feedbackByIndex, index: feedback},
        );
        return;
      }
      final next = state.firstPendingIndex ?? index;
      state = state.copyWith(
        submitting: false,
        index: next,
        staged: state.stagedByIndex[next],
      );
    } on ApiClientException catch (e) {
      if (stale()) return;
      state = state.copyWith(
        staged: staged,
        submitting: false,
        error: e.code,
        errorRetryable: e.retryable || state.sentByIndex.containsKey(index),
      );
    } on FormatException {
      if (stale()) return;
      state = state.copyWith(
        staged: staged,
        submitting: false,
        error: 'invalid_response',
        errorRetryable: true,
      );
    }
  }

  Future<void> complete() async {
    final generation = _generation;
    final attempt = state.attempt;
    final catalog = state.catalog;
    if (attempt == null ||
        catalog == null ||
        state.submitting ||
        !state.canComplete) {
      return;
    }
    state = state.copyWith(
      submitting: true,
      error: null,
      errorRetryable: false,
      postFinishError: null,
      postFinishRetryable: false,
    );
    try {
      final finish =
          state.finish ?? await ref.read(quizApiProvider).finish(attempt);
      if (generation != _generation || state.attempt != attempt) return;
      validateFinishReceipts(finish, state.receipts);
      // Persist the server result before a reveal request so retry never posts
      // finish a second time.
      state = state.copyWith(submitting: true, finish: finish);
      final reveals = await ref
          .read(quizApiProvider)
          .reveals(attempt, finish, expectedQuizId: catalog.quiz.id);
      if (generation != _generation || state.attempt != attempt) return;
      state = state.copyWith(
        submitting: false,
        finish: finish,
        reveals: reveals,
        postFinishError: null,
        postFinishRetryable: false,
      );
    } on ApiClientException catch (e) {
      if (generation != _generation || state.attempt != attempt) return;
      state = state.finish == null
          ? state.copyWith(
              submitting: false,
              error: e.code,
              errorRetryable: e.retryable,
            )
          : state.copyWith(
              submitting: false,
              error: null,
              postFinishError: e.code,
              postFinishRetryable: e.retryable,
            );
    } on FormatException {
      if (generation != _generation || state.attempt != attempt) return;
      state = state.finish == null
          ? state.copyWith(
              submitting: false,
              error: 'invalid_response',
              errorRetryable: false,
            )
          : state.copyWith(
              submitting: false,
              error: null,
              postFinishError: 'invalid_response',
              postFinishRetryable: false,
            );
    }
  }

  Future<void> retry() async {
    if (state.postFinishError != null) return complete();
    if (state.catalog == null) return reloadCatalog();
    if (state.attempt == null) return start();
    if (_quizId != null &&
        state.isAnsweredAt(state.index) &&
        !state.feedbackByIndex.containsKey(state.index)) {
      return submit();
    }
    if (!state.isComplete) return submit();
    return complete();
  }

  void newQuiz() {
    ++_generation;
    state = JourneyState(session: state.session, catalog: state.catalog);
  }
}
