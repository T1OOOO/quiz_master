import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/main.dart';

final _revision = Revision(1, 'a' * 64);
final _questions = [
  for (var i = 0; i < 2; i++)
    PublicQuestion(
      quizId: 'lotr-trilogy',
      id: 'lotr-$i',
      revision: _revision,
      stem: 'Question $i',
      kind: AnswerKind.multipleChoice,
      options: const [
        PublicOption(id: 'a', text: 'A'),
        PublicOption(id: 'b', text: 'B'),
        PublicOption(id: 'c', text: 'C'),
        PublicOption(id: 'd', text: 'D'),
      ],
    ),
];
final _catalog = Catalog(
  bundleVersion: 'v1',
  bundleSha256: 'b' * 64,
  quiz: PublicQuiz(id: 'lotr-trilogy', questions: _questions),
);

class _AliasApi extends QuizApiClient {
  _AliasApi() : super(baseUri: Uri.parse('http://127.0.0.1:8080'));
  final requestedCatalogIds = <String?>[];
  String? feedbackQuizId;
  @override
  Future<GuestSession> bootstrap(String _) async => GuestSession(
    participantId: 'p-${'0' * 32}',
    displayName: 'Guest',
    token: 'fixture',
    expiresAt: DateTime.utc(2030),
  );
  @override
  Future<Catalog> catalog({String? quizId, DifficultyBand? difficulty}) async {
    requestedCatalogIds.add(quizId);
    return _catalog;
  }
  @override
  Future<Attempt> startAttempt({String? quizId, int? round, DifficultyBand? difficulty, bool practice = false}) async => Attempt(
    id: 'attempt', participantId: 'p-${'0' * 32}', bundleVersion: 'v1', bundleSha256: 'b' * 64,
    snapshots: [for (final q in _questions) AttemptSnapshot(questionId: q.id, revision: _revision, optionOrder: const ['a','b','c','d'])],
  );
  @override
  Future<Receipt> submitAnswer(Attempt a, AttemptSnapshot q, StagedAnswer answer, {required String idempotencyKey}) async => Receipt(
    id: 'receipt-${q.questionId}', attemptId: a.id, participantId: a.participantId, questionId: q.questionId, revision: q.revision,
  );
  @override
  Future<PracticeFeedback> feedback(Attempt a, AttemptSnapshot q, String quizId) async {
    feedbackQuizId = quizId;
    return PracticeFeedback(true, Reveal(answer: 'B', explanation: 'Explanation', quizId: quizId, questionId: q.questionId, revision: q.revision, correctOptionIds: const {'b'}));
  }
}

void main() {
  test('reviewed alias opens canonical practice feedback', () async {
    expect(playableQuizId('lotr'), 'lotr-trilogy');
    final api = _AliasApi();
    final container = ProviderContainer(overrides: [quizApiProvider.overrideWithValue(api)]);
    addTearDown(container.dispose);
    final controller = container.read(journeyProvider.notifier);
    await controller.openQuiz('lotr');
    expect(api.requestedCatalogIds, ['lotr-trilogy']);
    expect(container.read(journeyProvider).error, isNull);
    controller.stage(AnswerKind.multipleChoice, {'b'});
    await controller.submit();
    expect(api.feedbackQuizId, 'lotr-trilogy');
  });

  test('an unknown route still rejects a different server quiz ID', () async {
    final api = _AliasApi();
    final container = ProviderContainer(
      overrides: [quizApiProvider.overrideWithValue(api)],
    );
    addTearDown(container.dispose);
    await container.read(journeyProvider.notifier).openQuiz('unknown-server-id');
    expect(api.requestedCatalogIds, ['unknown-server-id']);
    expect(container.read(journeyProvider).error, 'invalid_response');
  });
}
