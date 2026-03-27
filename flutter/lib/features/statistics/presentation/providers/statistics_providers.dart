import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:quiz_master/core/api/api_client.dart';
import 'package:quiz_master/features/statistics/domain/entities/statistics_entities.dart';

part 'statistics_providers.g.dart';

@riverpod
Future<List<LeaderboardEntry>> leaderboard(
  Ref ref, {
  int limit = 10,
}) async {
  final apiClient = ref.watch(apiClientProvider);
  return await apiClient.getLeaderboard(limit: limit);
}

@riverpod
class UserStatisticsNotifier extends _$UserStatisticsNotifier {
  @override
  UserStatistics build() {
    return const UserStatistics();
  }

  void updateFromQuiz({
    required int correct,
    required int incorrect,
    required int timeSpent,
  }) {
    final current = state;
    state = current.copyWith(
      questionsAnswered: current.questionsAnswered + correct + incorrect,
      correctAnswers: current.correctAnswers + correct,
      incorrectAnswers: current.incorrectAnswers + incorrect,
      totalTimeSpent: current.totalTimeSpent + timeSpent,
      lastActivity: DateTime.now(),
    );
  }

  void incrementQuizzesCompleted() {
    state = state.copyWith(
      quizzesCompleted: state.quizzesCompleted + 1,
      lastActivity: DateTime.now(),
    );
  }
}
