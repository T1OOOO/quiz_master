import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quiz_master/core/api/api_client.dart';
import 'package:quiz_master/features/quiz/data/repositories/quiz_repository_impl.dart';
import 'package:quiz_master/features/quiz/domain/repositories/quiz_repository.dart';

final quizRepositoryProvider = Provider<QuizRepository>((ref) {
  return QuizRepositoryImpl(ref.watch(apiClientProvider));
});
