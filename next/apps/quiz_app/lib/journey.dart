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
    this.submitting = false,
    this.finish,
    this.reveals = const [],
    this.receipts = const [],
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
  final bool submitting;
  final Finish? finish;
  final List<Reveal> reveals;
  final List<Receipt> receipts;
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
    bool? submitting,
    Finish? finish,
    List<Reveal>? reveals,
    List<Receipt>? receipts,
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
    submitting: submitting ?? this.submitting,
    finish: finish ?? this.finish,
    reveals: reveals ?? this.reveals,
    receipts: receipts ?? this.receipts,
  );
}

class JourneyController extends Notifier<JourneyState> {
  @override
  JourneyState build() => const JourneyState();
  Future<void> bootstrap(String name) async {
    state = state.copyWith(loading: true, error: null, errorRetryable: false);
    try {
      final session = await ref.read(quizApiProvider).bootstrap(name);
      state = state.copyWith(loading: true, session: session);
      final catalog = await ref.read(quizApiProvider).catalog();
      state = state.copyWith(
        loading: false,
        session: session,
        catalog: catalog,
      );
    } on ApiClientException catch (e) {
      state = state.copyWith(
        loading: false,
        error: e.code,
        errorRetryable: e.retryable,
      );
    } on FormatException {
      state = state.copyWith(
        loading: false,
        error: 'invalid_response',
        errorRetryable: false,
      );
    }
  }

  Future<void> reloadCatalog() async {
    if (state.session == null || state.loading) return;
    state = state.copyWith(loading: true, error: null, errorRetryable: false);
    try {
      final catalog = await ref.read(quizApiProvider).catalog();
      state = state.copyWith(loading: false, catalog: catalog);
    } on ApiClientException catch (e) {
      state = state.copyWith(
        loading: false,
        error: e.code,
        errorRetryable: e.retryable,
      );
    } on FormatException {
      state = state.copyWith(
        loading: false,
        error: 'invalid_response',
        errorRetryable: false,
      );
    }
  }

  Future<void> start() async {
    final catalog = state.catalog;
    if (catalog == null) return;
    state = state.copyWith(loading: true, error: null, errorRetryable: false);
    try {
      final attempt = await ref.read(quizApiProvider).startAttempt();
      validateAttemptCatalog(attempt, catalog);
      state = state.copyWith(loading: false, attempt: attempt, index: 0);
    } on ApiClientException catch (e) {
      state = state.copyWith(
        loading: false,
        error: e.code,
        errorRetryable: e.retryable,
      );
    } on FormatException {
      state = state.copyWith(
        loading: false,
        error: 'invalid_response',
        errorRetryable: false,
      );
    }
  }

  void stage(AnswerKind kind, Object value) {
    if (state.submitting) return;
    state = state.copyWith(staged: StagedAnswer.fromInput(kind, value));
  }

  Future<void> submit() async {
    final attempt = state.attempt;
    final staged = state.staged;
    if (attempt == null ||
        staged == null ||
        state.submitting ||
        state.index >= attempt.snapshots.length) {
      return;
    }
    state = state.copyWith(
      submitting: true,
      error: null,
      errorRetryable: false,
    );
    try {
      final receipt = await ref
          .read(quizApiProvider)
          .submitAnswer(
            attempt,
            attempt.snapshots[state.index],
            staged,
            idempotencyKey: 'a-${DateTime.now().microsecondsSinceEpoch}',
          );
      state = state.copyWith(
        submitting: false,
        index: state.index + 1,
        staged: null,
        receipts: [...state.receipts, receipt],
      );
    } on ApiClientException catch (e) {
      state = state.copyWith(
        submitting: false,
        error: e.code,
        errorRetryable: e.retryable,
      );
    } on FormatException {
      state = state.copyWith(
        submitting: false,
        error: 'invalid_response',
        errorRetryable: false,
      );
    }
  }

  Future<void> complete() async {
    final attempt = state.attempt;
    final catalog = state.catalog;
    if (attempt == null || catalog == null || state.submitting) return;
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
      validateFinishReceipts(finish, state.receipts);
      // Persist the server result before a reveal request so retry never posts
      // finish a second time.
      state = state.copyWith(submitting: true, finish: finish);
      final reveals = await ref
          .read(quizApiProvider)
          .reveals(attempt, finish, expectedQuizId: catalog.quiz.id);
      state = state.copyWith(
        submitting: false,
        finish: finish,
        reveals: reveals,
        postFinishError: null,
        postFinishRetryable: false,
      );
    } on ApiClientException catch (e) {
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
    if (state.index < state.attempt!.snapshots.length) return submit();
    return complete();
  }

  void newQuiz() {
    state = JourneyState(session: state.session, catalog: state.catalog);
  }
}
