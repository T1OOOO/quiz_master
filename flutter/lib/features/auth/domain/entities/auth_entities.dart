import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_entities.freezed.dart';
part 'auth_entities.g.dart';

@freezed
sealed class User with _$User {
  const factory User({
    required String id,
    required String username,
    String? email,
    String? avatar,
    @Default('user') String role,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}

@freezed
sealed class AuthResponse with _$AuthResponse {
  const factory AuthResponse({
    required String token,
    @Default('') String refreshToken,
    required User user,
  }) = _AuthResponse;

  factory AuthResponse.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseFromJson(json);
}

@freezed
sealed class AuthRequest with _$AuthRequest {
  const factory AuthRequest({
    required String username,
    String? password,
    String? email,
  }) = _AuthRequest;

  factory AuthRequest.fromJson(Map<String, dynamic> json) =>
      _$AuthRequestFromJson(json);
}

@freezed
sealed class UserQuota with _$UserQuota {
  const factory UserQuota({
    @Default(0) int quizzesCompleted,
    @Default(0) int questionsAnswered,
    @Default(0) int quizzesLimit,
    @Default(0) int questionsLimit,
    @Default(0) int attemptsLimit,
    @Default(0) int attemptsUsed,
  }) = _UserQuota;

  factory UserQuota.fromJson(Map<String, dynamic> json) =>
      _$UserQuotaFromJson(json);
}
