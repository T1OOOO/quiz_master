import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/main.dart';

const _quizId = 'quiz-dismiss';
final _revision = Revision(1, 'a' * 64);

final _questions = [
  for (var number = 1; number <= 5; number++)
    PublicQuestion(
      quizId: _quizId,
      id: 'question-$number',
      revision: _revision,
      stem: 'Вопрос $number',
      kind: AnswerKind.singleChoice,
      options: [
        for (final option in ['a', 'b', 'c', 'd'])
          PublicOption(id: option, text: 'Вариант $number-$option'),
      ],
    ),
];

class _DismissApi extends QuizApiClient {
  _DismissApi() : super(baseUri: Uri.parse('https://quiz.test'));

  @override
  Future<GuestSession> bootstrap(String name) async => GuestSession(
    participantId: 'p-${'0' * 32}',
    displayName: name,
    token: 'test-token',
    expiresAt: DateTime.utc(2030),
  );

  @override
  Future<Catalog> catalog({String? quizId, DifficultyBand? difficulty}) async =>
      Catalog(
        bundleVersion: 'v1',
        bundleSha256: 'b' * 64,
        quiz: PublicQuiz(id: _quizId, questions: _questions),
      );

  @override
  Future<Attempt> startAttempt({
    String? quizId,
    int? round,
    DifficultyBand? difficulty,
    bool practice = false,
  }) async => Attempt(
    id: 'attempt-dismiss',
    participantId: 'p-${'0' * 32}',
    bundleVersion: 'v1',
    bundleSha256: 'b' * 64,
    snapshots: [
      for (final question in _questions)
        AttemptSnapshot(
          questionId: question.id,
          revision: _revision,
          optionOrder: const ['a', 'b', 'c', 'd'],
        ),
    ],
  );

  @override
  Future<Receipt> submitAnswer(
    Attempt attempt,
    AttemptSnapshot snapshot,
    StagedAnswer answer, {
    required String idempotencyKey,
  }) async => Receipt(
    id: 'receipt-${snapshot.questionId}',
    attemptId: attempt.id,
    participantId: attempt.participantId,
    questionId: snapshot.questionId,
    revision: _revision,
  );

  @override
  Future<PracticeFeedback> feedback(
    Attempt attempt,
    AttemptSnapshot snapshot,
    String quizId,
  ) async {
    final number = snapshot.questionId.split('-').last;
    return PracticeFeedback(
      false,
      Reveal(
        answer: 'b',
        explanation: 'Разбор вопроса $number',
        quizId: quizId,
        questionId: snapshot.questionId,
        revision: _revision,
        correctOptionIds: const {'b'},
      ),
    );
  }
}

void main() {
  testWidgets(
    'dismissing non-first practice feedback preserves review while Continue finds the first pending question',
    (tester) async {
      final api = _DismissApi();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [quizApiProvider.overrideWithValue(api)],
          child: const QuizApp(
            initialLocation: '/quiz/$_quizId',
            defaultLocale: Locale('ru'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(QuizApp)),
      );

      Future<void> openQuestion(int index) async {
        await tester.tap(find.byKey(const Key('question-navigation-menu')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(Key('question-nav-$index')));
        await tester.pumpAndSettle();
      }

      Future<void> answerWrong(int number) async {
        await tester.tap(find.text('Вариант $number-a'));
        await tester.pumpAndSettle();
        expect(find.byType(Dialog), findsOneWidget);
      }

      // The explicit close keeps the selected non-first question in review.
      await openQuestion(1);
      await answerWrong(2);
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
      expect(container.read(journeyProvider).index, 1);
      expect(container.read(journeyProvider).feedback, isNull);
      expect(find.text('Разбор вопроса 2'), findsOneWidget);

      // Tapping the modal barrier has the same non-advancing behavior.
      await openQuestion(2);
      await answerWrong(3);
      await tester.tapAt(const Offset(4, 4));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
      expect(container.read(journeyProvider).index, 2);
      expect(container.read(journeyProvider).feedback, isNull);
      expect(find.text('Разбор вопроса 3'), findsOneWidget);

      // System back has the same behavior.
      await openQuestion(3);
      await answerWrong(4);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
      expect(container.read(journeyProvider).index, 3);
      expect(container.read(journeyProvider).feedback, isNull);
      expect(find.text('Разбор вопроса 4'), findsOneWidget);

      // Continue keeps its existing first-pending navigation policy.
      await openQuestion(4);
      await answerWrong(5);
      await tester.tap(find.byKey(const Key('feedback-next')));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
      expect(container.read(journeyProvider).index, 0);
      expect(container.read(journeyProvider).feedback, isNull);
      expect(find.text('Вопрос 1'), findsOneWidget);
      expect(find.text('Разбор вопроса 5'), findsNothing);
    },
  );
}
