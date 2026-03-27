import 'package:quiz_master/features/auth/domain/entities/auth_entities.dart';
import 'package:quiz_master/features/statistics/domain/entities/statistics_entities.dart';

/// Utility class to check user quotas and limits
class QuotaChecker {
  /// Check if user can start a new quiz
  static bool canStartQuiz({UserQuota? quota, UserStatistics? statistics}) {
    if (quota == null) {
      // No quota means unlimited (guest or no restrictions)
      return true;
    }

    // Check quizzes limit
    if (quota.quizzesLimit > 0) {
      if (statistics != null &&
          statistics.quizzesCompleted >= quota.quizzesLimit) {
        return false;
      }
    }

    return true;
  }

  /// Check if user can answer more questions
  static bool canAnswerQuestion({
    UserQuota? quota,
    UserStatistics? statistics,
  }) {
    if (quota == null) {
      return true;
    }

    // Check questions limit
    if (quota.questionsLimit > 0) {
      if (statistics != null &&
          statistics.questionsAnswered >= quota.questionsLimit) {
        return false;
      }
    }

    return true;
  }

  /// Check if user can attempt quiz again
  static bool canAttemptQuiz({
    required String quizId,
    UserQuota? quota,
    required Map<String, int> attempts, // quizId -> count
  }) {
    if (quota == null) {
      return true;
    }

    // Check attempts limit
    if (quota.attemptsLimit > 0) {
      final currentAttempts = attempts[quizId] ?? 0;
      if (currentAttempts >= quota.attemptsLimit) {
        return false;
      }
    }

    return true;
  }

  /// Get remaining quizzes
  static int? getRemainingQuizzes({
    UserQuota? quota,
    UserStatistics? statistics,
  }) {
    if (quota == null || quota.quizzesLimit == 0) {
      return null; // Unlimited
    }

    if (statistics == null) {
      return quota.quizzesLimit;
    }

    final remaining = quota.quizzesLimit - statistics.quizzesCompleted;
    return remaining > 0 ? remaining : 0;
  }

  /// Get remaining questions
  static int? getRemainingQuestions({
    UserQuota? quota,
    UserStatistics? statistics,
  }) {
    if (quota == null || quota.questionsLimit == 0) {
      return null; // Unlimited
    }

    if (statistics == null) {
      return quota.questionsLimit;
    }

    final remaining = quota.questionsLimit - statistics.questionsAnswered;
    return remaining > 0 ? remaining : 0;
  }

  /// Get remaining attempts for a quiz
  static int? getRemainingAttempts({
    required String quizId,
    UserQuota? quota,
    required Map<String, int> attempts,
  }) {
    if (quota == null || quota.attemptsLimit == 0) {
      return null; // Unlimited
    }

    final currentAttempts = attempts[quizId] ?? 0;
    final remaining = quota.attemptsLimit - currentAttempts;
    return remaining > 0 ? remaining : 0;
  }
}
