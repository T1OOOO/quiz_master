import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quiz_master/core/network/dio_client.dart';
import 'package:quiz_master/features/auth/domain/entities/auth_entities.dart';
import 'package:quiz_master/features/quiz/domain/entities/quiz_entities.dart';
import 'package:quiz_master/features/statistics/domain/entities/statistics_entities.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    quizDio: ref.watch(dioClientProvider),
    authDio: ref.watch(authDioClientProvider),
  );
});

class ApiClient {
  final Dio _quizDio;
  final Dio _authDio;

  ApiClient({required Dio quizDio, required Dio authDio})
    : _quizDio = quizDio,
      _authDio = authDio;

  Future<List<Quiz>> getAllQuizzes() async {
    final response = await _quizDio.get('/quizzes');
    final List<dynamic> data = response.data;
    return data.map((json) => Quiz.fromJson(json)).toList();
  }

  Future<List<Quiz>> getAdminQuizzes(String token) async {
    final response = await _quizDio.get(
      '/admin/quizzes',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    final List<dynamic> data = response.data;
    return data.map((json) => Quiz.fromJson(json)).toList();
  }

  Future<Quiz> getQuizById(String id) async {
    final response = await _quizDio.get('/quizzes/$id');
    return Quiz.fromJson(response.data);
  }

  Future<Quiz> getQuizSummary(String id) async {
    final response = await _quizDio.get(
      '/quizzes/$id',
      queryParameters: {'mode': 'summary'},
    );
    return Quiz.fromJson(response.data);
  }

  Future<Question> getQuestion(String quizId, String questionId) async {
    final response = await _quizDio.get(
      '/quizzes/$quizId/questions/$questionId',
    );
    return Question.fromJson(response.data);
  }

  Future<Feedback> checkAnswer(
    String quizId,
    String questionId,
    int answerIndex,
  ) async {
    final response = await _quizDio.post(
      '/quizzes/$quizId/check',
      data: {
        'quiz_id': quizId,
        'question_id': questionId,
        'answer': answerIndex,
      },
    );
    return Feedback.fromJson(response.data);
  }

  Future<bool> submitScore(
    String quizId,
    int score,
    int total,
    String? token,
  ) async {
    if (token == null) return false;
    try {
      await _authDio.post(
        '/submit',
        data: {'quiz_id': quizId, 'score': score, 'total_questions': total},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> reportIssue(
    String quizId,
    String questionId,
    String message,
    String questionText,
  ) async {
    try {
      await _quizDio.post(
        '/report',
        data: {
          'quiz_id': quizId,
          'question_id': questionId,
          'message': message,
          'question_text': questionText,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<AuthResponse> login(AuthRequest request) async {
    final response = await _authDio.post('/login', data: request.toJson());
    return _parseAuthResponse(response.data as Map<String, dynamic>);
  }

  Future<AuthResponse> register(AuthRequest request) async {
    final response = await _authDio.post('/register', data: request.toJson());
    return _parseAuthResponse(response.data as Map<String, dynamic>);
  }

  Future<AuthResponse> guestLogin(String username) async {
    final response = await _authDio.post(
      '/guest',
      data: {'username': username},
    );
    return _parseAuthResponse(response.data as Map<String, dynamic>);
  }

  Future<AuthResponse> refresh(String refreshToken) async {
    final response = await _authDio.post(
      '/refresh',
      data: {'refresh_token': refreshToken},
    );
    return _parseAuthResponse(response.data as Map<String, dynamic>);
  }

  Future<List<LeaderboardEntry>> getLeaderboard({int limit = 10}) async {
    final response = await _authDio.get(
      '/leaderboard',
      queryParameters: {'limit': limit},
    );
    final List<dynamic> data = response.data;
    return data.map((json) => LeaderboardEntry.fromJson(json)).toList();
  }

  Future<List<LeaderboardEntry>> getAdminLeaderboard(
    String token, {
    int limit = 10,
  }) async {
    final response = await _authDio.get(
      '/admin/leaderboard',
      queryParameters: {'limit': limit},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    final List<dynamic> data = response.data;
    return data.map((json) => LeaderboardEntry.fromJson(json)).toList();
  }

  Future<UserQuota?> getUserQuota(String token) async {
    try {
      final response = await _authDio.get(
        '/quota',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return UserQuota.fromJson(response.data);
    } catch (e) {
      return null;
    }
  }

  AuthResponse _parseAuthResponse(Map<String, dynamic> json) {
    if (json['user'] is Map<String, dynamic>) {
      return AuthResponse.fromJson({
        ...json,
        'refreshToken': json['refreshToken'] ?? json['refresh_token'],
      });
    }

    final username = json['username'] as String? ?? '';
    final role = json['role'] as String? ?? 'user';
    final userID = json['user_id'] as String? ?? username;
    final refreshToken = json['refresh_token'] as String? ?? '';

    return AuthResponse(
      token: json['token'] as String? ?? '',
      refreshToken: refreshToken,
      user: User(id: userID, username: username, role: role),
    );
  }
}
