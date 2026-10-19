import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/main.dart';

final revision = Revision(1, 'a' * 64);
final questions = [
  for (var i = 0; i < 2; i++)
    PublicQuestion(
      quizId: 'quiz-test',
      id: 'question-$i',
      revision: revision,
      stem: 'Вопрос $i',
      kind: AnswerKind.multipleChoice,
      options: [
        for (final id in ['a', 'b', 'c', 'd']) PublicOption(id: id, text: id),
      ],
    ),
];
final fixtureCatalog = Catalog(
  bundleVersion: 'v1',
  bundleSha256: 'b' * 64,
  quiz: PublicQuiz(id: 'quiz-test', questions: questions),
);
Attempt makeAttempt(int id) => Attempt(
  id: 'attempt-$id',
  participantId: 'p-${'0' * 32}',
  bundleVersion: 'v1',
  bundleSha256: 'b' * 64,
  snapshots: [
    for (final q in questions)
      AttemptSnapshot(
        questionId: q.id,
        revision: revision,
        optionOrder: const ['a', 'b', 'c', 'd'],
      ),
  ],
);
Receipt receipt(Attempt a, AttemptSnapshot q) => Receipt(
  id: 'receipt-${q.questionId}',
  attemptId: a.id,
  participantId: a.participantId,
  questionId: q.questionId,
  revision: revision,
);

class TestApi extends QuizApiClient {
  TestApi() : super(baseUri: Uri.parse('http://127.0.0.1:8080'));
  int starts = 0, feedbacks = 0, finishes = 0;
  bool failAnswer = false, failFeedback = false;
  Completer<void>? answerGate, startGate;
  final sent = <Map<String, Object>>[];
  final keys = <String>[];
  @override
  Future<GuestSession> bootstrap(String name) async => GuestSession(
    participantId: 'p-${'0' * 32}',
    displayName: name,
    token: 'fixture-only',
    expiresAt: DateTime.utc(2030),
  );
  @override
  Future<Catalog> catalog({String? quizId, DifficultyBand? difficulty}) async =>
      catalogValue;
  Catalog get catalogValue => fixtureCatalog;
  @override
  Future<Attempt> startAttempt({
    String? quizId,
    int? round,
    DifficultyBand? difficulty,
    bool practice = false,
  }) async {
    final id = ++starts;
    if (startGate != null) await startGate!.future;
    return makeAttempt(id);
  }

  @override
  Future<Receipt> submitAnswer(
    Attempt a,
    AttemptSnapshot q,
    StagedAnswer answer, {
    required String idempotencyKey,
  }) async {
    sent.add(answer.toJson());
    keys.add(idempotencyKey);
    if (answerGate != null) await answerGate!.future;
    if (failAnswer) {
      failAnswer = false;
      throw const FormatException('accepted response was damaged');
    }
    return receipt(a, q);
  }

  @override
  Future<PracticeFeedback> feedback(
    Attempt a,
    AttemptSnapshot q,
    String quizId,
  ) async {
    feedbacks++;
    if (failFeedback) {
      failFeedback = false;
      throw const ApiClientException('network', retryable: true);
    }
    return PracticeFeedback(
      true,
      Reveal(
        answer: 'b',
        explanation: 'Разбор',
        quizId: quizId,
        questionId: q.questionId,
        revision: revision,
        correctOptionIds: const {'b'},
      ),
    );
  }

  @override
  Future<Finish> finish(Attempt a) {
    finishes++;
    throw StateError('unexpected finish');
  }
}

class LoadedJourney extends JourneyController {
  LoadedJourney(this.initial);
  final JourneyState initial;
  @override
  JourneyState build() => initial;
  @override
  Future<void> openQuiz(
    String id, {
    int? round,
    DifficultyBand? difficulty,
  }) async {}
}

void main() {
  test(
    'a player can mark an unanswered or accepted question for review',
    () async {
      final api = TestApi();
      final c = ProviderContainer(
        overrides: [quizApiProvider.overrideWithValue(api)],
      );
      addTearDown(c.dispose);
      final controller = c.read(journeyProvider.notifier);
      await controller.bootstrap('Игрок');
      await controller.start();
      controller.toggleUncertain();
      expect(c.read(journeyProvider).progressAt(0), QuestionProgress.uncertain);
      controller.stage(AnswerKind.multipleChoice, {'b'});
      await controller.submit();
      controller.goToQuestion(0);
      expect(c.read(journeyProvider).isAnsweredAt(0), isTrue);
      expect(c.read(journeyProvider).isUncertainAt(0), isTrue);
      controller.toggleUncertain();
      expect(c.read(journeyProvider).isUncertainAt(0), isFalse);
      expect(c.read(journeyProvider).progressAt(0), QuestionProgress.answered);
      expect(api.sent, hasLength(1));
    },
  );
  test('ranked navigation preserves submitted and pending answers', () async {
    final api = TestApi();
    final c = ProviderContainer(
      overrides: [quizApiProvider.overrideWithValue(api)],
    );
    addTearDown(c.dispose);
    final controller = c.read(journeyProvider.notifier);
    await controller.bootstrap('Игрок');
    await controller.start();
    controller.goToQuestion(1);
    controller.stage(AnswerKind.multipleChoice, {'c'});
    controller.goToQuestion(0);
    controller.stage(AnswerKind.multipleChoice, {'b'});
    await controller.submit();
    expect(c.read(journeyProvider).index, 1);
    expect(c.read(journeyProvider).staged!.toJson(), {
      'option_ids': ['c'],
    });
    controller.goToQuestion(0);
    expect(c.read(journeyProvider).staged!.toJson(), {
      'option_ids': ['b'],
    });
    await controller.submit();
    expect(api.sent.length, 1);
  });
  test('damaged accepted response keeps the same payload across navigation and retry', () async {
    final api = TestApi()..failAnswer = true;
    final c = ProviderContainer(
      overrides: [quizApiProvider.overrideWithValue(api)],
    );
    addTearDown(c.dispose);
    final controller = c.read(journeyProvider.notifier);
    await controller.openQuiz('quiz-test');
    controller.stage(AnswerKind.multipleChoice, {'b'});
    await controller.submit();
    controller.goToQuestion(1);
    controller.goToQuestion(0);
    controller.stage(AnswerKind.multipleChoice, {'d'});
    await controller.submit();
    expect(api.sent, [
      {
        'option_ids': ['b'],
      },
      {
        'option_ids': ['b'],
      },
    ]);
    expect(api.keys[0], api.keys[1]);
    expect(c.read(journeyProvider).receipts, hasLength(1));
  });
  test(
    'final feedback retry never calls finish or resends an accepted answer',
    () async {
      final api = TestApi();
      final c = ProviderContainer(
        overrides: [quizApiProvider.overrideWithValue(api)],
      );
      addTearDown(c.dispose);
      final controller = c.read(journeyProvider.notifier);
      await controller.openQuiz('quiz-test');
      controller.stage(AnswerKind.multipleChoice, {'b'});
      await controller.submit();
      controller.nextQuestion();
      api.failFeedback = true;
      controller.stage(AnswerKind.multipleChoice, {'b'});
      await controller.submit();
      await controller.retry();
      expect(api.finishes, 0);
      expect(api.sent, hasLength(2));
      expect(api.feedbacks, 3);
      expect(c.read(journeyProvider).feedback, isNotNull);
      controller.nextQuestion();
      expect(c.read(journeyProvider).index, lessThan(2));
    },
  );
  test(
    'an older submission cannot overwrite an in-flight new attempt',
    () async {
      final api = TestApi();
      final c = ProviderContainer(
        overrides: [quizApiProvider.overrideWithValue(api)],
      );
      addTearDown(c.dispose);
      final controller = c.read(journeyProvider.notifier);
      await controller.openQuiz('quiz-test');
      api.answerGate = Completer<void>();
      controller.stage(AnswerKind.multipleChoice, {'b'});
      final old = controller.submit();
      api.startGate = Completer<void>();
      final next = controller.start();
      api.answerGate!.complete();
      await old;
      expect(c.read(journeyProvider).loading, isTrue);
      expect(c.read(journeyProvider).feedback, isNull);
      api.startGate!.complete();
      await next;
      expect(c.read(journeyProvider).receipts, isEmpty);
    },
  );
  testWidgets(
    'after the last receipt the phone can still review every answer',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final a = makeAttempt(1);
      final state = JourneyState(
        attempt: a,
        catalog: fixtureCatalog,
        index: 1,
        stagedByIndex: {
          0: MultipleChoiceAnswer({'b'}),
          1: MultipleChoiceAnswer({'c'}),
        },
        receipts: [for (final q in a.snapshots) receipt(a, q)],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            journeyProvider.overrideWith(() => LoadedJourney(state)),
            discoveryCatalogProvider.overrideWith(
              (ref) async => const [
                CatalogPack('quiz-test', 'Проверка', 'Описание', 'Разное', 2),
              ],
            ),
          ],
          child: const QuizApp(initialLocation: '/quiz/quiz-test'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('question-nav-0')), findsOneWidget);
      await tester.tap(find.byKey(const Key('question-nav-0')));
      await tester.pumpAndSettle();
      expect(find.text('Вопрос 0', findRichText: true), findsOneWidget);
      expect(find.text('Завершить викторину'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
