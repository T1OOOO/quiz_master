import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quiz_master/core/api/api_client.dart';
import 'package:quiz_master/features/auth/presentation/providers/auth_providers.dart';
import 'package:quiz_master/features/quiz/domain/entities/quiz_entities.dart';
import 'package:quiz_master/features/statistics/domain/entities/statistics_entities.dart';

final adminQuizzesProvider = FutureProvider<List<Quiz>>((ref) async {
  final auth = await ref.watch(authStateProvider.future);
  if (auth == null || auth.user.role != 'admin' || auth.token.isEmpty) {
    return const [];
  }

  final apiClient = ref.watch(apiClientProvider);
  return apiClient.getAdminQuizzes(auth.token);
});

final adminLeaderboardProvider = FutureProvider.family<List<LeaderboardEntry>, int>((
  ref,
  limit,
) async {
  final auth = await ref.watch(authStateProvider.future);
  if (auth == null || auth.user.role != 'admin' || auth.token.isEmpty) {
    return const [];
  }

  final apiClient = ref.watch(apiClientProvider);
  return apiClient.getAdminLeaderboard(auth.token, limit: limit);
});
