import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:quiz_master/core/api/api_client.dart';
import 'package:quiz_master/features/auth/data/repositories/auth_repository.dart';
import 'package:quiz_master/features/auth/domain/entities/auth_entities.dart';
import '../../../../fixtures/auth_fixtures.dart';

import 'auth_repository_test.mocks.dart';

@GenerateMocks([ApiClient])
void main() {
  late MockApiClient mockApiClient;
  late AuthRepository repository;
  late AuthRequest request;
  late AuthResponse expectedResponse;

  setUpAll(() {
    provideDummy<AuthResponse>(AuthFixtures.createAuthResponse());
  });

  setUp(() {
    mockApiClient = MockApiClient();
    repository = AuthRepository(mockApiClient);
    request = AuthFixtures.createAuthRequest();
    expectedResponse = AuthFixtures.createAuthResponse();
  });

  group('AuthRepository', () {
    test('login should return AuthResponse', () async {
      // Arrange
      when(mockApiClient.login(request)).thenAnswer((_) async => expectedResponse);

      // Act
      final result = await repository.login('testuser', 'password123');

      // Assert
      expect(result, isA<AuthResponse>());
      expect(result.token, expectedResponse.token);
      verify(mockApiClient.login(request)).called(1);
    });

    test('register should return AuthResponse', () async {
      // Arrange
      final registerRequest = AuthFixtures.createAuthRequest(
        email: 'test@example.com',
      );
      when(mockApiClient.register(registerRequest))
          .thenAnswer((_) async => expectedResponse);

      // Act
      final result = await repository.register('testuser', 'password123',
          email: 'test@example.com');

      // Assert
      expect(result, isA<AuthResponse>());
      expect(result.token, expectedResponse.token);
      verify(mockApiClient.register(registerRequest)).called(1);
    });

    test('guestLogin should return AuthResponse', () async {
      // Arrange
      when(mockApiClient.guestLogin('guestuser'))
          .thenAnswer((_) async => expectedResponse);

      // Act
      final result = await repository.guestLogin('guestuser');

      // Assert
      expect(result, isA<AuthResponse>());
      expect(result.token, expectedResponse.token);
      verify(mockApiClient.guestLogin('guestuser')).called(1);
    });

    test('refresh should return AuthResponse', () async {
      when(
        mockApiClient.refresh('refresh_token_123'),
      ).thenAnswer((_) async => expectedResponse);

      final result = await repository.refresh('refresh_token_123');

      expect(result, isA<AuthResponse>());
      expect(result.refreshToken, expectedResponse.refreshToken);
      verify(mockApiClient.refresh('refresh_token_123')).called(1);
    });

    test('getUserQuota should return UserQuota', () async {
      // Arrange
      final expectedQuota = AuthFixtures.createUserQuota(quizzesLimit: 10);
      when(mockApiClient.getUserQuota('token123'))
          .thenAnswer((_) async => expectedQuota);

      // Act
      final result = await repository.getUserQuota('token123');

      // Assert
      expect(result, isA<UserQuota>());
      expect(result?.quizzesLimit, 10);
      verify(mockApiClient.getUserQuota('token123')).called(1);
    });

    test('getUserQuota should return null on error', () async {
      // Arrange
      when(mockApiClient.getUserQuota('token123'))
          .thenAnswer((_) async => null);

      // Act
      final result = await repository.getUserQuota('token123');

      // Assert
      expect(result, null);
      verify(mockApiClient.getUserQuota('token123')).called(1);
    });
  });
}
