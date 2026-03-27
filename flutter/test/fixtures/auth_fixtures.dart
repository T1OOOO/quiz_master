import 'package:quiz_master/features/auth/domain/entities/auth_entities.dart';

/// Test fixtures for Auth entities
class AuthFixtures {
  static User createUser({
    String? id,
    String? username,
    String? email,
    String? avatar,
    String? role,
  }) {
    return User(
      id: id ?? 'user1',
      username: username ?? 'testuser',
      email: email,
      avatar: avatar,
      role: role ?? 'user',
    );
  }

  static AuthResponse createAuthResponse({
    String? token,
    String? refreshToken,
    User? user,
  }) {
    return AuthResponse(
      token: token ?? 'test_token_123',
      refreshToken: refreshToken ?? 'refresh_token_123',
      user: user ?? createUser(),
    );
  }

  static AuthRequest createAuthRequest({
    String? username,
    String? password,
    String? email,
  }) {
    return AuthRequest(
      username: username ?? 'testuser',
      password: password ?? 'password123',
      email: email,
    );
  }

  static UserQuota createUserQuota({
    int? quizzesCompleted,
    int? questionsAnswered,
    int? quizzesLimit,
    int? questionsLimit,
    int? attemptsLimit,
    int? attemptsUsed,
  }) {
    return UserQuota(
      quizzesCompleted: quizzesCompleted ?? 0,
      questionsAnswered: questionsAnswered ?? 0,
      quizzesLimit: quizzesLimit ?? 0,
      questionsLimit: questionsLimit ?? 0,
      attemptsLimit: attemptsLimit ?? 0,
      attemptsUsed: attemptsUsed ?? 0,
    );
  }
}
