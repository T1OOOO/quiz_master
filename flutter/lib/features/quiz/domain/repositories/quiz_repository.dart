import 'package:quiz_master/features/quiz/domain/entities/quiz_entities.dart';

abstract class QuizRepository {
  Future<List<Quiz>> getAllQuizzes();
  Future<Quiz> getQuizById(String id);
  Future<Quiz> getQuizSummary(String id);
  Future<Question> getQuestion(String quizId, String questionId);
  Future<Feedback> checkAnswer(
    String quizId,
    String questionId,
    int answerIndex,
  );
  Future<bool> submitScore(String quizId, int score, int total, String? token);
  Future<bool> reportIssue(
    String quizId,
    String questionId,
    String message,
    String questionText,
  );
}
