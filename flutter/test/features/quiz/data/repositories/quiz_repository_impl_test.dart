import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:quiz_master/core/api/api_client.dart';
import 'package:quiz_master/features/quiz/data/repositories/quiz_repository_impl.dart';
import 'package:quiz_master/features/quiz/domain/entities/quiz_entities.dart';
import '../../../../fixtures/quiz_fixtures.dart';

import 'quiz_repository_impl_test.mocks.dart';

@GenerateMocks([ApiClient])
void main() {
  late MockApiClient mockApiClient;
  late QuizRepositoryImpl repository;

  setUpAll(() {
    provideDummy<Quiz>(QuizFixtures.createQuiz());
    provideDummy<Question>(QuizFixtures.createQuestion());
    provideDummy<Feedback>(QuizFixtures.createFeedback(correct: true));
  });

  setUp(() {
    mockApiClient = MockApiClient();
    repository = QuizRepositoryImpl(mockApiClient);
  });

  group('QuizRepositoryImpl', () {
    test('getAllQuizzes should return list of quizzes', () async {
      // Arrange
      final expectedQuizzes = QuizFixtures.createQuizList();
      when(mockApiClient.getAllQuizzes())
          .thenAnswer((_) async => expectedQuizzes);

      // Act
      final result = await repository.getAllQuizzes();

      // Assert
      expect(result, isA<List<Quiz>>());
      expect(result.length, expectedQuizzes.length);
      verify(mockApiClient.getAllQuizzes()).called(1);
    });

    test('getQuizById should return quiz', () async {
      // Arrange
      final expectedQuiz = QuizFixtures.createQuiz(id: 'quiz1');
      when(mockApiClient.getQuizById('quiz1'))
          .thenAnswer((_) async => expectedQuiz);

      // Act
      final result = await repository.getQuizById('quiz1');

      // Assert
      expect(result, isA<Quiz>());
      expect(result.id, 'quiz1');
      verify(mockApiClient.getQuizById('quiz1')).called(1);
    });

    test('getQuizSummary should return quiz summary', () async {
      // Arrange
      final expectedQuiz = QuizFixtures.createQuiz(id: 'quiz1');
      when(mockApiClient.getQuizSummary('quiz1'))
          .thenAnswer((_) async => expectedQuiz);

      // Act
      final result = await repository.getQuizSummary('quiz1');

      // Assert
      expect(result, isA<Quiz>());
      expect(result.id, 'quiz1');
      verify(mockApiClient.getQuizSummary('quiz1')).called(1);
    });

    test('getQuestion should return question', () async {
      // Arrange
      final expectedQuestion = QuizFixtures.createQuestion(id: 'q1');
      when(mockApiClient.getQuestion('quiz1', 'q1'))
          .thenAnswer((_) async => expectedQuestion);

      // Act
      final result = await repository.getQuestion('quiz1', 'q1');

      // Assert
      expect(result, isA<Question>());
      expect(result.id, 'q1');
      verify(mockApiClient.getQuestion('quiz1', 'q1')).called(1);
    });

    test('checkAnswer should return feedback', () async {
      // Arrange
      final expectedFeedback = QuizFixtures.createFeedback(correct: true);
      when(mockApiClient.checkAnswer('quiz1', 'q1', 0))
          .thenAnswer((_) async => expectedFeedback);

      // Act
      final result = await repository.checkAnswer('quiz1', 'q1', 0);

      // Assert
      expect(result, isA<Feedback>());
      expect(result.correct, true);
      verify(mockApiClient.checkAnswer('quiz1', 'q1', 0)).called(1);
    });
  });
}
