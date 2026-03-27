import 'package:freezed_annotation/freezed_annotation.dart';

part 'statistics_entities.freezed.dart';
part 'statistics_entities.g.dart';

@freezed
sealed class UserStatistics with _$UserStatistics {
  const factory UserStatistics({
    @Default(0) int quizzesCompleted,
    @Default(0) int questionsAnswered,
    @Default(0) int correctAnswers,
    @Default(0) int incorrectAnswers,
    @Default(0) int totalTimeSpent, // in seconds
    DateTime? lastActivity,
  }) = _UserStatistics;

  factory UserStatistics.fromJson(Map<String, dynamic> json) =>
      _$UserStatisticsFromJson(json);
}

@freezed
sealed class LeaderboardEntry with _$LeaderboardEntry {
  const factory LeaderboardEntry({
    required String username,
    required int score,
    required int total,
    String? quizTitle,
  }) = _LeaderboardEntry;

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) =>
      _$LeaderboardEntryFromJson(json);
}
