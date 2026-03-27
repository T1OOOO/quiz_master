import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_master/core/utils/quota_checker.dart';
import 'package:quiz_master/features/statistics/domain/entities/statistics_entities.dart';
import '../../fixtures/auth_fixtures.dart';

void main() {
  group('QuotaChecker', () {
    test('canStartQuiz should return true when quota is null', () {
      // Act
      final result = QuotaChecker.canStartQuiz(quota: null);

      // Assert
      expect(result, true);
    });

    test('canStartQuiz should return true when quizzes limit is 0 (unlimited)',
        () {
      // Arrange
      final quota = AuthFixtures.createUserQuota(quizzesLimit: 0);
      final statistics = UserStatistics(quizzesCompleted: 5);

      // Act
      final result = QuotaChecker.canStartQuiz(
        quota: quota,
        statistics: statistics,
      );

      // Assert
      expect(result, true);
    });

    test('canStartQuiz should return false when limit reached', () {
      // Arrange
      final quota = AuthFixtures.createUserQuota(quizzesLimit: 5);
      final statistics = UserStatistics(quizzesCompleted: 5);

      // Act
      final result = QuotaChecker.canStartQuiz(
        quota: quota,
        statistics: statistics,
      );

      // Assert
      expect(result, false);
    });

    test('canStartQuiz should return true when limit not reached', () {
      // Arrange
      final quota = AuthFixtures.createUserQuota(quizzesLimit: 5);
      final statistics = UserStatistics(quizzesCompleted: 3);

      // Act
      final result = QuotaChecker.canStartQuiz(
        quota: quota,
        statistics: statistics,
      );

      // Assert
      expect(result, true);
    });

    test('canAnswerQuestion should return true when quota is null', () {
      // Act
      final result = QuotaChecker.canAnswerQuestion(quota: null);

      // Assert
      expect(result, true);
    });

    test('canAnswerQuestion should return false when questions limit reached',
        () {
      // Arrange
      final quota = AuthFixtures.createUserQuota(questionsLimit: 10);
      final statistics = UserStatistics(questionsAnswered: 10);

      // Act
      final result = QuotaChecker.canAnswerQuestion(
        quota: quota,
        statistics: statistics,
      );

      // Assert
      expect(result, false);
    });

    test('canAttemptQuiz should return true when quota is null', () {
      // Act
      final result = QuotaChecker.canAttemptQuiz(
        quizId: 'quiz1',
        quota: null,
        attempts: {},
      );

      // Assert
      expect(result, true);
    });

    test('canAttemptQuiz should return false when attempts limit reached', () {
      // Arrange
      final quota = AuthFixtures.createUserQuota(attemptsLimit: 3);
      final attempts = {'quiz1': 3};

      // Act
      final result = QuotaChecker.canAttemptQuiz(
        quizId: 'quiz1',
        quota: quota,
        attempts: attempts,
      );

      // Assert
      expect(result, false);
    });

    test('getRemainingQuizzes should return null when unlimited', () {
      // Arrange
      final quota = AuthFixtures.createUserQuota(quizzesLimit: 0);

      // Act
      final result = QuotaChecker.getRemainingQuizzes(quota: quota);

      // Assert
      expect(result, null);
    });

    test('getRemainingQuizzes should return correct remaining count', () {
      // Arrange
      final quota = AuthFixtures.createUserQuota(quizzesLimit: 10);
      final statistics = UserStatistics(quizzesCompleted: 7);

      // Act
      final result = QuotaChecker.getRemainingQuizzes(
        quota: quota,
        statistics: statistics,
      );

      // Assert
      expect(result, 3);
    });

    test('getRemainingQuestions should return null when unlimited', () {
      // Arrange
      final quota = AuthFixtures.createUserQuota(questionsLimit: 0);

      // Act
      final result = QuotaChecker.getRemainingQuestions(quota: quota);

      // Assert
      expect(result, null);
    });

    test('getRemainingAttempts should return correct remaining count', () {
      // Arrange
      final quota = AuthFixtures.createUserQuota(attemptsLimit: 5);
      final attempts = {'quiz1': 2};

      // Act
      final result = QuotaChecker.getRemainingAttempts(
        quizId: 'quiz1',
        quota: quota,
        attempts: attempts,
      );

      // Assert
      expect(result, 3);
    });
  });
}
