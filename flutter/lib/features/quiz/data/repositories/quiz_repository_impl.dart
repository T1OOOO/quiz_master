import 'package:quiz_master/core/api/api_client.dart';
import 'package:quiz_master/features/quiz/domain/entities/quiz_entities.dart';
import 'package:quiz_master/features/quiz/domain/repositories/quiz_repository.dart';

class QuizRepositoryImpl implements QuizRepository {
  final ApiClient _apiClient;

  QuizRepositoryImpl(this._apiClient);

  @override
  Future<List<Quiz>> getAllQuizzes() => _apiClient.getAllQuizzes();

  @override
  Future<Quiz> getQuizById(String id) => _apiClient.getQuizById(id);

  @override
  Future<Quiz> getQuizSummary(String id) => _apiClient.getQuizSummary(id);

  @override
  Future<Question> getQuestion(String quizId, String questionId) =>
      _apiClient.getQuestion(quizId, questionId);

  @override
  Future<Feedback> checkAnswer(
    String quizId,
    String questionId,
    int answerIndex,
  ) => _apiClient.checkAnswer(quizId, questionId, answerIndex);

  @override
  Future<bool> submitScore(
    String quizId,
    int score,
    int total,
    String? token,
  ) => _apiClient.submitScore(quizId, score, total, token);

  @override
  Future<bool> reportIssue(
    String quizId,
    String questionId,
    String message,
    String questionText,
  ) => _apiClient.reportIssue(quizId, questionId, message, questionText);
}
