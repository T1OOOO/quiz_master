import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:quiz_master/core/api/api_client.dart';
import 'package:quiz_master/features/auth/domain/entities/auth_entities.dart';
import 'package:quiz_master/features/auth/domain/repositories/auth_repository_interface.dart';
import 'package:quiz_master/features/auth/data/repositories/auth_repository.dart';

part 'auth_providers.g.dart';

final _storage = const FlutterSecureStorage();
const _authTokenKey = 'auth_token';
const _authRefreshTokenKey = 'auth_refresh_token';
const _authUserKey = 'auth_user';

@riverpod
AuthRepositoryInterface authRepository(Ref ref) {
  return AuthRepository(ref.watch(apiClientProvider));
}

@riverpod
class AuthState extends _$AuthState {
  @override
  Future<AuthResponse?> build() async {
    final repository = ref.watch(authRepositoryProvider);
    final token = await _storage.read(key: _authTokenKey);
    final refreshToken = await _storage.read(key: _authRefreshTokenKey);
    final userJson = await _storage.read(key: _authUserKey);

    if (userJson != null) {
      try {
        final userMap = jsonDecode(userJson) as Map<String, dynamic>;
        final user = User.fromJson(userMap);

        if (token != null && token.isNotEmpty) {
          return AuthResponse(
            token: token,
            refreshToken: refreshToken ?? '',
            user: user,
          );
        }

        if (refreshToken != null && refreshToken.isNotEmpty) {
          final refreshed = await repository.refresh(refreshToken);
          final hydrated = refreshed.copyWith(
            user: refreshed.user.id.isEmpty ? user : refreshed.user,
          );
          await _persistAuth(hydrated);
          return hydrated;
        }
      } catch (e) {
        await _clearAuthStorage();
      }
    }

    return null;
  }

  Future<void> login(String username, String password) async {
    final repository = ref.read(authRepositoryProvider);
    final response = await repository.login(username, password);
    await _persistAuth(response);

    state = AsyncValue.data(response);
  }

  Future<void> register(
    String username,
    String password, {
    String? email,
  }) async {
    final repository = ref.read(authRepositoryProvider);
    final response = await repository.register(
      username,
      password,
      email: email,
    );
    await _persistAuth(response);

    state = AsyncValue.data(response);
  }

  Future<void> guestLogin(String username) async {
    final repository = ref.read(authRepositoryProvider);
    final response = await repository.guestLogin(username);
    await _persistAuth(response);

    state = AsyncValue.data(response);
  }

  Future<void> logout() async {
    await _clearAuthStorage();
    state = const AsyncValue.data(null);
  }

  Future<void> _persistAuth(AuthResponse response) async {
    await _storage.write(key: _authTokenKey, value: response.token);
    await _storage.write(
      key: _authRefreshTokenKey,
      value: response.refreshToken,
    );
    await _storage.write(
      key: _authUserKey,
      value: jsonEncode(response.user.toJson()),
    );
  }

  Future<void> _clearAuthStorage() async {
    await _storage.delete(key: _authTokenKey);
    await _storage.delete(key: _authRefreshTokenKey);
    await _storage.delete(key: _authUserKey);
  }
}

@riverpod
Future<UserQuota?> userQuota(Ref ref) async {
  final authStateAsync = ref.watch(authStateProvider);

  return authStateAsync.when(
    data: (authData) async {
      if (authData == null) return null;
      final repository = ref.read(authRepositoryProvider);
      return await repository.getUserQuota(authData.token);
    },
    loading: () async => null,
    error: (_, _) async => null,
  );
}
