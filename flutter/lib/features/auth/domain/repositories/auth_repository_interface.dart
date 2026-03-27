import 'package:quiz_master/features/auth/domain/entities/auth_entities.dart';

abstract class AuthRepositoryInterface {
  Future<AuthResponse> login(String username, String password);
  Future<AuthResponse> register(
    String username,
    String password, {
    String? email,
  });
  Future<AuthResponse> guestLogin(String username);
  Future<AuthResponse> refresh(String refreshToken);
  Future<UserQuota?> getUserQuota(String token);
}
