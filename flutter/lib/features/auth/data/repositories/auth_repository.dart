import 'package:quiz_master/core/api/api_client.dart';
import 'package:quiz_master/features/auth/domain/entities/auth_entities.dart';
import 'package:quiz_master/features/auth/domain/repositories/auth_repository_interface.dart';

class AuthRepository implements AuthRepositoryInterface {
  final ApiClient _apiClient;

  AuthRepository(this._apiClient);

  @override
  Future<AuthResponse> login(String username, String password) async {
    final response = await _apiClient.login(
      AuthRequest(username: username, password: password),
    );
    return response;
  }

  @override
  Future<AuthResponse> register(
    String username,
    String password, {
    String? email,
  }) async {
    final response = await _apiClient.register(
      AuthRequest(username: username, password: password, email: email),
    );
    return response;
  }

  @override
  Future<AuthResponse> guestLogin(String username) async {
    final response = await _apiClient.guestLogin(username);
    return response;
  }

  @override
  Future<AuthResponse> refresh(String refreshToken) async {
    final response = await _apiClient.refresh(refreshToken);
    return response;
  }

  @override
  Future<UserQuota?> getUserQuota(String token) async {
    return await _apiClient.getUserQuota(token);
  }
}
