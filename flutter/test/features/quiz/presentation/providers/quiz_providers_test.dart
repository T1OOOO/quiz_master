import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:quiz_master/core/providers/core_providers.dart';
import 'package:quiz_master/features/quiz/domain/entities/quiz_entities.dart';
import 'package:quiz_master/features/quiz/domain/repositories/quiz_repository.dart';
import 'package:quiz_master/features/quiz/presentation/providers/quiz_providers.dart';
import '../../../../fixtures/quiz_fixtures.dart';

import 'quiz_providers_test.mocks.dart';

@GenerateMocks([QuizRepository])
void main() {
  late MockQuizRepository mockRepository;
  late ProviderContainer container;

  setUpAll(() {
    provideDummy<Quiz>(QuizFixtures.createQuiz());
    provideDummy<Question>(QuizFixtures.createQuestion());
    provideDummy<Feedback>(QuizFixtures.createFeedback(correct: true));
  });

  setUp(() {
    mockRepository = MockQuizRepository();
    container = ProviderContainer(
      overrides: [quizRepositoryProvider.overrideWithValue(mockRepository)],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('QuizStateNotifier', () {
    test('initQuiz should load quiz and set status to active', () async {
      // Arrange
      final quiz = QuizFixtures.createQuiz(id: 'quiz1');
      when(
        mockRepository.getQuizSummary('quiz1'),
      ).thenAnswer((_) async => quiz);
      when(
        mockRepository.getQuestion('quiz1', 'q1'),
      ).thenAnswer((_) async => quiz.questions.first);

      final notifier = container.read(quizStateProvider.notifier);

      // Act
      await notifier.initQuiz('quiz1');

      // Assert
      final state = container.read(quizStateProvider);
      expect(state.status, QuizStatus.active);
      expect(state.quizId, 'quiz1');
      expect(state.quizTitle, quiz.title);
      verify(mockRepository.getQuizSummary('quiz1')).called(1);
    });

    test('initQuiz should set error status on failure', () async {
      // Arrange
      when(
        mockRepository.getQuizSummary('quiz1'),
      ).thenThrow(Exception('Network error'));

      final notifier = container.read(quizStateProvider.notifier);

      // Act
      await notifier.initQuiz('quiz1');

      // Assert
      final state = container.read(quizStateProvider);
      expect(state.status, QuizStatus.error);
      expect(state.error, isNotNull);
    });

    test('submitAnswer should update answers and feedback', () async {
      // Arrange
      final quiz = QuizFixtures.createQuiz(id: 'quiz1');
      final question = quiz.questions.first;
      final feedback = QuizFixtures.createFeedback(correct: true);

      when(
        mockRepository.getQuizSummary('quiz1'),
      ).thenAnswer((_) async => quiz);
      when(
        mockRepository.getQuestion('quiz1', question.id),
      ).thenAnswer((_) async => question);
      when(
        mockRepository.checkAnswer('quiz1', question.id, 0),
      ).thenAnswer((_) async => feedback);

      final notifier = container.read(quizStateProvider.notifier);
      await notifier.initQuiz('quiz1');

      // Act
      await notifier.submitAnswer(question.id, 0);

      // Assert
      final state = container.read(quizStateProvider);
      expect(state.answers[question.id], 0);
      expect(state.feedback[question.id]?.correct, true);
      verify(mockRepository.checkAnswer('quiz1', question.id, 0)).called(1);
    });

    test('selectQuestion should update currentQuestionIndex', () async {
      // Arrange
      final quiz = QuizFixtures.createQuiz(
        id: 'quiz1',
        questions: [
          QuizFixtures.createQuestion(id: 'q1'),
          QuizFixtures.createQuestion(id: 'q2'),
        ],
      );

      when(
        mockRepository.getQuizSummary('quiz1'),
      ).thenAnswer((_) async => quiz);
      when(
        mockRepository.getQuestion('quiz1', 'q1'),
      ).thenAnswer((_) async => quiz.questions.first);
      when(
        mockRepository.getQuestion('quiz1', 'q2'),
      ).thenAnswer((_) async => quiz.questions[1]);

      final notifier = container.read(quizStateProvider.notifier);
      await notifier.initQuiz('quiz1');

      // Act
      notifier.selectQuestion(1);

      // Assert
      final state = container.read(quizStateProvider);
      expect(state.currentQuestionIndex, 1);
    });

    test('resetQuiz should reset state to idle', () {
      // Arrange
      final notifier = container.read(quizStateProvider.notifier);

      // Act
      notifier.resetQuiz();

      // Assert
      final state = container.read(quizStateProvider);
      expect(state.status, QuizStatus.idle);
      expect(state.quizId, null);
      expect(state.questions, isEmpty);
    });
  });
}
